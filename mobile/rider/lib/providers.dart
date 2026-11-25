import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

final configProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('override in main'));
final authStateProvider = StreamProvider<GmUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Who is signed in (null for nobody). Until the first sign-in news arrives, it is who the app already knows.
final signedInUidProvider = Provider<String?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ref.watch(authStateProvider.select((state) => state.hasValue ? state.value?.uid : auth.currentUser?.uid));
});

final apiProvider = Provider<GudMealApi>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  // A new client for each rider: everything read through it (profile, earnings, KYC...) is fetched again for them,
  // and the location reporter built on it stops. When a rider leaves, `PerUserScope` in main() also throws away
  // what was kept in memory.
  ref.watch(signedInUidProvider);
  return GudMealApi(baseUrl: ref.watch(configProvider).apiUrl, token: auth.idToken);
});

/// Location port: Geolocator on devices, a fixed spot in browser test builds, a fake in tests.
abstract class LocationSource {
  Future<bool> ensurePermission();
  Stream<(GeoPoint, double)> positions();

  /// One position right now, or null if none can be had quickly.
  Future<(GeoPoint, double)?> current();
}

/// How the rider's position is followed while they are online. Battery-aware: an update when the rider moves 25 m
/// (the API rate-limits pings too). The stream runs only while the rider is online, so tracking keeps going when
/// Google Maps is in front and stops the moment they go offline or sign out:
/// - Android: a foreground service with an ongoing notification for as long as the rider is online;
/// - iOS: background location updates (the blue location bar shows while they run).
LocationSettings onlineLocationSettings(TargetPlatform platform) {
  const accuracy = LocationAccuracy.high;
  const distanceFilter = 25;
  switch (platform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "You're online for deliveries",
          notificationText: 'Yummy Chops shares your location for jobs until you go offline.',
          notificationChannelName: 'Online for deliveries',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    case TargetPlatform.iOS:
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    default:
      return const LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
  }
}

class GeolocatorSource implements LocationSource {
  @override
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Stream<(GeoPoint, double)> positions() => Geolocator.getPositionStream(
        locationSettings: onlineLocationSettings(defaultTargetPlatform),
      ).map((p) => (GeoPoint(lat: p.latitude, lng: p.longitude), p.accuracy));

  @override
  Future<(GeoPoint, double)?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return (GeoPoint(lat: p.latitude, lng: p.longitude), p.accuracy);
    } catch (_) {
      return null; // no fix in time: the heartbeat re-sends the last known position instead
    }
  }
}

/// Browser test builds have no GPS: `--dart-define=RIDER_TEST_LOCATION=6.4478,3.4723` pins the rider there.
class FixedLocationSource implements LocationSource {
  FixedLocationSource(this.point);
  factory FixedLocationSource.parse(String latLng) {
    final parts = latLng.split(',').map((s) => double.parse(s.trim())).toList();
    return FixedLocationSource(GeoPoint(lat: parts[0], lng: parts[1]));
  }
  final GeoPoint point;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Stream<(GeoPoint, double)> positions() => Stream.value((point, 10.0));

  @override
  Future<(GeoPoint, double)?> current() async => (point, 10.0);
}

final locationSourceProvider = Provider<LocationSource>((ref) {
  const testLocation = String.fromEnvironment('RIDER_TEST_LOCATION');
  return testLocation.isNotEmpty ? FixedLocationSource.parse(testLocation) : GeolocatorSource();
});

final riderProfileProvider = FutureProvider<RiderProfile>((ref) => ref.watch(apiProvider).riderProfile());
final offersProvider = FutureProvider<List<DeliveryOffer>>((ref) => ref.watch(apiProvider).offers());
final activeDeliveriesProvider = FutureProvider<List<Order>>((ref) => ref.watch(apiProvider).activeDeliveries());
final earningsProvider = FutureProvider<Earnings>((ref) => ref.watch(apiProvider).earnings());

/// Streams the rider's GPS position to the API while online. Poor connectivity: failed pings are dropped
/// (the next position supersedes them) rather than queued, so the server never receives stale bursts.
/// The API refuses positions from offline riders (409); the reporter then stops sharing.
///
/// Riders often wait in one place, and the position stream only fires after 25 m of movement, so the reporter
/// also sends the current (or last known) position every [heartbeat]: dispatch only offers jobs to riders it has
/// heard from in the last 3 minutes (found on a phone test: a rider waiting online never got an offer).
class LocationReporter {
  LocationReporter(this._api, this._source, {this.heartbeat = const Duration(seconds: 60)});
  final GudMealApi _api;
  final LocationSource _source;
  final Duration heartbeat;
  StreamSubscription<(GeoPoint, double)>? _sub;
  Timer? _beat;
  GeoPoint? last;
  double? _accuracy;

  /// When the API last accepted a position (shown on the dashboard).
  DateTime? lastSentAt;

  bool get active => _sub != null;

  /// True when the server said this rider is offline and sharing stopped.
  bool stoppedByServer = false;

  Future<bool> ensurePermission() => _source.ensurePermission();

  Future<bool> start() async {
    if (_sub != null) return true;
    if (!await _source.ensurePermission()) return false;
    stoppedByServer = false;
    _sub = _source.positions().listen((event) => _send(event.$1, event.$2));
    _beat = Timer.periodic(heartbeat, (_) => _heartbeat());
    unawaited(_heartbeat()); // share the position as soon as the rider goes online
    return true;
  }

  Future<void> _heartbeat() async {
    if (!active) return;
    final sent = lastSentAt;
    if (sent != null && DateTime.now().difference(sent) < heartbeat ~/ 2) return; // a movement ping just went
    final fix = await _source.current();
    if (!active) return;
    if (fix != null) {
      await _send(fix.$1, fix.$2);
    } else if (last != null) {
      await _send(last!, _accuracy);
    }
  }

  Future<void> _send(GeoPoint point, double? accuracy) async {
    last = point;
    _accuracy = accuracy;
    try {
      await _api.sendLocation(point, accuracyM: accuracy);
      lastSentAt = DateTime.now();
    } on ApiException catch (e) {
      if (e.status == 409) {
        stoppedByServer = true;
        await stop();
      }
      // Otherwise offline or rate limited: skip this ping.
    } catch (_) {
      // Skip this ping.
    }
  }

  Future<void> stop() async {
    _beat?.cancel();
    _beat = null;
    await _sub?.cancel();
    _sub = null;
  }
}

final locationReporterProvider = Provider<LocationReporter>((ref) {
  final reporter = LocationReporter(ref.watch(apiProvider), ref.watch(locationSourceProvider));
  ref.onDispose(reporter.stop);
  return reporter;
});

/// Goes online or offline in the order the API needs: online first, then share positions; stop sharing first,
/// then go offline. Returns a message to show, or null on success.
Future<String?> setRiderOnline(GudMealApi api, LocationReporter reporter, bool online) async {
  try {
    if (online) {
      if (!await reporter.ensurePermission()) return 'Location permission is required to go online.';
      await api.setOnline(true);
      await reporter.start();
    } else {
      await reporter.stop();
      await api.setOnline(false);
    }
    return null;
  } on ApiException catch (e) {
    await reporter.stop();
    return e.message;
  }
}
