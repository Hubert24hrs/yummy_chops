import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/payment_picker.dart';

/// Yummy Chops Plus: price and benefits, the customer's membership, joining (card or wallet) and auto-renew.
class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key});

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> with WidgetsBindingObserver, PaymentReturn<PlusScreen> {
  PayMethod _method = PayMethod.wallet;
  bool _autoRenew = true;
  bool _busy = false;
  String? _error;
  String _key = newIdempotencyKey('plus');

  @override
  void paymentChecked() {
    ref.invalidate(plusProvider);
    ref.invalidate(walletProvider);
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiProvider).subscribePlus(_key, provider: _method.provider, autoRenew: _autoRenew);
      _key = newIdempotencyKey('plus');
      final url = res.payment.authorizationUrl;
      if (url != null) {
        // Provider-hosted page: the membership starts once the payment is verified on the server. That is asked
        // when the customer comes back to the app (there is nothing to check before they have paid).
        paymentPageOpened(res.payment.reference);
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      }
      ref.invalidate(plusProvider);
      ref.invalidate(walletProvider);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setAutoRenew(bool on) async {
    try {
      await ref.read(apiProvider).setPlusAutoRenew(on);
      ref.invalidate(plusProvider);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plus = ref.watch(plusProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Yummy Chops Plus')),
      body: plus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Could not load Yummy Chops Plus')),
        data: (p) {
          final m = p.membership;
          final canJoin = p.plan.enabled && (!p.member || (m?.canRenew ?? false));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3A1A0C), Color(0xFF7A2E12), Color(0xFFE0040B)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Yummy Chops Plus', style: TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: formatNaira(p.plan.priceKobo), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                    TextSpan(text: ' / ${p.plan.periodDays} days', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ])),
                  const Text('VAT included · cancel any time', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  for (final b in p.plan.benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b)),
                      ]),
                    ),
                ]),
              ),
            ),
            if (p.member && m != null) ...[
              const SizedBox(height: 16),
              Card(
                key: const ValueKey('plus-member'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Member until ${m.paidThroughText}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${m.daysLeft} days left · you\'ve saved ${formatNaira(m.savingsKobo)} so far'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: m.autoRenew,
                      title: const Text('Renew automatically from my Yummy Chops wallet'),
                      subtitle: m.autoRenew ? null : Text('Your benefits stay until ${m.paidThroughText}.'),
                      onChanged: _setAutoRenew,
                    ),
                  ]),
                ),
              ),
            ],
            if (!p.member && m?.status == 'expired')
              const Padding(padding: EdgeInsets.only(top: 12), child: Text('Your membership ended. Join again to get your benefits back.')),
            if (canJoin) ...[
              const SizedBox(height: 20),
              Text(p.member ? 'Renew early' : 'Join Yummy Chops Plus', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              PaymentMethodPicker(totalKobo: p.plan.priceKobo, value: _method, onChanged: (v) => setState(() => _method = v), offerCash: false),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _autoRenew,
                onChanged: (v) => setState(() => _autoRenew = v ?? false),
                title: Text('Renew automatically from my Yummy Chops wallet every ${p.plan.periodDays} days. I can turn this off any time.'),
              ),
              FilledButton(
                key: const ValueKey('plus-join'),
                onPressed: _busy ? null : _join,
                child: Text(_busy ? 'Please wait…' : '${p.member ? 'Renew' : 'Join'} for ${formatNaira(p.plan.priceKobo)}'),
              ),
              const SizedBox(height: 8),
              Text(
                'Benefits start once the payment is confirmed. Turning auto-renew off cancels at the end of the period you '
                'paid for; days already paid are not refunded.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
              ),
          ]);
        },
      ),
    );
  }
}
