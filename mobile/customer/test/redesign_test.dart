import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/assistant/assistant_screen.dart';
import 'package:gud_meal_customer/features/home/home_screen.dart';
import 'package:gud_meal_customer/features/orders/orders_screen.dart';
import 'package:gud_meal_customer/features/parcel/parcel_screen.dart';
import 'package:gud_meal_customer/features/parcel/waybill_screen.dart';
import 'package:gud_meal_customer/features/vertical/vertical_screen.dart';
import 'package:gud_meal_customer/features/wallet/wallet_screen.dart';
import 'package:gud_meal_customer/providers.dart';
import 'package:gud_meal_customer/ui/gudy.dart';
import 'package:gud_meal_customer/ui/payment_picker.dart';

const ada = GmUser(uid: 'u1', name: 'Ada Obi', email: 'ada@example.com');
const jollof = RestaurantCard(
  id: 'r-jollof', name: 'Jollof Junction', cuisines: ['Nigerian'], area: 'Lekki', rating: 4.7, isOpen: true, isFeatured: true,
  etaMinutes: 35, deliveryFeeKobo: 90000, promotions: [PromoBadge(code: 'JOLLOF20', label: '20% off at Jollof Junction')],
);
const shea = RestaurantCard(id: 'b-shea', vertical: 'beauty', name: 'Shea Harbour Skin Bar', cuisines: ['Skincare'], rating: 4.8, isOpen: true, deliveryFeeKobo: 80000);

/// Fake API: records parcel quotes; never touches the network.
class FakeApi extends GudMealApi {
  FakeApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  final parcelRequests = <(ParcelStop, ParcelStop, String)>[];
  final codRequests = <int?>[];

  @override
  Future<ParcelQuote> parcelQuote({
    required ParcelStop pickup,
    required ParcelStop dropoff,
    required String size,
    required String category,
    String description = '',
    DateTime? scheduledFor,
    int? codAmountKobo,
  }) async {
    parcelRequests.add((pickup, dropoff, size));
    codRequests.add(codAmountKobo);
    final cod = codAmountKobo != null;
    return ParcelQuote(
      id: 'pq1',
      details: ParcelDetails(pickup: pickup, dropoff: dropoff, size: size, category: category, codAmountKobo: codAmountKobo),
      breakdown: cod
          ? const PriceBreakdown(subtotalKobo: 0, deliveryFeeKobo: 200000, serviceFeeKobo: 10000, codFeeKobo: 38000, vatKobo: 18600, totalKobo: 266600)
          : const PriceBreakdown(subtotalKobo: 0, deliveryFeeKobo: 200000, serviceFeeKobo: 10000, vatKobo: 15750, totalKobo: 225750),
      distanceKm: 5.2,
      etaMinutes: 48,
      estimatedDeliveryAt: DateTime.utc(2026, 11, 16, 13, 30),
      expiresAt: DateTime.utc(2026, 11, 16, 12, 45),
    );
  }

  @override
  Future<List<PlaceArea>> areas({String? city}) async => const [];

  @override
  Future<WalletOverview> wallet() async => const WalletOverview(balanceKobo: 500000);

  final waybillRequests = <(String, String, String, String, WaybillParty)>[];

  @override
  Future<List<WaybillOrigin>> waybillOrigins() async => const [
        WaybillOrigin(id: 'lagos', name: 'Lagos', homePickup: true, dropoffHubs: [WaybillHub(id: 'lagos-lekki', name: 'Yummy Chops Hub, Lekki', city: 'lagos')]),
        WaybillOrigin(id: 'enugu', name: 'Enugu', homePickup: true),
      ];

  @override
  Future<WaybillDestinations> waybillDestinations(String origin) async => const WaybillDestinations(
        dropoffHubs: [WaybillHub(id: 'lagos-lekki', name: 'Yummy Chops Hub, Lekki', city: 'lagos')],
        destinations: [
          WaybillDestination(city: 'enugu', name: 'Enugu', doorDelivery: true, fromKobo: 505300),
          WaybillDestination(
            city: 'abuja',
            name: 'Abuja',
            fromKobo: 559000,
            collectionHubs: [WaybillHub(id: 'abuja-utako', name: 'Partner terminal, Utako', city: 'abuja')],
          ),
        ],
      );

  @override
  Future<WaybillQuote> waybillQuote({
    required String originCity,
    required String destinationCity,
    required String firstMile,
    required String lastMile,
    String? originHubId,
    String? destinationHubId,
    required WaybillParty sender,
    required WaybillParty recipient,
    required String size,
    required double weightKg,
    required String category,
    String description = '',
    int? codAmountKobo,
  }) async {
    waybillRequests.add((originCity, destinationCity, firstMile, lastMile, recipient));
    return WaybillQuote(
      id: 'wq1',
      details: WaybillDetails(
        originCityName: 'Lagos',
        destinationCityName: 'Abuja',
        sender: sender,
        recipient: recipient,
        weightKg: weightKg,
        carrierName: 'Sample Carrier North',
      ),
      breakdown: const PriceBreakdown(subtotalKobo: 0, linehaulFeeKobo: 500000, serviceFeeKobo: 20000, vatKobo: 39000, totalKobo: 559000),
      etaText: 'Tue 17 Nov – Wed 18 Nov',
      expiresAt: DateTime.utc(2026, 11, 16, 12, 45),
    );
  }
}

const _wallet = WalletOverview(
  balanceKobo: 1250000,
  refundToWallet: true,
  transactions: [],
  seller: SellerSummary(codBalanceKobo: 2500000, availableKobo: 2500000),
);

/// Pumps [home] inside a router with stub destinations, so taps that navigate can be asserted.
Future<void> pumpRouted(WidgetTester tester, Widget home, {List overrides = const [], GmUser? user = ada}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    for (final p in ['/food', '/beauty', '/send', '/assistant', '/checkout', '/sign-in'])
      GoRoute(path: p, builder: (_, _) => Scaffold(body: Text('PAGE $p'))),
    GoRoute(path: '/restaurants/:id', builder: (_, s) => Scaffold(body: Text('STORE ${s.pathParameters['id']}'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(user)), ...overrides],
    child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows the six service bubbles and personal picks; tapping a bubble opens the service', (tester) async {
    await pumpRouted(tester, const HomeScreen(), overrides: [forYouProvider.overrideWith((ref) async => [jollof, shea])]);
    for (final name in ['Order Food', 'Pharmacy', 'Beauty & Skin Care', 'Shop & Groceries', 'Buy Foodstuff', 'Package Delivery']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('Ada, these are for you'), findsOneWidget);
    expect(find.text('Jollof Junction'), findsWidgets);
    expect(find.text('Promo'), findsOneWidget); // the deal shows as a tag on the shop's tile

    await tester.tap(find.byKey(const ValueKey('bubble-beauty')));
    await tester.pumpAndSettle();
    expect(find.text('PAGE /beauty'), findsOneWidget);
  });

  testWidgets('an account without a name gets the title without a stray comma', (tester) async {
    // Seen on a phone, 2026-11-26: ", these are for you" for a Google account with no display name.
    await pumpRouted(tester, const HomeScreen(),
        user: const GmUser(uid: 'u2', name: '', email: 'someone@example.com'),
        overrides: [forYouProvider.overrideWith((ref) async => [jollof])]);
    expect(find.text('These are for you'), findsOneWidget);
    expect(find.textContaining(', these are for you'), findsNothing);
  });

  testWidgets('bubbles follow the finger and spring back home when released', (tester) async {
    await pumpRouted(tester, const HomeScreen(), overrides: [forYouProvider.overrideWith((ref) async => [jollof])]);
    final bubble = find.byKey(const ValueKey('bubble-food'));
    final home = tester.getCenter(bubble);

    final gesture = await tester.startGesture(home);
    await gesture.moveBy(const Offset(20, 0));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(15, 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 100));
    final dragged = tester.getCenter(bubble);
    expect((dragged - home).distance, greaterThan(60), reason: 'bubble follows the drag');
    expect(find.text('PAGE /food'), findsNothing, reason: 'a drag is not a tap');

    await gesture.up();
    await tester.pumpAndSettle();
    expect((tester.getCenter(bubble) - home).distance, lessThan(2), reason: 'bubble springs back to its place');
  });

  testWidgets('the Food page shows categories, filters, popular brands and store cards', (tester) async {
    final categories = [
      const BrowseCategory(id: 'promotions', name: 'Promotions', emoji: '🏷️', merchants: 1),
      const BrowseCategory(id: 'local', name: 'Local food', emoji: '🍲', merchants: 1),
    ];
    await pumpRouted(tester, const VerticalScreen(vertical: 'food'), overrides: [
      categoriesProvider.overrideWith((ref, v) async => categories),
      merchantsProvider.overrideWith((ref, q) async => q.category == 'promotions' ? [jollof] : [jollof, const RestaurantCard(id: 'r-closed', name: 'Closed Kitchen', rating: 4.1)]),
    ]);
    expect(find.text('Search in Food'), findsOneWidget);
    expect(find.text('Local food'), findsOneWidget);
    expect(find.text('Food type'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Popular brands'), findsOneWidget);
    final page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(find.text('Closed now'), 300, scrollable: page);
    expect(find.text('Closed now'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Promotions'), -300, scrollable: page);

    await tester.tap(find.text('Promotions'));
    await tester.pumpAndSettle();
    expect(find.text('Closed Kitchen'), findsNothing);
    expect(find.text('20% off at Jollof Junction'), findsOneWidget);
    await tester.tap(find.text('Jollof Junction').last);
    await tester.pumpAndSettle();
    expect(find.text('STORE r-jollof'), findsOneWidget);
  });

  testWidgets('Yummy floats over the app and opens the chat when tapped', (tester) async {
    await pumpRouted(tester, Scaffold(body: LayoutBuilder(builder: (context, c) => Stack(children: [
          const SizedBox.expand(),
          GudyFab(bounds: c.biggest, onOpen: () => GoRouter.of(context).push('/assistant')),
        ]))));
    expect(find.text('Hi, I’m Yummy!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gudy-fab')));
    await tester.pumpAndSettle();
    expect(find.text('PAGE /assistant'), findsOneWidget);
  });

  test('Yummy navigation cards map to app routes', () {
    expect(routeForScreen('parcel', const {}), '/send');
    expect(routeForScreen('food', const {'category': 'local'}), '/food?category=local');
    expect(routeForScreen('merchant', const {'merchant_id': 'b-shea'}), '/restaurants/b-shea');
    expect(routeForScreen('order', const {'order_id': 'o1'}), '/orders/o1');
    expect(routeForScreen('merchant', const {}), isNull);
  });

  testWidgets('a guest sees the orders tab itself, with no sign-in prompt', (tester) async {
    await pumpRouted(tester, const OrdersScreen(), user: const GmUser(uid: 'guest-1', isAnonymous: true), overrides: [
      myOrdersProvider.overrideWith((ref) async => const <Order>[]),
      orderSummaryProvider.overrideWith((ref) async => const OrderSummary()),
    ]);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Track your orders'), findsOneWidget); // the empty list
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('orders tab shows empty states and the spending summary', (tester) async {
    await pumpRouted(tester, const OrdersScreen(), overrides: [
      myOrdersProvider.overrideWith((ref) async => const <Order>[]),
      orderSummaryProvider.overrideWith((ref) async => const OrderSummary(
            ordersCount: 3,
            totalSpentKobo: 2512550,
            thisMonthSpentKobo: 1200000,
            byVertical: {'food': VerticalSpend(orders: 2, spentKobo: 2286800), 'parcel': VerticalSpend(orders: 1, spentKobo: 225750)},
          )),
    ]);
    expect(find.text('Your ongoing orders will be listed here'), findsOneWidget);
    expect(find.text('No carts yet'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('₦25,125.50'), findsOneWidget);
    expect(find.text('Package Delivery: ₦2,257.50'), findsOneWidget);
  });

  testWidgets('package delivery validates the form, then shows the exact price before booking', (tester) async {
    final api = FakeApi();
    await pumpRouted(tester, const ParcelScreen(), overrides: [apiProvider.overrideWithValue(api)]);
    await tester.tap(find.byKey(const ValueKey('parcel-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the pickup street address'), findsOneWidget);

    Future<void> type(String label, String text, {int index = 0}) async {
      await tester.enterText(find.widgetWithText(TextField, label).at(index), text);
    }

    await type('Street address and landmark', '5 Bisola Durosinmi-Etti Drive');
    await type('Sender phone', '+2348011111111');
    await tester.tap(find.byType(DropdownButtonFormField<Area>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yaba, Lagos').last);
    await tester.pumpAndSettle();
    await type('Street address and landmark', '4 Herbert Macaulay Way', index: 1);
    await type('Recipient name', 'Ngozi');
    await type('Recipient phone', '+2348055555555');
    await tester.scrollUntilVisible(find.text('Medium'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Medium'));
    await tester.tap(find.byKey(const ValueKey('parcel-primary')));
    await tester.pumpAndSettle();

    final (pickup, dropoff, size) = api.parcelRequests.single;
    expect(pickup.name, 'Ada Obi');
    expect(dropoff.area, 'Yaba');
    expect(size, 'medium');
    expect(find.text('Book & pay ₦2,257.50'), findsOneWidget);
    expect(find.text('₦2,000'), findsOneWidget);
  });

  testWidgets('package delivery can collect cash from the buyer and shows the collection fee', (tester) async {
    final api = FakeApi();
    await pumpRouted(tester, const ParcelScreen(), overrides: [apiProvider.overrideWithValue(api)]);
    Future<void> type(String label, String text, {int index = 0}) async {
      await tester.enterText(find.widgetWithText(TextField, label).at(index), text);
    }

    await type('Street address and landmark', '5 Bisola Durosinmi-Etti Drive');
    await type('Sender phone', '+2348011111111');
    await tester.tap(find.byType(DropdownButtonFormField<Area>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yaba, Lagos').last);
    await tester.pumpAndSettle();
    await type('Street address and landmark', '4 Herbert Macaulay Way', index: 1);
    await type('Recipient name', 'Ngozi');
    await type('Recipient phone', '+2348055555555');
    final cod = find.byKey(const ValueKey('cod-switch'));
    // Scroll past the switch so it sits clear of the fixed bottom button.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('interstate-link')), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(cod);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('parcel-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the amount the rider should collect from your buyer'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('cod-amount')), '25000');
    await tester.tap(find.byKey(const ValueKey('parcel-primary')));
    await tester.pumpAndSettle();
    expect(api.codRequests.single, 2500000);
    await tester.scrollUntilVisible(find.text('Cash collection fee'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('₦380'), findsOneWidget);
    expect(find.text('The rider collects ₦25,000 from Ngozi for you.'), findsOneWidget);
    // Packages are prepaid: card or wallet, never cash at the door.
    expect(find.text('Yummy Chops wallet'), findsOneWidget);
    expect(find.text('Pay on delivery'), findsNothing);
  });

  testWidgets('payment picker explains why the wallet and pay on delivery are unavailable', (tester) async {
    var chosen = PayMethod.card;
    await pumpRouted(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => PaymentMethodPicker(
            totalKobo: 750000,
            value: chosen,
            onChanged: (m) => setState(() => chosen = m),
          ),
        ),
      ),
      overrides: [
        walletProvider.overrideWith((ref) async => const WalletOverview(balanceKobo: 500000)),
        orderSummaryProvider.overrideWith((ref) async => const OrderSummary(completedCount: 0)),
      ],
    );
    expect(find.text('Balance ₦5,000 · top up ₦2,500 more'), findsOneWidget);
    expect(find.text('Unlocks after your first order'), findsOneWidget);
    expect(find.text('Top up your wallet'), findsOneWidget);
    await tester.tap(find.text('Yummy Chops wallet'));
    await tester.pumpAndSettle();
    expect(chosen, PayMethod.card); // disabled options can't be picked
    expect(PayMethod.wallet.provider, 'wallet');
    expect(PayMethod.card.provider, isNull);
  });

  testWidgets('wallet shows the balance, refund setting and cash-on-delivery money', (tester) async {
    await pumpRouted(tester, const WalletScreen(), overrides: [walletProvider.overrideWith((ref) async => _wallet)]);
    expect(find.text('₦12,500'), findsOneWidget);
    await tester.tap(find.text('₦5,000'));
    await tester.pumpAndSettle();
    expect(find.text('Top up ₦5,000'), findsOneWidget);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Instant refunds to my wallet'), 200, scrollable: list);
    await tester.scrollUntilVisible(find.text('Cash-on-delivery money'), 200, scrollable: list);
    expect(find.text('₦25,000'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No wallet activity yet. Top up to pay for your next order in one tap.'), 200, scrollable: list);
  });

  testWidgets('interstate waybill: hub drop-off to Abuja for collection shows the price and expected dates', (tester) async {
    final api = FakeApi();
    await pumpRouted(tester, const WaybillScreen(), overrides: [apiProvider.overrideWithValue(api)]);
    await tester.tap(find.byKey(const ValueKey('waybill-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Choose where the package is going'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wb-to-lagos')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Abuja: from').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’ll drop it at a hub'));
    await tester.pumpAndSettle();
    expect(find.text('Not available in this city yet'), findsOneWidget); // no door delivery in Abuja yet
    await tester.enterText(find.widgetWithText(TextField, 'Sender phone'), '+2348011111111');
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Recipient phone'), 200, scrollable: list);
    await tester.enterText(find.widgetWithText(TextField, 'Recipient name'), 'Musa Bello');
    await tester.enterText(find.widgetWithText(TextField, 'Recipient phone'), '+2348077777777');
    await tester.tap(find.byKey(const ValueKey('waybill-primary')));
    await tester.pumpAndSettle();

    final (origin, destination, first, last, recipient) = api.waybillRequests.single;
    expect((origin, destination, first, last), ('lagos', 'abuja', 'dropoff', 'collect'));
    expect(recipient.location, isNull); // collection: no recipient address needed
    await tester.scrollUntilVisible(find.text('Expected Tue 17 Nov – Wed 18 Nov'), 200, scrollable: list);
    expect(find.text('₦5,590'), findsOneWidget);
    expect(find.text('Book & pay ₦5,590'), findsOneWidget);
    expect(find.text('Pay on delivery'), findsNothing);
  });
}
