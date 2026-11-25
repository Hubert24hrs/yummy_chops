import 'package:flutter/material.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../cart_controller.dart';

/// Pieces shared by the cart and checkout: round grey buttons, big bold titles, rows with an icon and a chevron,
/// a pill quantity stepper and the bar that stays at the bottom of the screen.

/// A round grey button with one icon (back, empty the cart, edit the address).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.size = 44});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
      ),
      icon: Icon(icon, size: size * 0.5),
    );
  }
}

/// The round back button of the cart and checkout (nothing when there is nowhere to go back to).
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Center(
        child: RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, tooltip: 'Back', size: 42, onPressed: () => Navigator.of(context).maybePop()),
      ),
    );
  }
}

/// "Your cart", "Checkout": the big bold title at the top of the page.
class BigTitle extends StatelessWidget {
  const BigTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5));
}

/// A section heading ("Delivery address", "Payment method", "Summary").
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(20, 28, 20, 12)});
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      );
}

/// "1 product from **Suya Lane**", "5 products from **3 shops**".
class ProductsFrom extends StatelessWidget {
  const ProductsFrom(this.cart, {super.key, this.style});
  final CartState cart;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final n = cart.count;
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    return Text.rich(
      TextSpan(style: base, children: [
        TextSpan(text: '$n ${n == 1 ? 'product' : 'products'} from '),
        TextSpan(text: cart.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// A row with an icon, a title, an optional line under it and a chevron (allergies, phone number, promo code).
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.trailing, this.subtitleColor});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 26, color: theme.colorScheme.onSurface),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor ?? theme.colorScheme.onSurfaceVariant)),
                ),
            ]),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded),
        ]),
      ),
    );
  }
}

/// The product's picture: its placeholder (an emoji) on a soft square, or a bag when it has none.
class ItemThumb extends StatelessWidget {
  const ItemThumb({super.key, this.emoji, this.size = 72, this.radius = 16});
  final String? emoji;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(radius)),
      child: emoji == null || emoji!.isEmpty
          ? Icon(Icons.fastfood_rounded, size: size * 0.42, color: scheme.primary)
          : Text(emoji!, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}

/// The pill on a cart line: a bin when there is one (removes the line), "−" otherwise, the quantity and "+".
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.quantity, required this.onChanged, this.max = 50});
  final int quantity;
  final ValueChanged<int>? onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final change = onChanged;
    return Container(
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(GmRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: quantity <= 1 ? 'Remove' : 'Remove one',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          onPressed: change == null ? null : () => change(quantity - 1),
          icon: Icon(quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded),
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(
          tooltip: 'Add one',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          onPressed: change == null || quantity >= max ? null : () => change(quantity + 1),
          icon: const Icon(Icons.add_rounded),
        ),
      ]),
    );
  }
}

/// A grey pill button ("Add more items", "Edit address").
class SoftPillButton extends StatelessWidget {
  const SoftPillButton({super.key, required this.label, required this.onPressed, this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
        minimumSize: Size(expand ? double.infinity : 64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

/// Two choices in a grey pill track (Delivery / Pickup).
class PillToggle<T> extends StatelessWidget {
  const PillToggle({super.key, required this.options, required this.value, required this.onChanged});
  final List<(T, String, IconData)> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(GmRadius.pill)),
      child: Row(children: [
        for (final (v, label, icon) in options)
          Expanded(
            child: Semantics(
              selected: v == value,
              button: true,
              child: Material(
                color: v == value ? scheme.surface : Colors.transparent,
                elevation: v == value ? 1 : 0,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onChanged == null || v == value ? null : () => onChanged!(v),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(icon, size: 18, color: v == value ? scheme.primary : scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: v == value ? scheme.onSurface : scheme.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A soft coloured box with an icon (Plus offer, savings).
class SoftBanner extends StatelessWidget {
  const SoftBanner({super.key, required this.icon, required this.child, this.color});
  final IconData icon;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(GmRadius.md)),
      child: Row(children: [
        Icon(icon, color: tint, size: 28),
        const SizedBox(width: 12),
        Expanded(child: child),
      ]),
    );
  }
}

/// The bar that stays at the bottom of the cart and checkout.
class StickyBottomBar extends StatelessWidget {
  const StickyBottomBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), child: child)),
    );
  }
}

/// The amber of warnings ("Far from current location"), from the design tokens.
Color warningColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? GmDark.warning : GmLight.warning;

/// The green of savings, from the design tokens.
Color successColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? GmDark.success : GmLight.success;
