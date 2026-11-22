import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'features/assistant/assistant_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/cart/checkout_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/group/group_screens.dart';
import 'features/home/home_screen.dart';
import 'features/info/info_screens.dart';
import 'features/location/delivery_location.dart';
import 'features/location/nearby_map_screen.dart';
import 'features/orders/order_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/receipts/receipt_screen.dart';
import 'features/parcel/parcel_screen.dart';
import 'features/parcel/waybill_screen.dart';
import 'features/plus/plus_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/restaurant/restaurant_screen.dart';
import 'features/rewards/rewards_screen.dart';
import 'features/support/support_screen.dart';
import 'features/vertical/vertical_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'providers.dart';
import 'shell.dart';

/// Re-runs GoRouter redirects whenever the signed-in user changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<GmUser?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<GmUser?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Screens that need an account. Tabs (Orders, Profile) show a sign-in prompt instead of redirecting.
const _protected = ['/checkout', '/assistant', '/send', '/orders/', '/wallet', '/plus', '/rewards', '/group', '/receipts', '/partner-with-us', '/ride'];

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final listenable = _AuthListenable(auth.authStateChanges());
  ref.onDispose(listenable.dispose);
  return GoRouter(
    navigatorKey: _rootKey,
    refreshListenable: listenable,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final path = state.matchedLocation;
      if (!signedIn && _protected.any(path.startsWith)) return '/sign-in?next=${Uri.encodeComponent(state.uri.toString())}';
      if (signedIn && path == '/sign-in') return state.uri.queryParameters['next'] ?? '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (_, _) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => OrderScreen(
                    id: s.pathParameters['id']!,
                    paymentReference: s.uri.queryParameters['ref'],
                    justPaid: s.uri.queryParameters['paid'] == '1',
                  ),
                  routes: [
                    GoRoute(
                      path: 'receipt',
                      parentNavigatorKey: _rootKey,
                      builder: (_, s) => ReceiptScreen(orderId: s.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/support', builder: (_, _) => const SupportScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/food', builder: (_, s) => VerticalScreen(vertical: 'food', category: s.uri.queryParameters['category'])),
      GoRoute(path: '/beauty', builder: (_, s) => VerticalScreen(vertical: 'beauty', category: s.uri.queryParameters['category'])),
      // Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, ADR-0025): the same service page, with their own shops.
      for (final service in const [groceryService, pharmacyService, marketService])
        GoRoute(
          path: service.route,
          builder: (_, s) => VerticalScreen(vertical: service.id, category: s.uri.queryParameters['category']),
        ),
      GoRoute(
        path: '/send',
        builder: (_, s) => s.uri.queryParameters['mode'] == 'interstate' ? const WaybillScreen() : const ParcelScreen(),
      ),
      GoRoute(path: '/map', builder: (_, s) => NearbyMapScreen(vertical: s.uri.queryParameters['vertical'] ?? 'food')),
      GoRoute(
        path: '/restaurants/:id',
        builder: (_, s) => RestaurantScreen(id: s.pathParameters['id']!, initialItemId: s.uri.queryParameters['item']),
      ),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
      GoRoute(path: '/receipts', builder: (_, _) => const ReceiptsScreen()),
      // Pages the website has too: help centre, package tracking by number, and the two sign-ups.
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/track', builder: (_, s) => TrackScreen(code: s.uri.queryParameters['code'])),
      GoRoute(path: '/partner-with-us', builder: (_, _) => const BusinessApplyScreen()),
      GoRoute(path: '/ride', builder: (_, _) => const RiderApplyScreen()),
      GoRoute(path: '/plus', builder: (_, _) => const PlusScreen()),
      GoRoute(path: '/rewards', builder: (_, _) => const RewardsScreen()),
      GoRoute(
        path: '/group',
        builder: (_, s) => GroupHubScreen(initialCode: s.uri.queryParameters['code']),
        routes: [GoRoute(path: ':id', builder: (_, s) => GroupScreen(id: s.pathParameters['id']!))],
      ),
      GoRoute(path: '/assistant', builder: (_, s) => AssistantScreen(initial: s.uri.queryParameters['q'])),
    ],
  );
});

class GudMealApp extends ConsumerWidget {
  const GudMealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Notices a fresh sign-in, so the customer is asked where to deliver (features/location/delivery_location.dart).
    ref.listen(askWhereToDeliverProvider, (_, _) {});
    return MaterialApp.router(
      title: 'Yummy Chops',
      debugShowCheckedModeBanner: false,
      theme: buildGudMealTheme(Brightness.light),
      darkTheme: buildGudMealTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // Phone test builds only: says so when the test server stops answering, and finds it again.
      builder: (context, child) => TestServerWatch.wrap(ref.watch(configProvider), child),
    );
  }
}
