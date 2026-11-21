import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';

/// Connect WhatsApp: a one-time code the customer sends to Yummy Chops on WhatsApp, then chat with Yummy there.
class WhatsAppSheet extends ConsumerStatefulWidget {
  const WhatsAppSheet({super.key});

  @override
  ConsumerState<WhatsAppSheet> createState() => _WhatsAppSheetState();
}

class _WhatsAppSheetState extends ConsumerState<WhatsAppSheet> {
  WhatsAppLinkCode? _code;
  Timer? _poll;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run(() async {
        final code = await ref.read(apiProvider).whatsAppLinkCode();
        setState(() => _code = code);
        // Watch for the customer sending the code from WhatsApp.
        _poll = Timer.periodic(const Duration(seconds: 4), (_) => ref.invalidate(whatsAppStatusProvider));
      });

  Future<void> _disconnect() => _run(() async {
        await ref.read(apiProvider).disconnectWhatsApp();
        _code = null;
        ref.invalidate(whatsAppStatusProvider);
      });

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(whatsAppStatusProvider);
    final theme = Theme.of(context);
    final linked = status.asData?.value.linked ?? false;
    if (linked && _poll != null) {
      _poll?.cancel();
      _poll = null;
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: status.when(
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text(e is ApiException ? e.message : 'Could not load WhatsApp'),
          data: (s) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Order on WhatsApp', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            if (!s.enabled)
              const Text('Chatting with Yummy on WhatsApp is coming soon.')
            else if (s.linked) ...[
              Text('Yummy knows your WhatsApp number ${s.number}. Order, track and get help in a chat; you still approve '
                  'every order and pay on the secure page.'),
              const SizedBox(height: 12),
              if (s.chatLink != null)
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(s.chatLink!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Chat with Yummy'),
                ),
              OutlinedButton(key: const ValueKey('whatsapp-disconnect'), onPressed: _busy ? null : _disconnect, child: const Text('Disconnect')),
            ] else if (_code case final code?) ...[
              Text('Send this code to Yummy Chops on WhatsApp (${code.businessNumber}) before ${formatLagosTime(code.expiresAt)}:'),
              const SizedBox(height: 8),
              SelectableText(code.code,
                  key: const ValueKey('whatsapp-code'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 8)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(code.waLink), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open WhatsApp'),
              ),
              const SizedBox(height: 6),
              Text('WhatsApp opens with the message ready: just tap send.', style: theme.textTheme.bodySmall),
            ] else ...[
              const Text('Order food, groceries, foodstuff, pharmacy items, beauty products and packages, track orders and get help by chatting with Yummy on WhatsApp.'),
              const SizedBox(height: 12),
              FilledButton(key: const ValueKey('whatsapp-connect'), onPressed: _busy ? null : _connect, child: const Text('Connect WhatsApp')),
            ],
            if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
          ]),
        ),
      ),
    );
  }
}
