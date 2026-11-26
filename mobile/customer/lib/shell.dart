import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/location/delivery_location.dart';
import 'providers.dart';
import 'ui/components.dart';
import 'ui/gudy.dart';

/// Tab shell: Home · Discover · Orders · Support · Profile, with Yummy floating above every tab.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    // Guest mode: on first launch the app signs in a guest by itself, and a customer with no saved address is asked
    // where to deliver once. (Signing in from the Sign in screen asks there.)
    ref.listen(askWhereToDeliverProvider, (_, ask) {
      if (!ask || ref.read(authRepositoryProvider).currentUser?.isAnonymous != true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) askWhereToDeliverIfNeeded(context, ref);
      });
    });
    final initial = (user?.name?.trim().isNotEmpty ?? false) ? user!.name!.trim()[0].toUpperCase() : null;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(children: [
          Positioned.fill(child: shell),
          GudyFab(bounds: constraints.biggest, onOpen: () => context.push('/assistant')),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.manage_search_rounded), label: 'Discover'),
          const NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
          const NavigationDestination(icon: Icon(Icons.headset_mic_outlined), selectedIcon: Icon(Icons.headset_mic_rounded), label: 'Support'),
          NavigationDestination(
            icon: _ProfileIcon(initial: initial, selected: false),
            selectedIcon: _ProfileIcon(initial: initial, selected: true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon({required this.initial, required this.selected});
  final String? initial;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (initial == null) return Icon(selected ? Icons.person_rounded : Icons.person_outline_rounded);
    return CircleAvatar(
      radius: 13,
      backgroundColor: selected ? brandRed : const Color(0xFFF2A39C),
      child: Text(initial!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
