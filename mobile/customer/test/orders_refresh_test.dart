import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/orders/orders_screen.dart';
import 'package:gud_meal_customer/providers.dart';

/// Returns the next status each time the orders list is read.
class _MovingOrderApi extends GudMealApi {
  _MovingOrderApi(this.statuses) : super(baseUrl: 'http://fake', token: () async => 'tok');
  final List<String> statuses;
  int reads = 0;

  @override
  Future<OrderSummary> orderSummary() async => const OrderSummary();

  @override
  Future<List<Order>> myOrders() async {
    final status = statuses[reads < statuses.length ? reads : statuses.length - 1];
    reads++;
    return [Order(id: 'o1', shortCode: 'YWGAZW', status: status, restaurantName: 'Jollof Junction')];
  }
}

void main() {
  test('an order in progress keeps its status up to date in the list', () {
    fakeAsync((time) {
      final api = _MovingOrderApi(['pending_payment', 'paid', 'in_transit', 'completed']);
      final container = ProviderContainer(overrides: [apiProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      final sub = container.listen(myOrdersProvider, (_, _) {});
      addTearDown(sub.close);
      String? status() => container.read(myOrdersProvider).value?.single.status;

      time.flushMicrotasks();
      expect(status(), 'pending_payment');
      time.elapse(ordersRefreshInterval);
      time.flushMicrotasks();
      expect(status(), 'paid');
      time.elapse(ordersRefreshInterval);
      time.flushMicrotasks();
      expect(status(), 'in_transit');
      time.elapse(ordersRefreshInterval);
      time.flushMicrotasks();
      expect(status(), 'completed');
      // Nothing is in progress any more: the list stops asking.
      final reads = api.reads;
      time.elapse(ordersRefreshInterval * 4);
      time.flushMicrotasks();
      expect(api.reads, reads);
    });
  });

  test('every status of an order still on its way is "In progress" (the OrderStatus of the API)', () {
    expect(activeOrderStatuses, containsAll(<String>[
      'pending_payment', 'paid', 'submitted_to_restaurant', 'restaurant_accepted', 'preparing', 'ready_for_pickup',
      'rider_assigned', 'picked_up', 'in_transit',
    ]));
    for (final finished in ['draft', 'completed', 'cancelled', 'refunded', 'partially_refunded']) {
      expect(activeOrderStatuses, isNot(contains(finished)));
    }
  });

  testWidgets('the Orders tab reads the list again when it shows again and when the app comes back', (tester) async {
    // Found on the online test: an empty list read before paying was shown for ever after.
    final api = _MovingOrderApi(['completed']);
    final shown = ValueNotifier(true);
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))), apiProvider.overrideWithValue(api)],
      child: MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: shown,
          builder: (_, on, _) => TickerMode(enabled: on, child: const OrdersScreen()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(api.reads, 1);

    shown.value = false; // another tab
    await tester.pumpAndSettle();
    expect(api.reads, 1);
    shown.value = true; // back on Orders
    await tester.pumpAndSettle();
    expect(api.reads, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(api.reads, 3);

    // Pull to refresh.
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(api.reads, 4);
  });
}
