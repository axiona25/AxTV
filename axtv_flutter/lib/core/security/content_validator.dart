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

  /// Domini/pattern noti per URL non funzionanti o problematici
  /// Questi URL vengono filtrati durante il caricamento per evitare errori nel player
  /// NOTA: `/play/` è gestito separatamente per permettere URL IPTV-org
  static const List<String> _problematicUrlPatterns = [
    'streaming101tv.es', // URL problematico segnalato
    '/udp/', // UDP streams tunnelizzati via HTTP (spesso non funzionano)
    // '/play/' rimosso - gestito separatamente per permettere IPTV-org
    '188.60.179.180', // IP problematico segnalato (ma permesso se da IPTV-org)
    '49.113.179.174', // IP problematico segnalato
    'geo-blocked',
    '[Geo-blocked]',
    '[Not 24/7]',
    // Aggiungi qui altri pattern problematici noti
  ];

  /// Pattern sospetti negli URL
  /// Nota: .mp4, .mkv, .avi sono rimossi perché archive.org e altri servizi legittimi li usano
  static const List<String> _suspiciousPatterns = [
    'cdn-anonimo',
    'netflix-rip',
    'prime-rip',
    'disney-rip',
  ];
  
  /// Domini consentiti (whitelist) per contenuti legittimi
  static const List<String> _allowedDomains = [
    'archive.org',
    'zappr.stream',
    'cloudflare-api.zappr.stream',
    'vercel-api.zappr.stream',
    'zplaypro.lat', // Server usato da m3u8-xtream-playlist
    'zplaypro.com', // Server usato da m3u8-xtream-playlist
    'supabase.co', // Supabase Storage per M3U playlists
    'cloudfront.net', // AWS CloudFront (usato da IPTV-org)
    'mediaset.net', // MediaSet (usato da IPTV-org)
    'xdevel.com', // XDevel (usato da IPTV-org)
    'iptv-org.github.io', // Repository IPTV-org
  ];

  /// Valida un URL per contenuti sospetti
  /// Restituisce true se l'URL è sicuro, false se sospetto
  static bool validateUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Prima controlla se è in whitelist (domini consentiti)
    for (final domain in _allowedDomains) {
      if (lowerUrl.contains(domain)) {
        return true; // Domini consentiti sono sempre validi
      }
    }
    
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
  /// Restituisce true se il canale è sicuro e l'URL è valido
  static bool validateChannel({
    required String streamUrl,
    String? name,
  }) {
    final lowerUrl = streamUrl.toLowerCase();
    
    // Valida URL base (controlli sicurezza)
    if (!validateUrl(streamUrl)) {
      return false;
    }
    
    // Controlla pattern di URL problematici noti (PRIMA di altre validazioni per velocità)
    // ECCEZIONE: Permetti pattern /play/ per URL IPTV-org (gestito separatamente dopo)
    for (final pattern in _problematicUrlPatterns) {
      if (lowerUrl.contains(pattern.toLowerCase())) {
        // Se è il pattern /play/ e potrebbe essere da IPTV-org, salta (gestito dopo)
        if (pattern == '/play/') {
          continue; // Gestito separatamente dopo
        }
        logSecurityEvent(
          'URL problematico filtrato (pattern: $pattern)',
          {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl},
        );
        return false;
      }
    }
    
    // Filtra URL con IP diretti che usano UDP streams (quasi sempre problematici)
    // Pattern: http://IP:PORT/udp/ o simile
    if (RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/udp/').hasMatch(lowerUrl)) {
      logSecurityEvent(
        'URL UDP stream via IP diretto filtrato',
        {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl},
      );
      return false;
    }
    
    // Filtra URL con IP diretti e path /play/ (proxy/relay problematici)
    // Pattern: http://IP:PORT/play/xxx (es: http://188.60.179.180:8000/play/xxRaiYoyo)
    // ECCEZIONE: Permetti URL /play/ da repository IPTV-org perché sono proxy/relay legittimi
    // che potrebbero funzionare (sebbene instabili). L'utente può comunque provare a riprodurli.
    if (RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/play/').hasMatch(lowerUrl)) {
      // Per URL IP diretti con /play/, permetti solo se:
      // 1. È formato M3U8/HLS (potrebbe essere un proxy HLS legittimo)
      // 2. O è da un dominio noto di IPTV-org
      final isM3U8 = lowerUrl.contains('.m3u8') || lowerUrl.contains('.m3u');
      final isKnownIptvOrgDomain = lowerUrl.contains('cloudfront.net') ||
                                   lowerUrl.contains('mediaset.net') ||
                                   lowerUrl.contains('xdevel.com') ||
                                   lowerUrl.contains('30a-tv.com');
      
      // Permetti solo se è M3U8 o da dominio noto IPTV-org
      if (!isM3U8 && !isKnownIptvOrgDomain) {
        logSecurityEvent(
          'URL IP diretto con path /play/ filtrato (non M3U8 e non da dominio noto IPTV-org)',
          {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl},
        );
        return false;
      } else {
        // URL IPTV-org con /play/ - permetti ma avvisa (potrebbe non funzionare)
        logSecurityEvent(
          'URL IPTV-org con /play/ permesso (potenzialmente problematico ma M3U8 o da dominio noto)',
          {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl, 'isM3U8': isM3U8, 'isKnownDomain': isKnownIptvOrgDomain},
        );
        // Non bloccare - l'utente può provare a riprodurlo
      }
    }
    
    // Controlla anche pattern /play/ generico (non solo IP diretti)
    // Permetti per URL M3U8/HLS (potrebbero essere proxy/relay legittimi da IPTV-org)
    if (lowerUrl.contains('/play/') && !lowerUrl.contains('.m3u8') && !lowerUrl.contains('.m3u')) {
      // Se NON è M3U8/HLS e contiene /play/, potrebbe essere problematico
      // Ma permetti se è da dominio noto IPTV-org
      final isKnownIptvOrgDomain = lowerUrl.contains('cloudfront.net') ||
                                   lowerUrl.contains('mediaset.net') ||
                                   lowerUrl.contains('xdevel.com') ||
                                   lowerUrl.contains('30a-tv.com');
      
      if (!isKnownIptvOrgDomain) {
        logSecurityEvent(
          'URL con pattern /play/ filtrato (non M3U8 e non da dominio noto IPTV-org)',
          {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl},
        );
        return false;
      }
    }
    
    // Filtra URL con doppio IP:porta (proxy/relay che spesso non funzionano)
    // Pattern come: http://IP1:PORT/udp/IP2:PORT
    if (RegExp(r'\d+\.\d+\.\d+\.\d+:\d+.*\d+\.\d+\.\d+\.\d+:\d+').hasMatch(lowerUrl)) {
      if (lowerUrl.contains('/udp/') || lowerUrl.contains('/stream/')) {
        logSecurityEvent(
          'URL proxy/relay UDP filtrato',
          {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl},
        );
        return false;
      }
    }
    
    // Filtra IP diretti su porte non standard (spesso problematici)
    // IP diretti senza dominio sono spesso instabili e problematici
    final ipPattern = RegExp(r'http://(\d+\.\d+\.\d+\.\d+):(\d+)');
    final ipMatch = ipPattern.firstMatch(lowerUrl);
    if (ipMatch != null) {
      final port = int.tryParse(ipMatch.group(2) ?? '') ?? 0;
      
      // Filtra IP diretti che non sono in whitelist (domini noti)
      // Archive.org, Akamai, CloudFront, Netplus, zplaypro, IPTV-org sono OK perché usano CDN affidabili o server legittimi
      final isWhitelistedDomain = lowerUrl.contains('archive.org') || 
                                   lowerUrl.contains('akamaized.net') ||
                                   lowerUrl.contains('cloudfront.net') || // IPTV-org
                                   lowerUrl.contains('netplus.ch') ||
                                   lowerUrl.contains('zplaypro.lat') ||
                                   lowerUrl.contains('zplaypro.com') ||
                                   lowerUrl.contains('supabase.co') ||
                                   lowerUrl.contains('mediaset.net') || // IPTV-org
                                   lowerUrl.contains('xdevel.com') || // IPTV-org
                                   lowerUrl.contains('30a-tv.com'); // IPTV-org
      
      if (!isWhitelistedDomain) {
        // Per IP diretti, accetta solo se:
        // 1. Porta standard (80, 443) O
        // 2. Formato M3U8/HLS valido su porta comune (8080, 8081) O
        // 3. URL da domini CDN noti (già controllato sopra)
        
        final isStandardPort = port == 80 || port == 443;
        final isCommonHlsPort = (port == 8080 || port == 8081) && 
                                 (lowerUrl.contains('.m3u8') || lowerUrl.contains('.m3u'));
        
        // Filtra IP diretti su porte non standard che non sono M3U8/HLS
        // Porte come 8000, 4022, ecc. su IP diretti sono spesso problematiche
        if (!isStandardPort && !isCommonHlsPort) {
          // Porte > 5000 su IP diretti senza formato M3U8 sono quasi sempre problematiche
          if (port > 5000 && !lowerUrl.contains('.m3u8') && !lowerUrl.contains('.m3u')) {
            logSecurityEvent(
              'URL IP diretto con porta alta filtrato',
              {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl, 'port': port},
            );
            return false;
          }
          
          // Porte 8000-4999 su IP diretti sono spesso problematiche (es: 8000, 4022)
          // Permetti solo se è formato M3U8/HLS valido e non ha pattern problematici
          if (port >= 8000 && port <= 4999) {
            if (!lowerUrl.contains('.m3u8') && !lowerUrl.contains('.m3u')) {
              // Non è M3U8, filtra
              logSecurityEvent(
                'URL IP diretto con porta non standard filtrato',
                {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl, 'port': port},
              );
              return false;
            }
          }
        }
      }
    }
    
    // Controlla se l'URL è un formato HLS/M3U8 valido
    // Permette: .m3u8, .m3u, http/https, rtmp
    if (lowerUrl.contains('.m3u8') || lowerUrl.contains('.m3u')) {
      // URL HLS/M3U valido
      if (!lowerUrl.startsWith('http://') && 
          !lowerUrl.startsWith('https://') && 
          !lowerUrl.startsWith('rtmp://')) {
        logSecurityEvent(
          'URL HLS con formato non valido',
          {'url': streamUrl.length > 100 ? '${streamUrl.substring(0, 100)}...' : streamUrl},
        );
        return false;
      }
    }
    
    // Controlli aggiuntivi sul nome
    if (name != null) {
      final lowerName = name.toLowerCase();
      
      // Controlla pattern sospetti nel nome
      final suspiciousNames = ['pirate', 'free-movie', 'illegal'];
      for (final suspicious in suspiciousNames) {
        if (lowerName.contains(suspicious)) {
          return false;
        }
      }
      
      // Filtra canali con indicatori di problemi nel nome
      final problematicIndicators = ['[geo-blocked]', '[not 24/7]', '[offline]', '[broken]'];
      for (final indicator in problematicIndicators) {
        if (lowerName.contains(indicator)) {
          logSecurityEvent(
            'Canale con indicatore problematico nel nome',
            {'name': name, 'indicator': indicator},
          );
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Verifica se un URL è potenzialmente problematico
  /// Restituisce true se l'URL potrebbe non funzionare
  static bool isProblematicUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Controlla pattern problematici
    for (final pattern in _problematicUrlPatterns) {
      if (lowerUrl.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    
    // Controlla se è un URL che potrebbe essere geoblocked
    // (questo è solo un avviso, non blocca)
    final geoBlockedPatterns = ['geo-blocked', 'geoblocked', 'region-locked'];
    for (final pattern in geoBlockedPatterns) {
      if (lowerUrl.contains(pattern)) {
        return true;
      }
    }
    
    return false;
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

