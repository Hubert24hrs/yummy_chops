import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/app.dart';
import 'package:gud_meal_customer/features/auth/sign_in_screen.dart';
import 'package:gud_meal_customer/features/cart/cart_controller.dart';
import 'package:gud_meal_customer/features/cart/cart_screen.dart';
import 'package:gud_meal_customer/features/cart/checkout_screen.dart';
import 'package:gud_meal_customer/features/cart/contact_phone.dart';
import 'package:gud_meal_customer/features/cart/widgets/order_summary.dart';
import 'package:gud_meal_customer/features/location/address_picker.dart';
import 'package:gud_meal_customer/features/orders/payment_watch.dart';
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

/// The payment page, without a browser.
class FakePaymentPage extends PaymentPage {
  final opened = <Uri>[];
  int closed = 0;
  @override
  Future<void> open(Uri url) async => opened.add(url);
  @override
  Future<void> close() async => closed++;
}

/// Records quotes; never hits the network.
class FakeApi extends GudMealApi {
  FakeApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  final quotes = <List<CartLine>>[];
  final scheduled = <DateTime?>[];
  final quotedAddresses = <DeliveryAddress?>[];

  @override
  Future<Quote> quote({
    required String restaurantId,
    required List<CartLine> lines,
    required String fulfillment,
    DeliveryAddress? address,
    String? voucher,
    DateTime? scheduledFor,
  }) async {
    quotes.add(lines);
    scheduled.add(scheduledFor);
    quotedAddresses.add(address);
    return Quote(
      id: 'q1', restaurantName: 'Suya Lane', fulfillment: fulfillment, etaMinutes: 40,
      breakdown: const PriceBreakdown(subtotalKobo: 900000, deliveryFeeKobo: 175000, serviceFeeKobo: 45000, vatKobo: 16500, totalKobo: 1136500),
      estimatedDeliveryAt: DateTime.utc(2026, 11, 14, 19, 30), expiresAt: DateTime.utc(2026, 11, 14, 19, 0),
    );
  }

  @override
  Future<WalletOverview> wallet() async => const WalletOverview(balanceKobo: 2000000);

  @override
  Future<List<DeliveryAddress>> addresses() async => const [];

  @override
  Future<List<RewardVoucher>> myVouchers() async => const [];

  @override
  Future<OrderSummary> orderSummary() async => const OrderSummary(completedCount: 1);

  /// A member: no Plus offer at checkout.
  @override
  Future<PlusOverview> plus() async => const PlusOverview(plan: PlusPlan(priceKobo: 150000), member: true);
}

/// An API that refuses orders the way the real one does: every price has its own id, and the keys are recorded.
class _OrderingApi extends FakeApi {
  ApiException? refuse;
  final orders = <(String quoteId, String key, String? phone)>[];

  @override
  Future<Quote> quote({
    required String restaurantId,
    required List<CartLine> lines,
    required String fulfillment,
    DeliveryAddress? address,
    String? voucher,
    DateTime? scheduledFor,
  }) async =>
      (await super.quote(restaurantId: restaurantId, lines: lines, fulfillment: fulfillment, address: address, voucher: voucher, scheduledFor: scheduledFor))
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
  final quoted = <(String restaurantId, String? voucher, List<CartLine> lines, DateTime? scheduledFor, DeliveryAddress? address)>[];
  final orders = <(String quoteId, String key, String? phone)>[];
  final checkouts = <(List<String> orderIds, String key, String? provider)>[];
  final updatedAddresses = <(String id, DeliveryAddress address)>[];
  int orderListReads = 0;

  /// Set: card payments continue on this page.
  String? payUrl;

  @override
  Future<List<Order>> myOrders() async {
    orderListReads++;
    return const [];
  }

  @override
  Future<void> updateAddress(String id, DeliveryAddress a) async => updatedAddresses.add((id, a));

  @override
  Future<Quote> quote({
    required String restaurantId,
    required List<CartLine> lines,
    required String fulfillment,
    DeliveryAddress? address,
    String? voucher,
    DateTime? scheduledFor,
  }) async {
    quoted.add((restaurantId, voucher, lines, scheduledFor, address));
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
    orders.add((quoteId, idempotencyKey, contactPhone));
    return Order(id: 'o-$quoteId', shortCode: 'ABC123', status: 'pending_payment', restaurantName: 'x');
  }

  @override
  Future<MultiCheckoutResult> checkoutMany(List<String> orderIds, String idempotencyKey, {String? provider}) async {
    checkouts.add((orderIds, idempotencyKey, provider));
    return MultiCheckoutResult(
      orderIds: orderIds, provider: provider ?? 'paystack', reference: 'YC-B-1', amountKobo: 1636500,
      authorizationUrl: provider == null || provider == 'paystack' ? payUrl : null, paymentStatus: payUrl == null ? 'succeeded' : 'pending',
    );
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

  /// Lets checkout's wait after a change run out, then waits for the price.
  Future<void> settleQuote(WidgetTester tester) async {
    await tester.pump(CheckoutScreen.quoteDelay);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // Scrolled past (lists build only what is near the screen): go back up to it.
    if (finder.evaluate().isEmpty) await tester.dragUntilVisible(finder, find.byType(ListView).first, const Offset(0, 300));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  FilledButton payButton(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const ValueKey('checkout-pay')));

  testWidgets('checkout prices the order by itself once it has an address, not on every keystroke', (tester) async {
    tester.view.physicalSize = const Size(1080, 5400); // the whole checkout on screen
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
    await settleQuote(tester);
    expect(api.quotes, isEmpty, reason: 'no address yet');
    expect(find.text('Add your delivery address to see the total.'), findsOneWidget);
    expect(payButton(tester).onPressed, isNull);

    final street = find.widgetWithText(TextField, 'Street address');
    await tester.enterText(street, '5 Adm');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(street, '5 Admiralty Road');
    await settleQuote(tester);
    expect(api.quotes, hasLength(1), reason: 'one price for the finished street, not one per keystroke');
    expect(api.quotes.single.single.quantity, 2);
    expect(api.scheduled.single, isNull, reason: 'as soon as possible');
    expect(find.text('Total to pay'), findsOneWidget);
    expect(find.text('₦11,365'), findsOneWidget);
    expect(find.text('₦1,750'), findsOneWidget);
    expect(find.text('Pay to order'), findsOneWidget);
    // No phone number yet: the rider could not call, so nothing can be paid.
    expect(find.byKey(const ValueKey('checkout-phone-error')), findsOneWidget);
    expect(find.text(missingPhoneMessage), findsNWidgets(2)); // by the phone row and by the button
    expect(payButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('checkout-pay-needs-phone')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '0803 123 4567');
    await tester.tap(find.text('Save'));
    await settleQuote(tester);
    expect(find.text(missingPhoneMessage), findsNothing);
    expect(api.quotedAddresses.last?.contactPhone, '+2348031234567', reason: 'the number is on the delivery address of the quote');
    expect(payButton(tester).onPressed, isNotNull);
  });

  testWidgets('checkout: an expired price is asked for again, and a new order never reuses a key', (tester) async {
    tester.view.physicalSize = const Size(1080, 5400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final api = _OrderingApi();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
      apiProvider.overrideWithValue(api),
      contactPhoneStoreProvider.overrideWithValue(MemoryContactPhoneStore('08031234567')),
    ]);
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add('r-suya', 'Suya Lane', item('sl-beef', 2));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: CheckoutScreen())));
    await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
    await settleQuote(tester);

    // The price is no longer held: the customer is told, and a new price is asked for straight away.
    api.refuse = ApiException(409, 'quote_expired', 'Your price quote expired; please review your cart again');
    await tester.tap(find.text('Pay to order'));
    await tester.pumpAndSettle();
    expect(find.text('Your price quote expired; please review your cart again'), findsOneWidget);
    expect(api.quotes, hasLength(2));

    // No answer (the connection dropped): trying again is the same order with the same key.
    api.refuse = ApiException(0, 'network_error', 'offline');
    await tester.tap(find.text('Pay to order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay to order'));
    await tester.pumpAndSettle();
    // A changed phone number is a changed order (it is on the quote's address): a new price and a new key.
    await tapVisible(tester, find.text('08031234567'));
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '+234 903 123 4567');
    await tester.tap(find.text('Save'));
    await settleQuote(tester);
    expect(find.text('+234 903 123 4567'), findsOneWidget);
    await tester.tap(find.text('Pay to order'));
    await tester.pumpAndSettle();

    expect(api.orders.map((o) => o.$1), ['q1', 'q2', 'q2', 'q3']);
    expect(api.orders.first.$3, '+2348031234567', reason: 'sent as the order contact_phone, in E.164');
    expect(api.orders.last.$3, '+2349031234567');
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
      GoRoute(path: '/cart', builder: (_, _) => const Scaffold(body: Text('the cart'))),
      GoRoute(path: '/checkout', builder: (_, _) => const Scaffold(body: Text('checkout'))),
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
    expect(find.text('checkout'), findsNothing);
  });

  void fillCart(ProviderContainer container) {
    container.read(cartProvider.notifier)
      ..add('r-suya', 'Suya Lane', item('sl-beef', 2))
      ..add('r-pharm', 'HealthPlus Pharmacy', const CartItem(itemId: 'ph-pcm', name: 'Paracetamol', unitPriceKobo: 50000, quantity: 1))
      ..add('r-suya', 'Suya Lane', item('sl-chicken', 1));
  }

  group('cart screen', () {
    const wings = MenuItem(id: 'sl-wings', restaurantId: 'r-suya', name: 'Chicken Wings', priceKobo: 300000, popularity: 5, emoji: '🍗');
    const ramSuya = MenuItem(id: 'sl-ram', restaurantId: 'r-suya', name: 'Ram Suya', priceKobo: 500000, popularity: 9, optionGroupIds: ['heat']);
    const gizzard = MenuItem(id: 'sl-gizzard', restaurantId: 'r-suya', name: 'Gizzard', priceKobo: 200000, popularity: 20, isAvailable: false);
    const suyaDetail = RestaurantDetail(
      restaurant: suya,
      sections: [MenuSection(category: MenuCategory(id: 'grills', name: 'Grills'), items: [beefSuya, wings, ramSuya, gizzard])],
      optionGroups: {'heat': heat},
    );

    Future<ProviderContainer> openCart(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(overrides: [
        // A visitor: the cart needs no account.
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        apiProvider.overrideWithValue(FakeApi()),
        // The pharmacy is closed: nothing of it is suggested.
        restaurantDetailProvider.overrideWith((ref, id) async => id == 'r-suya'
            ? suyaDetail
            : RestaurantDetail(
                restaurant: amala.copyWith(id: id),
                sections: const [MenuSection(category: MenuCategory(id: 'otc', name: 'Pain relief'), items: [MenuItem(id: 'ph-ibu', restaurantId: 'r-pharm', name: 'Ibuprofen', priceKobo: 80000, popularity: 50)])],
              )),
      ]);
      addTearDown(container.dispose);
      fillCart(container);
      final router = GoRouter(initialLocation: '/cart', routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home'))),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (_, _) => const Scaffold(body: Text('PAGE /checkout'))),
        GoRoute(path: '/restaurants/:id', builder: (_, s) => Scaffold(body: Text('STORE ${s.pathParameters['id']}'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      return container;
    }

    Finder line(ProviderContainer c, int index) => find.byKey(ValueKey('cart-line-${c.read(cartProvider).items[index].key}'));

    testWidgets('items are grouped by shop; the stepper adds, takes away and removes', (tester) async {
      final container = await openCart(tester);
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Your cart'), findsOneWidget);
      expect(find.text('4 products from 2 shops', findRichText: true), findsOneWidget);
      expect(find.text('Suya Lane'), findsOneWidget);
      expect(find.text('HealthPlus Pharmacy'), findsOneWidget);
      expect(find.text('Start a new cart?'), findsNothing);
      expect(tester.getTopLeft(find.text('sl-chicken')).dy, lessThan(tester.getTopLeft(find.text('HealthPlus Pharmacy')).dy),
          reason: 'both Suya Lane items sit under Suya Lane');
      expect(find.text('₦3,500'), findsOneWidget, reason: 'the total in the bottom bar');

      // One of a line: a bin removes it; more than one: "−" takes one away.
      final paracetamol = line(container, 1);
      expect(find.descendant(of: paracetamol, matching: find.byTooltip('Remove')), findsOneWidget);
      await tester.tap(find.descendant(of: paracetamol, matching: find.byTooltip('Add one')));
      await tester.pump();
      expect(container.read(cartProvider).items[1].quantity, 2);
      await tester.tap(find.descendant(of: paracetamol, matching: find.byTooltip('Remove one')));
      await tester.pump();
      expect(container.read(cartProvider).items[1].quantity, 1);
      await tester.tap(find.descendant(of: paracetamol, matching: find.byTooltip('Remove')));
      await tester.pumpAndSettle();
      expect(find.text('HealthPlus Pharmacy'), findsNothing, reason: 'its last item is gone, so the shop is too');
      expect(container.read(cartProvider).shops.single.restaurantId, 'r-suya');
      expect(find.text('3 products from Suya Lane', findRichText: true), findsOneWidget);
    });

    testWidgets('"Add more items" opens that shop and "Go to checkout" goes to checkout', (tester) async {
      await openCart(tester);
      await tapVisible(tester, find.byKey(const ValueKey('add-more-r-pharm')));
      expect(find.text('STORE r-pharm'), findsOneWidget);
      GoRouter.of(tester.element(find.text('STORE r-pharm'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to checkout'));
      await tester.pumpAndSettle();
      expect(find.text('PAGE /checkout'), findsOneWidget);
    });

    testWidgets('the bin at the top empties the cart after asking', (tester) async {
      final container = await openCart(tester);
      await tester.tap(find.byTooltip('Empty cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(container.read(cartProvider).count, 4);
      await tester.tap(find.byTooltip('Empty cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Empty cart'));
      await tester.pumpAndSettle();
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Go to checkout'), findsNothing);
    });

    testWidgets('"You might also like" offers popular items not in the cart; "+" adds one or asks for the choice', (tester) async {
      final container = await openCart(tester);
      expect(find.text('You might also like'), findsOneWidget);
      expect(find.text('Gizzard'), findsNothing, reason: 'sold out');
      expect(find.text('Ibuprofen'), findsNothing, reason: 'its shop is closed');
      expect(find.byKey(const ValueKey('suggest-add-sl-beef')), findsNothing, reason: 'already in the cart');
      expect(tester.getTopLeft(find.text('Ram Suya')).dx, lessThan(tester.getTopLeft(find.text('Chicken Wings')).dx),
          reason: 'the most popular first');

      await tapVisible(tester, find.byKey(const ValueKey('suggest-add-sl-wings')));
      final added = container.read(cartProvider).items.last;
      expect((added.restaurantId, added.itemId, added.quantity, added.unitPriceKobo, added.emoji), ('r-suya', 'sl-wings', 1, 300000, '🍗'));
      expect(find.byKey(const ValueKey('suggest-add-sl-wings')), findsNothing, reason: 'it is in the cart now');

      // A product with a required choice opens its sheet; adding it stays on the cart.
      await tapVisible(tester, find.byKey(const ValueKey('suggest-add-sl-ram')));
      expect(find.text('Yaji level (required)'), findsOneWidget);
      await tester.tap(find.text('Mild'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add to cart · ₦5,000'));
      await tester.pumpAndSettle();
      expect(container.read(cartProvider).items.last.itemId, 'sl-ram');
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('You might also like'), findsNothing, reason: 'nothing left to suggest');
    });
  });

  group('checkout', () {
    Future<(_MixedApi, ProviderContainer)> openCheckout(WidgetTester tester,
        {List overrides = const [], ContactPhoneStore? phones, FakePaymentPage? page}) async {
      tester.view.physicalSize = const Size(1080, 5400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final api = _MixedApi();
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'u1'))),
        apiProvider.overrideWithValue(api),
        contactPhoneStoreProvider.overrideWithValue(phones ?? MemoryContactPhoneStore('08031234567')),
        paymentPageProvider.overrideWithValue(page ?? FakePaymentPage()),
        ...overrides,
      ]);
      addTearDown(container.dispose);
      fillCart(container);
      final router = GoRouter(initialLocation: '/checkout', routes: [
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(path: '/cart', builder: (_, _) => const Scaffold(body: Text('PAGE /cart'))),
        GoRoute(path: '/plus', builder: (_, _) => const Scaffold(body: Text('PAGE /plus'))),
        GoRoute(path: '/orders', builder: (_, s) => Scaffold(body: Text('orders ${s.uri}'))),
        GoRoute(path: '/orders/:id', builder: (_, s) => Scaffold(body: Text('order ${s.uri}'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      return (api, container);
    }

    testWidgets('one price per shop, allergies and voucher, a grand total, and one payment for every order', (tester) async {
      final (api, container) = await openCheckout(tester);
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('4 products from 2 shops', findRichText: true), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
      await settleQuote(tester);
      expect(api.quoted.map((q) => (q.$1, q.$2)), [('r-suya', null), ('r-pharm', null)]);
      expect(api.quoted.first.$3.map((l) => l.itemId), ['sl-beef', 'sl-chicken']);

      await tapVisible(tester, find.text('Got a promo code?'));
      await tester.enterText(find.widgetWithText(TextField, 'Promo or voucher code'), 'welcome500');
      expect(api.quoted, hasLength(2), reason: 'typing a code changes nothing until it is applied');
      expect(find.textContaining("A code applies to one shop's order"), findsOneWidget);
      await tapVisible(tester, find.text('Apply'));
      await settleQuote(tester);
      expect(api.quoted.skip(2).map((q) => (q.$1, q.$2)), [('r-suya', 'WELCOME500'), ('r-pharm', null)],
          reason: 'the voucher goes with the first shop only');

      // The allergy note goes with every shop's order, on its first line.
      await tapVisible(tester, find.text('Any allergies?'));
      await tester.enterText(find.widgetWithText(TextField, 'Allergies or food needs'), 'Peanuts');
      await tester.tap(find.text('Save'));
      await settleQuote(tester);
      expect(api.quoted, hasLength(6));
      final suyaLines = api.quoted[4].$3;
      expect(suyaLines.map((l) => l.notes), ['Allergies: Peanuts', null]);
      expect(api.quoted[5].$3.single.notes, 'Allergies: Peanuts');
      expect(find.text('Peanuts'), findsOneWidget);

      expect(find.text('Shop total'), findsNWidgets(2));
      expect(find.text('Total to pay'), findsOneWidget);
      expect(find.text('₦16,365'), findsOneWidget); // 11,365 + 5,000

      await tapVisible(tester, find.text('Yummy Chops wallet'));
      await tester.tap(find.text('Pay to order'));
      await tester.pumpAndSettle();
      expect(api.orders.map((o) => o.$1), ['q-r-suya-5', 'q-r-pharm-6']);
      expect(api.orders[0].$2, isNot(api.orders[1].$2), reason: 'each order has its own key');
      expect(api.checkouts, hasLength(1));
      expect(api.checkouts.single.$1, ['o-q-r-suya-5', 'o-q-r-pharm-6']);
      expect(api.checkouts.single.$3, 'wallet');
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(find.text('orders /orders'), findsOneWidget, reason: 'several orders: each is listed on Orders');
    });

    testWidgets('a changed cart is priced again by itself', (tester) async {
      final (api, container) = await openCheckout(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
      await settleQuote(tester);
      expect(api.quoted, hasLength(2));
      container.read(cartProvider.notifier).setQuantity(container.read(cartProvider).items.first.key, 3);
      await tester.pump();
      expect(find.text('Total to pay'), findsNothing, reason: 'the old price is gone');
      await settleQuote(tester);
      expect(api.quoted, hasLength(4));
      expect(api.quoted[2].$3.first.quantity, 3);
      expect(find.text('Total to pay'), findsOneWidget);
    });

    testWidgets('pickup can be scheduled: the price is asked for that time', (tester) async {
      final (api, _) = await openCheckout(tester);
      await tester.tap(find.text('Pickup'));
      await settleQuote(tester);
      expect(api.quoted.map((q) => q.$4), [null, null]);
      expect(find.text('Pickup options'), findsOneWidget);
      expect(find.text('Ready in about 40 min'), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('delivery-options')));
      await tapVisible(tester, find.byKey(const ValueKey('schedule-option')));
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(GridView), matching: find.byType(ChoiceChip)).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Schedule for Tomorrow'));
      await settleQuote(tester);

      final at = api.quoted.last.$4;
      expect(at, isNotNull);
      expect(api.quoted.skip(2).map((q) => q.$4), [at, at], reason: 'every shop for the same time');
      final now = DateTime.now().toUtc();
      expect(at!.isAfter(now.add(const Duration(minutes: 30))), isTrue);
      expect(at.isBefore(now.add(const Duration(days: 7))), isTrue);
      expect(find.text('Scheduled'), findsOneWidget);
    });

    testWidgets('far from the phone: asked before paying, with "Edit address" and "Pay to order"', (tester) async {
      const home = DeliveryAddress(label: 'Home', line1: '5 Admiralty Way', area: 'Lekki Phase 1', location: GeoPoint(lat: 6.4478, lng: 3.4723));
      final (api, _) = await openCheckout(tester, overrides: [
        knownPositionProvider.overrideWith((ref) async => const GeoPoint(lat: 6.5095, lng: 3.3711)), // Yaba, ~13 km away
        addressesProvider.overrideWith((ref) async => const [home]),
      ]);
      await tapVisible(tester, find.text('Pin your exact address'));
      await tester.tap(find.text('Home'));
      await settleQuote(tester);
      expect(find.text('Far from current location'), findsOneWidget);
      expect(api.quoted.first.$3, isNotEmpty);

      await tester.tap(find.text('Pay to order'));
      await tester.pumpAndSettle();
      expect(find.text('Is this address correct?'), findsOneWidget);
      expect(api.orders, isEmpty, reason: 'nothing is paid before the customer answers');
      await tester.tap(find.text('Edit address'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Search street, estate or landmark'), findsOneWidget, reason: 'the address picker');
      await tester.tap(find.text('Home'));
      await settleQuote(tester);

      await tester.tap(find.text('Pay to order'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('far-pay')));
      await tester.pumpAndSettle();
      expect(api.orders, hasLength(2));
      expect(api.checkouts, hasLength(1));
    });

    testWidgets('customers without Plus see the free-delivery offer, which opens the Plus page', (tester) async {
      await openCheckout(tester, overrides: [
        plusProvider.overrideWith((ref) async => const PlusOverview(plan: PlusPlan(priceKobo: 150000))),
      ]);
      expect(find.text('Free delivery with Yummy Chops Plus'), findsOneWidget);
      await tapVisible(tester, find.text('More info'));
      expect(find.text('PAGE /plus'), findsOneWidget);
    });

    testWidgets('delivery needs a phone number: Pay waits for it, it goes with the order and the quote, and is remembered', (tester) async {
      const home = DeliveryAddress(id: 'a-home', label: 'Home', line1: '5 Admiralty Way', area: 'Lekki Phase 1', location: GeoPoint(lat: 6.4478, lng: 3.4723));
      final phones = MemoryContactPhoneStore();
      final (api, container) = await openCheckout(tester, phones: phones, overrides: [addressesProvider.overrideWith((ref) async => const [home])]);
      await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
      await settleQuote(tester);
      expect(find.text('Total to pay'), findsOneWidget);
      expect(find.text('Add your phone number'), findsOneWidget);
      expect(find.byKey(const ValueKey('checkout-phone-error')), findsOneWidget);
      expect(payButton(tester).onPressed, isNull);

      // Not a Nigerian number: still waiting, and the customer is told why.
      await tapVisible(tester, find.byKey(const ValueKey('checkout-phone')));
      await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '12345');
      await tester.tap(find.text('Save'));
      await settleQuote(tester);
      expect(find.text(invalidPhoneMessage), findsWidgets);
      expect(payButton(tester).onPressed, isNull);

      await tapVisible(tester, find.byKey(const ValueKey('checkout-phone')));
      await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '0803 123 4567');
      await tester.tap(find.text('Save'));
      await settleQuote(tester);
      expect(find.byKey(const ValueKey('checkout-phone-error')), findsNothing);
      expect(api.quoted.skip(api.quoted.length - 2).map((q) => q.$5?.contactPhone), ['+2348031234567', '+2348031234567']);

      await tapVisible(tester, find.text('Yummy Chops wallet'));
      await tester.tap(find.text('Pay to order'));
      await tester.pumpAndSettle();
      expect(api.orders.map((o) => o.$3), ['+2348031234567', '+2348031234567'], reason: 'every order has the number');
      // Remembered on the phone and on the Home address, so the next checkout is filled in.
      expect(phones.phone, '+2348031234567');
      expect(api.updatedAddresses.single.$1, 'a-home');
      expect(api.updatedAddresses.single.$2.contactPhone, '+2348031234567');
      expect(api.updatedAddresses.single.$2.line1, '5 Admiralty Way');
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    testWidgets('the phone number is filled in from the Home address when the phone has none', (tester) async {
      const home = DeliveryAddress(id: 'a-home', label: 'Home', line1: '5 Admiralty Way', location: GeoPoint(lat: 6.4478, lng: 3.4723), contactPhone: '08035550000');
      await openCheckout(tester, phones: MemoryContactPhoneStore(), overrides: [addressesProvider.overrideWith((ref) async => const [home])]);
      expect(find.text('08035550000'), findsOneWidget);
      expect(find.byKey(const ValueKey('checkout-phone-error')), findsNothing);
    });

    testWidgets('a card payment opens the payment page inside the app, refreshes Orders and goes to the order', (tester) async {
      final page = FakePaymentPage();
      final (api, container) = await openCheckout(tester, page: page);
      final sub = container.listen(myOrdersProvider, (_, _) {});
      addTearDown(sub.close);
      await tester.pumpAndSettle();
      final readsBefore = api.orderListReads;
      api.payUrl = 'https://checkout.paystack.com/abc';
      await tester.enterText(find.widgetWithText(TextField, 'Street address'), '5 Admiralty Road');
      await settleQuote(tester);
      await tester.tap(find.text('Pay to order'));
      await tester.pumpAndSettle();
      expect(page.opened, [Uri.parse('https://checkout.paystack.com/abc')]);
      expect(find.text('order /orders/o-q-r-suya-1?ref=YC-B-1&many=1'), findsOneWidget);
      expect(api.orderListReads, greaterThan(readsBefore), reason: 'the orders list is read again after a checkout');
    });

    testWidgets('"Your order" goes back to the cart', (tester) async {
      await openCheckout(tester);
      await tester.tap(find.byKey(const ValueKey('checkout-your-order')));
      await tester.pumpAndSettle();
      expect(find.text('PAGE /cart'), findsOneWidget);
    });
  });

  testWidgets('the summary marks delivery Plus made free and what the customer saves', (tester) async {
    final q = Quote(
      id: 'q1', restaurantName: 'Suya Lane', fulfillment: 'delivery', etaMinutes: 30,
      breakdown: const PriceBreakdown(subtotalKobo: 900000, serviceFeeKobo: 45000, vatKobo: 3375, discountKobo: 50000, plusSavingsKobo: 175000, totalKobo: 898375),
      estimatedDeliveryAt: DateTime.utc(2026, 11, 14, 19, 30), expiresAt: DateTime.utc(2026, 11, 14, 19, 0),
    );
    await tester.pumpWidget(MaterialApp(
      theme: buildGudMealTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: OrderSummaryPanel(quotes: [('Suya Lane', q)]))),
    ));
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text("You're saving ₦2,250 on this order", findRichText: true), findsOneWidget);
    expect(find.text('₦8,983.75'), findsOneWidget);
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
