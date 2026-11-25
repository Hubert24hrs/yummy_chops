import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/providers.dart';

/// Returns the next status each time the orders list is read.
class _MovingOrderApi extends GudMealApi {
  _MovingOrderApi(this.statuses) : super(baseUrl: 'http://fake', token: () async => 'tok');
  final List<String> statuses;
  int reads = 0;

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
}
