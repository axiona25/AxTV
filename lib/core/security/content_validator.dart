/// Validatore di sicurezza per contenuti
/// 
/// Questo modulo implementa meccanismi di sicurezza per:
/// - Rilevare contenuti non autorizzati
/// - Validare URL sospetti
/// - Bloccare domini noti per contenuti pirata
class ContentValidator {
  /// Domini noti per contenuti pirata (per test di sicurezza)
  static const List<String> _blockedDomains = [
    'openload.co',
    'fmovies.to',
    '123movies.com',
    'pirate-stream',
    'free-movies',
  ];

  /// Pattern sospetti negli URL
  static const List<String> _suspiciousPatterns = [
    '.mp4',
    '.mkv',
    '.avi',
    'cdn-anonimo',
    'netflix-rip',
    'prime-rip',
    'disney-rip',
  ];

  /// Valida un URL per contenuti sospetti
  /// Restituisce true se l'URL è sicuro, false se sospetto
  static bool validateUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Controlla domini bloccati
    for (final domain in _blockedDomains) {
      if (lowerUrl.contains(domain)) {
        return false;
      }
    }
    
    // Controlla pattern sospetti
    for (final pattern in _suspiciousPatterns) {
      if (lowerUrl.contains(pattern)) {
        return false;
      }
    }
    
    // Controlla riferimenti a servizi premium
    final premiumServices = ['netflix', 'prime', 'disney', 'hbo', 'hulu'];
    for (final service in premiumServices) {
      if (lowerUrl.contains(service) && !lowerUrl.contains('official')) {
        // Potrebbe essere un riferimento non autorizzato
        // Log per analisi (non blocca, ma avvisa)
        // ignore: avoid_print
        print('ContentValidator: Riferimento a $service rilevato in URL');
      }
    }
    
    return true;
  }

  /// Valida un canale completo
  /// Restituisce true se il canale è sicuro
  static bool validateChannel({
    required String streamUrl,
    String? name,
  }) {
    // Valida URL
    if (!validateUrl(streamUrl)) {
      return false;
    }
    
    // Controlli aggiuntivi sul nome
    if (name != null) {
      final lowerName = name.toLowerCase();
      final suspiciousNames = ['pirate', 'free-movie', 'illegal'];
      for (final suspicious in suspiciousNames) {
        if (lowerName.contains(suspicious)) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Log di sicurezza (per test e analisi)
  static void logSecurityEvent(String event, Map<String, dynamic>? details) {
    // ignore: avoid_print
    print('🔒 Security Event: $event');
    if (details != null) {
      // ignore: avoid_print
      print('   Details: $details');
    }
  }
}

