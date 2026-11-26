import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../location/address_picker.dart';
import 'account_section.dart';
import 'whatsapp_sheet.dart';
import '../../ui/components.dart';

/// Profile: who you are, your addresses, deals, payments, settings and help. The only place to sign in: a guest
/// (guest mode, see features/auth/guest_session.dart) can save their account here with Google or Apple.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final guest = user == null || user.isAnonymous;
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final name = (user?.name?.trim().isNotEmpty ?? false) ? user!.name!.trim() : null;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: brandGradient),
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 36),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3A0D05), foregroundColor: Colors.white),
                    onPressed: () => context.go('/support'),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('Help'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFFFDE7E6),
                      child: name == null
                          ? const Icon(Icons.person_rounded, size: 36, color: Color(0xFFB3050B))
                          : Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFB3050B)),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Welcome to Yummy Chops',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(guest ? "You're ordering as a guest" : (user.email ?? user.phone ?? ''), style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            // A Material (not a coloured box), so taps on the rows below show their ripple.
            child: Material(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('Profile', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    if (guest) const SaveAccountCard(),
                    const HomeAddressTile(),
                    const FingerprintTile(),
                    ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: const Text('Order history'),
                      trailing: FilledButton.tonal(onPressed: () => context.go('/orders'), child: const Text('View in Orders')),
                    ),
                    if (!guest) _tile(context, Icons.person_outline_rounded, 'Account', onTap: () => _account(context, user)),
                    _tile(context, Icons.location_on_outlined, 'Saved addresses', onTap: () => _addresses(context)),
                    _tile(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Yummy Chops wallet',
                      badge: ref.watch(walletProvider).asData?.value.balanceKobo == null ? null : formatNaira(ref.watch(walletProvider).asData!.value.balanceKobo),
                      onTap: () => context.push('/wallet'),
                    ),
                    _tile(context, Icons.receipt_long_outlined, 'My receipts', onTap: () => context.push('/receipts')),
                    _tile(context, Icons.restaurant_menu_outlined, 'Food preferences', onTap: () => showFoodPreferences(context)),
                    _tile(context, Icons.local_offer_outlined, 'Promo codes', onTap: () => _promos(context, ref)),
                    _tile(context, Icons.credit_card_outlined, 'Payments', onTap: () => _payments(context)),
                    _tile(context, Icons.workspace_premium_outlined, 'Yummy Chops Plus', badge: 'Free delivery', onTap: () => context.push('/plus')),
                    _tile(context, Icons.card_giftcard_rounded, 'Yummy points and invite friends', onTap: () => context.push('/rewards')),
                    _tile(context, Icons.groups_outlined, 'Group orders', onTap: () => context.push('/group')),
                    _tile(
                      context,
                      Icons.chat_outlined,
                      'Order on WhatsApp',
                      onTap: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const WhatsAppSheet()),
                    ),
                    _tile(context, Icons.settings_outlined, 'App settings', onTap: () => _settings(context, ref)),
                    _tile(context, Icons.local_shipping_outlined, 'Track a package', onTap: () => context.push('/track')),
                    _tile(context, Icons.storefront_outlined, 'Register your business', onTap: () => context.push('/partner-with-us')),
                    _tile(context, Icons.pedal_bike_rounded, 'Ride with Yummy Chops', onTap: () => context.push('/ride')),
                    _tile(context, Icons.quiz_outlined, 'FAQ, privacy and terms', onTap: () => context.push('/help')),
                    if (user != null) _tile(context, Icons.download_outlined, 'Download my data', onTap: () => showMyData(context, ref)),
                    // Signing out starts afresh with a new guest; a guest has nothing to sign out of.
                    if (!guest) _tile(context, Icons.logout_rounded, 'Sign out', danger: true, onTap: () => signOutOfProfile(ref)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {required VoidCallback onTap, String? badge, bool danger = false}) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Row(
            children: [
              // Long titles and large text sizes wrap instead of running off the screen.
              Flexible(
                child: Text(title, style: TextStyle(color: color, fontSize: 16)),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF4E8E3), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3A0D05)),
                  ),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  void _account(BuildContext context, GmUser user) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Name'), subtitle: Text(user.name ?? 'Not set')),
          ListTile(leading: const Icon(Icons.mail_outline_rounded), title: const Text('Email'), subtitle: Text(user.email ?? 'Not set')),
          ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Phone'), subtitle: Text(user.phone ?? 'Not set')),
        ],
      ),
    ),
  );

  void _payments(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Card, bank transfer or USSD'),
              subtitle: Text('Paid on a secure payment page. Yummy Chops never stores your card.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.account_balance_wallet_outlined),
              title: Text('Yummy Chops wallet'),
              subtitle: Text('Top up once, pay in one tap, and get refunds instantly. Open it from your profile.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.payments_outlined),
              title: Text('Pay on delivery'),
              subtitle: Text('Pay the rider in cash for food and beauty orders, after your first completed order.'),
            ),
          ],
        ),
      ),
    ),
  );

  void _promos(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final deals = [
          ...?ref.watch(merchantsProvider((vertical: 'food', category: 'promotions', pickup: false, sort: 'recommended', query: null, cuisine: null))).value,
          ...?ref.watch(merchantsProvider((vertical: 'beauty', category: 'promotions', pickup: false, sort: 'recommended', query: null, cuisine: null))).value,
        ];
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .6,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const Text('Deals near you', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Enter the code at checkout.'),
                const SizedBox(height: 8),
                if (deals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No deals in your area right now')),
                  ),
                for (final m in deals)
                  for (final p in m.promotions)
                    Card(
                      child: ListTile(
                        title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(m.name),
                        trailing: Chip(
                          label: Text(p.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5)),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/restaurants/${m.id}');
                        },
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    ),
  );

  void _settings(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final mode = ref.watch(themeModeProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (m) => ref.read(themeModeProvider.notifier).set(m ?? ThemeMode.system),
                child: const Column(
                  children: [
                    RadioListTile(value: ThemeMode.system, title: Text('Match my phone')),
                    RadioListTile(value: ThemeMode.light, title: Text('Light')),
                    RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Delivery area'),
                subtitle: Text('${ref.watch(areaProvider).name}, ${ref.watch(areaProvider).cityName}'),
                onTap: () => showAreaPicker(context, ref),
              ),
            ],
          ),
        );
      },
    ),
  );

  void _addresses(BuildContext context) => showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true, builder: (_) => const _AddressBook());
}

class _AddressBook extends ConsumerStatefulWidget {
  const _AddressBook();

  @override
  ConsumerState<_AddressBook> createState() => _AddressBookState();
}

class _AddressBookState extends ConsumerState<_AddressBook> {
  final _line = TextEditingController();
  final _label = TextEditingController(text: 'Home');
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _line.dispose();
    _label.dispose();
    super.dispose();
  }

  /// Search or GPS through the map picker: saves the exact pin the customer confirmed.
  Future<void> _addFromMap() async {
    final picked = await pickDeliveryAddress(context, title: 'Add an address');
    if (picked == null || !mounted) return;
    try {
      final label = picked.address.label ?? (_label.text.trim().isEmpty ? 'Home' : _label.text.trim());
      await ref.read(apiProvider).saveAddress(picked.address.copyWith(label: label));
      ref.invalidate(addressesProvider);
      setState(() => _error = null);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _save() async {
    final area = ref.read(areaProvider);
    if (_line.text.trim().length < 3) {
      setState(() => _error = 'Enter the street address');
      return;
    }
    try {
      await ref
          .read(apiProvider)
          .saveAddress(
            DeliveryAddress(
              label: _label.text.trim().isEmpty ? null : _label.text.trim(),
              line1: _line.text.trim(),
              area: area.name,
              city: area.cityName,
              state: area.cityName,
              location: area.location,
            ),
          );
      ref.invalidate(addressesProvider);
      setState(() {
        _adding = false;
        _line.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(addressesProvider);
    final area = ref.watch(areaProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Saved addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          saved.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                if (list.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No saved addresses yet')),
                for (final a in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_rounded),
                    title: Text(a.label ?? a.line1),
                    subtitle: Text([a.line1, a.area, a.city].whereType<String>().join(', ')),
                  ),
              ],
            ),
          ),
          if (_adding) ...[
            Text('In ${area.name}, ${area.cityName}', style: Theme.of(context).textTheme.bodySmall),
            TextButton(onPressed: () => showAreaPicker(context, ref), child: const Text('Change area')),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label (Home, Work…)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _line,
              decoration: const InputDecoration(labelText: 'Street address and landmark'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Save address')),
          ] else ...[
            FilledButton.tonalIcon(onPressed: _addFromMap, icon: const Icon(Icons.map_rounded), label: const Text('Find on map')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => setState(() => _adding = true), icon: const Icon(Icons.add_rounded), label: const Text('Add address')),
          ],
        ],
      ),
    );
  }
}

/// Food preferences (the website's account page): allergies, diet, and whether orders may shape recommendations.
Future<void> showFoodPreferences(BuildContext context) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _FoodPreferencesSheet());

class _FoodPreferencesSheet extends ConsumerStatefulWidget {
  const _FoodPreferencesSheet();

  @override
  ConsumerState<_FoodPreferencesSheet> createState() => _FoodPreferencesState();
}

class _FoodPreferencesState extends ConsumerState<_FoodPreferencesSheet> {
  final _allergens = TextEditingController();
  final _dietary = TextEditingController();
  bool _personalise = false;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _allergens.dispose();
    _dietary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await ref.read(apiProvider).foodPreferences();
      if (!mounted) return;
      setState(() {
        _allergens.text = p.allergens.join(', ');
        _dietary.text = p.dietary.join(', ');
        _personalise = p.personalise;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ref.read(apiProvider).saveFoodPreferences(FoodPreferences(allergens: FoodPreferences.split(_allergens.text), dietary: FoodPreferences.split(_dietary.text), personalise: _personalise));
      if (mounted) setState(() => _message = 'Preferences saved');
    } on ApiException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: _loading
          ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Food preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _allergens,
                  decoration: const InputDecoration(labelText: 'Allergies', helperText: 'Comma separated, e.g. peanuts, shellfish. Yummy never recommends these.', helperMaxLines: 2),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dietary,
                  decoration: const InputDecoration(labelText: 'Dietary preferences', helperText: 'e.g. vegetarian, halal'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _personalise,
                  onChanged: (v) => setState(() => _personalise = v),
                  title: const Text('Personalise recommendations using my orders and preferences'),
                ),
                if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_message!)),
                FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save preferences')),
              ],
            ),
    );
  }
}

/// "Download my data" (the website's account page): everything Yummy Chops holds about the customer, to read and copy.
Future<void> showMyData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final data = await ref.read(apiProvider).exportMyData();
    if (!context.mounted) return;
    final text = const JsonEncoder.withIndent('  ').convert(data);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        maxChildSize: .95,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Your data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Everything Yummy Chops holds about you: ${data.keys.join(', ')}.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  messenger.showSnackBar(const SnackBar(content: Text('Your data is copied. Paste it into a note or an email to keep it.')));
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy my data'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
