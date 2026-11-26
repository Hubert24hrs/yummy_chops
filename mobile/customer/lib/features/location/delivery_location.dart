import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../ui/gm_map.dart';
import 'address_picker.dart';

/// True from the moment someone signs in on this phone until they have been asked where to deliver: the guest the app
/// signs in on first launch (guest mode), or a guest signing in to another account. A session the app restores at
/// start-up does not count, nor a guest saving their account (the same customer).
class AskWhereToDeliver extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(authStateProvider, (previous, next) {
      final before = previous is AsyncData<GmUser?> ? previous.value : null;
      final wasSignedOut = previous is AsyncData<GmUser?> && before == null;
      final user = next.value;
      if (user == null) {
        state = false;
      } else if (wasSignedOut || (before != null && before.isAnonymous && before.uid != user.uid)) {
        state = true;
      }
    });
    return false;
  }

  void asked() => state = false;
}

final askWhereToDeliverProvider = NotifierProvider<AskWhereToDeliver, bool>(AskWhereToDeliver.new);

/// Right after the first launch (or signing in), a customer with no saved address chooses how to set one: the phone's GPS, typing the
/// address, or choosing the spot on the Google map (when the build has map tiles). The address is saved to their
/// address book as "Home" and its neighbourhood becomes the delivery area on Home. "Not now" skips it.
class DeliveryLocationScreen extends ConsumerStatefulWidget {
  const DeliveryLocationScreen({super.key});

  @override
  ConsumerState<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends ConsumerState<DeliveryLocationScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _pick(AddressStart start) async {
    final picked = await pickDeliveryAddress(context, start: start);
    if (picked == null || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final address = picked.address.copyWith(label: picked.address.label ?? 'Home');
      await ref.read(apiProvider).saveAddress(address);
      ref.invalidate(addressesProvider);
      final areas = ref.read(areasProvider).value ?? const [...lagosAreas, ...enuguAreas];
      final area = nearestArea(address.location, areas);
      if (area != null) ref.read(areaProvider.notifier).select(area);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget option({required Key key, required IconData icon, required String title, required String body, required AddressStart start}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              key: key,
              borderRadius: BorderRadius.circular(18),
              onTap: _saving ? null : () => _pick(start),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: brandRed, child: Icon(icon, color: Colors.white)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(body, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Where should we deliver?')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(
          'Set your delivery address so we show the shops that deliver to you. You can change it any time from the '
          'address at the top of Home.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        option(
          key: const ValueKey('where-gps'),
          icon: Icons.my_location_rounded,
          title: 'Use my current location',
          body: "Your phone's GPS finds your address once. We don't track you.",
          start: AddressStart.myLocation,
        ),
        option(
          key: const ValueKey('where-type'),
          icon: Icons.search_rounded,
          title: 'Type my address',
          body: 'Street, estate or a landmark near you',
          start: AddressStart.search,
        ),
        if (googleMapsReady)
          option(
            key: const ValueKey('where-map'),
            icon: Icons.map_rounded,
            title: 'Choose on the map',
            body: 'Move the pin on Google Maps to your gate',
            start: AddressStart.map,
          ),
        if (_saving) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            key: const ValueKey('where-later'),
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
        ),
      ]),
    );
  }
}

/// Asks once after a fresh sign-in (the guest's included), and only when the customer has no saved address yet.
/// Never blocks signing in: if the address book can't be read, the customer simply goes on.
Future<void> askWhereToDeliverIfNeeded(BuildContext context, WidgetRef ref) async {
  // Signing out rebuilds the app around the new guest, and both the old and the new screens may ask: one question is
  // enough (seen on a phone, 2026-11-26: "Where should we deliver?" came up twice after signing out).
  if (_askingWhereToDeliver) return;
  if (!ref.read(askWhereToDeliverProvider)) return;
  ref.read(askWhereToDeliverProvider.notifier).asked();
  _askingWhereToDeliver = true;
  try {
    try {
      final saved = await ref.read(apiProvider).addresses();
      if (saved.isNotEmpty) return;
    } on ApiException {
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const DeliveryLocationScreen()));
  } finally {
    _askingWhereToDeliver = false;
  }
}

/// True while "Where should we deliver?" is on screen.
bool _askingWhereToDeliver = false;
