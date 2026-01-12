/// Statistiche pubblicità in tempo reale
class AdStatistics {
  /// Data dell'ultimo aggiornamento
  final DateTime lastUpdate;
  
  /// Statistiche totali
  final int totalImpressions;
  final int totalClicks;
  final double estimatedRevenue;
  
  /// Statistiche per formato
  final Map<String, AdFormatStats> formatStats;
  
  /// Statistiche per paese
  final Map<String, int> countryImpressions;
  
  /// Statistiche per lingua
  final Map<String, int> languageImpressions;
  
  /// Statistiche per repository
  final Map<String, int> repositoryImpressions;
  
  /// Statistiche giornaliere (ultimi 30 giorni)
  final Map<String, DailyStats> dailyStats;
  
  /// Fill rate (impressioni/tentativi)
  final double fillRate;
  
  /// Click-through rate (CTR)
  final double ctr;
  
  /// Numero di ads mostrate oggi
  final int todayImpressions;
  
  /// Revenue stimato oggi
  final double todayRevenue;

  const AdStatistics({
    required this.lastUpdate,
    this.totalImpressions = 0,
    this.totalClicks = 0,
    this.estimatedRevenue = 0.0,
    this.formatStats = const {},
    this.countryImpressions = const {},
    this.languageImpressions = const {},
    this.repositoryImpressions = const {},
    this.dailyStats = const {},
    this.fillRate = 0.0,
    this.ctr = 0.0,
    this.todayImpressions = 0,
    this.todayRevenue = 0.0,
  });

  /// Crea una copia con valori aggiornati
  AdStatistics copyWith({
    DateTime? lastUpdate,
    int? totalImpressions,
    int? totalClicks,
    double? estimatedRevenue,
    Map<String, AdFormatStats>? formatStats,
    Map<String, int>? countryImpressions,
    Map<String, int>? languageImpressions,
    Map<String, int>? repositoryImpressions,
    Map<String, DailyStats>? dailyStats,
    double? fillRate,
    double? ctr,
    int? todayImpressions,
    double? todayRevenue,
  }) {
    return AdStatistics(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      totalImpressions: totalImpressions ?? this.totalImpressions,
      totalClicks: totalClicks ?? this.totalClicks,
      estimatedRevenue: estimatedRevenue ?? this.estimatedRevenue,
      formatStats: formatStats ?? this.formatStats,
      countryImpressions: countryImpressions ?? this.countryImpressions,
      languageImpressions: languageImpressions ?? this.languageImpressions,
      repositoryImpressions: repositoryImpressions ?? this.repositoryImpressions,
      dailyStats: dailyStats ?? this.dailyStats,
      fillRate: fillRate ?? this.fillRate,
      ctr: ctr ?? this.ctr,
      todayImpressions: todayImpressions ?? this.todayImpressions,
      todayRevenue: todayRevenue ?? this.todayRevenue,
    );
  }

  /// Converte in Map per storage
  Map<String, dynamic> toMap() {
    return {
      'lastUpdate': lastUpdate.toIso8601String(),
      'totalImpressions': totalImpressions,
      'totalClicks': totalClicks,
      'estimatedRevenue': estimatedRevenue,
      'formatStats': formatStats.map((k, v) => MapEntry(k, v.toMap())),
      'countryImpressions': countryImpressions,
      'languageImpressions': languageImpressions,
      'repositoryImpressions': repositoryImpressions,
      'dailyStats': dailyStats.map((k, v) => MapEntry(k, v.toMap())),
      'fillRate': fillRate,
      'ctr': ctr,
      'todayImpressions': todayImpressions,
      'todayRevenue': todayRevenue,
    };
  }

  /// Crea da Map (da storage)
  factory AdStatistics.fromMap(Map<String, dynamic> map) {
    return AdStatistics(
      lastUpdate: DateTime.parse(map['lastUpdate'] as String? ?? DateTime.now().toIso8601String()),
      totalImpressions: map['totalImpressions'] as int? ?? 0,
      totalClicks: map['totalClicks'] as int? ?? 0,
      estimatedRevenue: (map['estimatedRevenue'] as num?)?.toDouble() ?? 0.0,
      formatStats: (map['formatStats'] as Map<String, dynamic>?)?.map((k, v) => 
        MapEntry(k, AdFormatStats.fromMap(v as Map<String, dynamic>))) ?? {},
      countryImpressions: Map<String, int>.from(map['countryImpressions'] as Map? ?? {}),
      languageImpressions: Map<String, int>.from(map['languageImpressions'] as Map? ?? {}),
      repositoryImpressions: Map<String, int>.from(map['repositoryImpressions'] as Map? ?? {}),
      dailyStats: (map['dailyStats'] as Map<String, dynamic>?)?.map((k, v) => 
        MapEntry(k, DailyStats.fromMap(v as Map<String, dynamic>))) ?? {},
      fillRate: (map['fillRate'] as num?)?.toDouble() ?? 0.0,
      ctr: (map['ctr'] as num?)?.toDouble() ?? 0.0,
      todayImpressions: map['todayImpressions'] as int? ?? 0,
      todayRevenue: (map['todayRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Statistiche vuote (iniziali)
  static AdStatistics empty() {
    return AdStatistics(
      lastUpdate: DateTime.now(),
    );
  }
}

/// Statistiche per formato ad (Banner, Interstitial, Rewarded)
class AdFormatStats {
  final int impressions;
  final int clicks;
  final double estimatedRevenue;
  final int requests;
  final double eCPM; // Revenue per 1000 impressioni

  const AdFormatStats({
    this.impressions = 0,
    this.clicks = 0,
    this.estimatedRevenue = 0.0,
    this.requests = 0,
    this.eCPM = 0.0,
  });

  AdFormatStats copyWith({
    int? impressions,
    int? clicks,
    double? estimatedRevenue,
    int? requests,
    double? eCPM,
  }) {
    return AdFormatStats(
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      estimatedRevenue: estimatedRevenue ?? this.estimatedRevenue,
      requests: requests ?? this.requests,
      eCPM: eCPM ?? this.eCPM,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'impressions': impressions,
      'clicks': clicks,
      'estimatedRevenue': estimatedRevenue,
      'requests': requests,
      'eCPM': eCPM,
    };
  }

  factory AdFormatStats.fromMap(Map<String, dynamic> map) {
    return AdFormatStats(
      impressions: map['impressions'] as int? ?? 0,
      clicks: map['clicks'] as int? ?? 0,
      estimatedRevenue: (map['estimatedRevenue'] as num?)?.toDouble() ?? 0.0,
      requests: map['requests'] as int? ?? 0,
      eCPM: (map['eCPM'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Calcola il fill rate (impressioni/richieste)
  double get fillRate {
    if (requests == 0) return 0.0;
    return (impressions / requests) * 100;
  }

  /// Calcola il CTR (click-through rate)
  double get clickThroughRate {
    if (impressions == 0) return 0.0;
    return (clicks / impressions) * 100;
  }
}

/// Statistiche giornaliere
class DailyStats {
  final String date; // Formato: YYYY-MM-DD
  final int impressions;
  final int clicks;
  final double estimatedRevenue;

  const DailyStats({
    required this.date,
    this.impressions = 0,
    this.clicks = 0,
    this.estimatedRevenue = 0.0,
  });

  DailyStats copyWith({
    String? date,
    int? impressions,
    int? clicks,
    double? estimatedRevenue,
  }) {
    return DailyStats(
      date: date ?? this.date,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      estimatedRevenue: estimatedRevenue ?? this.estimatedRevenue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'impressions': impressions,
      'clicks': clicks,
      'estimatedRevenue': estimatedRevenue,
    };
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      date: map['date'] as String,
      impressions: map['impressions'] as int? ?? 0,
      clicks: map['clicks'] as int? ?? 0,
      estimatedRevenue: (map['estimatedRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
