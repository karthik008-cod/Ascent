import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class CharacterEmptyBox extends StatefulWidget {
  final String text;
  final double size;

  const CharacterEmptyBox({
    super.key,
    required this.text,
    this.size = 280.0, // Increased size
  });

  @override
  State<CharacterEmptyBox> createState() => _CharacterEmptyBoxState();
}

class _CharacterEmptyBoxState extends State<CharacterEmptyBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: DetailedCharacterPainter(
                  animationValue: _controller.value,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class DetailedCharacterPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  DetailedCharacterPainter({
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 300.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    // Color Palette
    final outlineColor = isDark ? const Color(0xFFF1F1F1) : const Color(0xFF1E1E1E);
    final shadowColor = isDark ? Colors.black45 : Colors.black12;
    final primaryOrange = const Color(0xFFFF7A22); // Vibrant main orange
    final skinColor = const Color(0xFFFFD1B3); // Warm skin tone
    final pantsColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final boxShadowColor = const Color(0xFFE65C00); // Deeper orange for shading

    final paintFill = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    final paintStroke = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // 1. Background Organic Shape
    paintFill.color = primaryOrange.withOpacity(isDark ? 0.08 : 0.05);
    final bgPath = Path()
      ..moveTo(-50, -110)
      ..cubicTo(80, -140, 110, -30, 80, 60)
      ..cubicTo(50, 150, -80, 140, -110, 80)
      ..cubicTo(-140, 20, -100, -80, -50, -110);
    canvas.drawPath(bgPath, paintFill);

    // Helper to draw filled with outline and optional shadow
    void drawShape(Path path, Paint fill, {bool hasShadow = false, double shadowOffset = 4.0}) {
      if (hasShadow) {
        canvas.drawShadow(path, shadowColor, shadowOffset, false);
      }
      canvas.drawPath(path, fill);
      canvas.drawPath(path, paintStroke);
    }

    // 2. Legs & Shoes
    paintFill.color = pantsColor;
    
    // Left Leg
    final leftLeg = Path()
      ..moveTo(-20, 25)
      ..quadraticBezierTo(-35, 80, -30, 130)
      ..lineTo(-5, 130)
      ..quadraticBezierTo(-5, 80, 0, 25)
      ..close();
    drawShape(leftLeg, paintFill);
    
    // Right Leg
    final rightLeg = Path()
      ..moveTo(5, 25)
      ..quadraticBezierTo(5, 80, 10, 130)
      ..lineTo(35, 130)
      ..quadraticBezierTo(35, 80, 25, 25)
      ..close();
    drawShape(rightLeg, paintFill);

    // Shoes
    paintFill.color = pantsColor;
    final lShoe = Path()
      ..moveTo(-35, 128)
      ..cubicTo(-50, 128, -55, 145, -45, 145)
      ..lineTo(-5, 145)
      ..cubicTo(-5, 135, -15, 128, -35, 128)
      ..close();
    drawShape(lShoe, paintFill, hasShadow: true, shadowOffset: 2.0);

    final rShoe = Path()
      ..moveTo(5, 128)
      ..cubicTo(15, 135, 25, 128, 45, 128)
      ..cubicTo(60, 128, 65, 145, 55, 145)
      ..lineTo(5, 145)
      ..close();
    drawShape(rShoe, paintFill, hasShadow: true, shadowOffset: 2.0);
    
    // Pant cuffs
    canvas.drawLine(const Offset(-32, 132), const Offset(-8, 132), paintStroke);
    canvas.drawLine(const Offset(8, 132), const Offset(32, 132), paintStroke);

    // 3. Torso
    paintFill.shader = ui.Gradient.linear(
      const Offset(0, -40),
      const Offset(0, 40),
      [primaryOrange, boxShadowColor],
    );
    final torso = Path()
      ..moveTo(-25, -45)
      ..lineTo(30, -40)
      ..quadraticBezierTo(45, 0, 35, 30)
      ..quadraticBezierTo(10, 40, -15, 30)
      ..quadraticBezierTo(-30, 0, -25, -45)
      ..close();
    drawShape(torso, paintFill, hasShadow: true);
    paintFill.shader = null; // reset

    // V-Neck collar line
    paintFill.color = skinColor;
    final neck = Path()
      ..moveTo(-10, -44)
      ..lineTo(5, -25)
      ..lineTo(20, -41)
      ..close();
    canvas.drawPath(neck, paintFill);
    canvas.drawPath(neck, paintStroke);

    // 4. Head & Hair
    // Hair back
    paintFill.color = pantsColor;
    final hairBack = Path()
      ..moveTo(10, -80)
      ..cubicTo(45, -80, 60, -40, 50, -10)
      ..cubicTo(35, 15, 20, 5, 15, -20)
      ..close();
    drawShape(hairBack, paintFill);

    // Face
    paintFill.color = skinColor;
    final face = Path()
      ..moveTo(-15, -85)
      ..cubicTo(15, -85, 25, -60, 20, -40)
      ..cubicTo(15, -20, -5, -25, -15, -40)
      ..cubicTo(-25, -55, -35, -85, -15, -85)
      ..close();
    drawShape(face, paintFill);

    // Facial features (Peaceful closed eyes)
    final eyePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
      
    // Left eye (curved down)
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-8, -60), radius: 4),
      math.pi / 8, math.pi * 0.75, false, eyePaint
    );
    // Right eye
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(7, -60), radius: 4),
      math.pi / 8, math.pi * 0.75, false, eyePaint
    );
    // Nose
    canvas.drawPath(
      Path()..moveTo(-2, -55)..lineTo(-4, -50)..lineTo(0, -50),
      eyePaint
    );

    // Cap
    paintFill.color = primaryOrange;
    final capBase = Path()
      ..moveTo(-30, -80)
      ..cubicTo(-10, -100, 25, -95, 30, -75)
      ..lineTo(-30, -80)
      ..close();
    drawShape(capBase, paintFill);
    
    // Cap Bill
    final capBill = Path()
      ..moveTo(-32, -78)
      ..cubicTo(-50, -75, -45, -65, -20, -68);
    canvas.drawPath(capBill, paintStroke);

    // Cap Logo
    final logoPaint = Paint()
      ..color = isDark ? Colors.white : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(-5, -85), const Offset(5, -85), logoPaint);
    canvas.drawLine(const Offset(0, -85), const Offset(0, -90), logoPaint);

    // 5. Box & Arms (Animated)
    // Smooth sinusoidal movement
    final smoothAnim = (math.sin(animationValue * math.pi) + 1) / 2; // 0.0 to 1.0
    final armSwing = -5.0 + (smoothAnim * 10.0); // moves between -5 and +5

    // Box Base
    paintFill.color = primaryOrange;
    final boxPath = Path()
      ..moveTo(-85, -10 + armSwing)
      ..lineTo(-35, -25 + armSwing)
      ..lineTo(25, -10 + armSwing)
      ..lineTo(10, 60 + armSwing)
      ..lineTo(-35, 75 + armSwing)
      ..lineTo(-90, 55 + armSwing)
      ..close();

    drawShape(boxPath, paintFill, hasShadow: true, shadowOffset: 6.0);
    
    // Box Inner Seams
    canvas.drawLine(Offset(-35, -25 + armSwing), Offset(-35, 75 + armSwing), paintStroke);
    
    // Tape detail
    canvas.drawLine(Offset(-70, 10 + armSwing), Offset(-68, 40 + armSwing), paintStroke);
    canvas.drawLine(Offset(-78, 10 + armSwing), Offset(-62, 10 + armSwing), paintStroke);
    canvas.drawLine(Offset(-75, 40 + armSwing), Offset(-60, 40 + armSwing), paintStroke);

    // Open Flaps
    final topFlap = Path()
      ..moveTo(-35, -25 + armSwing)
      ..lineTo(-60, -50 + armSwing)
      ..lineTo(-10, -45 + armSwing)
      ..lineTo(25, -10 + armSwing)
      ..close();
    paintFill.color = boxShadowColor.withOpacity(0.9);
    drawShape(topFlap, paintFill);
    
    final frontFlap = Path()
      ..moveTo(-85, -10 + armSwing)
      ..lineTo(-110, -5 + armSwing)
      ..lineTo(-65, 10 + armSwing)
      ..lineTo(-35, -25 + armSwing)
      ..close();
    drawShape(frontFlap, paintFill);

    // Empty Void (Inside the box)
    paintFill.color = isDark ? const Color(0xFF111111) : const Color(0xFF4A1C00);
    final voidPath = Path()
      ..moveTo(-80, -10 + armSwing)
      ..lineTo(-35, -20 + armSwing)
      ..lineTo(15, -10 + armSwing)
      ..lineTo(-35, 5 + armSwing)
      ..close();
    canvas.drawPath(voidPath, paintFill);

    // Right Arm (overlapping box)
    paintFill.color = primaryOrange;
    final rightArm = Path()
      ..moveTo(25, -40)
      ..quadraticBezierTo(55, -10, 40, 10)
      ..lineTo(10, 15 + armSwing)
      ..lineTo(5, 0 + armSwing)
      ..quadraticBezierTo(30, -10, 20, -40)
      ..close();
    drawShape(rightArm, paintFill);

    // Right Hand
    paintFill.color = skinColor;
    final hand = Path()
      ..moveTo(5, -2 + armSwing)
      ..cubicTo(-10, -5 + armSwing, -20, 5 + armSwing, -10, 15 + armSwing)
      ..cubicTo(0, 18 + armSwing, 15, 10 + armSwing, 10, -2 + armSwing)
      ..close();
    drawShape(hand, paintFill);
    
    // Fingers detail
    canvas.drawLine(Offset(-5, 5 + armSwing), Offset(5, 5 + armSwing), eyePaint);
    canvas.drawLine(Offset(-3, 10 + armSwing), Offset(7, 10 + armSwing), eyePaint);

    // Left Arm (behind box, partially visible)
    // We draw the left hand holding the back
    paintFill.color = skinColor;
    final leftHand = Path()
      ..moveTo(-85, -5 + armSwing)
      ..cubicTo(-100, -5 + armSwing, -100, 15 + armSwing, -85, 15 + armSwing)
      ..close();
    canvas.drawPath(leftHand, paintFill);
    canvas.drawPath(leftHand, paintStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DetailedCharacterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.isDark != isDark;
  }
}
