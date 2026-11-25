import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// The rider trip contract (GET /v1/rider/trip, offer `pickups`, order `restaurant_phone` / `trip_id`).
class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

GudMealApi _api(_Adapter adapter) =>
    GudMealApi(baseUrl: 'http://api.test', token: () async => 't', dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter);

const _offer = <String, dynamic>{
  'id': 'a1',
  'order_id': 'o1',
  'restaurant_name': 'CareFirst Pharmacy',
  'distance_to_restaurant_km': 1.2,
  'payout_kobo': 110990,
  'expires_at': '2026-11-25T04:00:24Z',
  'pickup': {'lat': 6.43, 'lng': 3.42},
};

void main() {
  test('an offer lists every order and place of the trip', () {
    final offer = DeliveryOffer.fromJson({
      ..._offer,
      'trip_order_ids': ['o1', 'o2'],
      'pickups': [
        {'order_id': 'o1', 'name': 'CareFirst Pharmacy', 'address': '3 Fola Osibo Road, Lekki', 'location': {'lat': 6.44, 'lng': 3.47}},
        {'order_id': 'o2', 'name': 'Jollof Junction', 'address': '1 Admiralty Way'},
      ],
    });
    expect(offer.tripOrderIds, ['o1', 'o2']);
    expect(offer.pickups.map((p) => p.name), ['CareFirst Pharmacy', 'Jollof Junction']);
    expect(offer.pickups.first.location?.lat, 6.44);
    expect(offer.pickups.last.location, isNull);
  });

  test('an offer from an older server still parses', () {
    final offer = DeliveryOffer.fromJson(_offer);
    expect(offer.tripOrderIds, isEmpty);
    expect(offer.pickups, isEmpty);
  });

  test("a rider's order has the shop's phone and its trip", () {
    final order = Order.fromJson({
      'id': 'o1',
      'short_code': 'AB12CD',
      'status': 'rider_assigned',
      'restaurant_name': 'CareFirst Pharmacy',
      'restaurant_phone': '+2348011111111',
      'trip_id': 'T-1',
    });
    expect(order.restaurantPhone, '+2348011111111');
    expect(order.tripId, 'T-1');
    expect(Order.fromJson({'id': 'o', 'short_code': 'X', 'status': 's', 'restaurant_name': 'n'}).tripId, isNull);
  });

  test('riderTrips reads the planned trips', () async {
    final adapter = _Adapter({
      'trips': [
        {
          'trip_id': 'T-1',
          'order_ids': ['o1', 'o2'],
          'stops': [
            {
              'kind': 'pickup', 'order_id': 'o1', 'short_code': 'AB12CD', 'name': 'CareFirst Pharmacy',
              'vertical': 'pharmacy', 'address': '3 Fola Osibo Road', 'location': {'lat': 6.44, 'lng': 3.47},
              'phone': '+2348011111111',
              'items': [
                {'name': 'Vitamin C', 'quantity': 2, 'options': ['1000 mg']},
                {'name': 'Plaster'},
              ],
              'status': 'ready_for_pickup', 'ready': true, 'done': false, 'leg_km': 2, 'leg_minutes': 9,
            },
            {
              'kind': 'dropoff', 'order_ids': ['o1', 'o2'], 'name': 'Ada Obi', 'address': '5 Bisola, Lekki Phase 1',
              'location': {'lat': 6.45, 'lng': 3.48}, 'phone': '+2348022222222', 'instructions': 'Gate 2',
              'cash_to_collect_kobo': 0, 'done': false, 'leg_km': 5.1, 'leg_minutes': 17,
            },
          ],
          'next_stop': 0,
          'total_km': 7.5,
          'total_minutes': 26,
          'route_source': 'google',
          'navigation_url': 'https://www.google.com/maps/dir/?api=1&destination=6.45,3.48',
          'payout_kobo': 110990,
        },
      ],
    });
    final trips = await _api(adapter).riderTrips();
    expect(adapter.requests.single.path, '/v1/rider/trip');
    final trip = trips.single;
    expect(trip.tripId, 'T-1');
    expect(trip.orderIds, ['o1', 'o2']);
    expect(trip.totalKm, 7.5);
    expect(trip.payoutKobo, 110990);
    final pickup = trip.stops.first;
    expect(pickup.isPickup, isTrue);
    expect(pickup.phone, '+2348011111111');
    expect(pickup.legKm, 2.0);
    expect(pickup.items.first.options, ['1000 mg']);
    expect(pickup.items.last.quantity, 1);
    final dropoff = trip.stops.last;
    expect(dropoff.isPickup, isFalse);
    expect(dropoff.orderIds, ['o1', 'o2']);
    expect(dropoff.instructions, 'Gate 2');
  });

  test('no active work is an empty list', () async {
    expect(await _api(_Adapter({'trips': []})).riderTrips(), isEmpty);
  });
}
