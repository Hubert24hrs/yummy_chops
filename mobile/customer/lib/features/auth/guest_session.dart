import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/brand.dart';

/// Guest mode: nobody ever has to sign in to order. When no one is signed in (first launch, or after signing out),
/// the app quietly signs in a guest (Firebase anonymous sign-in) once. Orders, checkout, Yummy, the wallet... all use
/// that guest account; Profile offers to save it with Google or Apple.
///
/// The state is the last attempt: data when nothing is needed or it worked, loading while signing in, an error when
/// it failed (no network); [retry] tries again.
class GuestSession extends Notifier<AsyncValue<void>> {
  bool _busy = false;

  @override
  AsyncValue<void> build() {
    ref.listen<AsyncValue<GmUser?>>(authStateProvider, (_, next) {
      if (next is AsyncData<GmUser?> && next.value == null) Future.microtask(_signIn);
    }, fireImmediately: true);
    return const AsyncData(null);
  }

  Future<void> _signIn() async {
    final auth = ref.read(authRepositoryProvider);
    if (_busy || auth.currentUser != null) return;
    _busy = true;
    state = const AsyncLoading();
    try {
      await auth.signInAnonymously();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _busy = false;
    }
  }

  /// Tries the guest sign-in again (the "Try again" button).
  Future<void> retry() => _signIn();
}

final guestSessionProvider = NotifierProvider<GuestSession, AsyncValue<void>>(GuestSession.new);

/// Shows [child] once someone (a guest or a customer) is signed in. Until then it waits for the guest sign-in, and
/// says so with a "Try again" button when that fails, instead of letting the screen flash an error.
class GuestGate extends ConsumerWidget {
  const GuestGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(signedInUidProvider) != null) return child;
    final session = ref.watch(guestSessionProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: session.hasError
                ? Column(
                    key: const ValueKey('guest-error'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text("We can't connect right now", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Check your internet connection and try again.', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const ValueKey('guest-retry'),
                        onPressed: () => ref.read(guestSessionProvider.notifier).retry(),
                        child: const Text('Try again'),
                      ),
                    ],
                  )
                : const Column(
                    key: ValueKey('guest-loading'),
                    mainAxisSize: MainAxisSize.min,
                    children: [YummyChopsLogo(), SizedBox(height: 20), CircularProgressIndicator()],
                  ),
          ),
        ),
      ),
    );
  }
}
