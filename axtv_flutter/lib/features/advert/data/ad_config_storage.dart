import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ad_config.dart';

/// Gestisce il salvataggio e il caricamento della configurazione pubblicità
class AdConfigStorage {
  static const String _key = 'ad_config';

  /// Carica la configurazione pubblicità salvata
  static Future<AdConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_key);
      
      if (configJson == null) {
        return AdConfig.defaultConfig;
      }
      
      final Map<String, dynamic> configMap = json.decode(configJson);
      return AdConfig.fromMap(configMap);
    } catch (e) {
      // In caso di errore, ritorna la configurazione di default
      return AdConfig.defaultConfig;
    }
  }

  /// Salva la configurazione pubblicità
  static Future<void> saveConfig(AdConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configMap = config.toMap();
      final configJson = json.encode(configMap);
      await prefs.setString(_key, configJson);
    } catch (e) {
      throw Exception('Errore nel salvataggio della configurazione pubblicità: $e');
    }
  }

  /// Resetta la configurazione ai valori di default
  static Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      throw Exception('Errore nel ripristino della configurazione: $e');
    }
  }
}
