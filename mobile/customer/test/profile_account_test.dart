import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/location/address_picker.dart';
import 'package:gud_meal_customer/features/profile/profile_screen.dart';
import 'package:gud_meal_customer/features/security/app_lock.dart';
import 'package:gud_meal_customer/providers.dart';

import 'maps_test.dart' show FakeLocation, MapsApi, yaba;

/// Profile is the only place to sign in: a guest saves their account with Google (or Apple, when the build turns it
/// on), sets their home address with GPS, and a saved account can turn on "Unlock with fingerprint".
const _guest = GmUser(uid: 'guest-1', isAnonymous: true);
const _ada = GmUser(uid: 'u-ada', email: 'ada@example.com', name: 'Ada');

class _Api extends MapsApi {
  final saved = <DeliveryAddress>[];

  @override
  Future<List<DeliveryAddress>> addresses() async => List.of(saved);

  final updated = <String>[];

  @override
  Future<void> saveAddress(DeliveryAddress a) async => saved.add(a.copyWith(id: 'a${saved.length + 1}'));

  @override
  Future<void> updateAddress(String id, DeliveryAddress a) async {
    updated.add(id);
    saved[saved.indexWhere((s) => s.id == id)] = a.copyWith(id: id);
  }
}

class FakeBiometrics implements BiometricAuth {
  FakeBiometrics({this.available = true, this.passes = true});
  bool available;
  bool passes;
  int asked = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return passes;
  }
}

AppConfig _config({bool apple = false}) => AppConfig(
      apiUrl: 'http://fake',
      agentsUrl: 'http://fake',
      useEmulators: false,
      firebaseApiKey: 'k',
      firebaseAppId: 'a',
      firebaseProjectId: 'p',
      firebaseMessagingSenderId: 's',
      appleSignIn: apple,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _pumpProfile(
  WidgetTester tester,
  FakeAuthRepository auth, {
  _Api? api,
  bool apple = false,
  FakeBiometrics? biometrics,
  CustomerLocation? location,
  AppLockStore? lockStore,
}) async {
  _phone(tester);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
    for (final p in ['/sign-in', '/orders', '/support', '/wallet', '/receipts', '/plus', '/rewards', '/group', '/track', '/partner-with-us', '/ride', '/help'])
      GoRoute(path: p, builder: (_, _) => Scaffold(body: Text('PAGE $p'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(), // a fresh app each time a test pumps it again
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      apiProvider.overrideWithValue(api ?? _Api()),
      configProvider.overrideWithValue(_config(apple: apple)),
      biometricAuthProvider.overrideWithValue(biometrics ?? FakeBiometrics(available: false)),
      if (location != null) customerLocationProvider.overrideWithValue(location),
      if (lockStore != null) appLockStoreProvider.overrideWithValue(lockStore),
      walletProvider.overrideWith((ref) async => throw ApiException(500, 'offline', 'offline')),
    ],
    child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a guest sees Save your account with Google, and no Apple unless the build turns it on', (tester) async {
    await _pumpProfile(tester, FakeAuthRepository(_guest));
    expect(find.text('Save your account'), findsOneWidget);
    expect(find.byKey(const ValueKey('link-google')), findsOneWidget);
    expect(find.byKey(const ValueKey('link-apple')), findsNothing);
    expect(find.text('Other ways to sign in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing); // a guest has nothing to sign out of
    expect(find.text('Sign in or create account'), findsNothing);
  });

  testWidgets('with APPLE_SIGN_IN on, Continue with Apple shows too and links the guest', (tester) async {
    final auth = FakeAuthRepository(_guest);
    await _pumpProfile(tester, auth, apple: true);
    expect(find.byKey(const ValueKey('link-apple')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('link-apple')));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.uid, 'guest-1');
    expect(auth.currentUser?.isAnonymous, isFalse);
  });

  testWidgets('Continue with Google links the guest: same uid, so the orders stay', (tester) async {
    final auth = FakeAuthRepository(_guest);
    await _pumpProfile(tester, auth);
    await tester.tap(find.byKey(const ValueKey('link-google')));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.uid, 'guest-1');
    expect(auth.currentUser?.isAnonymous, isFalse);
    expect(auth.currentUser?.email, 'google.user@example.com');
    expect(find.text('Your account is saved. Your orders stay with it.'), findsOneWidget);
    expect(find.text('Save your account'), findsNothing);
    expect(find.text('google.user@example.com'), findsOneWidget);
  });

  testWidgets('a Google account that already exists is signed in to instead, and says what stays where', (tester) async {
    final auth = FakeAuthRepository(_guest)..existingAccounts.add('google.user@example.com');
    await _pumpProfile(tester, auth);
    await tester.tap(find.byKey(const ValueKey('link-google')));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.uid, 'u-google.user@example.com');
    expect(find.textContaining('Your cart stays on this phone'), findsOneWidget);
  });

  testWidgets('Home address: Use my location saves the GPS address as Home, then shows it with Change', (tester) async {
    final api = _Api();
    final location = FakeLocation(yaba);
    await _pumpProfile(tester, FakeAuthRepository(_guest), api: api, location: location);
    expect(find.text('Use my location'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-address')));
    await tester.pumpAndSettle();
    expect(location.asked, 1); // the picker finds the phone's position straight away
    expect(api.reversed.single, yaba);
    await tester.enterText(find.widgetWithText(TextField, 'Street and house number'), '12 Herbert Macaulay Way');
    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();

    final saved = api.saved.single;
    expect(saved.label, 'Home');
    expect(saved.location, yaba);
    expect(find.textContaining('12 Herbert Macaulay Way'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-address-change')), findsOneWidget);
    expect(find.text('Use my location'), findsNothing);

    // Change replaces the Home address (found in review: a second "Home" was added, and the address book's order
    // by id decided which one showed and which one checkout used).
    await tester.tap(find.byKey(const ValueKey('home-address-change')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Street and house number'), '3 Commercial Avenue');
    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();
    expect(api.updated, ['a1']);
    expect(api.saved.single.line1, '3 Commercial Avenue');
    expect(api.saved.single.label, 'Home');
    expect(find.textContaining('3 Commercial Avenue'), findsOneWidget);
  });

  testWidgets('Unlock with fingerprint is offered only to a saved account on a phone that can check it', (tester) async {
    await _pumpProfile(tester, FakeAuthRepository(_guest), biometrics: FakeBiometrics());
    expect(find.byKey(const ValueKey('fingerprint-switch')), findsNothing, reason: 'not for a guest');

    await _pumpProfile(tester, FakeAuthRepository(_ada), biometrics: FakeBiometrics(available: false));
    expect(find.byKey(const ValueKey('fingerprint-switch')), findsNothing, reason: 'the phone cannot check one');

    final biometrics = FakeBiometrics();
    final store = MemoryAppLockStore();
    await _pumpProfile(tester, FakeAuthRepository(_ada), biometrics: biometrics, lockStore: store);
    expect(find.byKey(const ValueKey('fingerprint-switch')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fingerprint-switch')));
    await tester.pumpAndSettle();
    expect(biometrics.asked, 1); // checked once before it is turned on
    expect(store.enabled, isTrue);
  });

  group('the fingerprint lock', () {
    Future<ProviderContainer> pumpLocked(WidgetTester tester, FakeAuthRepository auth, FakeBiometrics biometrics,
        {required bool on, DateTime Function()? now}) async {
      _phone(tester);
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        biometricAuthProvider.overrideWithValue(biometrics),
        appLockStoreProvider.overrideWithValue(MemoryAppLockStore(enabled: on)),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildGudMealTheme(Brightness.light),
          builder: (context, child) => AppLockGate(now: now ?? DateTime.now, child: child!),
          home: const Scaffold(body: Text('inside the app')),
        ),
      ));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('asks for the fingerprint when the app opens, and unlocks when it passes', (tester) async {
      final biometrics = FakeBiometrics(passes: false);
      await pumpLocked(tester, FakeAuthRepository(_ada), biometrics, on: true);
      expect(find.byKey(const ValueKey('app-lock')), findsOneWidget);
      expect(biometrics.asked, 1); // asked straight away
      expect(find.text('inside the app'), findsNothing);
      expect(find.text('Use phone PIN'), findsOneWidget);

      biometrics.passes = true;
      await tester.tap(find.byKey(const ValueKey('app-unlock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      expect(find.text('inside the app'), findsOneWidget);
    });

    testWidgets('locks again after more than five minutes in the background', (tester) async {
      var clock = DateTime(2026, 11, 26, 12);
      final biometrics = FakeBiometrics();
      await pumpLocked(tester, FakeAuthRepository(_ada), biometrics, on: true, now: () => clock);
      expect(find.text('inside the app'), findsOneWidget); // unlocked by the fake at once

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock = clock.add(const Duration(minutes: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(biometrics.asked, 1, reason: 'two minutes away: no new check');

      biometrics.passes = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock = clock.add(const Duration(minutes: 6));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-lock')), findsOneWidget);
      expect(biometrics.asked, 2);
    });

    testWidgets('Sign out on the lock screen turns the lock off and signs out', (tester) async {
      final auth = FakeAuthRepository(_ada);
      final container = await pumpLocked(tester, auth, FakeBiometrics(passes: false), on: true);
      await tester.tap(find.byKey(const ValueKey('app-lock-sign-out')));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(container.read(appLockProvider), isFalse);
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
    });

    testWidgets('never locks a guest, nor when it is off', (tester) async {
      await pumpLocked(tester, FakeAuthRepository(_guest), FakeBiometrics(), on: true);
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      await pumpLocked(tester, FakeAuthRepository(_ada), FakeBiometrics(), on: false);
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
    });
  });
}
