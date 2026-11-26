import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../auth/sign_in_screen.dart' show TestGoogleAccountDialog;
import '../location/address_picker.dart';
import '../security/app_lock.dart';

/// Profile, for a guest: "Save your account" with Google (and Apple when the build turns it on). Saving links the
/// guest to that account, so the same customer keeps their orders. Email and phone sign-in sit behind "Other ways to
/// sign in" (staff and testers use email accounts).
class SaveAccountCard extends ConsumerStatefulWidget {
  const SaveAccountCard({super.key});

  @override
  ConsumerState<SaveAccountCard> createState() => _SaveAccountCardState();
}

class _SaveAccountCardState extends ConsumerState<SaveAccountCard> {
  bool _busy = false;
  String? _error;

  Future<void> _save(Future<LinkOutcome> Function() link) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await link();
      messenger.showSnackBar(SnackBar(
        content: Text(switch (outcome) {
          LinkOutcome.linked => 'Your account is saved. Your orders stay with it.',
          LinkOutcome.signedInToExisting =>
            'You already had an account, so you are signed in to it. Your cart stays on this phone; orders you placed '
                'as a guest stay with the guest.',
        }),
      ));
    } catch (e) {
      final reason = _reason(e);
      debugPrint('Save account failed: $e');
      // Closing Google's account list is not an error.
      if (reason == 'canceled') return;
      if (mounted) setState(() => _error = "Your account wasn't saved ($reason). Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A short reason to show (and for support): Firebase's or Google sign-in's error code when there is one.
  static String _reason(Object e) {
    try {
      final code = (e as dynamic).code;
      if (code != null) return code.toString().split('.').last;
    } catch (_) {}
    return e.runtimeType.toString();
  }

  Future<void> _google(AuthRepository auth) async {
    String? testEmail;
    if (auth.googleAsksForTestEmail) {
      testEmail = await showDialog<String>(context: context, builder: (_) => const TestGoogleAccountDialog());
      if (testEmail == null) return;
    }
    await _save(() => auth.linkWithGoogle(testEmail: testEmail));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authRepositoryProvider);
    final apple = ref.watch(configProvider).appleSignIn;
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('save-account'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Save your account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              "Save your account to keep your orders, addresses and points on any phone.",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('link-google'),
              onPressed: _busy ? null : () => _google(auth),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
            if (apple) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('link-apple'),
                onPressed: _busy ? null : () => _save(auth.linkWithApple),
                icon: const Icon(Icons.apple_rounded),
                label: const Text('Continue with Apple'),
              ),
            ],
            if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            Align(
              child: TextButton(
                key: const ValueKey('other-sign-in'),
                onPressed: _busy ? null : () => context.push('/sign-in?next=/profile'),
                child: const Text('Other ways to sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The address labelled "Home" in the customer's address book (the newest one), if any.
DeliveryAddress? homeAddress(List<DeliveryAddress> saved) {
  DeliveryAddress? home;
  for (final a in saved) {
    if ((a.label ?? '').trim().toLowerCase() == 'home') home = a;
  }
  return home;
}

/// Profile → "Home address · Use my location": the phone's GPS finds the address, the map shows it to confirm, and it
/// is saved to the address book as "Home". Afterwards the row shows it, with Change.
class HomeAddressTile extends ConsumerStatefulWidget {
  const HomeAddressTile({super.key});

  @override
  ConsumerState<HomeAddressTile> createState() => _HomeAddressTileState();
}

class _HomeAddressTileState extends ConsumerState<HomeAddressTile> {
  bool _saving = false;

  Future<void> _useMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickDeliveryAddress(context, title: 'Home address', start: AddressStart.myLocation);
    if (picked == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiProvider);
      // "Change" replaces the Home address: a second "Home" would leave two, and the address book's order (by id,
      // not by age) decides which one shows and which one checkout uses.
      final current = homeAddress(await ref.read(addressesProvider.future).catchError((Object _) => const <DeliveryAddress>[]));
      final currentId = current?.id;
      final address = picked.address.copyWith(
        label: 'Home',
        // The rider's number on the old Home address stays, unless the new one brings its own.
        contactPhone: picked.address.contactPhone ?? current?.contactPhone,
      );
      if (currentId != null) {
        await api.updateAddress(currentId, address);
      } else {
        await api.saveAddress(address);
      }
      if (!mounted) return;
      ref.invalidate(addressesProvider);
      final areas = ref.read(areasProvider).value ?? const [...lagosAreas, ...enuguAreas];
      final area = nearestArea(address.location, areas);
      if (area != null) ref.read(areaProvider.notifier).select(area);
      messenger.showSnackBar(const SnackBar(content: Text('Home address saved')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = homeAddress(ref.watch(addressesProvider).value ?? const []);
    return Column(children: [
      ListTile(
        key: const ValueKey('home-address'),
        leading: const Icon(Icons.home_outlined),
        title: const Text('Home address', style: TextStyle(fontSize: 16)),
        subtitle: Text(home == null ? 'Use my location' : [home.line1, home.area].whereType<String>().join(', ')),
        trailing: _saving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : home == null
                ? const Icon(Icons.my_location_rounded)
                : TextButton(key: const ValueKey('home-address-change'), onPressed: _useMyLocation, child: const Text('Change')),
        onTap: _saving ? null : _useMyLocation,
      ),
      const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }
}

/// Profile → "Unlock with fingerprint": only for a customer who has saved their account, on a phone that can check a
/// fingerprint.
class FingerprintTile extends ConsumerWidget {
  const FingerprintTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null || user.isAnonymous) return const SizedBox.shrink();
    if (ref.watch(biometricAvailableProvider).value != true) return const SizedBox.shrink();
    return Column(children: [
      SwitchListTile(
        key: const ValueKey('fingerprint-switch'),
        secondary: const Icon(Icons.fingerprint_rounded),
        title: const Text('Unlock with fingerprint', style: TextStyle(fontSize: 16)),
        subtitle: const Text('Ask for your fingerprint when Yummy Chops opens'),
        value: ref.watch(appLockProvider),
        onChanged: (on) async {
          final messenger = ScaffoldMessenger.of(context);
          final message = await setFingerprintUnlock(ref, on);
          if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
        },
      ),
      const Divider(height: 1, indent: 16, endIndent: 16),
    ]);
  }
}

/// Signs out (turning the fingerprint lock off): the app then starts afresh with a new guest.
Future<void> signOutOfProfile(WidgetRef ref) async {
  await ref.read(appLockProvider.notifier).setEnabled(false);
  await ref.read(authRepositoryProvider).signOut();
}
