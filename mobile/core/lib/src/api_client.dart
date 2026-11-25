import 'dart:math';

import 'package:dio/dio.dart';

import 'discover.dart';
import 'models.dart';
import 'preferences.dart';
import 'places.dart';

typedef TokenProvider = Future<String?> Function();

class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, [this.details = const {}]);
  final int status;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res == null) {
      return ApiException(0, 'network_error', "We couldn't reach Yummy Chops. Check your connection and try again.");
    }
    final data = res.data;
    if (data is Map && data['error'] is Map) {
      final err = Map<String, dynamic>.from(data['error'] as Map);
      return ApiException(res.statusCode ?? 0, '${err['code'] ?? 'error'}', '${err['message'] ?? 'Something went wrong'}',
          Map<String, dynamic>.from((err['details'] as Map?) ?? const {}));
    }
    if (data is Map && data['detail'] is String) {
      return ApiException(res.statusCode ?? 0, 'error', data['detail'] as String);
    }
    return ApiException(res.statusCode ?? 0, 'error', 'Something went wrong (${res.statusCode})');
  }

  /// True when the server has answered the request, even with a "no": sending it again with the same idempotency
  /// key only gets that answer again, so the next attempt needs a new key. False when the app cannot know what
  /// happened (no connection, a timeout, a failure on the server, too many requests, or the server still working on
  /// the first attempt): the same key then makes sure the request is not carried out twice.
  bool get isFinalAnswer => status >= 400 && status < 500 && status != 401 && status != 429 && code != 'conflict';

  /// True when the price the customer was shown can no longer be used: they need a new one.
  bool get needsNewQuote => code == 'quote_expired' || code == 'price_changed';

  @override
  String toString() => message;
}

/// An offer only lasts seconds, so its countdown must not depend on clocks agreeing. The API says how many seconds
/// are left (`expires_in_seconds`); the deadline is rebuilt on this device's clock from the moment the answer
/// arrived. Found on a phone test: the server's clock was 16 s slow, so a 45 s offer showed 28 s; a phone whose
/// clock runs a minute fast would have shown every offer as expired.
DeliveryOffer offerFromJson(Map<String, dynamic> json, DateTime receivedAt) {
  final offer = DeliveryOffer.fromJson(json);
  final left = json['expires_in_seconds'];
  return left is num ? offer.copyWith(expiresAt: receivedAt.add(Duration(seconds: left.toInt()))) : offer;
}

String newIdempotencyKey([String prefix = 'app']) {
  final r = Random.secure();
  final hex = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  return '$prefix-$hex';
}

/// The idempotency key of one request a screen can send: an order, a withdrawal, a payment.
///
/// The API carries out a key only once: it repeats its stored answer when the key comes back, and refuses a key that
/// comes back with a different request. So the key stays the same while the app does not know what happened (trying
/// again then cannot place an order or move money twice), and a new one is made once the server has answered, yes
/// or no, or the request itself has changed.
class IdempotencyKey {
  IdempotencyKey(this.prefix) : _key = newIdempotencyKey(prefix);

  final String prefix;
  String _key;
  bool _sent = false;
  Object? _request;

  /// The key to send with [request]: what is being asked (a quote's id, an amount, a bank account), as a value
  /// that is equal for equal requests, such as a string or a record.
  String keyFor(Object? request) {
    if (_sent && request != _request) renew();
    _sent = true;
    _request = request;
    return _key;
  }

  /// Makes the next attempt a new request.
  void renew() {
    _key = newIdempotencyKey(prefix);
    _sent = false;
    _request = null;
  }

  /// Sends [request] with its key, and renews the key once the server has answered
  /// (see [ApiException.isFinalAnswer]).
  Future<T> send<T>(Object? request, Future<T> Function(String key) run) async {
    try {
      final result = await run(keyFor(request));
      renew();
      return result;
    } on ApiException catch (e) {
      if (e.isFinalAnswer) renew();
      rethrow;
    }
  }
}

/// Typed client for gudmeal-api. Every request carries the user's Firebase ID token.
class GudMealApi {
  GudMealApi({required String baseUrl, required TokenProvider token, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20))) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final t = await token();
      if (t != null) options.headers['Authorization'] = 'Bearer $t';
      handler.next(options);
    }));
  }

  final Dio _dio;

  Future<T> _call<T>(Future<Response<dynamic>> Function() run, T Function(dynamic data) parse) async {
    try {
      final res = await run();
      return parse(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);
  List<Map<String, dynamic>> _list(dynamic d) => (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ------------------------------------------------------------------- catalog
  /// Merchants for a service: restaurants (`vertical: 'food'`) or beauty shops (`vertical: 'beauty'`).
  Future<List<RestaurantCard>> restaurants({
    GeoPoint? near,
    String? query,
    String? cuisine,
    String vertical = 'food',
    String? category,
    String? city,
    bool pickup = false,
    String sort = 'recommended',
    int limit = 50,
  }) =>
      _call(
          () => _dio.get('/v1/restaurants', queryParameters: {
                if (near != null) 'lat': near.lat,
                if (near != null) 'lng': near.lng,
                if (query != null && query.isNotEmpty) 'q': query,
                'cuisine': ?cuisine,
                'vertical': vertical,
                'category': ?category,
                'city': ?city,
                if (pickup) 'pickup': true,
                'sort': sort,
                'limit': limit,
              }),
          (d) => _list(d).map(RestaurantCard.fromJson).toList());

  Future<List<ServiceInfo>> services({String? city}) =>
      _call(() => _dio.get('/v1/services', queryParameters: {'city': ?city}), (d) => _list(d).map(ServiceInfo.fromJson).toList());

  Future<List<BrowseCategory>> categories(String vertical, {String? city}) => _call(
      () => _dio.get('/v1/services/$vertical/categories', queryParameters: {'city': ?city}),
      (d) => _list(d).map(BrowseCategory.fromJson).toList());

  /// Discover tab: most loved dishes, new kitchens and top-rated kitchens (with delivery fee/ETA near [near]).
  Future<DiscoverFeed> discover({String? city, GeoPoint? near, int limit = 6}) => _call(
      () => _dio.get('/v1/discover/dishes', queryParameters: {
            'city': ?city,
            if (near != null) 'lat': near.lat,
            if (near != null) 'lng': near.lng,
            'limit': limit,
          }),
      (d) => DiscoverFeed.fromJson(_map(d)));

  /// Items (dishes or products) and merchants matching [query].
  Future<({List<Map<String, dynamic>> items, List<RestaurantCard> merchants})> search(String query, {String? vertical, GeoPoint? near}) =>
      _call(
          () => _dio.get('/v1/search', queryParameters: {
                'q': query,
                'vertical': ?vertical,
                if (near != null) 'lat': near.lat,
                if (near != null) 'lng': near.lng,
              }), (d) {
        final m = _map(d);
        return (items: _list(m['items']), merchants: _list(m['restaurants']).map(RestaurantCard.fromJson).toList());
      });

  Future<List<PlaceArea>> areas({String? city}) =>
      _call(() => _dio.get('/v1/places/areas', queryParameters: {'city': ?city}), (d) => _list(d).map(PlaceArea.fromJson).toList());

  // ------------------------------------------------------------------- maps (Google behind the API)
  /// Address suggestions while typing. Reuse one [session] (see [newPlacesSession]) until the user picks one.
  Future<List<PlaceSuggestion>> placeSuggestions(String query, {required String session, GeoPoint? near, String? city}) => _call(
      () => _dio.get('/v1/places/autocomplete', queryParameters: {
            'q': query,
            'session': session,
            if (near != null) 'lat': near.lat,
            if (near != null) 'lng': near.lng,
            'city': ?city,
          }),
      (d) => _list(_map(d)['suggestions']).map(PlaceSuggestion.fromJson).toList());

  /// The chosen suggestion: address, pin and whether Yummy Chops delivers there. Ends the search [session].
  Future<PlaceLookup> placeDetails(String placeId, {String? session}) => _call(
      () => _dio.get('/v1/places/details', queryParameters: {'place_id': placeId, 'session': ?session}),
      (d) => PlaceLookup.fromJson(_map(d)));

  /// "Use my location": the device's own fix plus the nearest address or neighbourhood.
  Future<PlaceLookup> reverseGeocode(GeoPoint point) => _call(
      () => _dio.get('/v1/places/reverse', queryParameters: {'lat': point.lat, 'lng': point.lng}),
      (d) => PlaceLookup.fromJson(_map(d)));

  /// Road distance, arrival time and delivery fee from up to 10 kitchens to [to].
  Future<List<DeliveryEstimate>> deliveryEstimates(List<String> restaurantIds, GeoPoint to) => _call(
      () => _dio.get('/v1/delivery/estimates', queryParameters: {'restaurant_ids': restaurantIds.take(10).join(','), 'lat': to.lat, 'lng': to.lng}),
      (d) => _list(_map(d)['estimates']).map(DeliveryEstimate.fromJson).toList());

  /// Restaurants or shops around [near], closest first, with their public pins (for the nearby map).
  Future<List<MapPlace>> nearbyOnMap({required GeoPoint near, String vertical = 'food', bool openNow = false, int limit = 30}) => _call(
      () => _dio.get('/v1/restaurants', queryParameters: {
            'lat': near.lat,
            'lng': near.lng,
            'vertical': vertical,
            if (openNow) 'open_now': true,
            'sort': 'distance',
            'limit': limit,
          }),
      (d) => [for (final card in _list(d)) ?MapPlace.fromCard(card)]);

  /// Live delivery map data (rider position and route only while a rider is on this delivery).
  Future<LiveTracking> liveTracking(String orderId) =>
      _call(() => _dio.get('/v1/orders/$orderId/tracking'), (d) => LiveTracking.fromJson(_map(d)));

  Future<SupportContacts> supportContacts() =>
      _call(() => _dio.get('/v1/config/public'), (d) => SupportContacts.fromJson(Map<String, dynamic>.from(_map(d)['support'] as Map)));

  Future<RestaurantDetail> restaurant(String id, {GeoPoint? near}) => _call(
      () => _dio.get('/v1/restaurants/$id', queryParameters: {if (near != null) 'lat': near.lat, if (near != null) 'lng': near.lng}),
      (d) => RestaurantDetail.fromJson(_map(d)));

  // ------------------------------------------------------------------- ordering
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher}) =>
      _call(
          () => _dio.post('/v1/quotes', data: {
                'restaurant_id': restaurantId,
                'lines': lines.map((l) => l.toJson()).toList(),
                'fulfillment': fulfillment,
                if (address != null) 'delivery_address': address.toJson(),
                if (voucher != null && voucher.isNotEmpty) 'voucher_code': voucher,
              }),
          (d) => Quote.fromJson(_map(d)));

  Future<Order> createOrder(String quoteId, String idempotencyKey, {String? contactPhone}) => _call(
      () => _dio.post('/v1/orders',
          data: {'quote_id': quoteId, 'channel': 'app', 'contact_phone': ?contactPhone},
          options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => Order.fromJson(_map(d)));

  /// [provider]: null = card/transfer/USSD (the server picks the gateway, with failover), 'wallet' or 'cash'.
  Future<CheckoutResult> checkout(String orderId, String idempotencyKey, {String? provider}) => _call(
      () => _dio.post('/v1/orders/$orderId/checkout',
          data: {'provider': ?provider}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => CheckoutResult.fromJson(_map(d)));

  /// One payment for several orders (a mixed cart: one order per shop). Same [provider] values as [checkout].
  Future<MultiCheckoutResult> checkoutMany(List<String> orderIds, String idempotencyKey, {String? provider}) => _call(
      () => _dio.post('/v1/checkouts',
          data: {'order_ids': orderIds, 'provider': ?provider}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => MultiCheckoutResult.fromJson(_map(d)));

  Future<PaymentOptions> paymentOptions(String orderId) =>
      _call(() => _dio.get('/v1/orders/$orderId/payment-options'), (d) => PaymentOptions.fromJson(_map(d)));

  // ------------------------------------------------------------------- wallet & seller cash on delivery
  Future<WalletOverview> wallet() => _call(() => _dio.get('/v1/wallet'), (d) => WalletOverview.fromJson(_map(d)));

  Future<TopUpResult> topUpWallet(int amountKobo, String idempotencyKey) => _call(
      () => _dio.post('/v1/wallet/topups',
          data: {'amount_kobo': amountKobo}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => TopUpResult.fromJson(_map(d)));

  Future<void> setRefundToWallet(bool on) =>
      _call(() => _dio.put('/v1/wallet/settings', data: {'refund_to_wallet': on}), (_) {});

  Future<int> moveCodToWallet(int amountKobo, String idempotencyKey) => _call(
      () => _dio.post('/v1/seller/move-to-wallet',
          data: {'amount_kobo': amountKobo}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => (_map(d)['wallet_balance_kobo'] as num).toInt());

  Future<void> requestSellerPayout({
    required int amountKobo,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String idempotencyKey,
  }) =>
      _call(
          () => _dio.post('/v1/seller/payouts',
              data: {'amount_kobo': amountKobo, 'bank_name': bankName, 'account_number': accountNumber, 'account_name': accountName},
              options: Options(headers: {'Idempotency-Key': idempotencyKey})),
          (_) {});

  Future<String> verifyPayment(String reference) =>
      _call(() => _dio.post('/v1/payments/verify', data: {'reference': reference}), (d) => '${_map(d)['status']}');

  // ------------------------------------------------------------------- package delivery
  Future<ParcelQuote> parcelQuote({
    required ParcelStop pickup,
    required ParcelStop dropoff,
    required String size,
    required String category,
    String description = '',
    DateTime? scheduledFor,
    int? codAmountKobo,
  }) =>
      _call(
          () => _dio.post('/v1/parcels/quotes', data: {
                'pickup': pickup.toJson(),
                'dropoff': dropoff.toJson(),
                'size': size,
                'category': category,
                'description': description,
                if (scheduledFor != null) 'scheduled_for': scheduledFor.toUtc().toIso8601String(),
                'cod_amount_kobo': ?codAmountKobo,
              }),
          (d) => ParcelQuote.fromJson(_map(d)));

  Future<Order> createParcel(String quoteId, String idempotencyKey) => _call(
      () => _dio.post('/v1/parcels', data: {'quote_id': quoteId, 'channel': 'app'}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => Order.fromJson(_map(d)));

  Future<OrderSummary> orderSummary() => _call(() => _dio.get('/v1/me/order-summary'), (d) => OrderSummary.fromJson(_map(d)));

  Future<void> openSupportTicket({required String category, required String description, String? orderId}) => _call(
      () => _dio.post('/v1/support/tickets', data: {'category': category, 'description': description, 'order_id': ?orderId, 'channel': 'app'}),
      (_) {});

  Future<List<Order>> myOrders() => _call(() => _dio.get('/v1/orders'), (d) => _list(d).map(Order.fromJson).toList());
  Future<Order> order(String id) => _call(() => _dio.get('/v1/orders/$id'), (d) => Order.fromJson(_map(d)));

  /// The receipt of an order that has been paid for (ADR-0019); `order_not_paid` until then.
  Future<Receipt> receipt(String orderId) =>
      _call(() => _dio.get('/v1/orders/$orderId/receipt'), (d) => Receipt.fromJson(_map(d)));

  /// The customer pressed PRINT: keeps the receipt under "My receipts" and counts the print.
  Future<Receipt> printReceipt(String orderId) =>
      _call(() => _dio.post('/v1/orders/$orderId/receipt'), (d) => Receipt.fromJson(_map(d)));

  /// The receipts the customer has printed, newest first.
  Future<List<Receipt>> receipts() => _call(() => _dio.get('/v1/receipts'), (d) => _list(d).map(Receipt.fromJson).toList());

  Future<Tracking> tracking(String id) => _call(() => _dio.get('/v1/orders/$id/tracking'), (d) => Tracking.fromJson(_map(d)));
  Future<String?> deliveryCode(String id) => _call(() => _dio.get('/v1/orders/$id/codes'), (d) => _map(d)['delivery_code'] as String?);
  /// Collection code for hub pickups (and pickup orders).
  Future<String?> pickupCode(String id) => _call(() => _dio.get('/v1/orders/$id/codes'), (d) => _map(d)['pickup_code'] as String?);

  // ------------------------------------------------------------------- interstate waybill
  Future<List<WaybillOrigin>> waybillOrigins() =>
      _call(() => _dio.get('/v1/waybill/origins'), (d) => _list(d).map(WaybillOrigin.fromJson).toList());

  Future<WaybillDestinations> waybillDestinations(String origin) => _call(
      () => _dio.get('/v1/waybill/destinations', queryParameters: {'origin': origin}),
      (d) => WaybillDestinations.fromJson(_map(d)));

  Future<WaybillQuote> waybillQuote({
    required String originCity,
    required String destinationCity,
    required String firstMile,
    required String lastMile,
    String? originHubId,
    String? destinationHubId,
    required WaybillParty sender,
    required WaybillParty recipient,
    required String size,
    required double weightKg,
    required String category,
    String description = '',
    int? codAmountKobo,
  }) =>
      _call(
          () => _dio.post('/v1/waybills/quotes', data: {
                'origin_city': originCity,
                'destination_city': destinationCity,
                'first_mile': firstMile,
                'last_mile': lastMile,
                'origin_hub_id': ?originHubId,
                'destination_hub_id': ?destinationHubId,
                'sender': sender.toJson(),
                'recipient': recipient.toJson(),
                'size': size,
                'weight_kg': weightKg,
                'category': category,
                'description': description,
                'cod_amount_kobo': ?codAmountKobo,
              }),
          (d) => WaybillQuote.fromJson(_map(d)));

  Future<Order> bookWaybill(String quoteId, String idempotencyKey) => _call(
      () => _dio.post('/v1/waybills', data: {'quote_id': quoteId, 'channel': 'app'}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => Order.fromJson(_map(d)));

  // ------------------------------------------------------------------- WhatsApp (Yummy)
  Future<WhatsAppStatus> whatsAppStatus() =>
      _call(() => _dio.get('/v1/me/whatsapp'), (d) => WhatsAppStatus.fromJson(_map(d)));
  Future<WhatsAppLinkCode> whatsAppLinkCode() =>
      _call(() => _dio.post('/v1/me/whatsapp/link-code'), (d) => WhatsAppLinkCode.fromJson(_map(d)));
  Future<WhatsAppStatus> disconnectWhatsApp() =>
      _call(() => _dio.delete('/v1/me/whatsapp'), (d) => WhatsAppStatus.fromJson(_map(d)));

  // ------------------------------------------------------------------- Yummy Chops Plus
  Future<PlusOverview> plus() => _call(() => _dio.get('/v1/plus'), (d) => PlusOverview.fromJson(_map(d)));

  /// Card payments return an authorization URL to open; wallet payments start the membership at once.
  Future<({TopUpResult payment, PlusOverview plus})> subscribePlus(String idempotencyKey, {String? provider, bool autoRenew = true}) =>
      _call(
          () => _dio.post('/v1/plus/subscribe',
              data: {'provider': ?provider, 'auto_renew': autoRenew},
              options: Options(headers: {'Idempotency-Key': idempotencyKey})),
          (d) => (payment: TopUpResult.fromJson(Map<String, dynamic>.from(_map(d)['payment'] as Map)), plus: PlusOverview.fromJson(_map(d))));

  Future<PlusOverview> setPlusAutoRenew(bool on) =>
      _call(() => _dio.put('/v1/plus/auto-renew', data: {'auto_renew': on}), (d) => PlusOverview.fromJson(_map(d)));

  // ------------------------------------------------------------------- rewards
  Future<RewardsOverview> rewards() => _call(() => _dio.get('/v1/rewards'), (d) => RewardsOverview.fromJson(_map(d)));
  Future<List<RewardVoucher>> myVouchers() =>
      _call(() => _dio.get('/v1/rewards/vouchers'), (d) => _list(d).map(RewardVoucher.fromJson).toList());
  Future<RewardVoucher?> applyReferral(String code) => _call(() => _dio.post('/v1/rewards/referral', data: {'code': code}), (d) {
        final v = _map(d)['voucher'];
        return v == null ? null : RewardVoucher.fromJson(Map<String, dynamic>.from(v as Map));
      });
  Future<RewardVoucher> redeemPoints(int points, String idempotencyKey) => _call(
      () => _dio.post('/v1/rewards/redeem', data: {'points': points}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => RewardVoucher.fromJson(Map<String, dynamic>.from(_map(d)['voucher'] as Map)));

  // ------------------------------------------------------------------- group orders
  Future<List<GroupOrder>> myGroups() => _call(() => _dio.get('/v1/group-orders'), (d) => _list(d).map(GroupOrder.fromJson).toList());
  Future<GroupOrder> group(String id) => _call(() => _dio.get('/v1/group-orders/$id'), (d) => GroupOrder.fromJson(_map(d)));
  Future<GroupOrder> createGroup({required String restaurantId, required String fulfillment, DeliveryAddress? address, String splitMode = 'each'}) =>
      _call(
          () => _dio.post('/v1/group-orders', data: {
                'restaurant_id': restaurantId,
                'fulfillment': fulfillment,
                'delivery_address': ?address?.toJson(),
                'split_mode': splitMode,
              }),
          (d) => GroupOrder.fromJson(_map(d)));
  Future<GroupOrder> joinGroup(String code) =>
      _call(() => _dio.post('/v1/group-orders/join', data: {'code': code}), (d) => GroupOrder.fromJson(_map(d)));
  Future<GroupOrder> setGroupLines(String id, List<CartLine> lines) => _call(
      () => _dio.put('/v1/group-orders/$id/lines', data: {'lines': [for (final l in lines) l.toJson()]}),
      (d) => GroupOrder.fromJson(_map(d)));
  Future<GroupOrder> setGroupReady(String id, bool ready) =>
      _call(() => _dio.put('/v1/group-orders/$id/ready', data: {'ready': ready}), (d) => GroupOrder.fromJson(_map(d)));
  Future<GroupOrder> setGroupSplitMode(String id, String mode) =>
      _call(() => _dio.put('/v1/group-orders/$id/settings', data: {'split_mode': mode}), (d) => GroupOrder.fromJson(_map(d)));
  Future<GroupOrder> lockGroup(String id, bool locked) =>
      _call(() => _dio.post('/v1/group-orders/$id/${locked ? 'lock' : 'unlock'}'), (d) => GroupOrder.fromJson(_map(d)));
  Future<void> leaveGroup(String id, String uid) => _call(() => _dio.delete('/v1/group-orders/$id/members/$uid'), (_) {});
  Future<GroupOrder> checkoutGroup(String id, String idempotencyKey, {String? voucher}) => _call(
      () => _dio.post('/v1/group-orders/$id/checkout',
          data: {'voucher_code': ?voucher, 'channel': 'app'}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
      (d) => GroupOrder.fromJson(_map(d)));
  Future<({TopUpResult payment, GroupOrder group})> payGroupShare(String id, String idempotencyKey, {String? provider, bool coverRest = false}) =>
      _call(
          () => _dio.post('/v1/group-orders/$id/pay',
              data: {'provider': ?provider, 'cover_rest': coverRest}, options: Options(headers: {'Idempotency-Key': idempotencyKey})),
          (d) => (
                payment: TopUpResult.fromJson(Map<String, dynamic>.from(_map(d)['payment'] as Map)),
                group: GroupOrder.fromJson(Map<String, dynamic>.from(_map(d)['group'] as Map)),
              ));
  Future<GroupOrder> cancelGroup(String id) => _call(() => _dio.post('/v1/group-orders/$id/cancel'), (d) => GroupOrder.fromJson(_map(d)));

  Future<WaybillTracking> trackWaybill(String code) =>
      _call(() => _dio.get('/v1/track/${Uri.encodeComponent(code)}'), (d) => WaybillTracking.fromJson(_map(d)));
  Future<Order> cancel(String id) => _call(() => _dio.post('/v1/orders/$id/cancel', data: {'reason': 'Cancelled in app'}), (d) => Order.fromJson(_map(d)));

  /// Food preferences kept on the customer's profile: allergies, diet, and whether orders may shape
  /// recommendations.
  Future<FoodPreferences> foodPreferences() =>
      _call(() => _dio.get('/v1/me/profile'), (d) => FoodPreferences.fromJson(_map(d)));
  Future<FoodPreferences> saveFoodPreferences(FoodPreferences preferences) =>
      _call(() => _dio.patch('/v1/me/profile', data: preferences.toJson()), (d) => FoodPreferences.fromJson(_map(d)));

  /// Everything Yummy Chops holds about the signed-in customer (their right under the NDPA).
  Future<Map<String, dynamic>> exportMyData() => _call(() => _dio.get('/v1/me/export'), (d) => _map(d));

  /// Applications to sell on Yummy Chops or to ride with it; the Yummy Chops team reviews them.
  Future<void> applyAsBusiness(Map<String, dynamic> application) =>
      _call(() => _dio.post('/v1/applications/restaurant', data: application), (_) {});
  Future<void> applyAsRider(Map<String, dynamic> application) =>
      _call(() => _dio.post('/v1/applications/rider', data: application), (_) {});

  Future<List<DeliveryAddress>> addresses() => _call(() => _dio.get('/v1/me/addresses'), (d) => _list(d).map(DeliveryAddress.fromJson).toList());
  Future<void> saveAddress(DeliveryAddress a) => _call(() => _dio.post('/v1/me/addresses', data: a.toJson()), (_) {});
  Future<void> registerDevice(String token, String platform) =>
      _call(() => _dio.post('/v1/me/devices', data: {'token': token, 'platform': platform}), (_) {});

  // ------------------------------------------------------------------- rider
  Future<RiderProfile> riderProfile() => _call(() => _dio.get('/v1/rider/profile'), (d) => RiderProfile.fromJson(_map(d)));
  Future<RiderProfile> setOnline(bool online) =>
      _call(() => _dio.put('/v1/rider/availability', data: {'online': online}), (d) => RiderProfile.fromJson(_map(d)));
  Future<void> sendLocation(GeoPoint p, {double? accuracyM}) => _call(
      () => _dio.post('/v1/rider/location', data: {'lat': p.lat, 'lng': p.lng, 'accuracy_m': ?accuracyM}), (_) {});
  Future<List<DeliveryOffer>> offers() => _call(() => _dio.get('/v1/rider/offers'), (d) {
        final receivedAt = DateTime.now().toUtc();
        return _list(d).map((json) => offerFromJson(json, receivedAt)).toList();
      });
  Future<Order> acceptOffer(String id) => _call(() => _dio.post('/v1/rider/offers/$id/accept'), (d) => Order.fromJson(_map(d)));
  Future<void> declineOffer(String id, String reason) => _call(() => _dio.post('/v1/rider/offers/$id/decline', data: {'reason': reason}), (_) {});
  Future<List<Order>> activeDeliveries() => _call(() => _dio.get('/v1/rider/deliveries'), (d) => _list(d).map(Order.fromJson).toList());
  Future<Order> pickup(String orderId) => _call(() => _dio.post('/v1/rider/deliveries/$orderId/pickup'), (d) => Order.fromJson(_map(d)));
  Future<Order> inTransit(String orderId) => _call(() => _dio.post('/v1/rider/deliveries/$orderId/in-transit'), (d) => Order.fromJson(_map(d)));
  /// [cashCollected] must be true when the order has cash to collect; the amount always comes from the server.
  Future<Order> deliver(String orderId, String code, {bool cashCollected = false}) => _call(
      () => _dio.post('/v1/rider/deliveries/$orderId/deliver', data: {'code': code, 'cash_collected': cashCollected}),
      (d) => Order.fromJson(_map(d)));
  Future<Earnings> earnings() => _call(() => _dio.get('/v1/rider/earnings'), (d) => Earnings.fromJson(_map(d)));
  Future<void> requestPayout(int amountKobo, String key) => _call(
      () => _dio.post('/v1/rider/payouts', data: {'amount_kobo': amountKobo}, options: Options(headers: {'Idempotency-Key': key})), (_) {});
  // ------------------------------------------------------------------- rider KYC (docs/adr/0027-rider-kyc.md)
  /// The rider's KYC: status, sign-up details, what is still missing, each document's state and the team's note.
  Future<Map<String, dynamic>> riderKyc() => _call(() => _dio.get('/v1/rider/kyc'), (d) => _map(d));
  /// Saves the typed details as the rider goes: permanent address, NIN and the two guarantors.
  Future<Map<String, dynamic>> updateRiderKyc(Map<String, dynamic> details) =>
      _call(() => _dio.put('/v1/rider/kyc', data: details), (d) => _map(d));
  /// A photo or scan, base64-encoded (at most 5 MB once decoded); the API checks what it really is.
  Future<Map<String, dynamic>> uploadKycDocument(String kind, String base64Data) =>
      _call(() => _dio.post('/v1/rider/kyc/documents/$kind', data: {'data': base64Data}), (d) => _map(d));
  Future<Map<String, dynamic>> submitRiderKyc() => _call(() => _dio.post('/v1/rider/kyc/submit'), (d) => _map(d));

  Future<void> emergency(String description, GeoPoint? at) => _call(
      () => _dio.post('/v1/rider/emergency', data: {'description': description, if (at != null) 'lat': at.lat, if (at != null) 'lng': at.lng}),
      (_) {});
}

/// Client for gudmeal-agents (the LangGraph AI service).
class GudMealAgentsApi {
  GudMealAgentsApi({required String baseUrl, required TokenProvider token, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, receiveTimeout: const Duration(seconds: 60))) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final t = await token();
      if (t != null) options.headers['Authorization'] = 'Bearer $t';
      handler.next(options);
    }));
  }

  final Dio _dio;

  Future<ChatResponse> chat(String message, {String? threadId, DeliveryAddress? address}) async {
    try {
      final res = await _dio.post('/v1/chat', data: {
        'message': message,
        'channel': 'app',
        'thread_id': ?threadId,
        if (address != null && threadId == null) 'delivery_address': address.toJson(),
      });
      return ChatResponse.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatResponse> decide(String threadId, {required bool approved, required String toolCallId}) async {
    try {
      final res = await _dio.post('/v1/chat/$threadId/approval', data: {'approved': approved, 'tool_call_id': toolCallId});
      return ChatResponse.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
