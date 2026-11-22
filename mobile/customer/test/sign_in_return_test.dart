import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/app.dart';
import 'package:gud_meal_customer/providers.dart';

/// Signing in from the Orders tab must bring the customer back to the Orders tab, signed in.
///
/// Found in the owner's preview: the sign-in worked, but the Sign in screen stayed open (back on its Phone tab),
/// because the router rebuilt its pages when the sign-in state changed and the old screen could not close itself.
void main() {
  mainWhereToDeliver();
  testWidgets('sign in from the Orders tab returns to the Orders tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final auth = FakeAuthRepository(null);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        forYouProvider.overrideWith((ref) async => const <RestaurantCard>[]),
        myOrdersProvider.overrideWith((ref) async => const <Order>[]),
        orderSummaryProvider.overrideWith((ref) async => const OrderSummary()),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: ref.watch(routerProvider)),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Track your orders'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Send code'), findsOneWidget); // the Sign in screen, on its Phone tab

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'ada@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'a-test-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    expect(find.text('Send code'), findsNothing, reason: 'the Sign in screen must close');
    expect(find.text('Password'), findsNothing);
    expect(find.text('In progress'), findsOneWidget); // the Orders tab, signed in
    expect(find.text('History'), findsOneWidget);
  });
}

/// No saved address after signing in: the customer first chooses where to deliver (GPS, typing it or the map), then
/// lands where they were going. The router may swap the Sign in screen for a fresh copy; the step still shows once.
class _NoAddressesApi extends GudMealApi {
  _NoAddressesApi() : super(baseUrl: 'http://fake', token: () async => 'tok');

  @override
  Future<List<DeliveryAddress>> addresses() async => const [];
}

void mainWhereToDeliver() {
  testWidgets('a fresh sign-in with no saved address asks where to deliver, then returns to Orders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final auth = FakeAuthRepository(null);

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
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'new@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'a-test-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Where should we deliver?'), findsOneWidget);
    expect(find.text('Use my current location'), findsOneWidget);
    expect(find.text('Type my address'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('where-later')));
    await tester.pumpAndSettle();

    expect(find.text('Where should we deliver?'), findsNothing);
    expect(find.text('Send code'), findsNothing, reason: 'the Sign in screen must close');
    expect(find.text('In progress'), findsOneWidget); // back on the Orders tab, signed in
  });
}
