import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../brand.dart';
import '../providers.dart';

class RiderSignInScreen extends ConsumerStatefulWidget {
  const RiderSignInScreen({super.key});

  @override
  ConsumerState<RiderSignInScreen> createState() => _RiderSignInScreenState();
}

class _RiderSignInScreenState extends ConsumerState<RiderSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          const Center(child: YummyChopsLogo(height: 150)),
          const SizedBox(height: 16),
          Text('Yummy Chops Rider', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          const Text('Sign in with your rider account. New riders sign up first, then complete their KYC here.'),
          const SizedBox(height: 32),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() {
                      _busy = true;
                      _error = null;
                    });
                    try {
                      await ref.read(authRepositoryProvider).signInWithEmail(_email.text.trim(), _password.text);
                    } catch (_) {
                      setState(() => _error = 'Sign-in failed. Check your email and password.');
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: const Text('Sign in'),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('become-a-rider'),
            onPressed: () => context.push('/sign-up'),
            child: const Text('New here? Become our rider'),
          ),
        ]),
      ),
    );
  }
}
