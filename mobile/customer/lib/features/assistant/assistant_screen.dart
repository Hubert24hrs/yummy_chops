import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../ui/components.dart';
import '../../ui/gudy.dart';
import '../../ui/illustrations.dart';

class _Turn {
  _Turn(this.fromUser, this.text, {this.cards = const [], this.approval});
  final bool fromUser;
  final String text;
  final List<Map<String, dynamic>> cards;
  ChatApproval? approval;
}

const _suggestions = [
  'What do you offer?',
  'How much have I spent?',
  'I have ₦10,000. Best meal for two?',
  'Find me a good sunscreen',
  'Send a package',
  'Talk to a person',
];

/// Route for a screen Yummy points to (from an `open_screen` card).
String? routeForScreen(String screen, Map<String, dynamic> params) => switch (screen) {
      'home' => '/',
      'food' => params['category'] != null ? '/food?category=${params['category']}' : '/food',
      'beauty' || 'grocery' || 'pharmacy' || 'market' =>
        '${serviceCopy(screen).route}${params['category'] != null ? '?category=${params['category']}' : ''}',
      'parcel' => '/send',
      'discover' => '/discover',
      'orders' => '/orders',
      'support' => '/support',
      'profile' => '/profile',
      'wallet' => '/wallet',
      'waybill' => '/send?mode=interstate',
      'plus' => '/plus',
      'rewards' => '/rewards',
      'group' => '/group',
      'merchant' => params['merchant_id'] != null ? '/restaurants/${params['merchant_id']}' : null,
      'order' => params['order_id'] != null ? '/orders/${params['order_id']}' : '/orders',
      _ => null,
    };

/// Yummy, the AI assistant (LangGraph agents service). Spending actions arrive as approval cards.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.initial});
  final String? initial;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _turns = <_Turn>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechToText();
  String? _threadId;
  bool _busy = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initial!));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  void _apply(ChatResponse res) {
    setState(() {
      _threadId = res.threadId;
      _turns.add(_Turn(false, res.status == 'approval_required' ? (res.reply ?? 'Please review and approve:') : (res.reply ?? ''),
          cards: res.cards, approval: res.approval));
    });
    _toBottom();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    setState(() {
      _turns.add(_Turn(true, text.trim()));
      _busy = true;
    });
    _input.clear();
    _toBottom();
    try {
      final area = ref.read(areaProvider);
      final address = DeliveryAddress(label: area.name, line1: '${area.name}, ${area.cityName}', area: area.name, city: area.cityName, state: area.cityName, location: area.location);
      _apply(await ref.read(agentsApiProvider).chat(text.trim(), threadId: _threadId, address: address));
    } on ApiException catch (e) {
      setState(() => _turns.add(_Turn(false, e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(_Turn turn, bool approved) async {
    final approval = turn.approval!;
    setState(() {
      turn.approval = null;
      _busy = true;
    });
    try {
      _apply(await ref.read(agentsApiProvider).decide(_threadId!, approved: approved, toolCallId: approval.toolCallId));
    } on ApiException catch (e) {
      setState(() => _turns.add(_Turn(false, e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize();
    if (!ok) return;
    setState(() => _listening = true);
    await _speech.listen(onResult: (r) {
      _input.text = r.recognizedWords;
      if (r.finalResult) setState(() => _listening = false);
    }, listenOptions: SpeechListenOptions(localeId: 'en_NG'));
  }

  void _open(String route) {
    if (route == '/' || route == '/discover' || route == '/orders' || route == '/support' || route == '/profile') {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = ref.watch(authStateProvider).value?.name?.split(' ').first;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          const GudyAvatar(size: 38),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Yummy', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('AI assistant · replies in your language', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
            _GudyBubble(
              text: 'Hi${name == null ? '' : ' $name'}! I’m Yummy. I can find food, groceries, foodstuff, pharmacy and beauty products, plan a meal within your budget, '
                  'send packages across Lagos and Enugu, track orders and tell you how much you’ve spent. '
                  'You can write in English, Pidgin, Igbo, Yoruba or Hausa.',
            ),
            if (_turns.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 44),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in _suggestions) ActionChip(label: Text(s), onPressed: () => _send(s)),
                ]),
              ),
            for (final t in _turns)
              t.fromUser
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4))),
                        child: Text(t.text, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                  : _GudyBubble(
                      text: t.text,
                      children: [
                        for (final card in t.cards) _CardView(card: card, onOpen: _open, onSay: _send),
                        if (t.approval != null) _ApprovalView(approval: t.approval!, onDecide: (ok) => _decide(t, ok)),
                      ],
                    ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(left: 44, top: 8),
                child: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Yummy is thinking…')]),
              ),
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
              IconButton(tooltip: _listening ? 'Stop' : 'Speak', onPressed: _listen, icon: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded)),
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: 'Ask Yummy anything…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: scheme.outline)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: 'Send',
                style: IconButton.styleFrom(backgroundColor: RobotPainter.body),
                onPressed: _busy ? null : () => _send(_input.text),
                icon: const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _GudyBubble extends StatelessWidget {
  const _GudyBubble({required this.text, this.children = const []});
  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const GudyAvatar(size: 34),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (text.isNotEmpty) Text(text),
              ...children,
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.onOpen, required this.onSay});
  final Map<String, dynamic> card;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onSay;

  static final _serviceRoutes = {for (final s in merchantServices) s.id: s.route, 'parcel': '/send'};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (card['type']) {
      case 'services':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in (card['services'] as List).cast<Map>())
              ActionChip(
                avatar: Icon(s['id'] == 'parcel' ? Icons.local_shipping_rounded : serviceCopy('${s['id']}').icon, size: 18),
                label: Text('${s['name']}'),
                onPressed: () => onOpen(_serviceRoutes['${s['id']}'] ?? '/'),
              ),
          ]),
        );
      case 'navigate':
        final route = routeForScreen('${card['screen']}', Map<String, dynamic>.from(card['params'] as Map? ?? const {}));
        if (route == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.tonalIcon(onPressed: () => onOpen(route), icon: const Icon(Icons.open_in_new_rounded, size: 18), label: Text('${card['label']}')),
        );
      case 'wallet':
        final recent = (card['recent'] as List? ?? const []).cast<Map>();
        return InkWell(
          onTap: () => onOpen('/wallet'),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(GmRadius.md)),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Yummy Chops wallet', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${card['balance']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                for (final t in recent.take(3)) Text('${t['what']}: ${t['amount']}'),
                if (card['cash_on_delivery_balance'] != null) Text('Cash on delivery: ${card['cash_on_delivery_balance']}'),
                const Text('Open wallet · top up', style: TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
              ]),
            ),
          ),
        );
      case 'waybill_options':
        final rows = (card['destinations'] as List? ?? const []).cast<Map>();
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('From ${card['from']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              for (final d in rows)
                Text('${d['to']}: from ${d['price_from']} · ${d['transit']} · '
                    '${d['door_delivery'] == true ? 'door delivery' : 'collect at ${(d['collection_points'] as List? ?? const []).join(', ')}'}'),
              const SizedBox(height: 6),
              FilledButton.tonal(onPressed: () => onOpen('/send?mode=interstate'), child: const Text('Send to another city')),
            ]),
          ),
        );
      case 'waybill_tracking':
        final history = (card['history'] as List? ?? const []).cast<String>();
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            leading: const Icon(Icons.local_shipping_rounded),
            title: Text('${card['status']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(['${card['tracking_code']} · ${card['route']}', if (card['delivered'] != true) 'Expected ${card['expected']}', if (history.isNotEmpty) history.join(' → ')].join('\n')),
          ),
        );
      case 'plus':
        final benefits = (card['benefits'] as List? ?? const []).cast<String>();
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: Text(card['member'] == true ? 'Plus member until ${card['member_until']}' : 'Yummy Chops Plus · ${card['price']}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(card['member'] == true ? 'Saved ${card['saved']} so far' : benefits.join('\n')),
            onTap: () => onOpen('/plus'),
          ),
        );
      case 'rewards':
        final vouchers = (card['vouchers'] as List? ?? const []).cast<Map>();
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: ListTile(
            leading: const Icon(Icons.card_giftcard_rounded),
            title: Text('${card['points']} Yummy points', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text([
              'Referral code ${card['referral_code']}',
              for (final v in vouchers) '${v['worth']} off · ${v['code']}',
            ].join('\n')),
            onTap: () => onOpen('/rewards'),
          ),
        );
      case 'group_orders':
        final groups = (card['groups'] as List? ?? const []).cast<Map>();
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: Column(children: [
            for (final g in groups)
              ListTile(
                leading: const Icon(Icons.groups_rounded),
                title: Text('${g['store']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([
                  '${g['status']}',
                  if (g['join_code'] != null) 'code ${g['join_code']}',
                  if (g['your_share'] != null) 'your share ${g['your_share']}',
                ].join(' · ')),
                onTap: () => onOpen('/group/${g['group_order_id']}'),
              ),
            TextButton(onPressed: () => onOpen('/group'), child: const Text('Open group orders')),
          ]),
        );
      case 'payment_options':
        final methods = (card['methods'] as List? ?? const []).cast<Map>();
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: Column(children: [
            for (final m in methods)
              ListTile(
                dense: true,
                leading: Icon(m['available'] == true ? Icons.check_circle_rounded : Icons.block_rounded,
                    color: m['available'] == true ? const Color(0xFF2E8B1E) : null),
                title: Text('${m['method']}'),
                subtitle: m['why_not'] == null ? null : Text('${m['why_not']}'),
              ),
          ]),
        );
      case 'order_totals':
        final byService = Map<String, dynamic>.from(card['by_service'] as Map? ?? const {});
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(GmRadius.md)),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${card['total_spent']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('${card['paid_orders']} paid order(s) · ${card['spent_this_month']} this month'),
              for (final e in byService.entries) Text('${e.key}: ${(e.value as Map)['spent']} (${(e.value as Map)['orders']})'),
            ]),
          ),
        );
      case 'meal_plans':
        final plans = (card['plans'] as List).cast<Map>();
        return Column(children: [
          for (final (i, p) in plans.indexed)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                title: Text('${p['restaurant']} · ${p['total']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${(p['items'] as List).join(' · ')}${p['arrives_around'] != null ? '\nArrives ~${p['arrives_around']}' : ''}'),
                trailing: TextButton(onPressed: () => onSay('plan ${i + 1}'), child: const Text('Order')),
              ),
            ),
        ]);
      case 'order_draft':
      case 'order_status':
        final o = Map<String, dynamic>.from(card['order'] as Map);
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${o['short_code']} · ${o['restaurant']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              if (o['status_label'] != null) Text('${o['status_label']}', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              for (final item in (o['items'] as List? ?? const [])) Text('$item'),
              Text('Total ${o['total']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              if (o['order_id'] != null)
                TextButton(onPressed: () => onOpen('/orders/${o['order_id']}'), child: const Text('Open order')),
            ]),
          ),
        );
      case 'restaurants':
        final items = (card['items'] as List).cast<Map>();
        return Column(children: [
          for (final r in items.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(r['service'] == null || r['service'] == 'food' ? Icons.storefront_rounded : serviceCopy('${r['service']}').icon, color: brandRed),
              title: Text('${r['name']}'),
              subtitle: Text([if (r['eta_minutes'] != null) '${r['eta_minutes']} min', if (r['delivery_fee'] != null) '${r['delivery_fee']} delivery'].join(' · ')),
              onTap: () => onOpen('/restaurants/${r['restaurant_id']}'),
            ),
        ]);
      case 'parcel_quote':
        final q = Map<String, dynamic>.from(card['quote'] as Map);
        return Card(
          margin: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Package · ${q['size']} · ${q['distance_km']} km', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('From ${q['from']}'),
              Text('To ${q['to']}'),
              Text('${q['pickup']} · arrives ~${q['estimated_delivery']}'),
              Text('Total ${q['total']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        );
      case 'support_contacts':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.tonalIcon(onPressed: () => onOpen('/support'), icon: const Icon(Icons.headset_mic_rounded, size: 18), label: const Text('Open Support')),
        );
      case 'support_ticket':
        return Padding(padding: const EdgeInsets.only(top: 6), child: Text('Ticket ${card['ticket_id']} opened', style: const TextStyle(fontWeight: FontWeight.w700)));
      case 'payment_link':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse('${card['url']}'), mode: LaunchMode.inAppBrowserView),
            icon: const Icon(Icons.lock_rounded),
            label: Text('Pay ${card['amount']} securely'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ApprovalView extends StatelessWidget {
  const _ApprovalView({required this.approval, required this.onDecide});
  final ChatApproval approval;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final preview = approval.preview;
    final order = preview['order'] is Map ? Map<String, dynamic>.from(preview['order'] as Map) : null;
    final parcel = preview['parcel'] is Map ? Map<String, dynamic>.from(preview['parcel'] as Map) : null;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: brandRed, width: 2), borderRadius: BorderRadius.circular(GmRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${preview['title'] ?? 'Approve this action?'}', style: const TextStyle(fontWeight: FontWeight.w800)),
        if (order != null) ...[
          for (final item in (order['items'] as List? ?? const [])) Text('$item'),
          Text('Total ${order['total']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          if (order['estimated_arrival'] != null) Text('Arrives ~${order['estimated_arrival']}'),
        ],
        if (parcel != null) ...[
          Text('From ${parcel['from']}'),
          Text('To ${parcel['to']}'),
          Text('Total ${parcel['total']}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
        if (preview['message'] != null) Text('${preview['message']}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(children: [
          FilledButton(onPressed: () => onDecide(true), child: const Text('Approve')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () => onDecide(false), child: const Text('Not now')),
        ]),
      ]),
    );
  }
}
