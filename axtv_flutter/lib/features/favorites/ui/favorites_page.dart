import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../channels/state/channels_controller.dart';
import '../../channels/model/channel.dart';
import '../../../widgets/zappr_app_header.dart';
import '../../../widgets/channels_scrollable_list.dart';
import '../../../widgets/zappr_bottom_nav_with_logo.dart';
import '../../../theme/zappr_tokens.dart';
import '../../../theme/zappr_theme.dart';

/// Pagina Preferiti - mostra solo canali preferiti salvati
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  int _currentBottomNavIndex = 2; // Preferiti è l'index 2
  List<String> _favoriteChannelIds = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Carica gli ID dei canali preferiti da SharedPreferences
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteChannelIds = prefs.getStringList('favorite_channels') ?? [];
    });
  }

  /// Filtra i canali per mostrare solo quelli preferiti
  List<Channel> _filterFavoriteChannels(List<Channel> channels) {
    return channels.where((channel) => _favoriteChannelIds.contains(channel.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    final channelsAsync = ref.watch(channelsStreamProvider);

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
            child: channelsAsync.when(
              data: (channels) {
                final favoriteChannels = _filterFavoriteChannels(channels);
                return _buildContent(favoriteChannels, scaler);
              },
              loading: () => _buildLoading(scaler),
              error: (e, _) => _buildError(e.toString(), scaler),
            ),
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

  Widget _buildContent(List<Channel> favoriteChannels, LayoutScaler scaler) {
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
        
        // "Preferiti" title
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: scaler.spacing(ZapprTokens.horizontalPadding),
            ),
            child: Text(
              'Preferiti',
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
        
        // Favorite channels list
        Expanded(
          child: favoriteChannels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: scaler.s(64),
                        color: ZapprTokens.textSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: scaler.spacing(16)),
                      Text(
                        'Nessun canale preferito',
                        style: TextStyle(
                          fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
                          color: ZapprTokens.textSecondary,
                          fontFamily: ZapprTokens.fontFamily,
                        ),
                      ),
                      SizedBox(height: scaler.spacing(8)),
                      Text(
                        'Tocca il cuore su un canale per aggiungerlo ai preferiti',
                        style: TextStyle(
                          fontSize: scaler.fontSize(ZapprTokens.fontSizeCaption),
                          color: ZapprTokens.textSecondary.withOpacity(0.7),
                          fontFamily: ZapprTokens.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ChannelsScrollableList(
                  channels: favoriteChannels,
                  onChannelTap: (channel) {
                    context.push('/player', extra: channel);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLoading(LayoutScaler scaler) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: scaler.spacing(16)),
          Text(
            'Caricamento preferiti...',
            style: TextStyle(
              fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
              color: ZapprTokens.textSecondary,
              fontFamily: ZapprTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, LayoutScaler scaler) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(scaler.spacing(16)),
        child: Text(
          'Errore: $error',
          style: TextStyle(
            fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
            color: ZapprTokens.danger,
            fontFamily: ZapprTokens.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
