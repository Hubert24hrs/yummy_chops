import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/gm_map.dart';

/// The device's position, behind a port so tests can fake it. Only asked when the customer taps
/// "Use my current location"; the position is sent once to the API to find the address and is not tracked.
abstract class CustomerLocation {
  /// The current fix, or throws [LocationUnavailable] with a message to show.
  Future<GeoPoint> current();
}

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class GeolocatorCustomerLocation implements CustomerLocation {
  @override
  Future<GeoPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Turn on location services, or search for your address instead.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('Location permission is off. Search for your address instead.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      return GeoPoint(lat: p.latitude, lng: p.longitude);
    } on TimeoutException {
      throw const LocationUnavailable("We couldn't get a GPS fix. Try again outside, or search for your address.");
    }
  }
}

final customerLocationProvider = Provider<CustomerLocation>((ref) => GeolocatorCustomerLocation());

/// Where the phone is, only when the customer has already allowed location (this never asks): checkout uses it
/// to say when the delivery address is far from them. Null when it is not known.
final knownPositionProvider = FutureProvider.autoDispose<GeoPoint?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return null;
    final last = await Geolocator.getLastKnownPosition().catchError((_) => null);
    final p = last ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
        );
    return GeoPoint(lat: p.latitude, lng: p.longitude);
  } catch (_) {
    return null; // no permission yet, no location services, no fix: nothing to compare with
  }
});

/// What the picker returns: the address details plus the pin the customer confirmed.
class PickedAddress {
  const PickedAddress({required this.address, required this.serviceable, this.precise = false, this.placeId});
  final DeliveryAddress address;
  final bool serviceable;
  final bool precise;
  final String? placeId;
}

/// How the picker opens: on the search box, finding the phone's position at once, or on the map with a pin to move.
enum AddressStart { search, myLocation, map }

/// Opens the address picker. Search goes through the Yummy Chops API (Google Places behind it when configured,
/// the neighbourhood list otherwise), so no Google key is in the app for this. "Choose on the map" needs Google map
/// tiles (a build with MAPS_ENABLED and the app's Maps key); without them the picker offers search and GPS only.
Future<PickedAddress?> pickDeliveryAddress(BuildContext context, {String title = 'Delivery address', AddressStart start = AddressStart.search}) =>
    // Root navigator: a focused full-screen step above the tab bar and the assistant button.
    Navigator.of(context, rootNavigator: true).push<PickedAddress>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => AddressPickerScreen(title: title, start: start)),
    );

class AddressPickerScreen extends ConsumerStatefulWidget {
  const AddressPickerScreen({super.key, this.title = 'Delivery address', this.start = AddressStart.search});
  final String title;
  final AddressStart start;

  @override
  ConsumerState<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends ConsumerState<AddressPickerScreen> {
  final _query = TextEditingController();
  final _line1 = TextEditingController();
  final _landmark = TextEditingController();
  String _session = newPlacesSession();
  Timer? _debounce;
  int _searchId = 0;
  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _locating = false;
  String? _error;

  PlaceLookup? _chosen;
  GeoPoint? _pin;

  /// "Choose on the map": the pin the customer is moving, before the API turns it into an address.
  bool _onMap = false;
  GeoPoint? _mapPin;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    if (widget.start == AddressStart.myLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
    } else if (widget.start == AddressStart.map && googleMapsReady) {
      _onMap = true;
      _mapPin = ref.read(areaProvider).location;
    }
  }

  void _openMap() => setState(() {
        _onMap = true;
        _mapPin ??= ref.read(areaProvider).location;
        _error = null;
      });

  /// The spot the customer chose on the map, as an address the rider can find (the API looks it up).
  Future<void> _useMapSpot() async {
    final spot = _mapPin;
    if (spot == null) return;
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final lookup = await ref.read(apiProvider).reverseGeocode(spot);
      _show(lookup);
      setState(() {
        _onMap = false;
        _pin = spot; // keep the exact spot, not the looked-up centre
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _line1.dispose();
    _landmark.dispose();
    super.dispose();
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.length < 3) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final id = ++_searchId;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final area = ref.read(areaProvider);
      final found = await ref.read(apiProvider).placeSuggestions(q, session: _session, near: area.location, city: area.city);
      if (mounted && id == _searchId) setState(() => _suggestions = found);
    } on ApiException catch (e) {
      if (mounted && id == _searchId) setState(() => _error = e.message);
    } finally {
      if (mounted && id == _searchId) setState(() => _searching = false);
    }
  }

  Future<void> _choose(PlaceSuggestion s) async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final lookup = await ref.read(apiProvider).placeDetails(s.placeId, session: _session);
      _session = newPlacesSession(); // the pick ends this search session
      _show(lookup);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final here = await ref.read(customerLocationProvider).current();
      final lookup = await ref.read(apiProvider).reverseGeocode(here);
      _show(lookup);
    } on LocationUnavailable catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _show(PlaceLookup lookup) {
    setState(() {
      _chosen = lookup;
      _pin = lookup.place.location;
      _line1.text = lookup.place.isPrecise ? lookup.place.formattedAddress : '';
      _landmark.clear();
      _error = null;
    });
  }

  void _confirm() {
    final chosen = _chosen!;
    final line1 = _line1.text.trim();
    if (line1.length < 3) {
      setState(() => _error = 'Add your street and house number so the rider can find you');
      return;
    }
    final landmark = _landmark.text.trim();
    Navigator.of(context).pop(PickedAddress(
      address: chosen.toAddress(line1: line1, instructions: landmark.isEmpty ? null : landmark, pin: _pin),
      serviceable: chosen.serviceable,
      precise: chosen.place.isPrecise,
      placeId: chosen.place.placeId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: _chosen == null && !_onMap
            ? null
            : IconButton(
                tooltip: 'Back to search',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _chosen = null;
                  _onMap = false;
                }),
              ),
      ),
      body: _chosen != null
          ? _confirmView(context, _chosen!)
          : _onMap
              ? _mapView(context)
              : _searchView(context),
      bottomNavigationBar: _chosen == null
          ? (_onMap ? _mapBar(context) : null)
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
                    ),
                  FilledButton(onPressed: _chosen!.serviceable ? _confirm : null, child: const Text('Use this address')),
                  if (!_chosen!.serviceable)
                    TextButton(onPressed: () => setState(() => _chosen = null), child: const Text('Choose another address')),
                ]),
              ),
            ),
    );
  }

  Widget _searchView(BuildContext context) {
    final theme = Theme.of(context);
    final saved = ref.watch(addressesProvider).value ?? const <DeliveryAddress>[];
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        controller: _query,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: 'Search street, estate or landmark',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
        ),
        onChanged: _onQuery,
        onSubmitted: (q) => q.trim().length >= 3 ? _search(q.trim()) : null,
      ),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _locating ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)) : Icon(Icons.my_location_rounded, color: theme.colorScheme.primary),
        title: const Text('Use my current location', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Asked once to find your address; Yummy Chops does not track you'),
        onTap: _locating ? null : _useMyLocation,
      ),
      if (googleMapsReady)
        ListTile(
          key: const ValueKey('choose-on-map'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.map_rounded, color: theme.colorScheme.primary),
          title: const Text('Choose on the map', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Move the pin to your gate'),
          onTap: _openMap,
        ),
      if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
      for (final s in _suggestions)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(s.source == 'google' ? Icons.place_rounded : Icons.location_city_rounded),
          title: Text(s.title),
          subtitle: Text([
            if (s.subtitle.isNotEmpty) s.subtitle,
            if (s.source != 'google') 'Neighbourhood',
            if (s.distanceM != null) _distance(s.distanceM!),
          ].join(' · ')),
          onTap: () => _choose(s),
        ),
      if (_query.text.trim().length >= 3 && !_searching && _suggestions.isEmpty && _error == null)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No matches yet. Try the estate, street or a nearby landmark.')),
      if (saved.isNotEmpty && _suggestions.isEmpty) ...[
        const SizedBox(height: 12),
        Text('Saved addresses', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        for (final a in saved)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_rounded),
            title: Text(a.label ?? a.line1),
            subtitle: Text([a.line1, a.area].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', ')),
            onTap: () => Navigator.of(context).pop(PickedAddress(address: a, serviceable: true)),
          ),
      ],
    ]);
  }

  /// "Choose on the map": a Google map with one pin the customer drags to their gate.
  Widget _mapView(BuildContext context) {
    final theme = Theme.of(context);
    final pin = _mapPin ?? ref.read(areaProvider).location;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Drag the pin to where the rider should stop, then tap "Use this spot".', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 12),
      GmMap(
        height: 380,
        pins: [MapPin(pin, PinKind.home, label: 'Deliver here')],
        onPinMoved: (p) => setState(() => _mapPin = p),
      ),
      if (_error != null)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
    ]);
  }

  Widget _mapBar(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            key: const ValueKey('use-map-spot'),
            onPressed: _placing ? null : _useMapSpot,
            icon: _placing
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: const Text('Use this spot'),
          ),
        ),
      );

  Widget _confirmView(BuildContext context, PlaceLookup chosen) {
    final theme = Theme.of(context);
    final place = chosen.place;
    return ListView(padding: const EdgeInsets.all(16), children: [
      GmMap(
        height: 190,
        pins: [MapPin(_pin ?? place.location, PinKind.home, label: place.area ?? 'Your address')],
        onPinMoved: (p) => setState(() => _pin = p),
      ),
      if (googleMapsReady)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text('Drag the pin to your exact gate if it is off.', style: theme.textTheme.bodySmall)),
      const SizedBox(height: 12),
      Card(
        color: chosen.serviceable ? theme.colorScheme.secondaryContainer : theme.colorScheme.errorContainer,
        child: ListTile(
          leading: Icon(chosen.serviceable ? Icons.check_circle_rounded : Icons.block_rounded),
          title: Text(chosen.serviceable ? 'Yummy Chops delivers here' : 'Outside our delivery area for now',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(place.formattedAddress),
        ),
      ),
      if (!place.isPrecise)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            place.source == 'google'
                ? 'This pin is approximate. Add your street, house number and a landmark below.'
                : 'This is the neighbourhood centre. Add your street, house number and a landmark below.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      const SizedBox(height: 12),
      TextField(controller: _line1, decoration: const InputDecoration(labelText: 'Street and house number')),
      const SizedBox(height: 8),
      TextField(controller: _landmark, decoration: const InputDecoration(labelText: 'Landmark or directions (optional)')),
    ]);
  }
}

String _distance(int metres) => metres < 1000 ? '$metres m' : '${(metres / 1000).toStringAsFixed(1)} km';
