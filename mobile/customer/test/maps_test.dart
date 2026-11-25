import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/cart/cart_controller.dart';
import 'package:gud_meal_customer/features/cart/checkout_screen.dart';
import 'package:gud_meal_customer/features/location/address_picker.dart';
import 'package:gud_meal_customer/features/location/nearby_map_screen.dart';
import 'package:gud_meal_customer/features/orders/order_screen.dart';
import 'package:gud_meal_customer/providers.dart';
import 'package:gud_meal_customer/ui/gm_map.dart';

const admiralty = GeoPoint(lat: 6.4478, lng: 3.4723);
const yaba = GeoPoint(lat: 6.5095, lng: 3.3711);

/// The maps endpoints, faked. Records what the screens asked for; never hits the network.
class MapsApi extends GudMealApi {
  MapsApi() : super(baseUrl: 'http://fake', token: () async => 'tok');

  final searches = <(String, String)>[];
  final details = <(String, String?)>[];
  final reversed = <GeoPoint>[];
  final quoted = <DeliveryAddress?>[];
  var trackingCalls = 0;
  bool serviceable = true;
  late LiveTracking live;

  @override
  Future<List<PlaceSuggestion>> placeSuggestions(String query, {required String session, GeoPoint? near, String? city}) async {
    searches.add((query, session));
    return const [PlaceSuggestion(placeId: 'ChIJ-admiralty', title: '5 Admiralty Way', subtitle: 'Lekki Phase 1, Lagos', distanceM: 900, source: 'google')];
  }

  @override
  Future<PlaceLookup> placeDetails(String placeId, {String? session}) async {
    details.add((placeId, session));
    return PlaceLookup(
      place: PlaceResult(
        placeId: placeId,
        formattedAddress: '5 Admiralty Way, Lekki Phase 1, Lagos',
        location: admiralty,
        area: 'Lekki Phase 1',
        city: 'lagos',
        precision: 'rooftop',
        source: 'google',
      ),
      serviceable: serviceable,
      zone: serviceable ? 'island' : null,
      city: 'lagos',
    );
  }

  @override
  Future<PlaceLookup> reverseGeocode(GeoPoint point) async {
    reversed.add(point);
    return PlaceLookup(
      place: PlaceResult(formattedAddress: 'Near Yaba, Lagos', location: point, area: 'Yaba', city: 'lagos', precision: 'area', source: 'local'),
      serviceable: true,
      zone: 'mainland',
      city: 'lagos',
    );
  }

  @override
  Future<List<DeliveryAddress>> addresses() async => const [];

  @override
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher, DateTime? scheduledFor}) async {
    quoted.add(address);
    return Quote(
      id: 'q1', restaurantName: 'Suya Lane', fulfillment: fulfillment, etaMinutes: 35,
      breakdown: const PriceBreakdown(subtotalKobo: 900000, deliveryFeeKobo: 150000, serviceFeeKobo: 45000, vatKobo: 14625, totalKobo: 1109625),
      estimatedDeliveryAt: DateTime.utc(2026, 11, 15, 19, 30), expiresAt: DateTime.utc(2026, 11, 15, 19, 0),
    );
  }

  @override
  Future<WalletOverview> wallet() async => const WalletOverview(balanceKobo: 0);

  @override
  Future<OrderSummary> orderSummary() async => const OrderSummary(completedCount: 1);

  @override
  Future<List<RewardVoucher>> myVouchers() async => const [];

  @override
  Future<PlusOverview> plus() async => const PlusOverview(plan: PlusPlan(priceKobo: 150000), member: true);

  @override
  Future<LiveTracking> liveTracking(String orderId) async {
    trackingCalls++;
    return live;
  }

  @override
  Future<List<MapPlace>> nearbyOnMap({required GeoPoint near, String vertical = 'food', bool openNow = false, int limit = 30}) async => const [
        MapPlace(id: 'r-jollof', name: 'Jollof Junction', location: GeoPoint(lat: 6.4490, lng: 3.4730), area: 'Lekki Phase 1', rating: 4.7, isOpen: true, etaMinutes: 28, distanceKm: 0.3),
        MapPlace(id: 'r-suya', name: 'Suya Lane', location: GeoPoint(lat: 6.4310, lng: 3.4210), area: 'Victoria Island', rating: 4.8, isOpen: true, etaMinutes: 41, distanceKm: 5.6),
        MapPlace(id: 'r-amala', name: "Mama Ayo's Kitchen", location: GeoPoint(lat: 6.5090, lng: 3.3710), area: 'Yaba', rating: 4.6, etaMinutes: 55, distanceKm: 12.4),
      ];
}

class FakeLocation implements CustomerLocation {
  FakeLocation(this.result);
  final Object result;
  var asked = 0;

  @override
  Future<GeoPoint> current() async {
    asked++;
    final r = result;
    if (r is LocationUnavailable) throw r;
    return r as GeoPoint;
  }
}

ProviderContainer _container(MapsApi api, {CustomerLocation? location}) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
    apiProvider.overrideWithValue(api),
    if (location != null) customerLocationProvider.overrideWithValue(location),
  ]);
  addTearDown(c.dispose);
  return c;
}

Widget _app(ProviderContainer c, Widget home) =>
    UncontrolledProviderScope(container: c, child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: home));

void main() {
  testWidgets('checkout pins the exact address from search and quotes with that pin', (tester) async {
    tester.view.physicalSize = const Size(1080, 5400); // the whole checkout on screen
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final api = MapsApi();
    final c = _container(api);
    c.read(cartProvider.notifier).add('r-suya', 'Suya Lane', const CartItem(itemId: 'sl-beef', name: 'Beef Suya', unitPriceKobo: 450000, quantity: 2));
    await tester.pumpWidget(_app(c, const CheckoutScreen()));

    await tester.tap(find.text('Pin your exact address'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Search street, estate or landmark'), 'Admiralty');
    await tester.pump(const Duration(milliseconds: 400)); // debounce
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 Admiralty Way'));
    await tester.pumpAndSettle();

    expect(find.text('Yummy Chops delivers here'), findsOneWidget);
    expect(find.byType(SchematicMap), findsOneWidget); // no key in tests: schematic map
    // One billing session: the search and the pick share a token.
    expect(api.searches.single.$2, api.details.single.$2);
    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();

    // The new address is priced straight away: no button to press.
    expect(find.byTooltip('Change address'), findsOneWidget);
    await tester.pumpAndSettle();
    final sent = api.quoted.single!;
    expect(sent.location, admiralty);
    expect(sent.line1, '5 Admiralty Way, Lekki Phase 1, Lagos');
    expect(sent.area, 'Lekki Phase 1');
  });

  testWidgets('use my location asks once, keeps the device fix and needs a street for an area-level pin', (tester) async {
    final api = MapsApi();
    final location = FakeLocation(yaba);
    final c = _container(api, location: location);
    PickedAddress? result;
    await tester.pumpWidget(_app(
      c,
      Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () async => result = await pickDeliveryAddress(context), child: const Text('open')))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use my current location'));
    await tester.pumpAndSettle();
    expect(location.asked, 1);
    expect(api.reversed.single, yaba);
    expect(find.textContaining('This is the neighbourhood centre'), findsOneWidget);

    await tester.tap(find.text('Use this address'));
    await tester.pump();
    expect(find.text('Add your street and house number so the rider can find you'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Street and house number'), '12 Herbert Macaulay Way');
    final landmark = find.widgetWithText(TextField, 'Landmark or directions (optional)');
    await tester.scrollUntilVisible(landmark, 80, scrollable: find.byType(Scrollable).first);
    await tester.enterText(landmark, 'Opposite the filling station');
    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();
    expect(result!.address.location, yaba); // the device's own fix, never a made-up point
    expect(result!.address.line1, '12 Herbert Macaulay Way');
    expect(result!.address.instructions, 'Opposite the filling station');
    expect(result!.precise, isFalse);
  });

  testWidgets('location problems are explained and outside-area addresses cannot be used', (tester) async {
    final api = MapsApi()..serviceable = false;
    final c = _container(api, location: FakeLocation(const LocationUnavailable('Location permission is off. Search for your address instead.')));
    await tester.pumpWidget(_app(c, const AddressPickerScreen()));

    await tester.tap(find.text('Use my current location'));
    await tester.pumpAndSettle();
    expect(find.text('Location permission is off. Search for your address instead.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Search street, estate or landmark'), 'Admiralty');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 Admiralty Way'));
    await tester.pumpAndSettle();
    expect(find.text('Outside our delivery area for now'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use this address'));
    expect(button.onPressed, isNull);
    expect(find.text('Choose another address'), findsOneWidget);
  });

  testWidgets('live delivery map shows the rider and says whether the time is measured', (tester) async {
    final api = MapsApi()
      ..live = const LiveTracking(
        orderId: 'o1',
        status: 'in_transit',
        riderName: 'Musa',
        riderLocation: GeoPoint(lat: 6.4400, lng: 3.4500),
        etaMinutes: 9,
        etaSource: 'google',
        routePolyline: '_p~iF~ps|U_ulLnnqC',
        pickupLocation: GeoPoint(lat: 6.4310, lng: 3.4210),
        dropoffLocation: admiralty,
      );
    final c = _container(api);
    await tester.pumpWidget(_app(c, const Scaffold(body: LiveDeliveryMap(orderId: 'o1', kitchenName: 'Suya Lane'))));
    await tester.pump();
    expect(find.text('Musa is on the way to you · about 9 min'), findsOneWidget);
    expect(find.text('Arrival time from live traffic.'), findsOneWidget);
    expect(find.byType(SchematicMap), findsOneWidget);

    api.live = const LiveTracking(
      orderId: 'o1',
      status: 'rider_assigned',
      riderName: 'Musa',
      riderLocation: GeoPoint(lat: 6.4300, lng: 3.4200),
      etaMinutes: 31,
      etaSource: 'estimate',
      pickupLocation: GeoPoint(lat: 6.4310, lng: 3.4210),
      dropoffLocation: admiralty,
    );
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(find.text('Musa is heading to Suya Lane · about 31 min'), findsOneWidget);
    expect(find.text('Arrival time is an estimate.'), findsOneWidget);

    // Delivered: the API stops sharing the rider and the map stops polling.
    api.live = const LiveTracking(orderId: 'o1', status: 'delivered');
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    final calls = api.trackingCalls;
    expect(find.text("Waiting for the rider's location…"), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(api.trackingCalls, calls);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('nearby map lists places closest first and can show only open ones', (tester) async {
    final c = _container(MapsApi());
    await tester.pumpWidget(_app(c, const NearbyMapScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Restaurants near Lekki Phase 1'), findsOneWidget);
    expect(find.text('3 restaurants'), findsOneWidget);
    expect(find.text('~28 min'), findsOneWidget);
    expect(find.textContaining('Distances and times are estimates'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Open now'));
    await tester.pumpAndSettle();
    expect(find.text('2 restaurants'), findsOneWidget);
    expect(find.text("Mama Ayo's Kitchen"), findsNothing);
  });

  test('schematic projection keeps north up and every pin inside the box', () {
    const size = Size(300, 200);
    final p = MapProjection(const [admiralty, yaba], size);
    final a = p.toScreen(admiralty), y = p.toScreen(yaba);
    expect(y.dy, lessThan(a.dy)); // Yaba is north of Lekki
    expect(y.dx, lessThan(a.dx)); // and west
    for (final o in [a, y]) {
      expect(o.dx, inInclusiveRange(0, size.width));
      expect(o.dy, inInclusiveRange(0, size.height));
    }
    final single = MapProjection(const [admiralty], size).toScreen(admiralty);
    expect(single, const Offset(150, 100));
  });
}
