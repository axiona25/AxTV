import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';

/// Widget neon glass con effetti esatti dal mockup
class NeonGlass extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final Color fill;
  final double borderWidth;
  final Gradient? borderGradient;
  final double blur;
  final double glowStrength;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showEdgeLight;
  final VoidCallback? onTap;
  
  const NeonGlass({
    super.key,
    required this.child,
    this.width,
    this.height,
    required this.radius,
    this.fill = ZapprTokens.bg1,
    this.borderWidth = 1.0,
    this.borderGradient,
    this.blur = 20.0,
    this.glowStrength = 1.0,
    this.padding,
    this.margin,
    this.showEdgeLight = true,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    final scaledRadius = scaler.r(radius);
    final scaledBlur = scaler.s(blur);
    final scaledBorderWidth = scaler.s(borderWidth);
    
    final effectiveBorderGradient = borderGradient ?? 
        ZapprTokens.electricBlueGradient;
    
    Widget container = Container(
      width: width != null ? scaler.s(width!) : null,
      height: height != null ? scaler.s(height!) : null,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaledRadius),
        color: fill,
        border: Border.all(
          width: scaledBorderWidth,
          color: Colors.transparent,
        ),
        boxShadow: ZapprTokens.electricBlueGlow(scaler.scale).map((s) => 
          BoxShadow(
            color: s.color.withOpacity(s.color.opacity * glowStrength),
            blurRadius: s.blurRadius,
            spreadRadius: s.spreadRadius,
            offset: s.offset,
          )
        ).toList(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(scaledRadius),
        child: Stack(
          children: [
            // Blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: scaledBlur * 0.3, sigmaY: scaledBlur * 0.3),
              child: Container(
                color: fill,
              ),
            ),
            // Border gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scaledRadius),
                  border: Border.all(
                    width: scaledBorderWidth,
                    color: Colors.transparent,
                  ),
                ),
                child: CustomPaint(
                  painter: _GradientBorderPainter(
                    gradient: effectiveBorderGradient,
                    borderWidth: scaledBorderWidth,
                    opacity: 0.65,
                    radius: scaledRadius,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    
    return container;
  }
}

class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double borderWidth;
  final double opacity;
  final double radius;
  
  _GradientBorderPainter({
    required this.gradient,
    required this.borderWidth,
    required this.opacity,
    required this.radius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    
    // Applica opacità ai colori del gradient
    Gradient gradientWithOpacity;
    if (gradient is LinearGradient) {
      final lg = gradient as LinearGradient;
      gradientWithOpacity = LinearGradient(
        colors: lg.colors.map((c) => c.withOpacity(c.opacity * opacity)).toList(),
        begin: lg.begin,
        end: lg.end,
      );
    } else {
      // Fallback per altri tipi di gradient
      gradientWithOpacity = gradient;
    }
    
    final paint = Paint()
      ..shader = gradientWithOpacity.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    
    canvas.drawRRect(rrect, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
