import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/orders/order_screen.dart';
import 'package:gud_meal_customer/providers.dart';

/// An order whose payment page was closed before paying (found on a phone test: the order sat at
/// "Awaiting payment" with only a Cancel button).
class _UnpaidOrderApi extends GudMealApi {
  _UnpaidOrderApi() : super(baseUrl: 'http://fake', token: () async => 't');
  final checkouts = <String?>[];
  final keys = <String>[];
  final cancelled = <String>[];
  var paid = false;
  ApiException? fails;

  @override
  Future<Order> order(String id) async => Order(
        id: id,
        shortCode: 'MZGBBZ',
        vertical: 'waybill',
        status: paid ? 'paid' : 'pending_payment',
        restaurantName: 'Yummy Chops Waybill',
        payment: OrderPayment(provider: 'local_sandbox', status: paid ? 'paid' : 'pending'),
      );

  @override
  Future<CheckoutResult> checkout(String orderId, String idempotencyKey, {String? provider}) async {
    checkouts.add(provider);
    keys.add(idempotencyKey);
    if (fails != null) throw fails!;
    if (provider == 'wallet') paid = true;
    return CheckoutResult(orderId: orderId, reference: 'YC-MZGBBZ-1', amountKobo: 1333000, provider: provider ?? 'local_sandbox');
  }

  @override
  Future<Order> cancel(String id) async {
    if (fails != null) throw fails!;
    cancelled.add(id);
    return order(id);
  }
}

Future<void> _open(WidgetTester tester, _UnpaidOrderApi api) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository()), apiProvider.overrideWithValue(api)],
    child: MaterialApp.router(
      theme: buildGudMealTheme(Brightness.light),
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const OrderScreen(id: 'o1')),
        GoRoute(path: '/orders/:id/receipt', builder: (_, s) => Scaffold(body: Text('RECEIPT ${s.pathParameters['id']}'))),
      ]),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unpaid order can still be paid from the order screen', (tester) async {
    final api = _UnpaidOrderApi();
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository()), apiProvider.overrideWithValue(api)],
      child: MaterialApp.router(
        theme: buildGudMealTheme(Brightness.light),
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, _) => const OrderScreen(id: 'o1')),
          GoRoute(path: '/orders/:id/receipt', builder: (_, s) => Scaffold(body: Text('RECEIPT ${s.pathParameters['id']}'))),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Finish paying'), findsOneWidget);
    expect(find.text('Pay by card, transfer or USSD'), findsOneWidget);

    await tester.tap(find.text('Pay from my Yummy Chops wallet'));
    await tester.pumpAndSettle();
    expect(api.checkouts, ['wallet']);
    expect(find.textContaining('Finish paying'), findsNothing); // paid: the order goes ahead
    expect(find.text('RECEIPT o1'), findsOneWidget); // and the receipt printer comes up (ADR-0019)

    await tester.pumpWidget(const SizedBox()); // dispose the screen and its refresh timer
  });

  testWidgets('paying again after a lost connection is the same payment, not a second one', (tester) async {
    final api = _UnpaidOrderApi()..fails = ApiException(0, 'network_error', "We couldn't reach Yummy Chops.");
    await _open(tester, api);
    await tester.tap(find.text('Pay from my Yummy Chops wallet'));
    await tester.pumpAndSettle();
    expect(find.text("We couldn't reach Yummy Chops."), findsOneWidget);

    api.fails = null;
    await tester.tap(find.text('Pay from my Yummy Chops wallet'));
    await tester.pumpAndSettle();
    expect(api.keys, hasLength(2));
    expect(api.keys[1], api.keys[0]); // the server carries out a key only once
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cancel order asks first, and says so when the order can no longer be cancelled', (tester) async {
    final api = _UnpaidOrderApi();
    await _open(tester, api);
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this order?'), findsOneWidget);
    await tester.tap(find.text('Keep my order'));
    await tester.pumpAndSettle();
    expect(api.cancelled, isEmpty);

    api.fails = ApiException(409, 'invalid_transition', 'This order can no longer be cancelled');
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-cancel-order')));
    await tester.pumpAndSettle();
    expect(find.text('This order can no longer be cancelled'), findsOneWidget);

    api.fails = null;
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-cancel-order')));
    await tester.pumpAndSettle();
    expect(api.cancelled, ['o1']);
    await tester.pumpWidget(const SizedBox());
  });
}
