import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';

/// Yummy Chops wallet: balance, top-up, instant refunds setting, history, and cash-on-delivery money for sellers.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

const _quickAmounts = [100000, 200000, 500000, 1000000]; // ₦1,000 – ₦10,000

int _toKobo(String naira) => ((double.tryParse(naira.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) * 100).round();

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amount = TextEditingController();
  String? _error;
  bool _busy = false;
  String _topUpKey = newIdempotencyKey('topup');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _topUp(WalletOverview w) async {
    final kobo = _toKobo(_amount.text);
    final room = w.limits.maxBalanceKobo - w.balanceKobo;
    final problem = kobo < w.limits.minTopupKobo
        ? 'The minimum top-up is ${formatNaira(w.limits.minTopupKobo)}'
        : kobo > w.limits.maxTopupKobo
            ? 'The maximum top-up is ${formatNaira(w.limits.maxTopupKobo)}'
            : kobo > room
                ? 'Your wallet can hold up to ${formatNaira(w.limits.maxBalanceKobo)}'
                : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiProvider).topUpWallet(kobo, _topUpKey);
      _topUpKey = newIdempotencyKey('topup');
      final url = res.authorizationUrl;
      // Provider-hosted payment page: card data never touches the app. The balance updates once it's verified.
      if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      if (url != null) await ref.read(apiProvider).verifyPayment(res.reference);
      ref.invalidate(walletProvider);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Yummy Chops wallet')),
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Could not load your wallet')),
        data: (w) => RefreshIndicator(
          onRefresh: () => ref.refresh(walletProvider.future),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF25C22), Color(0xFFE0040B)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Balance', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                Text(formatNaira(w.balanceKobo),
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                const Text('Pay for food, pharmacy, beauty, groceries, foodstuff and packages in one tap. Refunds land here instantly.',
                    style: TextStyle(color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Top up', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in _quickAmounts)
                ChoiceChip(
                  label: Text(formatNaira(k)),
                  selected: _toKobo(_amount.text) == k,
                  onSelected: (_) => setState(() => _amount.text = '${k ~/ 100}'),
                ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (₦)',
                helperText:
                    'From ${formatNaira(w.limits.minTopupKobo)} to ${formatNaira(w.limits.maxTopupKobo)} per top-up',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy || !w.enabled || _toKobo(_amount.text) == 0 ? null : () => _topUp(w),
              child: Text(_busy ? 'Please wait…' : 'Top up ${_toKobo(_amount.text) > 0 ? formatNaira(_toKobo(_amount.text)) : ''}'),
            ),
            const SizedBox(height: 6),
            Text(
              'You pay by card, bank transfer or USSD on a secure page. Wallet money is for Yummy Chops orders and '
              "deliveries; it can't be withdrawn as cash.",
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: w.refundToWallet,
              title: const Text('Instant refunds to my wallet'),
              subtitle: const Text('Card refunds go to your wallet straight away instead of back to the card.'),
              onChanged: (on) async {
                await ref.read(apiProvider).setRefundToWallet(on);
                ref.invalidate(walletProvider);
              },
            ),
            if (w.seller != null) _SellerCard(seller: w.seller!),
            const SizedBox(height: 12),
            Text('History', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (w.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No wallet activity yet. Top up to pay for your next order in one tap.'),
              ),
            for (final t in w.transactions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: t.direction == 'in' ? const Color(0xFFE5F3E0) : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(t.direction == 'in' ? Icons.south_west_rounded : Icons.north_east_rounded, size: 18),
                ),
                title: Text(t.description),
                subtitle: Text(formatLagosDateTime(t.createdAt)),
                trailing: Text(
                  '${t.direction == 'in' ? '+' : '−'}${formatNaira(t.amountKobo)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: t.direction == 'in' ? const Color(0xFF2E8B1E) : null,
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _SellerCard extends ConsumerStatefulWidget {
  const _SellerCard({required this.seller});
  final SellerSummary seller;

  @override
  ConsumerState<_SellerCard> createState() => _SellerCardState();
}

class _SellerCardState extends ConsumerState<_SellerCard> {
  final _move = TextEditingController();
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _name = TextEditingController();
  final _payout = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_move, _bank, _account, _name, _payout]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      setState(() => _message = done);
      ref.invalidate(walletProvider);
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seller;
    final api = ref.read(apiProvider);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.payments_rounded, color: Color(0xFF2E8B1E)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Cash-on-delivery money', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Text(formatNaira(s.availableKobo), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
          if (s.pendingPayoutsKobo > 0) Text('${formatNaira(s.pendingPayoutsKobo)} is being paid out to your bank'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _move,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Move to wallet (₦)'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => api.moveCodToWallet(_toKobo(_move.text), newIdempotencyKey('cod-move')),
                      'Moved to your wallet'),
              child: const Text('Move'),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('Withdraw to your bank', style: TextStyle(fontWeight: FontWeight.w700)),
          TextField(controller: _bank, decoration: const InputDecoration(labelText: 'Bank')),
          TextField(
            controller: _account,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: const InputDecoration(labelText: 'Account number (10 digits)'),
          ),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Account name')),
          TextField(
            controller: _payout,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount (₦)', helperText: 'Minimum ${formatNaira(s.minPayoutKobo)}'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _busy
                ? null
                : () => _run(
                      () => api.requestSellerPayout(
                        amountKobo: _toKobo(_payout.text),
                        bankName: _bank.text.trim(),
                        accountNumber: _account.text.trim(),
                        accountName: _name.text.trim(),
                        idempotencyKey: newIdempotencyKey('payout'),
                      ),
                      "Withdrawal requested. We'll let you know when it's paid.",
                    ),
            child: const Text('Request withdrawal'),
          ),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!)),
        ]),
      ),
    );
  }
}
