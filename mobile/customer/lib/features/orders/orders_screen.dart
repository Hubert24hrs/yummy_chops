import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../widgets.dart';
import '../cart/cart_controller.dart';

const _active = activeOrderStatuses;

/// Orders: in-progress tracking, the cart you haven't finished, history and what you've spent. The list is read
/// again each time the tab shows and when the app comes back to the front (a list read once, when there were no
/// orders yet, stayed empty after paying).
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with WidgetsBindingObserver {
  /// Whether the tab is the one on screen: the tab shell keeps the other tabs alive with their tickers off.
  bool? _shown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.valuesOf(context).enabled;
    // Shown again after another tab: read the list again (the first time it is read anyway).
    if (shown && _shown == false) {
      // Not while the tree is being built: the list's other readers rebuild with it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
    _shown = shown;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shown != false) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(myOrdersProvider);
    ref.invalidate(orderSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    // No sign-in here: the app has signed in a guest (or the customer) before this tab shows (GuestGate in app.dart).
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Orders', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          bottom: const TabBar(tabs: [Tab(text: 'In progress'), Tab(text: 'History')]),
        ),
        body: TabBarView(children: [_InProgress(), _History()]),
      ),
    );
  }
}

class _InProgress extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    final cart = ref.watch(cartProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myOrdersProvider.future).then((_) {}, onError: (_) {}),
      child: ListView(padding: const EdgeInsets.only(top: 8, bottom: 96), children: [
        orders.when(
          loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
          data: (list) {
            final active = list.where((o) => _active.contains(o.status)).toList();
            if (active.isEmpty) {
              return const EmptyState(icon: Icons.shopping_bag_outlined, title: 'Track your orders', body: 'Your ongoing orders will be listed here');
            }
            return Column(children: [for (final o in active) _OrderRow(order: o)]);
          },
        ),
        const SectionTitle('Continue your order'),
        if (cart.isEmpty)
          const EmptyState(icon: Icons.shopping_cart_outlined, title: 'No carts yet', body: 'Add items from stores to create new carts')
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.shopping_cart_rounded)),
              title: Text(cart.shops.length > 1 ? 'Your cart · ${cart.shops.length} shops' : cart.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${cart.count} item(s) · ${formatNaira(cart.subtotalKobo)}'),
              trailing: FilledButton(onPressed: () => context.push('/cart'), child: const Text('View cart')),
            ),
          ),
      ]),
    );
  }
}

class _History extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    final summary = ref.watch(orderSummaryProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orderSummaryProvider);
        await ref.refresh(myOrdersProvider.future).then((_) {}, onError: (_) {});
      },
      child: ListView(padding: const EdgeInsets.only(top: 8, bottom: 96), children: [
        summary.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (s) => s.ordersCount == 0 ? const SizedBox.shrink() : _SpendCard(summary: s),
        ),
        orders.when(
          loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
          data: (list) {
            final past = list.where((o) => !_active.contains(o.status)).toList();
            if (past.isEmpty) {
              return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No past orders yet', body: 'Completed, cancelled and refunded orders appear here');
            }
            return Column(children: [for (final o in past) _OrderRow(order: o)]);
          },
        ),
      ]),
    );
  }
}

class _SpendCard extends StatelessWidget {
  const _SpendCard({required this.summary});
  final OrderSummary summary;

  static const _names = serviceNames;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(GmRadius.lg)),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('You’ve spent', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(formatNaira(s.totalSpentKobo), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          Text('${s.ordersCount} paid order(s) · ${formatNaira(s.thisMonthSpentKobo)} this month'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final e in s.byVertical.entries)
              if (e.value.orders > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                  child: Text('${_names[e.key] ?? e.key}: ${formatNaira(e.value.spentKobo)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
          ]),
          if (s.refundedKobo > 0) ...[const SizedBox(height: 8), Text('Refunded: ${formatNaira(s.refundedKobo)}')],
        ]),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final icon = switch (o.vertical) {
      'parcel' => Icons.local_shipping_rounded,
      'waybill' => Icons.alt_route_rounded,
      _ => serviceCopy(o.vertical).icon,
    };
    final title = o.vertical == 'waybill' && o.waybill != null
        ? 'Waybill to ${o.waybill!.recipient.name}'
        : o.vertical == 'parcel' && o.parcel != null
            ? 'Package to ${o.parcel!.dropoff.name}'
            : o.restaurantName;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ListTile(
        onTap: () => context.push('/orders/${o.id}'),
        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(icon, color: brandRed)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        // Parcels show their progress in the chip; avoid saying it twice.
        subtitle: Text([
          '#${o.shortCode}',
          if (o.vertical != 'parcel') o.progress?.label ?? statusLabel(o.status),
          if (o.createdAt != null) formatLagosTime(o.createdAt),
        ].join(' · ')),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatNaira(o.breakdown?.totalKobo), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          StatusChip(o.status, label: ['parcel', 'waybill'].contains(o.vertical) ? o.progress?.label : null),
        ]),
      ),
    );
  }
}
