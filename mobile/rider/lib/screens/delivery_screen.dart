import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';

final _deliveryProvider = FutureProvider.family<Order, String>((ref, id) async {
  final list = await ref.watch(apiProvider).activeDeliveries();
  return list.firstWhere(
    (o) => o.id == id,
    orElse: () => throw ApiException(
      404,
      'not_found',
      'This delivery is no longer active',
    ),
  );
});

/// Opens turn-by-turn navigation in the Google Maps app (no API key involved).
Future<void> navigateTo(GeoPoint p) => launchUrl(navigationUri(p), mode: LaunchMode.externalApplication);

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    // Keep the job current while the rider waits (the kitchen marks the food ready, the order is cancelled...).
    _refresh = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_busy) ref.invalidate(_deliveryProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _act(Future<Order> Function(GudMealApi api) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action(ref.read(apiProvider));
      ref.invalidate(_deliveryProvider(widget.orderId));
      ref.invalidate(activeDeliveriesProvider);
      if (updated.status == 'delivered' || updated.status == 'completed') {
        ref.invalidate(earningsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivered — well done!')),
          );
          context.go('/');
        }
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = ref.watch(_deliveryProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: delivery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (o) {
          final parcel = o.vertical == 'parcel' ? o.parcel : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '#${o.shortCode} · ${statusLabel(o.status)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (parcel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(
                    avatar: const Icon(Icons.inventory_2_rounded, size: 18),
                    label: Text(
                      o.legKind == null
                          ? 'Package · ${parcel.size} · ${parcel.category}'
                          : 'Interstate · ${o.legKind == 'first_mile' ? 'to the hub' : 'from the hub'} · ${parcel.size}',
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(
                    parcel == null
                        ? Icons.storefront_rounded
                        : Icons.trip_origin_rounded,
                  ),
                  title: Text(
                    parcel == null
                        ? o.restaurantName
                        : 'Pickup: ${parcel.pickup.name}',
                  ),
                  subtitle: Text(
                    [
                      o.restaurantAddress ?? '',
                      if (parcel?.pickup.instructions != null)
                        parcel!.pickup.instructions!,
                    ].join(' · '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (parcel != null)
                        _CallButton(
                          phone: parcel.pickup.phone,
                          who: parcel.pickup.name,
                        ),
                      if (o.restaurantLocation != null)
                        IconButton(
                          tooltip: 'Navigate',
                          icon: const Icon(Icons.navigation_rounded),
                          onPressed: () => navigateTo(o.restaurantLocation!),
                        ),
                    ],
                  ),
                ),
              ),
              if (o.deliveryAddress != null && parcel == null) _CustomerCard(order: o),
              if (o.deliveryAddress != null && parcel != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.home_rounded),
                    title: Text('Drop-off: ${parcel.dropoff.name}'),
                    subtitle: Text(
                      [
                        o.deliveryAddress!.line1,
                        o.deliveryAddress!.area,
                        o.deliveryAddress!.instructions,
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CallButton(
                          phone: parcel.dropoff.phone,
                          who: parcel.dropoff.name,
                        ),
                        IconButton(
                          tooltip: 'Navigate',
                          icon: const Icon(Icons.navigation_rounded),
                          onPressed: () =>
                              navigateTo(o.deliveryAddress!.location),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (parcel == null)
                Text(
                  'Items: ${o.items.isNotEmpty ? o.items.map((i) => '${i.quantity}× ${i.name}').join(', ') : o.lines.map((l) => '${l.quantity}× ${l.name}').join(', ')}',
                )
              else if (parcel.description.isNotEmpty)
                Text('Contents: ${parcel.description}'),
              Text(
                'You earn ${formatNaira(o.riderPayKobo)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (parcel == null &&
                  o.status == 'rider_assigned' &&
                  o.readyAt == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(o.vertical == 'food'
                      ? 'The kitchen is still preparing this order.'
                      : 'The shop is still packing this order.'),
                ),
              const SizedBox(height: 20),
              if (o.status == 'rider_assigned')
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act((api) => api.pickup(o.id)),
                  child: Text(
                    parcel == null ? 'Confirm pickup' : 'Package collected',
                  ),
                ),
              if (o.status == 'picked_up')
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act((api) => api.inTransit(o.id)),
                  child: Text(
                    parcel == null
                        ? 'Start trip to customer'
                        : 'Start trip to recipient',
                  ),
                ),
              if (o.collectCashKobo > 0)
                Card(
                  key: const ValueKey('collect-cash'),
                  color: const Color(0xFFFFF4D6),
                  margin: const EdgeInsets.only(top: 16),
                  child: ListTile(
                    leading: const Icon(Icons.payments_rounded),
                    title: Text(
                      'Collect ${formatNaira(o.collectCashKobo)} in cash',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      parcel?.codAmountKobo != null && o.paymentMethod != 'cash'
                          ? 'Cash on delivery for ${parcel!.pickup.name}: collect it from ${parcel.dropoff.name} before handing over the package.'
                          : 'The customer pays on delivery. Collect the cash before handing over the order.',
                    ),
                  ),
                ),
              if (o.hubHandover && (o.status == 'picked_up' || o.status == 'in_transit'))
                const Card(
                  key: ValueKey('hub-handover'),
                  margin: EdgeInsets.only(top: 16),
                  child: ListTile(
                    leading: Icon(Icons.warehouse_rounded),
                    title: Text('Hand the package to the hub staff', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('They scan it in the hub console; this job then closes and you are paid.'),
                  ),
                ),
              if (!o.hubHandover && (o.status == 'picked_up' || o.status == 'in_transit'))
                DeliveryCodeForm(
                  controller: _code,
                  busy: _busy,
                  cashToCollectKobo: o.collectCashKobo,
                  onSubmit: (code) => _act(
                    (api) => api.deliver(o.id, code, cashCollected: o.collectCashKobo > 0),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A WhatsApp chat with this number, written as +234…, 234… or a local 0… number.
Uri whatsAppUri(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '234${digits.substring(1)}';
  return Uri.parse('https://wa.me/$digits');
}

/// Who the order is for and how to reach them, shown once the rider has accepted the job. The API sends the
/// customer's number only while the delivery is in progress.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress!;
    final phone = (address.contactPhone ?? '').trim();
    final name = order.customerName ?? 'Customer';
    final where = [address.label, address.line1, address.area, address.city]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .join(', ');
    final note = (address.instructions ?? '').trim();
    return Card(
      key: const ValueKey('customer-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Detail(icon: Icons.home_rounded, text: where),
            if (note.isNotEmpty) _Detail(icon: Icons.sticky_note_2_rounded, text: 'Note: $note'),
            if (phone.isNotEmpty) _Detail(icon: Icons.phone_rounded, text: phone),
            _Detail(
              icon: Icons.payments_rounded,
              text: order.collectCashKobo > 0
                  ? 'Pays ${formatNaira(order.collectCashKobo)} in cash on delivery'
                  : 'Paid online: nothing to collect',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (phone.isNotEmpty) ...[
                  _CallButton(phone: phone, who: name),
                  IconButton(
                    tooltip: 'WhatsApp $name',
                    icon: const Icon(Icons.chat_rounded),
                    onPressed: () => launchUrl(whatsAppUri(phone), mode: LaunchMode.externalApplication),
                  ),
                ],
                IconButton(
                  tooltip: 'Navigate',
                  icon: const Icon(Icons.navigation_rounded),
                  onPressed: () => navigateTo(address.location),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Riders call customers, senders and recipients of packages (numbers come from the order or the booking).
class _CallButton extends StatelessWidget {
  const _CallButton({required this.phone, required this.who});
  final String phone;
  final String who;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Call $who',
    icon: const Icon(Icons.call_rounded),
    onPressed: () =>
        launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', ''))),
  );
}

/// 4-digit code the customer reads out on arrival. Validated locally, verified by the API (5 attempts max).
/// When there is cash to collect, the rider must also confirm they took it (the amount comes from the server).
class DeliveryCodeForm extends StatefulWidget {
  const DeliveryCodeForm({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.busy = false,
    this.cashToCollectKobo = 0,
  });
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool busy;
  final int cashToCollectKobo;

  @override
  State<DeliveryCodeForm> createState() => _DeliveryCodeFormState();
}

class _DeliveryCodeFormState extends State<DeliveryCodeForm> {
  bool _cashTaken = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final needsCash = widget.cashToCollectKobo > 0;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 12,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: "Customer's delivery code",
                counterText: '',
              ),
            ),
            if (needsCash)
              CheckboxListTile(
                key: const ValueKey('cash-taken'),
                contentPadding: EdgeInsets.zero,
                value: _cashTaken,
                onChanged: (v) => setState(() => _cashTaken = v ?? false),
                title: Text('I collected ${formatNaira(widget.cashToCollectKobo)} in cash'),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: widget.busy || value.text.length != 4 || (needsCash && !_cashTaken)
                  ? null
                  : () => widget.onSubmit(value.text),
              child: const Text('Complete delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
