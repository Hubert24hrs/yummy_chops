import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/components.dart' show kmBetween;
import '../../ui/gm_map.dart';
import '../../ui/payment_picker.dart';
import '../location/address_picker.dart';
import 'cart_controller.dart';
import 'widgets/cart_widgets.dart';
import 'widgets/checkout_sheets.dart';
import 'widgets/order_summary.dart';

/// Checkout for the whole cart: each shop becomes its own order (one quote per shop) and one payment covers them
/// all (`POST /v1/checkouts`, ADR-0030). The price is asked for by itself whenever something it depends on
/// changes (address, delivery or pickup, time, voucher, the cart).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  /// How long checkout waits after a change before asking for the price (typing a street asks once, at the end).
  static const quoteDelay = Duration(milliseconds: 600);

  /// "Far from current location": the delivery address is further than this from the phone.
  static const farKm = 1.0;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _line1 = TextEditingController();
  final _voucher = TextEditingController();
  String _fulfillment = 'delivery';

  /// Applied voucher code ('' = none): typing in the field changes nothing until "Apply".
  String _appliedVoucher = '';
  String? _phone;
  String? _allergies;

  /// For the rider; sent as the address's instructions.
  String? _instructions;

  /// A later time for the order (UTC); null = as soon as possible.
  DateTime? _scheduledFor;
  bool _optionsOpen = false;
  bool _promoOpen = false;

  /// Exact address from the map picker (search, GPS or a saved address). Without it the neighbourhood centre is used.
  PickedAddress? _picked;

  /// The street field shows when there is no exact address yet, or the GPS found only the neighbourhood.
  bool _needsStreet = true;
  bool _locating = false;

  /// Why "Use my current location" did not work (shown by the address).
  String? _addressError;

  /// Where the phone is, when known (a GPS fix from "Use my current location", or location already allowed).
  GeoPoint? _here;

  /// One price per shop in the cart, in the cart's shop order. Null while there is none (being asked, or missing).
  List<(CartShop, Quote)>? _quotes;
  bool _quoting = false;
  String? _quoteError;
  String? _payError;
  bool _busy = false;
  Timer? _debounce;

  /// Only the latest request for a price is shown: an older answer arriving late is ignored.
  int _quoteRound = 0;

  /// One key per shop's order; a new price is a new set of orders.
  final _orderKeys = <String, IdempotencyKey>{};

  /// Orders already placed for a (quote id, phone): paying again (another method, a dropped connection)
  /// pays the same orders instead of placing new ones.
  final _placed = <(String, String?), Order>{};

  // One key per method: switching method after a refusal is a new request, a retry is not.
  final _checkoutKeys = <PayMethod, IdempotencyKey>{};
  PayMethod _method = PayMethod.card;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _getQuote();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _line1.dispose();
    _voucher.dispose();
    super.dispose();
  }

  /// Something the price depends on changed: the old price is gone, a new one is asked for shortly.
  void _changed({bool now = false}) {
    _debounce?.cancel();
    _quoteRound++;
    setState(() {
      _quotes = null;
      _quoteError = null;
      _payError = null;
    });
    if (now) {
      _getQuote();
    } else {
      _debounce = Timer(CheckoutScreen.quoteDelay, _getQuote);
    }
  }

  /// One tap: the phone's GPS position becomes the delivery address (the server finds the street, or the
  /// nearest neighbourhood when it has no street for that spot).
  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _addressError = null;
    });
    try {
      final here = await ref.read(customerLocationProvider).current();
      final lookup = await ref.read(apiProvider).reverseGeocode(here);
      if (!mounted) return;
      _here = here;
      if (!lookup.serviceable) {
        setState(() => _addressError = 'Yummy Chops does not deliver to where you are yet. Search for the address to deliver to.');
        return;
      }
      _picked = PickedAddress(
        address: lookup.toAddress(pin: here),
        serviceable: true,
        precise: lookup.place.isPrecise,
        placeId: lookup.place.placeId,
      );
      _line1.text = lookup.place.isPrecise ? lookup.place.formattedAddress : '';
      _needsStreet = !lookup.place.isPrecise;
      _changed(now: true);
    } on LocationUnavailable catch (e) {
      if (mounted) setState(() => _addressError = e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _addressError = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  DeliveryAddress? get _address {
    if (_fulfillment == 'pickup') return null;
    final line1 = _line1.text.trim();
    if (line1.length < 3) return null;
    final picked = _picked;
    if (picked != null) {
      return picked.address.copyWith(
        line1: line1,
        contactPhone: _phone ?? picked.address.contactPhone,
        instructions: _instructions ?? picked.address.instructions,
      );
    }
    final area = ref.read(areaProvider);
    return DeliveryAddress(line1: line1, area: area.name, location: area.location, contactPhone: _phone, instructions: _instructions);
  }

  Future<void> _pickAddress() async {
    final picked = await pickDeliveryAddress(context);
    if (picked == null || !mounted) return;
    _picked = picked;
    _addressError = null;
    _line1.text = picked.address.line1;
    _needsStreet = false;
    _instructions = null; // the new address brings its own directions
    if (_phone == null && picked.address.contactPhone != null) _phone = picked.address.contactPhone;
    _changed(now: true);
  }

  /// A shop's lines, with the allergy note on its first line so the shop sees it (a line note is at most 200 long).
  List<CartLine> _linesFor(CartShop shop) {
    final lines = shop.toLines();
    final allergies = _allergies;
    if (allergies == null || allergies.isEmpty || lines.isEmpty) return lines;
    final first = lines.first;
    var note = [if (first.notes != null && first.notes!.isNotEmpty) first.notes!, 'Allergies: $allergies'].join(' · ');
    if (note.length > 200) note = note.substring(0, 200);
    return [first.copyWith(notes: note), ...lines.skip(1)];
  }

  /// What the customer pays: every shop's total.
  int get _totalKobo => (_quotes ?? const <(CartShop, Quote)>[]).fold(0, (n, q) => n + q.$2.breakdown.totalKobo);

  Future<void> _getQuote() async {
    _debounce?.cancel();
    final shops = ref.read(cartProvider).shops;
    if (shops.isEmpty) return;
    final address = _address;
    if (_fulfillment == 'delivery' && address == null) {
      if (_quoting) setState(() => _quoting = false);
      return;
    }
    final round = ++_quoteRound;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final api = ref.read(apiProvider);
      final quotes = <(CartShop, Quote)>[];
      for (final (i, shop) in shops.indexed) {
        try {
          final q = await api.quote(
            restaurantId: shop.restaurantId,
            lines: _linesFor(shop),
            fulfillment: _fulfillment,
            address: address,
            // A voucher is one discount: it goes with the first shop's order only.
            voucher: i == 0 && _appliedVoucher.isNotEmpty ? _appliedVoucher : null,
            scheduledFor: _scheduledFor,
          );
          quotes.add((shop, q));
        } on ApiException catch (e) {
          throw shops.length > 1 ? ApiException(e.status, e.code, '${shop.restaurantName}: ${e.message}', e.details) : e;
        }
      }
      if (!mounted || round != _quoteRound) return;
      setState(() {
        _quotes = quotes;
        // A new price is a new order: it never goes out with the keys of the last one.
        _orderKeys.clear();
        _placed.clear();
        _checkoutKeys.clear();
      });
    } on ApiException catch (e) {
      if (mounted && round == _quoteRound) setState(() => _quoteError = e.message);
    } finally {
      if (mounted && round == _quoteRound) setState(() => _quoting = false);
    }
  }

  /// "Far from current location": the phone knows where it is and the address is more than a kilometre away.
  bool get _far {
    final here = _here ?? ref.read(knownPositionProvider).asData?.value;
    final picked = _picked;
    if (_fulfillment != 'delivery' || here == null || picked == null) return false;
    return kmBetween(here, picked.address.location) > CheckoutScreen.farKm;
  }

  String get _addressTitle {
    final picked = _picked;
    final line1 = _line1.text.trim();
    return picked?.address.label ?? (line1.isNotEmpty ? line1 : picked?.address.area ?? 'Delivery address');
  }

  String get _payLabel => _method == PayMethod.cash ? 'Place order' : 'Pay to order';

  Future<void> _onPayPressed() async {
    if (_far) {
      final choice = await showFarAddressSheet(context, address: _addressTitle, payLabel: _payLabel);
      if (!mounted || choice == null) return;
      if (choice == FarAddressChoice.edit) {
        await _pickAddress();
        return;
      }
    }
    await _pay();
  }

  Future<void> _pay() async {
    final quotes = _quotes;
    if (quotes == null) return;
    setState(() {
      _busy = true;
      _payError = null;
    });
    try {
      final api = ref.read(apiProvider);
      final phone = _phone;
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
      setState(() => _payError = e.message);
      // The price is no longer held: a new one is asked for straight away (the message stays).
      if (e.needsNewQuote) {
        _quoteRound++;
        setState(() => _quotes = null);
        unawaited(_getQuote());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToCart() {
    final router = GoRouter.maybeOf(context);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      router?.go('/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    ref.listen(cartProvider, (_, next) {
      if (!next.isEmpty) _changed();
    });
    // Asked once (never prompts): only used to say when the address is far from the phone.
    ref.watch(knownPositionProvider);
    final theme = Theme.of(context);
    final appBar = AppBar(
      automaticallyImplyLeading: false,
      leading: const RoundBackButton(),
      leadingWidth: 64,
      centerTitle: true,
    );
    if (cart.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: ListView(padding: const EdgeInsets.all(20), children: const [BigTitle('Checkout'), SizedBox(height: 16), Text('Your cart is empty')]),
      );
    }
    final shops = cart.shops;
    final quotes = _quotes;
    final delivery = _fulfillment == 'delivery';
    final plus = ref.watch(plusProvider).asData?.value;
    return Scaffold(
      appBar: appBar,
      body: ListView(padding: EdgeInsets.zero, children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 20), child: BigTitle('Checkout')),
        InkWell(
          key: const ValueKey('checkout-your-order'),
          onTap: _backToCart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your order', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  ProductsFrom(cart, style: theme.textTheme.bodyMedium),
                ]),
              ),
              Text(formatNaira(cart.subtotalKobo), style: theme.textTheme.bodyMedium),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: PillToggle<String>(
            options: const [('delivery', 'Delivery', Icons.delivery_dining_rounded), ('pickup', 'Pickup', Icons.storefront_rounded)],
            value: _fulfillment,
            onChanged: _busy
                ? null
                : (v) {
                    _fulfillment = v;
                    if (v == 'pickup' && _method == PayMethod.cash) _method = PayMethod.card;
                    _changed(now: true);
                  },
          ),
        ),
        ActionRow(
          key: const ValueKey('checkout-allergies'),
          icon: Icons.no_food_outlined,
          title: 'Any allergies?',
          subtitle: _allergies,
          onTap: _busy
              ? null
              : () async {
                  final text = await showTextFieldSheet(
                    context,
                    title: 'Any allergies?',
                    body: shops.length > 1 ? 'Every shop in your order sees this note.' : 'The shop sees this note with your order.',
                    label: 'Allergies or food needs',
                    initial: _allergies,
                  );
                  if (text == null || !mounted) return;
                  _allergies = text.isEmpty ? null : text;
                  _changed(now: true);
                },
        ),
        if (delivery) ..._deliveryAddress(context),
        _timeOptions(context),
        const SectionHeading('Payment method'),
        if (plus != null && !plus.member && plus.plan.enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SoftBanner(
              icon: Icons.workspace_premium_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Free delivery with Yummy Chops Plus', style: TextStyle(fontWeight: FontWeight.w700)),
                InkWell(
                  onTap: () => GoRouter.maybeOf(context)?.push('/plus'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('More info',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                  ),
                ),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PaymentMethodPicker(
            totalKobo: _totalKobo,
            value: _method,
            onChanged: (m) => setState(() => _method = m),
            cashReason: delivery ? null : 'Only for delivery orders',
          ),
        ),
        ..._promo(context, shops),
        const SizedBox(height: 24),
        OrderSummaryPanel(
          quotes: quotes == null ? null : [for (final (shop, q) in quotes) (shop.restaurantName, q)],
          loading: _quoting,
          error: _quoteError,
          message: delivery && _address == null ? 'Add your delivery address to see the total.' : null,
        ),
      ]),
      bottomNavigationBar: StickyBottomBar(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_payError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_payError!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
            ),
          FilledButton(
            key: const ValueKey('checkout-pay'),
            onPressed: _busy || quotes == null || _quoting ? null : _onPayPressed,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: Text(_busy ? 'Please wait…' : _payLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  List<Widget> _deliveryAddress(BuildContext context) {
    final theme = Theme.of(context);
    final picked = _picked;
    final pin = picked?.address.location ?? ref.watch(areaProvider).location;
    final far = _far;
    return [
      const SectionHeading('Delivery address'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GmMap(pins: [MapPin(pin, PinKind.home, label: 'delivery address')], height: 150, connectKitchenToHome: false),
      ),
      InkWell(
        onTap: _busy ? null : _pickAddress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
          child: Row(children: [
            const Icon(Icons.location_on_outlined, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(picked == null ? 'Pin your exact address' : _addressTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (picked == null)
                  Text('Delivering in ${ref.watch(areaProvider).name}. Search or use your location for a precise pin.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                else if (picked.address.area case final area? when area != _addressTitle)
                  Text(area, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (far)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Far from current location', style: TextStyle(color: warningColor(context), fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
            RoundIconButton(icon: Icons.edit_outlined, tooltip: picked == null ? 'Find address' : 'Change address', onPressed: _busy ? null : _pickAddress),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Align(
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
      ),
      if (_addressError != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(_addressError!, style: TextStyle(color: theme.colorScheme.error)),
        ),
      if (_needsStreet)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _line1,
            decoration: const InputDecoration(labelText: 'Street address', hintText: 'House number and street'),
            onChanged: (_) => _changed(),
          ),
        ),
      ActionRow(
        key: const ValueKey('checkout-instructions'),
        icon: Icons.sticky_note_2_outlined,
        title: 'Instructions for the rider',
        subtitle: _instructions ?? picked?.address.instructions ?? 'Gate, landmark, which floor',
        onTap: _busy
            ? null
            : () async {
                final text = await showTextFieldSheet(
                  context,
                  title: 'Instructions for the rider',
                  label: 'Gate, landmark, which floor',
                  initial: _instructions ?? picked?.address.instructions,
                  maxLength: 300,
                );
                if (text == null || !mounted) return;
                _instructions = text.isEmpty ? null : text;
                _changed(now: true);
              },
      ),
      ActionRow(
        key: const ValueKey('checkout-phone'),
        icon: Icons.phone_iphone_rounded,
        title: 'Phone number',
        subtitle: _phone ?? 'Add your phone number',
        onTap: _busy
            ? null
            : () async {
                final text = await showTextFieldSheet(
                  context,
                  title: 'Phone number',
                  body: 'The rider calls this number if they cannot find you.',
                  label: 'Phone number',
                  initial: _phone,
                  maxLength: 20,
                  maxLines: 1,
                  keyboardType: TextInputType.phone,
                );
                if (text == null || !mounted) return;
                // The number goes with the order, not the price: no new quote (a new number is a new order key).
                setState(() => _phone = text.isEmpty ? null : text);
              },
      ),
    ];
  }

  Widget _timeOptions(BuildContext context) {
    final theme = Theme.of(context);
    final delivery = _fulfillment == 'delivery';
    final eta = (_quotes ?? const <(CartShop, Quote)>[]).fold<int?>(null, (m, q) => m == null || q.$2.etaMinutes > m ? q.$2.etaMinutes : m);
    final standardNote = eta == null
        ? 'As soon as possible'
        : delivery
            ? '$eta–${eta + 15} min'
            : 'Ready in about $eta min';
    final scheduled = _scheduledFor;
    final now = DateTime.now();
    final summary = scheduled == null ? ('Standard', standardNote) : ('Scheduled', scheduleLabel(scheduled, now));
    Widget option(String title, String note, bool selected, VoidCallback? onTap, {Key? key}) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: InkWell(
            key: key,
            onTap: onTap,
            borderRadius: BorderRadius.circular(GmRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GmRadius.md),
                border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outline, width: selected ? 2 : 1),
              ),
              child: Row(children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Expanded(child: Text(note, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
              ]),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeading(delivery ? 'Delivery options' : 'Pickup options'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(GmRadius.lg), border: Border.all(color: theme.colorScheme.outline)),
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              key: const ValueKey('delivery-options'),
              onTap: () => setState(() => _optionsOpen = !_optionsOpen),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(summary.$1, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(summary.$2),
                    ]),
                  ),
                  Icon(_optionsOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                ]),
              ),
            ),
            if (_optionsOpen)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  option('Standard', standardNote, scheduled == null, _busy || scheduled == null
                      ? null
                      : () {
                          _scheduledFor = null;
                          _changed(now: true);
                        }),
                  option(
                    'Schedule',
                    scheduled == null ? 'Choose a day and time' : scheduleLabel(scheduled, now),
                    scheduled != null,
                    _busy
                        ? null
                        : () async {
                            final at = await showScheduleSheet(context, now: DateTime.now(), initial: _scheduledFor);
                            if (at == null || !mounted) return;
                            _scheduledFor = at;
                            _changed(now: true);
                          },
                    key: const ValueKey('schedule-option'),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }

  List<Widget> _promo(BuildContext context, List<CartShop> shops) {
    final theme = Theme.of(context);
    final vouchers = ref.watch(myVouchersProvider).asData?.value ?? const <RewardVoucher>[];
    void apply(String code) {
      _voucher.text = code;
      _appliedVoucher = code.trim().toUpperCase();
      FocusScope.of(context).unfocus();
      _changed(now: true);
    }

    return [
      ActionRow(
        key: const ValueKey('checkout-promo'),
        icon: Icons.local_offer_outlined,
        title: 'Got a promo code?',
        subtitle: _appliedVoucher.isEmpty ? null : '$_appliedVoucher applied',
        trailing: Icon(_promoOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
        onTap: () => setState(() => _promoOpen = !_promoOpen),
      ),
      if (_promoOpen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _voucher,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Promo or voucher code'),
                  onSubmitted: apply,
                ),
              ),
              const SizedBox(width: 8),
              SoftPillButton(label: 'Apply', onPressed: _busy ? null : () => apply(_voucher.text)),
            ]),
            if (shops.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("A code applies to one shop's order (${shops.first.restaurantName})", style: theme.textTheme.bodySmall),
              ),
            if (vouchers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 8, children: [
                  for (final v in vouchers) ActionChip(label: Text('${formatNaira(v.valueKobo)} off · ${v.code}'), onPressed: () => apply(v.code)),
                ]),
              ),
          ]),
        ),
    ];
  }
}
