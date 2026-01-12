import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'zappr_tokens.dart';

/// LayoutScaler per adattare dimensioni
class LayoutScaler {
  final double scale;
  final double baseWidth;
  
  LayoutScaler(BuildContext context)
      : baseWidth = 390.0,
        scale = (MediaQuery.of(context).size.width / 390.0).clamp(0.92, 1.10);
  
  double s(double value) => value * scale;
  double r(double base) => s(base);
  double fontSize(double base) => s(base);
  double spacing(double base) => s(base);
}

extension LayoutScalerExtension on BuildContext {
  LayoutScaler get scaler => LayoutScaler(this);
}

/// Tema Zappr
class ZapprTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ZapprTokens.bg0,
      primaryColor: ZapprTokens.neonBlue,
      colorScheme: const ColorScheme.dark(
        primary: ZapprTokens.neonBlue,
        secondary: ZapprTokens.neonCyan,
        surface: ZapprTokens.bg1,
        background: ZapprTokens.bg0,
        error: ZapprTokens.danger,
        onPrimary: ZapprTokens.textPrimary,
        onSecondary: ZapprTokens.textPrimary,
        onSurface: ZapprTokens.textPrimary,
        onBackground: ZapprTokens.textPrimary,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: ZapprTokens.fontFamily,
          fontSize: ZapprTokens.fontSizeHeaderBrand,
          fontWeight: FontWeight.w700,
          color: ZapprTokens.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: ZapprTokens.fontFamily,
          fontSize: ZapprTokens.fontSizeSectionTitle,
          fontWeight: FontWeight.w700,
          color: ZapprTokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: ZapprTokens.fontFamily,
          fontSize: ZapprTokens.fontSizeBody,
          fontWeight: FontWeight.w600,
          color: ZapprTokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: ZapprTokens.fontFamily,
          fontSize: ZapprTokens.fontSizeSecondary,
          fontWeight: FontWeight.w500,
          color: ZapprTokens.textSecondary,
        ),
      ),
    );
  }
}
