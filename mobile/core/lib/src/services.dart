import 'package:flutter/material.dart';

/// How the apps name a merchant service and its shops (ADR-0018, names from ADR-0025). The API calls a service a
/// "vertical". The services, in the owner's order: Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy
/// Foodstuff (and Package Delivery, a courier job rather than a shop).
class ServiceCopy {
  const ServiceCopy({
    required this.id,
    required this.title,
    required this.searchIn,
    required this.route,
    required this.icon,
    required this.shops,
    required this.allShops,
    required this.popular,
    required this.items,
    required this.typeFilter,
    required this.readyIn,
    required this.steps,
    this.note,
  });

  /// The API's id: food, grocery, pharmacy, market or beauty.
  final String id;
  final String title;

  /// Short name for the search box: "Search in Groceries".
  final String searchIn;

  /// The service's page in the customer app.
  final String route;
  final IconData icon;

  /// "restaurants", "stores", "pharmacies", "markets", "shops".
  final String shops;

  /// "All restaurants", "All stores" ...
  final String allShops;

  /// "Popular brands", "Popular stores" ...
  final String popular;

  /// What the shop sells, for search results: "Dishes", "Products", "Foodstuff".
  final String items;

  /// The label of the filter by what a shop carries: "Food type", "Department" ...
  final String typeFilter;

  /// "ready in", "packed in", "bought in" (before "~12 min").
  final String readyIn;

  /// The five steps of an order's timeline.
  final List<String> steps;

  /// Something customers should know before they shop, shown on the shop's page.
  final String? note;

  /// Shops that sell products by the aisle: their pages show aisles, sizes and stock instead of a menu.
  bool get isRetail => const {'grocery', 'pharmacy', 'market'}.contains(id);
}

const _packing = ['Placed', 'Accepted', 'Packing', 'On the way', 'Delivered'];

const foodService = ServiceCopy(
  id: 'food',
  title: 'Order Food',
  searchIn: 'Food',
  route: '/food',
  icon: Icons.restaurant_rounded,
  shops: 'restaurants',
  allShops: 'All restaurants',
  popular: 'Popular brands',
  items: 'Dishes',
  typeFilter: 'Food type',
  readyIn: 'ready in',
  steps: ['Placed', 'Accepted', 'Preparing', 'On the way', 'Delivered'],
);

const groceryService = ServiceCopy(
  id: 'grocery',
  title: 'Shop & Groceries',
  searchIn: 'Groceries',
  route: '/groceries',
  icon: Icons.local_grocery_store_rounded,
  shops: 'stores',
  allShops: 'All stores',
  popular: 'Popular stores',
  items: 'Products',
  typeFilter: 'Department',
  readyIn: 'packed in',
  steps: _packing,
);

const pharmacyService = ServiceCopy(
  id: 'pharmacy',
  title: 'Pharmacy',
  searchIn: 'Pharmacy',
  route: '/pharmacy',
  icon: Icons.local_pharmacy_rounded,
  shops: 'pharmacies',
  allShops: 'All pharmacies',
  popular: 'Popular pharmacies',
  items: 'Products',
  typeFilter: 'Health need',
  readyIn: 'packed in',
  steps: _packing,
  note: 'Over-the-counter products only. For prescription medicines, take your prescription to a pharmacy.',
);

const marketService = ServiceCopy(
  id: 'market',
  title: 'Buy Foodstuff',
  searchIn: 'Foodstuff',
  route: '/market',
  icon: Icons.shopping_basket_rounded,
  shops: 'markets',
  allShops: 'All markets',
  popular: 'Popular markets',
  items: 'Foodstuff',
  typeFilter: 'Foodstuff type',
  readyIn: 'bought in',
  steps: ['Placed', 'Accepted', 'Buying', 'On the way', 'Delivered'],
  note: 'A shopper buys these fresh for you at the market. Sizes are market measures: derica, paint, bunch.',
);

const beautyService = ServiceCopy(
  id: 'beauty',
  title: 'Beauty & Skin Care',
  searchIn: 'Beauty',
  route: '/beauty',
  icon: Icons.spa_rounded,
  shops: 'shops',
  allShops: 'All shops',
  popular: 'Popular shops',
  items: 'Products',
  typeFilter: 'Product type',
  readyIn: 'packed in',
  steps: _packing,
);

/// The merchant services in the order the home screen shows them (Package Delivery is a courier job, not a shop).
const merchantServices = [foodService, pharmacyService, beautyService, groceryService, marketService];

/// The copy for [vertical]; unknown services read like Food, so an older app still shows something sensible.
ServiceCopy serviceCopy(String vertical) =>
    merchantServices.firstWhere((s) => s.id == vertical, orElse: () => foodService);

/// Names of every kind of order, for spending summaries and order lists.
const serviceNames = {
  'food': 'Order Food',
  'pharmacy': 'Pharmacy',
  'beauty': 'Beauty & Skin Care',
  'grocery': 'Shop & Groceries',
  'market': 'Buy Foodstuff',
  'parcel': 'Package Delivery',
  'waybill': 'Interstate',
};

/// The price to show on a product: its lowest real price, and whether it starts "From" because a choice the
/// customer must make can cost more (beef by weight, eggs by the crate). Mirrors how the server prices a line.
({int kobo, bool from}) listPrice(int priceKobo, Iterable<({int minSelect, List<int> deltas})> groups) {
  var lowest = priceKobo;
  var from = false;
  for (final g in groups) {
    if (g.minSelect <= 0 || g.deltas.isEmpty) continue;
    final sorted = [...g.deltas]..sort();
    lowest += sorted.take(g.minSelect).fold(0, (a, b) => a + b);
    if (sorted.last > sorted.first) from = true;
  }
  return (kobo: lowest, from: from);
}
