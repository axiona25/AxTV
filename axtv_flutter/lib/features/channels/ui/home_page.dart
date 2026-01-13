import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/channels_controller.dart';
import '../data/channels_background_refresh.dart';
import '../model/channel.dart';
import '../../advert/services/ad_manager.dart';
import '../../../widgets/zappr_app_header.dart';
import '../../../widgets/neon_pill_tabs.dart';
import '../../../widgets/channels_scrollable_list.dart';
import '../../../widgets/zappr_bottom_nav_with_logo.dart';
import '../../../theme/zappr_tokens.dart';
import '../../../theme/zappr_theme.dart';

/// Home page esatta dal mockup con stile Zappr neon glass
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTabIndex = 0;
  List<String> _tabs = ['Tutti']; // Tabs dinamici basati sulle categorie reali
  bool _isSearchActive = false;
  int _currentBottomNavIndex = 0;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isRefreshing = false; // Flag per indicare se il refresh è in corso

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchController.addListener(() {
      setState(() {}); // Aggiorna la UI quando il testo cambia
    });
    // Avvia il refresh in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsBackgroundRefreshProvider);
      _loadBannerAd();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    // Ads non supportati su macOS/desktop
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return;
    }
    
    final adManager = ref.read(adManagerProvider);
    adManager.loadBannerAd(
      onAdLoaded: () {
        if (mounted) setState(() {});
      },
      onAdFailedToLoad: (error) {
        // Ignora errori
      },
    );
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
              data: (channels) => _buildContent(channels, scaler),
              loading: () => _buildLoading(scaler),
              error: (e, _) => _buildError(e.toString(), scaler),
            ),
          ),
          // Bottom navigation with logo
          ZapprBottomNavWithLogo(
            currentIndex: _currentBottomNavIndex,
            onTap: (index) {
              // ignore: avoid_print
              print('═══════════════════════════════════════════════════════════');
              // ignore: avoid_print
              print('HomePage: [FOOTER] Bottom nav tapped, index: $index');
              
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

  Widget _buildContent(List<Channel> channels, LayoutScaler scaler) {
    // Aggiorna i tabs dinamicamente basandosi sulle categorie reali dei canali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateTabsFromChannels(channels);
      }
    });
    
    // Filtra i canali in base al tab selezionato
    List<Channel> filteredChannels = _filterChannels(channels);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final safeAreaBottom = mediaQuery.padding.bottom;
        final screenHeight = constraints.maxHeight;
        
        // Calcola l'altezza totale degli elementi sopra la lista
        final headerHeight = scaler.s(44); // ZapprAppHeader
        final headerSpacing = scaler.spacing(8); // Ridotto da 16 a 8 per ridurre spazio
        final tabsHeight = scaler.s(ZapprTokens.tabHeight) + 5; // NeonPillTabs (altezza + padding)
        final tabsSpacing = scaler.spacing(20);
        final titleHeight = scaler.fontSize(ZapprTokens.fontSizeSectionTitle);
        final titleSpacing = scaler.spacing(12);
        final topElementsHeight = headerHeight + headerSpacing + tabsHeight + tabsSpacing + titleHeight + titleSpacing;
        
        // Calcola l'altezza del footer (footer base + safe area bottom)
        final footerHeight = scaler.s(ZapprTokens.bottomNavHeight) + safeAreaBottom;
        final paddingAboveFooter = 20.0; // Padding tra box e footer (valore fisso)
        final reduction = 100.0; // Riduzione dell'altezza del box (test: 100px)
        
        // Calcola l'altezza disponibile per il box dei canali
        // Sottraiamo: spazio sopra + footer + padding sopra footer + riduzione
        final availableHeight = screenHeight - topElementsHeight - footerHeight - paddingAboveFooter - reduction;
        
        // Assicuriamoci che l'altezza sia almeno un minimo
        final boxHeight = availableHeight > scaler.s(200) ? availableHeight : scaler.s(200);
        
        return Column(
          children: [
            // Header
            ZapprAppHeader(
              onSearchTap: () {
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    // Quando si disattiva la ricerca, pulisci il campo e rimuovi il focus
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  } else {
                    // Quando si attiva la ricerca, dai focus al campo dopo che è stato costruito
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocusNode.requestFocus();
                    });
                  }
                });
              },
              onSettingsTap: () {
                context.push('/settings');
              },
              isSearchActive: _isSearchActive,
            ),
            SizedBox(height: scaler.spacing(8)), // Ridotto da 16 a 8 per ridurre spazio
            
            // Campo ricerca o Category Tabs
            _isSearchActive
                ? _buildSearchField(scaler)
                : NeonPillTabs(
                    tabs: _tabs,
                    selectedIndex: _selectedTabIndex,
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
            SizedBox(height: scaler.spacing(20)),
            
            // "Canali in diretta" section con icona refresh
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Canali in diretta (${filteredChannels.length})',
                    style: TextStyle(
                      fontSize: scaler.fontSize(ZapprTokens.fontSizeSectionTitle),
                      fontWeight: FontWeight.w700,
                      color: ZapprTokens.textPrimary,
                      fontFamily: ZapprTokens.fontFamily,
                    ),
                  ),
                  // Icona refresh
                  _isRefreshing
                      ? SizedBox(
                          width: scaler.s(20),
                          height: scaler.s(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ZapprTokens.neonCyan,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: ZapprTokens.neonCyan,
                            size: scaler.s(24),
                          ),
                          onPressed: () => _handleManualRefresh(),
                          tooltip: 'Aggiorna canali',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: scaler.s(40),
                            minHeight: scaler.s(40),
                          ),
                        ),
                ],
              ),
            ),
            SizedBox(height: scaler.spacing(12)),
            
            // Box contenitore canali - ridotto di 30px per evitare overflow
            ChannelsScrollableList(
              channels: filteredChannels,
              onChannelTap: (channel) {
                context.push('/player', extra: channel);
              },
              height: boxHeight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading(LayoutScaler scaler) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ZapprTokens.neonBlue),
          ),
          SizedBox(height: scaler.spacing(16)),
          Text(
            'Caricamento canali...',
            style: TextStyle(
              fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
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
        padding: EdgeInsets.all(scaler.spacing(ZapprTokens.horizontalPadding)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: scaler.s(64),
              color: ZapprTokens.danger,
            ),
            SizedBox(height: scaler.spacing(16)),
            Text(
              'Errore',
              style: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizePageTitle),
                fontWeight: FontWeight.w700,
                color: ZapprTokens.textPrimary,
                fontFamily: ZapprTokens.fontFamily,
              ),
            ),
            SizedBox(height: scaler.spacing(8)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                color: ZapprTokens.textSecondary,
                fontFamily: ZapprTokens.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(LayoutScaler scaler) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
      ),
      child: Container(
        height: scaler.s(ZapprTokens.tabHeight) + 5, // Stessa altezza dei tabs
        padding: EdgeInsets.all(scaler.spacing(4)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(scaler.r(ZapprTokens.r16)), // Stesso radius dei tabs
          color: const Color(0xFF08213C).withOpacity(0.65), // Stesso colore dei tabs
          border: Border.all(
            width: 1.0,
            color: ZapprTokens.neonBlue.withOpacity(0.6), // Stesso bordo dei tabs
          ),
          // Stesse ombre dei tabs
          boxShadow: [
            BoxShadow(
              color: ZapprTokens.neonBlue.withOpacity(0.3),
              blurRadius: 15.0 * scaler.scale,
              spreadRadius: 1.0 * scaler.scale,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: ZapprTokens.neonCyan.withOpacity(0.2),
              blurRadius: 20.0 * scaler.scale,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Center(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
              color: ZapprTokens.textPrimary,
              fontFamily: ZapprTokens.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: 'Cerca canali...',
              hintStyle: TextStyle(
                fontSize: scaler.fontSize(ZapprTokens.fontSizeSecondary),
                color: ZapprTokens.textSecondary.withOpacity(0.6),
                fontFamily: ZapprTokens.fontFamily,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: ZapprTokens.neonCyan.withOpacity(0.9),
                size: scaler.s(18),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: scaler.spacing(12),
                vertical: scaler.spacing(8),
              ),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  /// Aggiorna i tabs dinamicamente basandosi sulle categorie reali dei canali
  void _updateTabsFromChannels(List<Channel> channels) {
    // Estrai tutte le categorie uniche dai canali
    final categories = <String>{};
    int canaliBambini = 0;
    for (final channel in channels) {
      if (channel.category != null && channel.category!.isNotEmpty) {
        // Escludi "Generale" perché è equivalente a "Tutti"
        if (channel.category!.toLowerCase() != 'generale') {
          categories.add(channel.category!);
          if (channel.category!.toLowerCase() == 'bambini') {
            canaliBambini++;
          }
        }
      }
    }
    
    // Log per debug canali per bambini
    if (canaliBambini > 0) {
      // ignore: avoid_print
      print('HomePage: 📊 Trovati $canaliBambini canali con categoria "Bambini"');
      // ignore: avoid_print
      print('HomePage: 📋 Categorie disponibili: ${categories.toList()..sort()}');
    }
    
    // Ordina le categorie per un ordine consistente
    final sortedCategories = categories.toList()..sort();
    
    // Crea lista tabs: "Tutti" + categorie ordinate
    final newTabs = ['Tutti', ...sortedCategories];
    
    // Log per debug tabs
    if (canaliBambini > 0) {
      // ignore: avoid_print
      print('HomePage: 📑 Tabs creati: $newTabs');
      // ignore: avoid_print
      print('HomePage: 🔍 Tab "Bambini" presente: ${newTabs.contains("Bambini")}');
    }
    
    // Aggiorna i tabs solo se sono cambiati (per evitare rebuild infiniti)
    if (!_areTabsEqual(_tabs, newTabs)) {
      // Mantieni l'indice selezionato se possibile (altrimenti resetta a 0)
      final oldSelectedCategory = _selectedTabIndex < _tabs.length ? _tabs[_selectedTabIndex] : null;
      
      setState(() {
        _tabs = newTabs;
        
        // Cerca il nuovo indice per la categoria precedentemente selezionata
        if (oldSelectedCategory != null && _tabs.contains(oldSelectedCategory)) {
          _selectedTabIndex = _tabs.indexOf(oldSelectedCategory);
        } else {
          _selectedTabIndex = 0; // Reset a "Tutti" se la categoria non esiste più
        }
      });
      
      if (canaliBambini > 0) {
        // ignore: avoid_print
        print('HomePage: ✅ Tabs aggiornati, tab selezionato: ${_tabs[_selectedTabIndex]} (indice: $_selectedTabIndex)');
      }
    }
  }
  
  /// Confronta due liste di tabs per vedere se sono uguali
  bool _areTabsEqual(List<String> tabs1, List<String> tabs2) {
    if (tabs1.length != tabs2.length) return false;
    for (int i = 0; i < tabs1.length; i++) {
      if (tabs1[i] != tabs2[i]) return false;
    }
    return true;
  }

  List<Channel> _filterChannels(List<Channel> channels) {
    // Se la ricerca è attiva, filtra per query di ricerca
    if (_isSearchActive && _searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase().trim();
      return channels.where((channel) {
        final name = channel.name.toLowerCase();
        final category = channel.category?.toLowerCase() ?? '';
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    // Altrimenti filtra per categoria/tab selezionato
    if (_selectedTabIndex == 0 || _selectedTabIndex >= _tabs.length) {
      return channels; // Tutti
    }

    final selectedCategory = _tabs[_selectedTabIndex];

    // Filtra i canali che appartengono alla categoria selezionata
    final filtered = channels.where((channel) {
      final category = channel.category ?? '';
      // Confronto esatto della categoria (case-insensitive)
      return category.toLowerCase() == selectedCategory.toLowerCase();
    }).toList();
    
    // Log per debug filtro categoria "Bambini"
    if (selectedCategory.toLowerCase() == 'bambini') {
      // ignore: avoid_print
      print('HomePage: 🔍 Filtro categoria "Bambini":');
      // ignore: avoid_print
      print('HomePage:    Canali totali: ${channels.length}');
      // ignore: avoid_print
      print('HomePage:    Canali filtrati: ${filtered.length}');
      if (filtered.length > 0) {
        // ignore: avoid_print
        print('HomePage:    Primi 5 canali filtrati:');
        for (final ch in filtered.take(5)) {
          // ignore: avoid_print
          print('HomePage:      - ${ch.name} (category: "${ch.category}")');
        }
      } else {
        // ignore: avoid_print
        print('HomePage:    ⚠️ NESSUN canale trovato per categoria "Bambini"!');
        // ignore: avoid_print
        print('HomePage:    Verifica canali con categoria simile:');
        final similar = channels.where((ch) => 
          ch.category?.toLowerCase().contains('bambini') == true ||
          ch.category?.toLowerCase().contains('kids') == true
        ).take(5).toList();
        for (final ch in similar) {
          // ignore: avoid_print
          print('HomePage:      - ${ch.name} (category: "${ch.category}")');
        }
      }
    }
    
    return filtered;
  }
  
  /// Gestisce il refresh manuale dei canali
  Future<void> _handleManualRefresh() async {
    if (_isRefreshing) {
      return; // Evita refresh multipli simultanei
    }
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // ignore: avoid_print
      print('HomePage: 🔄 Avvio refresh manuale canali...');
      
      // Ottieni il service di background refresh
      final refreshService = ref.read(channelsBackgroundRefreshProvider);
      
      // Esegui il refresh manuale (ref è WidgetRef che estende Ref)
      await refreshService.performManualRefresh(ref);
      
      // Mostra un messaggio di successo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: ZapprTokens.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Canali aggiornati con successo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: ZapprTokens.bg0.withOpacity(0.9),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // ignore: avoid_print
      print('HomePage: ✅ Refresh manuale completato');
    } catch (e) {
      // ignore: avoid_print
      print('HomePage: ❌ Errore nel refresh manuale: $e');
      
      // Mostra un messaggio di errore
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: ZapprTokens.danger,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Errore durante l\'aggiornamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: ZapprTokens.bg0.withOpacity(0.9),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}
