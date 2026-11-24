import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../providers.dart';
import 'kyc_screen.dart';

/// "Become our rider" (docs/adr/0027-rider-kyc.md): full name, WhatsApp number, email and residential address, plus
/// a password when there is no account yet. Then straight on to the KYC.
class RiderSignUpScreen extends ConsumerStatefulWidget {
  const RiderSignUpScreen({super.key});

  @override
  ConsumerState<RiderSignUpScreen> createState() => _RiderSignUpScreenState();
}

class _RiderSignUpScreenState extends ConsumerState<RiderSignUpScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  String _vehicle = 'motorcycle';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _name.text = user?.name ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _check(bool needsPassword) {
    if (_name.text.trim().length < 2) return 'Enter your full name';
    if (_phone.text.trim().length < 7) return 'Enter your WhatsApp number';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) return 'Enter a valid email address';
    if (_address.text.trim().length < 5) return 'Enter where you live';
    if (needsPassword && _password.text.length < 6) return 'Choose a password of at least 6 characters';
    return null;
  }

  Future<void> _signUp() async {
    final auth = ref.read(authRepositoryProvider);
    final hasAccount = auth.currentUser != null;
    final problem = _check(!hasAccount);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!hasAccount) await auth.signUpWithEmail(_name.text.trim(), _email.text.trim(), _password.text);
      await ref.read(apiProvider).applyAsRider({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'residential_address': _address.text.trim(),
        'vehicle': _vehicle,
        'city': 'Lagos',
      });
      await auth.refreshToken(); // the account is now a rider: the next requests must carry that
      ref.invalidate(riderProfileProvider);
      ref.invalidate(riderKycProvider);
      if (mounted) context.go('/kyc');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e'.contains('email-already-in-use')
          ? 'This email already has an account: sign in with it instead.'
          : 'Sign-up failed. Check your details and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = ref.watch(authRepositoryProvider).currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Become our rider')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Sign up, then complete your KYC in this app. When the team has checked it you get the Verified '
              'badge and can start delivering.'),
          const SizedBox(height: 16),
          TextField(key: const ValueKey('name'), controller: _name, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(key: const ValueKey('phone'), controller: _phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp phone number', hintText: '+234 803 000 0000')),
          const SizedBox(height: 12),
          TextField(key: const ValueKey('email'), controller: _email, keyboardType: TextInputType.emailAddress,
              enabled: !hasAccount, decoration: const InputDecoration(labelText: 'Email')),
          if (!hasAccount) ...[
            const SizedBox(height: 12),
            TextField(key: const ValueKey('password'), controller: _password, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (at least 6 characters)')),
          ],
          const SizedBox(height: 12),
          TextField(key: const ValueKey('address'), controller: _address,
              decoration: const InputDecoration(labelText: 'Residential address')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _vehicle,
            decoration: const InputDecoration(labelText: 'Vehicle'),
            items: const [
              DropdownMenuItem(value: 'motorcycle', child: Text('Motorcycle')),
              DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
              DropdownMenuItem(value: 'car', child: Text('Car')),
            ],
            onChanged: (v) => setState(() => _vehicle = v ?? 'motorcycle'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('sign-up'),
            onPressed: _busy ? null : _signUp,
            child: const Text('Sign up as a rider'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
