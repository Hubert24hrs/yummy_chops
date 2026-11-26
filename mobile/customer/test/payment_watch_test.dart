import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/orders/order_screen.dart';
import 'package:gud_meal_customer/features/orders/payment_watch.dart';
import 'package:gud_meal_customer/providers.dart';

/// Paystack's webhook does not reach the server, so only `POST /v1/payments/verify` tells it the order is paid.
class _PayingApi extends GudMealApi {
  _PayingApi(this.answers) : super(baseUrl: 'http://fake', token: () async => 't');

  /// What verify says each time it is asked (the last one repeats).
  final List<String> answers;
  final verified = <String>[];
  int orderListReads = 0;
  bool get paid => verified.isNotEmpty && _answer(verified.length - 1) == 'succeeded';

  String _answer(int i) => answers[i < answers.length ? i : answers.length - 1];

  @override
  Future<String> verifyPayment(String reference) async {
    verified.add(reference);
    return _answer(verified.length - 1);
  }

  @override
  Future<Order> order(String id) async => Order(
        id: id,
        shortCode: 'MZGBBZ',
        status: paid ? 'paid' : 'pending_payment',
        restaurantName: 'Suya Lane',
        payment: OrderPayment(provider: 'paystack', status: paid ? 'paid' : 'pending'),
      );

  @override
  Future<List<Order>> myOrders() async {
    orderListReads++;
    return const [];
  }

  @override
  Future<WalletOverview> wallet() async => const WalletOverview(balanceKobo: 0);
}

class _Page extends PaymentPage {
  int closed = 0;
  @override
  Future<void> open(Uri url) async {}
  @override
  Future<void> close() async => closed++;
}

Future<void> _open(WidgetTester tester, _PayingApi api, _Page page, {bool paidTogether = false, PaymentWatchTiming? timing}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
      apiProvider.overrideWithValue(api),
      paymentPageProvider.overrideWithValue(page),
      if (timing != null) paymentWatchTimingProvider.overrideWithValue(timing),
    ],
    child: MaterialApp.router(
      theme: buildGudMealTheme(Brightness.light),
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => OrderScreen(id: 'o1', paymentReference: 'YC-1', paidTogether: paidTogether)),
        GoRoute(path: '/orders', builder: (_, _) => const Scaffold(body: Text('ORDERS'))),
        GoRoute(path: '/orders/:id/receipt', builder: (_, s) => Scaffold(body: Text('RECEIPT ${s.pathParameters['id']}'))),
      ]),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('while the payment page is open the app asks every 2 s, and closes it as soon as it is paid', (tester) async {
    // Paystack calls a page that is still open "abandoned": that never closes it.
    final api = _PayingApi(['abandoned', 'pending', 'succeeded']);
    final page = _Page();
    await _open(tester, api, page);
    expect(api.verified, isEmpty);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(api.verified, ['YC-1', 'YC-1']);
    expect(page.closed, 0);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(page.closed, 1);
    expect(find.text('Payment received'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('RECEIPT o1'), findsOneWidget, reason: 'the order is paid: the receipt printer comes up (ADR-0019)');

    // Settled: nothing more is asked.
    await tester.pump(const Duration(seconds: 10));
    expect(api.verified, hasLength(3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('one payment for several shops: once paid, Orders lists them all', (tester) async {
    final api = _PayingApi(['succeeded']);
    final page = _Page();
    await _open(tester, api, page, paidTogether: true);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(page.closed, 1);
    expect(find.text('ORDERS'), findsOneWidget);
    expect(find.textContaining('Payment received'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a refused payment closes the page and says so', (tester) async {
    final api = _PayingApi(['failed']);
    final page = _Page();
    await _open(tester, api, page);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(page.closed, 1);
    expect(find.text('The payment did not go through. Choose a way to pay to try again.'), findsOneWidget);
    expect(find.text('Payment received'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('coming back to the app asks straight away; asking stops after the time limit', (tester) async {
    final api = _PayingApi(['abandoned']);
    final page = _Page();
    await _open(tester, api, page, timing: (every: const Duration(seconds: 2), giveUpAfter: const Duration(seconds: 6)));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(api.verified, ['YC-1'], reason: 'asked at once, without waiting for the next 2 s');
    expect(find.textContaining('The payment is not finished yet'), findsOneWidget);
    expect(page.closed, 0);

    await tester.pump(const Duration(seconds: 30));
    expect(api.verified, hasLength(4), reason: '3 more times in 6 s, then no more');
    await tester.pumpWidget(const SizedBox());
  });
}
