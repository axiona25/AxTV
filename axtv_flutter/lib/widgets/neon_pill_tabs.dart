import 'package:flutter/material.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import 'neon_glass.dart';

/// Tabs esatti dal mockup: Tutti selezionato con fill blu, altri con bordo glow
class NeonPillTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  
  const NeonPillTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
      ),
      child: Container(
        height: scaler.s(ZapprTokens.tabHeight) + 5, // Aumentato di 5px
        padding: EdgeInsets.all(scaler.spacing(4)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)),
          color: const Color(0xFF08213C).withOpacity(0.65), // Colore personalizzato #08213c con trasparenza 65%
          border: Border.all(
            width: 1.0,
            color: ZapprTokens.neonBlue.withOpacity(0.6), // Stesso bordo del footer
          ),
          // Ombra ridotta (stessa del footer e box canali)
          boxShadow: [
            BoxShadow(
              color: ZapprTokens.neonBlue.withOpacity(0.3), // Stessa opacità del footer
              blurRadius: 15.0 * scaler.scale, // Stesso blur del footer
              spreadRadius: 1.0 * scaler.scale, // Stesso spread del footer
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: ZapprTokens.neonCyan.withOpacity(0.2), // Stessa opacità del footer
              blurRadius: 20.0 * scaler.scale, // Stesso blur del footer
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(), // Sempre scrollabile anche senza overflow
          padding: EdgeInsets.symmetric(horizontal: scaler.spacing(2)),
          itemCount: tabs.length,
          separatorBuilder: (context, index) => SizedBox(width: scaler.spacing(8)),
          itemBuilder: (context, index) {
            final tab = tabs[index];
            final isSelected = index == selectedIndex;
            
              return _TabItem(
                label: tab,
                isSelected: isSelected,
                onTap: () => onTabChanged(index),
                scaler: scaler,
                showArrow: false, // Freccia rimossa - tutti i pulsanti sono uguali
              );
          },
        ),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final LayoutScaler scaler;
  final bool showArrow;
  
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scaler,
    this.showArrow = false,
  });
  
  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: widget.scaler.s(ZapprTokens.tabItemHeight) * 0.75, // Ridotta altezza badge al 75%
        padding: EdgeInsets.symmetric(
          horizontal: widget.scaler.spacing(16),
        ),
        constraints: BoxConstraints(
          minWidth: widget.scaler.s(60), // Larghezza minima per i badge
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.scaler.r(ZapprTokens.r16)), // Stesso radius del box
          // Selezionato: fill blu brillante, non selezionato: sfondo #08213c con bordo glow
          color: widget.isSelected
              ? ZapprTokens.neonBlue.withOpacity(0.8) // Fill blu brillante come nel mockup
              : const Color(0xFF08213C), // Colore personalizzato #08213c (stesso di footer e box canali)
          border: widget.isSelected
              ? null
              : Border.all(
                  width: 1.0,
                  color: ZapprTokens.neonBlue.withOpacity(0.6), // Stesso bordo del footer
                ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: ZapprTokens.neonBlue.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.scaler.fontSize(ZapprTokens.fontSizeSecondary),
                fontWeight: FontWeight.w600,
                color: widget.isSelected
                    ? ZapprTokens.textPrimary
                    : ZapprTokens.textSecondary,
                fontFamily: ZapprTokens.fontFamily,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (widget.showArrow) ...[
              SizedBox(width: widget.scaler.spacing(4)),
              Icon(
                Icons.arrow_forward_ios,
                size: widget.scaler.s(10),
                color: widget.isSelected
                    ? ZapprTokens.textPrimary
                    : ZapprTokens.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
