import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers.dart';
import '../../ui/brand.dart';

/// The phone's fingerprint (or face) check, behind a port so tests can fake it.
abstract class BiometricAuth {
  /// The phone can check a fingerprint (or face) and has one enrolled.
  Future<bool> isAvailable();

  /// Asks for the fingerprint; the phone also offers its PIN, pattern or password instead. True when it passed.
  Future<bool> authenticate(String reason);
}

/// [BiometricAuth] with the `local_auth` plugin. Android needs `FlutterFragmentActivity` and `USE_BIOMETRIC`.
class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false; // a browser build, or a test without the plugin
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // biometricOnly false: the phone's PIN/pattern is the fallback ("Use phone PIN").
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }
}

final biometricAuthProvider = Provider<BiometricAuth>((ref) => LocalBiometricAuth());

/// Whether this phone can offer "Unlock with fingerprint".
final biometricAvailableProvider = FutureProvider<bool>((ref) => ref.watch(biometricAuthProvider).isAvailable());

/// Where "Unlock with fingerprint" is remembered on this phone.
abstract class AppLockStore {
  bool get enabled;
  Future<void> setEnabled(bool enabled);
}

/// In memory (tests, and when the phone's storage can't be read).
class MemoryAppLockStore implements AppLockStore {
  MemoryAppLockStore({this.enabled = false});
  @override
  bool enabled;
  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}

/// In the app's shared preferences, read once in `main()` so the lock shows before anything else.
class SharedPrefsAppLockStore implements AppLockStore {
  SharedPrefsAppLockStore._(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'app_lock_fingerprint';

  /// The store, or one in memory when the phone's storage can't be read.
  static Future<AppLockStore> open() async {
    try {
      return SharedPrefsAppLockStore._(await SharedPreferences.getInstance());
    } catch (_) {
      return MemoryAppLockStore();
    }
  }

  @override
  bool get enabled => _prefs.getBool(_key) ?? false;

  @override
  Future<void> setEnabled(bool value) => _prefs.setBool(_key, value);
}

final appLockStoreProvider = Provider<AppLockStore>((ref) => MemoryAppLockStore());

/// "Unlock with fingerprint" is on.
class AppLockController extends Notifier<bool> {
  @override
  bool build() => ref.watch(appLockStoreProvider).enabled;

  Future<void> setEnabled(bool value) async {
    await ref.read(appLockStoreProvider).setEnabled(value);
    state = value;
  }
}

final appLockProvider = NotifierProvider<AppLockController, bool>(AppLockController.new);

/// How long the app may stay in the background before it asks for the fingerprint again.
const appLockAfter = Duration(minutes: 5);

/// Covers the app with [AppLockScreen] when "Unlock with fingerprint" is on and a customer with a saved account is
/// signed in: when the app opens, and when it comes back after more than [appLockAfter] in the background. What is
/// under it keeps its place.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child, this.now = DateTime.now});
  final Widget child;

  /// The clock (tests move it on).
  final DateTime Function() now;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  bool _decided = false;
  bool _locked = false;
  DateTime? _backgroundSince;

  bool get _shouldLock {
    final user = ref.read(authRepositoryProvider).currentUser;
    return ref.read(appLockProvider) && user != null && !user.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _backgroundSince ??= widget.now();
      case AppLifecycleState.resumed:
        final since = _backgroundSince;
        _backgroundSince = null;
        if (since != null && widget.now().difference(since) > appLockAfter && _shouldLock) setState(() => _locked = true);
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _signOut() async {
    await ref.read(appLockProvider.notifier).setEnabled(false);
    if (mounted) setState(() => _locked = false);
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value ?? ref.read(authRepositoryProvider).currentUser;
    // Decided once, as soon as the app knows who is signed in: that is "when the app opens".
    if (!_decided && user != null) {
      _decided = true;
      _locked = _shouldLock;
    }
    final locked = _locked && user != null && !user.isAnonymous && ref.watch(appLockProvider);
    return Stack(children: [
      Offstage(offstage: locked, child: TickerMode(enabled: !locked, child: widget.child)),
      if (locked)
        Positioned.fill(
          child: AppLockScreen(onUnlocked: () => setState(() => _locked = false), onSignOut: _signOut),
        ),
    ]);
  }
}

/// "Yummy Chops is locked": asks for the fingerprint at once, with the phone's PIN as the fallback and signing out as
/// the way out.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked, required this.onSignOut});
  final VoidCallback onUnlocked;
  final Future<void> Function() onSignOut;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final ok = await ref.read(biometricAuthProvider).authenticate('Unlock Yummy Chops');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _message = "That didn't work. Try again, or use your phone's PIN.";
    });
    if (ok) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('app-lock'),
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: YummyChopsLogo(height: 96)),
              const SizedBox(height: 24),
              Icon(Icons.fingerprint_rounded, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Yummy Chops is locked',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Unlock with your fingerprint to carry on.', textAlign: TextAlign.center),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('app-unlock'),
                onPressed: _busy ? null : _unlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock with fingerprint'),
              ),
              const SizedBox(height: 8),
              // The phone's own prompt offers its PIN, pattern or password too (biometricOnly is off).
              OutlinedButton(
                key: const ValueKey('app-unlock-pin'),
                onPressed: _busy ? null : _unlock,
                child: const Text('Use phone PIN'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('app-lock-sign-out'),
                onPressed: _busy ? null : widget.onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Turns "Unlock with fingerprint" on (after one successful check) or off. Returns a message to show, if any.
Future<String?> setFingerprintUnlock(WidgetRef ref, bool on) async {
  if (on) {
    final ok = await ref.read(biometricAuthProvider).authenticate('Turn on unlock with fingerprint');
    if (!ok) return "Fingerprint unlock wasn't turned on.";
  }
  await ref.read(appLockProvider.notifier).setEnabled(on);
  return null;
}
