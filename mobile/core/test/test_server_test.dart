import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// A pretend Wi-Fi: which addresses run the Yummy Chops API, which have something else on the same port, which
/// addresses the phone itself has, and what the app remembers from last time.
class _Wifi {
  _Wifi({this.gudMeal = const {}, this.other = const {}, this.own = const [], this.last});

  Set<String> gudMeal;
  Set<String> other;
  List<String> own;
  String? last;

  final asked = <String>[]; // given the full check
  final knocked = <String>[]; // given the quick check
  final saved = <String>[];

  TestServerFinder finder(List<String> known, {int maxNetworks = 4}) => TestServerFinder(
        knownHosts: known,
        isGudMeal: (host) async {
          asked.add(host);
          return gudMeal.contains(host);
        },
        portOpen: (host) async {
          knocked.add(host);
          return gudMeal.contains(host) || other.contains(host);
        },
        localAddresses: () async => own,
        loadLastHost: () async => last,
        saveLastHost: (host) async {
          saved.add(host);
          last = host;
        },
        maxNetworks: maxNetworks,
      );
}

const _home = '192.168.100.8'; // the computer on the home Wi-Fi: what the build was made for
const _hotspot = '10.221.34.228'; // the same computer after it joined another Wi-Fi

const _config = AppConfig(
  apiUrl: 'http://$_home:8000',
  agentsUrl: 'http://$_home:8100',
  useEmulators: true,
  firebaseApiKey: 'key',
  firebaseAppId: 'app',
  firebaseProjectId: 'project',
  firebaseMessagingSenderId: 'sender',
  findTestServer: true,
  testServerHosts: [_hotspot],
);

void main() {
  group('addresses', () {
    test('only home, office and hotspot networks count as private', () {
      for (final address in ['10.221.34.228', '172.16.0.1', '172.31.255.254', '192.168.100.8']) {
        expect(isPrivateIPv4(address), isTrue, reason: address);
      }
      for (final address in ['172.32.0.1', '8.8.8.8', '192.169.1.1', 'localhost', '999.1.1.1', '10.1.1', '']) {
        expect(isPrivateIPv4(address), isFalse, reason: address);
      }
    });

    test('an address belongs to the network of its first three numbers', () {
      expect(networkOf('192.168.100.8'), '192.168.100');
    });

    test('the address is picked out of what a tester types or pastes', () {
      expect(cleanHost('192.168.100.8'), '192.168.100.8');
      expect(cleanHost('  192.168.100.8 '), '192.168.100.8');
      expect(cleanHost('http://192.168.100.8:8090/'), '192.168.100.8');
      expect(cleanHost('192.168.100.8:8000'), '192.168.100.8');
      expect(cleanHost('192.168.100'), isNull);
      expect(cleanHost('192.168.100.800'), isNull);
      expect(cleanHost('my computer'), isNull);
      expect(cleanHost(''), isNull);
    });
  });

  group('finding the test server', () {
    test('an address the build knows is used at once, without searching the Wi-Fi', () async {
      final wifi = _Wifi(gudMeal: {_home}, own: ['192.168.100.3']);
      expect(await wifi.finder([_home, _hotspot]).find(), _home);
      expect(wifi.knocked, isEmpty);
      expect(wifi.saved, [_home]);
    });

    test('the address that worked last time comes before the ones the build was made with', () async {
      final wifi = _Wifi(gudMeal: {_home, _hotspot}, last: _hotspot);
      expect(await wifi.finder([_home]).find(), _hotspot);
    });

    test('after the computer joined another Wi-Fi it is found on the phone\'s own network', () async {
      final wifi = _Wifi(gudMeal: {_hotspot}, own: ['10.221.34.7']);
      expect(await wifi.finder([_home]).find(), _hotspot);
      expect(wifi.knocked, containsAll(['10.221.34.1', '10.221.34.254']));
      expect(wifi.knocked, isNot(contains('10.221.34.7')), reason: 'the phone does not ask itself');
      expect(wifi.knocked, isNot(contains('10.221.34.0')));
      expect(wifi.knocked, isNot(contains('10.221.34.255')));
      expect(wifi.saved, [_hotspot]);
    });

    test('something else on the same port is not mistaken for Yummy Chops', () async {
      final wifi = _Wifi(gudMeal: {_hotspot}, other: {'10.221.34.5'}, own: ['10.221.34.7']);
      expect(await wifi.finder([_home]).find(), _hotspot);
      expect(wifi.asked, contains('10.221.34.5'));
    });

    test('a new address on the same Wi-Fi is found even when the phone reports no addresses of its own', () async {
      final wifi = _Wifi(gudMeal: {'192.168.100.23'});
      expect(await wifi.finder([_home]).find(), '192.168.100.23');
    });

    test('nothing found gives null, and only private networks are searched', () async {
      final wifi = _Wifi(own: ['8.8.4.4', '192.168.1.10']);
      expect(await wifi.finder([_home, 'my-computer.local']).find(), isNull);
      expect(wifi.knocked.where((host) => host.startsWith('8.8.4.')), isEmpty);
      expect(wifi.knocked.map(networkOf).toSet(), {'192.168.1', '192.168.100'});
      expect(wifi.saved, isEmpty);
    });

    test('the phone\'s own networks are searched first, and only a few networks in all', () async {
      final wifi = _Wifi(own: ['192.168.1.10', '10.0.0.4']);
      final networks = <String>[];
      expect(await wifi.finder([_home, _hotspot], maxNetworks: 3).find(onNetwork: networks.add), isNull);
      expect(networks, ['192.168.1', '10.0.0', '192.168.100']);
    });

    test('a typed address is accepted only when Yummy Chops answers there', () async {
      final wifi = _Wifi(gudMeal: {_home});
      final finder = wifi.finder([]);
      expect(await finder.tryTyped('http://$_home:8090/'), _home);
      expect(wifi.saved, [_home]);
      expect(await finder.tryTyped('192.168.100.9'), isNull);
      wifi.asked.clear();
      expect(await finder.tryTyped('the computer'), isNull);
      expect(wifi.asked, isEmpty, reason: 'nothing is asked when no address was typed');
    });

    test('a broken memory of the last address does not stop the search', () async {
      final finder = TestServerFinder(
        knownHosts: [_home],
        isGudMeal: (host) async => host == _home,
        portOpen: (host) async => false,
        localAddresses: () async => throw StateError('no interfaces'),
        loadLastHost: () async => throw StateError('disk'),
        saveLastHost: (host) async => throw StateError('disk'),
      );
      expect(await finder.find(), _home);
    });

    test('a check that fails counts as no answer', () async {
      final finder = TestServerFinder(
        knownHosts: ['192.168.100.9', _home],
        isGudMeal: (host) async => host == _home ? true : throw StateError('odd address'),
        portOpen: (host) async => throw StateError('odd address'),
        localAddresses: () async => const [],
        loadLastHost: () async => null,
        saveLastHost: (host) async {},
      );
      expect(await finder.find(), _home);
      expect(await finder.answersOn('192.168.100.9'), isFalse);
    });
  });

  group('settings', () {
    test('every local service moves to the address where the computer was found', () {
      final moved = _config.onHost(_hotspot);
      expect(moved.apiUrl, 'http://$_hotspot:8000');
      expect(moved.agentsUrl, 'http://$_hotspot:8100');
      expect(moved.emulatorHost, _hotspot);
      expect(moved.emulatorPort, 9099); // the emulator's own port on the computer that was found
      expect(_config.emulatorPort, 9099); // no AUTH_EMULATOR_PORT in this build
      expect(moved.serverHost, _hotspot);
      expect(moved.findTestServer, isTrue);
      expect(moved.testServerHosts, [_hotspot]);
      expect(_config.serverHost, _home);
    });

    test('a list of addresses is read from one build setting', () {
      expect(AppConfig.splitHosts('192.168.100.8+10.221.34.228'), ['192.168.100.8', '10.221.34.228']);
      expect(AppConfig.splitHosts('192.168.100.8, 10.221.34.228;10.0.0.2'), ['192.168.100.8', '10.221.34.228', '10.0.0.2']);
      expect(AppConfig.splitHosts(''), isEmpty);
    });

    test('an ordinary build never looks for a test server', () {
      final config = AppConfig.fromEnvironment();
      expect(config.findTestServer, isFalse);
      expect(config.testServerHosts, isEmpty);
    });

    test('the sign-in emulator is the default in a debug run only', () {
      // Tests run in debug mode, like `flutter run`. In a release build `kDebugMode` is false: the emulator is
      // then used only when the build asks for it (USE_FIREBASE_EMULATORS=true), never by forgetting a setting.
      expect(AppConfig.fromEnvironment().useEmulators, kDebugMode);
    });
  });

  group('the search screen', () {
    Future<List<String>> show(WidgetTester tester, _Wifi wifi) async {
      final found = <String>[];
      await tester.pumpWidget(TestServerSearch(
        appName: 'Yummy Chops',
        finder: wifi.finder([_home]),
        fallbackHost: _home,
        onFound: found.add,
      ));
      await tester.pump();
      await tester.pump();
      return found;
    }

    testWidgets('says what to do when the server is not found, and finds it on a second try', (tester) async {
      final wifi = _Wifi(own: ['10.221.34.7']);
      final found = await show(tester, wifi);
      expect(find.text("Can't find the test server"), findsOneWidget);
      expect(found, isEmpty);

      wifi.gudMeal = {_hotspot}; // the phone has joined the computer's Wi-Fi
      await tester.tap(find.byKey(const Key('test-server-retry')));
      await tester.pump();
      await tester.pump();
      expect(found, [_hotspot]);
    });

    testWidgets('takes a typed address when Yummy Chops answers there', (tester) async {
      final wifi = _Wifi(gudMeal: {'172.20.10.4'}, own: ['192.168.1.10']);
      final found = await show(tester, wifi);
      await tester.enterText(find.byKey(const Key('test-server-address')), 'not an address');
      await tester.tap(find.byKey(const Key('test-server-use-address')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Type an address like 192.168.100.8'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('test-server-address')), '172.20.10.9');
      await tester.tap(find.byKey(const Key('test-server-use-address')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Yummy Chops did not answer at that address'), findsOneWidget);
      expect(found, isEmpty);

      await tester.enterText(find.byKey(const Key('test-server-address')), '172.20.10.4');
      await tester.tap(find.byKey(const Key('test-server-use-address')));
      await tester.pump();
      await tester.pump();
      expect(found, ['172.20.10.4']);
    });

    testWidgets('the app can be opened without a server', (tester) async {
      final found = await show(tester, _Wifi());
      await tester.ensureVisible(find.byKey(const Key('test-server-skip')));
      await tester.tap(find.byKey(const Key('test-server-skip')));
      expect(found, [_home]);
    });
  });

  group('while the app is open', () {
    var closed = 0;

    Future<void> open(WidgetTester tester, _Wifi wifi) async {
      closed = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TestServerWatch(
          config: _config,
          finder: wifi.finder([_home, _hotspot]),
          onClose: () => closed++,
          patience: const Duration(milliseconds: 10),
          child: child!,
        ),
        home: const Scaffold(body: Text('the app')),
      ));
    }

    /// The tester comes back to the app: three attempts, a short wait apart.
    Future<void> comeBack(WidgetTester tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    testWidgets('nothing is shown while the server answers', (tester) async {
      await open(tester, _Wifi(gudMeal: {_home}));
      await comeBack(tester);
      expect(find.text("Can't reach the test server"), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('a server that moved to another Wi-Fi is found, and the app asks to be reopened', (tester) async {
      final wifi = _Wifi(own: ['10.221.34.7']);
      await open(tester, wifi);
      await comeBack(tester);
      expect(find.text("Can't reach the test server"), findsOneWidget);

      wifi.gudMeal = {_hotspot};
      await tester.tap(find.byKey(const Key('test-server-look')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Found the computer at a new address'), findsOneWidget);
      expect(find.textContaining(_hotspot), findsOneWidget);
      expect(wifi.saved, [_hotspot], reason: 'the next start goes straight to the new address');

      await tester.tap(find.byKey(const Key('test-server-close-app')));
      expect(closed, 1);
    });

    testWidgets('a server that comes back where it was lets the tester carry on', (tester) async {
      final wifi = _Wifi();
      await open(tester, wifi);
      await comeBack(tester);
      wifi.gudMeal = {_home}; // the computer woke up
      await tester.tap(find.byKey(const Key('test-server-look')));
      await tester.pump();
      await tester.pump();
      expect(find.text("Can't reach the test server"), findsNothing);
      expect(find.text('Found the computer at a new address'), findsNothing);
      expect(closed, 0);
    });

    testWidgets('a server that stays away can be looked for again or left for later', (tester) async {
      await open(tester, _Wifi());
      await comeBack(tester);
      await tester.tap(find.byKey(const Key('test-server-look')));
      await tester.pump();
      await tester.pump();
      expect(find.text("Still can't find it"), findsOneWidget);
      expect(find.text('Look again'), findsOneWidget);

      await tester.tap(find.byKey(const Key('test-server-not-now')));
      await tester.pump();
      expect(find.text("Still can't find it"), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('an ordinary build is left exactly as it is', (tester) async {
      const app = Text('the app', textDirection: TextDirection.ltr);
      const ordinary = AppConfig(
        apiUrl: 'https://api.example.com',
        agentsUrl: 'https://agents.example.com',
        useEmulators: false,
        firebaseApiKey: 'key',
        firebaseAppId: 'app',
        firebaseProjectId: 'project',
        firebaseMessagingSenderId: 'sender',
      );
      expect(TestServerWatch.wrap(ordinary, app), same(app));
      expect(TestServerWatch.wrap(_config, app), isA<TestServerWatch>());
    });
  });
}
