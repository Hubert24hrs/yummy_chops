import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/bubbles.dart';
import '../../ui/components.dart';
import '../../ui/illustrations.dart';
import '../../widgets.dart';

/// Home, kept minimal like Glovo's: the six services as floating bubbles on the red header (two rows of three, in
/// the owner's order: Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, Package Delivery),
/// then the places picked for the customer. No banners or explanations (the website and Profile have those); deals show as
/// a "Promo" tag on the shop tiles, and Yummy floats over every tab.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    // No name (a guest, or an account without one): no "Ada, …" in front of the title.
    final first = (user?.name?.trim() ?? '').split(' ').first;
    final forYou = ref.watch(forYouProvider);
    final area = ref.watch(areaProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(forYouProvider);
          ref.invalidate(merchantsProvider);
          await ref.read(forYouProvider.future).catchError((_) => <RestaurantCard>[]);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: const WaveClipper(),
              child: Container(
                decoration: const BoxDecoration(gradient: brandGradient),
                padding: EdgeInsets.only(top: top + 12, bottom: 44),
                child: Column(children: [
                  const Center(child: AddressPill(onDark: true)),
                  const SizedBox(height: 8),
                  ServiceBubbleField(
                    height: 352,
                    bubbles: [
                      BubbleSpec(
                          id: 'food', label: foodService.title, art: const FoodIllustration(), relSize: 1.08, onTap: () => context.push(foodService.route)),
                      BubbleSpec(
                          id: 'pharmacy', label: pharmacyService.title, art: const PharmacyIllustration(), onTap: () => context.push(pharmacyService.route)),
                      BubbleSpec(id: 'beauty', label: beautyService.title, art: const BeautyIllustration(), onTap: () => context.push(beautyService.route)),
                      BubbleSpec(
                          id: 'grocery', label: groceryService.title, art: const GroceryIllustration(), onTap: () => context.push(groceryService.route)),
                      BubbleSpec(id: 'market', label: marketService.title, art: const MarketIllustration(), onTap: () => context.push(marketService.route)),
                      BubbleSpec(id: 'parcel', label: 'Package Delivery', art: const ParcelIllustration(), onTap: () => context.push('/send')),
                    ],
                  ),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionTitle(first.isEmpty ? 'These are for you' : '$first, these are for you',
                info: 'Top-rated places near ${area.name}, picked for you', onMore: () => context.go('/discover')),
          ),
          SliverToBoxAdapter(
            child: forYou.when(
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(forYouProvider)),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Nothing nearby yet',
                      body: 'We are adding partners in ${area.cityName}. Try another area.',
                      action: OutlinedButton(onPressed: () => showAreaPicker(context, ref), child: const Text('Change area')),
                    )
                  : SizedBox(
                      height: 168,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => BrandTile(merchant: list[i], onTap: () => context.push('/restaurants/${list[i].id}')),
                      ),
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ]),
      ),
    );
  }
}
