import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/location/address_picker.dart';
import 'package:gud_meal_customer/features/location/delivery_location.dart';
import 'package:gud_meal_customer/providers.dart';
import 'package:gud_meal_customer/ui/gm_map.dart';

import 'maps_test.dart' show FakeLocation, MapsApi, yaba;

/// The maps fake, plus an address book.
class _Api extends MapsApi {
  List<DeliveryAddress> existing = const [];
  final saved = <DeliveryAddress>[];

  @override
  Future<List<DeliveryAddress>> addresses() async => existing;

  @override
  Future<void> saveAddress(DeliveryAddress a) async => saved.add(a);
}

ProviderContainer _container(_Api api, AuthRepository auth, {CustomerLocation? location}) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    apiProvider.overrideWithValue(api),
    if (location != null) customerLocationProvider.overrideWithValue(location),
  ]);
  addTearDown(c.dispose);
  return c;
}

Widget _app(ProviderContainer c, Widget home) =>
    UncontrolledProviderScope(container: c, child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: home));

void main() {
  testWidgets('a new customer sets the delivery address with GPS: saved as Home, and Home shows that area', (tester) async {
    final api = _Api();
    final location = FakeLocation(yaba);
    final c = _container(api, FakeAuthRepository(const GmUser(uid: 'u1')), location: location);
    bool? done;
    await tester.pumpWidget(_app(
      c,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => done = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const DeliveryLocationScreen())),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Where should we deliver?'), findsOneWidget);
    expect(find.text('Use my current location'), findsOneWidget);
    expect(find.text('Type my address'), findsOneWidget);
    expect(find.text('Choose on the map'), findsNothing); // no Google map tiles in this build

    await tester.tap(find.byKey(const ValueKey('where-gps')));
    await tester.pumpAndSettle();
    expect(location.asked, 1); // the picker finds the phone's position straight away
    expect(api.reversed.single, yaba);

    await tester.enterText(find.widgetWithText(TextField, 'Street and house number'), '12 Herbert Macaulay Way');
    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    final saved = api.saved.single;
    expect(saved.label, 'Home');
    expect(saved.location, yaba); // the device's own fix
    expect(saved.line1, '12 Herbert Macaulay Way');
    expect(c.read(areaProvider).name, 'Yaba'); // Home now shows shops for that area
  });

  testWidgets('"Not now" skips it, and "Type my address" opens the search', (tester) async {
    final api = _Api();
    final c = _container(api, FakeAuthRepository(const GmUser(uid: 'u1')));
    bool? done;
    await tester.pumpWidget(_app(
      c,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => done = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const DeliveryLocationScreen())),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('where-type')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Search street, estate or landmark'), findsOneWidget);
    await tester.tap(find.byType(CloseButton)); // the picker is a full-screen step with a close button
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('where-later')));
    await tester.pumpAndSettle();
    expect(done, isFalse);
    expect(api.saved, isEmpty);
  });

  testWidgets('"Choose on the map" is offered when the build has Google map tiles', (tester) async {
    final before = googleMapsReady;
    googleMapsReady = true;
    addTearDown(() => googleMapsReady = before);
    final c = _container(_Api(), FakeAuthRepository(const GmUser(uid: 'u1')));
    await tester.pumpWidget(_app(c, const DeliveryLocationScreen()));
    expect(find.text('Choose on the map'), findsOneWidget);
    expect(find.text('Move the pin on Google Maps to your gate'), findsOneWidget);
  });

  testWidgets('asked once after a fresh sign-in, only without a saved address', (tester) async {
    final api = _Api();
    final auth = FakeAuthRepository(); // signed out
    final c = _container(api, auth);
    late BuildContext ctx;
    late WidgetRef widgetRef;
    await tester.pumpWidget(_app(
      c,
      Consumer(builder: (context, ref, _) {
        ctx = context;
        widgetRef = ref;
        ref.listen(askWhereToDeliverProvider, (_, _) {}); // the app root keeps this alive
        return const Scaffold(body: Text('home'));
      }),
    ));
    await tester.pumpAndSettle();
    expect(c.read(askWhereToDeliverProvider), isFalse);

    await auth.signInWithEmail('ada@example.com', 'secret');
    await tester.pumpAndSettle();
    expect(c.read(askWhereToDeliverProvider), isTrue);

    final asking = askWhereToDeliverIfNeeded(ctx, widgetRef);
    await tester.pumpAndSettle();
    expect(find.text('Where should we deliver?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('where-later')));
    await tester.pumpAndSettle();
    await asking;
    expect(c.read(askWhereToDeliverProvider), isFalse);

    // Asked only once per sign-in: nothing happens the second time.
    await askWhereToDeliverIfNeeded(ctx, widgetRef);
    await tester.pumpAndSettle();
    expect(find.text('Where should we deliver?'), findsNothing);
  });

  testWidgets('a customer who already has an address is not asked', (tester) async {
    final api = _Api()
      ..existing = const [DeliveryAddress(label: 'Home', line1: '5 Admiralty Way', location: GeoPoint(lat: 6.4478, lng: 3.4723))];
    final auth = FakeAuthRepository();
    final c = _container(api, auth);
    late BuildContext ctx;
    late WidgetRef widgetRef;
    await tester.pumpWidget(_app(
      c,
      Consumer(builder: (context, ref, _) {
        ctx = context;
        widgetRef = ref;
        ref.listen(askWhereToDeliverProvider, (_, _) {});
        return const Scaffold(body: Text('home'));
      }),
    ));
    await auth.signInWithEmail('ada@example.com', 'secret');
    await tester.pumpAndSettle();
    await askWhereToDeliverIfNeeded(ctx, widgetRef);
    await tester.pumpAndSettle();
    expect(find.text('Where should we deliver?'), findsNothing);
  });

  testWidgets('the picker can open straight on GPS', (tester) async {
    final api = _Api();
    final location = FakeLocation(yaba);
    final c = _container(api, FakeAuthRepository(const GmUser(uid: 'u1')), location: location);
    await tester.pumpWidget(_app(
      c,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => pickDeliveryAddress(context, start: AddressStart.myLocation), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(location.asked, 1);
    expect(find.text('Yummy Chops delivers here'), findsOneWidget);
  });
}
