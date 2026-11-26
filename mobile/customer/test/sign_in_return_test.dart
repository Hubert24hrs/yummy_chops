import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/app.dart';
import 'package:gud_meal_customer/features/orders/orders_screen.dart';
import 'package:gud_meal_customer/providers.dart';

/// Guest mode: nobody has to sign in to order. The app signs in a guest by itself; only Profile offers to sign in.
class _NoAddressesApi extends GudMealApi {
  _NoAddressesApi() : super(baseUrl: 'http://fake', token: () async => 'tok');

  @override
  Future<List<DeliveryAddress>> addresses() async => const [];
}

Future<void> _pumpApp(WidgetTester tester, FakeAuthRepository auth) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      apiProvider.overrideWithValue(_NoAddressesApi()),
      forYouProvider.overrideWith((ref) async => const <RestaurantCard>[]),
      myOrdersProvider.overrideWith((ref) async => const <Order>[]),
      orderSummaryProvider.overrideWith((ref) async => const OrderSummary()),
    ],
    child: const GudMealApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a guest gets in without a sign-in screen: asked where to deliver once, then Orders and checkout work',
      (tester) async {
    final auth = FakeAuthRepository(null);
    await _pumpApp(tester, auth);

    expect(auth.currentUser?.isAnonymous, isTrue);
    expect(auth.anonymousSignIns, 1);
    // First launch: the guest is asked where to deliver (no saved address yet).
    expect(find.text('Where should we deliver?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('where-later')));
    await tester.pumpAndSettle();
    expect(find.text('Where should we deliver?'), findsNothing);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Send code'), findsNothing, reason: 'no sign-in screen');
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);

    GoRouter.of(tester.element(find.byType(OrdersScreen))).push('/checkout');
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget); // checkout itself, not a sign-in screen
    expect(find.text('Send code'), findsNothing);
    expect(auth.anonymousSignIns, 1, reason: 'the guest signs in once');
  });

  testWidgets('when the guest sign-in fails (no network) the screen says so, and Try again works', (tester) async {
    final auth = FakeAuthRepository(null)..anonymousSignInError = Exception('offline');
    await _pumpApp(tester, auth);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guest-error')), findsOneWidget);
    expect(find.text('In progress'), findsNothing);

    auth.anonymousSignInError = null;
    await tester.tap(find.byKey(const ValueKey('guest-retry')));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.isAnonymous, isTrue);
    if (find.text('Where should we deliver?').evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('where-later')));
      await tester.pumpAndSettle();
    }
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('Profile → Other ways to sign in: email sign-in asks where to deliver, then returns to Profile', (tester) async {
    final auth = FakeAuthRepository(const GmUser(uid: 'guest-7', isAnonymous: true)); // a guest session restored at start
    await _pumpApp(tester, auth);
    expect(find.text('Where should we deliver?'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Save your account'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('other-sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('Send code'), findsOneWidget); // the Sign in screen, on its Phone tab

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ada@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'a-test-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Where should we deliver?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('where-later')));
    await tester.pumpAndSettle();

    expect(auth.currentUser?.email, 'ada@example.com');
    expect(find.text('Send code'), findsNothing, reason: 'the Sign in screen must close');
    expect(find.text('ada@example.com'), findsOneWidget); // Profile, signed in
    expect(find.text('Save your account'), findsNothing);
  });

  testWidgets('signing out from Profile starts afresh with a new guest', (tester) async {
    final auth = FakeAuthRepository(const GmUser(uid: 'u1', email: 'ada@example.com', name: 'Ada'));
    await _pumpApp(tester, auth);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    if (find.text('Where should we deliver?').evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('where-later')));
      await tester.pumpAndSettle();
    }

    expect(auth.currentUser?.isAnonymous, isTrue);
    expect(auth.anonymousSignIns, 1);
    expect(find.text('Save your account'), findsOneWidget);
  });
}
