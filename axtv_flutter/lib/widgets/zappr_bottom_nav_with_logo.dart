import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';

/// Bottom navigation con 4 icone e logo centrale sferico al centro del footer
class ZapprBottomNavWithLogo extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? logoAssetPath;
  
  const ZapprBottomNavWithLogo({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.logoAssetPath,
  });
  
  @override
  State<ZapprBottomNavWithLogo> createState() => _ZapprBottomNavWithLogoState();
}

class _ZapprBottomNavWithLogoState extends State<ZapprBottomNavWithLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      bottom: safeAreaBottom,
      left: scaler.spacing(ZapprTokens.horizontalPadding),
      right: scaler.spacing(ZapprTokens.horizontalPadding),
      child: Container(
        height: scaler.s(ZapprTokens.bottomNavHeight),
        padding: EdgeInsets.symmetric(
          horizontal: scaler.spacing(18),
          vertical: scaler.spacing(10),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
          color: const Color(0xFF08213C).withOpacity(0.65),
          border: Border.all(
            width: 1.0,
            color: ZapprTokens.neonBlue.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: ZapprTokens.neonBlue.withOpacity(0.3),
              blurRadius: 15.0 * scaler.scale,
              spreadRadius: 1.0 * scaler.scale,
              offset: const Offset(0, 0),
            ),
            BoxShadow(
              color: ZapprTokens.neonCyan.withOpacity(0.2),
              blurRadius: 20.0 * scaler.scale,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Row con le 4 icone distribuite uniformemente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icona 1 (Live - posizione 0)
                _NavItem(
                  icon: Icons.live_tv,
                  label: 'Live',
                  isActive: widget.currentIndex == 0,
                  onTap: () => widget.onTap(0),
                  scaler: scaler,
                ),
                // Icona 2 (Radio - posizione 1)
                _NavItem(
                  icon: Icons.radio,
                  label: 'Radio',
                  isActive: widget.currentIndex == 1,
                  onTap: () => widget.onTap(1),
                  scaler: scaler,
                ),
                // Spazio invisibile per il logo centrale
                SizedBox(width: scaler.s(90)),
                // Icona 3 (Preferiti - posizione 2)
                _NavItem(
                  icon: Icons.favorite,
                  label: 'Preferiti',
                  isActive: widget.currentIndex == 2,
                  onTap: () => widget.onTap(2),
                  scaler: scaler,
                ),
                // Icona 4 (Profilo - posizione 3)
                _NavItem(
                  icon: Icons.account_circle,
                  label: 'Profilo',
                  isActive: widget.currentIndex == 3,
                  onTap: () => widget.onTap(3),
                  scaler: scaler,
                ),
              ],
            ),
            // Logo centrale con animazione futuristico
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: scaler.s(90),
                    height: scaler.s(90),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ZapprTokens.neonBlue.withOpacity(_glowAnimation.value * 0.8),
                          blurRadius: 25.0 * scaler.scale * _glowAnimation.value,
                          spreadRadius: 3.0 * scaler.scale * _glowAnimation.value,
                        ),
                        BoxShadow(
                          color: ZapprTokens.neonCyan.withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: 35.0 * scaler.scale * _glowAnimation.value,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: ZapprTokens.neonPurple.withOpacity(_glowAnimation.value * 0.4),
                          blurRadius: 45.0 * scaler.scale * _glowAnimation.value,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: widget.logoAssetPath != null
                        ? ClipOval(
                            child: Image.asset(
                              widget.logoAssetPath!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: ZapprTokens.electricBlueGradient,
                                  ),
                                  child: Icon(
                                    Icons.bolt,
                                    size: scaler.s(45),
                                    color: ZapprTokens.textPrimary,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: ZapprTokens.electricBlueGradient,
                            ),
                            child: Icon(
                              Icons.bolt,
                              size: scaler.s(45),
                              color: ZapprTokens.textPrimary,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final LayoutScaler scaler;
  
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.scaler,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: scaler.s(28), // Aumentata da 22 a 28
        color: isActive
            ? ZapprTokens.neonCyan.withOpacity(0.9) // Celeste quando attiva (come i pulsanti preferito)
            : Colors.white, // Bianco quando spenta
      ),
    );
  }
}
