import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/home/home_screen.dart';
import 'package:gud_meal_customer/features/restaurant/restaurant_screen.dart';
import 'package:gud_meal_customer/features/vertical/vertical_screen.dart';
import 'package:gud_meal_customer/providers.dart';

/// Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, ADR-0025): six services on the home screen, service pages that say
/// what customers need to know, and shops browsed by the aisle.
const ada = GmUser(uid: 'u1', name: 'Ada Obi', email: 'ada@example.com');
const jollof = RestaurantCard(id: 'r-jollof', name: 'Jollof Junction', rating: 4.7, isOpen: true, isFeatured: true);
const market = RestaurantCard(
  id: 'm-lekki', vertical: 'market', name: 'Lekki Market Shopper', description: 'A shopper buys your foodstuff fresh at the market.',
  rating: 4.5, ratingCount: 760, isOpen: true, badge: 'Shopper',
);
const pharmacy = RestaurantCard(id: 'p-care', vertical: 'pharmacy', name: 'CareFirst Pharmacy', rating: 4.7, isOpen: true);

MenuItem product(String id, String name, int naira,
        {String? unit, bool available = true, int pop = 0, List<String> groups = const [], String kind = 'product'}) =>
    MenuItem(
      id: id, restaurantId: 'm-lekki', name: name, priceKobo: naira * 100, unitLabel: unit, emoji: '🧺', isAvailable: available,
      popularity: pop, optionGroupIds: groups, kind: kind,
    );

final marketDetail = RestaurantDetail(
  restaurant: market,
  address: 'Market road, Lekki Phase 1, Lagos',
  avgPrepMinutes: 35,
  sections: [
    MenuSection(category: const MenuCategory(id: 'combos', name: 'Soup & stew combos'), items: [
      product('c1', 'Egusi soup combo', 7500, pop: 310, kind: 'combo'),
    ]),
    MenuSection(category: const MenuCategory(id: 'grains', name: 'Rice, grains & garri'), items: [
      product('g1', 'Ijebu garri', 600, unit: 'derica', pop: 260),
      product('g2', 'Yam flour (elubo)', 6000, unit: 'half paint', pop: 180),
      product('g3', 'Local rice', 1500, unit: 'derica', pop: 240),
      product('g4', 'Honey beans', 1800, unit: 'derica', pop: 215),
    ]),
    MenuSection(category: const MenuCategory(id: 'meat', name: 'Meat (raw)'), items: [
      product('m1', 'Beef (raw)', 4200, unit: 'from 500 g', pop: 295, groups: ['weight']),
      product('m2', 'Goat meat', 9500, unit: '1 kg', available: false),
    ]),
  ],
  optionGroups: const {
    'weight': OptionGroup(id: 'weight', name: 'How much?', minSelect: 1, choices: [
      OptionChoice(id: '500g', name: '500 g'),
      OptionChoice(id: '1kg', name: '1 kg', priceDeltaKobo: 380000),
    ]),
  },
);

Future<void> pump(WidgetTester tester, Widget home, {List overrides = const []}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    for (final p in ['/food', '/groceries', '/pharmacy', '/market', '/beauty', '/send', '/checkout'])
      GoRoute(path: p, builder: (_, _) => Scaffold(body: Text('PAGE $p'))),
    GoRoute(path: '/restaurants/:id', builder: (_, s) => Scaffold(body: Text('STORE ${s.pathParameters['id']}'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(ada)), ...overrides],
    child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('a product shows "From" only when a choice the customer must make changes the price', () {
    // Beef by weight: 500 g is the listed price, 1 kg costs more.
    expect(listPrice(420000, [(minSelect: 1, deltas: [0, 380000])]), (kobo: 420000, from: true));
    // Eggs: the cheapest pack is not free of charge on top of the base price.
    expect(listPrice(100000, [(minSelect: 1, deltas: [50000, 300000])]), (kobo: 150000, from: true));
    // An optional extra, or a required choice that costs the same either way, leaves the price as it is.
    expect(listPrice(50000, [(minSelect: 0, deltas: [0, 20000])]), (kobo: 50000, from: false));
    expect(listPrice(50000, [(minSelect: 1, deltas: [0, 0, 0])]), (kobo: 50000, from: false));
    expect(listPrice(270000, const []), (kobo: 270000, from: false));
  });

  test('every service has its own words', () {
    // The owner's order (ADR-0025): Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff.
    expect([for (final s in merchantServices) s.id], ['food', 'pharmacy', 'beauty', 'grocery', 'market']);
    expect([for (final s in merchantServices) s.title], ['Order Food', 'Pharmacy', 'Beauty & Skin Care', 'Shop & Groceries', 'Buy Foodstuff']);
    expect(serviceCopy('market').steps, ['Placed', 'Accepted', 'Buying', 'On the way', 'Delivered']);
    expect(serviceCopy('pharmacy').note, contains('Over-the-counter products only'));
    expect(serviceCopy('grocery').isRetail && serviceCopy('market').isRetail && serviceCopy('pharmacy').isRetail, isTrue);
    expect(serviceCopy('food').isRetail || serviceCopy('beauty').isRetail, isFalse);
    expect(serviceCopy('something-new').id, 'food'); // an older app still shows something sensible
    expect(serviceNames['grocery'], 'Shop & Groceries');
    expect(serviceNames['market'], 'Buy Foodstuff');
  });

  testWidgets('home shows the six services; Pharmacy, Shop & Groceries and Buy Foodstuff open their pages', (tester) async {
    for (final (id, label, page) in [
      ('pharmacy', 'Pharmacy', '/pharmacy'),
      ('grocery', 'Shop & Groceries', '/groceries'),
      ('market', 'Buy Foodstuff', '/market'),
    ]) {
      await pump(tester, const HomeScreen(), overrides: [forYouProvider.overrideWith((ref) async => [jollof])]);
      for (final name in ['Order Food', 'Pharmacy', 'Beauty & Skin Care', 'Shop & Groceries', 'Buy Foodstuff', 'Package Delivery']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('bubble-$id')));
      await tester.pumpAndSettle();
      expect(find.text('PAGE $page'), findsOneWidget);
    }
  });

  testWidgets('the Pharmacy page says it is over-the-counter only and lists pharmacies', (tester) async {
    await pump(tester, const VerticalScreen(vertical: 'pharmacy'), overrides: [
      categoriesProvider.overrideWith((ref, v) async => const [BrowseCategory(id: 'pain', name: 'Pain & fever', emoji: '💊', merchants: 1)]),
      merchantsProvider.overrideWith((ref, q) async => [pharmacy]),
    ]);
    expect(find.text('Pharmacy'), findsOneWidget);
    expect(find.textContaining('Over-the-counter products only'), findsOneWidget);
    expect(find.text('Search in Pharmacy'), findsOneWidget);
    expect(find.text('Pain & fever'), findsOneWidget);
    expect(find.text('Health need'), findsOneWidget);
    expect(find.text('Popular pharmacies'), findsOneWidget);
    expect(find.text('All pharmacies'), findsOneWidget);
    expect(find.text('CareFirst Pharmacy'), findsWidgets);
  });

  test("the app reads the shop's own photo of an item", () {
    final item = MenuItem.fromJson({
      'id': 'i1', 'restaurant_id': 'r1', 'name': 'Pounded yam', 'price_kobo': 150000,
      'image_url': 'https://api.test/v1/media/public/restaurants/r1/items/i1-abc.jpg',
    });
    expect(item.imageUrl, endsWith('/i1-abc.jpg'));
    expect(MenuItem.fromJson({'id': 'i2', 'restaurant_id': 'r1', 'name': 'Eba', 'price_kobo': 80000}).imageUrl, isNull);
  });

  testWidgets("products and dishes show the shop's photo, and the emoji when there is none", (tester) async {
    const url = 'https://api.test/v1/media/public/restaurants/m-lekki/items/g1-abc.jpg';
    final withPhoto = RestaurantDetail(
      restaurant: market,
      address: 'Market road',
      avgPrepMinutes: 35,
      sections: [
        MenuSection(category: const MenuCategory(id: 'grains', name: 'Rice, grains & garri'), items: [
          product('g1', 'Ijebu garri', 600, unit: 'derica', pop: 260).copyWith(imageUrl: url),
          product('g3', 'Local rice', 1500, unit: 'derica', pop: 240),
        ]),
      ],
      optionGroups: const {},
    );
    await pump(tester, const RestaurantScreen(id: 'm-lekki'), overrides: [
      restaurantDetailProvider.overrideWith((ref, id) async => withPhoto),
    ]);
    final photo = find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url == url);
    expect(photo, findsWidgets);
    expect(find.text('🧺'), findsWidgets); // Local rice has no photo: its emoji shows
  });

  testWidgets('a market is browsed by the aisle: popular, measures, "From" prices, stock, view more, search', (tester) async {
    await pump(tester, const RestaurantScreen(id: 'm-lekki'), overrides: [
      restaurantDetailProvider.overrideWith((ref, id) async => marketDetail),
    ]);
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    expect(find.text('Shopper'), findsOneWidget);
    expect(find.textContaining('A shopper buys these fresh for you'), findsOneWidget);
    expect(find.textContaining('bought in ~35 min'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Browse all'), findsOneWidget);
    expect(find.text('From ₦4,200'), findsWidgets); // beef, by weight
    expect(find.text('derica'), findsWidgets); // a market measure, not a weight

    // Each aisle shows three products and a way to see the rest.
    await tester.scrollUntilVisible(find.text('View more (4)'), 250, scrollable: page);
    await tester.scrollUntilVisible(find.text('Out of stock'), 250, scrollable: page);
    expect(find.text('Goat meat'), findsOneWidget); // out of stock, still listed

    await tester.scrollUntilVisible(find.text('View more (4)'), -250, scrollable: page);
    await tester.tap(find.text('View more (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Rice, grains & garri'), findsOneWidget); // the aisle's own page
    expect(find.text('Lekki Market Shopper'), findsOneWidget);
    for (final name in ['Ijebu garri', 'Yam flour (elubo)', 'Local rice', 'Honey beans']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Search inside the shop.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('shop-search')), -400, scrollable: page);
    await tester.enterText(find.byKey(const ValueKey('shop-search')), 'beef');
    await tester.pumpAndSettle();
    expect(find.text('1 found'), findsOneWidget);
    expect(find.text('Popular'), findsNothing);
    expect(find.text('Beef (raw)'), findsOneWidget);

    // A product with a choice opens its options: the weight must be picked.
    await tester.tap(find.text('Beef (raw)'));
    await tester.pumpAndSettle();
    expect(find.text('How much? (required)'), findsOneWidget);
    expect(find.text('1 kg +₦3,800'), findsOneWidget);
  });
}
