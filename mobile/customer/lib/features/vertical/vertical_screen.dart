import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../widgets.dart';

const _sorts = {'recommended': 'Recommended', 'rating': 'Top rated', 'distance': 'Nearest', 'delivery_fee': 'Lowest delivery fee'};

/// A service page (Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff): search, category bubbles,
/// filters, popular shops, all shops.
class VerticalScreen extends ConsumerStatefulWidget {
  const VerticalScreen({super.key, required this.vertical, this.category});
  final String vertical;
  final String? category;

  @override
  ConsumerState<VerticalScreen> createState() => _VerticalScreenState();
}

class _VerticalScreenState extends ConsumerState<VerticalScreen> {
  late String? _category = widget.category;
  String? _cuisine;
  bool _pickup = false;
  String _sort = 'recommended';
  String _query = '';
  Timer? _debounce;

  bool get _food => widget.vertical == 'food';
  ServiceCopy get _service => serviceCopy(widget.vertical);
  String get _title => _service.title;

  MerchantQuery get _q => (
        vertical: widget.vertical,
        category: _category,
        pickup: _pickup,
        sort: _sort,
        query: _query.length >= 2 ? _query : null,
        cuisine: _cuisine,
      );

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _query = v.trim()));
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in _sorts.entries)
            ListTile(
              title: Text(e.value),
              trailing: e.key == _sort ? Icon(Icons.check_rounded, color: brandRed) : null,
              onTap: () => Navigator.pop(context, e.key),
            ),
        ]),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _pickCuisine(List<String> options) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          ListTile(title: const Text('Any'), onTap: () => Navigator.pop(context, '')),
          for (final c in options)
            ListTile(
              title: Text(c),
              trailing: c == _cuisine ? Icon(Icons.check_rounded, color: brandRed) : null,
              onTap: () => Navigator.pop(context, c),
            ),
        ]),
      ),
    );
    if (picked != null) setState(() => _cuisine = picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = ref.watch(categoriesProvider(widget.vertical));
    final merchants = ref.watch(merchantsProvider(_q));
    final all = ref.watch(merchantsProvider(recommended(widget.vertical)));
    final cuisines = {for (final m in all.value ?? const <RestaurantCard>[]) ...m.cuisines}.toList()..sort();
    final popular = [...(all.value ?? const <RestaurantCard>[])]..sort((a, b) => b.rating.compareTo(a.rating));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(tooltip: 'Back', onPressed: () => context.canPop() ? context.pop() : context.go('/'), icon: const Icon(Icons.arrow_back_rounded)),
                const Expanded(child: Center(child: AddressPill())),
                IconButton(
                  tooltip: 'Map of nearby ${_service.shops}',
                  onPressed: () => context.push('/map?vertical=${widget.vertical}'),
                  icon: const Icon(Icons.map_rounded),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(_title, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
            ),
          ),
          if (_service.note != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ServiceNote(_service.note!),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search in ${_service.searchIn}',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 124,
              child: cats.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
                data: (list) => ListView(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in list)
                      CategoryBubble(
                        label: c.name,
                        emoji: c.emoji,
                        selected: _category == c.id,
                        onTap: () => setState(() => _category = _category == c.id ? null : c.id),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: [
                FilterPill(
                  label: _cuisine ?? _service.typeFilter,
                  dropdown: true,
                  selected: _cuisine != null,
                  onTap: () => _pickCuisine(cuisines),
                ),
                FilterPill(label: 'Pickup', icon: Icons.directions_walk_rounded, selected: _pickup, onTap: () => setState(() => _pickup = !_pickup)),
                FilterPill(label: _sort == 'recommended' ? 'Sort by' : _sorts[_sort]!, dropdown: true, selected: _sort != 'recommended', onTap: _pickSort),
              ]),
            ),
          ),
          if (_query.length < 2 && _category == null && popular.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionTitle(_service.popular, info: 'Highest-rated near you')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 168,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.length.clamp(0, 10),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => BrandTile(merchant: popular[i], onTap: () => context.push('/restaurants/${popular[i].id}')),
                ),
              ),
            ),
          ],
          if (_query.length >= 2) SliverToBoxAdapter(child: _ItemHits(query: _query, vertical: widget.vertical)),
          SliverToBoxAdapter(
            child: SectionTitle(
              _category != null
                  ? (cats.value?.where((c) => c.id == _category).firstOrNull?.name ?? 'Results')
                  : _service.allShops,
            ),
          ),
          ...merchants.when(
            loading: () => [const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())))],
            error: (e, _) => [SliverToBoxAdapter(child: ErrorRetry(error: e, onRetry: () => ref.invalidate(merchantsProvider(_q))))],
            data: (list) => list.isEmpty
                ? [
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: _food ? Icons.ramen_dining_outlined : _service.icon,
                        title: 'No matches nearby',
                        body: 'Try another category, turn off filters, or change your area.',
                        action: OutlinedButton(
                          onPressed: () => setState(() {
                            _category = null;
                            _cuisine = null;
                            _pickup = false;
                          }),
                          child: const Text('Clear filters'),
                        ),
                      ),
                    ),
                  ]
                : [
                    SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => MerchantCard(merchant: list[i], onTap: () => context.push('/restaurants/${list[i].id}')),
                    ),
                  ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ]),
      ),
    );
  }
}

/// Dishes or products matching the search, across stores.
class _ItemHits extends ConsumerWidget {
  const _ItemHits({required this.query, required this.vertical});
  final String query;
  final String vertical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(searchProvider((query: query, vertical: vertical)));
    return Builder(
      builder: (context) {
        final items = found.value?.items ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(serviceCopy(vertical).items),
          for (final hit in items.take(6))
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(serviceCopy(vertical).icon, color: brandRed),
              ),
              title: Text('${(hit['item'] as Map)['name']}${(hit['item'] as Map)['unit_label'] != null ? ' · ${(hit['item'] as Map)['unit_label']}' : ''}'),
              subtitle: Text('${hit['restaurant_name']}'),
              trailing: Text(formatNaira((hit['item'] as Map)['price_kobo'] as int), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => context.push('/restaurants/${hit['restaurant_id']}'),
            ),
        ]);
      },
    );
  }
}
