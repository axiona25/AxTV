import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/zappr_app_header.dart';
import '../../../widgets/zappr_bottom_nav_with_logo.dart';
import '../../../theme/zappr_tokens.dart';
import '../../../theme/zappr_theme.dart';

/// Pagina Radio - mostra solo canali radio
/// TODO: I canali radio verranno caricati da un repository Git separato
class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  int _currentBottomNavIndex = 1; // Radio è l'index 1

  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;

    return Scaffold(
      backgroundColor: ZapprTokens.bg0,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/background_07.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: ZapprTokens.bg0);
              },
            ),
          ),
          // Main content
          SafeArea(
            child: _buildContent(scaler),
          ),
          // Bottom navigation with logo
          ZapprBottomNavWithLogo(
            currentIndex: _currentBottomNavIndex,
            onTap: (index) {
              setState(() {
                _currentBottomNavIndex = index;
              });
              
              // Navigazione tra pagine
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/radio');
                  break;
                case 2:
                  context.go('/favorites');
                  break;
                case 3:
                  context.go('/profile');
                  break;
              }
            },
            logoAssetPath: 'assets/icona.png',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LayoutScaler scaler) {
    // TODO: Qui verrà implementato il caricamento dei canali radio da un repository Git separato
    // Per ora mostra un messaggio che i canali radio verranno aggiunti presto
    
    return Column(
      children: [
        // Header
        ZapprAppHeader(
          onSettingsTap: () {
            context.push('/settings');
          },
          isSearchActive: false,
        ),
        SizedBox(height: scaler.spacing(20)),
        
        // "Radio" title
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: scaler.spacing(ZapprTokens.horizontalPadding),
            ),
            child: Text(
              'Radio',
              style: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizeSectionTitle),
                fontWeight: FontWeight.bold,
                color: ZapprTokens.textPrimary,
                fontFamily: ZapprTokens.fontFamily,
              ),
            ),
          ),
        ),
        SizedBox(height: scaler.spacing(20)),
        
        // Placeholder per canali radio (da implementare)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.radio,
                  size: scaler.s(64),
                  color: ZapprTokens.textSecondary.withOpacity(0.5),
                ),
                SizedBox(height: scaler.spacing(16)),
                Text(
                  'I canali radio saranno disponibili presto',
                  style: TextStyle(
                    fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
                    color: ZapprTokens.textSecondary,
                    fontFamily: ZapprTokens.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: scaler.spacing(8)),
                Text(
                  'I canali radio verranno caricati da un repository Git separato',
                  style: TextStyle(
                    fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                    color: ZapprTokens.textSecondary.withOpacity(0.7),
                    fontFamily: ZapprTokens.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
