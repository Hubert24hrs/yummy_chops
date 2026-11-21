import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../widgets.dart';
import '../cart/cart_controller.dart';
import '../group/group_screens.dart' show StartGroupSheet;
import 'shop_view.dart';

class RestaurantScreen extends ConsumerStatefulWidget {
  /// [initialItemId] opens that dish straight away (e.g. "Order food" on a Discover dish).
  const RestaurantScreen({super.key, required this.id, this.initialItemId});
  final String id;
  final String? initialItemId;

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  bool _openedInitialItem = false;

  void _openItem(MenuItem item, RestaurantDetail d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemSheet(item: item, groups: d.optionGroups, restaurantId: d.restaurant.id, restaurantName: d.restaurant.name),
    );
  }

  /// Opens [RestaurantScreen.initialItemId] once, after the menu has loaded, if it can be ordered now.
  void _maybeOpenInitialItem(RestaurantDetail d) {
    final wanted = widget.initialItemId;
    if (wanted == null || _openedInitialItem) return;
    _openedInitialItem = true;
    final r = d.restaurant;
    final item = [for (final s in d.sections) ...s.items].where((i) => i.id == wanted).firstOrNull;
    if (item == null || !item.isAvailable || !r.isOpen || !r.isAcceptingOrders) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openItem(item, d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final detail = ref.watch(restaurantDetailProvider(id));
    final cart = ref.watch(cartProvider);
    return Scaffold(
      floatingActionButton: cart.restaurantId == id && !cart.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/checkout'),
              icon: const Icon(Icons.shopping_bag_rounded),
              label: Text('View order · ${formatNaira(cart.subtotalKobo)}'),
            )
          : null,
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(restaurantDetailProvider(id))),
        data: (d) {
          final r = d.restaurant;
          final canOrder = r.isOpen && r.isAcceptingOrders;
          _maybeOpenInitialItem(d);
          // Supermarkets, pharmacies and markets are browsed by the aisle, not as a menu.
          if (serviceCopy(r.vertical).isRetail) {
            return ShopView(detail: d, canOrder: canOrder, onOpen: (item) => _openItem(item, d));
          }
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(title: Text(r.name), background: MerchantArt(merchant: r, height: 220)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.description),
                  const SizedBox(height: 8),
                  Text('${ratingPercent(r.rating)} positive (${r.ratingCount}) · ${serviceCopy(r.vertical).readyIn} ~${d.avgPrepMinutes} min · ${d.address}',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (canOrder)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton.icon(
                        key: const ValueKey('order-with-friends'),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => StartGroupSheet(restaurantId: r.id),
                        ),
                        icon: const Icon(Icons.groups_rounded),
                        label: const Text('Order with friends'),
                      ),
                    ),
                  if (!canOrder)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(r.isOpen ? 'Not taking orders right now' : 'Closed now — check back later',
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ),
            ),
            for (final section in d.sections) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(section.category.name, style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              SliverList.builder(
                itemCount: section.items.length,
                itemBuilder: (_, i) {
                  final item = section.items[i];
                  return ListTile(
                    enabled: canOrder && item.isAvailable,
                    title: Text(item.unitLabel == null ? item.name : '${item.name} · ${item.unitLabel}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([formatNaira(item.priceKobo), if (item.serves > 1) 'Serves ${item.serves}', if (!item.isAvailable) 'Sold out'].join(' · ')),
                    trailing: const Icon(Icons.add_circle_rounded),
                    onTap: () => _openItem(item, d),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ]);
        },
      ),
    );
  }
}

class ItemSheet extends ConsumerStatefulWidget {
  const ItemSheet({
    super.key,
    required this.item,
    required this.groups,
    required this.restaurantId,
    required this.restaurantName,
    this.onAdd,
  });
  final MenuItem item;
  final Map<String, OptionGroup> groups;
  final String restaurantId;
  final String restaurantName;

  /// Group orders: hand the chosen line to the caller instead of adding it to this phone's cart.
  final void Function(CartLine line)? onAdd;

  @override
  ConsumerState<ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<ItemSheet> {
  final Map<String, List<String>> _chosen = {};
  int _qty = 1;

  void _toggle(OptionGroup g, String id) => setState(() {
        final current = [...(_chosen[g.id] ?? const <String>[])];
        if (g.maxSelect == 1) {
          _chosen[g.id] = [id];
        } else if (current.contains(id)) {
          _chosen[g.id] = current..remove(id);
        } else if (current.length < g.maxSelect) {
          _chosen[g.id] = current..add(id);
        }
      });

  void _add() {
    final item = widget.item;
    final groups = [for (final gid in item.optionGroupIds) if (widget.groups[gid] != null) widget.groups[gid]!];
    final cartItem = CartItem(
      itemId: item.id,
      name: item.name,
      unitPriceKobo: item.priceKobo + optionsPriceKobo(item, widget.groups, _chosen),
      quantity: _qty,
      selections: [for (final g in groups) if ((_chosen[g.id] ?? []).isNotEmpty) OptionSelection(groupId: g.id, choiceIds: _chosen[g.id]!)],
      selectionLabels: [
        for (final g in groups)
          for (final cid in _chosen[g.id] ?? const <String>[]) '${g.name}: ${g.choices.firstWhere((c) => c.id == cid).name}',
      ],
    );
    if (widget.onAdd != null) {
      Navigator.pop(context);
      widget.onAdd!(CartLine(itemId: item.id, quantity: _qty, selections: cartItem.selections));
      return;
    }
    final cart = ref.read(cartProvider.notifier);
    if (!cart.add(widget.restaurantId, widget.restaurantName, cartItem)) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start a new cart?'),
          content: Text('Your cart has items from ${ref.read(cartProvider).restaurantName}.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep cart')),
            FilledButton(
              onPressed: () {
                cart.add(widget.restaurantId, widget.restaurantName, cartItem, replace: true);
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('New cart'),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final error = validateSelections(item, widget.groups, _chosen);
    final unit = item.priceKobo + optionsPriceKobo(item, widget.groups, _chosen);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 12),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.unitLabel == null ? item.name : '${item.name} · ${item.unitLabel}', style: Theme.of(context).textTheme.headlineSmall),
            if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.description)),
            if (item.allergens.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Contains: ${item.allergens.join(', ')}', style: Theme.of(context).textTheme.bodySmall)),
            for (final gid in item.optionGroupIds)
              if (widget.groups[gid] case final g?) ...[
                const SizedBox(height: 16),
                Text('${g.name}${g.minSelect > 0 ? ' (required)' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Wrap(spacing: 8, children: [
                  for (final c in g.choices)
                    FilterChip(
                      label: Text(c.priceDeltaKobo > 0 ? '${c.name} +${formatNaira(c.priceDeltaKobo)}' : c.name),
                      selected: (_chosen[g.id] ?? const []).contains(c.id),
                      onSelected: c.isAvailable ? (_) => _toggle(g, c.id) : null,
                    ),
                ]),
              ],
            const SizedBox(height: 16),
            Row(children: [
              IconButton.outlined(tooltip: 'Fewer', onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$_qty', style: Theme.of(context).textTheme.titleLarge)),
              IconButton.outlined(tooltip: 'More', onPressed: _qty < 20 ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add)),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: error == null ? _add : null, child: Text('Add · ${formatNaira(unit * _qty)}'))),
            ]),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error, style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ),
      ),
    );
  }
}
