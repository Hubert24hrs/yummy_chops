import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../providers.dart';
import 'delivery_screen.dart';

/// Which trip a screen shows: by its id (from the dashboard) or by one of its orders (after accepting an offer, or
/// an old `/deliveries/{order_id}` link).
typedef TripKey = ({String? tripId, String? orderId});

/// What the trip screen needs: the planned trip and the rider's active orders (cash, address details, status).
class TripView {
  const TripView(this.trip, this.orders);
  final RiderTrip? trip;
  final Map<String, Order> orders;
}

/// Packages and interstate legs keep their own screen (sender, recipient, hub handover).
bool isParcelJob(Order o) =>
    o.vertical == 'parcel' || o.vertical == 'waybill' || o.parcel != null || o.waybill != null || o.legKind != null;

RiderTrip? findTrip(List<RiderTrip> trips, TripKey key) {
  for (final t in trips) {
    if (key.tripId != null && t.tripId == key.tripId) return t;
    if (key.orderId != null && (t.tripId == key.orderId || t.orderIds.contains(key.orderId))) return t;
  }
  return null;
}

final tripViewProvider = FutureProvider.family<TripView, TripKey>((ref, key) async {
  final api = ref.watch(apiProvider);
  final active = api.activeDeliveries();
  List<RiderTrip> trips;
  try {
    trips = await api.riderTrips();
  } on ApiException catch (e) {
    if (e.status != 404) rethrow;
    trips = const []; // a server without trips yet: the order keeps its old screen
  }
  final orders = {for (final o in await active) o.id: o};
  return TripView(findTrip(trips, key), orders);
});

/// What kind of place a pickup is, from the order's vertical.
String placeKind(String? vertical) => switch (vertical) {
      'food' => 'Restaurant',
      'pharmacy' => 'Pharmacy',
      'grocery' || 'store' => 'Store',
      'market' => 'Market',
      'beauty' => 'Beauty',
      _ => 'Shop',
    };

String _legText(double? km, int? minutes) => [
      if (km != null) '${km.toStringAsFixed(1)} km',
      if (minutes != null) '$minutes min',
    ].join(' · ');

/// The rider's trip: every shop to collect from in the planned (fastest) order, then the customer. A trip of one
/// order is a normal delivery. Package and interstate jobs open the delivery screen instead.
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key, this.tripId, this.orderId}) : assert(tripId != null || orderId != null);
  final String? tripId;
  final String? orderId;

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  Timer? _refresh;

  TripKey get _key => (tripId: widget.tripId, orderId: widget.orderId);

  @override
  void initState() {
    super.initState();
    // Keep the trip current while the rider rides (a shop marks an order ready, another order joins the trip...).
    _refresh = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_busy) ref.invalidate(tripViewProvider(_key));
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(tripViewProvider(_key));
    ref.invalidate(activeDeliveriesProvider);
    ref.invalidate(riderTripsProvider);
  }

  Future<void> _open(Uri uri) async {
    final ok = await ref.read(urlOpenerProvider)(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that on this phone')));
    }
  }

  Future<void> _run(Future<void> Function(GudMealApi api) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(apiProvider));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      _refreshAll();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// At a shop: this order is collected. Once the last shop is done the rider is on the way to the customer.
  Future<void> _pickedUp(RiderTrip trip, TripStop stop) => _run((api) async {
        await api.pickup(stop.orderId!);
        final pickups = trip.stops.where((s) => s.isPickup);
        final allDone = pickups.every((s) => s.done || s.orderId == stop.orderId);
        if (!allDone) return;
        for (final s in pickups) {
          if (s.orderId == stop.orderId || s.status == 'picked_up') {
            try {
              await api.inTransit(s.orderId!);
            } on ApiException {
              // Not required: delivering sends it again when needed.
            }
          }
        }
      });

  /// At the customer: one code delivers every order of the trip.
  Future<void> _delivered(RiderTrip trip, TripStop dropoff, Map<String, Order> orders, String code) async {
    final ids = dropoff.orderIds.isNotEmpty ? dropoff.orderIds : trip.orderIds;
    var finished = false;
    await _run((api) async {
      for (final id in ids) {
        final pickupStatus = trip.stops.where((s) => s.isPickup && s.orderId == id).map((s) => s.status).firstOrNull;
        final status = orders[id]?.status ?? pickupStatus;
        if (const {'delivered', 'completed', 'cancelled'}.contains(status)) continue;
        if (status == 'picked_up') await api.inTransit(id);
        final cash = orders[id]?.collectCashKobo ?? dropoff.cashToCollectKobo;
        await api.deliver(id, code, cashCollected: cash > 0);
      }
      finished = true;
    });
    if (!finished || !mounted) return;
    ref.invalidate(earningsProvider);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivered — well done!')));
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tripViewProvider(_key));
    final view = async.value;
    if (view == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: Center(child: async.hasError ? Text('${async.error}') : const CircularProgressIndicator()),
      );
    }
    final trip = view.trip;
    final parcel = trip?.orderIds.any((id) => view.orders[id] != null && isParcelJob(view.orders[id]!)) ?? false;
    if (trip == null || parcel) {
      final orderId = widget.orderId ?? trip?.orderIds.firstOrNull;
      if (orderId != null) return DeliveryScreen(orderId: orderId);
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('This trip is no longer active')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(trip.orderIds.length > 1 ? 'Trip · ${trip.orderIds.length} orders' : 'Delivery')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _TripHeader(trip: trip, orders: view.orders, onNavigate: _open),
          const SizedBox(height: 12),
          for (var i = 0; i < trip.stops.length; i++)
            _StopCard(
              key: ValueKey('stop-$i'),
              index: i,
              last: i == trip.stops.length - 1,
              trip: trip,
              stop: trip.stops[i],
              orders: view.orders,
              busy: _busy,
              code: _code,
              open: _open,
              onPickedUp: () => _pickedUp(trip, trip.stops[i]),
              onDelivered: (code) => _delivered(trip, trip.stops[i], view.orders, code),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, key: const ValueKey('trip-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}

/// What is left of the trip and the one button that opens the whole route in Google Maps.
class _TripHeader extends StatelessWidget {
  const _TripHeader({required this.trip, required this.orders, required this.onNavigate});
  final RiderTrip trip;
  final Map<String, Order> orders;
  final Future<void> Function(Uri) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = _legText(trip.totalKm, trip.totalMinutes);
    final pay = trip.payoutKobo ??
        trip.orderIds.map((id) => orders[id]?.riderPayKobo ?? 0).fold<int>(0, (a, b) => a + b);
    final pickups = trip.stops.where((s) => s.isPickup).length;
    final next = trip.nextStop < trip.stops.length ? trip.stops[trip.nextStop] : null;
    final Uri? route = trip.navigationUrl != null
        ? Uri.tryParse(trip.navigationUrl!)
        : next?.location != null
            ? navigationUri(next!.location!)
            : null;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(left.isEmpty ? 'Your trip' : '$left left',
              key: const ValueKey('trip-remaining'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text([
            '$pickups ${pickups == 1 ? 'pickup' : 'pickups'}, then the customer',
            if (trip.routeSource == 'google') 'fastest route by Google Maps',
          ].join(' · ')),
          const SizedBox(height: 4),
          Text('You earn ${formatNaira(pay)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('start-navigation'),
            onPressed: route == null ? null : () => onNavigate(route),
            icon: const Icon(Icons.navigation_rounded),
            label: const Text('Start navigation'),
          ),
        ]),
      ),
    );
  }
}

/// One step of the trip: a shop (what to collect, its phone, picked up) or the customer (one code for all orders).
class _StopCard extends StatelessWidget {
  const _StopCard({
    super.key,
    required this.index,
    required this.last,
    required this.trip,
    required this.stop,
    required this.orders,
    required this.busy,
    required this.code,
    required this.open,
    required this.onPickedUp,
    required this.onDelivered,
  });
  final int index;
  final bool last;
  final RiderTrip trip;
  final TripStop stop;
  final Map<String, Order> orders;
  final bool busy;
  final TextEditingController code;
  final Future<void> Function(Uri) open;
  final VoidCallback onPickedUp;
  final ValueChanged<String> onDelivered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNext = index == trip.nextStop && !stop.done;
    final body = stop.isPickup ? _pickup(context) : _dropoff(context);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // The timeline: a numbered dot (ticked once done) and the line to the next stop.
        SizedBox(
          width: 36,
          child: Column(children: [
            const SizedBox(height: 14),
            CircleAvatar(
              radius: 14,
              backgroundColor: stop.done ? scheme.outlineVariant : (isNext ? scheme.primary : scheme.surfaceContainerHighest),
              foregroundColor: stop.done ? scheme.onSurfaceVariant : (isNext ? scheme.onPrimary : scheme.onSurface),
              child: stop.done
                  ? const Icon(Icons.check_rounded, size: 18)
                  : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            if (!last) Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Opacity(
            opacity: stop.done ? 0.55 : 1,
            child: Card(
              shape: isNext
                  ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: scheme.primary, width: 2))
                  : null,
              child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 8, 10), child: body),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _title(BuildContext context, IconData icon, String text, String? tag) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ),
      if (tag != null) Padding(padding: const EdgeInsets.only(right: 6), child: Text(tag, style: theme.textTheme.bodySmall)),
    ]);
  }

  Widget _contactButtons(String? phone, String who) {
    final number = (phone ?? '').trim();
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (number.isNotEmpty) ...[
        IconButton(tooltip: 'Call $who', icon: const Icon(Icons.call_rounded), onPressed: () => open(dialUri(number))),
        IconButton(tooltip: 'WhatsApp $who', icon: const Icon(Icons.chat_rounded), onPressed: () => open(whatsAppUri(number))),
      ],
      if (stop.location != null)
        TextButton.icon(
          onPressed: () => open(navigationUri(stop.location!)),
          icon: const Icon(Icons.navigation_rounded),
          label: const Text('Navigate'),
        ),
    ]);
  }

  Widget _pickup(BuildContext context) {
    final theme = Theme.of(context);
    final order = orders[stop.orderId];
    final phone = stop.phone ?? order?.restaurantPhone;
    final vertical = stop.vertical ?? order?.vertical;
    final items = stop.items.isNotEmpty
        ? stop.items.map((i) => '${i.quantity}× ${i.name}${i.options.isEmpty ? '' : ' (${i.options.join(', ')})'}').toList()
        : (order?.items ?? const <OrderItem>[]).map((i) => '${i.quantity}× ${i.name}').toList();
    final leg = _legText(stop.legKm, stop.legMinutes);
    final status = stop.done
        ? 'Picked up'
        : stop.ready
            ? 'Ready to collect'
            : vertical == 'food'
                ? 'The kitchen is still preparing this order.'
                : 'The shop is still packing this order.';
    // The API takes a pickup at the next shop or any shop whose order is ready (it answers otherwise).
    final canPickUp = !stop.done && !busy && stop.orderId != null && (stop.ready || index == trip.nextStop);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(context, Icons.storefront_rounded, stop.name.isNotEmpty ? stop.name : (order?.restaurantName ?? 'Shop'),
          stop.shortCode != null ? '#${stop.shortCode}' : null),
      const SizedBox(height: 2),
      Text(['Pick up · ${placeKind(vertical)}', if (leg.isNotEmpty) leg].join(' · '), style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      if ((stop.address ?? order?.restaurantAddress) != null)
        _Detail(icon: Icons.place_rounded, text: stop.address ?? order!.restaurantAddress!),
      if ((phone ?? '').trim().isNotEmpty) _Detail(icon: Icons.phone_rounded, text: phone!.trim()),
      if (items.isNotEmpty) _Detail(icon: Icons.shopping_bag_rounded, text: 'Collect: ${items.join(', ')}'),
      _Detail(
        icon: stop.done ? Icons.check_circle_rounded : (stop.ready ? Icons.inventory_rounded : Icons.hourglass_top_rounded),
        text: status,
      ),
      _contactButtons(phone, stop.name),
      if (!stop.done)
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilledButton(onPressed: canPickUp ? onPickedUp : null, child: const Text('Picked up')),
          ),
        ),
    ]);
  }

  Widget _dropoff(BuildContext context) {
    final theme = Theme.of(context);
    final ids = stop.orderIds.isNotEmpty ? stop.orderIds : trip.orderIds;
    final known = ids.map((id) => orders[id]).whereType<Order>().toList();
    final first = known.firstOrNull;
    final address = first?.deliveryAddress;
    final name = stop.name.isNotEmpty ? stop.name : (first?.customerName ?? 'Customer');
    final where = stop.address ??
        [address?.label, address?.line1, address?.area, address?.city]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .join(', ');
    final note = (stop.instructions ?? address?.instructions ?? '').trim();
    final phone = stop.phone ?? address?.contactPhone;
    final cash = stop.cashToCollectKobo > 0 ? stop.cashToCollectKobo : known.fold<int>(0, (a, o) => a + o.collectCashKobo);
    final leg = _legText(stop.legKm, stop.legMinutes);
    final pickupsDone = trip.stops.where((s) => s.isPickup).every((s) => s.done);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(context, Icons.person_rounded, name, null),
      const SizedBox(height: 2),
      Text(['Deliver · ${ids.length} ${ids.length == 1 ? 'order' : 'orders'}', if (leg.isNotEmpty) leg].join(' · '),
          style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      if (where.isNotEmpty) _Detail(icon: Icons.home_rounded, text: where),
      if (note.isNotEmpty) _Detail(icon: Icons.sticky_note_2_rounded, text: 'Note: $note'),
      if ((phone ?? '').trim().isNotEmpty) _Detail(icon: Icons.phone_rounded, text: phone!.trim()),
      if (cash > 0)
        Card(
          key: const ValueKey('collect-cash'),
          color: const Color(0xFFFFF4D6),
          margin: const EdgeInsets.only(bottom: 6, right: 6),
          child: ListTile(
            leading: const Icon(Icons.payments_rounded),
            title: Text('Collect ${formatNaira(cash)} in cash', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('The customer pays on delivery. Collect the cash before handing over the order.'),
          ),
        )
      else
        const _Detail(icon: Icons.payments_rounded, text: 'Paid online: nothing to collect'),
      _contactButtons(phone, name),
      if (!stop.done)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: pickupsDone
              ? DeliveryCodeForm(
                  controller: code,
                  busy: busy,
                  cashToCollectKobo: cash,
                  label: 'Delivered',
                  onSubmit: onDelivered,
                )
              : Text(
                  ids.length > 1
                      ? 'Collect from every shop first. The customer then gives you one code for all the orders.'
                      : 'Collect the order first. The customer then gives you the delivery code.',
                  style: theme.textTheme.bodySmall,
                ),
        ),
    ]);
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ]),
      );
}
