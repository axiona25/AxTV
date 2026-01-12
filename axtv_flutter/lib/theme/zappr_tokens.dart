import 'package:flutter/material.dart';

/// Design tokens esatti dal mockup
class ZapprTokens {
  // ========== PALETTE ESATTA ==========
  static const Color bg0 = Color(0xFF000000); // Nero puro
  static const Color bg1 = Color.fromRGBO(12, 18, 40, 0.55); // Glass
  static const Color bg2 = Color.fromRGBO(10, 14, 30, 0.75); // Deep glass
  static const Color channelCardBg = Color(0xFF00234B); // Sfondo box contenitore canali
  static const Color channelBorderColor = Color(0xFF006B92); // Colore bordo card canali
  
  static const Color textPrimary = Color(0xFFFFFFFF); // Bianco puro
  static const Color textSecondary = Color.fromRGBO(255, 255, 255, 0.70);
  static const Color textMuted = Color.fromRGBO(255, 255, 255, 0.45);
  
  // Electric blue dal mockup
  static const Color neonBlue = Color(0xFF00A8FF); // Blu elettrico brillante
  static const Color neonCyan = Color(0xFF00D4FF); // Cyan brillante
  static const Color neonPurple = Color(0xFF8B5CF6); // Viola
  
  static const Color success = Color(0xFF49E2A8);
  static const Color danger = Color(0xFFFF3B30); // Rosso per LIVE badge
  
  // ========== RADIUS ==========
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r14 = 14.0;
  static const double r16 = 16.0;
  static const double r22 = 22.0;
  static const double r26 = 26.0;
  
  // ========== SHADOWS/GLOW ESATTI ==========
  static List<BoxShadow> electricBlueGlow(double scale) {
    return [
      BoxShadow(
        color: neonBlue.withOpacity(0.6),
        blurRadius: 20.0 * scale,
        spreadRadius: 0,
        offset: Offset(0, 0),
      ),
      BoxShadow(
        color: neonCyan.withOpacity(0.4),
        blurRadius: 30.0 * scale,
        spreadRadius: 0,
        offset: Offset(0, 0),
      ),
    ];
  }
  
  static List<BoxShadow> strongBlueGlow(double scale) {
    return [
      BoxShadow(
        color: neonBlue.withOpacity(0.8),
        blurRadius: 25.0 * scale,
        spreadRadius: 2.0 * scale,
        offset: Offset(0, 0),
      ),
      BoxShadow(
        color: neonCyan.withOpacity(0.6),
        blurRadius: 35.0 * scale,
        spreadRadius: 0,
        offset: Offset(0, 0),
      ),
    ];
  }
  
  // ========== SPACING ==========
  static const double horizontalPadding = 16.0;
  static const double verticalSpacing = 12.0;
  
  // ========== TYPOGRAPHY ==========
  static const String fontFamily = '.SF Pro Text';
  
  static const double fontSizeHeaderBrand = 24.5;
  static const double fontSizePageTitle = 20.0;
  static const double fontSizeSectionTitle = 18.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeSecondary = 14.0;
  static const double fontSizeCaption = 12.5;
  
  // ========== COMPONENT SIZES ==========
  static const double headerHeight = 44.0;
  static const double tabHeight = 40.0;
  static const double tabItemHeight = 32.0;
  static const double channelTileHeight = 62.0;
  static const double bannerHeight = 180.0; // Più alto per il mockup
  static const double bottomNavHeight = 64.0;
  
  // ========== GRADIENTS ==========
  static const LinearGradient electricBlueGradient = LinearGradient(
    colors: [
      Color(0xFF00A8FF), // neonBlue
      Color(0xFF00D4FF), // neonCyan
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
