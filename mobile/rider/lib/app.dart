import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'providers.dart';
import 'screens/delivery_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kyc_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';

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

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final listenable = _AuthListenable(auth.authStateChanges());
  ref.onDispose(listenable.dispose);
  return GoRouter(
    refreshListenable: listenable,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      // Signed out: sign in, or sign up as a new rider ("Become our rider").
      if (!signedIn && state.matchedLocation != '/sign-in' && state.matchedLocation != '/sign-up') return '/sign-in';
      if (signedIn && state.matchedLocation == '/sign-in') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const RiderHomeScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const RiderSignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const RiderSignUpScreen()),
      GoRoute(path: '/kyc', builder: (_, _) => const KycScreen()),
      GoRoute(path: '/deliveries/:id', builder: (_, s) => DeliveryScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/earnings', builder: (_, _) => const EarningsScreen()),
    ],
  );
});

class RiderApp extends ConsumerWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Yummy Chops Rider',
        debugShowCheckedModeBanner: false,
        theme: buildGudMealTheme(Brightness.light),
        darkTheme: buildGudMealTheme(Brightness.dark),
        routerConfig: ref.watch(routerProvider),
        // Phone test builds only: says so when the test server stops answering, and finds it again.
        builder: (context, child) => TestServerWatch.wrap(ref.watch(configProvider), child),
      );
}
