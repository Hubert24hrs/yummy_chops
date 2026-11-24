import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/auth/sign_in_screen.dart';
import 'package:gud_meal_customer/features/cart/cart_controller.dart';
import 'package:gud_meal_customer/features/cart/checkout_screen.dart';
import 'package:gud_meal_customer/features/discover/discover_screen.dart';
import 'package:gud_meal_customer/features/home/home_screen.dart';
import 'package:gud_meal_customer/features/info/info_screens.dart';
import 'package:gud_meal_customer/features/location/address_picker.dart';
import 'package:gud_meal_customer/features/profile/profile_screen.dart';
import 'package:gud_meal_customer/providers.dart';
import 'package:gud_meal_customer/ui/components.dart';

/// Everything the website has is in the app too (owner's request of 2026-11-17): the home page's closing
/// sections, Google sign-in, the phone's current location, the profile's extras, the help centre, the two
/// sign-ups, package tracking and a Discover list of every kind of shop.
const ada = GmUser(uid: 'u1', name: 'Ada Obi', email: 'ada@example.com');
const lekki = Area('Lekki Phase 1', GeoPoint(lat: 6.4478, lng: 3.4723));
const yaba = Area('Yaba', GeoPoint(lat: 6.5095, lng: 3.3711));
const independence = Area('Independence Layout', GeoPoint(lat: 6.4473, lng: 7.5214), city: 'enugu');

class _Api extends GudMealApi {
  _Api() : super(baseUrl: 'http://fake', token: () async => 't');
  FoodPreferences preferences = const FoodPreferences(allergens: ['peanuts'], dietary: ['halal'], personalise: true);
  final businesses = <Map<String, dynamic>>[];
  final riders = <Map<String, dynamic>>[];
  bool serviceable = true;
  String precision = 'rooftop';

  @override
  Future<FoodPreferences> foodPreferences() async => preferences;

  @override
  Future<FoodPreferences> saveFoodPreferences(FoodPreferences p) async => preferences = p;

  @override
  Future<Map<String, dynamic>> exportMyData() async => {
        'profile': {'display_name': 'Ada Obi'},
        'orders': [
          {'id': 'o1'}
        ],
      };

  @override
  Future<void> applyAsBusiness(Map<String, dynamic> application) async => businesses.add(application);

  @override
  Future<void> applyAsRider(Map<String, dynamic> application) async => riders.add(application);

  @override
  Future<WaybillTracking> trackWaybill(String code) async {
    if (code != 'GMW2ABC3DEF') throw ApiException(404, 'not_found', 'Not found');
    return WaybillTracking(
      trackingCode: code,
      origin: 'Lagos',
      destination: 'Enugu',
      label: 'On the road to Enugu',
      etaText: 'Thu 19 Nov',
      milestones: [
        WaybillScan(stage: 'received', label: 'Received at the Lagos hub', at: DateTime.utc(2026, 11, 17, 9), place: 'Ikeja hub'),
        WaybillScan(stage: 'in_transit', label: 'Left Lagos', at: DateTime.utc(2026, 11, 17, 14)),
      ],
    );
  }

  @override
  Future<PlaceLookup> reverseGeocode(GeoPoint point) async => PlaceLookup(
        place: PlaceResult(formattedAddress: '12 Admiralty Way', location: point, area: 'Lekki Phase 1', city: 'lagos', precision: precision),
        serviceable: serviceable,
        city: 'lagos',
      );
}

class _Here implements CustomerLocation {
  _Here(this.point, {this.fails});
  final GeoPoint point;
  final String? fails;

  @override
  Future<GeoPoint> current() async {
    if (fails != null) throw LocationUnavailable(fails!);
    return point;
  }
}

Future<void> _pump(WidgetTester tester, Widget home, {List overrides = const [], AuthRepository? auth, _Api? api, bool tall = false}) async {
  // `tall`: a very long screen, so a whole form is laid out and nothing needs scrolling.
  tester.view.physicalSize = Size(1080, tall ? 7800 : 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    for (final p in ['/discover', '/assistant', '/support', '/partner-with-us', '/ride', '/help', '/track', '/receipts', '/orders', '/wallet', '/plus', '/rewards', '/group', '/sign-in'])
      GoRoute(path: p, builder: (_, _) => Scaffold(body: Text('PAGE $p'))),
    GoRoute(path: '/restaurants/:id', builder: (_, s) => Scaffold(body: Text('STORE ${s.pathParameters['id']}'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository(ada)),
      apiProvider.overrideWithValue(api ?? _Api()),
      areasProvider.overrideWith((ref) async => const [lekki, yaba, independence]),
      ...overrides,
    ],
    child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

Finder get page => find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

void main() {
  test('the nearest delivery area to a GPS position, or none when Yummy Chops is not there', () {
    const areas = [lekki, yaba, independence];
    expect(nearestArea(const GeoPoint(lat: 6.45, lng: 3.47), areas), lekki);
    expect(nearestArea(const GeoPoint(lat: 6.50, lng: 3.38), areas), yaba);
    expect(nearestArea(const GeoPoint(lat: 6.45, lng: 7.50), areas), independence);
    expect(nearestArea(const GeoPoint(lat: 9.07, lng: 7.40), areas), isNull); // Abuja
    expect(nearestArea(const GeoPoint(lat: 6.45, lng: 3.47), const []), isNull);
  });

  testWidgets('home is minimal: the six services and the picks, no banners or explanations', (tester) async {
    await _pump(tester, const HomeScreen(), overrides: [forYouProvider.overrideWith((ref) async => const <RestaurantCard>[])]);
    for (final service in ['Order Food', 'Pharmacy', 'Beauty & Skin Care', 'Shop & Groceries', 'Buy Foodstuff', 'Package Delivery']) {
      expect(find.text(service), findsOneWidget, reason: service);
    }
    for (final gone in ['Ask Yummy', 'Send a package', 'Yummy plans to your budget',
        'Transparent, safe payments', 'Live tracking to your door', 'Sell on Yummy Chops. Ride with Yummy Chops.']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    // "See all" beside the picks opens Discover.
    await _pump(tester, const HomeScreen(), overrides: [forYouProvider.overrideWith((ref) async => const <RestaurantCard>[])]);
    await tester.tap(find.byTooltip('See all'));
    await tester.pumpAndSettle();
    expect(find.text('PAGE /discover'), findsOneWidget);
  });

  testWidgets('Continue with Google signs the customer in', (tester) async {
    final auth = FakeAuthRepository();
    await _pump(tester, const SignInScreen(), auth: auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.email, 'google.user@example.com');
  });

  testWidgets('on the test server Continue with Google asks which Google address to use', (tester) async {
    final auth = FakeAuthRepository()..googleAsksForTestEmail = true;
    await _pump(tester, const SignInScreen(), auth: auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This is the test server'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a Google address, e.g. ada@gmail.com'), findsOneWidget);
    expect(auth.currentUser, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Google address'), 'Ada@Gmail.com ');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.email, 'ada@gmail.com');
  });

  testWidgets('the area picker sets the delivery area from the phone location', (tester) async {
    late WidgetRef ref;
    final opener = Consumer(builder: (context, r, _) {
      ref = r;
      return Scaffold(body: Center(child: FilledButton(onPressed: () => showAreaPicker(context, r), child: Text('Deliver to ${r.watch(areaProvider).name}'))));
    });
    await _pump(tester, opener, overrides: [customerLocationProvider.overrideWithValue(_Here(const GeoPoint(lat: 6.505, lng: 3.375)))]);
    await tester.tap(find.textContaining('Deliver to'));
    await tester.pumpAndSettle();
    expect(find.text('Finds the delivery area nearest to you'), findsOneWidget);
    await tester.tap(find.text('Use my current location'));
    await tester.pumpAndSettle();
    expect(ref.read(areaProvider), yaba);
    expect(find.text('Deliver to Yaba'), findsOneWidget);

    // Somewhere Yummy Chops does not deliver, or no GPS: the picker says so and stays open.
    for (final (here, message) in [
      (_Here(const GeoPoint(lat: 9.07, lng: 7.40)), 'Yummy Chops does not deliver where you are yet. Choose the area to deliver to.'),
      (_Here(const GeoPoint(lat: 0, lng: 0), fails: 'Location permission is off. Search for your address instead.'), 'Location permission is off. Search for your address instead.'),
    ]) {
      await _pump(tester, opener, overrides: [customerLocationProvider.overrideWithValue(here)]);
      await tester.tap(find.textContaining('Deliver to'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.text('Where should we deliver?'), findsOneWidget);
    }
  });

  testWidgets('checkout fills the delivery address from the phone location in one tap', (tester) async {
    final api = _Api();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(ada)),
      apiProvider.overrideWithValue(api),
      customerLocationProvider.overrideWithValue(_Here(const GeoPoint(lat: 6.4479, lng: 3.4725))),
      myVouchersProvider.overrideWith((ref) async => const <RewardVoucher>[]),
    ]);
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add('r-suya', 'Suya Lane', const CartItem(itemId: 'sl-beef', name: 'Beef suya', unitPriceKobo: 450000, quantity: 1));
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CheckoutScreen())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('checkout-use-my-location')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '12 Admiralty Way'), findsOneWidget); // the street is filled in
    expect(find.text('Pin your exact address'), findsNothing);

    api.serviceable = false;
    await tester.tap(find.byKey(const ValueKey('checkout-use-my-location')));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not deliver to where you are yet'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // let the button's press animation finish
  });

  testWidgets('the profile has what the website account page has', (tester) async {
    final api = _Api();
    await _pump(tester, const ProfileScreen(), api: api, tall: true, overrides: [
      walletProvider.overrideWith((ref) async => const WalletOverview(balanceKobo: 500000)),
    ]);
    for (final tile in ['My receipts', 'Food preferences', 'Track a package', 'Register your business', 'Ride with Yummy Chops', 'FAQ, privacy and terms', 'Download my data']) {
      await tester.scrollUntilVisible(find.text(tile), 200, scrollable: page);
      expect(find.text(tile), findsOneWidget, reason: tile);
    }

    // Food preferences: what is saved comes back, and changes are sent.
    await tester.scrollUntilVisible(find.text('Food preferences'), -200, scrollable: page);
    await tester.tap(find.text('Food preferences'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'peanuts'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'halal'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'peanuts'), 'Peanuts, Shellfish ,');
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    expect(api.preferences.allergens, ['peanuts', 'shellfish']);
    expect(api.preferences.dietary, ['halal']);
    expect(api.preferences.personalise, isFalse);
    expect(find.text('Preferences saved'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Download my data: everything held, to read and copy.
    await tester.scrollUntilVisible(find.text('Download my data'), 200, scrollable: page);
    await tester.tap(find.text('Download my data'));
    await tester.pumpAndSettle();
    expect(find.text('Everything Yummy Chops holds about you: profile, orders.'), findsOneWidget);
    expect(find.text('Copy my data'), findsOneWidget);
    expect(find.textContaining('"display_name": "Ada Obi"'), findsOneWidget);
  });

  testWidgets('the help centre answers the common questions and covers privacy and terms', (tester) async {
    await _pump(tester, const HelpScreen());
    expect(find.text('Help centre'), findsOneWidget);
    for (final (question, _) in helpFaqs) {
      expect(find.text(question), findsOneWidget, reason: question);
    }
    await tester.tap(find.text('How are fees calculated?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A 5% service fee (min ₦100, max ₦1,500)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Terms'), 200, scrollable: page);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.textContaining('Nigeria Data Protection Act 2023'), findsOneWidget);
    expect(find.textContaining('Full terms will be published before launch'), findsOneWidget);
  });

  testWidgets('a business applies to sell on Yummy Chops', (tester) async {
    final api = _Api();
    await _pump(tester, const BusinessApplyScreen(), api: api, tall: true);
    await tester.tap(find.text('Send application'));
    await tester.pumpAndSettle();
    expect(api.businesses, isEmpty); // nothing is sent until the form is complete
    expect(find.text('Enter your CAC registration number'), findsOneWidget);

    expect(find.textContaining('Account'), findsNothing); // bank details come later, in the partner dashboard
    for (final (label, value) in [
      ('Business name', 'Mama Nkechi Kitchen'), ('What you sell', 'Nigerian, Grills'), ('Address (main branch)', '4 Admiralty Way'),
      ('Your name', 'Nkechi Eze'), ('Phone number', '08031234567'), ('Email', 'hello@mamankechi.ng'), ('CAC number', 'RC123456'),
    ]) {
      await tester.enterText(find.widgetWithText(TextFormField, label), value);
    }
    // A second branch (ADR-0028): its own address, the same menu.
    await tester.tap(find.byKey(const ValueKey('add-branch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Branch 2 address'), '7 Ajose Adeogun Street');
    await tester.tap(find.text('Send application'));
    await tester.pumpAndSettle();
    expect(api.businesses.single, {
      'vertical': 'food', // a restaurant unless the business picks another kind
      'business_name': 'Mama Nkechi Kitchen', 'cac_number': 'RC123456', 'contact_name': 'Nkechi Eze', 'contact_phone': '08031234567',
      'email': 'hello@mamankechi.ng', 'address': '4 Admiralty Way', 'area': 'Lekki Phase 1', 'location': {'lat': 6.4478, 'lng': 3.4723},
      'branches': [
        {'address': '7 Ajose Adeogun Street', 'area': 'Lekki Phase 1', 'location': {'lat': 6.4478, 'lng': 3.4723}},
      ],
      'cuisines': ['nigerian', 'grills'],
    });
    expect(find.text('Application received'), findsOneWidget);
  });

  testWidgets('a pharmacy picks its kind of business and gives its PCN premises licence', (tester) async {
    final api = _Api();
    await _pump(tester, const BusinessApplyScreen(), api: api, tall: true);
    expect(find.text('PCN premises licence number'), findsNothing); // only pharmacies are asked
    await tester.tap(find.byKey(const ValueKey('business-kind')));
    await tester.pumpAndSettle();
    for (final kind in ['Restaurant (Order Food)', 'Beauty & Skin Care shop', 'Supermarket or store (Shop & Groceries)', 'Market shopper (Buy Foodstuff)']) {
      expect(find.text(kind), findsWidgets, reason: kind);
    }
    await tester.tap(find.text('Pharmacy').last);
    await tester.pumpAndSettle();
    for (final (label, value) in [
      ('Business name', 'Allen Avenue Pharmacy'), ('What you sell', 'Pain relief, Vitamins'), ('Address (main branch)', '12 Allen Avenue'),
      ('Your name', 'Tobi Ade'), ('Phone number', '08033333333'), ('CAC number', 'RC654321'),
    ]) {
      await tester.enterText(find.widgetWithText(TextFormField, label), value);
    }
    await tester.tap(find.text('Send application'));
    await tester.pumpAndSettle();
    expect(api.businesses, isEmpty); // a pharmacy cannot apply without its licence
    expect(find.text('Enter your PCN premises licence number'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'PCN premises licence number'), 'PCN/PR/12345');
    await tester.tap(find.text('Send application'));
    await tester.pumpAndSettle();
    expect(api.businesses.single['vertical'], 'pharmacy');
    expect(api.businesses.single['pcn_licence_number'], 'PCN/PR/12345');
    expect(find.text('Application received'), findsOneWidget);
  });

  testWidgets('a rider signs up with the same details as on the website (docs/adr/0027-rider-kyc.md)', (tester) async {
    final api = _Api();
    await _pump(tester, const RiderApplyScreen(), api: api);
    final signUp = find.text('Sign up as a rider');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();
    expect(api.riders, isEmpty);
    // The name and email come from the signed-in account; the WhatsApp number and the address are still missing.
    expect(find.text('Enter your WhatsApp number', skipOffstage: false), findsOneWidget);
    expect(find.text('Enter where you live', skipOffstage: false), findsOneWidget);
    expect(find.text('Ada Obi', skipOffstage: false), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Emeka Obi');
    await tester.enterText(find.widgetWithText(TextFormField, 'WhatsApp phone number'), '08039876543');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'emeka@gmail.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Residential address'), '12 Admiralty Way, Lekki');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();
    expect(api.riders.single, {
      'full_name': 'Emeka Obi',
      'phone': '08039876543',
      'email': 'emeka@gmail.com',
      'residential_address': '12 Admiralty Way, Lekki',
      'vehicle': 'motorcycle',
      'city': 'Lagos',
    });
    expect(find.text("You're signed up"), findsOneWidget);
    expect(find.textContaining('Yummy Chops Rider app'), findsOneWidget);
  });

  testWidgets('a package is tracked by its number without signing in', (tester) async {
    await _pump(tester, const TrackScreen(), auth: FakeAuthRepository());
    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter the tracking number on your waybill'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'gmw2abc3def');
    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();
    expect(find.text('Lagos → Enugu'), findsOneWidget);
    expect(find.text('On the road to Enugu'), findsOneWidget);
    expect(find.text('Expected Thu 19 Nov'), findsOneWidget);
    expect(find.textContaining('Received at the Lagos hub'), findsOneWidget);
    expect(find.textContaining('Ikeja hub'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'GMW9ZZZ9ZZZ');
    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();
    expect(find.text("We couldn't find that tracking number. Check it and try again."), findsOneWidget);
    expect(find.text('Lagos → Enugu'), findsNothing);
  });

  testWidgets('Discover lists every kind of shop in demand and names the service', (tester) async {
    String? asked;
    await _pump(tester, const DiscoverScreen(), overrides: [
      discoverFeedProvider.overrideWith((ref) async => const DiscoverFeed()),
      merchantsProvider.overrideWith((ref, q) async {
        asked = q.vertical;
        return const [
          RestaurantCard(id: 'r-jollof', name: 'Jollof Junction', rating: 4.7, ratingCount: 900, isOpen: true),
          RestaurantCard(id: 'g-fresh', vertical: 'grocery', name: 'FreshBasket Supermarket', rating: 4.6, ratingCount: 700, isOpen: true),
          RestaurantCard(id: 'm-lekki', vertical: 'market', name: 'Lekki Market Shopper', rating: 4.5, ratingCount: 600, isOpen: true),
        ];
      }),
    ]);
    expect(asked, 'all');
    await tester.scrollUntilVisible(find.text('Lekki Market Shopper'), 300, scrollable: page);
    expect(find.text('FreshBasket Supermarket'), findsOneWidget);
    expect(find.text('Shop & Groceries'), findsOneWidget);
    expect(find.text('Buy Foodstuff'), findsOneWidget);
  });
}
