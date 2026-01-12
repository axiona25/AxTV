import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'neon_glass.dart';

/// Banner "In Onda" esatto dal mockup: card grande con thumbnail, LIVE badge, dots
class LiveBannerCard extends StatelessWidget {
  final String channelName;
  final String? logoUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  
  const LiveBannerCard({
    super.key,
    required this.channelName,
    this.logoUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: scaler.s(ZapprTokens.bannerHeight),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
            boxShadow: ZapprTokens.strongBlueGlow(scaler.scale),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background con gradient e pattern city lights
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ZapprTokens.neonPurple.withOpacity(0.3),
                        ZapprTokens.neonBlue.withOpacity(0.2),
                        ZapprTokens.neonCyan.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _CityLightsPainter(),
                  ),
                ),
                // Overlay scuro
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),
                // Bordo glow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
                    border: Border.all(
                      width: 1.0,
                      color: ZapprTokens.neonBlue.withOpacity(0.6),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.only(
                    left: scaler.spacing(14),
                    bottom: scaler.spacing(12),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo canale (opzionale)
                        if (logoUrl != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: scaler.spacing(8)),
                            child: Image.network(
                              logoUrl!,
                              height: scaler.s(24),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: scaler.fontSize(17.5),
                            fontWeight: FontWeight.w700,
                            color: ZapprTokens.textPrimary,
                            fontFamily: ZapprTokens.fontFamily,
                          ),
                        ),
                        SizedBox(height: scaler.spacing(4)),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: scaler.fontSize(ZapprTokens.fontSizeCaption),
                            fontWeight: FontWeight.w500,
                            color: ZapprTokens.textSecondary,
                            fontFamily: ZapprTokens.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Badge LIVE rosso in basso a destra
                Positioned(
                  bottom: scaler.spacing(12),
                  right: scaler.spacing(12),
                  child: Container(
                    height: scaler.s(26),
                    padding: EdgeInsets.symmetric(
                      horizontal: scaler.spacing(10),
                    ),
                    decoration: BoxDecoration(
                      color: ZapprTokens.danger,
                      borderRadius: BorderRadius.circular(scaler.r(13)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: scaler.fontSize(ZapprTokens.fontSizeCaption),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: ZapprTokens.fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

/// Painter per pattern city lights
class _CityLightsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ZapprTokens.neonCyan.withOpacity(0.15);
    
    // Pattern luci città
    final points = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.6),
    ];
    
    for (final point in points) {
      canvas.drawCircle(point, 3, paint);
      canvas.drawCircle(point, 8, paint..color = paint.color.withOpacity(0.3));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dots di paginazione sotto il banner
class BannerPaginationDots extends StatelessWidget {
  final int currentIndex;
  final int totalDots;
  
  const BannerPaginationDots({
    super.key,
    required this.currentIndex,
    this.totalDots = 4,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    return Padding(
      padding: EdgeInsets.only(
        top: scaler.spacing(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalDots, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: scaler.spacing(3)),
            child: Container(
              width: scaler.s(6),
              height: scaler.s(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentIndex
                    ? ZapprTokens.neonBlue
                    : ZapprTokens.textSecondary.withOpacity(0.3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
