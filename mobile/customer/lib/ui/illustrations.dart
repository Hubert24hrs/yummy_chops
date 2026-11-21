import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original Yummy Chops illustrations drawn in code (no image assets, no third-party artwork).
/// Each painter draws in a 100×100 design space scaled to the widget size.
abstract class _Illustration extends CustomPainter {
  const _Illustration();

  void draw(Canvas c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

void _shadow(Canvas c, Offset center, double w, double h) =>
    c.drawOval(Rect.fromCenter(center: center, width: w, height: h), _fill(const Color(0x1F000000)));

/// A bowl of smoky jollof with a drumstick, dodo and a sprig of green.
class FoodIllustration extends _Illustration {
  const FoodIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(50, 86), 66, 8);
    // steam
    final steam = _stroke(const Color(0xFFD9CFC4), 3);
    for (final x in [40.0, 56.0]) {
      final p = Path()..moveTo(x, 24);
      p.cubicTo(x - 6, 18, x + 6, 13, x, 6);
      c.drawPath(p, steam);
    }
    // rice dome
    final rice = Path()
      ..moveTo(16, 56)
      ..cubicTo(18, 30, 82, 30, 84, 56)
      ..close();
    c.drawPath(rice, _fill(const Color(0xFFE2622C)));
    final grain = _fill(const Color(0xFFF08A4B));
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = 22 + rnd.nextDouble() * 56;
      final y = 40 + rnd.nextDouble() * 14;
      c.save();
      c.translate(x, y);
      c.rotate(rnd.nextDouble() * math.pi);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2.2, -0.9, 4.4, 1.8), const Radius.circular(1)), grain);
      c.restore();
    }
    // dodo (fried plantain) slices
    for (final (dx, dy, a) in [(28.0, 44.0, -0.4), (36.0, 40.0, 0.2), (24.0, 37.0, 0.6)]) {
      c.save();
      c.translate(dx, dy);
      c.rotate(a);
      final r = Rect.fromCenter(center: Offset.zero, width: 11, height: 7);
      c.drawOval(r, _fill(const Color(0xFFF5A21A)));
      c.drawOval(r, _stroke(const Color(0xFFB8741C), 1.4));
      c.restore();
    }
    // drumstick
    c.save();
    c.translate(63, 40);
    c.rotate(-0.55);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -7, 22, 14), const Radius.circular(7)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFB4561F), Color(0xFF7A3512)]).createShader(const Rect.fromLTWH(-12, -7, 22, 14)));
    c.drawRect(const Rect.fromLTWH(9, -2, 9, 4), _fill(const Color(0xFFF7EBDD)));
    c.drawCircle(const Offset(19, -2.5), 3, _fill(const Color(0xFFF7EBDD)));
    c.drawCircle(const Offset(19, 2.5), 3, _fill(const Color(0xFFF7EBDD)));
    c.restore();
    // green garnish
    for (final (dx, a) in [(46.0, -0.6), (51.0, 0.5)]) {
      c.save();
      c.translate(dx, 33);
      c.rotate(a);
      c.drawOval(const Rect.fromLTWH(-2.5, -6, 5, 12), _fill(const Color(0xFF2E8B57)));
      c.restore();
    }
    // bowl
    final bowl = Path()
      ..moveTo(12, 55)
      ..lineTo(88, 55)
      ..cubicTo(86, 74, 70, 86, 50, 86)
      ..cubicTo(30, 86, 14, 74, 12, 55)
      ..close();
    c.drawPath(bowl, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEF6E3E), Color(0xFFB3050B)]).createShader(const Rect.fromLTWH(12, 55, 76, 31)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 52, 80, 7), const Radius.circular(4)), _fill(const Color(0xFFF5A21A)));
    final pattern = _stroke(const Color(0x66FFFFFF), 2);
    for (final x in [30.0, 50.0, 70.0]) {
      c.drawCircle(Offset(x, 70), 3.2, pattern);
    }
  }
}

/// A cream jar, a serum dropper and a lipstick with sparkles.
class BeautyIllustration extends _Illustration {
  const BeautyIllustration();

  void _sparkle(Canvas c, Offset o, double r) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(p, _fill(const Color(0xFFF5A21A)));
  }

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(52, 88), 70, 8);
    _sparkle(c, const Offset(18, 22), 6);
    _sparkle(c, const Offset(86, 18), 4.5);
    _sparkle(c, const Offset(30, 10), 3);
    // serum dropper (back)
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 30, 18, 6), const Radius.circular(2)), _fill(const Color(0xFF2B2B2B)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47, 16, 12, 16), const Radius.circular(6)), _fill(const Color(0xFF3A3A3A)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(41, 36, 24, 46), const Radius.circular(7)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFD9893A), Color(0xFFA85A1A)]).createShader(const Rect.fromLTWH(41, 36, 24, 46)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(45, 52, 16, 14), const Radius.circular(3)), _fill(const Color(0xFFFDF1D6)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 40, 4, 34), const Radius.circular(2)), _fill(const Color(0x40FFFFFF)));
    // cream jar (front left)
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 56, 36, 30), const Radius.circular(8)), _fill(const Color(0xFFFFF7F0)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 56, 36, 30), const Radius.circular(8)), _stroke(const Color(0xFFEBD8C8), 1.6));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 47, 40, 12), const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF59AA8), Color(0xFFE06A7E)]).createShader(const Rect.fromLTWH(8, 47, 40, 12)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 66, 28, 10), const Radius.circular(3)), _fill(const Color(0xFFFDE7E6)));
    c.drawCircle(const Offset(28, 71), 3, _fill(const Color(0xFFE0040B)));
    // lipstick (front right)
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(68, 58, 18, 28), const Radius.circular(3)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFE9C25A), Color(0xFFB98A22)]).createShader(const Rect.fromLTWH(68, 58, 18, 28)));
    c.drawRect(const Rect.fromLTWH(70, 46, 14, 13), _fill(const Color(0xFFC9A03A)));
    final bullet = Path()
      ..moveTo(71, 46)
      ..lineTo(71, 34)
      ..quadraticBezierTo(76, 26, 83, 28)
      ..lineTo(83, 46)
      ..close();
    c.drawPath(bullet, _fill(const Color(0xFFD23B4E)));
    c.drawLine(const Offset(73, 44), const Offset(73, 34), _stroke(const Color(0x55FFFFFF), 2));
  }
}

/// A delivery scooter carrying a Yummy Chops parcel box.
class ParcelIllustration extends _Illustration {
  const ParcelIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(52, 88), 72, 7);
    final motion = _stroke(const Color(0xFFD9CFC4), 3);
    for (final (y, len) in [(58.0, 10.0), (66.0, 14.0), (74.0, 9.0)]) {
      c.drawLine(Offset(2, y), Offset(2 + len, y), motion);
    }
    // parcel box
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 24, 34, 32), const Radius.circular(4)), _fill(const Color(0xFFE4AB6E)));
    c.drawRect(const Rect.fromLTWH(30, 24, 6, 32), _fill(const Color(0xFFC98A4B)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 24, 34, 32), const Radius.circular(4)), _stroke(const Color(0xFFB4743A), 1.4));
    c.drawCircle(const Offset(23, 47), 3.4, _fill(const Color(0xFFE0040B)));
    // scooter body
    final body = Path()
      ..moveTo(14, 62)
      ..lineTo(60, 62)
      ..quadraticBezierTo(70, 62, 74, 70)
      ..lineTo(80, 72)
      ..lineTo(18, 72)
      ..quadraticBezierTo(12, 70, 14, 62)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFF0262B), Color(0xFF3A0D05)]).createShader(const Rect.fromLTWH(12, 60, 70, 14)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 54, 24, 7), const Radius.circular(3.5)), _fill(const Color(0xFF2B2B2B)));
    // steering column + handlebar
    c.drawLine(const Offset(70, 66), const Offset(80, 32), _stroke(const Color(0xFF3A0D05), 5));
    c.drawLine(const Offset(74, 31), const Offset(88, 31), _stroke(const Color(0xFF2B2B2B), 4));
    c.drawCircle(const Offset(84, 40), 3, _fill(const Color(0xFFF5A21A)));
    // wheels
    for (final x in [26.0, 76.0]) {
      c.drawCircle(Offset(x, 78), 10, _fill(const Color(0xFF2B2B2B)));
      c.drawCircle(Offset(x, 78), 4, _fill(const Color(0xFFC8C8C8)));
    }
  }
}

/// Yummy, the Yummy Chops AI assistant: a friendly robot face in a disc of the logo's chocolate brown (the cloche),
/// with a gold antenna and a chat-bubble tail.
class RobotPainter extends CustomPainter {
  const RobotPainter({this.eyeOpen = 1, this.ring = 0});

  /// 1 = eyes open, 0 = closed (blink).
  final double eyeOpen;

  /// 0..1 pulse ring around the disc.
  final double ring;

  static const body = Color(0xFF6B2410);
  static const bodyDark = Color(0xFF3A0D05);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.scale(s);
    if (ring > 0) {
      canvas.drawCircle(const Offset(50, 50), 50 + 8 * ring, _fill(body.withValues(alpha: .25 * (1 - ring))));
    }
    canvas.drawCircle(
      const Offset(50, 50),
      50,
      Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), radius: 1.1, colors: [Color(0xFFB4561F), body, bodyDark]).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    final white = _fill(Colors.white);
    // antenna
    canvas.drawLine(const Offset(50, 31), const Offset(50, 21), _stroke(Colors.white, 3.4));
    canvas.drawCircle(const Offset(50, 18.5), 4.6, _fill(const Color(0xFFF5A21A))); // gold, like the cloche's rim
    // ears
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, 44, 8, 15), const Radius.circular(4)), _fill(const Color(0xFFF6DCC6)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(73, 44, 8, 15), const Radius.circular(4)), _fill(const Color(0xFFF6DCC6)));
    // head with chat tail
    final head = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(25, 31, 50, 38), const Radius.circular(17)))
      ..moveTo(36, 64)
      ..lineTo(33, 78)
      ..lineTo(50, 67)
      ..close();
    canvas.drawPath(head, white);
    // visor
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 40, 36, 19), const Radius.circular(9.5)), _fill(body));
    // eyes (blink by squashing vertically)
    final eyeH = 8.4 * eyeOpen.clamp(0.08, 1);
    for (final x in [42.0, 58.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 49.5), width: 8.4, height: eyeH), white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RobotPainter oldDelegate) => oldDelegate.eyeOpen != eyeOpen || oldDelegate.ring != ring;
}

/// A shopping basket with bread, a milk carton, greens and an orange.
class GroceryIllustration extends _Illustration {
  const GroceryIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(50, 88), 70, 8);
    // bread, leaning out of the basket
    c.save();
    c.translate(30, 34);
    c.rotate(-0.35);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -22, 14, 46), const Radius.circular(7)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFE9B565), Color(0xFFC98632)]).createShader(const Rect.fromLTWH(-7, -22, 14, 46)));
    final score = _stroke(const Color(0xFFA9661F), 1.6);
    for (final y in [-12.0, -3.0, 6.0]) {
      c.drawLine(Offset(-4, y), Offset(4, y + 3), score);
    }
    c.restore();
    // milk carton
    c.drawPath(
      Path()
        ..moveTo(44, 26)
        ..lineTo(53, 16)
        ..lineTo(62, 26)
        ..close(),
      _fill(const Color(0xFFDCEBFA)),
    );
    c.drawRect(const Rect.fromLTWH(44, 26, 18, 34), _fill(const Color(0xFFF7FBFF)));
    c.drawRect(const Rect.fromLTWH(44, 36, 18, 10), _fill(const Color(0xFF4C8FDB)));
    // leafy greens
    for (final (dx, a) in [(70.0, -0.35), (76.0, 0.1), (82.0, 0.5)]) {
      c.save();
      c.translate(dx, 40);
      c.rotate(a);
      c.drawOval(const Rect.fromLTWH(-5, -18, 10, 30), _fill(const Color(0xFF2E8B57)));
      c.drawLine(const Offset(0, -12), const Offset(0, 10), _stroke(const Color(0xFF1F6B41), 1.2));
      c.restore();
    }
    // orange
    c.drawCircle(const Offset(63, 50), 8, _fill(const Color(0xFFF5A623)));
    c.drawCircle(const Offset(60.5, 47.5), 2.2, _fill(const Color(0x55FFFFFF)));
    // basket
    final body = Path()
      ..moveTo(14, 52)
      ..lineTo(86, 52)
      ..lineTo(78, 84)
      ..quadraticBezierTo(77, 88, 73, 88)
      ..lineTo(27, 88)
      ..quadraticBezierTo(23, 88, 22, 84)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3FA66B), Color(0xFF237247)]).createShader(const Rect.fromLTWH(14, 52, 72, 36)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 48, 80, 8), const Radius.circular(4)), _fill(const Color(0xFF2F8A57)));
    final slot = _stroke(const Color(0x55FFFFFF), 2.4);
    for (final x in [32.0, 44.0, 56.0, 68.0]) {
      c.drawLine(Offset(x, 62), Offset(x + (x - 50) * -.06, 80), slot);
    }
  }
}

/// A medicine bottle with a green cross, a capsule and a plaster.
class PharmacyIllustration extends _Illustration {
  const PharmacyIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(50, 88), 68, 8);
    // bottle
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 12, 28, 12), const Radius.circular(3)), _fill(const Color(0xFF1F9D63)));
    for (final x in [35.0, 41.0, 47.0, 53.0]) {
      c.drawLine(Offset(x, 14), Offset(x, 22), _stroke(const Color(0x55FFFFFF), 1.4));
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 24, 40, 62), const Radius.circular(9)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE6EEF2)]).createShader(const Rect.fromLTWH(24, 24, 40, 62)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 24, 40, 62), const Radius.circular(9)), _stroke(const Color(0xFFD3DEE4), 1.6));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(29, 40, 30, 30), const Radius.circular(5)), _fill(const Color(0xFFE6F6EE)));
    const green = Color(0xFF1F9D63);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40.5, 45, 7, 20), const Radius.circular(2)), _fill(green));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 51.5, 20, 7), const Radius.circular(2)), _fill(green));
    // capsule
    c.save();
    c.translate(77, 66);
    c.rotate(-0.6);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-15, -7, 30, 14), const Radius.circular(7)), _fill(const Color(0xFFFFF7F0)));
    c.save();
    c.clipRect(const Rect.fromLTWH(-15, -7, 15, 14));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-15, -7, 30, 14), const Radius.circular(7)), _fill(const Color(0xFFE85D32)));
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-15, -7, 30, 14), const Radius.circular(7)), _stroke(const Color(0x33000000), 1));
    c.restore();
    // plaster
    c.save();
    c.translate(76, 34);
    c.rotate(0.5);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -5, 28, 10), const Radius.circular(5)), _fill(const Color(0xFFF0C9A0)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -5, 10, 10), const Radius.circular(1.5)), _fill(const Color(0xFFFBE3C8)));
    for (final x in [-10.0, 10.0]) {
      c.drawCircle(Offset(x, -2), .9, _fill(const Color(0xFFC79B6B)));
      c.drawCircle(Offset(x, 2), .9, _fill(const Color(0xFFC79B6B)));
    }
    c.restore();
  }
}

/// A woven market basket of tomatoes, pepper, leaves and a tuber of yam.
class MarketIllustration extends _Illustration {
  const MarketIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(50, 88), 72, 8);
    // yam, at the back
    c.save();
    c.translate(70, 36);
    c.rotate(0.45);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -22, 16, 44), const Radius.circular(8)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF8A5A33), Color(0xFF5F3B1E)]).createShader(const Rect.fromLTWH(-8, -22, 16, 44)));
    c.drawOval(const Rect.fromLTWH(-6, -22, 12, 7), _fill(const Color(0xFFF3E3C4)));
    c.restore();
    // leaves
    for (final (dx, a) in [(22.0, -0.5), (29.0, -0.1), (36.0, 0.3)]) {
      c.save();
      c.translate(dx, 38);
      c.rotate(a);
      c.drawOval(const Rect.fromLTWH(-5.5, -20, 11, 32), _fill(const Color(0xFF2E8B57)));
      c.drawLine(const Offset(0, -14), const Offset(0, 10), _stroke(const Color(0xFF1F6B41), 1.2));
      c.restore();
    }
    // tomatoes
    for (final (x, y, r) in [(44.0, 44.0, 9.0), (58.0, 47.0, 8.0), (50.0, 36.0, 7.5)]) {
      c.drawCircle(Offset(x, y), r, _fill(const Color(0xFFE2412B)));
      c.drawCircle(Offset(x - r * .3, y - r * .35), r * .25, _fill(const Color(0x66FFFFFF)));
      c.drawCircle(Offset(x, y - r + 1), 1.8, _fill(const Color(0xFF2E8B57)));
    }
    // a pepper
    c.save();
    c.translate(33, 49);
    c.rotate(-0.9);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -9, 7, 18), const Radius.circular(3.5)), _fill(const Color(0xFFF5B942)));
    c.restore();
    // basket: a woven bowl
    final body = Path()
      ..moveTo(12, 54)
      ..lineTo(88, 54)
      ..cubicTo(86, 74, 72, 88, 50, 88)
      ..cubicTo(28, 88, 14, 74, 12, 54)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDDA85B), Color(0xFFB07A2E)]).createShader(const Rect.fromLTWH(12, 54, 76, 34)));
    c.save();
    c.clipPath(body);
    final weave = _stroke(const Color(0x66704514), 1.6);
    for (var y = 60.0; y < 88; y += 7) {
      c.drawLine(Offset(10, y), Offset(90, y), weave);
    }
    for (var x = 18.0; x < 88; x += 9) {
      c.drawLine(Offset(x, 54), Offset(x + (50 - x) * .18, 90), weave);
    }
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 50, 82, 8), const Radius.circular(4)), _fill(const Color(0xFFC98C3C)));
  }
}
