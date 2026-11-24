import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;

class GmUser {
  const GmUser({required this.uid, this.email, this.name, this.phone});
  final String uid;
  final String? email;
  final String? name;
  final String? phone;
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

  GmUser? _map(fb.User? u) => u == null ? null : GmUser(uid: u.uid, email: u.email, name: u.displayName, phone: u.phoneNumber);

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

  @override
  Future<void> signInWithGoogle({String? testEmail}) async {
    if (usingEmulator) {
      // The emulator accepts an unsigned ID token: the stand-in for Google's account chooser on the test
      // server, on phones and in a browser alike (the emulator's own pop-up cannot open inside an embedded
      // preview).
      final email = (testEmail ?? '').trim().toLowerCase();
      if (!email.contains('@')) throw ArgumentError.value(testEmail, 'testEmail', 'Enter a Google address');
      final token = jsonEncode({'sub': 'test-$email', 'email': email, 'email_verified': true, 'name': email.split('@').first});
      await _auth.signInWithCredential(fb.GoogleAuthProvider.credential(idToken: token));
    } else if (kIsWeb) {
      await _auth.signInWithPopup(fb.GoogleAuthProvider()); // Google's account chooser
    } else {
      await _auth.signInWithProvider(fb.GoogleAuthProvider());
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// In-memory auth for tests and screenshots.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([GmUser? user]) : _user = user;
  GmUser? _user;
  final _controller = StreamController<GmUser?>.broadcast();

  @override
  Stream<GmUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
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
