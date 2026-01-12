import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'neon_glass.dart';

/// Header esatto dal mockup: logo fulmine + Zappr con glow, icone circolari a destra
class ZapprAppHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;
  final bool isSearchActive; // Indica se la ricerca è attiva
  
  const ZapprAppHeader({
    super.key,
    this.onSearchTap,
    this.onSettingsTap,
    this.isSearchActive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    // Rimuoviamo SafeArea perché è già gestito nella home_page
    // Questo riduce lo spazio inutile sopra il logo
    return Padding(
      padding: EdgeInsets.only(
        top: scaler.spacing(4), // Padding minimo per separazione
        left: scaler.spacing(ZapprTokens.horizontalPadding),
        right: scaler.spacing(ZapprTokens.horizontalPadding),
        bottom: scaler.spacing(0),
      ),
        child: Row(
          children: [
            // Logo originale logo.png ingrandito - senza constraint di altezza
            Image.asset(
              'assets/logo.png',
              height: scaler.s(120), // Doppio della dimensione precedente
              fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback se il logo non viene trovato
                  return Row(
                    children: [
                      Container(
                        width: scaler.s(22),
                        height: scaler.s(22),
                        decoration: BoxDecoration(
                          gradient: ZapprTokens.electricBlueGradient,
                          borderRadius: BorderRadius.circular(scaler.r(4)),
                          boxShadow: [
                            BoxShadow(
                              color: ZapprTokens.neonBlue.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: scaler.spacing(8)),
                      Text(
                        'Zappr',
                        style: TextStyle(
                          fontSize: scaler.fontSize(ZapprTokens.fontSizeHeaderBrand),
                          fontWeight: FontWeight.w700,
                          color: ZapprTokens.textPrimary,
                          fontFamily: ZapprTokens.fontFamily,
                          shadows: [
                            Shadow(
                              color: ZapprTokens.neonBlue.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              // Action buttons circolari con glow blu
              Row(
                children: [
                  _ActionButton(
                    icon: isSearchActive ? Icons.search_off : Icons.search,
                    onTap: onSearchTap ?? () {},
                    scaler: scaler,
                    isActive: isSearchActive,
                  ),
                  SizedBox(width: scaler.spacing(10)),
                  _ActionButton(
                    icon: Icons.settings,
                    onTap: onSettingsTap ?? () {},
                    scaler: scaler,
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final LayoutScaler scaler;
  final bool isActive; // Indica se il pulsante è attivo
  
  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.scaler,
    this.isActive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: scaler.s(34),
        height: scaler.s(34),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ZapprTokens.bg2,
          border: Border.all(
            width: 1.0,
            color: ZapprTokens.neonBlue.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: ZapprTokens.neonBlue.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: scaler.s(18),
          color: isActive 
              ? ZapprTokens.neonBlue 
              : ZapprTokens.textPrimary,
        ),
      ),
    );
  }
}
