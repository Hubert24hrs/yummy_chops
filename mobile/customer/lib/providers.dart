import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Overridden in main() (Firebase) and in tests (fakes).
final configProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('override in main'));

final authStateProvider = StreamProvider<GmUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Who is signed in (null for a visitor). Until the first sign-in news arrives, it is who the app already knows.
final signedInUidProvider = Provider<String?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ref.watch(authStateProvider.select((state) => state.hasValue ? state.value?.uid : auth.currentUser?.uid));
});

final apiProvider = Provider<GudMealApi>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  // A new client for each user: everything read through it (orders, addresses, wallet...) is fetched again for
  // them. When a user leaves, `PerUserScope` in main() also throws away what was kept in memory, the cart included.
  ref.watch(signedInUidProvider);
  return GudMealApi(baseUrl: ref.watch(configProvider).apiUrl, token: auth.idToken);
});

final agentsApiProvider = Provider<GudMealAgentsApi>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return GudMealAgentsApi(baseUrl: ref.watch(configProvider).agentsUrl, token: auth.idToken);
});

// ------------------------------------------------------------------------------------------ where am I
/// A neighbourhood we deliver to (approximate centre; replaced by map pins once Google Maps is configured).
class Area {
  const Area(this.name, this.location, {this.city = 'lagos'});
  final String name;
  final GeoPoint location;
  final String city;

  String get cityName => city == 'enugu' ? 'Enugu' : 'Lagos';

  @override
  bool operator ==(Object other) => other is Area && other.name == name && other.city == city;

  @override
  int get hashCode => Object.hash(name, city);
}

/// Offline fallback; the live list comes from GET /v1/places/areas.
const lagosAreas = [
  Area('Lekki Phase 1', GeoPoint(lat: 6.4478, lng: 3.4723)),
  Area('Victoria Island', GeoPoint(lat: 6.4281, lng: 3.4219)),
  Area('Ikoyi', GeoPoint(lat: 6.4520, lng: 3.4350)),
  Area('Oniru', GeoPoint(lat: 6.4366, lng: 3.4517)),
  Area('Yaba', GeoPoint(lat: 6.5095, lng: 3.3711)),
  Area('Surulere', GeoPoint(lat: 6.4969, lng: 3.3602)),
  Area('Ikeja GRA', GeoPoint(lat: 6.5833, lng: 3.3500)),
];
const enuguAreas = [
  Area('Independence Layout', GeoPoint(lat: 6.4473, lng: 7.5214), city: 'enugu'),
  Area('Enugu GRA', GeoPoint(lat: 6.4590, lng: 7.5050), city: 'enugu'),
  Area('Trans-Ekulu', GeoPoint(lat: 6.4840, lng: 7.5160), city: 'enugu'),
  Area('New Haven', GeoPoint(lat: 6.4400, lng: 7.5150), city: 'enugu'),
];

final areasProvider = FutureProvider<List<Area>>((ref) async {
  try {
    final live = await ref.watch(apiProvider).areas();
    if (live.isNotEmpty) return [for (final a in live) Area(a.name, GeoPoint(lat: a.lat, lng: a.lng), city: a.city)];
  } on ApiException {
    // fall through to the built-in list
  }
  return const [...lagosAreas, ...enuguAreas];
});

class AreaController extends Notifier<Area> {
  @override
  Area build() => lagosAreas.first;
  void select(Area area) => state = area;
}

final areaProvider = NotifierProvider<AreaController, Area>(AreaController.new);

// ------------------------------------------------------------------------------------------ catalogue
final servicesProvider = FutureProvider<List<ServiceInfo>>((ref) {
  final city = ref.watch(areaProvider).city;
  return ref.watch(apiProvider).services(city: city);
});

final categoriesProvider = FutureProvider.family<List<BrowseCategory>, String>((ref, vertical) {
  final city = ref.watch(areaProvider).city;
  return ref.watch(apiProvider).categories(vertical, city: city);
});

typedef MerchantQuery = ({String vertical, String? category, bool pickup, String sort, String? query, String? cuisine});

final merchantsProvider = FutureProvider.family<List<RestaurantCard>, MerchantQuery>((ref, q) {
  final area = ref.watch(areaProvider);
  return ref.watch(apiProvider).restaurants(
        near: area.location,
        city: area.city,
        vertical: q.vertical,
        category: q.category,
        pickup: q.pickup,
        sort: q.sort,
        query: q.query,
        cuisine: q.cuisine,
      );
});

/// Kept for screens that only need nearby restaurants.
final restaurantsProvider = FutureProvider<List<RestaurantCard>>((ref) => ref.watch(merchantsProvider(recommended('food')).future));

/// "These are for you": the best nearby restaurants and shops of every kind, featured first.
MerchantQuery recommended(String vertical) =>
    (vertical: vertical, category: null, pickup: false, sort: 'recommended', query: null, cuisine: null);

final forYouProvider = FutureProvider<List<RestaurantCard>>((ref) async {
  final food = await ref.watch(merchantsProvider(recommended('food')).future);
  final beauty = await ref.watch(merchantsProvider(recommended('beauty')).future);
  // One of each new kind of shop too, so people find Pharmacy, Shop & Groceries and Buy Foodstuff from the home screen.
  final shops = <RestaurantCard>[];
  for (final service in const [groceryService, pharmacyService, marketService]) {
    final list = await ref.watch(merchantsProvider(recommended(service.id)).future).catchError((_) => <RestaurantCard>[]);
    shops.addAll(list.take(1));
  }
  final all = [...food.take(6), ...shops, ...beauty.take(3)];
  final open = all.where((r) => r.isOpen && r.isAcceptingOrders).toList()
    ..sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
  return open.isEmpty ? all : open;
});

typedef SearchQuery = ({String query, String? vertical});

/// Dishes/products and stores matching a search, near the selected area.
final searchProvider = FutureProvider.family<({List<Map<String, dynamic>> items, List<RestaurantCard> merchants}), SearchQuery>((ref, q) {
  return ref.watch(apiProvider).search(q.query, vertical: q.vertical, near: ref.watch(areaProvider).location);
});

final restaurantDetailProvider =FutureProvider.family<RestaurantDetail, String>((ref, id) {
  return ref.watch(apiProvider).restaurant(id, near: ref.watch(areaProvider).location);
});

// ------------------------------------------------------------------------------------------ me
/// Statuses of an order that is still on its way (the Orders tab's "In progress"): every `OrderStatus` of the API
/// (`domain/order_state.py`) except draft, completed, cancelled, refunded and partially refunded.
const activeOrderStatuses = {
  'pending_payment', 'paid', 'submitted_to_restaurant', 'restaurant_accepted', 'preparing',
  'ready_for_pickup', 'rider_assigned', 'picked_up', 'in_transit', 'delivered', 'disputed', 'refund_pending',
};

/// How often the orders list looks again while an order is in progress: its status moves on without the customer
/// doing anything (paid, accepted, picked up...), so a list read once would go stale.
const ordersRefreshInterval = Duration(seconds: 10);

/// The customer's orders. Read again whenever the Orders tab shows, when the app comes back to the front, right
/// after a checkout, every [ordersRefreshInterval] while one is in progress, and on pull-to-refresh.
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final orders = await ref.watch(apiProvider).myOrders();
  if (orders.any((o) => activeOrderStatuses.contains(o.status))) {
    final timer = Timer(ordersRefreshInterval, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return orders;
});
final orderProvider = FutureProvider.family<Order, String>((ref, id) => ref.watch(apiProvider).order(id));
final addressesProvider = FutureProvider<List<DeliveryAddress>>((ref) => ref.watch(apiProvider).addresses());
final orderSummaryProvider = FutureProvider<OrderSummary>((ref) => ref.watch(apiProvider).orderSummary());

/// The receipt of a paid order, and the receipts the customer has printed (ADR-0019).
final receiptProvider = FutureProvider.autoDispose.family<Receipt, String>((ref, orderId) => ref.watch(apiProvider).receipt(orderId));
final receiptsProvider = FutureProvider.autoDispose<List<Receipt>>((ref) => ref.watch(apiProvider).receipts());
final supportContactsProvider = FutureProvider<SupportContacts>((ref) => ref.watch(apiProvider).supportContacts());
final walletProvider = FutureProvider<WalletOverview>((ref) => ref.watch(apiProvider).wallet());

// ------------------------------------------------------------------------------------------ growth (phase 4)
final plusProvider = FutureProvider<PlusOverview>((ref) => ref.watch(apiProvider).plus());
final rewardsProvider = FutureProvider<RewardsOverview>((ref) => ref.watch(apiProvider).rewards());
final myVouchersProvider = FutureProvider<List<RewardVoucher>>((ref) => ref.watch(apiProvider).myVouchers());
final myGroupsProvider = FutureProvider<List<GroupOrder>>((ref) => ref.watch(apiProvider).myGroups());
final groupProvider = FutureProvider.family<GroupOrder, String>((ref, id) => ref.watch(apiProvider).group(id));
final whatsAppStatusProvider = FutureProvider<WhatsAppStatus>((ref) => ref.watch(apiProvider).whatsAppStatus());

/// Favourite stores (hearts). Kept on the device for now.
class FavouritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String merchantId) {
    final next = {...state};
    if (!next.remove(merchantId)) next.add(merchantId);
    state = next;
  }
}

final favouritesProvider = NotifierProvider<FavouritesController, Set<String>>(FavouritesController.new);

/// Light / dark / system appearance (Profile → App settings).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
