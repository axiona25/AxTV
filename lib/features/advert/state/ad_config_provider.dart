import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/ad_config.dart';
import '../data/ad_config_storage.dart';

/// Provider per la configurazione pubblicità
final adConfigProvider = FutureProvider<AdConfig>((ref) async {
  return await AdConfigStorage.loadConfig();
});

/// Notifier per gestire la configurazione pubblicità (salvataggio)
class AdConfigNotifier {
  /// Salva la configurazione e invalida il provider
  static Future<void> saveConfig(WidgetRef ref, AdConfig config) async {
    try {
      await AdConfigStorage.saveConfig(config);
      ref.invalidate(adConfigProvider);
    } catch (e) {
      rethrow;
    }
  }

  /// Resetta la configurazione ai valori di default e invalida il provider
  static Future<void> resetToDefaults(WidgetRef ref) async {
    try {
      await AdConfigStorage.resetToDefaults();
      ref.invalidate(adConfigProvider);
    } catch (e) {
      rethrow;
    }
  }
}
