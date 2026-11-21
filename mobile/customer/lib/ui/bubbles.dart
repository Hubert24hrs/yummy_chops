import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// One service bubble on the home screen.
class BubbleSpec {
  const BubbleSpec({required this.id, required this.label, required this.art, required this.onTap, this.relSize = 1});
  final String id;
  final String label;
  final CustomPainter art;
  final VoidCallback onTap;

  /// Relative diameter (1 = default).
  final double relSize;
}

/// Rest positions for six services: two rows of three.
const sixBubbleLayout = [
  Offset(.19, .19),
  Offset(.5, .16),
  Offset(.81, .19),
  Offset(.19, .65),
  Offset(.5, .62),
  Offset(.81, .65),
];

class _Body {
  _Body(this.spec, this.home, this.radius, this.phase) : pos = home;
  final BubbleSpec spec;
  Offset home;
  Offset pos;
  Offset vel = Offset.zero;
  double radius;
  final double phase;
  bool dragging = false;
  bool pressed = false;
  Offset target = Offset.zero;
}

/// Animated, finger-draggable service bubbles.
///
/// Bubbles pop in, float gently, follow the finger when dragged (pushing neighbours aside), and spring back to
/// their place with a soft wobble when released. A tap opens the service. Floating is disabled when the platform
/// asks for reduced motion; dragging always works.
class ServiceBubbleField extends StatefulWidget {
  const ServiceBubbleField({super.key, required this.bubbles, this.height = 340, this.layout});
  final List<BubbleSpec> bubbles;
  final double height;

  /// Rest positions as fractions of the field (by default three big bubbles, or two rows of three for six).
  final List<Offset>? layout;

  @override
  State<ServiceBubbleField> createState() => _ServiceBubbleFieldState();
}

class _ServiceBubbleFieldState extends State<ServiceBubbleField> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final List<_Body> _bodies = [];
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  double _t = 0;
  bool _reduceMotion = false;

  static const _defaultLayout = [Offset(.29, .33), Offset(.72, .36), Offset(.49, .75)];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _layout(Size size) {
    if (size == _size && _bodies.isNotEmpty) return;
    _size = size;
    // Three services: big bubbles that fill the red header, as on Glovo's home screen. Five or more share the
    // field: smaller bubbles, three to a row.
    final many = widget.bubbles.length > 4;
    final layout = widget.layout ?? (many ? sixBubbleLayout : _defaultLayout);
    final base = many ? math.min(size.width * .135, 58.0) : math.min(size.width * .19, 82.0);
    if (_bodies.isEmpty) {
      for (var i = 0; i < widget.bubbles.length; i++) {
        final spec = widget.bubbles[i];
        final r = base * spec.relSize;
        final rel = layout[i % layout.length];
        final home = _inBounds(Offset(rel.dx * size.width, rel.dy * size.height), r);
        _bodies.add(_Body(spec, home, r, i * 1.7));
      }
    } else {
      for (var i = 0; i < _bodies.length; i++) {
        final r = base * _bodies[i].spec.relSize;
        final rel = layout[i % layout.length];
        _bodies[i]
          ..radius = r
          ..home = _inBounds(Offset(rel.dx * size.width, rel.dy * size.height), r);
      }
    }
    _wake();
  }

  /// Where a bubble of radius [r] may be: fully on screen, with room for its label below.
  Offset _inBounds(Offset p, double r) => Offset(
        p.dx.clamp(r, math.max(r, _size.width - r)).toDouble(),
        p.dy.clamp(r, math.max(r, _size.height - r - 14)).toDouble(),
      );

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  Offset _float(_Body b) {
    if (_reduceMotion) return Offset.zero;
    return Offset(math.sin(_t * .9 + b.phase) * 7, math.cos(_t * 1.1 + b.phase * 1.3) * 6);
  }

  double _entrance(int i) {
    if (_reduceMotion) return 1;
    final p = ((_t - i * .12) / .7).clamp(0.0, 1.0);
    return Curves.elasticOut.transform(p);
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min((elapsed - _last).inMicroseconds / 1e6, 1 / 30);
    _last = elapsed;
    _t += dt;
    var moving = false;
    for (final b in _bodies) {
      if (b.dragging) {
        final next = Offset.lerp(b.pos, b.target, .45)!;
        b.vel = (next - b.pos) / dt;
        b.pos = next;
        moving = true;
        continue;
      }
      final goal = b.home + _float(b);
      final acc = (goal - b.pos) * 70 - b.vel * 9;
      b.vel += acc * dt;
      b.pos += b.vel * dt;
      if (b.vel.distance > 4 || (goal - b.pos).distance > .5) moving = true;
    }
    // Soft collisions: a dragged bubble shoves the others; resting bubbles share the push.
    for (var i = 0; i < _bodies.length; i++) {
      for (var j = i + 1; j < _bodies.length; j++) {
        final a = _bodies[i], b = _bodies[j];
        final d = b.pos - a.pos;
        final dist = d.distance;
        final min = (a.radius + b.radius) * .96;
        if (dist <= 0 || dist >= min) continue;
        final dir = d / dist;
        final overlap = min - dist;
        if (a.dragging && !b.dragging) {
          b.pos += dir * overlap;
          b.vel += dir * overlap * 30;
        } else if (b.dragging && !a.dragging) {
          a.pos -= dir * overlap;
          a.vel -= dir * overlap * 30;
        } else {
          a.pos -= dir * overlap / 2;
          b.pos += dir * overlap / 2;
        }
        moving = true;
      }
    }
    // Keep bubbles on screen with a little bounce.
    for (final b in _bodies) {
      final clamped = _inBounds(b.pos, b.radius);
      if (clamped.dx != b.pos.dx) b.vel = Offset(-b.vel.dx * .4, b.vel.dy);
      if (clamped.dy != b.pos.dy) b.vel = Offset(b.vel.dx, -b.vel.dy * .4);
      b.pos = clamped;
    }
    final entering = _bodies.indexed.any((e) => _entrance(e.$1) < 1);
    setState(() {});
    if (!moving && !entering && _reduceMotion) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, constraints) {
        _layout(Size(constraints.maxWidth, widget.height));
        return Stack(clipBehavior: Clip.none, children: [
          for (final (i, b) in _bodies.indexed) _bubble(i, b),
        ]);
      }),
    );
  }

  Widget _bubble(int i, _Body b) {
    final d = b.radius * 2;
    final tilt = (b.vel.dx / 2500).clamp(-.18, .18);
    final scale = _entrance(i) * (b.dragging ? 1.08 : (b.pressed ? .94 : 1.0));
    return Positioned(
      left: b.pos.dx - b.radius,
      top: b.pos.dy - b.radius,
      width: d,
      height: d + 26,
      child: Semantics(
        button: true,
        label: b.spec.label,
        onTap: b.spec.onTap,
        child: GestureDetector(
          key: ValueKey('bubble-${b.spec.id}'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => b.pressed = true),
          onTapCancel: () => setState(() => b.pressed = false),
          onTapUp: (_) {
            setState(() => b.pressed = false);
            HapticFeedback.lightImpact();
            b.spec.onTap();
          },
          onPanStart: (_) {
            HapticFeedback.selectionClick();
            b
              ..dragging = true
              ..pressed = false
              ..target = b.pos;
            _wake();
          },
          onPanUpdate: (details) {
            b.target += details.delta;
            _wake();
          },
          onPanEnd: (details) {
            b
              ..dragging = false
              ..vel = details.velocity.pixelsPerSecond * .6;
            _wake();
          },
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: scale,
              child: _BubbleFace(diameter: d, label: b.spec.label, art: b.spec.art, lifted: b.dragging),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleFace extends StatelessWidget {
  const _BubbleFace({required this.diameter, required this.label, required this.art, required this.lifted});
  final double diameter;
  final String label;
  final CustomPainter art;
  final bool lifted;

  static const _labelStyle = TextStyle(color: Color(0xFF2A0D06), fontWeight: FontWeight.w700, fontSize: 13, height: 1.15);

  /// The width a label needs: one line when it fits under the bubble, otherwise the narrowest width that keeps
  /// it to two lines of about the same length ("Beauty &" / "Skin Care"), never starting a line with "&".
  /// [style] must be the style the label is drawn with (the app's font), or the widths will not match.
  static double labelWidth(String label, double maxWidth, TextStyle style, TextScaler scaler) {
    double widthOf(String text) =>
        (TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)
              ..layout())
            .width;
    final words = label.split(' ');
    if (words.length < 2 || widthOf(label) <= maxWidth) return maxWidth;
    var best = maxWidth;
    for (var i = 1; i < words.length; i++) {
      if (words[i] == '&') continue;
      final both = math.max(widthOf(words.take(i).join(' ')), widthOf(words.skip(i).join(' ')));
      if (both < best) best = both;
    }
    return best.ceilToDouble() + 1;
  }

  @override
  Widget build(BuildContext context) {
    // Six services share the header: the smaller bubbles sit close together, so their labels are a little smaller.
    final small = diameter < 120;
    final padX = small ? 9.0 : 12.0;
    final labelPadding = padX * 2 + 2; // both sides, and the border
    final textMax = diameter * (small ? 1.06 : 1.08) - labelPadding;
    final style = DefaultTextStyle.of(context).style.merge(_labelStyle.copyWith(fontSize: small ? 12 : 13));
    final textWidth = labelWidth(label, textMax, style, MediaQuery.textScalerOf(context));
    return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
      // halo rings
      Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .22),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: lifted ? .22 : .12), blurRadius: lifted ? 26 : 16, offset: Offset(0, lifted ? 14 : 8)),
          ],
        ),
      ),
      Positioned(
        top: diameter * .06,
        child: Container(
          width: diameter * .88,
          height: diameter * .88,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          padding: EdgeInsets.all(diameter * .14),
          child: CustomPaint(painter: art),
        ),
      ),
      Positioned(
        top: diameter * .80,
        child: Container(
          // A long name ("Beauty & Skin Care") wraps to two even lines instead of running past the bubble or
          // covering a neighbour.
          constraints: BoxConstraints(maxWidth: textWidth + labelPadding),
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1DCD3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(label, maxLines: 2, textAlign: TextAlign.center, style: style),
        ),
      ),
    ]);
  }
}
