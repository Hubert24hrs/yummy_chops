import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_rider/providers.dart';
import 'package:gud_meal_rider/screens/delivery_screen.dart';
import 'package:gud_meal_rider/screens/home_screen.dart';
import 'package:gud_meal_rider/screens/trip_screen.dart';

import 'rider_test.dart' show FakeLocation;

const _navUrl = 'https://www.google.com/maps/dir/?api=1&destination=6.45,3.48&waypoints=6.44,3.47&travelmode=driving';

/// A mixed cart: a pharmacy and a restaurant, then Ada.
RiderTrip _trip({bool firstDone = false, bool secondDone = false, bool secondReady = false}) => RiderTrip(
      tripId: 'T-1',
      orderIds: const ['o1', 'o2'],
      nextStop: firstDone ? (secondDone ? 2 : 1) : 0,
      totalKm: 7.5,
      totalMinutes: 26,
      routeSource: 'google',
      navigationUrl: _navUrl,
      payoutKobo: 110990,
      stops: [
        TripStop(
          kind: 'pickup', orderId: 'o1', shortCode: 'AB12CD', name: 'CareFirst Pharmacy', vertical: 'pharmacy',
          address: '3 Fola Osibo Road, Lekki', location: const GeoPoint(lat: 6.44, lng: 3.47), phone: '+2348011111111',
          items: const [TripItem(name: 'Vitamin C', quantity: 2, options: ['1000 mg'])],
          status: firstDone ? 'picked_up' : 'rider_assigned', ready: true, done: firstDone, legKm: 2.4, legMinutes: 9,
        ),
        TripStop(
          kind: 'pickup', orderId: 'o2', shortCode: 'EF34GH', name: 'Jollof Junction', vertical: 'food',
          address: '1 Admiralty Way', location: const GeoPoint(lat: 6.445, lng: 3.475), phone: '0803 222 2222',
          items: const [TripItem(name: 'Party Jollof Rice', quantity: 1)],
          status: secondDone ? 'in_transit' : 'rider_assigned', ready: secondReady, done: secondDone, legKm: 1.0, legMinutes: 4,
        ),
        const TripStop(
          kind: 'dropoff', orderIds: ['o1', 'o2'], name: 'Ada Obi', address: '5 Bisola Durosinmi-Etti Drive, Lekki Phase 1',
          location: GeoPoint(lat: 6.45, lng: 3.48), phone: '+2348033333333', instructions: 'Gate 2', legKm: 5.1, legMinutes: 17,
        ),
      ],
    );

Order _order(String id, String status, {String vertical = 'food'}) => Order(
      id: id, shortCode: id.toUpperCase(), status: status, vertical: vertical, restaurantName: 'Shop $id', tripId: 'T-1',
      riderPayKobo: 50000,
      deliveryAddress: const DeliveryAddress(line1: '5 Bisola Durosinmi-Etti Drive', area: 'Lekki Phase 1', location: GeoPoint(lat: 6.45, lng: 3.48)),
    );

class _TripApi extends GudMealApi {
  _TripApi(this.trips, this.orders) : super(baseUrl: 'http://fake', token: () async => 't');
  List<RiderTrip> trips;
  List<Order> orders;
  final calls = <String>[];
  final delivered = <(String, String, bool)>[];
  ApiException? pickupError;

  @override
  Future<List<RiderTrip>> riderTrips() async => trips;

  @override
  Future<List<Order>> activeDeliveries() async => orders;

  @override
  Future<Order> pickup(String orderId) async {
    if (pickupError != null) throw pickupError!;
    calls.add('pickup $orderId');
    return orders.firstWhere((o) => o.id == orderId).copyWith(status: 'picked_up');
  }

  @override
  Future<Order> inTransit(String orderId) async {
    calls.add('in-transit $orderId');
    return orders.firstWhere((o) => o.id == orderId).copyWith(status: 'in_transit');
  }

  @override
  Future<Order> deliver(String orderId, String code, {bool cashCollected = false}) async {
    calls.add('deliver $orderId');
    delivered.add((orderId, code, cashCollected));
    return orders.firstWhere((o) => o.id == orderId).copyWith(status: 'delivered');
  }

  @override
  Future<RiderProfile> riderProfile() async =>
      const RiderProfile(uid: 'demo-rider-1', name: 'Chidi Okafor', status: 'active', isOnline: true, rating: 4.9);

  @override
  Future<List<DeliveryOffer>> offers() async => const [];

  @override
  Future<Earnings> earnings() async =>
      const Earnings(balanceKobo: 0, pendingPayoutsKobo: 0, availableKobo: 0, deliveriesCompleted: 0, earnedLast7DaysKobo: 0);

  @override
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) async {}
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<List<Uri>> _pumpTrip(WidgetTester tester, _TripApi api, {String? tripId = 'T-1', String? orderId}) async {
  _tall(tester);
  final opened = <Uri>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
      apiProvider.overrideWithValue(api),
      urlOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(initialLocation: '/trip', routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HOME'))),
        GoRoute(path: '/trip', builder: (_, _) => TripScreen(tripId: tripId, orderId: orderId)),
      ]),
    ),
  ));
  await tester.pumpAndSettle();
  return opened;
}

Finder _inStop(int i, Finder f) => find.descendant(of: find.byKey(ValueKey('stop-$i')), matching: f);

void main() {
  testWidgets('a trip offer lists every place to collect from, the drop-off area and the whole payout', (tester) async {
    final now = DateTime.utc(2026, 11, 25, 12);
    final offer = DeliveryOffer(
      id: 'a1', orderId: 'o1', restaurantName: 'CareFirst Pharmacy', distanceToRestaurantKm: 1.2, payoutKobo: 110990,
      expiresAt: now.add(const Duration(seconds: 30)), pickup: const GeoPoint(lat: 6.44, lng: 3.47), dropoffArea: 'Lekki Phase 1',
      tripOrderIds: const ['o1', 'o2'],
      pickups: const [
        OfferPickup(orderId: 'o1', name: 'CareFirst Pharmacy', address: '3 Fola Osibo Road, Lekki'),
        OfferPickup(orderId: 'o2', name: 'Jollof Junction', address: '1 Admiralty Way'),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      child: MaterialApp(home: Scaffold(body: OfferCard(offer: offer, now: () => now))),
    ));
    expect(find.text('2 pickups'), findsOneWidget);
    expect(find.textContaining('CareFirst Pharmacy', findRichText: true), findsOneWidget);
    expect(find.textContaining('3 Fola Osibo Road, Lekki', findRichText: true), findsOneWidget);
    expect(find.textContaining('Jollof Junction', findRichText: true), findsOneWidget);
    expect(find.text('1.2 km to the first pickup · drop-off in Lekki Phase 1'), findsOneWidget);
    expect(find.text('You earn ₦1,109.90 for the whole trip'), findsOneWidget);
  });

  testWidgets('the trip screen shows the stops in the planned order with each place and its phone', (tester) async {
    final api = _TripApi([_trip()], [_order('o1', 'rider_assigned', vertical: 'pharmacy'), _order('o2', 'rider_assigned')]);
    await _pumpTrip(tester, api);
    expect(find.text('7.5 km · 26 min left'), findsOneWidget);
    expect(find.text('You earn ₦1,109.90'), findsOneWidget);
    expect(_inStop(0, find.text('CareFirst Pharmacy')), findsOneWidget);
    expect(_inStop(0, find.text('Pick up · Pharmacy · 2.4 km · 9 min')), findsOneWidget);
    expect(_inStop(0, find.text('#AB12CD')), findsOneWidget);
    expect(_inStop(0, find.text('+2348011111111')), findsOneWidget);
    expect(_inStop(0, find.text('Collect: 2× Vitamin C (1000 mg)')), findsOneWidget);
    expect(_inStop(0, find.text('Ready to collect')), findsOneWidget);
    expect(find.byTooltip('Call CareFirst Pharmacy'), findsOneWidget);
    expect(find.byTooltip('WhatsApp CareFirst Pharmacy'), findsOneWidget);
    expect(_inStop(1, find.text('Jollof Junction')), findsOneWidget);
    expect(_inStop(1, find.text('Pick up · Restaurant · 1.0 km · 4 min')), findsOneWidget);
    expect(_inStop(1, find.text('0803 222 2222')), findsOneWidget);
    expect(_inStop(1, find.text('The kitchen is still preparing this order.')), findsOneWidget);
    expect(find.byTooltip('Call Jollof Junction'), findsOneWidget);
    expect(_inStop(2, find.text('Ada Obi')), findsOneWidget);
    expect(_inStop(2, find.text('Note: Gate 2')), findsOneWidget);
    expect(_inStop(2, find.text('+2348033333333')), findsOneWidget);
    expect(_inStop(2, find.text('Paid online: nothing to collect')), findsOneWidget);
    expect(find.byTooltip('WhatsApp Ada Obi'), findsOneWidget);
    // In the planned order, top to bottom.
    final y = [for (var i = 0; i < 3; i++) tester.getTopLeft(find.byKey(ValueKey('stop-$i'))).dy];
    expect(y[0] < y[1] && y[1] < y[2], isTrue);
    // No code before every shop is done.
    expect(find.byType(DeliveryCodeForm), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Picked up" collects that order; a shop that is neither next nor ready waits', (tester) async {
    final api = _TripApi([_trip()], [_order('o1', 'rider_assigned', vertical: 'pharmacy'), _order('o2', 'rider_assigned')]);
    await _pumpTrip(tester, api);
    final second = _inStop(1, find.widgetWithText(FilledButton, 'Picked up'));
    expect(tester.widget<FilledButton>(second).onPressed, isNull);
    await tester.tap(_inStop(0, find.widgetWithText(FilledButton, 'Picked up')));
    await tester.pumpAndSettle();
    expect(api.calls, ['pickup o1']); // not the last shop: no in-transit yet
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the last pickup sets off to the customer, and API errors are shown', (tester) async {
    final api = _TripApi([_trip(firstDone: true, secondReady: true)],
        [_order('o1', 'picked_up', vertical: 'pharmacy'), _order('o2', 'rider_assigned')]);
    await _pumpTrip(tester, api);
    await tester.tap(_inStop(1, find.widgetWithText(FilledButton, 'Picked up')));
    await tester.pumpAndSettle();
    expect(api.calls, ['pickup o2', 'in-transit o1', 'in-transit o2']);

    api.pickupError = ApiException(409, 'invalid_transition', 'The shop has not handed this order over yet');
    await tester.tap(_inStop(1, find.widgetWithText(FilledButton, 'Picked up')));
    await tester.pumpAndSettle();
    expect(find.text('The shop has not handed this order over yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Delivered" delivers every order of the trip with the one code', (tester) async {
    final api = _TripApi([_trip(firstDone: true, secondDone: true)],
        [_order('o1', 'picked_up', vertical: 'pharmacy'), _order('o2', 'in_transit')]);
    await _pumpTrip(tester, api);
    expect(find.byType(DeliveryCodeForm), findsOneWidget);
    expect(find.byKey(const ValueKey('stop-0')), findsOneWidget);
    expect(_inStop(0, find.byIcon(Icons.check_rounded)), findsOneWidget); // done stops are ticked
    await tester.enterText(find.byType(TextField), '4118');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delivered'));
    await tester.pumpAndSettle();
    expect(api.calls, ['in-transit o1', 'deliver o1', 'deliver o2']);
    expect(api.delivered.map((d) => d.$2), ['4118', '4118']);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('"Start navigation" opens the whole route in Google Maps; Call dials the shop', (tester) async {
    final api = _TripApi([_trip()], [_order('o1', 'rider_assigned', vertical: 'pharmacy'), _order('o2', 'rider_assigned')]);
    final opened = await _pumpTrip(tester, api);
    await tester.tap(find.byKey(const ValueKey('start-navigation')));
    await tester.pump();
    expect(opened.single.toString(), _navUrl);
    await tester.tap(find.byTooltip('Call CareFirst Pharmacy'));
    await tester.pump();
    expect(opened.last.toString(), 'tel:+2348011111111');
    await tester.tap(_inStop(1, find.text('Navigate')));
    await tester.pump();
    expect(opened.last, navigationUri(const GeoPoint(lat: 6.445, lng: 3.475)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an order link opens its trip; a package keeps the delivery screen', (tester) async {
    final parcel = _order('p1', 'rider_assigned', vertical: 'parcel').copyWith(
      tripId: null,
      parcel: const ParcelDetails(
        pickup: ParcelStop(name: 'Ada', phone: '+2348011111111', line1: '5 Bisola', location: GeoPoint(lat: 6.44, lng: 3.46)),
        dropoff: ParcelStop(name: 'Ngozi', phone: '+2348055555555', line1: '4 Herbert Macaulay Way', location: GeoPoint(lat: 6.51, lng: 3.37)),
        size: 'medium',
        category: 'clothing',
      ),
    );
    final api = _TripApi([_trip()], [_order('o1', 'rider_assigned'), _order('o2', 'rider_assigned'), parcel]);
    await _pumpTrip(tester, api, tripId: null, orderId: 'o2');
    expect(find.byKey(const ValueKey('stop-2')), findsOneWidget);
    expect(find.text('Trip · 2 orders'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _pumpTrip(tester, api, tripId: null, orderId: 'p1');
    expect(find.byType(DeliveryScreen), findsOneWidget);
    expect(find.text('Package collected'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the dashboard shows one card per trip with the next stop, stops and time', (tester) async {
    _tall(tester);
    final parcel = _order('p1', 'rider_assigned', vertical: 'parcel').copyWith(restaurantName: 'Package from Ada', shortCode: 'PKG123');
    final api = _TripApi([_trip()], [_order('o1', 'rider_assigned'), _order('o2', 'rider_assigned'), parcel]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
        apiProvider.overrideWithValue(api),
        locationSourceProvider.overrideWithValue(FakeLocation(fix: (const GeoPoint(lat: 6.4478, lng: 3.4723), 5.0))),
      ],
      child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: const RiderHomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trip-T-1')), findsOneWidget);
    expect(find.text('Next: pick up at CareFirst Pharmacy'), findsOneWidget);
    expect(find.text('3 of 3 stops left · 26 min · 7.5 km · earn ₦1,109.90'), findsOneWidget);
    expect(find.text('Shop o1 · #O1'), findsNothing); // inside the trip card, not on its own
    expect(find.text('Package from Ada · #PKG123'), findsOneWidget); // packages keep their own card
    await tester.pumpWidget(const SizedBox());
  });

  test('without trips every active order keeps its own card', () {
    final jobs = activeJobs([_order('o1', 'rider_assigned')], const []);
    expect(jobs.single.order?.id, 'o1');
    expect(jobs.single.trip, isNull);
  });
}
