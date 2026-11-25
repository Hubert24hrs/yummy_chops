import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

/// Prices each shop on its own and records the orders and the one checkout.
class _MixedApi extends FakeApi {
  final quoted = <(String restaurantId, String? voucher, List<CartLine> lines)>[];
  final orders = <(String quoteId, String key)>[];
  final checkouts = <(List<String> orderIds, String key, String? provider)>[];

  @override
  Future<Quote> quote({required String restaurantId, required List<CartLine> lines, required String fulfillment, DeliveryAddress? address, String? voucher}) async {
    quoted.add((restaurantId, voucher, lines));
    final pharmacy = restaurantId == 'r-pharm';
    return Quote(
      id: 'q-$restaurantId-${quoted.length}', restaurantName: pharmacy ? 'HealthPlus Pharmacy' : 'Suya Lane', fulfillment: fulfillment, etaMinutes: 40,
      breakdown: pharmacy
          ? const PriceBreakdown(subtotalKobo: 50000, deliveryFeeKobo: 400000, serviceFeeKobo: 20000, vatKobo: 30000, totalKobo: 500000)
          : const PriceBreakdown(subtotalKobo: 900000, deliveryFeeKobo: 175000, serviceFeeKobo: 45000, vatKobo: 16500, totalKobo: 1136500),
      estimatedDeliveryAt: DateTime.utc(2026, 11, 14, 19, 30), expiresAt: DateTime.utc(2026, 11, 14, 19, 0),
    );
  }

  @override
  Future<Order> createOrder(String quoteId, String idempotencyKey, {String? contactPhone}) async {
    orders.add((quoteId, idempotencyKey));
    return Order(id: 'o-$quoteId', shortCode: 'ABC123', status: 'pending_payment', restaurantName: 'x');
  }

  @override
  Future<MultiCheckoutResult> checkoutMany(List<String> orderIds, String idempotencyKey, {String? provider}) async {
    checkouts.add((orderIds, idempotencyKey, provider));
    return MultiCheckoutResult(orderIds: orderIds, provider: provider ?? 'local_sandbox', reference: 'YC-B-1', amountKobo: 1636500, paymentStatus: 'succeeded');
  }
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

    test('keeps items from several shops, grouped by shop in the order first added', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier);
      cart.add('r1', 'R1', item('a', 1));
      cart.add('r2', 'R2', item('b', 1));
      cart.add('r1', 'R1', item('c', 2));
      cart.add('r2', 'R2', item('a', 1)); // the same item id at another shop is another line
      final state = c.read(cartProvider);
      expect(state.count, 5);
      expect(state.subtotalKobo, 500000);
      expect(state.shops.map((s) => s.restaurantId), ['r1', 'r2']);
      expect(state.shops.map((s) => s.restaurantName), ['R1', 'R2']);
      expect(state.shops.first.toLines().map((l) => l.itemId), ['a', 'c']);
      expect(state.shops.last.toLines().map((l) => l.itemId), ['b', 'a']);
      expect(state.shops.first.subtotalKobo, 300000);
      expect(state.items.map((i) => i.key).toSet(), hasLength(4));
    });

    test('setQuantity and remove change one line; the last line of a shop drops the shop', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier)
        ..add('r1', 'R1', item('a', 1))
        ..add('r2', 'R2', item('b', 1));
      final a = c.read(cartProvider).items.first.key;
      final b = c.read(cartProvider).items.last.key;
      cart.setQuantity(a, 3);
      expect(c.read(cartProvider).items.first.quantity, 3);
      cart.setQuantity(a, 99);
      expect(c.read(cartProvider).items.first.quantity, 50);
      cart.remove(b);
      expect(c.read(cartProvider).shops.map((s) => s.restaurantId), ['r1']);
      expect(c.read(cartProvider).count, 50);
    });

    test('quantity zero removes the line and empties the cart', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final cart = c.read(cartProvider.notifier)..add('r1', 'R1', item('a', 1));
      cart.setQuantity(c.read(cartProvider).items.single.key, 0);
      expect(c.read(cartProvider).isEmpty, isTrue);
      expect(c.read(cartProvider).shops, isEmpty);
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
    final addButton = find.widgetWithText(FilledButton, 'Add to cart · ₦4,500');
    expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
    await tester.tap(find.text('Fire +₦200'));
    await tester.pump();
    final enabled = find.widgetWithText(FilledButton, 'Add to cart · ₦4,700');
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
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '08031234567');
    await tester.tap(find.text('Pay ₦11,365'));
    await tester.pumpAndSettle();

    expect(api.orders.map((o) => o.$1), ['q1', 'q2', 'q2', 'q2']);
    final keys = api.orders.map((o) => o.$2).toList();
    expect(keys[1], isNot(keys[0]), reason: 'the new price is a new order');
    expect(keys[2], keys[1], reason: 'a retry cannot place the order twice');
    expect(keys[3], isNot(keys[2]), reason: 'the API refuses an old key with a changed order');
  });

  testWidgets('item sheet adds a second shop to the cart without asking to start a new cart', (tester) async {
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())]);
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add('r-jollof', 'Jollof Junction', item('jj-rice', 1));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: ItemSheet(item: beefSuya, groups: const {'heat': heat}, restaurantId: 'r-suya', restaurantName: 'Suya Lane')),
      ),
    ));
    await tester.tap(find.text('Mild'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add to cart · ₦4,500'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new cart?'), findsNothing);
    final cart = container.read(cartProvider);
    expect(cart.shops.map((s) => s.restaurantName), ['Jollof Junction', 'Suya Lane']);
    expect(cart.items.last.restaurantId, 'r-suya');
  });

  testWidgets('item sheet takes the customer to the cart after adding', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => ItemSheet(item: beefSuya, groups: const {'heat': heat}, restaurantId: 'r-suya', restaurantName: 'Suya Lane'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/checkout', builder: (_, _) => const Scaffold(body: Text('the cart'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mild'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add to cart · ₦4,500'));
    await tester.pumpAndSettle();
    expect(find.text('the cart'), findsOneWidget);
  });

  group('mixed cart', () {
    Future<(_MixedApi, ProviderContainer)> openCart(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final api = _MixedApi();
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
        apiProvider.overrideWithValue(api),
      ]);
      addTearDown(container.dispose);
      container.read(cartProvider.notifier)
        ..add('r-suya', 'Suya Lane', item('sl-beef', 2))
        ..add('r-pharm', 'HealthPlus Pharmacy', const CartItem(itemId: 'ph-pcm', name: 'Paracetamol', unitPriceKobo: 50000, quantity: 1))
        ..add('r-suya', 'Suya Lane', item('sl-chicken', 1));
      final router = GoRouter(initialLocation: '/checkout', routes: [
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(path: '/orders', builder: (_, s) => Scaffold(body: Text('orders ${s.uri}'))),
        GoRoute(path: '/orders/:id', builder: (_, s) => Scaffold(body: Text('order ${s.uri}'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      return (api, container);
    }

    Finder line(ProviderContainer c, int index) => find.byKey(ValueKey('cart-line-${c.read(cartProvider).items[index].key}'));

    testWidgets('items are grouped by shop and can be changed or removed', (tester) async {
      final (_, container) = await openCart(tester);
      expect(find.text('Your cart'), findsOneWidget);
      expect(find.text('Suya Lane'), findsOneWidget);
      expect(find.text('HealthPlus Pharmacy'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Start a new cart?'), findsNothing);
      expect(tester.getTopLeft(find.text('sl-chicken')).dy, lessThan(tester.getTopLeft(find.text('HealthPlus Pharmacy')).dy),
          reason: 'both Suya Lane items sit under Suya Lane');

      await tester.tap(find.descendant(of: line(container, 1), matching: find.byTooltip('Add one')));
      await tester.pump();
      expect(container.read(cartProvider).items[1].quantity, 2);
      await tester.tap(find.descendant(of: line(container, 1), matching: find.byTooltip('Remove')));
      await tester.pump();
      expect(find.text('HealthPlus Pharmacy'), findsNothing, reason: 'its last item is gone, so the shop is too');
      expect(container.read(cartProvider).shops.single.restaurantId, 'r-suya');
    });

    testWidgets('one price per shop, a grand total, and one payment for every order', (tester) async {
      final (api, container) = await openCart(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
      await tester.enterText(find.widgetWithText(TextField, 'Voucher (optional)'), 'welcome500');
      expect(find.textContaining("Voucher applies to one shop's order"), findsOneWidget);
      await tester.tap(find.text('Review total'));
      await tester.pumpAndSettle();
      expect(api.quoted.map((q) => q.$1), ['r-suya', 'r-pharm']);
      expect(api.quoted.map((q) => q.$2), ['WELCOME500', null], reason: 'the voucher goes with the first shop only');
      expect(api.quoted.first.$3.map((l) => l.itemId), ['sl-beef', 'sl-chicken']);
      expect(find.text('Shop total'), findsNWidgets(2));
      expect(find.text('Total to pay'), findsOneWidget);
      expect(find.text('₦16,365'), findsOneWidget); // 11,365 + 5,000

      // Changing the cart drops the price.
      await tester.tap(find.descendant(of: line(container, 1), matching: find.byTooltip('Add one')));
      await tester.pump();
      expect(find.text('Total to pay'), findsNothing);
      await tester.tap(find.text('Review total'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Yummy Chops wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yummy Chops wallet'));
      await tester.pump();
      await tester.tap(find.text('Pay ₦16,365 from wallet'));
      await tester.pumpAndSettle();
      expect(api.orders.map((o) => o.$1), ['q-r-suya-3', 'q-r-pharm-4']);
      expect(api.orders[0].$2, isNot(api.orders[1].$2), reason: 'each order has its own key');
      expect(api.checkouts, hasLength(1));
      expect(api.checkouts.single.$1, ['o-q-r-suya-3', 'o-q-r-pharm-4']);
      expect(api.checkouts.single.$3, 'wallet');
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(find.text('orders /orders'), findsOneWidget, reason: 'several orders: each is listed on Orders');
    });
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
