import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../providers.dart';
import 'kyc_screen.dart';
import 'trip_screen.dart';

/// The rider's dashboard: online switch with location status, today's numbers, new offers (with a buzz), the
/// deliveries in hand, and what to do while waiting.
class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  Timer? _poll;
  String? _message;
  final _seenOffers = <String>{};
  int? _activeCount;

  @override
  void initState() {
    super.initState();
    // Offers expire in ~45 s, so poll quickly. FCM push wakes the app in the background.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(offersProvider);
      ref.invalidate(activeDeliveriesProvider);
      ref.invalidate(riderTripsProvider);
    });
    // App reopened while still online (e.g. mid-delivery): resume sharing the position.
    ref.listenManual(riderProfileProvider, (_, next) {
      final reporter = ref.read(locationReporterProvider);
      if (next.value?.isOnline == true && !reporter.active && !reporter.stoppedByServer) reporter.start();
    }, fireImmediately: true);
    // An offer only lasts ~45 s: buzz when a new one arrives so the rider notices it.
    ref.listenManual(offersProvider, (_, next) {
      final fresh = (next.value ?? const <DeliveryOffer>[]).where((o) => _seenOffers.add(o.id)).toList();
      if (fresh.isNotEmpty) HapticFeedback.vibrate();
    });
    // A delivery finished or started: refresh the numbers.
    ref.listenManual(activeDeliveriesProvider, (_, next) {
      final count = next.value?.length;
      if (count != null && count != _activeCount) {
        if (_activeCount != null) {
          ref.invalidate(earningsProvider);
          ref.invalidate(riderProfileProvider);
        }
        _activeCount = count;
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Signing out ends the shift first: the phone stops sharing its position and the server stops offering jobs.
  /// The rider is signed out even when the server cannot be told (no connection).
  Future<void> _signOut() async {
    final auth = ref.read(authRepositoryProvider);
    await setRiderOnline(ref.read(apiProvider), ref.read(locationReporterProvider), false);
    await auth.signOut();
  }

  Future<void> _setOnline(bool online) async {
    final message = await setRiderOnline(ref.read(apiProvider), ref.read(locationReporterProvider), online);
    ref.invalidate(riderProfileProvider);
    ref.invalidate(offersProvider);
    if (mounted) setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(riderProfileProvider);
    final offers = ref.watch(offersProvider);
    final active = ref.watch(activeDeliveriesProvider);
    final earnings = ref.watch(earningsProvider);
    final reporter = ref.watch(locationReporterProvider);
    final kyc = ref.watch(riderKycProvider).value;
    final verified = kyc?['status'] == 'verified';
    final theme = Theme.of(context);
    final p = profile.value;
    final offerList = offers.value ?? const <DeliveryOffer>[];
    final activeList = active.value ?? const <Order>[];
    final jobs = activeJobs(activeList, ref.watch(riderTripsProvider).value ?? const <RiderTrip>[]);

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(p == null ? 'Yummy Chops Rider' : 'Hi, ${p.name.split(' ').first}', overflow: TextOverflow.ellipsis)),
          if (verified) ...[
            const SizedBox(width: 6),
            const Tooltip(message: 'Verified rider', child: Icon(Icons.verified_rounded, color: GmLight.success, key: ValueKey('verified-badge'))),
          ],
        ]),
        actions: [
          IconButton(tooltip: 'Earnings', onPressed: () => context.push('/earnings'), icon: const Icon(Icons.account_balance_wallet_rounded)),
          IconButton(tooltip: 'Sign out', onPressed: _signOut, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: Colors.white,
        onPressed: () => _sos(context),
        icon: const Icon(Icons.sos_rounded),
        label: const Text('Emergency'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(riderKycProvider);
          ref.invalidate(riderProfileProvider);
          ref.invalidate(earningsProvider);
          ref.invalidate(offersProvider);
          ref.invalidate(activeDeliveriesProvider);
          ref.invalidate(riderTripsProvider);
        },
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
          // New riders: their KYC comes first; the team's verification lets them go online (the Verified badge).
          if (kyc != null && !verified)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KycStatusCard(kyc: kyc, onTap: () => context.push('/kyc')),
            ),
          profile.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => e is ApiException && (e.status == 403 || e.status == 404)
                ? Card(
                    key: const ValueKey('not-a-rider'),
                    child: ListTile(
                      leading: const Icon(Icons.two_wheeler_rounded),
                      title: const Text('This account is not a rider yet'),
                      subtitle: const Text('Sign up as a rider, then complete your KYC.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/sign-up'),
                    ),
                  )
                : Text('$e'),
            data: (p) => _StatusCard(profile: p, reporter: reporter, onChanged: p.status == 'active' ? _setOnline : null),
          ),
          if (_message != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, style: TextStyle(color: theme.colorScheme.error))),
          const SizedBox(height: 12),
          _Stats(earnings: earnings.value, profile: p),
          if ((earnings.value?.cashHeldKobo ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('You are holding ${formatNaira(earnings.value!.cashHeldKobo)} in cash to hand in.',
                  style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700)),
            ),
          if (offerList.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('New offers', count: offerList.length),
            for (final offer in offerList) OfferCard(offer: offer),
          ],
          if (offers.hasError) Text('${offers.error}', style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 20),
          _SectionTitle('Active deliveries', count: jobs.length),
          if (active.hasError) Text('${active.error}', style: TextStyle(color: theme.colorScheme.error)),
          if (jobs.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('No active deliveries'))
          else
            for (final job in jobs)
              if (job.trip != null)
                TripCard(trip: job.trip!)
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delivery_dining_rounded),
                    title: Text('${job.order!.restaurantName} · #${job.order!.shortCode}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${statusLabel(job.order!.status)} · earn ${formatNaira(job.order!.riderPayKobo)}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/deliveries/${job.order!.id}'),
                  ),
                ),
          if (offerList.isEmpty) ...[
            const SizedBox(height: 16),
            _WaitingCard(online: p?.isOnline ?? false, busy: activeList.isNotEmpty),
          ],
        ]),
      ),
    );
  }

  Future<void> _sos(BuildContext context) async {
    var typed = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report an emergency'),
        content: TextField(onChanged: (text) => typed = text.trim(), decoration: const InputDecoration(hintText: 'What is happening?'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Send to Yummy Chops')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Always sent, and always answered on screen: a rider in trouble may type little or nothing.
    final description = typed.length >= 3 ? typed : 'Emergency (the rider did not say more)';
    try {
      // Where the rider is: the last shared position, or a fresh one when they are offline.
      final at = ref.read(locationReporterProvider).last ?? (await ref.read(locationSourceProvider).current())?.$1;
      await ref.read(apiProvider).emergency(description, at);
      messenger.showSnackBar(const SnackBar(content: Text('Our operations team has been alerted. If you are in danger, call 112.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        duration: Duration(seconds: 10),
        content: Text('We could not send your alert. Call 112 now if you are in danger, then try again.'),
      ));
    }
  }
}

/// A delivery offer with a live countdown. Accepting after expiry is impossible (the API rejects it too).
class OfferCard extends ConsumerStatefulWidget {
  const OfferCard({super.key, required this.offer, this.now});
  final DeliveryOffer offer;
  final DateTime Function()? now;

  @override
  ConsumerState<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<OfferCard> {
  Timer? _tick;
  bool _busy = false;

  DateTime _now() => (widget.now ?? DateTime.now)().toUtc();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final remaining = o.expiresAt.toUtc().difference(_now()).inSeconds;
    final expired = remaining <= 0;
    final multi = o.pickups.length > 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(multi ? '${o.pickups.length} pickups' : o.restaurantName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            Text(expired ? 'Expired' : '${remaining}s', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          ]),
          if (multi)
            // A mixed cart: every place to collect from, then one customer.
            for (final p in o.pickups)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.storefront_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if ((p.address ?? '').isNotEmpty) TextSpan(text: ' · ${p.address}'),
                    ])),
                  ),
                ]),
              ),
          if (multi) const SizedBox(height: 4),
          Text('${o.distanceToRestaurantKm.toStringAsFixed(1)} km to ${multi ? 'the first pickup' : 'pickup'}'
              '${o.dropoffArea != null ? ' · drop-off in ${o.dropoffArea}' : ''}'),
          Text('You earn ${formatNaira(o.payoutKobo)}${multi ? ' for the whole trip' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: expired || _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          final order = await ref.read(apiProvider).acceptOffer(o.id);
                          ref.invalidate(offersProvider);
                          ref.invalidate(activeDeliveriesProvider);
                          if (context.mounted) context.push('/deliveries/${order.id}');
                        } on ApiException catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: expired || _busy
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _busy = true);
                      try {
                        await ref.read(apiProvider).declineOffer(o.id, 'Declined in app');
                      } on ApiException catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text(e.message)));
                      } finally {
                        if (mounted) {
                          setState(() => _busy = false);
                          ref.invalidate(offersProvider);
                        }
                      }
                    },
              child: const Text('Decline'),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// One line of the dashboard's active work: a planned trip, or an order the trips do not cover (packages,
/// interstate legs, or a server without trips yet).
typedef ActiveJob = ({RiderTrip? trip, Order? order});

List<ActiveJob> activeJobs(List<Order> orders, List<RiderTrip> trips) {
  final byId = {for (final o in orders) o.id: o};
  final shown = trips
      .where((t) => t.orderIds.isNotEmpty && !t.orderIds.any((id) => byId[id] != null && isParcelJob(byId[id]!)))
      .toList();
  final covered = {for (final t in shown) ...t.orderIds};
  return [
    for (final t in shown) (trip: t, order: null),
    for (final o in orders)
      if (!covered.contains(o.id)) (trip: null, order: o),
  ];
}

/// A trip on the dashboard: where to go next, how many stops and how long it takes. Opens the trip screen.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});
  final RiderTrip trip;

  @override
  Widget build(BuildContext context) {
    final next = trip.nextStop < trip.stops.length ? trip.stops[trip.nextStop] : null;
    final title = next == null
        ? 'Trip ${trip.tripId}'
        : next.isPickup
            ? 'Next: pick up at ${next.name}'
            : 'Next: deliver to ${next.name}';
    final left = trip.stops.where((s) => !s.done).length;
    return Card(
      key: ValueKey('trip-${trip.tripId}'),
      child: ListTile(
        leading: const Icon(Icons.route_rounded),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([
          '$left of ${trip.stops.length} stops left',
          if (trip.totalMinutes != null) '${trip.totalMinutes} min',
          if (trip.totalKm != null) '${trip.totalKm!.toStringAsFixed(1)} km',
          if (trip.payoutKobo != null) 'earn ${formatNaira(trip.payoutKobo)}',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/trips/${Uri.encodeComponent(trip.tripId)}'),
      ),
    );
  }
}

/// Online switch, account line and whether the position is reaching Yummy Chops (dispatch only offers jobs to riders
/// it heard from in the last 3 minutes).
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.profile, required this.reporter, required this.onChanged});
  final RiderProfile profile;
  final LocationReporter reporter;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final online = profile.isOnline;
    final sent = reporter.lastSentAt;
    final location = !online
        ? 'Location sharing is off'
        : sent == null
            ? 'Finding your location…'
            : 'Location shared · updated ${_ago(sent)}';
    final foreground = online ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Card(
      color: online ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(online ? Icons.delivery_dining_rounded : Icons.bedtime_rounded, size: 34, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(online ? "You're online" : "You're offline",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: foreground)),
                Text(
                  profile.status != 'active'
                      ? 'Your account is ${profile.status}. Contact support.'
                      : online
                          ? 'You get delivery offers near you'
                          : 'Go online to get delivery offers',
                  style: TextStyle(color: foreground),
                ),
              ]),
            ),
            Switch(value: online, onChanged: onChanged),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(online ? Icons.my_location_rounded : Icons.location_disabled_rounded, size: 16, color: foreground),
            const SizedBox(width: 6),
            Expanded(child: Text(location, style: theme.textTheme.bodySmall?.copyWith(color: foreground))),
            Text('${profile.vehicle} · ★ ${profile.rating.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(color: foreground)),
          ]),
        ]),
      ),
    );
  }
}

String _ago(DateTime t) {
  final seconds = DateTime.now().difference(t).inSeconds;
  if (seconds < 10) return 'just now';
  if (seconds < 60) return '${seconds}s ago';
  return '${seconds ~/ 60} min ago';
}

/// Earnings and delivery numbers at a glance.
class _Stats extends StatelessWidget {
  const _Stats({required this.earnings, required this.profile});
  final Earnings? earnings;
  final RiderProfile? profile;

  @override
  Widget build(BuildContext context) {
    final e = earnings;
    Widget tile(IconData icon, String value, String label) => Expanded(child: _StatTile(icon: icon, value: value, label: label));
    return Column(children: [
      Row(children: [
        tile(Icons.payments_rounded, e == null ? '…' : formatNaira(e.earnedLast7DaysKobo), 'Earned in 7 days'),
        const SizedBox(width: 10),
        tile(Icons.account_balance_wallet_rounded, e == null ? '…' : formatNaira(e.availableKobo), 'Ready to withdraw'),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        tile(Icons.check_circle_rounded, '${profile?.completedDeliveries ?? e?.deliveriesCompleted ?? 0}', 'Deliveries done'),
        const SizedBox(width: 10),
        tile(Icons.star_rounded, profile == null ? '…' : profile!.rating.toStringAsFixed(2), 'Your rating'),
      ]),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.count});
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(text, style: theme.textTheme.titleLarge),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
            child: Text('$count', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800)),
          ),
        ],
      ]),
    );
  }
}

/// What the rider sees while there is no offer: keep the app open when online, or how to start.
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.online, required this.busy});
  final bool online;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, body) = !online
        ? (Icons.power_settings_new_rounded, 'Go online to start', 'Switch on above when you are ready to ride.')
        : busy
            ? (Icons.route_rounded, 'Finish your delivery', 'New offers appear here while you can still take one.')
            : (Icons.radar_rounded, 'Waiting for orders near you…',
                'Keep this app open. Each offer lasts 45 seconds and your phone buzzes when one arrives.');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ]),
      ),
    );
  }
}
