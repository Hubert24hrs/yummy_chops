import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// The provider's payment page (Paystack). It opens inside the app, so the app can close it by itself as soon as the
/// payment is confirmed: card data never touches the app.
class PaymentPage {
  const PaymentPage();
  Future<void> open(Uri url) => launchUrl(url, mode: LaunchMode.inAppWebView);
  Future<void> close() => closeInAppWebView();
}

final paymentPageProvider = Provider<PaymentPage>((ref) => const PaymentPage());

/// How often the app asks whether a payment went through while its page is open, and for how long.
typedef PaymentWatchTiming = ({Duration every, Duration giveUpAfter});

final paymentWatchTimingProvider = Provider<PaymentWatchTiming>((ref) => (every: const Duration(seconds: 2), giveUpAfter: const Duration(minutes: 10)));

/// What the server said about a payment (`POST /v1/payments/verify`).
enum PaymentCheck {
  /// Paid: the order(s) go ahead.
  succeeded,

  /// Refused by the bank or the provider, or money came in that does not match (flagged): this payment is over.
  failed,

  /// Not finished yet. Paystack also calls a page that is still open "abandoned", so this only means something once
  /// the customer has left the page.
  notFinished,

  /// Still being processed, or the check itself did not work (no connection): ask again.
  pending;

  static PaymentCheck of(String status) => switch (status) {
        'succeeded' => succeeded,
        'failed' || 'flagged' => failed,
        'abandoned' => notFinished,
        _ => pending,
      };
}

/// Asks the server about one payment every [every] while its page is open (Paystack's webhook may not reach the
/// server, so nothing else would tell it), until it is settled, [giveUpAfter] has passed, or [stop] is called.
/// [onSettled] is called once, with [PaymentCheck.succeeded] or [PaymentCheck.failed].
class PaymentWatcher {
  PaymentWatcher({required this.verify, required this.onSettled, required PaymentWatchTiming timing})
      : every = timing.every,
        giveUpAfter = timing.giveUpAfter;

  final Future<String> Function() verify;
  final void Function(PaymentCheck result) onSettled;
  final Duration every;
  final Duration giveUpAfter;

  Timer? _timer;
  int _ticks = 0;
  bool _asking = false;
  bool _settled = false;

  bool get settled => _settled;
  bool get watching => _timer != null;

  /// Starts asking (the first time after [every]: the page has only just opened).
  void start() {
    if (_settled) return;
    _timer?.cancel();
    _ticks = 0;
    final maxTicks = (giveUpAfter.inMilliseconds / every.inMilliseconds).ceil();
    _timer = Timer.periodic(every, (_) {
      if (++_ticks > maxTicks) {
        stop();
        return;
      }
      unawaited(check());
    });
  }

  /// Asks once now (the app came back to the front, for example) and returns what the server said, or null when a
  /// question is already on its way or the payment is settled.
  Future<PaymentCheck?> check() async {
    if (_settled || _asking) return null;
    _asking = true;
    PaymentCheck result;
    try {
      result = PaymentCheck.of(await verify());
    } catch (_) {
      result = PaymentCheck.pending; // no answer: nothing is known, ask again next time
    } finally {
      _asking = false;
    }
    if (_settled) return null;
    if (result == PaymentCheck.succeeded || result == PaymentCheck.failed) {
      _settled = true;
      stop();
      onSettled(result);
    }
    return result;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
