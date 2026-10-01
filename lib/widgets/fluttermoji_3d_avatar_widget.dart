import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Model representing the full state of a 3D Fluttermoji Avatar.
class Fluttermoji3DState {
  final Color skinColor;
  final int hairStyle; // 0: None, 1: Short, 2: Curly, 3: Long, 4: Afro, 5: Mohawk
  final Color hairColor;
  final int beardStyle; // 0: None, 1: Full Beard, 2: Stubble, 3: Goatee, 4: Mustache
  final Color beardColor;
  final int eyeStyle; // 0: Normal, 1: Sunglasses, 2: Specs, 3: VR
  final Color eyeColor;
  final int mouthStyle; // 0: Smile, 1: Neutral, 2: Laughing, 3: Smirk
  final int outfitStyle; // 0: Casual Tee, 1: Suit, 2: Hoodie, 3: Jacket
  final Color outfitColor;

  const Fluttermoji3DState({
    this.skinColor = const Color(0xFFF0D5BE),
    this.hairStyle = 1,
    this.hairColor = const Color(0xFF2C1B18),
    this.beardStyle = 0,
    this.beardColor = const Color(0xFF2C1B18),
    this.eyeStyle = 0,
    this.eyeColor = const Color(0xFF1A1A1A),
    this.mouthStyle = 0,
    this.outfitStyle = 0,
    this.outfitColor = const Color(0xFF6C5CE7),
  });

  Fluttermoji3DState copyWith({
    Color? skinColor,
    int? hairStyle,
    Color? hairColor,
    int? beardStyle,
    Color? beardColor,
    int? eyeStyle,
    Color? eyeColor,
    int? mouthStyle,
    int? outfitStyle,
    Color? outfitColor,
  }) {
    return Fluttermoji3DState(
      skinColor: skinColor ?? this.skinColor,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      beardStyle: beardStyle ?? this.beardStyle,
      beardColor: beardColor ?? this.beardColor,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      eyeColor: eyeColor ?? this.eyeColor,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      outfitStyle: outfitStyle ?? this.outfitStyle,
      outfitColor: outfitColor ?? this.outfitColor,
    );
  }
}

/// Interactive 3D Fluttermoji Avatar Widget with Touch Orbit & Volumetric 3D Rendering.
class Fluttermoji3DAvatarWidget extends StatefulWidget {
  final Fluttermoji3DState state;
  final double size;

  const Fluttermoji3DAvatarWidget({
    super.key,
    required this.state,
    this.size = 220,
  });

  @override
  State<Fluttermoji3DAvatarWidget> createState() => _Fluttermoji3DAvatarWidgetState();
}

class _Fluttermoji3DAvatarWidgetState extends State<Fluttermoji3DAvatarWidget> {
  double _rotX = 0.0;
  double _rotY = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotY += details.delta.dx * 0.01;
          _rotX -= details.delta.dy * 0.01;
          // Clamp rotation angles for smooth perspective
          _rotX = _rotX.clamp(-0.4, 0.4);
          _rotY = _rotY.clamp(-0.6, 0.6);
        });
      },
      onDoubleTap: () {
        setState(() {
          _rotX = 0.0;
          _rotY = 0.0;
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015) // Perspective 3D depth
          ..rotateX(_rotX)
          ..rotateY(_rotY),
        alignment: Alignment.center,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _Fluttermoji3DPainter(
            state: widget.state,
            rotX: _rotX,
            rotY: _rotY,
          ),
        ),
      ),
    );
  }
}

/// Custom 3D Volumetric Painter rendering 3D Head, Hair, Eyes, Beard, Outfit & Lighting.
class _Fluttermoji3DPainter extends CustomPainter {
  final Fluttermoji3DState state;
  final double rotX;
  final double rotY;

  _Fluttermoji3DPainter({
    required this.state,
    required this.rotX,
    required this.rotY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final headRadius = size.width * 0.35;

    // Shift offsets based on 3D Y/X rotation for parallax depth
    final shiftX = rotY * 30.0;
    final shiftY = -rotX * 30.0;

    // 1. Render 3D Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + shiftX * 0.5, center.dy + headRadius * 1.3 + shiftY * 0.5),
        width: headRadius * 1.8,
        height: headRadius * 0.5,
      ),
      shadowPaint,
    );

    // 2. Render 3D Torso & Outfit
    _paint3DTorso(canvas, center, headRadius, shiftX, shiftY);

    // 3. Render 3D Neck
    final neckRect = Rect.fromCenter(
      center: Offset(center.dx + shiftX * 0.3, center.dy + headRadius * 0.75 + shiftY * 0.3),
      width: headRadius * 0.6,
      height: headRadius * 0.5,
    );
    final neckPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          state.skinColor,
          Color.lerp(state.skinColor, Colors.black, 0.3)!,
        ],
        center: Alignment.topCenter,
        radius: 1.0,
      ).createShader(neckRect);
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, const Radius.circular(12)), neckPaint);

    // 4. Render 3D Head Sphere (With Specular Lighting)
    final headRect = Rect.fromCircle(center: center, radius: headRadius);
    final headLightOffset = Offset(
      center.dx - headRadius * 0.35 + shiftX,
      center.dy - headRadius * 0.35 + shiftY,
    );

    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(state.skinColor, Colors.white, 0.45)!, // Specular Highlight
          state.skinColor,
          Color.lerp(state.skinColor, Colors.black, 0.35)!, // Ambient Occlusion Shadow
        ],
        stops: const [0.0, 0.55, 1.0],
        center: Alignment(
          ((headLightOffset.dx - center.dx) / headRadius).clamp(-1.0, 1.0),
          ((headLightOffset.dy - center.dy) / headRadius).clamp(-1.0, 1.0),
        ),
        radius: 0.95,
      ).createShader(headRect);
    canvas.drawCircle(center, headRadius, headPaint);

    // 5. Render 3D Ears
    final earPaint = Paint()..color = Color.lerp(state.skinColor, Colors.black, 0.15)!;
    canvas.drawCircle(Offset(center.dx - headRadius * 0.98 + shiftX * 0.2, center.dy), headRadius * 0.18, earPaint);
    canvas.drawCircle(Offset(center.dx + headRadius * 0.98 + shiftX * 0.2, center.dy), headRadius * 0.18, earPaint);

    // 6. Render 3D Eyes & Eyewear
    _paint3DEyes(canvas, center, headRadius, shiftX, shiftY);

    // 7. Render 3D Facial Hair (Beard)
    _paint3DBeard(canvas, center, headRadius, shiftX, shiftY);

    // 8. Render 3D Mouth
    _paint3DMouth(canvas, center, headRadius, shiftX, shiftY);

    // 9. Render 3D Hairstyle (Top Layer)
    _paint3DHair(canvas, center, headRadius, shiftX, shiftY);
  }

  void _paint3DTorso(Canvas canvas, Offset center, double headRadius, double shiftX, double shiftY) {
    final torsoPath = Path();
    final torsoCenter = Offset(center.dx + shiftX * 0.4, center.dy + headRadius * 1.45 + shiftY * 0.4);

    torsoPath.moveTo(torsoCenter.dx - headRadius * 1.4, torsoCenter.dy + headRadius);
    torsoPath.quadraticBezierTo(
      torsoCenter.dx - headRadius * 1.2, torsoCenter.dy - headRadius * 0.4,
      torsoCenter.dx - headRadius * 0.4, torsoCenter.dy - headRadius * 0.5,
    );
    torsoPath.quadraticBezierTo(
      torsoCenter.dx, torsoCenter.dy - headRadius * 0.2,
      torsoCenter.dx + headRadius * 0.4, torsoCenter.dy - headRadius * 0.5,
    );
    torsoPath.quadraticBezierTo(
      torsoCenter.dx + headRadius * 1.2, torsoCenter.dy - headRadius * 0.4,
      torsoCenter.dx + headRadius * 1.4, torsoCenter.dy + headRadius,
    );
    torsoPath.close();

    final torsoRect = torsoPath.getBounds();
    final torsoPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(state.outfitColor, Colors.white, 0.25)!,
          state.outfitColor,
          Color.lerp(state.outfitColor, Colors.black, 0.4)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(torsoRect);

    canvas.drawPath(torsoPath, torsoPaint);

    // Collar / Hoodie Detail
    if (state.outfitStyle == 2) {
      final hoodiePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(torsoCenter.dx - 12, torsoCenter.dy - headRadius * 0.2),
        Offset(torsoCenter.dx - 12, torsoCenter.dy + headRadius * 0.3),
        hoodiePaint,
      );
      canvas.drawLine(
        Offset(torsoCenter.dx + 12, torsoCenter.dy - headRadius * 0.2),
        Offset(torsoCenter.dx + 12, torsoCenter.dy + headRadius * 0.3),
        hoodiePaint,
      );
    }
  }

  void _paint3DEyes(Canvas canvas, Offset center, double headRadius, double shiftX, double shiftY) {
    final eyeLevelY = center.dy - headRadius * 0.1 + shiftY * 0.8;
    final leftEyeX = center.dx - headRadius * 0.35 + shiftX * 0.8;
    final rightEyeX = center.dx + headRadius * 0.35 + shiftX * 0.8;

    if (state.eyeStyle == 1) {
      // 3D Sunglasses
      final glassesPath = Path();
      glassesPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(leftEyeX, eyeLevelY), width: headRadius * 0.65, height: headRadius * 0.45),
        const Radius.circular(10),
      ));
      glassesPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(rightEyeX, eyeLevelY), width: headRadius * 0.65, height: headRadius * 0.45),
        const Radius.circular(10),
      ));

      final glassesPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.black, Colors.grey.shade900, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: headRadius));

      canvas.drawPath(glassesPath, glassesPaint);

      // Glasses Frame Bridge
      final bridgePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(leftEyeX + headRadius * 0.2, eyeLevelY - 6), Offset(rightEyeX - headRadius * 0.2, eyeLevelY - 6), bridgePaint);
    } else {
      // 3D Natural Spherical Eyes
      final eyeWhitePaint = Paint()..color = Colors.white;
      final eyePupilPaint = Paint()..color = state.eyeColor;
      final eyeHighlightPaint = Paint()..color = Colors.white;

      for (final eyeX in [leftEyeX, rightEyeX]) {
        // Eye White
        canvas.drawCircle(Offset(eyeX, eyeLevelY), headRadius * 0.16, eyeWhitePaint);
        // Pupil
        canvas.drawCircle(Offset(eyeX + shiftX * 0.05, eyeLevelY + shiftY * 0.05), headRadius * 0.09, eyePupilPaint);
        // Specular Highlight
        canvas.drawCircle(Offset(eyeX - headRadius * 0.04 + shiftX * 0.05, eyeLevelY - headRadius * 0.04 + shiftY * 0.05), headRadius * 0.03, eyeHighlightPaint);
      }

      // 3D Eyebrows
      final eyebrowPaint = Paint()
        ..color = state.hairColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(leftEyeX - 16, eyeLevelY - 22), Offset(leftEyeX + 16, eyeLevelY - 20), eyebrowPaint);
      canvas.drawLine(Offset(rightEyeX - 16, eyeLevelY - 20), Offset(rightEyeX + 16, eyeLevelY - 22), eyebrowPaint);
    }
  }

  void _paint3DBeard(Canvas canvas, Offset center, double headRadius, double shiftX, double shiftY) {
    if (state.beardStyle == 0) return;

    final beardPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          state.beardColor,
          Color.lerp(state.beardColor, Colors.black, 0.4)!,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: headRadius));

    final beardY = center.dy + headRadius * 0.35 + shiftY * 0.9;
    final beardX = center.dx + shiftX * 0.9;

    if (state.beardStyle == 1 || state.beardStyle == 2) {
      // Full Beard / Stubble
      final beardPath = Path();
      beardPath.moveTo(beardX - headRadius * 0.7, center.dy + shiftY * 0.8);
      beardPath.quadraticBezierTo(beardX - headRadius * 0.8, beardY + headRadius * 0.5, beardX, beardY + headRadius * 0.65);
      beardPath.quadraticBezierTo(beardX + headRadius * 0.8, beardY + headRadius * 0.5, beardX + headRadius * 0.7, center.dy + shiftY * 0.8);
      beardPath.quadraticBezierTo(beardX, beardY - headRadius * 0.1, beardX - headRadius * 0.7, center.dy + shiftY * 0.8);
      canvas.drawPath(beardPath, beardPaint);
    } else if (state.beardStyle == 4) {
      // Mustache
      final mustachePath = Path();
      mustachePath.moveTo(beardX - 28, beardY);
      mustachePath.quadraticBezierTo(beardX, beardY - 10, beardX + 28, beardY);
      mustachePath.quadraticBezierTo(beardX, beardY + 12, beardX - 28, beardY);
      canvas.drawPath(mustachePath, beardPaint);
    }
  }

  void _paint3DMouth(Canvas canvas, Offset center, double headRadius, double shiftX, double shiftY) {
    final mouthY = center.dy + headRadius * 0.38 + shiftY * 0.9;
    final mouthX = center.dx + shiftX * 0.9;

    final mouthPaint = Paint()
      ..color = const Color(0xFF8D4B4E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    if (state.mouthStyle == 0) {
      // Smile
      final path = Path();
      path.moveTo(mouthX - 22, mouthY);
      path.quadraticBezierTo(mouthX, mouthY + 18, mouthX + 22, mouthY);
      canvas.drawPath(path, mouthPaint);
    } else if (state.mouthStyle == 1) {
      // Neutral
      canvas.drawLine(Offset(mouthX - 18, mouthY), Offset(mouthX + 18, mouthY), mouthPaint);
    } else if (state.mouthStyle == 2) {
      // Laughing Open Mouth
      final path = Path();
      path.moveTo(mouthX - 22, mouthY);
      path.quadraticBezierTo(mouthX, mouthY + 24, mouthX + 22, mouthY);
      path.close();
      final fillPaint = Paint()..color = const Color(0xFF6B2D30);
      canvas.drawPath(path, fillPaint);
    } else {
      // Cool Smirk
      final path = Path();
      path.moveTo(mouthX - 18, mouthY + 4);
      path.quadraticBezierTo(mouthX + 5, mouthY, mouthX + 20, mouthY - 8);
      canvas.drawPath(path, mouthPaint);
    }
  }

  void _paint3DHair(Canvas canvas, Offset center, double headRadius, double shiftX, double shiftY) {
    if (state.hairStyle == 0) return; // Bald

    final hairPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(state.hairColor, Colors.white, 0.3)!,
          state.hairColor,
          Color.lerp(state.hairColor, Colors.black, 0.4)!,
        ],
        center: Alignment(-0.3 + rotY, -0.4 - rotX),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center, radius: headRadius * 1.2));

    final hairX = center.dx + shiftX * 0.9;
    final hairY = center.dy + shiftY * 0.9;

    final hairPath = Path();

    if (state.hairStyle == 1) {
      // Short Cut
      hairPath.addOval(Rect.fromCenter(
        center: Offset(hairX, hairY - headRadius * 0.4),
        width: headRadius * 2.1,
        height: headRadius * 1.4,
      ));
    } else if (state.hairStyle == 2) {
      // Curly Top
      for (int i = 0; i < 7; i++) {
        final angle = -math.pi + (i * math.pi / 6);
        final cx = hairX + (headRadius * 0.75) * math.cos(angle);
        final cy = hairY - headRadius * 0.35 + (headRadius * 0.5) * math.sin(angle);
        canvas.drawCircle(Offset(cx, cy), headRadius * 0.32, hairPaint);
      }
      return;
    } else if (state.hairStyle == 4) {
      // Afro Volume
      canvas.drawCircle(Offset(hairX, hairY - headRadius * 0.3), headRadius * 1.15, hairPaint);
      return;
    } else if (state.hairStyle == 5) {
      // Mohawk
      hairPath.moveTo(hairX - 16, hairY - headRadius * 1.2);
      hairPath.lineTo(hairX + 16, hairY - headRadius * 1.2);
      hairPath.lineTo(hairX + 30, hairY - headRadius * 0.2);
      hairPath.lineTo(hairX - 30, hairY - headRadius * 0.2);
      hairPath.close();
    } else {
      // Long Locks
      hairPath.addOval(Rect.fromCenter(
        center: Offset(hairX, hairY - headRadius * 0.2),
        width: headRadius * 2.25,
        height: headRadius * 1.8,
      ));
    }

    canvas.drawPath(hairPath, hairPaint);
  }

  @override
  bool shouldRepaint(covariant _Fluttermoji3DPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.rotX != rotX || oldDelegate.rotY != rotY;
  }
}
