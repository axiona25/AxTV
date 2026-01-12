import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';

/// Sfondo space esatto dal mockup
class StarfieldBackground extends CustomPainter {
  final List<Star> stars;
  
  StarfieldBackground() : stars = _generateStars();
  
  static List<Star> _generateStars() {
    final random = math.Random(42);
    final stars = <Star>[];
    
    for (int i = 0; i < 150; i++) {
      stars.add(Star(
        x: random.nextDouble() * 390,
        y: random.nextDouble() * 844,
        size: 1.0 + random.nextDouble() * 1.0,
        opacity: 0.06 + random.nextDouble() * 0.06,
      ));
    }
    
    return stars;
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    // Background nero puro
    final bgPaint = Paint()..color = ZapprTokens.bg0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Radial glow top-left (blu)
    final topLeftGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: size.width * 0.8,
      colors: [
        ZapprTokens.neonBlue.withOpacity(0.15),
        ZapprTokens.neonBlue.withOpacity(0.0),
      ],
    );
    final topLeftPaint = Paint()..shader = topLeftGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topLeftPaint);
    
    // Radial glow center (viola)
    final centerGradient = RadialGradient(
      center: Alignment.topCenter,
      radius: size.width * 1.2,
      colors: [
        ZapprTokens.neonPurple.withOpacity(0.10),
        ZapprTokens.neonPurple.withOpacity(0.0),
      ],
    );
    final centerPaint = Paint()..shader = centerGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), centerPaint);
    
    // Radial glow bottom-right (cyan)
    final bottomRightGradient = RadialGradient(
      center: Alignment.bottomRight,
      radius: size.width * 0.9,
      colors: [
        ZapprTokens.neonCyan.withOpacity(0.08),
        ZapprTokens.neonCyan.withOpacity(0.0),
      ],
    );
    final bottomRightPaint = Paint()..shader = bottomRightGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomRightPaint);
    
    // Stars
    final starPaint = Paint()..color = Colors.white;
    for (final star in stars) {
      final scaledX = star.x * (size.width / 390);
      final scaledY = star.y * (size.height / 844);
      starPaint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(
        Offset(scaledX, scaledY),
        star.size,
        starPaint,
      );
    }
    
    // Noise overlay
    final noisePaint = Paint()..color = Colors.white.withOpacity(0.03);
    final random = math.Random(123);
    for (int i = 0; i < 500; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, noisePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  
  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}
