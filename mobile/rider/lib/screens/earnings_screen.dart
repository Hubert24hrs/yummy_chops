import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../providers.dart';

const minimumWithdrawalKobo = 100000; // ₦1,000 — enforced by the API as well

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  /// One key per withdrawal: a retry of the same request reuses it, the next withdrawal gets a new one.
  var _key = newIdempotencyKey('payout');
  String? _message;

  @override
  Widget build(BuildContext context) {
    final earnings = ref.watch(earningsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: earnings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (e) => ListView(padding: const EdgeInsets.all(16), children: [
          Text('Available to withdraw', style: theme.textTheme.bodyMedium),
          Text(formatNaira(e.availableKobo), style: theme.textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Balance ${formatNaira(e.balanceKobo)} · pending withdrawals ${formatNaira(e.pendingPayoutsKobo)}'),
          Text('Last 7 days ${formatNaira(e.earnedLast7DaysKobo)} · ${e.deliveriesCompleted} deliveries'),
          if (e.cashHeldKobo > 0)
            Card(
              color: const Color(0xFFFFF4D6),
              margin: const EdgeInsets.only(top: 12),
              child: ListTile(
                leading: const Icon(Icons.payments_rounded),
                title: Text('Cash you are holding: ${formatNaira(e.cashHeldKobo)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                  'Collected at the door. Hand it in at the hub or by bank transfer; until then it is deducted before withdrawals.',
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: e.availableKobo < minimumWithdrawalKobo
                ? null
                : () async {
                    try {
                      await ref.read(apiProvider).requestPayout(e.availableKobo, _key);
                      _key = newIdempotencyKey('payout');
                      if (!mounted) return;
                      ref.invalidate(earningsProvider);
                      setState(() => _message = 'Withdrawal requested. Finance pays approved requests to your bank account.');
                    } on ApiException catch (err) {
                      if (mounted) setState(() => _message = err.message);
                    }
                  },
            child: Text('Withdraw ${formatNaira(e.availableKobo)}'),
          ),
          if (e.availableKobo < minimumWithdrawalKobo)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('Minimum withdrawal is ${formatNaira(minimumWithdrawalKobo)}', style: theme.textTheme.bodySmall)),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
        ]),
      ),
    );
  }
}
