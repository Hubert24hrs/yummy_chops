import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gud_meal_rider/providers.dart';

void main() {
  test('on Android an online rider is followed through an ongoing notification', () {
    final settings = onlineLocationSettings(TargetPlatform.android) as AndroidSettings;
    final notice = settings.foregroundNotificationConfig!;
    expect(notice.setOngoing, isTrue);
    expect(notice.notificationTitle, contains('online'));
    expect(settings.distanceFilter, 25);
  });

  test('on iPhones background updates show the location bar', () {
    final settings = onlineLocationSettings(TargetPlatform.iOS) as AppleSettings;
    expect(settings.allowBackgroundLocationUpdates, isTrue);
    expect(settings.showBackgroundLocationIndicator, isTrue);
    expect(settings.pauseLocationUpdatesAutomatically, isFalse);
  });

  test('elsewhere (browser test builds) plain settings', () {
    final settings = onlineLocationSettings(TargetPlatform.windows);
    expect(settings, isNot(isA<AndroidSettings>()));
    expect(settings.distanceFilter, 25);
  });
}
