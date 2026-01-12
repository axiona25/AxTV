import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ad_statistics.dart';

/// Gestisce il salvataggio e il caricamento delle statistiche pubblicità
class AdStatisticsStorage {
  static const String _key = 'ad_statistics';

  /// Carica le statistiche salvate
  static Future<AdStatistics> loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_key);
      
      if (statsJson == null) {
        return AdStatistics.empty();
      }
      
      final Map<String, dynamic> statsMap = json.decode(statsJson);
      return AdStatistics.fromMap(statsMap);
    } catch (e) {
      // In caso di errore, ritorna statistiche vuote
      return AdStatistics.empty();
    }
  }

  /// Salva le statistiche
  static Future<void> saveStatistics(AdStatistics statistics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsMap = statistics.toMap();
      final statsJson = json.encode(statsMap);
      await prefs.setString(_key, statsJson);
    } catch (e) {
      throw Exception('Errore nel salvataggio delle statistiche: $e');
    }
  }

  /// Aggiunge una nuova impressione alle statistiche
  static Future<void> recordImpression({
    required String format, // 'banner', 'interstitial', 'rewarded'
    String? country,
    String? language,
    String? repository,
    double estimatedRevenue = 0.0,
    double eCPM = 0.0,
  }) async {
    final stats = await loadStatistics();
    final now = DateTime.now();
    final today = _formatDate(now);
    
    // Aggiorna formato stats
    final formatStats = Map<String, AdFormatStats>.from(stats.formatStats);
    final currentFormatStats = formatStats[format] ?? const AdFormatStats();
    formatStats[format] = currentFormatStats.copyWith(
      impressions: currentFormatStats.impressions + 1,
      requests: currentFormatStats.requests + 1,
      estimatedRevenue: currentFormatStats.estimatedRevenue + estimatedRevenue,
      eCPM: eCPM,
    );
    
    // Aggiorna country stats
    final countryImpressions = Map<String, int>.from(stats.countryImpressions);
    if (country != null) {
      countryImpressions[country] = (countryImpressions[country] ?? 0) + 1;
    }
    
    // Aggiorna language stats
    final languageImpressions = Map<String, int>.from(stats.languageImpressions);
    if (language != null) {
      languageImpressions[language] = (languageImpressions[language] ?? 0) + 1;
    }
    
    // Aggiorna repository stats
    final repositoryImpressions = Map<String, int>.from(stats.repositoryImpressions);
    if (repository != null) {
      repositoryImpressions[repository] = (repositoryImpressions[repository] ?? 0) + 1;
    }
    
    // Aggiorna daily stats
    final dailyStats = Map<String, DailyStats>.from(stats.dailyStats);
    final todayStats = dailyStats[today] ?? DailyStats(date: today);
    dailyStats[today] = todayStats.copyWith(
      impressions: todayStats.impressions + 1,
      estimatedRevenue: todayStats.estimatedRevenue + estimatedRevenue,
    );
    
    // Calcola fill rate (impressioni/tentativi)
    final totalRequests = formatStats.values.fold<int>(0, (sum, s) => sum + s.requests);
    final totalImpressions = formatStats.values.fold<int>(0, (sum, s) => sum + s.impressions);
    final fillRate = totalRequests > 0 ? (totalImpressions / totalRequests) * 100 : 0.0;
    
    // Calcola CTR
    final totalClicks = stats.totalClicks;
    final ctr = totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;
    
    // Statistiche oggi
    final todayImpressions = todayStats.impressions + 1;
    final todayRevenue = todayStats.estimatedRevenue + estimatedRevenue;
    
    // Crea nuova statistica
    final newStats = stats.copyWith(
      lastUpdate: now,
      totalImpressions: stats.totalImpressions + 1,
      estimatedRevenue: stats.estimatedRevenue + estimatedRevenue,
      formatStats: formatStats,
      countryImpressions: countryImpressions,
      languageImpressions: languageImpressions,
      repositoryImpressions: repositoryImpressions,
      dailyStats: dailyStats,
      fillRate: fillRate,
      ctr: ctr,
      todayImpressions: todayImpressions,
      todayRevenue: todayRevenue,
    );
    
    await saveStatistics(newStats);
  }

  /// Registra un click su un'ad
  static Future<void> recordClick({
    required String format,
  }) async {
    final stats = await loadStatistics();
    final now = DateTime.now();
    final today = _formatDate(now);
    
    // Aggiorna formato stats
    final formatStats = Map<String, AdFormatStats>.from(stats.formatStats);
    final currentFormatStats = formatStats[format] ?? const AdFormatStats();
    formatStats[format] = currentFormatStats.copyWith(
      clicks: currentFormatStats.clicks + 1,
    );
    
    // Aggiorna daily stats
    final dailyStats = Map<String, DailyStats>.from(stats.dailyStats);
    final todayStats = dailyStats[today] ?? DailyStats(date: today);
    dailyStats[today] = todayStats.copyWith(
      clicks: todayStats.clicks + 1,
    );
    
    // Calcola CTR
    final totalClicks = stats.totalClicks + 1;
    final ctr = stats.totalImpressions > 0 ? (totalClicks / stats.totalImpressions) * 100 : 0.0;
    
    // Crea nuova statistica
    final newStats = stats.copyWith(
      lastUpdate: now,
      totalClicks: totalClicks,
      formatStats: formatStats,
      dailyStats: dailyStats,
      ctr: ctr,
    );
    
    await saveStatistics(newStats);
  }

  /// Registra una richiesta ad (anche se fallisce)
  static Future<void> recordRequest({
    required String format,
  }) async {
    final stats = await loadStatistics();
    
    // Aggiorna formato stats (solo requests, non impressions)
    final formatStats = Map<String, AdFormatStats>.from(stats.formatStats);
    final currentFormatStats = formatStats[format] ?? const AdFormatStats();
    formatStats[format] = currentFormatStats.copyWith(
      requests: currentFormatStats.requests + 1,
    );
    
    // Calcola fill rate
    final totalRequests = formatStats.values.fold<int>(0, (sum, s) => sum + s.requests);
    final totalImpressions = formatStats.values.fold<int>(0, (sum, s) => sum + s.impressions);
    final fillRate = totalRequests > 0 ? (totalImpressions / totalRequests) * 100 : 0.0;
    
    // Crea nuova statistica
    final newStats = stats.copyWith(
      lastUpdate: DateTime.now(),
      formatStats: formatStats,
      fillRate: fillRate,
    );
    
    await saveStatistics(newStats);
  }

  /// Resetta tutte le statistiche
  static Future<void> resetStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      throw Exception('Errore nel reset delle statistiche: $e');
    }
  }

  /// Formatta data in YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
