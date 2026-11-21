import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/components.dart';

// Screens the website already had and the app did not: the help centre, the two sign-ups (sell on Yummy Chops,
// ride with Yummy Chops) and tracking a package by its number. The words match the website's pages.

/// Help centre: common questions, privacy and terms (the website's /help).
const helpFaqs = [
  (
    'How are fees calculated?',
    'Delivery fees depend on distance and are shown before you pay. A 5% service fee (min ₦100, max ₦1,500) applies, '
        'plus a small-order fee under ₦3,000. VAT (7.5%) applies to platform fees. The total you approve is exactly '
        'what you pay.'
  ),
  (
    'Is my payment safe?',
    'Payments are processed on a secure page by our payment partners. Yummy Chops never sees your card details and '
        'will never ask for your PIN or OTP.'
  ),
  (
    "What if the restaurant can't fulfil my order?",
    "If a restaurant rejects or doesn't confirm your paid order in time, you're refunded in full automatically."
  ),
  (
    'Something was missing or wrong',
    'Open the order and report an issue within 48 hours. Our team reviews it and refunds approved amounts to your '
        'original payment method.'
  ),
  (
    'What is the delivery code?',
    'A 4-digit code shown on your order. Give it to the rider only when you have your order: it confirms the delivery.'
  ),
  (
    'Can I cancel?',
    'Yes, until the restaurant accepts your order. After that the kitchen has started cooking: contact support.'
  ),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget block(String title, String body) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Help centre')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        for (final (q, a) in helpFaqs)
          ExpansionTile(
            title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(a)],
          ),
        block(
          'Privacy',
          'We process your data under the Nigeria Data Protection Act 2023 to deliver orders, prevent fraud and, with '
              'your consent, personalise recommendations. You can download your data from your profile or ask us to '
              'delete it.',
        ),
        block(
          'Terms',
          'Orders are prepared by independent partner restaurants and shops. Prices include VAT where applicable. '
              'Full terms will be published before launch.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: () => context.push('/assistant'),
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Ask Yummy'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/support'),
              icon: const Icon(Icons.headset_mic_outlined),
              label: const Text('Contact support'),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// A form field with the app's spacing.
class _Field extends StatelessWidget {
  const _Field(this.controller, this.label, {this.hint, this.keyboard, this.validator, this.maxLength});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  final String? Function(String value)? validator;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label, helperText: hint, counterText: ''),
        validator: validator == null ? null : (v) => validator!((v ?? '').trim()),
      ),
    );
  }
}

String? _atLeast(String value, int n, String message) => value.length < n ? message : null;

/// What the applicant sees once the application is in.
class _Received extends StatelessWidget {
  const _Received({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.check_circle_outline_rounded,
      title: title,
      body: body,
      action: FilledButton(onPressed: () => context.go('/'), child: const Text('Back to Home')),
    );
  }
}

/// The kinds of business that can sell on Yummy Chops (ADR-0025): the API's service id, the name in the list, and an
/// example of what such a shop lists under "What you sell".
const businessKinds = [
  (id: 'food', label: 'Restaurant (Order Food)', example: 'Nigerian, grills'),
  (id: 'pharmacy', label: 'Pharmacy', example: 'Pain relief, vitamins, first aid'),
  (id: 'beauty', label: 'Beauty & Skin Care shop', example: 'Skincare, hair care, make-up'),
  (id: 'grocery', label: 'Supermarket or store (Shop & Groceries)', example: 'Drinks, household, baby'),
  (id: 'market', label: 'Market shopper (Buy Foodstuff)', example: 'Foodstuff, pepper & vegetables, meat & fish'),
];

/// "Add your business": a restaurant or shop of any kind applies to sell on Yummy Chops (the website's
/// /partner-with-us). A pharmacy also gives its PCN premises licence number.
class BusinessApplyScreen extends ConsumerStatefulWidget {
  const BusinessApplyScreen({super.key});

  @override
  ConsumerState<BusinessApplyScreen> createState() => _BusinessApplyState();
}

class _BusinessApplyState extends ConsumerState<BusinessApplyScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sells = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _cac = TextEditingController();
  final _bank = TextEditingController();
  final _accountName = TextEditingController();
  final _last4 = TextEditingController();
  final _licence = TextEditingController();
  String _kind = 'food';
  Area? _area;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _sells, _address, _contact, _phone, _cac, _bank, _accountName, _last4, _licence]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(Area area) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).applyAsBusiness({
        'vertical': _kind,
        if (_kind == 'pharmacy') 'pcn_licence_number': _licence.text.trim(),
        'business_name': _name.text.trim(),
        'cac_number': _cac.text.trim(),
        'contact_name': _contact.text.trim(),
        'contact_phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'area': area.name,
        'location': area.location.toJson(),
        'cuisines': FoodPreferences.split(_sells.text),
        'bank_name': _bank.text.trim(),
        'bank_account_name': _accountName.text.trim(),
        'bank_account_last4': _last4.text.trim(),
      });
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final areas = ref.watch(areasProvider).value ?? [ref.watch(areaProvider)];
    final Area area = _area ?? ref.watch(areaProvider);
    final kind = businessKinds.firstWhere((k) => k.id == _kind);
    return Scaffold(
      appBar: AppBar(title: const Text('Add your business')),
      body: _sent
          ? const _Received(
              title: 'Application received',
              body: 'Our partnerships team will review your documents within 2 business days.',
            )
          : Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Text('Grow your business with Yummy Chops', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('• Reach customers across Lagos and Enugu, including through Yummy, our AI assistant.'),
                const Text('• Live order board, product tools, sales insights and demand forecasts.'),
                const Text('• Transparent commission and weekly settlement statements.'),
                const SizedBox(height: 8),
                Text('We verify every partner (CAC registration, bank details and, for pharmacies, the PCN premises licence) before going live.',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('business-kind'),
                    isExpanded: true,
                    initialValue: _kind,
                    decoration: const InputDecoration(labelText: 'Kind of business'),
                    items: [for (final k in businessKinds) DropdownMenuItem(value: k.id, child: Text(k.label))],
                    onChanged: (v) => setState(() => _kind = v ?? 'food'),
                  ),
                ),
                _Field(_name, 'Business name', validator: (v) => _atLeast(v, 2, 'Enter the name of your restaurant or shop'), maxLength: 80),
                _Field(_sells, 'What you sell', hint: 'Comma separated, e.g. ${kind.example}', validator: (v) => _atLeast(v, 2, 'List at least one')),
                if (_kind == 'pharmacy')
                  _Field(_licence, 'PCN premises licence number',
                      hint: 'From the Pharmacists Council of Nigeria',
                      validator: (v) => _atLeast(v, 4, 'Enter your PCN premises licence number'),
                      maxLength: 30),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<Area>(
                    isExpanded: true, // a long name is cut short instead of running past the edge
                    initialValue: areas.contains(area) ? area : areas.first,
                    decoration: const InputDecoration(labelText: 'Area'),
                    items: [for (final a in areas) DropdownMenuItem(value: a, child: Text('${a.name}, ${a.cityName}'))],
                    onChanged: (a) => setState(() => _area = a),
                  ),
                ),
                _Field(_address, 'Street address', validator: (v) => _atLeast(v, 5, 'Enter the street address'), maxLength: 200),
                _Field(_contact, 'Contact name', validator: (v) => _atLeast(v, 2, 'Enter a contact name'), maxLength: 80),
                _Field(_phone, 'Contact phone', keyboard: TextInputType.phone, validator: (v) => _atLeast(v, 7, 'Enter a phone number'), maxLength: 20),
                _Field(_cac, 'CAC number', validator: (v) => _atLeast(v, 4, 'Enter your CAC registration number'), maxLength: 20),
                _Field(_bank, 'Bank', validator: (v) => _atLeast(v, 2, 'Enter the bank'), maxLength: 60),
                _Field(_accountName, 'Account name', validator: (v) => _atLeast(v, 2, 'Enter the account name'), maxLength: 80),
                _Field(
                  _last4,
                  'Account number (last 4)',
                  keyboard: TextInputType.number,
                  maxLength: 4,
                  validator: (v) => RegExp(r'^\d{4}$').hasMatch(v) ? null : 'Last 4 digits only',
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                FilledButton(onPressed: _busy ? null : () => _submit(area), child: Text(_busy ? 'Sending…' : 'Send application')),
              ]),
            ),
    );
  }
}

/// "Become a rider" (the website's /ride).
class RiderApplyScreen extends ConsumerStatefulWidget {
  const RiderApplyScreen({super.key});

  @override
  ConsumerState<RiderApplyScreen> createState() => _RiderApplyState();
}

class _RiderApplyState extends ConsumerState<RiderApplyScreen> {
  static const _vehicles = {'motorcycle': 'Motorcycle', 'bicycle': 'Bicycle', 'car': 'Car'};
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  final _licence = TextEditingController();
  String _vehicle = 'motorcycle';
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _plate, _licence]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).applyAsRider({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'vehicle': _vehicle,
        if (_plate.text.trim().isNotEmpty) 'plate_number': _plate.text.trim(),
        if (_licence.text.trim().isNotEmpty) 'licence_number': _licence.text.trim(),
        'city': ref.read(areaProvider).cityName,
      });
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Become a rider')),
      body: _sent
          ? const _Received(
              title: 'Thanks for applying',
              body: "We'll verify your identity and vehicle documents and contact you.",
            )
          : Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Text('Ride with Yummy Chops', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Flexible hours, transparent earnings per delivery, and withdrawals to your bank.'),
                const SizedBox(height: 16),
                _Field(_name, 'Full name', validator: (v) => _atLeast(v, 2, 'Enter your full name'), maxLength: 80),
                _Field(_phone, 'Phone', keyboard: TextInputType.phone, validator: (v) => _atLeast(v, 7, 'Enter your phone number'), maxLength: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // a long name is cut short instead of running past the edge
                    initialValue: _vehicle,
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                    items: [for (final v in _vehicles.entries) DropdownMenuItem(value: v.key, child: Text(v.value))],
                    onChanged: (v) => setState(() => _vehicle = v ?? 'motorcycle'),
                  ),
                ),
                _Field(_plate, 'Plate number', hint: 'Optional', maxLength: 20),
                _Field(_licence, "Driver's licence number", hint: 'Optional', maxLength: 30),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Sending…' : 'Apply to ride')),
              ]),
            ),
    );
  }
}

/// "Track a package": anyone with a tracking number can follow an interstate waybill (the website's /track).
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key, this.code});
  final String? code;

  @override
  ConsumerState<TrackScreen> createState() => _TrackState();
}

class _TrackState extends ConsumerState<TrackScreen> {
  late final _code = TextEditingController(text: widget.code ?? '');
  WaybillTracking? _found;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if ((widget.code ?? '').isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _track());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Enter the tracking number on your waybill, e.g. GMW2ABC3DEF');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _found = null;
    });
    try {
      final found = await ref.read(apiProvider).trackWaybill(code);
      if (mounted) setState(() => _found = found);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.status == 404 ? "We couldn't find that tracking number. Check it and try again." : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = _found;
    return Scaffold(
      appBar: AppBar(title: const Text('Track a package')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Enter the tracking number of an interstate waybill. You do not need to sign in.'),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
          decoration: const InputDecoration(labelText: 'Tracking number', hintText: 'GMW…'),
          onSubmitted: (_) => _track(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _track,
          icon: const Icon(Icons.search_rounded),
          label: Text(_busy ? 'Looking…' : 'Track'),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
        if (t != null)
          Card(
            margin: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.local_shipping_rounded),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${t.origin} → ${t.destination}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  SelectableText(t.trackingCode, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ]),
                const SizedBox(height: 6),
                Text(t.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (!t.delivered) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Expected ${t.etaText}')),
                const SizedBox(height: 8),
                for (final m in t.milestones.reversed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.circle, size: 10, color: m == t.milestones.last ? theme.colorScheme.primary : theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${m.label} · ${formatLagosDateTime(m.at)}${m.place == null ? '' : ' · ${m.place}'}')),
                    ]),
                  ),
              ]),
            ),
          ),
      ]),
    );
  }
}
