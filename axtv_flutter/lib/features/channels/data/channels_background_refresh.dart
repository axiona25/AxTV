import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'channels_repository.dart';
import 'channels_cache.dart';
import 'live_repositories_storage.dart';
import '../state/channels_controller.dart';

/// Service per refresh in background dei canali
/// Valida periodicamente URL non validi e cerca nuovi canali
class ChannelsBackgroundRefresh {
  Timer? _refreshTimer;
  final ChannelsRepository _repository;
  
  /// Intervallo di refresh (30 minuti)
  static const Duration _refreshInterval = Duration(minutes: 30);
  
  ChannelsBackgroundRefresh(this._repository);
  
  /// Avvia il refresh in background periodico
  void startPeriodicRefresh(Ref ref) {
    // Ferma eventuale timer esistente
    stopPeriodicRefresh();
    
    // ignore: avoid_print
    print('ChannelsBackgroundRefresh: 🚀 Avvio refresh periodico (ogni ${_refreshInterval.inMinutes} minuti)');
    
    // Esegui refresh immediato (dopo 1 minuto dall'avvio)
    Timer(const Duration(minutes: 1), () {
      _performBackgroundRefresh(ref);
    });
    
    // Poi esegui refresh periodico
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _performBackgroundRefresh(ref);
    });
  }
  
  /// Ferma il refresh periodico
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    // ignore: avoid_print
    print('ChannelsBackgroundRefresh: ⏹️ Refresh periodico fermato');
  }
  
  /// Esegue il refresh in background
  /// Valida URL non validi/nuovi canali e aggiorna la cache
  Future<void> _performBackgroundRefresh(Ref ref) async {
    try {
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 🔄 Inizio refresh in background...');
      
      // Carica i repository attivi
      final repositories = await LiveRepositoriesStorage.loadRepositoriesState();
      final activeRepositories = repositories.where((repo) => repo.enabled).toList();
      
      if (activeRepositories.isEmpty) {
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: ⚠️ Nessun repository attivo, skip refresh');
        return;
      }
      
      // Carica cache attuale
      final cachedChannels = await ChannelsCache.loadCachedChannels() ?? <dynamic>[];
      final cachedChannelsMap = <String, dynamic>{};
      for (final channel in cachedChannels) {
        // Usa ID come chiave
        if (channel is Map) {
          cachedChannelsMap[channel['id'] as String? ?? ''] = channel;
        }
      }
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 📦 Cache attuale: ${cachedChannels.length} canali');
      
      // Carica nuovi canali da repository usando lo stream
      // Controlla se ci sono nuovi canali rispetto alla cache
      var hasNewChannels = false;
      var totalChannels = 0;
      
      await for (final channels in _repository.fetchChannelsStream(forceRefresh: true)) {
        totalChannels = channels.length;
        
        // Controlla se ci sono nuovi canali rispetto alla cache
        for (final channel in channels) {
          if (!cachedChannelsMap.containsKey(channel.id)) {
            hasNewChannels = true;
            // ignore: avoid_print
            print('ChannelsBackgroundRefresh: ✨ Nuovo canale trovato: ${channel.name}');
          }
        }
        
        // Se abbiamo già trovato nuovi canali o la lista è completa, esci dal loop
        if (hasNewChannels && channels.length >= cachedChannels.length) {
          break;
        }
      }
      
      if (hasNewChannels || totalChannels > cachedChannels.length) {
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: ✅ Trovati nuovi canali (cache: ${cachedChannels.length}, attuali: $totalChannels), invalidando provider...');
        
        // Invalida il provider per forzare il reload con i nuovi canali
        ref.invalidate(channelsStreamProvider);
      } else {
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: ℹ️ Nessun nuovo canale trovato (cache: ${cachedChannels.length}, attuali: $totalChannels)');
      }
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: ✅ Refresh in background completato');
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: ❌ Errore nel refresh in background: $e');
    }
  }
}

/// Provider per il service di refresh in background
final channelsBackgroundRefreshProvider = Provider<ChannelsBackgroundRefresh>((ref) {
  final repository = ref.read(channelsRepositoryProvider);
  final service = ChannelsBackgroundRefresh(repository);
  
  // Avvia automaticamente il refresh periodico quando il provider è creato
  // Si ferma automaticamente quando il provider viene distrutto
  ref.onDispose(() {
    service.stopPeriodicRefresh();
  });
  
  // Avvia il refresh periodico
  // Usa un timer leggermente ritardato per non bloccare l'inizializzazione
  Future.microtask(() {
    service.startPeriodicRefresh(ref);
  });
  
  return service;
});
