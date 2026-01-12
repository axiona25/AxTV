import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/channels_controller.dart';
import '../data/channels_background_refresh.dart';
import '../model/channel.dart';
import '../../advert/services/ad_manager.dart';
import '../../advert/utils/device_locale_helper.dart';
import '../../../core/theme/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedFilter = 'Tutti';
  final List<String> _filters = ['Tutti', 'Intrattenimento', 'News', 'Sport'];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Avvia il refresh in background quando la pagina viene caricata
    // Il provider si inizializza automaticamente e avvia il refresh periodico
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsBackgroundRefreshProvider);
      _loadBannerAd();
    });
  }

  void _loadBannerAd() {
    // Ads non supportati su macOS/desktop - skip
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return;
    }
    
    // Solo su iOS/Android
    final adManager = ref.read(adManagerProvider);
    final country = DeviceLocaleHelper.getCountryCode(context);
    final language = DeviceLocaleHelper.getLanguageCode(context);
    
    // Usa un approccio che non richiede import diretto di AdSize
    // AdManager gestirà la creazione di AdSize internamente
    adManager.loadBannerAd(
      onAdLoaded: () {
        if (mounted) setState(() {});
      },
      onAdFailedToLoad: (error) {
        // Ignora errori (ads potrebbero essere disabilitati)
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usa StreamProvider per caricamento progressivo
    final channelsAsync = ref.watch(channelsStreamProvider);
    // Verifica se ci sono repository attivi
    final repositoriesAsync = ref.watch(liveRepositoriesStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: channelsAsync.when(
        data: (channels) {
          // Se la lista è vuota, verifica se ci sono repository attivi
          if (channels.isEmpty) {
            return repositoriesAsync.when(
              data: (repositories) {
                final activeRepos = repositories.where((r) => r.enabled).toList();
                // Se non ci sono repository attivi, mostra placeholder
                if (activeRepos.isEmpty) {
                  return _buildNoRepositoriesPlaceholder(context);
                }
                // Se ci sono repository attivi ma lista vuota, mostra loading
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Caricamento canali...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Caricamento...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              error: (_, __) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Caricamento canali...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildContent(channels);
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Caricamento canali...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => _ErrorView(error: e.toString()),
      ),
      // Bottom navigation rimosso per desktop (usa sidebar)
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.blueGlow,
          ),
          child: const Icon(
            Icons.bolt,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),
      ),
      title: const Text(
        'AxTV',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.clear, color: AppTheme.textPrimary),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        if (!_isSearching) ...[
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: () {
              // Forza refresh: cancella cache e ricarica
              ref.invalidate(channelsStreamProvider);
            },
            tooltip: 'Aggiorna canali',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ],
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.darkBackground,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cerca canali...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(List<Channel> channels) {
    // Filtra i canali in base alla query di ricerca
    final filteredChannels = _searchQuery.isEmpty
        ? channels
        : channels.where((channel) {
            return channel.name.toLowerCase().contains(_searchQuery) ||
                   channel.id.toLowerCase().contains(_searchQuery);
          }).toList();

    final adManager = ref.watch(adManagerProvider);
    final bannerWidget = adManager.getBannerAdWidget();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Ad (se disponibile e non in ricerca)
          if (!_isSearching && bannerWidget != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              child: bannerWidget,
            ),
            const SizedBox(height: 8),
          ],
          if (!_isSearching) _buildFilters(),
          if (!_isSearching) const SizedBox(height: 16),
          _buildSectionHeader(
            _searchQuery.isEmpty 
                ? 'Canali in diretta (${channels.length})' 
                : 'Risultati ricerca (${filteredChannels.length})',
          ),
          const SizedBox(height: 12),
          if (filteredChannels.isEmpty && _searchQuery.isNotEmpty)
            _buildEmptySearchResults()
          else if (filteredChannels.isEmpty && _searchQuery.isEmpty && channels.isEmpty)
            _buildEmptySearchResults()
          else
            _buildChannelsList(filteredChannels),
          if (!_isSearching) ...[
            const SizedBox(height: 24),
            _buildLivePreview(),
          ],
          const SizedBox(height: 80), // Spazio per bottom nav
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontFamily: 'Poppins',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
                width: 1,
              ),
              backgroundColor: AppTheme.cardBackground,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChannelsList(List<Channel> channels) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return _ChannelTile(
          channel: channel,
          onTap: () async {
            // Mostra interstitial ad prima di aprire il player (se disponibile)
            final adManager = ref.read(adManagerProvider);
            final country = DeviceLocaleHelper.getCountryCode(context);
            final language = DeviceLocaleHelper.getLanguageCode(context);
            
            // Carica l'interstitial ad
            await adManager.loadInterstitialAd(
              country: country,
              language: language,
              category: _selectedFilter != 'Tutti' ? _selectedFilter : null,
            );
            
            // Mostra l'interstitial ad (se caricato)
            await adManager.showInterstitialAd(
              country: country,
              language: language,
              category: _selectedFilter != 'Tutti' ? _selectedFilter : null,
              onAdDismissed: () {
                // Naviga al player dopo che l'ad è stata chiusa
                if (mounted) {
                  context.push('/player', extra: channel);
                }
              },
            );
            
            // Se l'ad non è disponibile, naviga direttamente dopo un breve delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.push('/player', extra: channel);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildLivePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('In Onda'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
              boxShadow: AppTheme.blueGlow,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.3),
                          AppTheme.darkBackground,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Talk Show in Diretta',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.liveRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptySearchResults() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun canale trovato',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova con un termine di ricerca diverso',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoRepositoriesPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.live_tv_outlined,
              size: 80,
              color: AppTheme.primaryBlue.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun repository attivo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Attiva almeno un repository dalle impostazioni per visualizzare i canali disponibili.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text(
                'Vai alle Impostazioni',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppTheme.blueGlow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: channel.logo == null
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tv,
                  color: AppTheme.primaryBlue,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  channel.logo!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    child: const Icon(Icons.tv, color: AppTheme.primaryBlue),
                  ),
                ),
              ),
        title: Text(
          channel.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.primaryBlue,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Errore:\n$error\n\nControlla Env.channelsJsonUrl e il formato JSON.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

