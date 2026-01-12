import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/channel.dart';

/// Gestisce la cache dei canali per caricamento rapido
/// La cache viene aggiornata ogni volta che i canali vengono validati
class ChannelsCache {
  static const String _cacheKey = 'channels_cache';
  static const String _cacheTimestampKey = 'channels_cache_timestamp';
  static const String _cacheVersionKey = 'channels_cache_version';
  
  /// Versione della cache (incrementare quando cambia il formato)
  static const int _currentVersion = 1;
  
  /// Durata della cache prima di considerarla obsoleta (24 ore)
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  /// Carica i canali dalla cache
  /// Restituisce null se la cache non esiste o è obsoleta
  static Future<List<Channel>?> loadCachedChannels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verifica che la cache esista
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson == null || cacheJson.isEmpty) {
        // ignore: avoid_print
        print('ChannelsCache: ⚠️ Cache non trovata');
        return null;
      }
      
      // Verifica la versione della cache
      final cacheVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      if (cacheVersion != _currentVersion) {
        // ignore: avoid_print
        print('ChannelsCache: ⚠️ Versione cache obsoleta ($cacheVersion != $_currentVersion), invalidata');
        await clearCache();
        return null;
      }
      
      // Verifica che la cache non sia scaduta
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      if (cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
        );
        if (cacheAge > _cacheExpiration) {
          // ignore: avoid_print
          print('ChannelsCache: ⚠️ Cache scaduta (età: ${cacheAge.inHours}h), invalidata');
          await clearCache();
          return null;
        }
      }
      
      // Parsa i canali dalla cache
      final List<dynamic> channelsJson = jsonDecode(cacheJson);
      final channels = channelsJson
          .map((json) => Channel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // ignore: avoid_print
      print('ChannelsCache: ✅ Cache caricata: ${channels.length} canali (età: ${cacheTimestamp != null ? DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cacheTimestamp)).inMinutes : "N/A"} minuti)');
      
      return channels;
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsCache: ❌ Errore nel caricamento cache: $e');
      // In caso di errore, cancella la cache corrotta
      await clearCache();
      return null;
    }
  }
  
  /// Salva i canali nella cache
  static Future<void> saveChannels(List<Channel> channels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Converti i canali in JSON
      final channelsJson = channels.map((channel) => channel.toJson()).toList();
      final cacheJson = jsonEncode(channelsJson);
      
      // Salva cache, timestamp e versione
      await prefs.setString(_cacheKey, cacheJson);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_cacheVersionKey, _currentVersion);
      
      // ignore: avoid_print
      print('ChannelsCache: 💾 Cache salvata: ${channels.length} canali');
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsCache: ❌ Errore nel salvataggio cache: $e');
    }
  }
  
  /// Aggiorna la cache aggiungendo nuovi canali (merge)
  /// Mantiene i canali esistenti e aggiunge quelli nuovi
  static Future<void> updateCache(List<Channel> newChannels) async {
    try {
      final cachedChannels = await loadCachedChannels() ?? <Channel>[];
      
      // Crea una mappa per lookup veloce (per ID)
      final existingChannelsMap = <String, Channel>{};
      for (final channel in cachedChannels) {
        existingChannelsMap[channel.id] = channel;
      }
      
      // Aggiungi nuovi canali o aggiorna quelli esistenti
      for (final newChannel in newChannels) {
        existingChannelsMap[newChannel.id] = newChannel;
      }
      
      // Salva la cache aggiornata
      await saveChannels(existingChannelsMap.values.toList());
      
      // ignore: avoid_print
      print('ChannelsCache: 🔄 Cache aggiornata: ${newChannels.length} nuovi canali, totale: ${existingChannelsMap.length}');
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsCache: ❌ Errore nell\'aggiornamento cache: $e');
    }
  }
  
  /// Cancella la cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_cacheVersionKey);
      // ignore: avoid_print
      print('ChannelsCache: 🗑️ Cache cancellata');
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsCache: ❌ Errore nella cancellazione cache: $e');
    }
  }
  
  /// Verifica se la cache esiste ed è valida
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson == null || cacheJson.isEmpty) {
        return false;
      }
      
      final cacheVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      if (cacheVersion != _currentVersion) {
        return false;
      }
      
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      if (cacheTimestamp == null) {
        return false;
      }
      
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );
      
      return cacheAge <= _cacheExpiration;
    } catch (e) {
      return false;
    }
  }
}
