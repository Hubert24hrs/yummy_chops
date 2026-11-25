import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../ui/illustrations.dart';
import '../../ui/payment_picker.dart';

const _sizes = [
  ('small', 'Small', 'Documents, phone, shoes · up to 5 kg', Icons.mail_outline_rounded),
  ('medium', 'Medium', 'Shoebox to small carton · up to 10 kg', Icons.inventory_2_outlined),
  ('large', 'Large', 'Bulky but fits a bike · up to 20 kg', Icons.luggage_outlined),
];
const _categories = {
  'documents': 'Documents',
  'clothing': 'Clothing',
  'electronics': 'Electronics',
  'food': 'Food',
  'cosmetics': 'Cosmetics',
  'household': 'Household',
  'other': 'Other',
};
final _phone = RegExp(r'^\+?[0-9 ]{7,20}$');

/// Package Delivery: price a bike delivery within Lagos or Enugu, now or scheduled, then book and pay.
class ParcelScreen extends ConsumerStatefulWidget {
  const ParcelScreen({super.key});

  @override
  ConsumerState<ParcelScreen> createState() => _ParcelScreenState();
}

class _StopFields {
  final line = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();
  Area? area;

  void dispose() {
    line.dispose();
    name.dispose();
    phone.dispose();
    notes.dispose();
  }
}

class _ParcelScreenState extends ConsumerState<ParcelScreen> {
  final _pickup = _StopFields();
  final _dropoff = _StopFields();
  final _what = TextEditingController();
  String _size = 'small';
  String _category = 'documents';
  DateTime? _when;
  ParcelQuote? _quote;
  String? _error;
  bool _busy = false;
  final _scroll = ScrollController();
  final _orderKey = IdempotencyKey('parcel');
  final _checkoutKeys = <PayMethod, IdempotencyKey>{};
  PayMethod _method = PayMethod.card;
  bool _cod = false;
  final _codAmount = TextEditingController();

  int get _codKobo => ((double.tryParse(_codAmount.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) * 100).round();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value ?? ref.read(authRepositoryProvider).currentUser;
    _pickup.name.text = user?.name ?? '';
    _pickup.phone.text = user?.phone ?? '';
    _pickup.area = ref.read(areaProvider);
  }

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _what.dispose();
    _codAmount.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _quote = null);

  String? _validate() {
    for (final (label, s) in [('pickup', _pickup), ('drop-off', _dropoff)]) {
      if (s.area == null) return 'Choose the $label area';
      if (s.line.text.trim().length < 3) return 'Enter the $label street address';
      if (s.name.text.trim().length < 2) return 'Enter the ${label == 'pickup' ? 'sender' : 'recipient'}’s name';
      if (!_phone.hasMatch(s.phone.text.trim())) return 'Enter a valid ${label == 'pickup' ? 'sender' : 'recipient'} phone number';
    }
    if (_pickup.area!.city != _dropoff.area!.city) {
      return 'Pickup and drop-off must be in the same city. Interstate waybill is coming soon.';
    }
    if (_cod && _codKobo < 100) return 'Enter the amount the rider should collect from your buyer';
    return null;
  }

  ParcelStop _stop(_StopFields s) => ParcelStop(
        name: s.name.text.trim(),
        phone: s.phone.text.trim(),
        line1: s.line.text.trim(),
        area: s.area!.name,
        city: s.area!.cityName,
        location: s.area!.location,
        instructions: s.notes.text.trim().isEmpty ? null : s.notes.text.trim(),
      );

  Future<void> _price() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final q = await ref.read(apiProvider).parcelQuote(
            pickup: _stop(_pickup),
            dropoff: _stop(_dropoff),
            size: _size,
            category: _category,
            description: _what.text.trim(),
            scheduledFor: _when,
            codAmountKobo: _cod ? _codKobo : null,
          );
      setState(() {
        _quote = q;
        // A new price is a new booking: it never goes out with the keys of the last one.
        _orderKey.renew();
        _checkoutKeys.clear();
      });
      // Bring the price breakdown into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
        }
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
      final order = await _orderKey.send(quote.id, (key) => api.createParcel(quote.id, key));
      final checkout = await _checkoutKeys
          .putIfAbsent(_method, () => IdempotencyKey('checkout'))
          .send(order.id, (key) => api.checkout(order.id, key, provider: _method.provider));
      ref.invalidate(walletProvider);
      final url = checkout.authorizationUrl;
      if (url == null) {
        if (mounted) context.go('/orders/${order.id}?paid=1'); // paid from the wallet: the receipt comes up
        return;
      }
      // Provider-hosted payment page: card details never touch the app.
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

  Future<void> _schedule() async {
    final now = DateTime.now();
    final day = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 6)), initialDate: now);
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0), helpText: 'Pickup time (7am – 9pm)');
    if (time == null) return;
    setState(() {
      _when = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      _quote = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final areas = ref.watch(areasProvider).value ?? const [...lagosAreas, ...enuguAreas];
    final b = _quote?.breakdown;
    return Scaffold(
      appBar: AppBar(title: const Text('Package Delivery')),
      body: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(GmRadius.lg)),
          child: const Row(children: [
            SizedBox(width: 84, height: 70, child: CustomPaint(painter: ParcelIllustration())),
            SizedBox(width: 12),
            Expanded(child: Text('Send anything that fits on a bike, across Lagos or Enugu. You see the exact price before you pay.')),
          ]),
        ),
        _section(context, 'Pickup', Icons.trip_origin_rounded),
        _stopForm(_pickup, areas, who: 'Sender'),
        _section(context, 'Drop-off', Icons.location_on_rounded),
        _stopForm(_dropoff, areas, who: 'Recipient'),
        _section(context, 'What are you sending?', Icons.inventory_2_outlined),
        for (final (id, label, hint, icon) in _sizes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _size == id ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GmRadius.md),
                side: BorderSide(color: _size == id ? brandRed : theme.colorScheme.outline, width: _size == id ? 2 : 1),
              ),
              child: ListTile(
                leading: Icon(icon),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(hint),
                trailing: _size == id ? Icon(Icons.check_circle_rounded, color: brandRed) : null,
                onTap: () => setState(() {
                  _size = id;
                  _quote = null;
                }),
              ),
            ),
          ),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in _categories.entries)
            ChoiceChip(label: Text(e.value), selected: _category == e.key, onSelected: (_) => setState(() {
                  _category = e.key;
                  _quote = null;
                })),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _what, maxLength: 200, decoration: const InputDecoration(labelText: 'Short description (optional)'), onChanged: (_) => _changed()),
        _section(context, 'When?', Icons.schedule_rounded),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Now'), icon: Icon(Icons.bolt_rounded)),
            ButtonSegment(value: true, label: Text('Schedule'), icon: Icon(Icons.event_rounded)),
          ],
          selected: {_when != null},
          onSelectionChanged: (s) => s.first ? _schedule() : setState(() {
            _when = null;
            _quote = null;
          }),
        ),
        if (_when != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Pickup ${MaterialLocalizations.of(context).formatMediumDate(_when!)} at ${TimeOfDay.fromDateTime(_when!).format(context)}',
                style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: [
            SwitchListTile(
              key: const ValueKey('cod-switch'),
              value: _cod,
              secondary: const Icon(Icons.payments_outlined),
              title: const Text('Collect cash from my buyer', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('The rider collects the price at drop-off. Move it to your wallet or withdraw it to your bank.'),
              onChanged: (on) => setState(() {
                _cod = on;
                _quote = null;
              }),
            ),
            if (_cod)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  key: const ValueKey('cod-amount'),
                  controller: _codAmount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount to collect (₦)',
                    helperText: 'Up to ₦100,000. A 1.5% collection fee (min ₦100) is added to your booking.',
                  ),
                  onChanged: (_) => _changed(),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            key: const ValueKey('interstate-link'),
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Sending to another city?', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Book an interstate waybill: Lagos, Enugu, Abuja and Port Harcourt.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/send?mode=interstate'),
          ),
        ),
        if (b != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _row('Delivery (${_quote!.distanceKm.toStringAsFixed(1)} km, $_size)', b.deliveryFeeKobo),
                _row('Booking fee', b.serviceFeeKobo),
                if (b.codFeeKobo > 0) _row('Cash collection fee', b.codFeeKobo),
                _row('VAT (7.5%)', b.vatKobo),
                const Divider(),
                _row('Total', b.totalKobo, bold: true),
                if ((_quote!.details.codAmountKobo ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'The rider collects ${formatNaira(_quote!.details.codAmountKobo)} from ${_quote!.details.dropoff.name} for you.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${_quote!.scheduledFor != null ? 'Scheduled pickup' : 'Rider assigned after payment'} · delivered around ${formatLagosTime(_quote!.estimatedDeliveryAt)} · price held until ${formatLagosTime(_quote!.expiresAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text('Pay with', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          PaymentMethodPicker(
            totalKobo: b.totalKobo,
            value: _method,
            onChanged: (m) => setState(() => _method = m),
            offerCash: false,
          ),
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
              key: const ValueKey('parcel-primary'),
              onPressed: _busy ? null : (_quote == null ? _price : _book),
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

  Widget _stopForm(_StopFields s, List<Area> areas, {required String who}) {
    return Column(children: [
      DropdownButtonFormField<Area>(
        initialValue: s.area != null && areas.contains(s.area) ? s.area : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Area'),
        items: [
          for (final a in areas) DropdownMenuItem(value: a, child: Text('${a.name}, ${a.cityName}')),
        ],
        onChanged: (a) => setState(() {
          s.area = a;
          _quote = null;
        }),
      ),
      const SizedBox(height: 8),
      TextField(controller: s.line, decoration: const InputDecoration(labelText: 'Street address and landmark'), onChanged: (_) => _changed()),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: s.name, decoration: InputDecoration(labelText: '$who name'), onChanged: (_) => _changed())),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: s.phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: '$who phone'),
            onChanged: (_) => _changed(),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      TextField(controller: s.notes, decoration: const InputDecoration(labelText: 'Instructions for the rider (optional)')),
    ]);
  }

  Widget _section(BuildContext context, String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Row(children: [
          Icon(icon, size: 20, color: brandRed),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _row(String label, int kobo, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
          Text(formatNaira(kobo), style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        ]),
      );
}
