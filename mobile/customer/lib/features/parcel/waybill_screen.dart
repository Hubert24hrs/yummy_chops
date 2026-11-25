import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/payment_picker.dart';

final waybillOriginsProvider = FutureProvider<List<WaybillOrigin>>((ref) => ref.watch(apiProvider).waybillOrigins());
final waybillDestinationsProvider =
    FutureProvider.family<WaybillDestinations, String>((ref, origin) => ref.watch(apiProvider).waybillDestinations(origin));

final _phone = RegExp(r'^\+?[0-9 ]{7,20}$');
const _sizes = [('small', 'Small', 'Up to 5 kg'), ('medium', 'Medium', 'Up to 10 kg'), ('large', 'Large', 'Up to 20 kg')];
const _categories = {
  'documents': 'Documents',
  'clothing': 'Clothing',
  'electronics': 'Electronics',
  'food': 'Food',
  'cosmetics': 'Cosmetics',
  'household': 'Household',
  'other': 'Other',
};

class _Person {
  final name = TextEditingController();
  final phone = TextEditingController();
  final line = TextEditingController();
  Area? area;

  void dispose() {
    name.dispose();
    phone.dispose();
    line.dispose();
  }
}

/// Interstate waybill booking: route, pickup or hub drop-off, door delivery or hub collection, package, price, pay.
class WaybillScreen extends ConsumerStatefulWidget {
  const WaybillScreen({super.key});

  @override
  ConsumerState<WaybillScreen> createState() => _WaybillScreenState();
}

class _WaybillScreenState extends ConsumerState<WaybillScreen> {
  String _origin = 'lagos';
  String? _destination;
  String _firstMile = 'pickup';
  String? _originHub;
  String _lastMile = 'door';
  String? _destHub;
  final _sender = _Person();
  final _recipient = _Person();
  String _size = 'small';
  final _weight = TextEditingController(text: '1');
  String _category = 'clothing';
  final _what = TextEditingController();
  bool _cod = false;
  final _codAmount = TextEditingController();
  WaybillQuote? _quote;
  PayMethod _method = PayMethod.card;
  String? _error;
  bool _busy = false;
  final _orderKey = IdempotencyKey('waybill');
  final _checkoutKeys = <PayMethod, IdempotencyKey>{};

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value ?? ref.read(authRepositoryProvider).currentUser;
    _sender.name.text = user?.name ?? '';
    _sender.phone.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _sender.dispose();
    _recipient.dispose();
    _weight.dispose();
    _what.dispose();
    _codAmount.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _quote = null);

  int get _codKobo => ((double.tryParse(_codAmount.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) * 100).round();

  WaybillParty _party(_Person p, {required bool withAddress}) => WaybillParty(
        name: p.name.text.trim(),
        phone: p.phone.text.trim(),
        line1: withAddress ? p.line.text.trim() : null,
        area: withAddress ? p.area?.name : null,
        location: withAddress ? p.area?.location : null,
      );

  String? _validate(WaybillDestination? dest, bool pickup, bool door) {
    if (dest == null) return 'Choose where the package is going';
    for (final (who, p, withAddress) in [('sender', _sender, pickup), ('recipient', _recipient, door)]) {
      if (p.name.text.trim().length < 2) return 'Enter the $who’s name';
      if (!_phone.hasMatch(p.phone.text.trim())) return 'Enter a valid $who phone number';
      if (withAddress && p.area == null) return 'Choose the ${who == 'sender' ? 'pickup' : 'delivery'} area';
      if (withAddress && p.line.text.trim().length < 3) return 'Enter the ${who == 'sender' ? 'pickup' : 'delivery'} street address';
    }
    if ((double.tryParse(_weight.text) ?? 0) <= 0) return 'Enter the weight in kg';
    if (_cod && door && _codKobo < 100) return 'Enter the amount the rider should collect from your buyer';
    return null;
  }

  Future<void> _price(WaybillDestination? dest, bool pickup, bool door) async {
    final problem = _validate(dest, pickup, door);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final q = await ref.read(apiProvider).waybillQuote(
            originCity: _origin,
            destinationCity: _destination!,
            firstMile: pickup ? 'pickup' : 'dropoff',
            lastMile: door ? 'door' : 'collect',
            originHubId: pickup ? null : _originHub,
            destinationHubId: door ? null : _destHub,
            sender: _party(_sender, withAddress: pickup),
            recipient: _party(_recipient, withAddress: door),
            size: _size,
            weightKg: double.parse(_weight.text),
            category: _category,
            description: _what.text.trim(),
            codAmountKobo: _cod && door ? _codKobo : null,
          );
      setState(() {
        _quote = q;
        // A new price is a new booking: it never goes out with the keys of the last one.
        _orderKey.renew();
        _checkoutKeys.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _book() async {
    final quote = _quote;
    if (quote == null) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final order = await _orderKey.send(quote.id, (key) => api.bookWaybill(quote.id, key));
      final checkout = await _checkoutKeys
          .putIfAbsent(_method, () => IdempotencyKey('checkout'))
          .send(order.id, (key) => api.checkout(order.id, key, provider: _method.provider));
      ref.invalidate(walletProvider);
      final url = checkout.authorizationUrl;
      if (url == null) {
        if (mounted) context.go('/orders/${order.id}?paid=1'); // paid from the wallet: the receipt comes up
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      if (mounted) context.go('/orders/${order.id}?ref=${checkout.reference}');
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        // The price is no longer held: the button goes back to asking for a new one.
        if (e.needsNewQuote) _quote = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origins = ref.watch(waybillOriginsProvider).value ?? const <WaybillOrigin>[];
    final routes = ref.watch(waybillDestinationsProvider(_origin)).value;
    final areas = ref.watch(areasProvider).value ?? const [...lagosAreas, ...enuguAreas];
    final originInfo = origins.where((o) => o.id == _origin).firstOrNull;
    final dest = routes?.destinations.where((d) => d.city == _destination).firstOrNull;
    final pickup = _firstMile == 'pickup' && (originInfo?.homePickup ?? true);
    final door = _lastMile == 'door' && (dest?.doorDelivery ?? true);
    final b = _quote?.breakdown;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
          child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        );

    Widget person(_Person p, String who, String city, bool withAddress) => Column(children: [
          TextField(controller: p.name, decoration: InputDecoration(labelText: '$who name'), onChanged: (_) => _changed()),
          const SizedBox(height: 8),
          TextField(
            controller: p.phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: '$who phone'),
            onChanged: (_) => _changed(),
          ),
          if (withAddress) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<Area>(
              key: ValueKey('$who-area-$city'),
              initialValue: p.area != null && p.area!.city == city ? p.area : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Area'),
              items: [for (final a in areas.where((a) => a.city == city)) DropdownMenuItem(value: a, child: Text(a.name))],
              onChanged: (a) => setState(() {
                p.area = a;
                _quote = null;
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: p.line,
              decoration: const InputDecoration(labelText: 'Street address and landmark'),
              onChanged: (_) => _changed(),
            ),
          ],
        ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Interstate waybill')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Within the city')),
            ButtonSegment(value: true, label: Text('Interstate')),
          ],
          selected: const {true},
          onSelectionChanged: (s) {
            if (!s.first) context.go('/send');
          },
        ),
        section('Route'),
        DropdownButtonFormField<String>(
          key: const ValueKey('wb-from'),
          initialValue: _origin,
          decoration: const InputDecoration(labelText: 'From'),
          items: [
            for (final o in origins.isEmpty ? const [WaybillOrigin(id: 'lagos', name: 'Lagos'), WaybillOrigin(id: 'enugu', name: 'Enugu')] : origins)
              DropdownMenuItem(value: o.id, child: Text(o.name)),
          ],
          onChanged: (v) => setState(() {
            _origin = v ?? 'lagos';
            _destination = null;
            _originHub = null;
            _quote = null;
          }),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey('wb-to-$_origin'),
          initialValue: _destination,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'To'),
          items: [
            for (final d in routes?.destinations ?? const <WaybillDestination>[])
              DropdownMenuItem(
                value: d.city,
                child: Text(
                  '${d.name}: from ${formatNaira(d.fromKobo)}, '
                  '${d.transitDays.first == d.transitDays.last ? '${d.transitDays.first} day' : '${d.transitDays.first}–${d.transitDays.last} days'}',
                ),
              ),
          ],
          onChanged: (v) => setState(() {
            _destination = v;
            _destHub = null;
            _quote = null;
          }),
        ),
        section('How does it start?'),
        RadioGroup<String>(
          groupValue: pickup ? 'pickup' : 'dropoff',
          onChanged: (v) => setState(() {
            _firstMile = v ?? 'pickup';
            _quote = null;
          }),
          child: Column(children: [
            RadioListTile(
              value: 'pickup',
              enabled: originInfo?.homePickup ?? true,
              contentPadding: EdgeInsets.zero,
              title: const Text('A rider picks it up'),
              subtitle: const Text('From your address, taken to our hub'),
            ),
            const RadioListTile(
              value: 'dropoff',
              contentPadding: EdgeInsets.zero,
              title: Text('I’ll drop it at a hub'),
              subtitle: Text('No pickup fee'),
            ),
          ]),
        ),
        if (!pickup)
          DropdownButtonFormField<String?>(
            key: ValueKey('wb-origin-hub-$_origin'),
            initialValue: _originHub,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Drop-off hub'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Nearest hub')),
              for (final h in routes?.dropoffHubs ?? const <WaybillHub>[]) DropdownMenuItem(value: h.id, child: Text(h.name)),
            ],
            onChanged: (v) => setState(() {
              _originHub = v;
              _quote = null;
            }),
          ),
        person(_sender, 'Sender', _origin, pickup),
        section('How does it end?'),
        RadioGroup<String>(
          groupValue: door ? 'door' : 'collect',
          onChanged: (v) => setState(() {
            _lastMile = v ?? 'door';
            _quote = null;
          }),
          child: Column(children: [
            RadioListTile(
              value: 'door',
              enabled: dest?.doorDelivery ?? true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Door delivery'),
              subtitle: Text(dest == null || dest.doorDelivery ? 'A rider delivers to the recipient' : 'Not available in this city yet'),
            ),
            const RadioListTile(
              value: 'collect',
              contentPadding: EdgeInsets.zero,
              title: Text('Collect at a hub'),
              subtitle: Text('The recipient shows a collection code'),
            ),
          ]),
        ),
        if (!door)
          DropdownButtonFormField<String?>(
            key: ValueKey('wb-dest-hub-$_destination'),
            initialValue: _destHub,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Collection point'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Nearest collection point')),
              for (final h in dest?.collectionHubs ?? const <WaybillHub>[]) DropdownMenuItem(value: h.id, child: Text(h.name)),
            ],
            onChanged: (v) => setState(() {
              _destHub = v;
              _quote = null;
            }),
          ),
        person(_recipient, 'Recipient', _destination ?? '', door),
        section('The package'),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final (id, label, hint) in _sizes)
            ChoiceChip(
              label: Text('$label · $hint'),
              selected: _size == id,
              onSelected: (_) => setState(() {
                _size = id;
                _quote = null;
              }),
            ),
        ]),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('wb-weight'),
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in _categories.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _category == e.key,
              onSelected: (_) => setState(() {
                _category = e.key;
                _quote = null;
              }),
            ),
        ]),
        TextField(controller: _what, maxLength: 200, decoration: const InputDecoration(labelText: 'What is it? (optional)'), onChanged: (_) => _changed()),
        if (door)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _cod,
            title: const Text('Collect cash from my buyer'),
            subtitle: const Text('The rider collects the price at the door; it shows in your wallet.'),
            onChanged: (on) => setState(() {
              _cod = on;
              _quote = null;
            }),
          ),
        if (door && _cod)
          TextField(
            controller: _codAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount to collect (₦)', helperText: 'Up to ₦100,000. A 1.5% fee (min ₦100) is added.'),
            onChanged: (_) => _changed(),
          ),
        if (b != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('${_quote!.details.originCityName} → ${_quote!.details.destinationCityName} (${_quote!.details.weightKg.toStringAsFixed(1)} kg)', b.linehaulFeeKobo),
                if (b.pickupFeeKobo > 0) _row('Rider pickup', b.pickupFeeKobo),
                if (b.deliveryFeeKobo > 0) _row('Door delivery', b.deliveryFeeKobo),
                _row('Booking fee', b.serviceFeeKobo),
                if (b.codFeeKobo > 0) _row('Cash collection fee', b.codFeeKobo),
                _row('VAT (7.5%)', b.vatKobo),
                const Divider(),
                _row('Total', b.totalKobo, bold: true),
                const SizedBox(height: 6),
                Text('Expected ${_quote!.etaText}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'Carried by ${_quote!.details.carrierName}. Hubs and carriers are samples until launch.',
                  style: theme.textTheme.bodySmall,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text('Pay with', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          PaymentMethodPicker(totalKobo: b.totalKobo, value: _method, onChanged: (m) => setState(() => _method = m), offerCash: false),
        ],
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
              ),
            FilledButton(
              key: const ValueKey('waybill-primary'),
              onPressed: _busy ? null : (_quote == null ? () => _price(dest, pickup, door) : _book),
              child: Text(_busy
                  ? 'Please wait…'
                  : _quote == null
                      ? 'See price'
                      : 'Book & pay ${formatNaira(_quote!.breakdown.totalKobo)}${_method == PayMethod.wallet ? ' from wallet' : ''}'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, int kobo, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
          Text(formatNaira(kobo), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        ]),
      );
}
