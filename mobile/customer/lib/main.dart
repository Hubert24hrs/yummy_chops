import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'app.dart';
import 'features/cart/contact_phone.dart';
import 'features/security/app_lock.dart';
import 'maps_loader.dart';
import 'providers.dart';
import 'ui/gm_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var config = AppConfig.fromEnvironment();
  // A phone test build first finds the computer that runs the test server: its address changes with the Wi-Fi it
  // joins, and the sign-in emulator below can be given an address only once.
  if (config.findTestServer) config = await locateTestServer(config, appName: 'Yummy Chops');
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: config.firebaseApiKey,
      appId: config.firebaseAppId,
      messagingSenderId: config.firebaseMessagingSenderId,
      projectId: config.firebaseProjectId,
    ),
  );
  if (config.useEmulators) {
    await connectAuthEmulator(FirebaseAuth.instance, config.emulatorHost, port: config.emulatorPort);
  }
  if (mapsEnabled && kIsWeb) {
    googleMapsReady = await loadGoogleMapsScript(const String.fromEnvironment('MAPS_BROWSER_KEY'));
  }
  final auth = FirebaseAuthRepository(
    FirebaseAuth.instance,
    usingEmulator: config.useEmulators,
    googleWebClientId: config.googleWebClientId,
  );
  // Read before the first frame, so "Unlock with fingerprint" covers the app before anything shows.
  final appLock = await SharedPrefsAppLockStore.open();
  // The phone number used at the last checkout fills in the next one.
  final contactPhone = await SharedPrefsContactPhoneStore.open();
  // What the app keeps in memory belongs to the signed-in customer: it all starts afresh when they sign out.
  runApp(PerUserScope(
    auth: auth,
    child: ProviderScope(
      overrides: [
        configProvider.overrideWithValue(config),
        authRepositoryProvider.overrideWithValue(auth),
        appLockStoreProvider.overrideWithValue(appLock),
        contactPhoneStoreProvider.overrideWithValue(contactPhone),
      ],
      child: const GudMealApp(),
    ),
  ));
}
