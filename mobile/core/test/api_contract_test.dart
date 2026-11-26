import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Responses copied from the running API. Both broke the rider app in a phone test: the earnings field name has a
/// digit (`earned_last_7_days_kobo`, which code generation spells `earned_last7_days_kobo`) and riders get
/// `items` (no prices) instead of the customer's priced `lines`.
void main() {
  test('rider earnings parse the API response', () {
    final earnings = Earnings.fromJson({
      'balance_kobo': 261190,
      'pending_payouts_kobo': 0,
      'cash_held_kobo': 0,
      'available_kobo': 261190,
      'deliveries_completed': 1,
      'earned_last_7_days_kobo': 60990,
      'payouts': [
        {'id': 'p1', 'amount_kobo': 100000, 'status': 'paid', 'requested_at': '2026-11-16T23:43:08.785935'},
      ],
    });
    expect(earnings.earnedLast7DaysKobo, 60990);
    expect(earnings.availableKobo, 261190);
  });

  test('an offer counts down from the seconds left, whatever the clocks say', () {
    final receivedAt = DateTime.utc(2026, 11, 17, 4, 0, 0);
    final json = <String, dynamic>{
      'id': 'a1',
      'order_id': 'o1',
      'restaurant_name': 'Suya Lane',
      'distance_to_restaurant_km': 1.2,
      'payout_kobo': 60990,
      // The server's clock is 16 s slow: by this phone's clock the offer would seem to have 24 s left, not 40.
      'expires_at': '2026-11-17T04:00:24Z',
      'expires_in_seconds': 40,
      'pickup': {'lat': 6.43, 'lng': 3.42},
    };
    expect(offerFromJson(json, receivedAt).expiresAt, receivedAt.add(const Duration(seconds: 40)));
    expect(offerFromJson(json, receivedAt).expiresInSeconds, 40);
    // A server that does not send the seconds left: keep its deadline.
    final older = Map<String, dynamic>.of(json)..remove('expires_in_seconds');
    expect(offerFromJson(older, receivedAt).expiresAt.toUtc(), DateTime.utc(2026, 11, 17, 4, 0, 24));
  });

  test("a rider's order lists what to collect without prices", () {
    final order = Order.fromJson({
      'id': 'o1',
      'short_code': 'D6JM7E',
      'vertical': 'food',
      'status': 'rider_assigned',
      'restaurant_name': 'Jollof Junction',
      'items': [
        {'name': 'Party Jollof Rice', 'quantity': 2},
        {'name': 'Chapman', 'quantity': 1},
      ],
      'rider_pay_kobo': 60990,
    });
    expect(order.items.map((i) => '${i.quantity}× ${i.name}'), ['2× Party Jollof Rice', '1× Chapman']);
    expect(order.lines, isEmpty);
  });
}
