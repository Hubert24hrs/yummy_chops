import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../ui/components.dart';
import '../cart/cart_controller.dart';

/// A shop that sells products by the aisle (Shop & Groceries, Pharmacy, Buy Foodstuff), laid out the way people know
/// from supermarket and market delivery apps (ADR-0018): search, what's popular, the aisles, a few products per
/// aisle with "View more", sizes or market measures, "From" prices and out-of-stock labels.
class ShopView extends StatefulWidget {
  const ShopView({super.key, required this.detail, required this.canOrder, required this.onOpen});
  final RestaurantDetail detail;
  final bool canOrder;
  final void Function(MenuItem item) onOpen;

  @override
  State<ShopView> createState() => _ShopViewState();
}

/// In-stock products first (as listed), then the ones that are out of stock.
List<MenuItem> _inStockFirst(Iterable<MenuItem> items) =>
    [...items.where((i) => i.isAvailable), ...items.where((i) => !i.isAvailable)];

class _ShopViewState extends State<ShopView> {
  String _query = '';

  void _openAisle(MenuSection aisle) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AisleScreen(detail: widget.detail, aisle: aisle, canOrder: widget.canOrder, onOpen: widget.onOpen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final r = d.restaurant;
    final service = serviceCopy(r.vertical);
    final theme = Theme.of(context);
    final all = [for (final s in d.sections) ...s.items];
    final q = _query.trim().toLowerCase();
    final hits = q.length < 2
        ? const <MenuItem>[]
        : _inStockFirst(all.where((i) => '${i.name} ${i.unitLabel ?? ''} ${i.brand ?? ''}'.toLowerCase().contains(q)));
    final popular = ([...all.where((i) => i.isAvailable)]..sort((a, b) => b.popularity.compareTo(a.popularity))).take(8).toList();

    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 180,
        pinned: true,
        flexibleSpace: FlexibleSpaceBar(title: Text(r.name), background: MerchantArt(merchant: r, height: 220)),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.badge != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(r.badge!, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.secondary)),
                ]),
              ),
            Text(r.description),
            const SizedBox(height: 8),
            Text('${ratingPercent(r.rating)} positive (${r.ratingCount}) · ${service.readyIn} ~${d.avgPrepMinutes} min · ${d.address}',
                style: theme.textTheme.bodySmall),
            if (!widget.canOrder)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(r.isOpen ? 'Not taking orders right now' : 'Closed now — check back later',
                    style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700)),
              ),
            if (service.note != null) Padding(padding: const EdgeInsets.only(top: 12), child: ServiceNote(service.note!)),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('shop-search'),
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search in ${r.name}',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              ),
            ),
          ]),
        ),
      ),
      if (q.length >= 2) ...[
        SliverToBoxAdapter(child: SectionTitle(hits.isEmpty ? 'Nothing matches "$_query"' : '${hits.length} found')),
        _ProductGrid(items: hits, detail: d, canOrder: widget.canOrder, onOpen: widget.onOpen),
      ] else ...[
        if (popular.length >= 3) ...[
          const SliverToBoxAdapter(child: SectionTitle('Popular')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 196,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: popular.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(
                  width: 112,
                  child: ProductCard(item: popular[i], groups: d.optionGroups, service: service, enabled: widget.canOrder, onTap: () => widget.onOpen(popular[i])),
                ),
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Browse all', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), scrollDirection: Axis.horizontal, children: [
              for (final aisle in d.sections)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(label: Text(aisle.category.name), onPressed: () => _openAisle(aisle)),
                ),
            ]),
          ),
        ),
        for (final aisle in d.sections) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 2),
              child: Row(children: [
                Expanded(child: Text(aisle.category.name, style: theme.textTheme.titleLarge)),
                if (aisle.items.length > 3)
                  TextButton(onPressed: () => _openAisle(aisle), child: Text('View more (${aisle.items.length})')),
              ]),
            ),
          ),
          _ProductGrid(items: _inStockFirst(aisle.items).take(3).toList(), detail: d, canOrder: widget.canOrder, onOpen: widget.onOpen),
        ],
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ]);
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.items, required this.detail, required this.canOrder, required this.onOpen});
  final List<MenuItem> items;
  final RestaurantDetail detail;
  final bool canOrder;
  final void Function(MenuItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    final service = serviceCopy(detail.restaurant.vertical);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisExtent: 190,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            ProductCard(item: items[i], groups: detail.optionGroups, service: service, enabled: canOrder, onTap: () => onOpen(items[i])),
      ),
    );
  }
}

/// One product: its picture (or a placeholder), the price ("From ₦..." when a choice changes it), the name and
/// the size or market measure. Out-of-stock products stay listed, greyed out.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item, required this.groups, required this.service, required this.enabled, required this.onTap});
  final MenuItem item;
  final Map<String, OptionGroup> groups;
  final ServiceCopy service;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = listPrice(item.priceKobo, [
      for (final gid in item.optionGroupIds)
        if (groups[gid] case final g?) (minSelect: g.minSelect, deltas: [for (final c in g.choices) c.priceDeltaKobo]),
    ]);
    final priceText = '${price.from ? 'From ' : ''}${formatNaira(price.kobo)}';
    final available = item.isAvailable;
    return Semantics(
      button: true,
      enabled: enabled && available,
      label: [item.name, if (item.unitLabel != null) item.unitLabel!, priceText, if (!available) 'out of stock'].join(', '),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled && available ? onTap : null,
        child: Opacity(
          opacity: available ? 1 : .55,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Stack(children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
                    child: item.emoji != null
                        ? Text(item.emoji!, style: const TextStyle(fontSize: 38))
                        : Icon(service.icon, size: 34, color: theme.colorScheme.primary),
                  ),
                ),
                if (!available)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: theme.colorScheme.inverseSurface, borderRadius: BorderRadius.circular(999)),
                      child: Text('Out of stock', style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (enabled)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: Icon(Icons.add_rounded, size: 20, color: theme.colorScheme.onPrimary),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(priceText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(height: 1.2)),
                if (item.unitLabel != null)
                  Text(item.unitLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Everything in one aisle ("View more").
class AisleScreen extends ConsumerWidget {
  const AisleScreen({super.key, required this.detail, required this.aisle, required this.canOrder, required this.onOpen});
  final RestaurantDetail detail;
  final MenuSection aisle;
  final bool canOrder;
  final void Function(MenuItem item) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final shop = detail.restaurant;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(aisle.category.name),
          Text(shop.name, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      floatingActionButton: !cart.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/checkout'),
              icon: const Icon(Icons.shopping_bag_rounded),
              label: Text('View cart · ${formatNaira(cart.subtotalKobo)}'),
            )
          : null,
      body: CustomScrollView(slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        _ProductGrid(items: _inStockFirst(aisle.items), detail: detail, canOrder: canOrder, onOpen: onOpen),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ]),
    );
  }
}
