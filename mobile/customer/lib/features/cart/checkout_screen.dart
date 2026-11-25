import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/payment_picker.dart';
import '../location/address_picker.dart';
import 'cart_controller.dart';

/// The cart: items from any number of shops, grouped by shop. Each shop becomes its own order and one payment
/// covers them all (`POST /v1/checkouts`).
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

  /// One price per shop in the cart, in the cart's shop order. Null until "Review total".
  List<(CartShop, Quote)>? _quotes;
  String? _error;
  bool _busy = false;

  /// One key per shop's order; a new price is a new set of orders.
  final _orderKeys = <String, IdempotencyKey>{};

  /// Orders already placed for a (quote id, phone): paying again (another method, a dropped connection)
  /// pays the same orders instead of placing new ones.
  final _placed = <(String, String?), Order>{};

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
        _quotes = null;
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
      _quotes = null;
      _error = null;
    });
  }

  /// What the customer pays: every shop's total.
  int get _totalKobo => (_quotes ?? const <(CartShop, Quote)>[]).fold(0, (n, q) => n + q.$2.breakdown.totalKobo);

  Future<void> _getQuote() async {
    final shops = ref.read(cartProvider).shops;
    if (_fulfillment == 'delivery' && _address == null) {
      setState(() => _error = 'Enter your street address');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final voucher = _voucher.text.trim().toUpperCase();
      final quotes = <(CartShop, Quote)>[];
      for (final (i, shop) in shops.indexed) {
        try {
          final q = await api.quote(
            restaurantId: shop.restaurantId,
            lines: shop.toLines(),
            fulfillment: _fulfillment,
            address: _address,
            // A voucher is one discount: it goes with the first shop's order only.
            voucher: i == 0 ? voucher : null,
          );
          quotes.add((shop, q));
        } on ApiException catch (e) {
          throw shops.length > 1 ? ApiException(e.status, e.code, '${shop.restaurantName}: ${e.message}', e.details) : e;
        }
      }
      if (!mounted) return;
      setState(() {
        _quotes = quotes;
        // A new price is a new order: it never goes out with the keys of the last one.
        _orderKeys.clear();
        _placed.clear();
        _checkoutKeys.clear();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final quotes = _quotes;
    if (quotes == null) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
      // One order per shop. Each key goes with its price and this phone number: a retry keeps it, a changed
      // order gets a new one.
      final ids = <String>[];
      for (final (shop, quote) in quotes) {
        final order = _placed[(quote.id, phone)] ??= await _orderKeys
            .putIfAbsent(shop.restaurantId, () => IdempotencyKey('order'))
            .send((quote.id, phone), (key) => api.createOrder(quote.id, key, contactPhone: phone));
        ids.add(order.id);
      }
      // ONE payment for every shop's order.
      final checkout = await _checkoutKeys
          .putIfAbsent(_method, () => IdempotencyKey('checkout'))
          .send(ids.join(','), (key) => api.checkoutMany(ids, key, provider: _method.provider));
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(walletProvider);
      final first = ids.first;
      final url = checkout.authorizationUrl;
      if (url == null) {
        // Wallet and pay-on-delivery orders are placed already: go straight to tracking. An order paid from
        // the wallet is paid now, so its receipt printer comes up; cash is paid at the door. Several orders are
        // each listed on Orders.
        if (!mounted) return;
        if (ids.length > 1) {
          context.go('/orders');
        } else {
          context.go('/orders/$first${checkout.provider == 'wallet' ? '?paid=1' : ''}');
        }
        return;
      }
      // Provider-hosted payment page: card data never touches the app. The order screen verifies the reference,
      // which marks every order of this payment paid.
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      if (mounted) context.go('/orders/$first?ref=${checkout.reference}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        // The price is no longer held: the button goes back to "Review total" for a new one.
        if (e.needsNewQuote) _quotes = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Any change to the cart is a new price.
  void _changeCart(void Function(CartController cart) change) {
    change(ref.read(cartProvider.notifier));
    setState(() => _quotes = null);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    ref.listen(cartProvider, (_, _) {
      if (_quotes != null) setState(() => _quotes = null);
    });
    final theme = Theme.of(context);
    if (cart.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Your cart')), body: const Center(child: Text('Your cart is empty')));
    }
    final shops = cart.shops;
    final quotes = _quotes;
    final total = _totalKobo;
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final shop in shops) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(children: [
              Icon(Icons.storefront_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(shop.restaurantName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            ]),
          ),
          for (final i in shop.items)
            Padding(
              key: ValueKey('cart-line-${i.key}'),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (i.selectionLabels.isNotEmpty) Text(i.selectionLabels.join(' · '), style: theme.textTheme.bodySmall),
                    Text(formatNaira(i.unitPriceKobo * i.quantity), style: theme.textTheme.bodySmall),
                  ]),
                ),
                IconButton(
                  tooltip: 'Remove one',
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : () => _changeCart((c) => c.setQuantity(i.key, i.quantity - 1)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${i.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: 'Add one',
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy || i.quantity >= 50 ? null : () => _changeCart((c) => c.setQuantity(i.key, i.quantity + 1)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : () => _changeCart((c) => c.remove(i.key)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ]),
            ),
          const Divider(),
        ],
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'delivery', label: Text('Delivery'), icon: Icon(Icons.delivery_dining_rounded)),
            ButtonSegment(value: 'pickup', label: Text('Pickup'), icon: Icon(Icons.storefront_rounded)),
          ],
          selected: {_fulfillment},
          onSelectionChanged: (s) => setState(() {
            _fulfillment = s.first;
            _quotes = null;
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
          TextField(controller: _line1, decoration: const InputDecoration(labelText: 'Street address'), onChanged: (_) => setState(() => _quotes = null)),
          const SizedBox(height: 8),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
        ],
        const SizedBox(height: 8),
        TextField(controller: _voucher, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Voucher (optional)')),
        if (shops.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text("Voucher applies to one shop's order (${shops.first.restaurantName})", style: theme.textTheme.bodySmall),
          ),
        if (ref.watch(myVouchersProvider).asData?.value case final vouchers? when vouchers.isNotEmpty)
          Wrap(spacing: 8, children: [
            for (final v in vouchers)
              ActionChip(
                label: Text('${formatNaira(v.valueKobo)} off · ${v.code}'),
                onPressed: () => setState(() {
                  _voucher.text = v.code;
                  _quotes = null;
                }),
              ),
          ]),
        const SizedBox(height: 16),
        if (quotes != null) ...[
          for (final (shop, q) in quotes) ...[
            if (quotes.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text(shop.restaurantName, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            _row('Subtotal', q.breakdown.subtotalKobo),
            if (q.breakdown.deliveryFeeKobo > 0) _row('Delivery', q.breakdown.deliveryFeeKobo),
            _row('Service fee', q.breakdown.serviceFeeKobo + q.breakdown.smallOrderFeeKobo),
            _row('VAT (7.5% on fees)', q.breakdown.vatKobo),
            if (q.breakdown.discountKobo > 0) _row('Discount', -q.breakdown.discountKobo),
            if (q.breakdown.plusSavingsKobo > 0) _row('Yummy Chops Plus saved you', q.breakdown.plusSavingsKobo),
            if (quotes.length > 1) ...[
              _row('Shop total', q.breakdown.totalKobo, bold: true),
              Text('Arrives around ${formatLagosTime(q.estimatedDeliveryAt)}', style: theme.textTheme.bodySmall),
            ],
          ],
          const Divider(),
          _row(quotes.length > 1 ? 'Total to pay' : 'Total', total, bold: true),
          Text(
              quotes.length > 1
                  ? '${quotes.length} orders, one payment · price held until '
                      '${formatLagosTime(quotes.map((q) => q.$2.expiresAt).reduce((a, b) => a.isBefore(b) ? a : b))}'
                  : 'Arrives around ${formatLagosTime(quotes.single.$2.estimatedDeliveryAt)} · price held until ${formatLagosTime(quotes.single.$2.expiresAt)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Pay with', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          PaymentMethodPicker(
            totalKobo: total,
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
            onPressed: _busy ? null : (quotes == null ? _getQuote : _pay),
            child: Text(_busy
                ? 'Please wait…'
                : quotes == null
                    ? 'Review total'
                    : switch (_method) {
                        PayMethod.cash => 'Place order · pay ${formatNaira(total)} on delivery',
                        PayMethod.wallet => 'Pay ${formatNaira(total)} from wallet',
                        PayMethod.card => 'Pay ${formatNaira(total)}',
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
