import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_rider/providers.dart';
import 'package:gud_meal_rider/screens/delivery_screen.dart';
import 'package:gud_meal_rider/screens/home_screen.dart';

class FakeLocation implements LocationSource {
  FakeLocation({this.allowed = true, this.fix});
  final bool allowed;
  final (GeoPoint, double)? fix;
  final controller = StreamController<(GeoPoint, double)>();

  @override
  Future<bool> ensurePermission() async => allowed;

  @override
  Stream<(GeoPoint, double)> positions() => controller.stream;

  @override
  Future<(GeoPoint, double)?> current() async => fix;
}

class RecordingApi extends GudMealApi {
  RecordingApi({this.failLocation = false}) : super(baseUrl: 'http://fake', token: () async => 't');
  final bool failLocation;
  final sent = <GeoPoint>[];

  @override
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) async {
    if (failLocation) throw ApiException(0, 'network_error', 'offline');
    sent.add(p);
  }
}

/// Records the order of online/offline switches and pings; can act as if the server thinks the rider is offline.
class _OrderApi extends GudMealApi {
  _OrderApi() : super(baseUrl: 'http://fake', token: () async => 't');
  final events = <String>[];
  bool offlineOnServer = false;

  @override
  Future<RiderProfile> setOnline(bool online) async {
    events.add(online ? 'online' : 'offline');
    offlineOnServer = !online;
    return RiderProfile(uid: 'r1', name: 'Musa', isOnline: online);
  }

  @override
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) async {
    if (offlineOnServer) throw ApiException(409, 'invalid_transition', 'Go online to share your location');
    events.add('ping');
  }
}

DeliveryOffer offer(DateTime expiresAt) => DeliveryOffer(
      id: 'a1', orderId: 'o1', restaurantName: 'Suya Lane', distanceToRestaurantKm: 1.2, payoutKobo: 121960,
      expiresAt: expiresAt, pickup: const GeoPoint(lat: 6.43, lng: 3.42), dropoffArea: 'Lekki Phase 1',
    );

class _CustomerApi extends GudMealApi {
  _CustomerApi(this.job) : super(baseUrl: 'http://fake', token: () async => 'tok');
  final Order job;

  @override
  Future<List<Order>> activeDeliveries() async => [job];
}

const _foodJob = Order(
  id: 'f1',
  shortCode: 'FOOD12',
  status: 'rider_assigned',
  restaurantName: 'Jollof Junction',
  restaurantLocation: GeoPoint(lat: 6.44, lng: 3.46),
  riderPayKobo: 90000,
  customerName: 'Ada Obi',
  items: [OrderItem(name: 'Party Jollof Rice', quantity: 2)],
  paymentMethod: 'prepaid',
  deliveryAddress: DeliveryAddress(
    label: 'Home',
    line1: '5 Admiralty Way',
    area: 'Lekki Phase 1',
    location: GeoPoint(lat: 6.44, lng: 3.47),
    instructions: 'Blue gate, call on arrival',
    contactPhone: '+234 801 111 1111',
  ),
);

void customerTests() {
  Widget screen(Order order) => ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
          apiProvider.overrideWithValue(_CustomerApi(order)),
        ],
        child: const MaterialApp(home: DeliveryScreen(orderId: 'f1')),
      );

  testWidgets('an accepted job shows the customer, their address, note and number, with call and WhatsApp',
      (tester) async {
    await tester.pumpWidget(screen(_foodJob));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('customer-card')), findsOneWidget);
    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('Home, 5 Admiralty Way, Lekki Phase 1, Lagos'), findsOneWidget);
    expect(find.text('Note: Blue gate, call on arrival'), findsOneWidget);
    expect(find.text('+234 801 111 1111'), findsOneWidget);
    expect(find.text('Paid online: nothing to collect'), findsOneWidget);
    expect(find.byTooltip('Call Ada Obi'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Ada Obi'), findsOneWidget);
  });

  testWidgets('without a number there is nothing to call, and cash orders say what to collect', (tester) async {
    final job = _foodJob.copyWith(
      paymentMethod: 'cash',
      collectCashKobo: 1136500,
      deliveryAddress: _foodJob.deliveryAddress!.copyWith(contactPhone: null, instructions: null),
    );
    await tester.pumpWidget(screen(job));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Call Ada Obi'), findsNothing);
    expect(find.byTooltip('WhatsApp Ada Obi'), findsNothing);
    expect(find.textContaining('Note:'), findsNothing);
    expect(find.text('Pays ₦11,365 in cash on delivery'), findsOneWidget);
    expect(find.byTooltip('Navigate'), findsWidgets);
  });

  test('WhatsApp links use the international number', () {
    expect(whatsAppUri('0803 123 4567').toString(), 'https://wa.me/2348031234567');
    expect(whatsAppUri('+234 803 123 4567').toString(), 'https://wa.me/2348031234567');
  });
}

void main() {
  parcelTests();
  cashTests();
  hubLegTests();
  customerTests();
  testWidgets('offer shows countdown, payout and disables actions once expired', (tester) async {
    final now = DateTime.utc(2026, 11, 14, 20, 0, 0);
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      child: MaterialApp(home: Scaffold(body: Column(children: [
        OfferCard(offer: offer(now.add(const Duration(seconds: 30))), now: () => now),
        OfferCard(offer: offer(now.subtract(const Duration(seconds: 1))), now: () => now),
      ]))),
    ));
    expect(find.text('30s'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('You earn ₦1,219.60'), findsNWidgets(2));
    final accepts = tester.widgetList<FilledButton>(find.widgetWithText(FilledButton, 'Accept')).toList();
    expect(accepts.first.onPressed, isNotNull);
    expect(accepts.last.onPressed, isNull);
  });

  testWidgets('delivery code form only submits four digits', (tester) async {
    String? submitted;
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DeliveryCodeForm(controller: controller, onSubmit: (c) => submitted = c))));
    final button = find.widgetWithText(FilledButton, 'Complete delivery');
    await tester.enterText(find.byType(TextField), '12a');
    await tester.pump();
    expect(controller.text, '12');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '4118');
    await tester.pump();
    await tester.tap(button);
    expect(submitted, '4118');
  });

  group('LocationReporter', () {
    test('streams positions to the API while online', () async {
      final api = RecordingApi();
      final source = FakeLocation();
      final reporter = LocationReporter(api, source);
      expect(await reporter.start(), isTrue);
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(Duration.zero);
      expect(api.sent.single.lat, 6.44);
      await reporter.stop();
      expect(reporter.active, isFalse);
    });

    test('refuses to start without location permission', () async {
      final reporter = LocationReporter(RecordingApi(), FakeLocation(allowed: false));
      expect(await reporter.start(), isFalse);
      expect(reporter.active, isFalse);
    });

    test('stops sharing when the server says the rider is offline', () async {
      final api = _OrderApi()..offlineOnServer = true;
      final source = FakeLocation();
      final reporter = LocationReporter(api, source);
      await reporter.start();
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(reporter.active, isFalse);
      expect(reporter.stoppedByServer, isTrue);
    });

    test('goes online before sharing and stops sharing before going offline', () async {
      final api = _OrderApi();
      final source = FakeLocation();
      final reporter = LocationReporter(api, source);
      expect(await setRiderOnline(api, reporter, true), isNull);
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(Duration.zero);
      expect(await setRiderOnline(api, reporter, false), isNull);
      expect(api.events, ['online', 'ping', 'offline']);
      expect(reporter.active, isFalse);

      final denied = LocationReporter(api, FakeLocation(allowed: false));
      expect(await setRiderOnline(api, denied, true), 'Location permission is required to go online.');
      expect(api.events.last, 'offline'); // never went online without location
    });

    test('drops pings while offline instead of crashing', () async {
      final api = RecordingApi(failLocation: true);
      final source = FakeLocation();
      final reporter = LocationReporter(api, source);
      await reporter.start();
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(Duration.zero);
      expect(reporter.last?.lat, 6.44);
      await reporter.stop();
    });

    test('shares the position as soon as the rider goes online', () async {
      final api = RecordingApi();
      final reporter = LocationReporter(api, FakeLocation(fix: (const GeoPoint(lat: 6.4478, lng: 3.4723), 5.0)));
      await reporter.start();
      await Future<void>.delayed(Duration.zero);
      expect(api.sent.single.lat, 6.4478);
      expect(reporter.lastSentAt, isNotNull);
      await reporter.stop();
    });

    test('keeps a rider waiting in one place visible to dispatch', () async {
      // Standing still: the movement stream is silent, so the heartbeat keeps re-sending the position.
      final api = RecordingApi();
      final reporter = LocationReporter(
        api,
        FakeLocation(fix: (const GeoPoint(lat: 6.4478, lng: 3.4723), 5.0)),
        heartbeat: const Duration(milliseconds: 30),
      );
      await reporter.start();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      expect(api.sent.length, greaterThanOrEqualTo(3));
      await reporter.stop();
      final after = api.sent.length;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(api.sent.length, after); // no pings once offline
    });

    test('re-sends the last known position when no fresh fix is available', () async {
      final api = RecordingApi();
      final source = FakeLocation();
      final reporter = LocationReporter(api, source, heartbeat: const Duration(milliseconds: 30));
      await reporter.start();
      source.controller.add((const GeoPoint(lat: 6.44, lng: 3.46), 8.0));
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(api.sent.length, greaterThanOrEqualTo(2));
      expect(api.sent.every((p) => p.lat == 6.44), isTrue);
      await reporter.stop();
    });
  });

  testWidgets('dashboard shows the online state, numbers and what to do while waiting', (tester) async {
    final api = _DashboardApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        apiProvider.overrideWithValue(api),
        locationSourceProvider.overrideWithValue(FakeLocation(fix: (const GeoPoint(lat: 6.4478, lng: 3.4723), 5.0))),
      ],
      child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: const RiderHomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hi, Chidi'), findsOneWidget);
    expect(find.text("You're online"), findsOneWidget);
    expect(find.text('₦12,500'), findsOneWidget); // earned in 7 days
    expect(find.text('Earned in 7 days'), findsOneWidget);
    expect(find.text('Deliveries done'), findsOneWidget);
    expect(find.text('Waiting for orders near you…'), findsOneWidget);
    expect(api.pings, greaterThanOrEqualTo(1)); // online on open: the position is shared straight away

    api.pendingOffers = [offer(DateTime.now().toUtc().add(const Duration(seconds: 40)))];
    await tester.pump(const Duration(seconds: 5)); // next poll
    await tester.pumpAndSettle();
    expect(find.text('New offers'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsOneWidget);
    expect(find.text('Waiting for orders near you…'), findsNothing);

    await tester.pumpWidget(const SizedBox()); // dispose: stops polling and location sharing
  });
}

class _DashboardApi extends GudMealApi {
  _DashboardApi() : super(baseUrl: 'http://fake', token: () async => 't');
  List<DeliveryOffer> pendingOffers = const [];
  int pings = 0;

  @override
  Future<RiderProfile> riderProfile() async =>
      const RiderProfile(uid: 'demo-rider-1', name: 'Chidi Okafor', status: 'active', isOnline: true, rating: 4.9, completedDeliveries: 12);

  @override
  Future<List<DeliveryOffer>> offers() async => pendingOffers;

  @override
  Future<List<Order>> activeDeliveries() async => const [];

  @override
  Future<Earnings> earnings() async => const Earnings(
        balanceKobo: 900000, pendingPayoutsKobo: 0, availableKobo: 900000, deliveriesCompleted: 12, earnedLast7DaysKobo: 1250000);

  @override
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) async {
    pings++;
  }
}

class _ParcelApi extends GudMealApi {
  _ParcelApi() : super(baseUrl: 'http://fake', token: () async => 'tok');

  @override
  Future<List<Order>> activeDeliveries() async => [
        const Order(
          id: 'p1',
          shortCode: 'PKG123',
          vertical: 'parcel',
          status: 'rider_assigned',
          restaurantName: 'Package from Ada',
          restaurantAddress: '5 Bisola Durosinmi-Etti Drive, Lekki Phase 1',
          restaurantLocation: GeoPoint(lat: 6.44, lng: 3.46),
          riderPayKobo: 120000,
          deliveryAddress: DeliveryAddress(line1: '4 Herbert Macaulay Way', area: 'Yaba', location: GeoPoint(lat: 6.51, lng: 3.37), contactPhone: '+2348055555555'),
          parcel: ParcelDetails(
            pickup: ParcelStop(name: 'Ada', phone: '+2348011111111', line1: '5 Bisola Durosinmi-Etti Drive', location: GeoPoint(lat: 6.44, lng: 3.46)),
            dropoff: ParcelStop(name: 'Ngozi', phone: '+2348055555555', line1: '4 Herbert Macaulay Way', location: GeoPoint(lat: 6.51, lng: 3.37)),
            size: 'medium',
            category: 'clothing',
            description: 'Two dresses',
          ),
        ),
      ];
}

class _CashApi extends GudMealApi {
  _CashApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  final delivered = <(String, bool)>[];

  static const cashOrder = Order(
    id: 'c1',
    shortCode: 'CASH12',
    status: 'in_transit',
    restaurantName: 'Jollof Junction',
    restaurantLocation: GeoPoint(lat: 6.44, lng: 3.46),
    riderPayKobo: 90000,
    // The API gives riders `items` (names and quantities, no prices), not the customer's priced `lines`.
    items: [OrderItem(name: 'Party Jollof Rice', quantity: 2), OrderItem(name: 'Chapman')],
    paymentMethod: 'cash',
    collectCashKobo: 1136500,
    deliveryAddress: DeliveryAddress(line1: '5 Admiralty Way', area: 'Lekki Phase 1', location: GeoPoint(lat: 6.44, lng: 3.47)),
  );

  @override
  Future<List<Order>> activeDeliveries() async => [cashOrder];

  @override
  Future<Order> deliver(String orderId, String code, {bool cashCollected = false}) async {
    delivered.add((code, cashCollected));
    return cashOrder.copyWith(status: 'delivered');
  }
}

class _HubLegApi extends GudMealApi {
  _HubLegApi() : super(baseUrl: 'http://fake', token: () async => 'tok');

  @override
  Future<List<Order>> activeDeliveries() async => [
        const Order(
          id: 'w1-fm',
          shortCode: 'LEG123',
          vertical: 'parcel',
          status: 'picked_up',
          restaurantName: 'Waybill GMW7K3P9Q2X (to the hub)',
          restaurantLocation: GeoPoint(lat: 6.44, lng: 3.46),
          riderPayKobo: 90000,
          legKind: 'first_mile',
          hubHandover: true,
          deliveryAddress: DeliveryAddress(line1: 'Admiralty Way', area: 'Lekki Phase 1', location: GeoPoint(lat: 6.4478, lng: 3.4723)),
          parcel: ParcelDetails(
            pickup: ParcelStop(name: 'Ada', phone: '+2348011111111', line1: '5 Bisola Durosinmi-Etti Drive', location: GeoPoint(lat: 6.44, lng: 3.46)),
            dropoff: ParcelStop(name: 'Yummy Chops Hub, Lekki', phone: '+234 000 000 0012', line1: 'Admiralty Way', location: GeoPoint(lat: 6.4478, lng: 3.4723)),
            size: 'small',
            category: 'clothing',
          ),
        ),
      ];
}

void hubLegTests() {
  testWidgets('interstate jobs to a hub end with the hub staff, not a delivery code', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
        apiProvider.overrideWithValue(_HubLegApi()),
      ],
      child: const MaterialApp(home: DeliveryScreen(orderId: 'w1-fm')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Interstate · to the hub · small'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-handover')), findsOneWidget);
    expect(find.byType(DeliveryCodeForm), findsNothing);
  });
}

void cashTests() {
  testWidgets('cash jobs show the amount and need the rider to confirm the cash before delivery', (tester) async {
    final api = _CashApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
        apiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(initialLocation: '/deliveries/c1', routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HOME'))),
          GoRoute(path: '/deliveries/:id', builder: (_, s) => DeliveryScreen(orderId: s.pathParameters['id']!)),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Collect ₦11,365 in cash'), findsOneWidget);
    expect(find.text('Items: 2× Party Jollof Rice, 1× Chapman'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4118');
    await tester.pump();
    final button = find.widgetWithText(FilledButton, 'Complete delivery');
    await tester.ensureVisible(button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull); // cash not confirmed yet
    await tester.ensureVisible(find.byKey(const ValueKey('cash-taken')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cash-taken')));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(api.delivered.single, ('4118', true));
    expect(find.text('HOME'), findsOneWidget);
  });
}

void parcelTests() {
  testWidgets('package jobs show sender and recipient contacts and package wording', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'demo-rider-1'))),
        apiProvider.overrideWithValue(_ParcelApi()),
      ],
      child: const MaterialApp(home: DeliveryScreen(orderId: 'p1')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Package · medium · clothing'), findsOneWidget);
    expect(find.text('Pickup: Ada'), findsOneWidget);
    expect(find.text('Drop-off: Ngozi'), findsOneWidget);
    expect(find.text('Contents: Two dresses'), findsOneWidget);
    expect(find.byTooltip('Call Ada'), findsOneWidget);
    expect(find.byTooltip('Call Ngozi'), findsOneWidget);
    expect(find.text('Package collected'), findsOneWidget);
    expect(find.textContaining('kitchen'), findsNothing);
  });
}
