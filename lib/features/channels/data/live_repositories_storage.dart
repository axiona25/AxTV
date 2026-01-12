import 'package:shared_preferences/shared_preferences.dart';
import '../../channels/model/repository_config.dart';
import 'live_repositories_config.dart';

/// Gestisce il salvataggio e il caricamento dello stato dei repository live
class LiveRepositoriesStorage {
  static const String _keyPrefix = 'live_repo_enabled_';

  /// Carica lo stato salvato dei repository live
  static Future<List<RepositoryConfig>> loadRepositoriesState() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultRepos = LiveRepositoriesConfig.defaultRepositories;

    return defaultRepos.map((repo) {
      final key = '$_keyPrefix${repo.id}';
      // Se non c'è un valore salvato, usa il valore di default
      final enabled = prefs.getBool(key) ?? repo.enabled;
      return repo.copyWith(enabled: enabled);
    }).toList();
  }

  /// Salva lo stato di un repository live
  static Future<void> saveRepositoryState(
      String repositoryId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$repositoryId';
    await prefs.setBool(key, enabled);
  }

  /// Salva lo stato di tutti i repository live
  static Future<void> saveAllRepositoriesState(
      List<RepositoryConfig> repositories) async {
    final prefs = await SharedPreferences.getInstance();
    for (final repo in repositories) {
      final key = '$_keyPrefix${repo.id}';
      await prefs.setBool(key, repo.enabled);
    }
  }

  /// Resetta tutti i repository live ai valori di default
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultRepos = LiveRepositoriesConfig.defaultRepositories;
    
    for (final repo in defaultRepos) {
      final key = '$_keyPrefix${repo.id}';
      await prefs.setBool(key, repo.enabled);
    }
  }
}
