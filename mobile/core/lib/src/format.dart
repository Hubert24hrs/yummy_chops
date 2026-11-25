import 'package:intl/intl.dart';

import 'models.dart';

final _thousands = NumberFormat.decimalPattern('en_NG');
final _time = DateFormat('h:mm a');

/// 1_000_000 kobo → "₦10,000"; keeps kobo when present ("₦1,500.50").
String formatNaira(int? kobo) {
  if (kobo == null) return '—';
  final negative = kobo < 0;
  final abs = kobo.abs();
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final body = _thousands.format(whole);
  return '${negative ? '-' : ''}₦$body${frac == 0 ? '' : '.${frac.toString().padLeft(2, '0')}'}';
}

/// Lagos is UTC+1 all year (no daylight saving).
String formatLagosTime(DateTime? t) => t == null ? '—' : _time.format(t.toUtc().add(const Duration(hours: 1)));

final _dateTime = DateFormat('d MMM, h:mm a');

/// "15 Nov, 2:30 PM" in Lagos time.
String formatLagosDateTime(DateTime? t) =>
    t == null ? '—' : _dateTime.format(t.toUtc().add(const Duration(hours: 1)));

enum StatusTone { neutral, info, progress, success, warning, danger }

const orderStatusLabels = <String, (String, StatusTone)>{
  'draft': ('Draft', StatusTone.neutral),
  'pending_payment': ('Awaiting payment', StatusTone.warning),
  'paid': ('Paid', StatusTone.info),
  'submitted_to_restaurant': ('Sent to the shop', StatusTone.info),
  'restaurant_accepted': ('Accepted', StatusTone.progress),
  'preparing': ('Preparing', StatusTone.progress),
  'ready_for_pickup': ('Ready', StatusTone.progress),
  'rider_assigned': ('Rider assigned', StatusTone.progress),
  'picked_up': ('Picked up', StatusTone.progress),
  'in_transit': ('On the way', StatusTone.progress),
  'delivered': ('Delivered', StatusTone.success),
  'completed': ('Completed', StatusTone.success),
  'cancelled': ('Cancelled', StatusTone.danger),
  'refund_pending': ('Refund pending', StatusTone.warning),
  'partially_refunded': ('Partially refunded', StatusTone.warning),
  'refunded': ('Refunded', StatusTone.neutral),
  'disputed': ('Under review', StatusTone.danger),
};

String statusLabel(String status) => orderStatusLabels[status]?.$1 ?? status;

/// Mirrors the API's option-group rules so the UI can block invalid selections before a quote.
String? validateSelections(MenuItem item, Map<String, OptionGroup> groups, Map<String, List<String>> chosen) {
  for (final gid in item.optionGroupIds) {
    final group = groups[gid];
    if (group == null) return 'Some options are unavailable';
    final n = chosen[gid]?.length ?? 0;
    if (n < group.minSelect || n > group.maxSelect) {
      return group.minSelect == group.maxSelect
          ? 'Choose ${group.minSelect} for “${group.name}”'
          : 'Choose ${group.minSelect}–${group.maxSelect} for “${group.name}”';
    }
  }
  return null;
}

int optionsPriceKobo(MenuItem item, Map<String, OptionGroup> groups, Map<String, List<String>> chosen) {
  var total = 0;
  for (final gid in item.optionGroupIds) {
    final group = groups[gid];
    if (group == null) continue;
    for (final cid in chosen[gid] ?? const <String>[]) {
      total += group.choices.firstWhere((c) => c.id == cid, orElse: () => const OptionChoice(id: '', name: '')).priceDeltaKobo;
    }
  }
  return total;
}
