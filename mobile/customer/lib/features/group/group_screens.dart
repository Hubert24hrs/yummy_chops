import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/payment_picker.dart';
import '../restaurant/restaurant_screen.dart' show ItemSheet;

// ------------------------------------------------------------------------------------------ start a group
/// "Order with friends" from a store: delivery or pickup, who pays, then the group screen with its code.
class StartGroupSheet extends ConsumerStatefulWidget {
  const StartGroupSheet({super.key, required this.restaurantId});
  final String restaurantId;

  @override
  ConsumerState<StartGroupSheet> createState() => _StartGroupSheetState();
}

class _StartGroupSheetState extends ConsumerState<StartGroupSheet> {
  final _line1 = TextEditingController();
  String _fulfillment = 'delivery';
  String _split = 'each';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _line1.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final area = ref.read(areaProvider);
    if (_fulfillment == 'delivery' && _line1.text.trim().length < 3) {
      setState(() => _error = 'Enter the street address for the delivery');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await ref.read(apiProvider).createGroup(
            restaurantId: widget.restaurantId,
            fulfillment: _fulfillment,
            address: _fulfillment == 'delivery'
                ? DeliveryAddress(line1: _line1.text.trim(), area: area.name, city: area.cityName, state: area.cityName, location: area.location)
                : null,
            splitMode: _split,
          );
      if (!mounted) return;
      Navigator.pop(context);
      context.push('/group/${g.id}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = ref.watch(areaProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Order with friends', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Friends join with a code and add their own items. You place one order when everyone is ready.'),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'delivery', label: Text('Delivery')), ButtonSegment(value: 'pickup', label: Text('Pickup'))],
            selected: {_fulfillment},
            onSelectionChanged: (s) => setState(() => _fulfillment = s.first),
          ),
          if (_fulfillment == 'delivery') ...[
            const SizedBox(height: 8),
            TextField(controller: _line1, decoration: InputDecoration(labelText: 'Street address', helperText: 'In ${area.name}, ${area.cityName}')),
          ],
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'each', label: Text('Everyone pays')),
              ButtonSegment(value: 'host', label: Text('I pay for all')),
            ],
            selected: {_split},
            onSelectionChanged: (s) => setState(() => _split = s.first),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 12),
          FilledButton(key: const ValueKey('start-group'), onPressed: _busy ? null : _start, child: Text(_busy ? 'Please wait…' : 'Start and get a code')),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------ group hub
class GroupHubScreen extends ConsumerStatefulWidget {
  const GroupHubScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<GroupHubScreen> createState() => _GroupHubScreenState();
}

class _GroupHubScreenState extends ConsumerState<GroupHubScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await ref.read(apiProvider).joinGroup(_code.text.trim());
      ref.invalidate(myGroupsProvider);
      if (mounted) context.push('/group/${g.id}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Group orders')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Order together from one store. Everyone picks their own food, and pays their own share or lets the host pay.'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Group code'))),
          const SizedBox(width: 8),
          FilledButton(onPressed: _busy ? null : _join, child: const Text('Join')),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
        const SizedBox(height: 20),
        Text('Your group orders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        groups.when(
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text(e is ApiException ? e.message : 'Could not load your group orders'),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No group orders yet. Open any restaurant or beauty shop and tap "Order with friends", then share the code.'),
                )
              : Column(children: [
                  for (final g in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.groups_rounded),
                      title: Text(g.restaurant.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${groupStatusLabel(g)} · ${g.members.length} people${g.isHost ? ' · you\'re the host' : ''}'),
                      trailing: g.myShare == null ? const Icon(Icons.chevron_right_rounded) : Text(formatNaira(g.myShare!.amountKobo)),
                      onTap: () => context.push('/group/${g.id}'),
                    ),
                ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------------------------------ one group
class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> with WidgetsBindingObserver, PaymentReturn<GroupScreen> {
  Timer? _poll;
  PayMethod _method = PayMethod.card;
  final _voucher = TextEditingController();
  final _checkoutKey = IdempotencyKey('group');
  String _shareKey = newIdempotencyKey('share');
  String _restKey = newIdempotencyKey('rest');
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Others are adding items and paying at the same time: refresh every few seconds.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => ref.invalidate(groupProvider(widget.id)));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _voucher.dispose();
    super.dispose();
  }

  @override
  void paymentChecked() {
    ref.invalidate(groupProvider(widget.id));
    ref.invalidate(walletProvider);
  }

  List<CartLine> _myLines(GroupOrder g, {String? except}) {
    final me = g.members.where((m) => m.me).firstOrNull;
    return [
      for (final l in g.lines)
        if (l.memberUid == me?.uid && l.id != except) CartLine(itemId: l.itemId, quantity: l.quantity, selections: l.selections, notes: l.notes),
    ];
  }

  Future<void> _act(Future<void> Function(GudMealApi api) run) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await run(ref.read(apiProvider));
      ref.invalidate(groupProvider(widget.id));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay({required bool rest}) => _act((api) async {
        final res = await api.payGroupShare(widget.id, rest ? _restKey : _shareKey, provider: _method.provider, coverRest: rest);
        if (rest) {
          _restKey = newIdempotencyKey('rest');
        } else {
          _shareKey = newIdempotencyKey('share');
        }
        final url = res.payment.authorizationUrl;
        if (url != null) {
          // Checked when the customer comes back to the app: there is nothing to check before they have paid.
          paymentPageOpened(res.payment.reference);
          await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
        }
        ref.invalidate(walletProvider);
      });

  void _addItems(GroupOrder g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(builder: (context, ref, _) {
        final detail = ref.watch(restaurantDetailProvider(g.restaurant.id));
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Menu unavailable')),
            data: (d) => ListView(children: [
              for (final s in d.sections) ...[
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(s.category.name, style: Theme.of(context).textTheme.titleMedium)),
                for (final item in s.items)
                  ListTile(
                    enabled: item.isAvailable,
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(formatNaira(item.priceKobo)),
                    trailing: const Icon(Icons.add_circle_rounded),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => ItemSheet(
                        item: item,
                        groups: d.optionGroups,
                        restaurantId: d.restaurant.id,
                        restaurantName: d.restaurant.name,
                        onAdd: (line) {
                          Navigator.pop(sheetContext);
                          _act((api) => api.setGroupLines(g.id, [..._myLines(g), line]));
                        },
                      ),
                    ),
                  ),
              ],
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.id));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Group order')),
      body: group.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is ApiException && e.status == 404
                ? 'This group order isn\'t available. Ask the host for the code and join from Group orders.'
                : 'Could not load the group order'),
          ),
        ),
        data: (g) {
          final me = g.members.where((m) => m.me).firstOrNull;
          final beforeOrder = g.status == 'open' || g.status == 'locked';
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Text(g.restaurant.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text('${g.isHost ? 'You\'re the host' : 'Hosted by ${g.hostName}'} · '
                '${g.fulfillment == 'delivery' ? 'delivery to ${g.deliveryArea ?? 'the host'}' : 'pickup'} · '
                '${g.splitMode == 'each' ? 'everyone pays their share' : '${g.hostName} pays'}'),
            const SizedBox(height: 8),
            Chip(key: const ValueKey('group-status'), label: Text(groupStatusLabel(g))),
            if (g.status == 'open')
              Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code_2_rounded),
                  title: SelectableText(g.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  subtitle: Text('${g.members.length}/${g.maxMembers} people. Friends join with this code.'),
                  trailing: IconButton(
                    tooltip: 'Copy invite',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: 'Join my Yummy Chops group order at ${g.restaurant.name} with code ${g.code}'));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite copied')));
                    },
                  ),
                ),
              ),
            if (g.cancelReason != null) Text(g.cancelReason!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            Row(children: [
              Text('Everyone\'s items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (g.status == 'open') FilledButton.tonalIcon(onPressed: _busy ? null : () => _addItems(g), icon: const Icon(Icons.add), label: const Text('Add items')),
            ]),
            for (final m in g.members) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${m.me ? 'You' : m.name}${m.isHost ? ' (host)' : ''}${m.ready ? ' · ready' : ''} · ${formatNaira(m.itemsKobo)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final l in g.lines.where((l) => l.memberUid == m.uid))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${l.quantity} × ${l.name}'),
                  subtitle: l.problem != null
                      ? Text(l.problem!, style: TextStyle(color: theme.colorScheme.error))
                      : (l.options.isEmpty ? null : Text(l.options.join(' · '))),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(formatNaira(l.lineTotalKobo)),
                    if (m.me && g.status == 'open')
                      IconButton(
                        tooltip: 'Remove ${l.name}',
                        onPressed: _busy ? null : () => _act((api) => api.setGroupLines(g.id, _myLines(g, except: l.id))),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ]),
                ),
            ],
            if (g.status == 'open' && me != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: me.ready,
                title: const Text('I\'m done choosing'),
                onChanged: _busy ? null : (v) => _act((api) => api.setGroupReady(g.id, v)),
              ),
            if (g.isHost && beforeOrder) ...[
              const Divider(height: 32),
              Text('Place the order', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'each', label: Text('Everyone pays')), ButtonSegment(value: 'host', label: Text('I pay for all'))],
                selected: {g.splitMode},
                onSelectionChanged: _busy ? null : (s) => _act((api) => api.setGroupSplitMode(g.id, s.first)),
              ),
              const SizedBox(height: 8),
              TextField(controller: _voucher, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Voucher (optional)')),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton(
                  onPressed: _busy ? null : () => _act((api) => api.lockGroup(g.id, g.status == 'open')),
                  child: Text(g.status == 'open' ? 'Lock the cart' : 'Unlock'),
                ),
                FilledButton(
                  key: const ValueKey('place-group-order'),
                  onPressed: _busy || g.lines.isEmpty
                      ? null
                      : () => _act((api) async {
                            final v = _voucher.text.trim();
                            final voucher = v.isEmpty ? null : v.toUpperCase();
                            // A retry keeps the key; a changed voucher, or a "no" from the server (an item sold
                            // out, say), makes the next attempt a new request.
                            await _checkoutKey.send(voucher, (key) => api.checkoutGroup(g.id, key, voucher: voucher));
                          }),
                  child: const Text('Place group order'),
                ),
                TextButton(onPressed: _busy ? null : () => _act((api) => api.cancelGroup(g.id)), child: const Text('Cancel')),
              ]),
            ],
            if (!g.isHost && beforeOrder && me != null)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _act((api) async {
                          await api.leaveGroup(g.id, me.uid);
                          ref.invalidate(myGroupsProvider);
                          if (context.mounted) context.go('/group');
                        }),
                child: const Text('Leave this group order'),
              ),
            if (g.status == 'ordered') ...[
              const Divider(height: 32),
              GroupBillCard(group: g),
              if (g.canPay || g.canCoverRest) ...[
                const SizedBox(height: 8),
                PaymentMethodPicker(
                  totalKobo: g.canPay && g.myShare != null ? g.myShare!.amountKobo : g.remainingKobo,
                  value: _method,
                  onChanged: (m) => setState(() => _method = m),
                  offerCash: false,
                ),
                if (g.canPay && g.myShare != null)
                  FilledButton(
                    key: const ValueKey('pay-share'),
                    onPressed: _busy ? null : () => _pay(rest: false),
                    child: Text('Pay my share · ${formatNaira(g.myShare!.amountKobo)}'),
                  ),
                if (g.canCoverRest)
                  OutlinedButton(onPressed: _busy ? null : () => _pay(rest: true), child: Text('Pay the rest · ${formatNaira(g.remainingKobo)}')),
              ],
              if (g.splitMode == 'host' && g.isHost && g.order?.status == 'draft')
                FilledButton(onPressed: () => context.push('/orders/${g.order!.id}'), child: Text('Pay ${formatNaira(g.totalKobo)} on the order page')),
              if (g.isHost && g.order != null)
                TextButton(onPressed: () => context.push('/orders/${g.order!.id}'), child: const Text('Track the order')),
            ],
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600))),
          ]);
        },
      ),
    );
  }
}

/// Everyone's share once the host placed the order, and who has paid.
class GroupBillCard extends StatelessWidget {
  const GroupBillCard({super.key, required this.group});
  final GroupOrder group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    final each = g.splitMode == 'each';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(each ? 'Who pays what' : '${g.hostName} is paying', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        Text(formatNaira(g.totalKobo), style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
      const Text('Each person pays for their own items; delivery, fees, VAT and discounts are shared in proportion.',
          style: TextStyle(fontSize: 12)),
      for (final s in g.shares)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(s.me ? 'You' : s.name, style: TextStyle(fontWeight: s.me ? FontWeight.w800 : FontWeight.w500)),
          subtitle: Text('Items ${formatNaira(s.itemsKobo)}'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatNaira(s.amountKobo), style: const TextStyle(fontWeight: FontWeight.w800)),
            if (each) Text(s.status == 'paid' ? (s.paidByHost ? 'Paid by ${g.hostName}' : 'Paid') : 'Not paid yet', style: const TextStyle(fontSize: 12)),
          ]),
        ),
      if (each && g.remainingKobo > 0)
        Text('${formatNaira(g.paidKobo)} paid, ${formatNaira(g.remainingKobo)} to go'
            '${g.payBy != null ? ' · pay by ${formatLagosTime(g.payBy!)} or the order is cancelled and refunded' : ''}.'),
    ]);
  }
}
