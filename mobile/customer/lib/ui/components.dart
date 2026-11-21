import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../features/location/address_picker.dart' show LocationUnavailable, customerLocationProvider;
import '../providers.dart';
import 'illustrations.dart';

/// The red of the Yummy Chops logo (design tokens), and the warm orange-red the header gradient starts from.
const brandRed = GmLight.primary;
const brandWarm = Color(0xFFF25C22);
const brandGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [brandWarm, brandRed]);

/// Bottom edge shaped like a soft wave (home and discover headers).
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final h = size.height, w = size.width;
    return Path()
      ..lineTo(0, h - 30)
      ..cubicTo(w * .25, h - 4, w * .55, h - 46, w, h - 18)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// The address pill at the top of Home and the service pages: shows the delivery area, opens the area picker.
class AddressPill extends ConsumerWidget {
  const AddressPill({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(areaProvider);
    final fg = onDark ? const Color(0xFF3A1A0C) : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: 'Delivering to ${area.name}, ${area.cityName}. Change area',
      child: Material(
        color: onDark ? Colors.white.withValues(alpha: .9) : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showAreaPicker(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on_rounded, size: 18, color: brandRed),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: Text('${area.name}, ${area.cityName}',
                    overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 15)),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: fg),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The delivery area nearest to [here], or null when even the nearest is more than [withinKm] away
/// (Yummy Chops does not deliver there).
Area? nearestArea(GeoPoint here, List<Area> areas, {double withinKm = 25}) {
  Area? nearest;
  var best = double.infinity;
  for (final area in areas) {
    final km = _kmBetween(here, area.location);
    if (km < best) {
      best = km;
      nearest = area;
    }
  }
  return best <= withinKm ? nearest : null;
}

/// Great-circle distance in kilometres.
double _kmBetween(GeoPoint a, GeoPoint b) {
  const toRad = math.pi / 180;
  final dLat = (b.lat - a.lat) * toRad;
  final dLng = (b.lng - a.lng) * toRad;
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(a.lat * toRad) * math.cos(b.lat * toRad) * math.pow(math.sin(dLng / 2), 2);
  return 2 * 6371 * math.asin(math.min(1, math.sqrt(h)));
}

Future<void> showAreaPicker(BuildContext context, WidgetRef ref) async {
  final picked = await showModalBottomSheet<Area>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AreaPicker(),
  );
  if (picked != null) ref.read(areaProvider.notifier).select(picked);
}

class _AreaPicker extends ConsumerStatefulWidget {
  const _AreaPicker();

  @override
  ConsumerState<_AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends ConsumerState<_AreaPicker> {
  String _q = '';
  bool _locating = false;
  String? _gpsNote;

  /// "Use my current location": the delivery area nearest to the phone's GPS fix.
  Future<void> _useMyLocation(List<Area> all) async {
    setState(() {
      _locating = true;
      _gpsNote = null;
    });
    try {
      final here = await ref.read(customerLocationProvider).current();
      final nearest = nearestArea(here, all);
      if (!mounted) return;
      if (nearest == null) {
        setState(() => _gpsNote = 'Yummy Chops does not deliver where you are yet. Choose the area to deliver to.');
      } else {
        Navigator.of(context).pop(nearest);
      }
    } on LocationUnavailable catch (e) {
      if (mounted) setState(() => _gpsNote = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(areasProvider);
    final current = ref.watch(areaProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Where should we deliver?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Yummy Chops delivers in Lagos and Enugu.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              autofocus: false,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search your area'),
              onChanged: (v) => setState(() => _q = v.toLowerCase().trim()),
            ),
            ListTile(
              key: const ValueKey('area-use-my-location'),
              contentPadding: EdgeInsets.zero,
              leading: _locating
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location_rounded, color: brandRed),
              title: const Text('Use my current location', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_gpsNote ?? 'Finds the delivery area nearest to you'),
              onTap: _locating ? null : () => _useMyLocation(areas.value ?? const []),
            ),
          ]),
        ),
        Expanded(
          child: areas.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (list) {
              final shown = list.where((a) => _q.isEmpty || a.name.toLowerCase().contains(_q)).toList();
              final byCity = <String, List<Area>>{};
              for (final a in shown) {
                byCity.putIfAbsent(a.cityName, () => []).add(a);
              }
              return ListView(children: [
                for (final entry in byCity.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(entry.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .8, fontSize: 12)),
                  ),
                  for (final a in entry.value)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(a.name),
                      trailing: a == current ? Icon(Icons.check_circle_rounded, color: brandRed) : null,
                      onTap: () => Navigator.of(context).pop(a),
                    ),
                ],
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.onMore, this.info});
  final String text;
  final VoidCallback? onMore;
  final String? info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Flexible(child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            if (info != null)
              IconButton(
                tooltip: info,
                visualDensity: VisualDensity.compact,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(info!))),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
              ),
          ]),
        ),
        if (onMore != null)
          IconButton.filledTonal(tooltip: 'See all', onPressed: onMore, icon: const Icon(Icons.arrow_forward_rounded)),
      ]),
    );
  }
}

/// Branded art for a store until it uploads photos: warm gradient, initials and a faint illustration.
class MerchantArt extends StatelessWidget {
  const MerchantArt({super.key, required this.merchant, this.height = 150, this.compact = false});
  final RestaurantCard merchant;
  final double height;
  final bool compact;

  static const _food = [
    [Color(0xFFE0040B), Color(0xFFF5A21A)],
    [Color(0xFFB4442A), Color(0xFFF28C5B)],
    [Color(0xFF7A2E12), Color(0xFFE2762E)],
    [Color(0xFF6B2410), Color(0xFFE8C468)],
  ];
  static const _beauty = [
    [Color(0xFFC2557A), Color(0xFFF6B9C6)],
    [Color(0xFF6E4AA8), Color(0xFFE2C7F4)],
    [Color(0xFF2E8B1E), Color(0xFFBFE5B0)],
  ];
  static const _grocery = [
    [Color(0xFF1F7A4D), Color(0xFFBFE8CF)],
    [Color(0xFF2B6CB0), Color(0xFFCFE3F7)],
    [Color(0xFF8A6A1F), Color(0xFFF3E2A9)],
  ];
  static const _pharmacy = [
    [Color(0xFF12746B), Color(0xFFBDEBE4)],
    [Color(0xFF2B5FA8), Color(0xFFCADDF6)],
  ];
  static const _market = [
    [Color(0xFF9A4A1B), Color(0xFFF4CF9C)],
    [Color(0xFF3F7A2E), Color(0xFFD6ECB8)],
  ];

  @override
  Widget build(BuildContext context) {
    if (merchant.coverUrl != null) {
      return Image.network(merchant.coverUrl!, height: height, width: double.infinity, fit: BoxFit.cover);
    }
    final palette = switch (merchant.vertical) {
      'beauty' => _beauty,
      'grocery' => _grocery,
      'pharmacy' => _pharmacy,
      'market' => _market,
      _ => _food,
    };
    final CustomPainter art = switch (merchant.vertical) {
      'beauty' => const BeautyIllustration(),
      'grocery' => const GroceryIllustration(),
      'pharmacy' => const PharmacyIllustration(),
      'market' => const MarketIllustration(),
      _ => const FoodIllustration(),
    };
    final colors = palette[merchant.id.codeUnits.fold(0, (a, c) => a + c) % palette.length];
    final initials = merchant.name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && w != '&').take(2).map((w) => w[0]).join();
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors[1], colors[0]])),
      child: Stack(children: [
        Positioned(
          right: -height * .12,
          bottom: -height * .14,
          width: height * (compact ? .9 : 1.05),
          height: height * (compact ? .9 : 1.05),
          child: Opacity(
            opacity: .9,
            child: CustomPaint(painter: art),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 10,
          child: Text(initials,
              style: TextStyle(color: Colors.white, fontSize: compact ? 26 : 34, fontWeight: FontWeight.w800, shadows: const [Shadow(blurRadius: 8, color: Colors.black26)])),
        ),
      ]),
    );
  }
}

String ratingPercent(double rating) => '${(rating * 20).round()}%';

String deliveryLabel(RestaurantCard r) {
  if (r.deliversToLocation == false) return 'Pickup only';
  final fee = r.deliveryFeeKobo;
  if (fee == null) return '';
  return fee == 0 ? 'Free delivery' : formatNaira(fee);
}

/// Large store card (image, promo badge, favourite heart, name, rating, ETA, fee).
class MerchantCard extends ConsumerWidget {
  const MerchantCard({super.key, required this.merchant, required this.onTap});
  final RestaurantCard merchant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = merchant;
    final theme = Theme.of(context);
    final fav = ref.watch(favouritesProvider).contains(r.id);
    final available = r.isOpen && r.isAcceptingOrders;
    final promo = r.promotions.isEmpty ? null : r.promotions.first;
    return Semantics(
      button: true,
      label: '${r.name}, ${ratingPercent(r.rating)} positive${available ? '' : ', closed'}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: InkWell(
          borderRadius: BorderRadius.circular(GmRadius.xl),
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(GmRadius.xl),
              child: Stack(children: [
                Opacity(opacity: available ? 1 : .55, child: MerchantArt(merchant: r, height: 170)),
                if (promo != null)
                  Positioned(left: 12, top: 12, child: PromoTag(promo.label)),
                if (!available)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                        child: Text(r.isOpen ? 'Not taking orders' : 'Closed now',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      tooltip: fav ? 'Remove from favourites' : 'Add to favourites',
                      onPressed: () => ref.read(favouritesProvider.notifier).toggle(r.id),
                      icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? const Color(0xFFE0040B) : const Color(0xFF2A0D06)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(r.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Color(0xFF2E8B1E)),
                Text(ratingPercent(r.rating)),
                if (r.etaMinutes != null) Text('·  ${r.etaMinutes} min'),
                if (deliveryLabel(r).isNotEmpty) ...[
                  const Text('·'),
                  const Icon(Icons.delivery_dining_rounded, size: 16),
                  Text(deliveryLabel(r)),
                ],
                if (r.cuisines.isNotEmpty) Text('·  ${r.cuisines.take(2).join(', ')}'),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class PromoTag extends StatelessWidget {
  const PromoTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE0040B), borderRadius: BorderRadius.circular(6)),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Square store logo tile ("Popular brands", "These are for you").
class BrandTile extends StatelessWidget {
  const BrandTile({super.key, required this.merchant, required this.onTap, this.size = 104});
  final RestaurantCard merchant;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = merchant;
    final promo = r.promotions.isNotEmpty;
    final fee = r.deliveryFeeKobo;
    return SizedBox(
      width: size,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GmRadius.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(GmRadius.lg),
            child: SizedBox(width: size, height: size, child: MerchantArt(merchant: r, height: size, compact: true)),
          ),
          const SizedBox(height: 6),
          Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (promo || fee != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: promo ? const Color(0xFFE0040B) : const Color(0xFFF4E8E3), borderRadius: BorderRadius.circular(6)),
              child: Text(
                promo ? 'Promo' : (fee == 0 ? 'Free' : formatNaira(fee)),
                style: TextStyle(color: promo ? Colors.white : const Color(0xFF3A0D05), fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Round category bubble ("Promotions", "Local food", "Skincare"...).
class CategoryBubble extends StatelessWidget {
  const CategoryBubble({super.key, required this.label, required this.emoji, required this.selected, required this.onTap});
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 86,
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                border: Border.all(color: selected ? brandRed : Colors.transparent, width: 2),
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(child: Text(emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

/// Pill-shaped filter button ("Food type ▾", "Pickup", "Sort by ▾").
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.onTap, this.icon, this.selected = false, this.dropdown = false});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        shape: StadiumBorder(side: BorderSide(color: selected ? brandRed : Colors.transparent)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (dropdown) const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Something customers should know before they shop in a service (over-the-counter only, market measures).
class ServiceNote extends StatelessWidget {
  const ServiceNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(GmRadius.md)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSecondaryContainer),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer, height: 1.3))),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(GmRadius.lg), border: Border.all(color: scheme.outline)),
      child: Column(children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surfaceContainerHighest),
          child: Icon(icon, size: 36, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
        if (action != null) ...[const SizedBox(height: 14), action!],
      ]),
    );
  }
}

