import 'package:flutter/material.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import 'cart_widgets.dart';

/// The bottom sheets of checkout: a short note (allergies, rider instructions, phone number), the time of a
/// scheduled order, and "Far from current location" before paying.

/// A sheet with one text field and "Save". Returns the trimmed text ('' clears it), or null when dismissed.
Future<String?> showTextFieldSheet(
  BuildContext context, {
  required String title,
  required String label,
  String? body,
  String? initial,
  int maxLength = 200,
  int maxLines = 3,
  TextInputType? keyboardType,
  String? Function(String text)? validate,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TextFieldSheet(
        title: title,
        label: label,
        body: body,
        initial: initial,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validate: validate,
      ),
    );

class _TextFieldSheet extends StatefulWidget {
  const _TextFieldSheet({
    required this.title,
    required this.label,
    this.body,
    this.initial,
    required this.maxLength,
    required this.maxLines,
    this.keyboardType,
    this.validate,
  });
  final String title;
  final String label;
  final String? body;
  final String? initial;
  final int maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String text)? validate;

  @override
  State<_TextFieldSheet> createState() => _TextFieldSheetState();
}

class _TextFieldSheetState extends State<_TextFieldSheet> {
  late final _text = TextEditingController(text: widget.initial ?? '');
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final text = _text.text.trim();
    final error = text.isEmpty ? null : widget.validate?.call(text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          if (widget.body != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(widget.body!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: widget.maxLength,
            minLines: 1,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(labelText: widget.label, errorText: _error),
            onSubmitted: widget.maxLines == 1 ? (_) => _save() : null,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)), child: const Text('Save')),
        ]),
      ),
    );
  }
}

/// Lagos is UTC+1 all year: the clock the customer reads and the shop works by.
const _lagos = Duration(hours: 1);

/// The times a scheduled order can be for: every half hour from 30 minutes (and a little margin) to 7 days ahead,
/// grouped by Lagos day. All in UTC.
List<List<DateTime>> scheduleSlots(DateTime now) {
  final earliest = now.toUtc().add(const Duration(minutes: 40));
  final latest = now.toUtc().add(const Duration(days: 7));
  // First half hour on the Lagos clock at or after [earliest].
  final local = earliest.add(_lagos);
  final roundUp = local.minute == 0 || local.minute == 30 ? 0 : (local.minute < 30 ? 30 - local.minute : 60 - local.minute);
  var t = DateTime.utc(local.year, local.month, local.day, local.hour, local.minute).add(Duration(minutes: roundUp)).subtract(_lagos);
  final days = <List<DateTime>>[];
  int? day;
  while (!t.isAfter(latest)) {
    final d = t.add(_lagos).day;
    if (d != day) {
      days.add([]);
      day = d;
    }
    days.last.add(t);
    t = t.add(const Duration(minutes: 30));
  }
  return days;
}

String _dayLabel(DateTime slot, DateTime now) {
  final s = slot.add(_lagos);
  final n = now.toUtc().add(_lagos);
  final days = DateTime.utc(s.year, s.month, s.day).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  const week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${week[s.weekday - 1]} ${s.day} ${months[s.month - 1]}';
}

/// Picks a day and a half-hour slot. Returns the chosen time (UTC), or null when dismissed.
Future<DateTime?> showScheduleSheet(BuildContext context, {required DateTime now, DateTime? initial}) =>
    showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScheduleSheet(now: now, initial: initial),
    );

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.now, this.initial});
  final DateTime now;
  final DateTime? initial;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late final List<List<DateTime>> _days = scheduleSlots(widget.now);
  late int _day = _initialDay();
  DateTime? _chosen;

  int _initialDay() {
    final initial = widget.initial;
    if (initial == null) return 0;
    final i = _days.indexWhere((d) => d.contains(initial));
    if (i >= 0) _chosen = initial;
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slots = _days.isEmpty ? const <DateTime>[] : _days[_day];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Schedule', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Choose when it should arrive: from 30 minutes to 7 days ahead.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_dayLabel(_days[i].first, widget.now)),
                selected: i == _day,
                onSelected: (_) => setState(() => _day = i),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, mainAxisExtent: 44, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: slots.length,
              itemBuilder: (_, i) => ChoiceChip(
                label: SizedBox(width: double.infinity, child: Text(formatLagosTime(slots[i]), textAlign: TextAlign.center)),
                selected: slots[i] == _chosen,
                onSelected: (_) => setState(() => _chosen = slots[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: FilledButton(
              onPressed: _chosen == null ? null : () => Navigator.pop(context, _chosen),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(_chosen == null ? 'Choose a time' : 'Schedule for ${_dayLabel(_chosen!, widget.now)}, ${formatLagosTime(_chosen)}'),
            ),
          ),
        ]),
      ),
    );
  }
}

/// "Today, 2:30 PM", "Fri 27 Nov, 2:30 PM".
String scheduleLabel(DateTime slot, DateTime now) => '${_dayLabel(slot, now)}, ${formatLagosTime(slot)}';

/// What the customer chose on the "Far from current location" sheet.
enum FarAddressChoice { pay, edit }

/// Asked before paying when the delivery address is more than a kilometre from where the phone is.
Future<FarAddressChoice?> showFarAddressSheet(BuildContext context, {required String address, required String payLabel}) =>
    showModalBottomSheet<FarAddressChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final amber = warningColor(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.map_outlined, size: 72, color: theme.colorScheme.primary),
                    Positioned(
                      right: 22,
                      bottom: 22,
                      child: Container(
                        decoration: BoxDecoration(color: amber, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.priority_high_rounded, size: 22, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              Text('Far from current location', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text('Is this address correct?', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 16),
                Expanded(child: Text(address, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 28),
              FilledButton(
                key: const ValueKey('far-pay'),
                onPressed: () => Navigator.pop(context, FarAddressChoice.pay),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: Text(payLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              SoftPillButton(label: 'Edit address', expand: true, onPressed: () => Navigator.pop(context, FarAddressChoice.edit)),
            ]),
          ),
        );
      },
    );
