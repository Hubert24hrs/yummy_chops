import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../restaurant/restaurant_screen.dart' show ItemSheet;
import 'cart_controller.dart';
import 'widgets/cart_widgets.dart';

/// The cart: items from any number of shops, grouped by shop, with "You might also like" and the way to checkout.
/// Seeing and changing the cart needs no account; checkout does. Prices here are estimates (the quote decides).
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty your cart?'),
        content: const Text('Every item from every shop is taken out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Empty cart')),
        ],
      ),
    );
    if (ok == true) ref.read(cartProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final shops = cart.shops;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const RoundBackButton(),
        leadingWidth: 64,
        centerTitle: true,
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: cart.isEmpty
          ? ListView(children: [
              const SizedBox(height: 24),
              EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your cart is empty',
                body: 'Add items from any shop: they all come together here and are paid at once.',
                action: FilledButton(onPressed: () => GoRouter.maybeOf(context)?.go('/'), child: const Text('Find something')),
              ),
            ])
          : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(children: [
                  const Expanded(child: BigTitle('Your cart')),
                  RoundIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Empty cart', onPressed: () => _confirmClear(context, ref)),
                ]),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: ProductsFrom(cart)),
              Divider(thickness: 6, color: theme.colorScheme.surfaceContainerHighest),
              for (final shop in shops) ...[
                if (shops.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      Icon(Icons.storefront_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(shop.restaurantName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                    ]),
                  ),
                for (final i in shop.items) _CartLineRow(key: ValueKey('cart-line-${i.key}'), item: i),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: SoftPillButton(
                      key: ValueKey('add-more-${shop.restaurantId}'),
                      label: 'Add more items',
                      onPressed: () => GoRouter.maybeOf(context)?.push('/restaurants/${shop.restaurantId}'),
                    ),
                  ),
                ),
              ],
              const _YouMightAlsoLike(),
            ]),
      bottomNavigationBar: cart.isEmpty
          ? null
          : StickyBottomBar(
              child: Row(children: [
                Expanded(
                  child: Text(formatNaira(cart.subtotalKobo),
                      key: const ValueKey('cart-total'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                ),
                FilledButton(
                  onPressed: () => GoRouter.maybeOf(context)?.push('/checkout'),
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 54), padding: const EdgeInsets.fromLTRB(24, 0, 16, 0)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Go to checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ]),
            ),
    );
  }
}

class _CartLineRow extends ConsumerWidget {
  const _CartLineRow({super.key, required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ItemThumb(emoji: item.emoji),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: theme.textTheme.titleMedium),
            if (item.selectionLabels.isNotEmpty)
              Text(item.selectionLabels.join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(formatNaira(item.unitPriceKobo * item.quantity), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        QuantityStepper(
          quantity: item.quantity,
          onChanged: (q) => ref.read(cartProvider.notifier).setQuantity(item.key, q),
        ),
      ]),
    );
  }
}

/// Popular products the cart's shops have in stock that are not in the cart yet.
class _YouMightAlsoLike extends ConsumerWidget {
  const _YouMightAlsoLike();

  static const _max = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final picks = <(MenuItem, RestaurantDetail)>[];
    for (final shop in cart.shops) {
      final d = ref.watch(restaurantDetailProvider(shop.restaurantId)).asData?.value;
      if (d == null || !d.restaurant.isOpen || !d.restaurant.isAcceptingOrders) continue;
      final inCart = cart.itemIdsOf(shop.restaurantId);
      for (final s in d.sections) {
        for (final item in s.items) {
          if (item.isAvailable && !inCart.contains(item.id)) picks.add((item, d));
        }
      }
    }
    if (picks.isEmpty) return const SizedBox.shrink();
    picks.sort((a, b) => b.$1.popularity.compareTo(a.$1.popularity));
    final shown = picks.take(_max).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeading('You might also like', padding: EdgeInsets.fromLTRB(20, 24, 20, 12)),
      SizedBox(
        height: 236,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _SuggestionCard(item: shown[i].$1, detail: shown[i].$2),
        ),
      ),
    ]);
  }
}

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.item, required this.detail});
  final MenuItem item;
  final RestaurantDetail detail;

  /// A product with a choice the customer must make opens its sheet; anything else goes straight in.
  void _add(BuildContext context, WidgetRef ref) {
    final r = detail.restaurant;
    final mustChoose = item.optionGroupIds.any((g) => (detail.optionGroups[g]?.minSelect ?? 0) > 0);
    if (mustChoose) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ItemSheet(item: item, groups: detail.optionGroups, restaurantId: r.id, restaurantName: r.name, goToCart: false),
      );
      return;
    }
    ref.read(cartProvider.notifier).add(
          r.id,
          r.name,
          CartItem(itemId: item.id, name: item.name, unitPriceKobo: item.priceKobo, quantity: 1, emoji: item.emoji),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _add(context, ref),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ItemThumb(emoji: item.emoji, size: 150),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                key: ValueKey('suggest-add-${item.id}'),
                tooltip: 'Add ${item.name}',
                onPressed: () => _add(context, ref),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(item.unitLabel == null ? item.name : '${item.name} · ${item.unitLabel}',
              maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(formatNaira(item.priceKobo), style: theme.textTheme.bodyMedium),
        ]),
      ),
    );
  }
}
