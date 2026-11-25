import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/app.dart';
import 'package:gud_meal_customer/features/auth/sign_in_screen.dart';
import 'package:gud_meal_customer/features/cart/cart_controller.dart';
import 'package:gud_meal_customer/features/cart/checkout_screen.dart';
import 'package:gud_meal_customer/features/restaurant/restaurant_screen.dart';
import 'package:gud_meal_customer/providers.dart';

const suya = RestaurantCard(id: 'r-suya', name: 'Suya Lane', cuisines: ['Grills'], area: 'Victoria Island', rating: 4.8, isOpen: true, etaMinutes: 40, deliveryFeeKobo: 175000);
const amala = RestaurantCard(id: 'r-amala', name: "Mama Ayo's Kitchen", cuisines: ['Nigerian'], area: 'Yaba', rating: 4.6, isOpen: false);

const heat = OptionGroup(id: 'heat', name: 'Yaji level', minSelect: 1, maxSelect: 1, choices: [
  OptionChoice(id: 'mild', name: 'Mild'),
  OptionChoice(id: 'fire', name: 'Fire', priceDeltaKobo: 20000),
]);
const beefSuya = MenuItem(id: 'sl-beef', restaurantId: 'r-suya', name: 'Beef Suya', priceKobo: 450000, optionGroupIds: ['heat']);

CartItem item(String id, int qty, {List<OptionSelection> sel = const []}) =>
    CartItem(itemId: id, name: id, unitPriceKobo: 100000, quantity: qty, selections: sel);

/// Records quotes; never hits the network.
class FakeApi extends GudMealApi {
  FakeApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  final quotes = <List<CartLine>>[];

  @override
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher}) async {
    quotes.add(lines);
    return Quote(
      id: 'q1', restaurantName: 'Suya Lane', fulfillment: fulfillment, etaMinutes: 40,
      breakdown: const PriceBreakdown(subtotalKobo: 900000, deliveryFeeKobo: 175000, serviceFeeKobo: 45000, vatKobo: 16500, totalKobo: 1136500),
      estimatedDeliveryAt: DateTime.utc(2026, 11, 14, 19, 30), expiresAt: DateTime.utc(2026, 11, 14, 19, 0),
    );
  }

  @override
  Future<WalletOverview> wallet() async => const WalletOverview(balanceKobo: 2000000);

  @override
  Future<List<RewardVoucher>> myVouchers() async => const [];

  @override
  Future<OrderSummary> orderSummary() async => const OrderSummary(completedCount: 1);
}

/// An API that refuses orders the way the real one does: every price has its own id, and the keys are recorded.
class _OrderingApi extends FakeApi {
  ApiException? refuse;
  final orders = <(String quoteId, String key, String? phone)>[];

  @override
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher}) async =>
      (await super.quote(restaurantId: restaurantId, lines: lines, fulfillment: fulfillment, address: address, voucher: voucher))
          .copyWith(id: 'q${quotes.length}');

  @override
  Future<Order> createOrder(String quoteId, String idempotencyKey, {String? contactPhone}) async {
    orders.add((quoteId, idempotencyKey, contactPhone));
    throw refuse!;
  }

  @override
  Future<List<Order>> myOrders() async => const [];

  @override
  Future<List<DeliveryAddress>> addresses() async => const [];
}

Widget harness(Widget child, {List overrides = const []}) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))), ...overrides],
      child: MaterialApp(theme: buildGudMealTheme(Brightness.light), home: child),
    );

void main() {
  group('CartController', () {
    test('merges identical lines and totals the subtotal', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);
      cart.add('r1', 'R1', item('a', 1));
      cart.add('r1', 'R1', item('a', 2));
      cart.add('r1', 'R1', item('b', 1));
      final state = c.read(cartProvider);
      expect(state.count, 4);
      expect(state.subtotalKobo, 400000);
      expect(state.toLines().map((l) => l.itemId), ['a', 'b']);
    });

    test('refuses mixing restaurants unless replacing', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);
      cart.add('r1', 'R1', item('a', 1));
      expect(cart.add('r2', 'R2', item('b', 1)), isFalse);
      expect(cart.add('r2', 'R2', item('b', 1), replace: true), isTrue);
      expect(c.read(cartProvider).restaurantId, 'r2');
      expect(c.read(cartProvider).items.single.itemId, 'b');
    });

    test('quantity zero removes the line and empties the cart', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier)..add('r1', 'R1', item('a', 1));
      cart.setQuantity(c.read(cartProvider).items.single.key, 0);
      expect(c.read(cartProvider).isEmpty, isTrue);
      expect(c.read(cartProvider).restaurantId, isNull);
    });
  });

  test('Nigerian phone numbers normalise to E.164', () {
    expect(normaliseNigerianPhone('0803 123 4567'), '+2348031234567');
    expect(normaliseNigerianPhone('+2349061234567'), '+2349061234567');
    expect(normaliseNigerianPhone('8031234567'), '+2348031234567');
    expect(normaliseNigerianPhone('12345'), isNull);
  });

  testWidgets('item sheet requires the mandatory choice before adding', (tester) async {
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: ItemSheet(item: beefSuya, groups: const {'heat': heat}, restaurantId: 'r-suya', restaurantName: 'Suya Lane')),
      ),
    ));
    final addButton = find.widgetWithText(FilledButton, 'Add · ₦4,500');
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
    await tester.tap(find.text('Fire +₦200'));
    await tester.pump();
    final enabled = find.widgetWithText(FilledButton, 'Add · ₦4,700');
    expect(tester.widget<FilledButton>(enabled).onPressed, isNotNull);
    await tester.tap(enabled);
    await tester.pump();
    final cart = container.read(cartProvider);
    expect(cart.items.single.selections.single.choiceIds, ['fire']);
    expect(cart.subtotalKobo, 470000);
  });

  testWidgets('checkout asks the server for the total before paying', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // a phone: the whole checkout is on screen
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final api = FakeApi();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
      apiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add('r-suya', 'Suya Lane', item('sl-beef', 2));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CheckoutScreen())));
    await tester.tap(find.text('Review total'));
    await tester.pump();
    expect(find.text('Enter your street address'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
    await tester.tap(find.text('Review total'));
    await tester.pumpAndSettle();
    expect(api.quotes.single.single.quantity, 2);
    expect(find.text('Pay ₦11,365'), findsOneWidget);
    expect(find.text('₦1,750'), findsOneWidget);
  });

  testWidgets('checkout: an expired price asks for a new one, and a new order never reuses a key', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final api = _OrderingApi();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
      apiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add('r-suya', 'Suya Lane', item('sl-beef', 2));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CheckoutScreen())));
    await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
    await tester.tap(find.text('Review total'));
    await tester.pumpAndSettle();

    // The price is no longer held: the customer is told, and the button asks for a new price.
    api.refuse = ApiException(409, 'quote_expired', 'Your price quote expired; please review your cart again');
    await tester.tap(find.text('Pay ₦11,365'));
    await tester.pumpAndSettle();
    expect(find.text('Your price quote expired; please review your cart again'), findsOneWidget);
    expect(find.text('Pay ₦11,365'), findsNothing);
    await tester.tap(find.text('Review total'));
    await tester.pumpAndSettle();

    // No answer (the connection dropped): trying again is the same order with the same key.
    api.refuse = ApiException(0, 'network_error', 'offline');
    await tester.tap(find.text('Pay ₦11,365'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay ₦11,365'));
    await tester.pumpAndSettle();
    // A changed phone number is a changed order: a new key again.
    await tester.enterText(find.widgetWithText(TextField, 'Phone for the rider'), '08031234567');
    await tester.tap(find.text('Pay ₦11,365'));
    await tester.pumpAndSettle();

    expect(api.orders.map((o) => o.$1), ['q1', 'q2', 'q2', 'q2']);
    final keys = api.orders.map((o) => o.$2).toList();
    expect(keys[1], isNot(keys[0]), reason: 'the new price is a new order');
    expect(keys[2], keys[1], reason: 'a retry cannot place the order twice');
    expect(keys[3], isNot(keys[2]), reason: 'the API refuses an old key with a changed order');
  });

  test('a new sign-in gets a new API client, so what is read through it is fetched again', () async {
    final auth = FakeAuthRepository();
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(container.dispose);
    container.listen(apiProvider, (_, _) {});
    final visitor = container.read(apiProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(apiProvider), same(visitor), reason: 'nothing changed: the same client');
    await auth.signInWithEmail('ada@example.com', 'secret1');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(apiProvider), isNot(same(visitor)));
  });

  testWidgets('signing out leaves nothing of the customer in memory: not their cart, not their orders', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final auth = FakeAuthRepository(const GmUser(uid: 'u1', name: 'Ada Obi'));
    await tester.pumpWidget(PerUserScope(
      auth: auth,
      child: ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          apiProvider.overrideWithValue(_OrderingApi()),
          forYouProvider.overrideWith((ref) async => const <RestaurantCard>[]),
          myOrdersProvider.overrideWith((ref) async => const [Order(id: 'o1', shortCode: 'ADA123', status: 'completed', restaurantName: 'Suya Lane')]),
        ],
        child: const GudMealApp(),
      ),
    ));
    await tester.pumpAndSettle();
    ProviderContainer memory() => ProviderScope.containerOf(tester.element(find.byType(GudMealApp)));
    final adas = memory();
    adas.read(cartProvider.notifier).add('r-suya', 'Suya Lane', item('sl-beef', 2));
    await adas.read(myOrdersProvider.future);
    expect(adas.read(myOrdersProvider).value, hasLength(1));

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(memory(), isNot(same(adas)), reason: 'a fresh start for whoever uses the phone next');
    expect(memory().read(cartProvider).isEmpty, isTrue);
    expect(memory().read(myOrdersProvider).value, isNull, reason: "the next person never sees Ada's orders");
    expect(find.text('Order Food'), findsOneWidget); // back on Home, signed out
  });
}
