import 'package:flutter/foundation.dart';

/// Build-time configuration via `--dart-define` (no secrets: these values ship in the app binary).
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.agentsUrl,
    required this.useEmulators,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseProjectId,
    required this.firebaseMessagingSenderId,
    this.findTestServer = false,
    this.testServerHosts = const [],
    this.foundHost,
  });

  final String apiUrl;
  final String agentsUrl;
  final bool useEmulators;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseProjectId;
  final String firebaseMessagingSenderId;

  /// Phone test builds only (`scripts/build-test-apk.mjs`): at startup the app looks for the computer that runs the
  /// test server on the phone's Wi-Fi, because that computer's address changes with the Wi-Fi it joins
  /// (`test_server.dart`, docs/adr/0020-test-apps-find-the-test-server.md).
  final bool findTestServer;

  /// Addresses that computer had when earlier test builds were made: tried before the app searches the Wi-Fi.
  final List<String> testServerHosts;

  /// Where a phone test found the computer that runs the test server; null in every other build.
  final String? foundHost;

  /// Android emulators reach the host machine at 10.0.2.2.
  static String get _host => !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

  factory AppConfig.fromEnvironment() => AppConfig(
        apiUrl: const String.fromEnvironment('API_URL').isNotEmpty
            ? const String.fromEnvironment('API_URL')
            : 'http://$_host:8000',
        agentsUrl: const String.fromEnvironment('AGENTS_URL').isNotEmpty
            ? const String.fromEnvironment('AGENTS_URL')
            : 'http://$_host:8100',
        // The sign-in emulator is the default only in a debug run (`flutter run` against the local stack). A release
        // build uses it only when the build says so (`USE_FIREBASE_EMULATORS=true`, as the test builds do), so a
        // store build that forgets the setting cannot point sign-in at a test server.
        useEmulators: const bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: kDebugMode),
        firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key'),
        firebaseAppId: const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:000000000000:android:demo'),
        firebaseProjectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-gudmeal'),
        firebaseMessagingSenderId: const String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: '000000000000'),
        // Never in a store build: the search needs the emulators, which only test builds use. Not in a browser either
        // (a web page cannot open connections to the addresses around it).
        findTestServer: !kIsWeb &&
            const bool.fromEnvironment('FIND_TEST_SERVER') &&
            const bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: kDebugMode),
        testServerHosts: splitHosts(const String.fromEnvironment('TEST_SERVER_HOSTS')),
      );

  /// A list of hosts from one build setting: separated by `+`, commas, semicolons or spaces.
  static List<String> splitHosts(String value) =>
      value.split(RegExp(r'[+,;\s]+')).where((host) => host.isNotEmpty).toList();

  /// The host of the API. In a local or phone test this is the computer that runs every local service.
  String get serverHost => Uri.tryParse(apiUrl)?.host ?? '';

  /// Where the Firebase Auth emulator runs: where a phone test found the computer, else AUTH_EMULATOR_HOST if given,
  /// else the API's host when API_URL is set (a phone on the same Wi-Fi as the laptop running the stack), else the
  /// emulator/simulator default.
  String get emulatorHost {
    final found = foundHost;
    if (found != null) return found;
    const explicit = String.fromEnvironment('AUTH_EMULATOR_HOST');
    if (explicit.isNotEmpty) return explicit;
    const api = String.fromEnvironment('API_URL');
    final apiHost = api.isEmpty ? '' : (Uri.tryParse(api)?.host ?? '');
    return apiHost.isNotEmpty ? apiHost : _host;
  }

  /// The Auth emulator's port: 9099 on the computer running the phone test, or AUTH_EMULATOR_PORT when the build
  /// reaches the emulator another way (80 through the public test link, docs/adr/0024-public-test-link.md).
  int get emulatorPort =>
      foundHost != null ? 9099 : const int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);

  /// The same settings with the API, Yummy and the sign-in emulator on [host]: where a phone test found the computer
  /// that runs them.
  AppConfig onHost(String host) => AppConfig(
        apiUrl: _moved(apiUrl, host),
        agentsUrl: _moved(agentsUrl, host),
        useEmulators: useEmulators,
        firebaseApiKey: firebaseApiKey,
        firebaseAppId: firebaseAppId,
        firebaseProjectId: firebaseProjectId,
        firebaseMessagingSenderId: firebaseMessagingSenderId,
        findTestServer: findTestServer,
        testServerHosts: testServerHosts,
        foundHost: host,
      );

  static String _moved(String url, String host) => Uri.parse(url).replace(host: host).toString();
}
