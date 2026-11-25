import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/payment_picker.dart';
import '../location/address_picker.dart';
import 'cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _line1 = TextEditingController();
  final _phone = TextEditingController();
  final _voucher = TextEditingController();
  String _fulfillment = 'delivery';
  Quote? _quote;
  String? _error;
  bool _busy = false;
  final _orderKey = IdempotencyKey('order');
  // One key per method: switching method after a refusal is a new request, a retry is not.
  final _checkoutKeys = <PayMethod, IdempotencyKey>{};
  PayMethod _method = PayMethod.card;

  /// Exact address from the map picker (search, GPS or a saved address). Without it the neighbourhood centre is used.
  PickedAddress? _picked;
  bool _locating = false;

  /// One tap: the phone's GPS position becomes the delivery address (the server finds the street, or the
  /// nearest neighbourhood when it has no street for that spot).
  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final here = await ref.read(customerLocationProvider).current();
      final lookup = await ref.read(apiProvider).reverseGeocode(here);
      if (!mounted) return;
      if (!lookup.serviceable) {
        setState(() => _error = 'Yummy Chops does not deliver to where you are yet. Search for the address to deliver to.');
        return;
      }
      setState(() {
        _picked = PickedAddress(
          address: lookup.toAddress(pin: here),
          serviceable: true,
          precise: lookup.place.isPrecise,
          placeId: lookup.place.placeId,
        );
        if (lookup.place.isPrecise) _line1.text = lookup.place.formattedAddress;
        _quote = null;
      });
    } on LocationUnavailable catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _line1.dispose();
    _phone.dispose();
    _voucher.dispose();
    super.dispose();
  }

  DeliveryAddress? get _address {
    if (_fulfillment == 'pickup') return null;
    if (_line1.text.trim().length < 3) return null;
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final picked = _picked;
    if (picked != null) return picked.address.copyWith(line1: _line1.text.trim(), contactPhone: phone ?? picked.address.contactPhone);
    final area = ref.read(areaProvider);
    return DeliveryAddress(line1: _line1.text.trim(), area: area.name, location: area.location, contactPhone: phone);
  }

  Future<void> _pickAddress() async {
    final picked = await pickDeliveryAddress(context);
    if (picked == null || !mounted) return;
    setState(() {
      _picked = picked;
      _line1.text = picked.address.line1;
      if (_phone.text.trim().isEmpty && picked.address.contactPhone != null) _phone.text = picked.address.contactPhone!;
      _quote = null;
      _error = null;
    });
  }

  Future<void> _getQuote() async {
    final cart = ref.read(cartProvider);
    if (_fulfillment == 'delivery' && _address == null) {
      setState(() => _error = 'Enter your street address');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final q = await ref.read(apiProvider).quote(
            restaurantId: cart.restaurantId!,
            lines: cart.toLines(),
            fulfillment: _fulfillment,
            address: _address,
            voucher: _voucher.text.trim().toUpperCase(),
          );
      setState(() {
        _quote = q;
        // A new price is a new order: it never goes out with the keys of the last one.
        _orderKey.renew();
        _checkoutKeys.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final quote = _quote;
    if (quote == null) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
      // The key goes with this price and this phone number: a retry keeps it, a changed order gets a new one.
      final order = await _orderKey.send((quote.id, phone), (key) => api.createOrder(quote.id, key, contactPhone: phone));
      final checkout = await _checkoutKeys
          .putIfAbsent(_method, () => IdempotencyKey('checkout'))
          .send(order.id, (key) => api.checkout(order.id, key, provider: _method.provider));
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(walletProvider);
      final url = checkout.authorizationUrl;
      if (url == null) {
        // Wallet and pay-on-delivery orders are placed already: go straight to tracking. An order paid from
        // the wallet is paid now, so its receipt printer comes up; cash is paid at the door.
        if (mounted) context.go('/orders/${order.id}${checkout.provider == 'wallet' ? '?paid=1' : ''}');
        return;
      }
      // Provider-hosted payment page: card data never touches the app.
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      if (mounted) context.go('/orders/${order.id}?ref=${checkout.reference}');
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        // The price is no longer held: the button goes back to "Review total" for a new one.
        if (e.needsNewQuote) _quote = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    if (cart.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Checkout')), body: const Center(child: Text('Your cart is empty')));
    }
    final b = _quote?.breakdown;
    return Scaffold(
      appBar: AppBar(title: Text(cart.restaurantName ?? 'Checkout')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final i in cart.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${i.quantity} × ${i.name}'),
            subtitle: i.selectionLabels.isEmpty ? null : Text(i.selectionLabels.join(' · ')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Remove one',
                onPressed: () {
                  ref.read(cartProvider.notifier).setQuantity(i.key, i.quantity - 1);
                  setState(() => _quote = null);
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(formatNaira(i.unitPriceKobo * i.quantity)),
            ]),
          ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'delivery', label: Text('Delivery'), icon: Icon(Icons.delivery_dining_rounded)),
            ButtonSegment(value: 'pickup', label: Text('Pickup'), icon: Icon(Icons.storefront_rounded)),
          ],
          selected: {_fulfillment},
          onSelectionChanged: (s) => setState(() {
            _fulfillment = s.first;
            _quote = null;
          }),
        ),
        if (_fulfillment == 'delivery') ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(_picked == null ? Icons.add_location_alt_rounded : Icons.location_on_rounded, color: theme.colorScheme.primary),
              title: Text(_picked == null ? 'Pin your exact address' : (_picked!.address.label ?? _picked!.address.area ?? 'Delivery address'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_picked == null
                  ? 'Delivering in ${ref.watch(areaProvider).name}. Search or use your location for a precise pin.'
                  : [_picked!.address.line1, _picked!.address.area].whereType<String>().toSet().join(', ')),
              trailing: Text(_picked == null ? 'Find' : 'Change', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
              onTap: _busy ? null : _pickAddress,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('checkout-use-my-location'),
              onPressed: _busy || _locating ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
              label: const Text('Use my current location'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(controller: _line1, decoration: const InputDecoration(labelText: 'Street address'), onChanged: (_) => setState(() => _quote = null)),
          const SizedBox(height: 8),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone for the rider')),
        ],
        const SizedBox(height: 8),
        TextField(controller: _voucher, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Voucher (optional)')),
        if (ref.watch(myVouchersProvider).asData?.value case final vouchers? when vouchers.isNotEmpty)
          Wrap(spacing: 8, children: [
            for (final v in vouchers)
              ActionChip(
                label: Text('${formatNaira(v.valueKobo)} off · ${v.code}'),
                onPressed: () => setState(() {
                  _voucher.text = v.code;
                  _quote = null;
                }),
              ),
          ]),
        const SizedBox(height: 16),
        if (b != null) ...[
          _row('Subtotal', b.subtotalKobo),
          if (b.deliveryFeeKobo > 0) _row('Delivery', b.deliveryFeeKobo),
          _row('Service fee', b.serviceFeeKobo + b.smallOrderFeeKobo),
          _row('VAT (7.5% on fees)', b.vatKobo),
          if (b.discountKobo > 0) _row('Discount', -b.discountKobo),
          if (b.plusSavingsKobo > 0) _row('Yummy Chops Plus saved you', b.plusSavingsKobo),
          const Divider(),
          _row('Total', b.totalKobo, bold: true),
          Text('Arrives around ${formatLagosTime(_quote!.estimatedDeliveryAt)} · price held until ${formatLagosTime(_quote!.expiresAt)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Pay with', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          PaymentMethodPicker(
            totalKobo: b.totalKobo,
            value: _method,
            onChanged: (m) => setState(() => _method = m),
            cashReason: _fulfillment == 'pickup' ? 'Only for delivery orders' : null,
          ),
        ],
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _busy ? null : (_quote == null ? _getQuote : _pay),
            child: Text(_busy
                ? 'Please wait…'
                : _quote == null
                    ? 'Review total'
                    : switch (_method) {
                        PayMethod.cash => 'Place order · pay ${formatNaira(_quote!.breakdown.totalKobo)} on delivery',
                        PayMethod.wallet => 'Pay ${formatNaira(_quote!.breakdown.totalKobo)} from wallet',
                        PayMethod.card => 'Pay ${formatNaira(_quote!.breakdown.totalKobo)}',
                      }),
          ),
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
