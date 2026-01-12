import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/ad_config.dart';
import '../state/ad_config_provider.dart';
import '../data/ad_statistics_storage.dart';
import '../utils/device_locale_helper.dart';
import '../../channels/model/repository_config.dart';
import '../../channels/data/live_repositories_storage.dart';

/// Manager per gestire le pubblicità con configurazione
class AdManager {
  final Ref ref;
  
  // Banner Ad
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  
  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;
  
  // Rewarded Ad
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  
  // Contatore ads mostrate oggi
  Map<String, int> _todayImpressions = {}; // key: format, value: count
  DateTime _lastResetDate = DateTime.now();

  AdManager(this.ref);

  /// Ottiene la configurazione pubblicità
  Future<AdConfig?> _getConfig() async {
    try {
      final configAsync = ref.read(adConfigProvider);
      return configAsync.maybeWhen(
        data: (config) => config,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica se le pubblicità sono abilitate
  Future<bool> _isEnabled() async {
    final config = await _getConfig();
    return config?.enabled ?? false;
  }

  /// Ottiene l'Ad Unit ID per un formato (usa test se testMode)
  Future<String?> _getAdUnitId(String format) async {
    final config = await _getConfig();
    if (config == null) return null;
    
    // Test Mode: usa test ad units
    if (config.testMode) {
      switch (format) {
        case 'banner':
          return 'ca-app-pub-3940256099942544/6300978111';
        case 'interstitial':
          return 'ca-app-pub-3940256099942544/1033173712';
        case 'rewarded':
          return 'ca-app-pub-3940256099942544/5224354917';
        default:
          return null;
      }
    }
    
    // Produzione: usa ad units configurati
    switch (format) {
      case 'banner':
        return config.bannerAdUnitId;
      case 'interstitial':
        return config.interstitialAdUnitId;
      case 'rewarded':
        return config.rewardedAdUnitId;
      default:
        return null;
    }
  }

  /// Verifica se mostrare l'ad in base alla configurazione
  Future<bool> _shouldShowAd({
    String? country,
    String? language,
    String? repository,
    String? category,
  }) async {
    final config = await _getConfig();
    if (config == null || !config.enabled) return false;
    
    // Verifica paese
    if (config.countries.isNotEmpty && country != null) {
      if (!config.countries.contains(country)) return false;
    }
    
    // Verifica lingua
    if (config.languages.isNotEmpty && language != null) {
      if (!config.languages.contains(language)) return false;
    }
    
    // Verifica repository
    if (config.enabledRepositories.isNotEmpty && repository != null) {
      if (!config.enabledRepositories.contains(repository)) return false;
    }
    
    // Verifica categoria (se disponibile)
    if (config.categories.isNotEmpty && category != null) {
      if (!config.categories.contains(category)) return false;
    }
    
    // Verifica frequenza giornaliera
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final impressionsToday = _todayImpressions.values.fold<int>(0, (sum, count) => sum + count);
    
    if (impressionsToday >= config.maxPerDay) {
      return false; // Raggiunto limite giornaliero
    }
    
    return true;
  }

  /// Resetta contatore giornaliero se necessario
  void _resetDailyCounterIfNeeded() {
    final now = DateTime.now();
    if (now.day != _lastResetDate.day || 
        now.month != _lastResetDate.month || 
        now.year != _lastResetDate.year) {
      _todayImpressions.clear();
      _lastResetDate = now;
    }
  }

  /// Carica Banner Ad
  Future<void> loadBannerAd({
    AdSize? size,
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    // AdMob non supportato su macOS/web
    if (!Platform.isAndroid && !Platform.isIOS) {
      onAdFailedToLoad?.call('Ads not supported on this platform');
      return;
    }
    
    if (!await _isEnabled()) {
      onAdFailedToLoad?.call('Ads disabled');
      return;
    }
    
    final adUnitId = await _getAdUnitId('banner');
    if (adUnitId == null) {
      onAdFailedToLoad?.call('Ad Unit ID not configured');
      return;
    }
    
    _bannerAd?.dispose();
    _isBannerAdReady = false;
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerAdReady = true;
          onAdLoaded?.call();
          _recordRequest('banner');
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          _isBannerAdReady = false;
          onAdFailedToLoad?.call(err.message);
          _recordRequest('banner');
        },
        onAdOpened: (_) {
          _recordClick('banner');
        },
        onAdImpression: (_) async {
          await _recordImpression(
            format: 'banner',
            estimatedRevenue: 0.005, // Stima conservativa
            eCPM: 5.0,
          );
        },
      ),
    );

    _bannerAd?.load();
  }

  /// Ottiene il widget Banner Ad
  Widget? getBannerAdWidget() {
    if (!_isBannerAdReady || _bannerAd == null) {
      return null;
    }
    
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Carica Interstitial Ad
  Future<void> loadInterstitialAd({
    String? country,
    String? language,
    String? repository,
    String? category,
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    // AdMob non supportato su macOS/web
    if (!Platform.isAndroid && !Platform.isIOS) {
      onAdFailedToLoad?.call('Ads not supported on this platform');
      return;
    }
    
    if (!await _isEnabled()) {
      onAdFailedToLoad?.call('Ads disabled');
      return;
    }
    
    // Verifica se dovrebbe mostrare l'ad
    if (!await _shouldShowAd(
      country: country,
      language: language,
      repository: repository,
      category: category,
    )) {
      onAdFailedToLoad?.call('Ad not allowed by configuration');
      return;
    }
    
    final adUnitId = await _getAdUnitId('interstitial');
    if (adUnitId == null) {
      onAdFailedToLoad?.call('Ad Unit ID not configured');
      return;
    }
    
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          onAdLoaded?.call();
          _recordRequest('interstitial');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _numInterstitialLoadAttempts += 1;
          if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            loadInterstitialAd(
              country: country,
              language: language,
              repository: repository,
              category: category,
              onAdLoaded: onAdLoaded,
              onAdFailedToLoad: onAdFailedToLoad,
            );
          } else {
            onAdFailedToLoad?.call(error.message);
          }
          _recordRequest('interstitial');
        },
      ),
    );
  }

  /// Mostra Interstitial Ad
  Future<void> showInterstitialAd({
    String? country,
    String? language,
    String? repository,
    String? category,
    VoidCallback? onAdDismissed,
  }) async {
    if (_interstitialAd == null) {
      // Carica nuovo ad
      await loadInterstitialAd(
        country: country,
        language: language,
        repository: repository,
        category: category,
      );
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        _resetDailyCounterIfNeeded();
        _todayImpressions['interstitial'] = (_todayImpressions['interstitial'] ?? 0) + 1;
        onAdDismissed?.call();
        // Ricarica nuovo ad
        loadInterstitialAd(
          country: country,
          language: language,
          repository: repository,
          category: category,
        );
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        // Ricarica nuovo ad
        loadInterstitialAd(
          country: country,
          language: language,
          repository: repository,
          category: category,
        );
      },
      onAdImpression: (InterstitialAd ad) async {
        await _recordImpression(
          format: 'interstitial',
          country: country,
          language: language,
          repository: repository,
          estimatedRevenue: 0.015, // Stima conservativa
          eCPM: 15.0,
        );
        _resetDailyCounterIfNeeded();
        _todayImpressions['interstitial'] = (_todayImpressions['interstitial'] ?? 0) + 1;
      },
      onAdClicked: (InterstitialAd ad) {
        _recordClick('interstitial');
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  /// Carica Rewarded Video Ad
  Future<void> loadRewardedAd({
    String? country,
    String? language,
    String? repository,
    String? category,
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    // AdMob non supportato su macOS/web
    if (!Platform.isAndroid && !Platform.isIOS) {
      onAdFailedToLoad?.call('Ads not supported on this platform');
      return;
    }
    
    if (!await _isEnabled()) {
      onAdFailedToLoad?.call('Ads disabled');
      return;
    }
    
    // Verifica se dovrebbe mostrare l'ad
    if (!await _shouldShowAd(
      country: country,
      language: language,
      repository: repository,
      category: category,
    )) {
      onAdFailedToLoad?.call('Ad not allowed by configuration');
      return;
    }
    
    final adUnitId = await _getAdUnitId('rewarded');
    if (adUnitId == null) {
      onAdFailedToLoad?.call('Ad Unit ID not configured');
      return;
    }
    
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
          onAdLoaded?.call();
          _recordRequest('rewarded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          onAdFailedToLoad?.call(error.message);
          _recordRequest('rewarded');
        },
      ),
    );
  }

  /// Mostra Rewarded Video Ad
  Future<void> showRewardedAd({
    String? country,
    String? language,
    String? repository,
    String? category,
    required Function(RewardItem) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    Function()? onAdFailedToShow,
  }) async {
    if (_rewardedAd == null) {
      // Carica nuovo ad
      await loadRewardedAd(
        country: country,
        language: language,
        repository: repository,
        category: category,
      );
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null;
        _resetDailyCounterIfNeeded();
        _todayImpressions['rewarded'] = (_todayImpressions['rewarded'] ?? 0) + 1;
        onAdDismissed?.call();
        // Ricarica nuovo ad
        loadRewardedAd(
          country: country,
          language: language,
          repository: repository,
          category: category,
        );
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        onAdFailedToShow?.call();
        // Ricarica nuovo ad
        loadRewardedAd(
          country: country,
          language: language,
          repository: repository,
          category: category,
        );
      },
      onAdImpression: (RewardedAd ad) async {
        await _recordImpression(
          format: 'rewarded',
          country: country,
          language: language,
          repository: repository,
          estimatedRevenue: 0.020, // Stima conservativa
          eCPM: 20.0,
        );
        _resetDailyCounterIfNeeded();
        _todayImpressions['rewarded'] = (_todayImpressions['rewarded'] ?? 0) + 1;
      },
      onAdClicked: (RewardedAd ad) {
        _recordClick('rewarded');
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );

    _rewardedAd = null;
  }

  /// Registra una richiesta ad
  void _recordRequest(String format) {
    AdStatisticsStorage.recordRequest(format: format);
  }

  /// Registra un'impressione
  Future<void> _recordImpression({
    required String format,
    String? country,
    String? language,
    String? repository,
    double estimatedRevenue = 0.0,
    double eCPM = 0.0,
  }) async {
    // Ottieni paese e lingua del dispositivo se non specificati
    if (country == null || language == null) {
      final locale = Platform.localeName.split('_');
      country ??= locale.length > 1 ? locale[1].toLowerCase() : null;
      language ??= locale.isNotEmpty ? locale[0].toLowerCase() : null;
    }
    
    await AdStatisticsStorage.recordImpression(
      format: format,
      country: country,
      language: language,
      repository: repository,
      estimatedRevenue: estimatedRevenue,
      eCPM: eCPM,
    );
  }

  /// Registra un click
  void _recordClick(String format) {
    AdStatisticsStorage.recordClick(format: format);
  }

  /// Dispose delle risorse
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}

/// Provider per AdManager
final adManagerProvider = Provider<AdManager>((ref) {
  final manager = AdManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});
