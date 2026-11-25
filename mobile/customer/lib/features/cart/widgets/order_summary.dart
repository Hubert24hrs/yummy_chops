import 'package:flutter/material.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'cart_widgets.dart';

/// The grey "Summary" at the end of checkout: what each shop's order costs (from the server's quotes), the total
/// to pay, and what the customer saves. While a price is being asked for it shows placeholders.
class OrderSummaryPanel extends StatelessWidget {
  const OrderSummaryPanel({super.key, required this.quotes, this.loading = false, this.message, this.error});

  /// Shop name and its quote, in the cart's shop order. Null when there is no price yet.
  final List<(String, Quote)>? quotes;
  final bool loading;

  /// Why there is no price yet ("Add your delivery address…").
  final String? message;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quotes = this.quotes;
    final many = (quotes?.length ?? 0) > 1;
    final total = (quotes ?? const <(String, Quote)>[]).fold(0, (n, q) => n + q.$2.breakdown.totalKobo);
    final saved = (quotes ?? const <(String, Quote)>[]).fold(0, (n, q) => n + q.$2.breakdown.discountKobo + q.$2.breakdown.plusSavingsKobo);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Summary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (error != null)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error!, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600))),
        if (loading && quotes == null)
          const _Placeholders()
        else if (quotes == null)
          Text(message ?? 'The price shows here once checkout has what it needs.', style: TextStyle(color: scheme.onSurfaceVariant))
        else ...[
          for (final (name, q) in quotes) ...[
            if (many)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(children: [
                  Icon(Icons.storefront_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
                ]),
              ),
            ..._rows(context, q),
            if (many) ...[
              _row(context, 'Shop total', Text(formatNaira(q.breakdown.totalKobo), style: const TextStyle(fontWeight: FontWeight.w800)), bold: true),
              Text('Arrives around ${formatLagosTime(q.estimatedDeliveryAt)}', style: theme.textTheme.bodySmall),
              const Divider(height: 24),
            ],
          ],
          if (!many) const Divider(height: 24),
          Row(children: [
            Expanded(child: Text('Total to pay', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
            Text(formatNaira(total), key: const ValueKey('total-to-pay'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          Text(
            many
                ? '${quotes.length} orders, one payment · price held until '
                    '${formatLagosTime(quotes.map((q) => q.$2.expiresAt).reduce((a, b) => a.isBefore(b) ? a : b))}'
                : '${quotes.single.$2.fulfillment == 'pickup' ? 'Ready' : 'Arrives'} around ${formatLagosTime(quotes.single.$2.estimatedDeliveryAt)}'
                    ' · price held until ${formatLagosTime(quotes.single.$2.expiresAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (loading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2)),
          if (saved > 0) ...[
            const SizedBox(height: 16),
            SoftBanner(
              icon: Icons.savings_rounded,
              color: successColor(context),
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: "You're saving "),
                TextSpan(text: formatNaira(saved), style: const TextStyle(fontWeight: FontWeight.w900)),
                const TextSpan(text: ' on this order'),
              ])),
            ),
          ],
        ],
      ]),
    );
  }

  List<Widget> _rows(BuildContext context, Quote q) {
    final b = q.breakdown;
    final scheme = Theme.of(context).colorScheme;
    // Plus made delivery free: say so instead of showing ₦0.
    final freeDelivery = q.fulfillment == 'delivery' && b.deliveryFeeKobo == 0 && b.plusSavingsKobo > 0;
    return [
      _row(context, 'Products', Text(formatNaira(b.subtotalKobo))),
      if (q.fulfillment == 'delivery')
        _row(
          context,
          'Delivery',
          freeDelivery
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(6)),
                  child: Text('FREE', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w900, fontSize: 12)),
                )
              : Text(formatNaira(b.deliveryFeeKobo)),
        ),
      _row(context, 'Service fee', Text(formatNaira(b.serviceFeeKobo + b.smallOrderFeeKobo))),
      _row(context, 'VAT (7.5% on fees)', Text(formatNaira(b.vatKobo))),
      if (b.discountKobo > 0)
        _row(context, b.voucherCode == null ? 'Discount' : 'Discount (${b.voucherCode})',
            Text(formatNaira(-b.discountKobo), style: TextStyle(color: successColor(context), fontWeight: FontWeight.w700))),
      if (b.plusSavingsKobo > 0)
        _row(context, 'Yummy Chops Plus saved you', Text(formatNaira(b.plusSavingsKobo), style: TextStyle(color: successColor(context)))),
    ];
  }

  Widget _row(BuildContext context, String label, Widget value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
          DefaultTextStyle.merge(style: const TextStyle(fontSize: 15), child: value),
        ]),
      );
}

class _Placeholders extends StatelessWidget {
  const _Placeholders();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double w) => Container(width: w, height: 14, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7)));
    return Semantics(
      label: 'Getting the price',
      child: Column(children: [
        for (final w in const [90.0, 70.0, 100.0, 60.0])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [bar(w), const Spacer(), bar(70)]),
          ),
        const Divider(height: 24),
        Row(children: [bar(130), const Spacer(), bar(100)]),
      ]),
    );
  }
}
