import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/gm_map.dart';
import '../../ui/payment_picker.dart';
import '../../widgets.dart';

const _live = {
  'pending_payment', 'paid', 'submitted_to_restaurant', 'restaurant_accepted', 'preparing', 'ready_for_pickup',
  'rider_assigned', 'picked_up', 'in_transit', 'delivered', 'refund_pending',
};
const _steps = ['Placed', 'Accepted', 'Preparing', 'On the way', 'Delivered'];

/// A rider is on this delivery: the only time the API shares their position.
const _onDelivery = {'rider_assigned', 'picked_up', 'in_transit'};

/// Live order tracking. Polls the API every 5 s while the order is active (Firestore listener in production).
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.id, this.paymentReference, this.justPaid = false});
  final String id;

  /// Set when returning from checkout; used to re-verify the payment server-side on resume.
  final String? paymentReference;

  /// Opened straight after paying from the wallet: the receipt printer comes up once (ADR-0019).
  final bool justPaid;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> with WidgetsBindingObserver {
  Timer? _timer;
  // A payment started from this screen (the payment page was closed before paying the first time).
  String? _payReference;
  bool _paying = false;
  String? _payError;
  // The receipt printer opens by itself once, right after this customer paid (not when an old order is opened).
  bool _receiptOffered = false;

  bool _paidHere = false;

  // One key per method until the server answers: a second tap after a lost connection is not a second payment.
  final _payKeys = <PayMethod, IdempotencyKey>{};
  bool _cancelling = false;
  String? _cancelError;

  bool get _cameFromPaying => widget.justPaid || _paidHere || widget.paymentReference != null || _payReference != null;

  void _offerReceipt(Order? o) {
    if (o == null || _receiptOffered || !_cameFromPaying || o.payment.status != 'paid' || !mounted) return;
    _receiptOffered = true;
    context.push('/orders/${o.id}/receipt');
  }

  Future<void> _pay(Order o, PayMethod method) async {
    setState(() {
      _paying = true;
      _payError = null;
    });
    try {
      // The server resumes the pending card payment (same page) or pays from the wallet straight away.
      final api = ref.read(apiProvider);
      final checkout = await _payKeys
          .putIfAbsent(method, () => IdempotencyKey('checkout'))
          .send(o.id, (key) => api.checkout(o.id, key, provider: method.provider));
      ref.invalidate(walletProvider);
      final url = checkout.authorizationUrl;
      if (url != null) {
        _payReference = checkout.reference;
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      } else if (checkout.provider == 'wallet') {
        _paidHere = true; // paid on the spot: the receipt printer comes up
      }
      ref.invalidate(orderProvider(o.id));
    } on ApiException catch (e) {
      if (mounted) setState(() => _payError = e.message);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// Cancelling cannot be undone, so the customer is asked first; when the order can no longer be cancelled, the
  /// reason is shown.
  Future<void> _cancel(Order o) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Text('Order #${o.shortCode} will be cancelled. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep my order')),
          FilledButton(
            key: const ValueKey('confirm-cancel-order'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() {
      _cancelling = true;
      _cancelError = null;
    });
    try {
      await ref.read(apiProvider).cancel(o.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _cancelError = e.message);
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
        ref.invalidate(orderProvider(o.id));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final status = ref.read(orderProvider(widget.id)).value?.status;
      if (status == null || _live.contains(status)) ref.invalidate(orderProvider(widget.id));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the payment page: ask the server to verify with the provider (never trust the redirect).
    final reference = _payReference ?? widget.paymentReference;
    if (state == AppLifecycleState.resumed && reference != null) {
      ref.read(apiProvider).verifyPayment(reference).whenComplete(() => ref.invalidate(orderProvider(widget.id)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.id));
    ref.listen(orderProvider(widget.id), (_, next) => _offerReceipt(next.value));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(orderProvider(widget.id))),
        data: (o) {
          final step = o.progress?.step ?? 0;
          final parcel = o.vertical == 'parcel' ? o.parcel : null;
          final steps = switch (o.vertical) {
            'parcel' => const ['Booked', 'Rider found', 'Heading to pickup', 'On the way', 'Delivered'],
            'beauty' || 'grocery' || 'pharmacy' || 'market' => serviceCopy(o.vertical).steps,
            'waybill' => (o.progress?.steps.isNotEmpty ?? false)
                ? o.progress!.steps
                : const ['Booked', 'At the hub', 'On the way', 'Arrived', 'Delivered'],
            _ => _steps,
          };
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text(o.progress?.label ?? statusLabel(o.status), style: theme.textTheme.headlineSmall)),
              StatusChip(o.status, label: o.vertical == 'parcel' ? o.progress?.label : null),
            ]),
            Text('#${o.shortCode} · ${o.restaurantName}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (step >= 0)
              Row(children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: Column(children: [
                      Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i < step ? theme.colorScheme.secondary : i == step ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i], style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
                    ]),
                  ),
              ]),
            if (_onDelivery.contains(o.status)) ...[
              const SizedBox(height: 16),
              LiveDeliveryMap(orderId: o.id, kitchenName: o.restaurantName, parcel: o.vertical == 'parcel'),
            ],
            if (o.estimatedDeliveryAt != null && step < 5)
              Padding(padding: const EdgeInsets.only(top: 12), child: Text('Estimated arrival: ${formatLagosTime(o.estimatedDeliveryAt)}')),
            if (['draft', 'pending_payment'].contains(o.status) && o.payment.status != 'paid')
              Card(
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Finish paying ${formatNaira(o.breakdown?.totalKobo)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Text('Your order goes ahead as soon as it is paid.'),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _paying ? null : () => _pay(o, PayMethod.card),
                      child: const Text('Pay by card, transfer or USSD'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _paying ? null : () => _pay(o, PayMethod.wallet),
                      child: const Text('Pay from my Yummy Chops wallet'),
                    ),
                    if (_payError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_payError!, style: TextStyle(color: theme.colorScheme.error)),
                      ),
                  ]),
                ),
              ),
            if (o.payment.provider == 'cash' && o.payment.status != 'paid' && !['cancelled', 'draft', 'pending_payment'].contains(o.status))
              Card(
                color: theme.colorScheme.secondaryContainer,
                margin: const EdgeInsets.only(top: 12),
                child: ListTile(
                  leading: const Icon(Icons.payments_rounded),
                  title: Text('Pay ${formatNaira(o.breakdown?.totalKobo)} in cash when it arrives',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Have the exact amount ready if you can. Share your delivery code after you pay.'),
                ),
              ),
            if (o.riderName != null)
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delivery_dining_rounded), title: Text(o.riderName!), subtitle: const Text('Your rider')),
            if (o.waybill != null && o.waybill!.trackingCode != null && !['draft', 'pending_payment'].contains(o.status))
              _WaybillHistory(details: o.waybill!),
            if (o.waybill != null ? ['paid', 'in_transit'].contains(o.status) : step >= 1 && step < 5)
              _DeliveryCode(
                orderId: o.id,
                recipient: parcel?.dropoff.name ?? o.waybill?.recipient.name,
                collectAt: o.waybill?.lastMile == 'collect' ? o.waybill!.destinationHubName : null,
              ),
            if (parcel != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${parcel.size[0].toUpperCase()}${parcel.size.substring(1)} package · ${parcel.category}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (parcel.description.isNotEmpty) Text(parcel.description),
                    const SizedBox(height: 10),
                    _Stop(icon: Icons.trip_origin_rounded, title: 'Pickup', stop: parcel.pickup),
                    const SizedBox(height: 8),
                    _Stop(icon: Icons.location_on_rounded, title: 'Drop-off', stop: parcel.dropoff),
                    if ((parcel.codAmountKobo ?? 0) > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        o.cashCollectedAt != null
                            ? 'Collected ${formatNaira(parcel.codAmountKobo)} from ${parcel.dropoff.name}: it is in your wallet as cash-on-delivery money.'
                            : 'The rider collects ${formatNaira(parcel.codAmountKobo)} from ${parcel.dropoff.name} for you.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
            const Divider(height: 32),
            for (final ln in o.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [Expanded(child: Text('${ln.quantity} × ${ln.name}')), Text(formatNaira(ln.lineTotalKobo))]),
              ),
            const Divider(),
            Row(children: [
              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
              Text(formatNaira(o.breakdown?.totalKobo), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            if (o.payment.provider == 'wallet' && o.payment.status != 'unpaid')
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Paid from your Yummy Chops wallet')),
            if (o.payment.provider == 'cash' && o.payment.status == 'paid')
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Paid in cash on delivery')),
            if (const ['paid', 'partially_refunded', 'refunded'].contains(o.payment.status))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/orders/${o.id}/receipt'),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print my receipt'),
                ),
              ),
            if (o.refundTotalKobo > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Refunded ${formatNaira(o.refundTotalKobo)}${['wallet', 'cash'].contains(o.payment.provider) ? ' to your wallet' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (['draft', 'pending_payment', 'submitted_to_restaurant'].contains(o.status) ||
                (parcel != null && ['paid', 'ready_for_pickup'].contains(o.status)) ||
                (o.waybill != null && o.status == 'paid' && [null, 'awaiting_dropoff', 'pickup_scheduled'].contains(o.waybill!.stage)))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: _cancelling ? null : () => _cancel(o),
                  child: const Text('Cancel order'),
                ),
              ),
            if (_cancelError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_cancelError!, style: TextStyle(color: theme.colorScheme.error)),
              ),
          ]);
        },
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.title, required this.stop});
  final IconData icon;
  final String title;
  final ParcelStop stop;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            Text('${stop.name} · ${stop.phone}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text([stop.line1, stop.area, stop.city].whereType<String>().join(', ')),
          ]),
        ),
      ]);
}

class _DeliveryCode extends ConsumerWidget {
  const _DeliveryCode({required this.orderId, this.recipient, this.collectAt});
  final String orderId;

  /// For packages: who receives it (they must give the rider this code).
  final String? recipient;

  /// Waybills collected at a hub: the recipient shows the collection code there.
  final String? collectAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiProvider);
    return FutureBuilder<String?>(
      future: collectAt == null ? api.deliveryCode(orderId) : api.pickupCode(orderId),
      builder: (context, snap) => snap.data == null
          ? const SizedBox.shrink()
          : Card(
              child: ListTile(
                leading: const Icon(Icons.key_rounded),
                title: Text('${collectAt == null ? 'Delivery' : 'Collection'} code: ${snap.data}',
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
                subtitle: Text(recipient == null
                    ? 'Share it only when you have your order.'
                    : collectAt != null
                        ? 'Send this code to $recipient. They show it at $collectAt to collect the package.'
                        : 'Send this code to $recipient. The rider needs it to complete the delivery.'),
              ),
            ),
    );
  }
}

/// The customer's live delivery map: kitchen (or pickup), their address and the rider, refreshed every 10 s.
class LiveDeliveryMap extends ConsumerStatefulWidget {
  const LiveDeliveryMap({super.key, required this.orderId, required this.kitchenName, this.parcel = false, this.interval = const Duration(seconds: 10)});
  final String orderId;
  final String kitchenName;
  final bool parcel;
  final Duration interval;

  @override
  ConsumerState<LiveDeliveryMap> createState() => _LiveDeliveryMapState();
}

class _LiveDeliveryMapState extends ConsumerState<LiveDeliveryMap> {
  LiveTracking? _t;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(widget.interval, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await ref.read(apiProvider).liveTracking(widget.orderId);
      if (!mounted) return;
      setState(() => _t = t);
      if (!_onDelivery.contains(t.status)) _timer?.cancel();
    } on ApiException {
      // Keep the last good map; the next refresh tries again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = _t;
    if (t == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    final pins = [
      if (t.pickupLocation != null) MapPin(t.pickupLocation!, PinKind.kitchen, label: widget.parcel ? 'Pickup' : widget.kitchenName),
      if (t.dropoffLocation != null) MapPin(t.dropoffLocation!, PinKind.home, label: widget.parcel ? 'Drop-off' : 'You'),
      if (t.riderLocation != null) MapPin(t.riderLocation!, PinKind.rider, label: t.riderName ?? 'Rider'),
    ];
    final eta = t.etaMinutes;
    final where = t.toPickup ? (widget.parcel ? 'heading to the pickup' : 'heading to ${widget.kitchenName}') : 'on the way to you';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GmMap(pins: pins, route: t.route, height: 230),
      const SizedBox(height: 8),
      Row(children: [
        Icon(Icons.delivery_dining_rounded, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t.isLive
                ? '${t.riderName ?? 'Your rider'} is $where${eta == null ? '' : ' · about $eta min'}'
                : "Waiting for the rider's location…",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ]),
      if (t.isLive && eta != null)
        Text(
          isMeasured(t.etaSource) ? 'Arrival time from live traffic.' : 'Arrival time is an estimate.',
          style: theme.textTheme.bodySmall,
        ),
    ]);
  }
}

final waybillTrackingProvider =
    FutureProvider.family<WaybillTracking, String>((ref, code) => ref.watch(apiProvider).trackWaybill(code));

/// Waybill tracking number, expected dates and scan history (labels come from the public tracking endpoint).
class _WaybillHistory extends ConsumerWidget {
  const _WaybillHistory({required this.details});
  final WaybillDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracking = ref.watch(waybillTrackingProvider(details.trackingCode!));
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_shipping_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${details.originCityName} → ${details.destinationCityName}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            SelectableText(details.trackingCode!, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
          if (tracking.value case final t?) ...[
            if (!t.delivered) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Expected ${t.etaText}')),
            const SizedBox(height: 8),
            for (final m in t.milestones.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.circle, size: 10, color: m == t.milestones.last ? theme.colorScheme.primary : theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${m.label} · ${formatLagosDateTime(m.at)}${m.place == null ? '' : ' · ${m.place}'}'),
                  ),
                ]),
              ),
          ],
          if (details.lastMile == 'collect')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Collection: ${details.destinationHubName}, ${details.destinationHubAddress}', style: theme.textTheme.bodySmall),
            ),
        ]),
      ),
    );
  }
}
