import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_customer/features/group/group_screens.dart';
import 'package:gud_meal_customer/features/plus/plus_screen.dart';
import 'package:gud_meal_customer/features/profile/whatsapp_sheet.dart';
import 'package:gud_meal_customer/features/rewards/rewards_screen.dart';
import 'package:gud_meal_customer/providers.dart';

const ada = GmUser(uid: 'cust-1', name: 'Ada Obi', email: 'ada@example.com');

const plan = PlusPlan(
  priceKobo: 150000,
  vatKobo: 10465,
  periodDays: 30,
  freeDeliveryMinSubtotalKobo: 300000,
  serviceFeeDiscountBps: 5000,
  pointsMultiplier: 2,
  benefits: ['Free delivery on Food and Beauty orders of ₦3,000 or more', '50% off the service fee on Food and Beauty orders'],
);

GroupOrder _group({String myStatus = 'unpaid'}) => GroupOrder(
      id: 'g1',
      code: 'AB3K7P',
      status: 'ordered',
      hostName: 'Ada',
      restaurant: const GroupRestaurant(id: 'r-jollof', name: 'Jollof Junction'),
      members: const [
        GroupMemberView(uid: 'cust-1', name: 'Ada', isHost: true, ready: true, items: 1, itemsKobo: 550000),
        GroupMemberView(uid: 'cust-2', name: 'Bayo', me: true, ready: true, items: 2, itemsKobo: 300000),
      ],
      lines: const [
        GroupLineView(id: 'l1', memberUid: 'cust-2', member: 'Bayo', itemId: 'drink', name: 'Chapman', quantity: 2, lineTotalKobo: 300000),
      ],
      order: const GroupOrderRef(id: 'o1', shortCode: 'GM12AB', status: 'pending_payment', totalKobo: 1046154),
      totalKobo: 1046154,
      shares: [
        const GroupShareView(uid: 'cust-1', name: 'Ada', itemsKobo: 550000, amountKobo: 676923),
        GroupShareView(uid: 'cust-2', name: 'Bayo', me: true, itemsKobo: 300000, amountKobo: 369231, status: myStatus),
      ],
      myShare: GroupMyShare(amountKobo: 369231, itemsKobo: 300000, status: myStatus),
      paidKobo: myStatus == 'paid' ? 369231 : 0,
      remainingKobo: myStatus == 'paid' ? 676923 : 1046154,
      canPay: myStatus == 'unpaid',
    );

/// Fake API for the growth screens; never touches the network.
class GrowthApi extends GudMealApi {
  GrowthApi() : super(baseUrl: 'http://fake', token: () async => 'tok');
  bool member = false;
  final subscribed = <(String?, bool)>[];
  final redeemed = <int>[];
  final shares = <(String?, bool)>[];
  final created = <(String, String, String?)>[];
  GroupOrder groupState = _group();
  bool waLinked = false;
  bool cardPage = false; // card payments open the provider's page
  final verified = <String>[];

  @override
  Future<String> verifyPayment(String reference) async {
    verified.add(reference);
    member = true;
    return 'succeeded';
  }

  @override
  Future<WhatsAppStatus> whatsAppStatus() async => WhatsAppStatus(
        enabled: true,
        linked: waLinked,
        number: waLinked ? '+234 801 ••• 1111' : null,
        businessNumber: '+234 800 000 0000',
        chatLink: waLinked ? 'https://wa.me/2348000000000' : null,
      );

  @override
  Future<WhatsAppLinkCode> whatsAppLinkCode() async => WhatsAppLinkCode(
        code: '123456',
        expiresAt: DateTime.utc(2026, 11, 16, 12, 10),
        businessNumber: '+234 800 000 0000',
        waLink: 'https://wa.me/2348000000000?text=LINK%20123456',
      );

  @override
  Future<WhatsAppStatus> disconnectWhatsApp() async {
    waLinked = false;
    return whatsAppStatus();
  }

  @override
  Future<WalletOverview> wallet() async => const WalletOverview(balanceKobo: 500000);

  @override
  Future<PlusOverview> plus() async => PlusOverview(
        plan: plan,
        member: member,
        membership: member
            ? PlusMembership(paidThrough: DateTime.utc(2026, 12, 15), paidThroughText: 'Tue 15 Dec 2026', daysLeft: 30, periods: 1)
            : null,
      );

  @override
  Future<({TopUpResult payment, PlusOverview plus})> subscribePlus(String idempotencyKey, {String? provider, bool autoRenew = true}) async {
    subscribed.add((provider, autoRenew));
    if (cardPage) {
      return (
        payment: const TopUpResult(reference: 'YC-PLUS-C1', provider: 'paystack', authorizationUrl: 'https://pay.example.com/c1', amountKobo: 150000),
        plus: await plus(),
      );
    }
    member = true;
    return (payment: const TopUpResult(reference: 'YC-PLUS-W1', provider: 'wallet', amountKobo: 150000), plus: await plus());
  }

  @override
  Future<RewardsOverview> rewards() async => const RewardsOverview(
        points: 1240,
        pointsValueKobo: 124000,
        redeem: RewardsRedeem(stepPoints: 500, stepValueKobo: 50000, redeemablePoints: 1000, minSubtotalKobo: 200000),
        referral: RewardsReferral(code: 'ADAO7K2P', friendGetsKobo: 100000, youGetKobo: 100000, shareText: 'Get ₦1,000 off with ADAO7K2P'),
        vouchers: [RewardVoucher(code: 'YCP-3K7P9Q', description: '500 Yummy points', valueKobo: 50000, minSubtotalKobo: 200000)],
      );

  @override
  Future<RewardVoucher> redeemPoints(int points, String idempotencyKey) async {
    redeemed.add(points);
    return RewardVoucher(code: 'YCP-7Q2K9X', valueKobo: points * 100);
  }

  @override
  Future<List<RewardVoucher>> myVouchers() async => const [];

  @override
  Future<GroupOrder> group(String id) async => groupState;

  @override
  Future<({TopUpResult payment, GroupOrder group})> payGroupShare(String id, String idempotencyKey, {String? provider, bool coverRest = false}) async {
    shares.add((provider, coverRest));
    groupState = _group(myStatus: 'paid');
    return (payment: const TopUpResult(reference: 'YC-G1', provider: 'wallet', amountKobo: 369231), group: groupState);
  }

  @override
  Future<GroupOrder> createGroup({required String restaurantId, required String fulfillment, DeliveryAddress? address, String splitMode = 'each'}) async {
    created.add((fulfillment, splitMode, address?.line1));
    return groupState;
  }
}

Future<void> pump(WidgetTester tester, Widget home, GrowthApi api) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/group/:id', builder: (_, s) => Scaffold(body: Text('GROUP ${s.pathParameters['id']}'))),
    GoRoute(path: '/orders/:id', builder: (_, s) => Scaffold(body: Text('ORDER ${s.pathParameters['id']}'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository(ada)), apiProvider.overrideWithValue(api)],
    child: MaterialApp.router(theme: buildGudMealTheme(Brightness.light), routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Plus: the price and benefits, then joining from the wallet with auto-renew', (tester) async {
    final api = GrowthApi();
    await pump(tester, const PlusScreen(), api);
    expect(find.text('Free delivery on Food and Beauty orders of ₦3,000 or more'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('plus-join')));
    expect(find.text('Join for ₦1,500'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plus-join')));
    await tester.pumpAndSettle();
    expect(api.subscribed, [('wallet', true)]);
    expect(find.text('Member until Tue 15 Dec 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('plus-join')), findsNothing);
  });

  testWidgets('Plus by card: the payment is checked when the customer comes back from the payment page', (tester) async {
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    final opened = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, (call) async {
      opened.add((call.arguments as Map)['url']);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, null));
    final api = GrowthApi()..cardPage = true;
    await pump(tester, const PlusScreen(), api);
    await tester.ensureVisible(find.text('Card, bank transfer or USSD'));
    await tester.tap(find.text('Card, bank transfer or USSD'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('plus-join')));
    await tester.tap(find.byKey(const ValueKey('plus-join')));
    await tester.pumpAndSettle();
    expect(opened, ['https://pay.example.com/c1']);
    expect(api.verified, isEmpty, reason: 'nothing to check before the customer has paid');
    expect(find.byKey(const ValueKey('plus-join')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused); // on the payment page
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed); // and back
    await tester.pumpAndSettle();
    expect(api.verified, ['YC-PLUS-C1']);
    expect(find.text('Member until Tue 15 Dec 2026'), findsOneWidget);
  });

  testWidgets('Rewards: points, voucher steps, vouchers and the referral code', (tester) async {
    final api = GrowthApi();
    await pump(tester, const RewardsScreen(), api);
    expect(find.text('1240'), findsOneWidget);
    expect(find.byKey(const ValueKey('redeem-500')), findsOneWidget);
    expect(find.text('₦500 off · YCP-3K7P9Q'), findsOneWidget);
    expect(find.text('ADAO7K2P'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('redeem-1000')));
    await tester.pumpAndSettle();
    expect(api.redeemed, [1000]);
    expect(find.text('Your ₦1,000 voucher YCP-7Q2K9X is ready. Pick it at checkout.'), findsOneWidget);
  });

  testWidgets('Group order: the bill shows who has paid, and a member pays their share', (tester) async {
    final api = GrowthApi();
    await pump(tester, const GroupScreen(id: 'g1'), api);
    expect(find.text('Waiting for everyone to pay'), findsOneWidget);
    expect(find.text('Who pays what'), findsOneWidget);
    expect(find.text('Not paid yet'), findsNWidgets(2));
    await tester.ensureVisible(find.byKey(const ValueKey('pay-share')));
    expect(find.text('Pay my share · ₦3,692.31'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pay-share')));
    await tester.pumpAndSettle();
    expect(api.shares, [(null, false)]);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-share')), findsNothing);
  });

  testWidgets('Order with friends: starting a group order opens it', (tester) async {
    final api = GrowthApi();
    await pump(tester, Scaffold(body: Builder(builder: (context) {
      return Center(
        child: FilledButton(
          onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const StartGroupSheet(restaurantId: 'r-jollof')),
          child: const Text('open'),
        ),
      );
    })), api);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-group')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the street address for the delivery'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5 Bisola Durosinmi-Etti Drive');
    await tester.tap(find.text('I pay for all'));
    await tester.tap(find.byKey(const ValueKey('start-group')));
    await tester.pumpAndSettle();
    expect(api.created, [('delivery', 'host', '5 Bisola Durosinmi-Etti Drive')]);
    expect(find.text('GROUP g1'), findsOneWidget);
  });

  testWidgets('Connect WhatsApp: a code to send, then connected, then disconnect', (tester) async {
    final api = GrowthApi();
    await pump(tester, const Scaffold(body: WhatsAppSheet()), api);
    await tester.tap(find.byKey(const ValueKey('whatsapp-connect')));
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('Open WhatsApp'), findsOneWidget);
    api.waLinked = true; // the customer sent "LINK 123456" from WhatsApp
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('+234 801 ••• 1111'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('whatsapp-disconnect')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('whatsapp-connect')), findsOneWidget);
  });
}
