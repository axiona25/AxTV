import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'channels_repository.dart';
import 'channels_cache.dart';
import 'live_repositories_storage.dart';
import '../state/channels_controller.dart';
import '../model/channel.dart';

/// Service per refresh in background dei canali
/// Scannerizza i repository, confronta con la cache e aggiunge automaticamente i canali mancanti
/// Aggiorna 2 volte al giorno (mattina e sera)
class ChannelsBackgroundRefresh {
  Timer? _morningTimer;
  Timer? _eveningTimer;
  Timer? _nextRefreshTimer;
  final ChannelsRepository _repository;
  
  /// Orari di refresh (2 volte al giorno)
  static const int _morningHour = 8; // 8:00
  static const int _eveningHour = 20; // 20:00
  
  ChannelsBackgroundRefresh(this._repository);
  
  /// Avvia il refresh in background con aggiornamenti 2 volte al giorno
  void startPeriodicRefresh(Ref ref) {
    // Ferma eventuali timer esistenti
    stopPeriodicRefresh();
    
    // ignore: avoid_print
    print('ChannelsBackgroundRefresh: 🚀 Avvio refresh automatico (2 volte al giorno: $_morningHour:00 e $_eveningHour:00)');
    
    // Calcola il prossimo refresh
    _scheduleNextRefresh(ref);
    
    // Esegui anche un refresh immediato al primo avvio (dopo 30 secondi)
    Timer(const Duration(seconds: 30), () {
      _performBackgroundRefresh(ref, isScheduled: false);
    });
  }
  
  /// Ferma il refresh periodico
  void stopPeriodicRefresh() {
    _morningTimer?.cancel();
    _eveningTimer?.cancel();
    _nextRefreshTimer?.cancel();
    _morningTimer = null;
    _eveningTimer = null;
    _nextRefreshTimer = null;
    // ignore: avoid_print
    print('ChannelsBackgroundRefresh: ⏹️ Refresh periodico fermato');
  }
  
  /// Programma il prossimo refresh
  void _scheduleNextRefresh(Ref ref) {
    final now = DateTime.now();
    final todayMorning = DateTime(now.year, now.month, now.day, _morningHour, 0);
    final todayEvening = DateTime(now.year, now.month, now.day, _eveningHour, 0);
    
    DateTime? nextRefresh;
    
    if (now.hour < _morningHour) {
      // Prima delle 8:00 -> prossimo refresh alle 8:00 di oggi
      nextRefresh = todayMorning;
    } else if (now.hour < _eveningHour) {
      // Tra le 8:00 e le 20:00 -> prossimo refresh alle 20:00 di oggi
      nextRefresh = todayEvening;
    } else {
      // Dopo le 20:00 -> prossimo refresh alle 8:00 di domani
      nextRefresh = todayMorning.add(const Duration(days: 1));
    }
    
    final delay = nextRefresh.difference(now);
    
    // ignore: avoid_print
    print('ChannelsBackgroundRefresh: ⏰ Prossimo refresh programmato per: ${nextRefresh.toString().substring(0, 16)} (tra ${delay.inHours}h ${delay.inMinutes % 60}m)');
    
    _nextRefreshTimer = Timer(delay, () {
      _performBackgroundRefresh(ref, isScheduled: true);
      // Programma il refresh successivo
      _scheduleNextRefresh(ref);
    });
  }
  
  /// Esegue un refresh manuale forzato
  /// Scannerizza tutti i repository e aggiorna la cache con tutti i canali mancanti
  /// Accetta un Ref per invalidare i provider (può essere Ref o WidgetRef)
  Future<void> performManualRefresh(dynamic ref) async {
    return _performBackgroundRefresh(ref, isScheduled: false);
  }
  
  /// Esegue il refresh in background
  /// Scannerizza i repository, confronta con la cache e aggiunge i canali mancanti
  Future<void> _performBackgroundRefresh(dynamic ref, {required bool isScheduled}) async {
    try {
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 🔄 Inizio scan repository e confronto con cache...');
      
      // Carica i repository attivi
      final repositories = await LiveRepositoriesStorage.loadRepositoriesState();
      final activeRepositories = repositories.where((repo) => repo.enabled).toList();
      
      if (activeRepositories.isEmpty) {
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: ⚠️ Nessun repository attivo, skip refresh');
        return;
      }
      
      // Carica cache attuale
      final cachedChannels = await ChannelsCache.loadCachedChannels() ?? <Channel>[];
      final cachedChannelsMap = <String, Channel>{};
      for (final channel in cachedChannels) {
        cachedChannelsMap[channel.id] = channel;
      }
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 📦 Cache attuale: ${cachedChannels.length} canali');
      
      // Scannerizza tutti i repository e raccogli tutti i canali
      final allNewChannels = <String, Channel>{};
      var totalScanned = 0;
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 🔍 Scannerizzazione ${activeRepositories.length} repository attivi...');
      
      // Carica canali da tutti i repository usando lo stream
      await for (final channels in _repository.fetchChannelsStream(forceRefresh: true)) {
        totalScanned = channels.length;
        
        // Aggiungi tutti i canali alla mappa (sovrascrive duplicati con stesso ID)
        for (final channel in channels) {
          allNewChannels[channel.id] = channel;
        }
      }
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 📊 Scannerizzazione completata: ${allNewChannels.length} canali unici trovati nei repository');
      
      // Confronta con la cache e identifica canali mancanti
      final missingChannels = <Channel>[];
      final updatedChannels = <Channel>[];
      
      for (final newChannel in allNewChannels.values) {
        final cachedChannel = cachedChannelsMap[newChannel.id];
        
        if (cachedChannel == null) {
          // Canale completamente nuovo
          missingChannels.add(newChannel);
        } else {
          // Canale esistente - verifica se è stato aggiornato (es: URL cambiato)
          if (cachedChannel.streamUrl != newChannel.streamUrl ||
              cachedChannel.name != newChannel.name ||
              cachedChannel.logo != newChannel.logo) {
            updatedChannels.add(newChannel);
          }
        }
      }
      
      // Identifica anche canali rimossi (presenti in cache ma non nei repository)
      final removedChannels = <String>[];
      for (final cachedId in cachedChannelsMap.keys) {
        if (!allNewChannels.containsKey(cachedId)) {
          removedChannels.add(cachedId);
        }
      }
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: 📈 Analisi completata:');
      // ignore: avoid_print
      print('  - Canali in cache: ${cachedChannels.length}');
      // ignore: avoid_print
      print('  - Canali nei repository: ${allNewChannels.length}');
      // ignore: avoid_print
      print('  - Nuovi canali da aggiungere: ${missingChannels.length}');
      // ignore: avoid_print
      print('  - Canali aggiornati: ${updatedChannels.length}');
      // ignore: avoid_print
      print('  - Canali rimossi: ${removedChannels.length}');
      
      // Se ci sono nuovi canali o aggiornamenti, aggiorna la cache
      if (missingChannels.isNotEmpty || updatedChannels.isNotEmpty || removedChannels.isNotEmpty) {
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: 💾 Aggiornamento cache con nuovi/aggiornati canali...');
        
        // Unisci cache esistente con nuovi canali
        final finalChannels = <String, Channel>{};
        
        // Mantieni canali esistenti (tranne quelli rimossi o aggiornati)
        for (final cachedChannel in cachedChannels) {
          if (!removedChannels.contains(cachedChannel.id)) {
            finalChannels[cachedChannel.id] = cachedChannel;
          }
        }
        
        // Aggiungi/aggiorna con nuovi canali
        for (final newChannel in allNewChannels.values) {
          finalChannels[newChannel.id] = newChannel;
        }
        
        // Salva la cache aggiornata
        await ChannelsCache.saveChannels(finalChannels.values.toList());
        
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: ✅ Cache aggiornata: ${finalChannels.length} canali totali');
        
        // Log dettagliato dei nuovi canali
        if (missingChannels.isNotEmpty) {
          // ignore: avoid_print
          print('ChannelsBackgroundRefresh: ✨ Nuovi canali aggiunti:');
          for (final channel in missingChannels.take(10)) {
            // ignore: avoid_print
            print('  - ${channel.name} (id: ${channel.id})');
          }
          if (missingChannels.length > 10) {
            // ignore: avoid_print
            print('  ... e altri ${missingChannels.length - 10} canali');
          }
        }
        
        // Invalida il provider per forzare il reload con i nuovi canali
        ref.invalidate(channelsStreamProvider);
        
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: 🔄 Provider invalidato, UI si aggiornerà automaticamente');
      } else {
        // ignore: avoid_print
        print('ChannelsBackgroundRefresh: ℹ️ Nessuna modifica rilevata, cache già aggiornata');
      }
      
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: ✅ Refresh in background completato');
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: ❌ Errore nel refresh in background: $e');
      // ignore: avoid_print
      print('ChannelsBackgroundRefresh: Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
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
