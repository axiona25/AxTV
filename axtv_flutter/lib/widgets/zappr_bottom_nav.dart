import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'neon_glass.dart';

/// Bottom navigation con: Live TV, Radio, Preferiti, Profilo (con avatar)
class ZapprBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? userAvatarUrl; // URL avatar da Google/Facebook/Apple
  
  const ZapprBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userAvatarUrl,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      bottom: safeAreaBottom + scaler.spacing(0), // Ridotto da 10 a 0 per abbassare il footer
      left: scaler.spacing(ZapprTokens.horizontalPadding),
      right: scaler.spacing(ZapprTokens.horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra principale con glow forte
          Container(
            height: scaler.s(ZapprTokens.bottomNavHeight),
            padding: EdgeInsets.symmetric(
              horizontal: scaler.spacing(18),
              vertical: scaler.spacing(10),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
              color: const Color(0xFF08213C).withOpacity(0.65), // Colore personalizzato #08213c con trasparenza 65%
              border: Border.all(
                width: 1.0,
                color: ZapprTokens.neonBlue.withOpacity(0.6),
              ),
              // Ombra ridotta (meno intensa)
              boxShadow: [
                BoxShadow(
                  color: ZapprTokens.neonBlue.withOpacity(0.3), // Ridotto da 0.8 a 0.3
                  blurRadius: 15.0 * scaler.scale, // Ridotto da 25 a 15
                  spreadRadius: 1.0 * scaler.scale, // Ridotto da 2 a 1
                  offset: Offset(0, 0),
                ),
                BoxShadow(
                  color: ZapprTokens.neonCyan.withOpacity(0.2), // Ridotto da 0.6 a 0.2
                  blurRadius: 20.0 * scaler.scale, // Ridotto da 35 a 20
                  spreadRadius: 0,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.live_tv,
                  label: 'Live TV',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                  scaler: scaler,
                ),
                _NavItem(
                  icon: Icons.radio,
                  label: 'Radio',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                  scaler: scaler,
                ),
                _NavItem(
                  icon: Icons.favorite,
                  label: 'Preferiti',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                  scaler: scaler,
                ),
                _NavItem(
                  icon: Icons.person,
                  label: 'Profilo',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                  scaler: scaler,
                  avatarUrl: userAvatarUrl,
                ),
              ],
            ),
          ),
          // Linea bianca sottile sotto (dal mockup)
          Padding(
            padding: EdgeInsets.only(top: scaler.spacing(8)),
            child: Container(
              width: double.infinity,
              height: 1.0,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
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
  final String? avatarUrl; // Solo per il pulsante Profilo
  
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.scaler,
    this.avatarUrl,
  });
  
  @override
  Widget build(BuildContext context) {
    // Se è il pulsante Profilo e c'è un avatar, mostra l'avatar
    final bool isProfile = label == 'Profilo';
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scaler.s(56),
        height: scaler.s(44),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Selezionato: fill blu brillante come nel mockup
          color: isActive
              ? ZapprTokens.neonBlue.withOpacity(0.8)
              : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ZapprTokens.neonBlue.withOpacity(0.6),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: isProfile && hasAvatar
            ? ClipOval(
                child: Image.network(
                  avatarUrl!,
                  width: scaler.s(32),
                  height: scaler.s(32),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback a icona se l'immagine non carica
                    return Icon(
                      icon,
                      size: scaler.s(22),
                      color: isActive
                          ? ZapprTokens.textPrimary
                          : ZapprTokens.textSecondary.withOpacity(0.9),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Icon(
                      icon,
                      size: scaler.s(22),
                      color: isActive
                          ? ZapprTokens.textPrimary
                          : ZapprTokens.textSecondary.withOpacity(0.9),
                    );
                  },
                ),
              )
            : Icon(
                icon,
                size: scaler.s(22),
                color: isActive
                    ? ZapprTokens.textPrimary
                    : ZapprTokens.textSecondary.withOpacity(0.9),
              ),
      ),
    );
  }
}
