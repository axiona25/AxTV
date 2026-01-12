/// Configurazione pubblicità per l'app
class AdConfig {
  /// Abilita/disabilita le pubblicità
  final bool enabled;
  
  /// Lista di codici paese per cui mostrare le pubblicità (es: ['it', 'fr', 'de'])
  final List<String> countries;
  
  /// Lista di codici lingua per cui mostrare le pubblicità (es: ['it', 'en', 'fr'])
  final List<String> languages;
  
  /// Numero massimo di volte al giorno per mostrare le pubblicità
  final int maxPerDay;
  
  /// Durata minima del video (in secondi) prima di mostrare pubblicità
  final int minVideoDurationSeconds;
  
  /// Lista di ID repository per cui mostrare le pubblicità (se vuota = tutti)
  final List<String> enabledRepositories;
  
  /// Lista di ID repository per cui NON mostrare le pubblicità
  final List<String> disabledRepositories;
  
  /// Lista di categorie tematiche per cui mostrare le pubblicità
  /// (es: ['Intrattenimento', 'News', 'Sport'])
  final List<String> categories;
  
  /// Ad Unit ID per Banner Ads
  final String? bannerAdUnitId;
  
  /// Ad Unit ID per Interstitial Ads
  final String? interstitialAdUnitId;
  
  /// Ad Unit ID per Rewarded Video Ads
  final String? rewardedAdUnitId;
  
  /// Test Mode (usa test ad units se true)
  final bool testMode;

  const AdConfig({
    this.enabled = false,
    this.countries = const [],
    this.languages = const [],
    this.maxPerDay = 10,
    this.minVideoDurationSeconds = 30,
    this.enabledRepositories = const [],
    this.disabledRepositories = const [],
    this.categories = const [],
    this.bannerAdUnitId,
    this.interstitialAdUnitId,
    this.rewardedAdUnitId,
    this.testMode = true,
  });

  /// Crea una copia con valori aggiornati
  AdConfig copyWith({
    bool? enabled,
    List<String>? countries,
    List<String>? languages,
    int? maxPerDay,
    int? minVideoDurationSeconds,
    List<String>? enabledRepositories,
    List<String>? disabledRepositories,
    List<String>? categories,
    String? bannerAdUnitId,
    String? interstitialAdUnitId,
    String? rewardedAdUnitId,
    bool? testMode,
  }) {
    return AdConfig(
      enabled: enabled ?? this.enabled,
      countries: countries ?? this.countries,
      languages: languages ?? this.languages,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      minVideoDurationSeconds: minVideoDurationSeconds ?? this.minVideoDurationSeconds,
      enabledRepositories: enabledRepositories ?? this.enabledRepositories,
      disabledRepositories: disabledRepositories ?? this.disabledRepositories,
      categories: categories ?? this.categories,
      bannerAdUnitId: bannerAdUnitId ?? this.bannerAdUnitId,
      interstitialAdUnitId: interstitialAdUnitId ?? this.interstitialAdUnitId,
      rewardedAdUnitId: rewardedAdUnitId ?? this.rewardedAdUnitId,
      testMode: testMode ?? this.testMode,
    );
  }


  /// Crea da Map (da storage) - versione compatibile con SharedPreferences
  factory AdConfig.fromMap(Map<String, dynamic> map) {
    return AdConfig(
      enabled: map['enabled'] as bool? ?? false,
      countries: List<String>.from(map['countries'] as List? ?? []),
      languages: List<String>.from(map['languages'] as List? ?? []),
      maxPerDay: map['maxPerDay'] as int? ?? 10,
      minVideoDurationSeconds: map['minVideoDurationSeconds'] as int? ?? 30,
      enabledRepositories: List<String>.from(map['enabledRepositories'] as List? ?? []),
      disabledRepositories: List<String>.from(map['disabledRepositories'] as List? ?? []),
      categories: List<String>.from(map['categories'] as List? ?? []),
      bannerAdUnitId: map['bannerAdUnitId'] as String?,
      interstitialAdUnitId: map['interstitialAdUnitId'] as String?,
      rewardedAdUnitId: map['rewardedAdUnitId'] as String?,
      testMode: map['testMode'] as bool? ?? true,
    );
  }

  /// Converte in Map per SharedPreferences (con supporto liste)
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'countries': countries,
      'languages': languages,
      'maxPerDay': maxPerDay,
      'minVideoDurationSeconds': minVideoDurationSeconds,
      'enabledRepositories': enabledRepositories,
      'disabledRepositories': disabledRepositories,
      'categories': categories,
      'bannerAdUnitId': bannerAdUnitId,
      'interstitialAdUnitId': interstitialAdUnitId,
      'rewardedAdUnitId': rewardedAdUnitId,
      'testMode': testMode,
    };
  }

  /// Configurazione di default
  static const AdConfig defaultConfig = AdConfig(
    enabled: false,
    countries: [],
    languages: [],
    maxPerDay: 10,
    minVideoDurationSeconds: 30,
    enabledRepositories: [],
    disabledRepositories: [],
    categories: [],
    testMode: true,
  );
}
