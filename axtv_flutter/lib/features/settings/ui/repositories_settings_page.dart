import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../channels/model/repository_config.dart';
import '../../channels/state/channels_controller.dart';
import '../../channels/data/live_repositories_storage.dart';
import '../../channels/data/live_repositories_config.dart';
import '../../channels/data/channels_cache.dart'; // Per invalidare la cache

/// Classe helper per raggruppare i repository
class RepositoryGroup {
  final String key;
  final String name;
  final List<RepositoryConfig> repositories;
  
  RepositoryGroup({
    required this.key,
    required this.name,
    required this.repositories,
  });
}

class RepositoriesSettingsPage extends ConsumerStatefulWidget {
  const RepositoriesSettingsPage({super.key});

  @override
  ConsumerState<RepositoriesSettingsPage> createState() =>
      _RepositoriesSettingsPageState();
}

class _RepositoriesSettingsPageState
    extends ConsumerState<RepositoriesSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Repository',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(
              icon: Icon(Icons.live_tv),
              text: 'Live',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveTab(),
        ],
      ),
    );
  }


  Widget _buildLiveTab() {
    final repositoriesAsync = ref.watch(liveRepositoriesStateProvider);

    return repositoriesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlue,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Errore nel caricamento',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (repositories) => _buildRepositoriesList(repositories, isLive: true),
    );
  }

  Widget _buildRepositoriesList(List<RepositoryConfig> repositories, {required bool isLive}) {
    if (repositories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLive ? Icons.live_tv_outlined : Icons.movie_outlined,
              color: AppTheme.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun repository disponibile',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Raggruppa i repository per sorgente
    final groupedRepos = _groupRepositories(repositories);

    return Column(
      children: [
        // Header con informazioni
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:                   Text(
                  'Attiva o disattiva i repository live per mostrare i canali nell\'app. I repository disattivati non verranno caricati.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista repository raggruppati
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedRepos.length,
            itemBuilder: (context, index) {
              final group = groupedRepos[index];
              return _buildRepositoryGroup(group, isLive: isLive);
            },
          ),
        ),
        // Pulsante reset
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
            onPressed: () => _resetToDefaults(isLive: isLive),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Ripristina valori di default',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Raggruppa i repository per paese/lingua (per M3U8) o per sorgente (per altri)
  List<RepositoryGroup> _groupRepositories(List<RepositoryConfig> repositories) {
    final Map<String, List<RepositoryConfig>> groups = {};
    
    for (final repo in repositories) {
      String groupKey;
      
      // Repository IPTV-org: ogni repository diventa un gruppo separato (già per paese)
      if (repo.id.startsWith('iptv-org-')) {
        // Estrai il codice paese dall'ID (es: iptv-org-it -> it)
        final countryCode = repo.id.replaceAll('iptv-org-', '');
        groupKey = 'iptv-org-$countryCode';
      }
      // Repository M3U8-Xtream: raggruppa per categoria (tutti insieme)
      else if (repo.id.startsWith('m3u8-xtream-')) {
        groupKey = 'm3u8-xtream';
      }
      // Altri repository: raggruppa per sorgente
      else if (repo.id.startsWith('axtv-')) {
        groupKey = 'axtv';
      } else if (repo.id == 'cinedantan') {
        groupKey = 'cinedantan';
      } else {
        groupKey = 'other';
      }
      
      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(repo);
    }
    
    // Crea i gruppi finali: ogni repository IPTV-org diventa un gruppo separato (per paese)
    // I repository m3u8-xtream vengono raggruppati insieme in "Categorie M3U8"
    final List<RepositoryGroup> result = [];
    final List<RepositoryConfig> m3u8Repos = [];
    final List<RepositoryConfig> otherRepos = [];
    
    for (final entry in groups.entries) {
      if (entry.key.startsWith('iptv-org-')) {
        // Ogni repository IPTV-org diventa un gruppo separato (già per paese/lingua)
        result.add(RepositoryGroup(
          key: entry.key,
          name: entry.value.first.name, // Nome contiene già bandiera e paese
          repositories: entry.value,
        ));
      } else if (entry.key == 'm3u8-xtream') {
        // I repository m3u8-xtream vengono raggruppati insieme
        m3u8Repos.addAll(entry.value);
      } else {
        // Altri repository (axtv, cinedantan, etc.)
        otherRepos.addAll(entry.value);
      }
    }
    
    // Aggiungi il gruppo "Categorie M3U8" se ci sono repository m3u8-xtream
    if (m3u8Repos.isNotEmpty) {
      result.add(RepositoryGroup(
        key: 'm3u8-xtream',
        name: 'Categorie M3U8',
        repositories: m3u8Repos,
      ));
    }
    
    // Aggiungi gli altri repository (axtv, cinedantan, etc.)
    if (otherRepos.isNotEmpty) {
      for (final repo in otherRepos) {
        result.add(RepositoryGroup(
          key: repo.id,
          name: repo.name,
          repositories: [repo],
        ));
      }
    }
    
    // Ordina i repository: prima IPTV-org (per paese), poi M3U8, poi altri
    result.sort((a, b) {
      final aIsIptvOrg = a.key.startsWith('iptv-org-');
      final bIsIptvOrg = b.key.startsWith('iptv-org-');
      final aIsM3U8 = a.key == 'm3u8-xtream';
      final bIsM3U8 = b.key == 'm3u8-xtream';
      
      if (aIsIptvOrg && !bIsIptvOrg && !bIsM3U8) return -1;
      if (!aIsIptvOrg && !aIsM3U8 && bIsIptvOrg) return 1;
      if (aIsM3U8 && !bIsM3U8) return 1;
      if (!aIsM3U8 && bIsM3U8) return -1;
      
      return a.name.compareTo(b.name);
    });
    
    return result;
  }


  Widget _buildRepositoryGroup(RepositoryGroup group, {required bool isLive}) {
    return _RepositoryGroupWidget(
      key: ValueKey(group.key),
      group: group,
      isLive: isLive,
      parentState: this,
    );
  }
  
  // Metodo pubblico per permettere ai widget figli di costruire i tile
  Widget _buildRepositoryTile(RepositoryConfig repo, {required bool isLive, bool isSubItem = false}) {
    // Solo repository live supportati
    assert(isLive, 'Solo repository live sono supportati');
    return Container(
      margin: EdgeInsets.only(bottom: 12, left: isSubItem ? 16 : 0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: repo.enabled
              ? AppTheme.primaryBlue
              : AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: repo.enabled ? 2 : 1,
        ),
        boxShadow: repo.enabled ? AppTheme.blueGlow : null,
      ),
      child: Container(
        decoration: isSubItem
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              )
            : null,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSubItem ? 24 : 16,
            vertical: 12,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: repo.enabled
                  ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                  : AppTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.live_tv,
              color: repo.enabled
                  ? AppTheme.primaryBlue
                  : AppTheme.textSecondary,
              size: 24,
            ),
          ),
          title: Text(
            repo.name,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: repo.enabled
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                repo.description ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                repo.fullUrl,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Switch(
            value: repo.enabled,
            onChanged: (value) => _toggleRepository(repo.id, value, isLive: true, showSnackBar: true),
            activeColor: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRepository(String repositoryId, bool enabled, {required bool isLive, bool showSnackBar = true}) async {
    try {
      // Solo repository live
      final repo = LiveRepositoriesConfig.findById(repositoryId);
      if (repo == null) {
        throw Exception('Repository live non trovato: $repositoryId');
      }
      
      // Salva lo stato del repository live
      await LiveRepositoriesStorage.saveRepositoryState(repositoryId, enabled);
      
      // Ricarica lo stato dei repository live
      ref.invalidate(liveRepositoriesStateProvider);
      
      // Controlla se ci sono altri repository live attivi
      final allLiveRepos = await LiveRepositoriesStorage.loadRepositoriesState();
      final activeLiveRepos = allLiveRepos.where((r) => r.enabled).toList();
      
      // IMPORTANTE: Pulisci prima la cache per forzare il ricaricamento completo
      await ChannelsCache.clearCache();
      
      // Invalida i provider dei canali per ricaricare i contenuti.
      // Questo forzerà il ChannelsRepository a ricaricare dai repository attivi.
      ref.invalidate(channelsControllerProvider);
      ref.invalidate(channelsStreamProvider); // Invalida anche lo StreamProvider usato dalla home page
      
      if (mounted && showSnackBar) {
        if (!enabled) {
          // Repository live disabilitato: svuota i canali dalla pagina
          if (activeLiveRepos.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Repository live disabilitato. Nessun repository attivo - canali rimossi dalla pagina Live.'),
                backgroundColor: AppTheme.primaryBlue,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Repository "${repo.name}" disabilitato. Ricaricamento canali Live da ${activeLiveRepos.length} repository attivi...'),
                backgroundColor: AppTheme.primaryBlue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Repository live abilitato
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Repository "${repo.name}" abilitato. La pagina Live si sta popolando con i canali...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults({required bool isLive}) async {
    try {
      await LiveRepositoriesStorage.resetToDefaults();
      
      // Pulisci prima la cache per forzare il ricaricamento completo
      await ChannelsCache.clearCache();
      
      ref.invalidate(liveRepositoriesStateProvider);
      ref.invalidate(channelsControllerProvider);
      ref.invalidate(channelsStreamProvider); // Invalida anche lo StreamProvider usato dalla home page
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valori di default repository live ripristinati'),
            backgroundColor: AppTheme.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel ripristino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Widget separato per gestire lo stato di espansione del gruppo
class _RepositoryGroupWidget extends StatefulWidget {
  final RepositoryGroup group;
  final bool isLive;
  final _RepositoriesSettingsPageState parentState;

  const _RepositoryGroupWidget({
    super.key,
    required this.group,
    required this.isLive,
    required this.parentState,
  });

  @override
  State<_RepositoryGroupWidget> createState() => _RepositoryGroupWidgetState();
}

class _RepositoryGroupWidgetState extends State<_RepositoryGroupWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final enabledCount = widget.group.repositories.where((r) => r.enabled).length;
    final totalCount = widget.group.repositories.length;
    
    // Se il gruppo contiene solo un repository, mostra direttamente il tile del repository
    // (non serve un gruppo collapsible)
    if (totalCount == 1) {
      return widget.parentState._buildRepositoryTile(
        widget.group.repositories.first,
        isLive: widget.isLive,
        isSubItem: false,
      );
    }
    
    // Se il gruppo contiene più repository, mostra il gruppo collapsible
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabledCount > 0
              ? AppTheme.primaryBlue
              : AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: enabledCount > 0 ? 2 : 1,
        ),
        boxShadow: enabledCount > 0 ? AppTheme.blueGlow : null,
      ),
      child: Column(
        children: [
          // Header del gruppo
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$enabledCount / $totalCount attivi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Switch per attivare/disattivare tutto il gruppo
                  Switch(
                    value: enabledCount > 0,
                    onChanged: (value) {
                      _toggleGroup(value);
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
          // Sottorepository (visibili solo se espanso)
          if (_isExpanded)
            ...widget.group.repositories.map((repo) {
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: widget.parentState._buildRepositoryTile(repo, isLive: widget.isLive, isSubItem: true),
              );
            }).toList(),
        ],
      ),
    );
  }

  Future<void> _toggleGroup(bool enabled) async {
    for (final repo in widget.group.repositories) {
      await widget.parentState._toggleRepository(repo.id, enabled, isLive: widget.isLive, showSnackBar: false);
    }
    
    // Mostra un solo snackbar per tutto il gruppo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.group.name}: ${enabled ? "attivati" : "disattivati"} ${widget.group.repositories.length} repository',
          ),
          backgroundColor: enabled ? Colors.green : AppTheme.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
