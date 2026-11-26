import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

class GmUser {
  const GmUser({required this.uid, this.email, this.name, this.phone, this.isAnonymous = false});
  final String uid;
  final String? email;
  final String? name;
  final String? phone;

  /// A guest: the app signed in quietly (Firebase anonymous sign-in) so the customer can order without an account.
  /// Saving the account (Google or Apple in Profile) links this same user, so the uid and its orders stay.
  final bool isAnonymous;
}

/// What happened when a guest saved their account with Google or Apple.
enum LinkOutcome {
  /// The guest became that Google/Apple account: same uid, so their orders stay.
  linked,

  /// That Google/Apple account already existed, so the phone signed in to it instead. The cart stays on the phone;
  /// orders made as the guest stay with the guest.
  signedInToExisting,
}

/// Authentication port. The Firebase implementation is used in the apps; tests use a fake.
abstract class AuthRepository {
  Stream<GmUser?> authStateChanges();
  GmUser? get currentUser;
  Future<String?> idToken();

  /// Gets a fresh sign-in token now, e.g. after the server gave the account a new role (a new rider).
  Future<void> refreshToken();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String name, String email, String password);

  /// Starts phone sign-in (Nigerian numbers in E.164, e.g. +2348012345678). Returns a verification id.
  Future<String> startPhoneSignIn(String phoneNumber);
  Future<void> confirmPhoneCode(String verificationId, String smsCode);

  /// Sign in with a Google account ("Continue with Google", as on the website).
  ///
  /// The local sign-in emulator has no Google account chooser, so on the test server the screen asks which
  /// Google address to use and passes it as [testEmail]; [googleAsksForTestEmail] says when that is needed.
  Future<void> signInWithGoogle({String? testEmail});
  bool get googleAsksForTestEmail;

  /// Signs in a guest (Firebase anonymous sign-in): the customer app does this when nobody is signed in.
  Future<void> signInAnonymously();

  /// Saves a guest's account with Google: links the guest to the Google account so the uid stays. When that Google
  /// account already exists, signs in to it instead. [testEmail] as for [signInWithGoogle].
  Future<LinkOutcome> linkWithGoogle({String? testEmail});

  /// As [linkWithGoogle], with an Apple ID.
  Future<LinkOutcome> linkWithApple();
  Future<void> signOut();
}

/// Connects [auth] to the local Firebase Auth emulator (local testing only).
///
/// Browser builds: while the app starts, the Firebase web SDK checks a remembered session with Google's servers,
/// and after that the emulator can no longer be attached. The app would then talk to production sign-in and
/// every sign-in would fail (found in the owner's browser preview: "Sign-in failed" after a page reload). So with
/// the emulator a browser build keeps its session for this page load only: reloading the page asks to sign in
/// again. A session remembered by an older build is dropped, and works again after one more reload.
Future<void> connectAuthEmulator(fb.FirebaseAuth auth, String host, {int port = 9099}) async {
  if (kIsWeb) {
    await auth.setPersistence(fb.Persistence.NONE);
    if (auth.currentUser != null) await auth.signOut();
  }
  await auth.useAuthEmulator(host, port);
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {this.usingEmulator = false});
  final fb.FirebaseAuth _auth;

  /// Connected to the local Auth emulator (local testing), not to Firebase.
  final bool usingEmulator;

  GmUser? _map(fb.User? u) {
    if (u == null) return null;
    // Right after a guest links Google or Apple, the name and email may only be on the provider's profile.
    String? fromProviders(String? Function(fb.UserInfo) field) {
      for (final info in u.providerData) {
        final value = field(info);
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    return GmUser(
      uid: u.uid,
      email: u.email ?? fromProviders((i) => i.email),
      name: u.displayName ?? fromProviders((i) => i.displayName),
      phone: u.phoneNumber,
      isAnonymous: u.isAnonymous,
    );
  }

  @override
  Stream<GmUser?> authStateChanges() => _auth.idTokenChanges().map(_map);

  @override
  GmUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> refreshToken() async => _auth.currentUser?.getIdToken(true);

  @override
  Future<void> signInWithEmail(String email, String password) => _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> signUpWithEmail(String name, String email, String password) async {
    final guest = _auth.currentUser;
    if (guest != null && guest.isAnonymous) {
      // A guest creating an account keeps their uid, so the orders they placed as a guest stay theirs.
      final cred = await guest.linkWithCredential(fb.EmailAuthProvider.credential(email: email, password: password));
      await cred.user?.updateDisplayName(name);
      await cred.user?.getIdToken(true);
      return;
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);
  }

  @override
  Future<String> startPhoneSignIn(String phoneNumber) {
    final completer = Completer<String>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential); // Android auto-retrieval
        if (!completer.isCompleted) completer.complete('');
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) =>
      _auth.signInWithCredential(fb.PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode));

  @override
  bool get googleAsksForTestEmail => usingEmulator;

  /// The emulator accepts an unsigned ID token: the stand-in for Google's account chooser on the test server, on
  /// phones and in a browser alike (the emulator's own pop-up cannot open inside an embedded preview).
  static fb.AuthCredential _testGoogleCredential(String? testEmail) {
    final email = (testEmail ?? '').trim().toLowerCase();
    if (!email.contains('@')) throw ArgumentError.value(testEmail, 'testEmail', 'Enter a Google address');
    final token = jsonEncode({'sub': 'test-$email', 'email': email, 'email_verified': true, 'name': email.split('@').first});
    return fb.GoogleAuthProvider.credential(idToken: token);
  }

  Future<void> _signInWithProvider(fb.AuthProvider provider) async {
    if (kIsWeb) {
      await _auth.signInWithPopup(provider); // the provider's account chooser
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  @override
  Future<void> signInWithGoogle({String? testEmail}) async {
    if (usingEmulator) {
      await _auth.signInWithCredential(_testGoogleCredential(testEmail));
    } else {
      await _signInWithProvider(fb.GoogleAuthProvider());
    }
  }

  @override
  Future<void> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<LinkOutcome> linkWithGoogle({String? testEmail}) =>
      usingEmulator ? _linkCredential(_testGoogleCredential(testEmail)) : _linkProvider(fb.GoogleAuthProvider());

  @override
  Future<LinkOutcome> linkWithApple() => _linkProvider(fb.AppleAuthProvider());

  /// The provider account already belongs to another Yummy Chops user.
  static bool _alreadyInUse(fb.FirebaseAuthException e) =>
      e.code == 'credential-already-in-use' || e.code == 'email-already-in-use';

  Future<LinkOutcome> _linkCredential(fb.AuthCredential credential) async {
    final guest = _auth.currentUser;
    if (guest == null || !guest.isAnonymous) {
      await _auth.signInWithCredential(credential);
      return LinkOutcome.signedInToExisting;
    }
    try {
      await guest.linkWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      if (!_alreadyInUse(e)) rethrow;
      await _auth.signInWithCredential(e.credential ?? credential);
      return LinkOutcome.signedInToExisting;
    }
    await _linked();
    return LinkOutcome.linked;
  }

  Future<LinkOutcome> _linkProvider(fb.AuthProvider provider) async {
    final guest = _auth.currentUser;
    if (guest == null || !guest.isAnonymous) {
      await _signInWithProvider(provider);
      return LinkOutcome.signedInToExisting;
    }
    try {
      if (kIsWeb) {
        await guest.linkWithPopup(provider);
      } else {
        await guest.linkWithProvider(provider);
      }
    } on fb.FirebaseAuthException catch (e) {
      if (!_alreadyInUse(e)) rethrow;
      final credential = e.credential;
      if (credential != null) {
        await _auth.signInWithCredential(credential);
      } else {
        await _signInWithProvider(provider);
      }
      return LinkOutcome.signedInToExisting;
    }
    await _linked();
    return LinkOutcome.linked;
  }

  /// A fresh token after linking: the app hears about the new name and email (and the API sees the provider).
  Future<void> _linked() async {
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Starts everything under it afresh when the signed-in user leaves: they sign out, or another account takes their
/// place. What the app keeps in memory (orders, addresses, wallet, cart, a rider's earnings and KYC) belongs to that
/// user and must not be shown to the next person on the same phone. Signing in keeps what a visitor already chose,
/// and so does a guest (anonymous user) signing in to an account: the guest's cart stays on the phone.
///
/// It goes above the app's `ProviderScope` in `main()`.
class PerUserScope extends StatefulWidget {
  const PerUserScope({super.key, required this.auth, required this.child});
  final AuthRepository auth;
  final Widget child;

  @override
  State<PerUserScope> createState() => _PerUserScopeState();
}

class _PerUserScopeState extends State<PerUserScope> {
  late final StreamSubscription<GmUser?> _changes;
  String? _uid;
  bool _guest = false;

  /// How many users have left since the app started: a new number is a new start for [PerUserScope.child].
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _uid = widget.auth.currentUser?.uid;
    _guest = widget.auth.currentUser?.isAnonymous ?? false;
    _changes = widget.auth.authStateChanges().listen((user) {
      final left = _uid != null && _uid != user?.uid && !(_guest && user != null);
      _uid = user?.uid;
      _guest = user?.isAnonymous ?? false;
      if (left) setState(() => _left++);
    });
  }

  @override
  void dispose() {
    _changes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: ValueKey(_left), child: widget.child);
}

/// In-memory auth for tests and screenshots.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([GmUser? user]) : _user = user;
  GmUser? _user;
  final _controller = StreamController<GmUser?>.broadcast();

  /// The current user first, then every change. Subscribes to the changes at once, so a change made right after the
  /// first event (the app signing in a guest) is not missed.
  @override
  Stream<GmUser?> authStateChanges() {
    StreamSubscription<GmUser?>? changes;
    late final StreamController<GmUser?> out;
    out = StreamController<GmUser?>(
      sync: true,
      // Like Firebase, the first event comes a moment after listening; the changes follow without a gap.
      onListen: () => scheduleMicrotask(() {
        if (out.isClosed || !out.hasListener) return;
        changes = _controller.stream.listen(out.add);
        out.add(_user);
      }),
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  @override
  GmUser? get currentUser => _user;

  @override
  Future<String?> idToken() async => _user == null ? null : 'fake-token-${_user!.uid}';

  int tokenRefreshes = 0;

  @override
  Future<void> refreshToken() async => tokenRefreshes++;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (password.length < 6) throw Exception('Invalid credentials');
    _user = GmUser(uid: 'u-$email', email: email);
    _controller.add(_user);
  }

  @override
  Future<void> signUpWithEmail(String name, String email, String password) => signInWithEmail(email, password);

  @override
  bool googleAsksForTestEmail = false;

  @override
  Future<void> signInWithGoogle({String? testEmail}) async {
    final email = testEmail ?? 'google.user@example.com';
    _user = GmUser(uid: 'u-$email', email: email, name: email.split('@').first);
    _controller.add(_user);
  }

  /// Set to make [signInAnonymously] fail (no network), as a test needs.
  Object? anonymousSignInError;
  int anonymousSignIns = 0;

  /// Google/Apple addresses that already have an account: linking a guest to one signs in to it instead.
  final Set<String> existingAccounts = {};

  @override
  Future<void> signInAnonymously() async {
    final error = anonymousSignInError;
    if (error != null) throw error;
    anonymousSignIns++;
    _user = GmUser(uid: 'guest-$anonymousSignIns', isAnonymous: true);
    _controller.add(_user);
  }

  Future<LinkOutcome> _link(String email) async {
    final guest = _user;
    final name = email.split('@').first;
    if (guest != null && guest.isAnonymous && !existingAccounts.contains(email)) {
      _user = GmUser(uid: guest.uid, email: email, name: name);
      _controller.add(_user);
      return LinkOutcome.linked;
    }
    _user = GmUser(uid: 'u-$email', email: email, name: name);
    _controller.add(_user);
    return LinkOutcome.signedInToExisting;
  }

  @override
  Future<LinkOutcome> linkWithGoogle({String? testEmail}) => _link(testEmail ?? 'google.user@example.com');

  @override
  Future<LinkOutcome> linkWithApple() => _link('apple.user@privaterelay.appleid.com');

  @override
  Future<String> startPhoneSignIn(String phoneNumber) async => 'verification-$phoneNumber';

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) async {
    _user = GmUser(uid: 'u-${verificationId.split('-').last}', phone: verificationId.split('-').last);
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
