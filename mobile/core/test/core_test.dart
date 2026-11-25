import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Records requests and replies with canned JSON — no network.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body);
  final int status;
  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const orderJson = {
  'id': 'o1',
  'short_code': 'BGHZ6Z',
  'status': 'in_transit',
  'restaurant_name': 'Suya Lane',
  'fulfillment': 'delivery',
  'lines': [
    {'item_id': 'sl-beef-suya', 'name': 'Beef Suya (250g)', 'quantity': 2, 'line_total_kobo': 900000, 'selection_labels': ['Yaji level: Medium']}
  ],
  'breakdown': {
    'subtotal_kobo': 1150000, 'delivery_fee_kobo': 175000, 'service_fee_kobo': 57500, 'small_order_fee_kobo': 0,
    'vat_kobo': 17438, 'discount_kobo': 50000, 'total_kobo': 1349938, 'voucher_code': 'WELCOME500', 'discount_funded_by': 'platform'
  },
  'progress': {'step': 4, 'total_steps': 5, 'label': 'On the way to you'},
  'rider_name': 'Chidi Okafor',
  'estimated_delivery_at': '2026-11-14T23:16:05.349906Z',
  'unknown_future_field': true,
};

/// Stands for what the app keeps in memory: counts how many times it was started.
class _Memory extends StatefulWidget {
  const _Memory({required this.onStart});
  final VoidCallback onStart;

  @override
  State<_Memory> createState() => _MemoryState();
}

class _MemoryState extends State<_Memory> {
  @override
  void initState() {
    super.initState();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  group('formatting', () {
    test('naira from kobo', () {
      expect(formatNaira(1000000), '₦10,000');
      expect(formatNaira(150050), '₦1,500.50');
      expect(formatNaira(-500), '-₦5');
      expect(formatNaira(null), '—');
    });
    test('Lagos time is UTC+1', () {
      expect(formatLagosTime(DateTime.utc(2026, 11, 14, 23, 16)), '12:16 AM');
    });
    test('every order status has a label', () {
      expect(orderStatusLabels.length, 17);
      expect(statusLabel('in_transit'), 'On the way');
    });
  });

  group('option rules mirror the API', () {
    const group = OptionGroup(id: 'p', name: 'Protein', minSelect: 1, maxSelect: 1, choices: [
      OptionChoice(id: 'chicken', name: 'Chicken'),
      OptionChoice(id: 'turkey', name: 'Turkey', priceDeltaKobo: 150000),
    ]);
    const item = MenuItem(id: 'i', restaurantId: 'r', name: 'Jollof', priceKobo: 550000, optionGroupIds: ['p']);
    test('required group', () {
      expect(validateSelections(item, {'p': group}, {}), contains('Choose 1'));
      expect(validateSelections(item, {'p': group}, {'p': ['turkey']}), isNull);
    });
    test('extras price', () {
      expect(optionsPriceKobo(item, {'p': group}, {'p': ['turkey']}), 150000);
    });
  });

  test('parses API order payloads (snake_case, unknown fields ignored)', () {
    final order = Order.fromJson(orderJson);
    expect(order.shortCode, 'BGHZ6Z');
    expect(order.breakdown!.totalKobo, 1349938);
    expect(order.lines.single.selectionLabels, ['Yaji level: Medium']);
    expect(order.progress!.step, 4);
    expect(order.estimatedDeliveryAt!.isUtc, isTrue);
  });

  test('cart lines serialise to the API shape', () {
    const line = CartLine(itemId: 'jj', quantity: 2, selections: [OptionSelection(groupId: 'p', choiceIds: ['chicken'])]);
    expect(line.toJson(), {
      'item_id': 'jj',
      'quantity': 2,
      'selections': [
        {'group_id': 'p', 'choice_ids': ['chicken']}
      ],
    });
  });

  group('GudMealApi', () {
    test('sends bearer token and idempotency key', () async {
      final adapter = FakeAdapter(201, orderJson);
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      final api = GudMealApi(baseUrl: 'http://api.test', token: () async => 'tok-123', dio: dio);
      final order = await api.createOrder('q1', 'app-key-12345678');
      expect(order.id, 'o1');
      final req = adapter.requests.single;
      expect(req.path, '/v1/orders');
      expect(req.headers['Authorization'], 'Bearer tok-123');
      expect(req.headers['Idempotency-Key'], 'app-key-12345678');
    });

    test('checkoutMany posts every order id once, with the key and the provider', () async {
      final adapter = FakeAdapter(200, {
        'order_ids': ['o1', 'o2'],
        'provider': 'local_sandbox',
        'reference': 'YC-B-1A2B3C4D',
        'authorization_url': 'https://pay.test/YC-B-1A2B3C4D',
        'amount_kobo': 1234500,
        'currency': 'NGN',
        'payment_status': 'pending',
        'orders': [
          {'order_id': 'o1', 'status': 'pending_payment', 'amount_kobo': 600000},
          {'order_id': 'o2', 'status': 'pending_payment', 'amount_kobo': 634500},
        ],
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      final api = GudMealApi(baseUrl: 'http://api.test', token: () async => 'tok-123', dio: dio);
      final result = await api.checkoutMany(['o1', 'o2'], 'checkout-key-1', provider: 'wallet');
      final req = adapter.requests.single;
      expect(req.path, '/v1/checkouts');
      expect(req.method, 'POST');
      expect(req.headers['Idempotency-Key'], 'checkout-key-1');
      expect(req.data, {'order_ids': ['o1', 'o2'], 'provider': 'wallet'});
      expect(result.orderIds, ['o1', 'o2']);
      expect(result.reference, 'YC-B-1A2B3C4D');
      expect(result.authorizationUrl, 'https://pay.test/YC-B-1A2B3C4D');
      expect(result.amountKobo, 1234500);
      expect(result.paymentStatus, 'pending');
      expect(result.orders.map((o) => o.amountKobo), [600000, 634500]);

      await api.checkoutMany(['o1'], 'checkout-key-2');
      expect(adapter.requests.last.data, {'order_ids': ['o1']}, reason: 'no provider: the server picks the gateway');
    });

    test('maps API errors to ApiException', () async {
      final adapter = FakeAdapter(409, {
        'error': {'code': 'price_changed', 'message': 'Prices changed', 'details': {'new_total_kobo': 1}}
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      final api = GudMealApi(baseUrl: 'http://api.test', token: () async => null, dio: dio);
      await expectLater(
        api.order('x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'price_changed').having((e) => e.status, 'status', 409)),
      );
    });

    test('idempotency keys are unique', () {
      expect(newIdempotencyKey(), isNot(newIdempotencyKey()));
      expect(newIdempotencyKey('rider').startsWith('rider-'), isTrue);
    });

    test('discover feed: query and parsing', () async {
      final adapter = FakeAdapter(200, {
        'city': 'lagos',
        'generated_at': '2026-11-15T10:00:00Z',
        'sections': [
          {
            'id': 'most_loved',
            'title': 'Most loved dishes',
            'subtitle': 'What everyone near you is ordering',
            'dishes': [
              {
                'item_id': 'jj-party-jollof',
                'restaurant_id': 'r-jollof-junction',
                'restaurant_name': 'Jollof Junction',
                'area': 'Lekki Phase 1',
                'city': 'lagos',
                'name': 'Party Jollof Rice',
                'description': 'Smoky firewood jollof.',
                'price_kobo': 550000,
                'image_url': null,
                'art': 'rice',
                'kind': 'main',
                'tags': ['jollof', 'chicken'],
                'dietary': [],
                'allergens': ['celery'],
                'spice_level': 1,
                'serves': 1,
                'prep_minutes': 18,
                'likes': 980,
                'rating': 4.7,
                'rating_count': 1240,
                'eyebrow': '#1 Most loved dish',
                'has_options': true,
                'is_available': true,
                'is_open': false,
                'is_accepting_orders': true,
                'is_new_kitchen': false,
                'distance_km': 0.4,
                'eta_minutes': 24,
                'delivery_fee_kobo': 60000,
                'delivers_to_location': true,
                'future_field': 'ignored',
              },
            ],
          },
          {'id': 'new_kitchens', 'title': 'New kitchen discoveries', 'subtitle': '', 'dishes': []},
        ],
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
      final api = GudMealApi(baseUrl: 'http://api.test', token: () async => null, dio: dio);
      final feed = await api.discover(city: 'lagos', near: const GeoPoint(lat: 6.44, lng: 3.47), limit: 5);

      final q = adapter.requests.single;
      expect(q.path, '/v1/discover/dishes');
      expect(q.queryParameters, {'city': 'lagos', 'lat': 6.44, 'lng': 3.47, 'limit': 5});
      expect(feed.city, 'lagos');
      expect(feed.sections, hasLength(2));
      expect(feed.nonEmpty.map((s) => s.id), ['most_loved']);
      expect(feed.sections.first.shortTitle, 'Most loved');
      final dish = feed.sections.first.dishes.single;
      expect(dish.name, 'Party Jollof Rice');
      expect(dish.priceKobo, 550000);
      expect(dish.art, 'rice');
      expect(dish.rating, 4.7);
      expect(dish.likes, 980);
      expect(dish.hasOptions, isTrue);
      expect(dish.canOrderNow, isFalse, reason: 'the kitchen is closed');
      expect(dish.highlights, ['jollof', 'chicken', 'contains celery']);
      expect(dish.deliveryFeeKobo, 60000);
    });
  });

  test('fake auth repository signs in and out', () async {
    final auth = FakeAuthRepository();
    await auth.signInWithEmail('ada@example.com', 'secret1');
    expect(auth.currentUser?.email, 'ada@example.com');
    expect(await auth.idToken(), startsWith('fake-token-'));
    await auth.signOut();
    expect(auth.currentUser, isNull);
  });

  group('an idempotency key lasts until the server answers', () {
    ApiException error(int status, String code) => ApiException(status, code, code);

    test('which errors are an answer', () {
      expect(error(0, 'network_error').isFinalAnswer, isFalse); // no connection, a timeout
      expect(error(503, 'service_unavailable').isFinalAnswer, isFalse);
      expect(error(429, 'rate_limited').isFinalAnswer, isFalse);
      expect(error(409, 'conflict').isFinalAnswer, isFalse); // the first attempt is still being worked on
      expect(error(409, 'quote_expired').isFinalAnswer, isTrue);
      expect(error(409, 'idempotency_conflict').isFinalAnswer, isTrue);
      expect(error(422, 'validation_failed').isFinalAnswer, isTrue);
      expect(error(409, 'quote_expired').needsNewQuote, isTrue);
      expect(error(409, 'price_changed').needsNewQuote, isTrue);
      expect(error(409, 'item_unavailable').needsNewQuote, isFalse);
    });

    test('a retry keeps the key; an answer or a changed request gets a new one', () async {
      final key = IdempotencyKey('payout');
      final sent = <String>[];
      Future<void> attempt(Object request, [ApiException? fails]) => key.send(request, (k) async {
            sent.add(k);
            if (fails != null) throw fails;
          });

      await expectLater(attempt(('gtb', 500000), error(0, 'network_error')), throwsA(isA<ApiException>()));
      await attempt(('gtb', 500000)); // the retry: the same request with the same key cannot happen twice
      expect(sent[1], sent[0]);
      await attempt(('gtb', 500000)); // the server answered: asking again is a second withdrawal
      expect(sent[2], isNot(sent[1]));

      await expectLater(attempt(('gtb', 500000), error(0, 'network_error')), throwsA(isA<ApiException>()));
      await attempt(('gtb', 700000)); // a changed request: the API refuses an old key with a new request
      expect(sent[4], isNot(sent[3]));

      await expectLater(attempt(('gtb', 100), error(422, 'validation_failed')), throwsA(isA<ApiException>()));
      await attempt(('gtb', 100)); // refused: the same key would only get the refusal again
      expect(sent[6], isNot(sent[5]));
      expect(sent.every((k) => k.startsWith('payout-')), isTrue);
    });
  });

  testWidgets('what is in memory starts afresh when the signed-in user leaves, not when one signs in', (tester) async {
    final auth = FakeAuthRepository();
    var starts = 0;
    await tester.pumpWidget(PerUserScope(auth: auth, child: _Memory(onStart: () => starts++)));
    await tester.pump();
    expect(starts, 1);

    await auth.signInWithEmail('ada@example.com', 'secret1');
    await tester.pump();
    expect(starts, 1, reason: 'signing in keeps what a visitor chose, such as their cart');

    await auth.signOut();
    await tester.pump();
    expect(starts, 2, reason: 'nothing of the last user is left for the next');

    await auth.signInWithEmail('bayo@example.com', 'secret1');
    await tester.pump();
    expect(starts, 2);
  });
}
