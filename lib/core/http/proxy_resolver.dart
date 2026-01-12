import 'package:dio/dio.dart';

/// Paesi disponibili per simulazione
enum GeoLocation {
  usa,
  uk,
  germany,
  canada,
  france,
  spain,
  italy,
}

/// Servizio per risolvere URL geoblocked tramite proxy e header personalizzati
/// 
/// Questo servizio può:
/// - Usare proxy HTTP pubblici per bypassare geoblocking
/// - Modificare header HTTP per simulare una posizione geografica diversa
/// - Gestire redirect e URL finali
class ProxyResolver {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    followRedirects: true,
    maxRedirects: 10,
  ));

  /// Mappa dei paesi ai loro header HTTP
  static Map<GeoLocation, Map<String, String>> _geoHeaders = {
    GeoLocation.usa: {
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'US',
      'X-Forwarded-For': '8.8.8.8',
    },
    GeoLocation.uk: {
      'Accept-Language': 'en-GB,en;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'GB',
      'X-Forwarded-For': '1.1.1.1',
    },
    GeoLocation.germany: {
      'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'DE',
      'X-Forwarded-For': '1.0.0.1',
    },
    GeoLocation.canada: {
      'Accept-Language': 'en-CA,en;q=0.9,fr;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'CA',
      'X-Forwarded-For': '1.1.1.1',
    },
    GeoLocation.france: {
      'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'FR',
      'X-Forwarded-For': '1.0.0.1',
    },
    GeoLocation.spain: {
      'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'ES',
      'X-Forwarded-For': '1.0.0.1',
    },
    GeoLocation.italy: {
      'Accept-Language': 'it-IT,it;q=0.9,en;q=0.8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'CF-IPCountry': 'IT',
      'X-Forwarded-For': '1.0.0.1',
    },
  };

  /// Risolve un URL geoblocked tramite proxy e header personalizzati
  /// 
  /// [originalUrl] URL originale che potrebbe essere geoblocked
  /// [preferredLocation] Paese da simulare (default: USA)
  /// [useProxy] Se true, usa un proxy HTTP (se disponibile)
  /// [tryMultipleLocations] Se true, prova più location se la prima fallisce
  /// 
  /// Restituisce l'URL originale con header personalizzati che possono essere passati al player
  /// o un URL proxy se useProxy è true
  Future<ResolvedProxyUrl> resolveGeoblockedUrl(
    String originalUrl, {
    GeoLocation preferredLocation = GeoLocation.usa,
    bool useProxy = false,
    bool tryMultipleLocations = true,
  }) async {
    // ignore: avoid_print
    print('ProxyResolver: [START] Risolvo URL geoblocked: $originalUrl');
    // ignore: avoid_print
    print('ProxyResolver: [CONFIG] Location: $preferredLocation, UseProxy: $useProxy, TryMultiple: $tryMultipleLocations');

    // Se useProxy è true, prova a usare un proxy HTTP pubblico
    if (useProxy) {
      try {
        final proxyUrl = await _resolveViaProxy(originalUrl, preferredLocation);
        if (proxyUrl != null) {
          // ignore: avoid_print
          print('ProxyResolver: [SUCCESS] Risolto tramite proxy: $proxyUrl');
          return ResolvedProxyUrl(
            url: proxyUrl,
            headers: _geoHeaders[preferredLocation] ?? {},
            method: ProxyMethod.proxy,
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('ProxyResolver: [ERROR] Proxy fallito: $e');
      }
    }

    // Se tryMultipleLocations è true e l'URL è potenzialmente geoblocked, prepara location alternative
    List<GeoLocation>? alternativeLocations;
    if (tryMultipleLocations && isPotentiallyGeoblocked(originalUrl)) {
      // ignore: avoid_print
      print('ProxyResolver: [MULTI-LOCATION] Preparo location alternative per bypassare geoblock...');
      
      // Lista di location da provare (in ordine di priorità)
      // Rimuoviamo la location preferita dalla lista alternative (già usata)
      final allLocations = [
        GeoLocation.usa, // USA spesso funziona meglio
        GeoLocation.uk,  // UK come fallback
        GeoLocation.germany, // Germania
        GeoLocation.canada, // Canada
        GeoLocation.france, // Francia
        GeoLocation.spain, // Spagna
        GeoLocation.italy, // Italia come ultimo tentativo
      ];
      
      // Crea lista alternative escludendo la location preferita
      alternativeLocations = allLocations.where((loc) => loc != preferredLocation).toList();
      
      // ignore: avoid_print
      print('ProxyResolver: [LOCATION] Location preferita: $preferredLocation');
      // ignore: avoid_print
      print('ProxyResolver: [LOCATION] Location alternative disponibili: ${alternativeLocations.length}');
    }

    // Prova con la location preferita
    final preferredHeaders = _getHeadersForLocation(preferredLocation);
    // ignore: avoid_print
    print('ProxyResolver: [FALLBACK] Uso header personalizzati con location: $preferredLocation');
    return ResolvedProxyUrl(
      url: originalUrl,
      headers: preferredHeaders,
      method: ProxyMethod.headers,
      alternativeLocations: alternativeLocations,
    );
  }

  /// Prova a risolvere un URL tramite un proxy HTTP pubblico
  Future<String?> _resolveViaProxy(String url, GeoLocation location) async {
    // Per video streaming, i proxy pubblici gratuiti spesso non funzionano bene
    // perché richiedono troppo bandwidth. Invece, modifichiamo l'URL per passare
    // attraverso servizi che possono aiutare a bypassare geoblocking
    
    // Opzione 1: Usa un proxy CORS pubblico (funziona solo per test HEAD)
    // Opzione 2: Costruisci un URL che passa attraverso un servizio proxy
    // Per ora, restituiamo null e usiamo solo header personalizzati
    // perché i proxy pubblici gratuiti non sono adatti per video streaming
    
    // TODO: In futuro, potremmo integrare un servizio proxy dedicato
    // che supporti video streaming (richiede server proprio o servizio a pagamento)
    
    print('ProxyResolver: [INFO] Proxy HTTP pubblico non disponibile per video streaming');
    print('ProxyResolver: [INFO] Uso solo header personalizzati per simulare geolocalizzazione');
    
    return null; // Per ora, non usiamo proxy reali per video streaming
  }

  /// Costruisce un URL proxy
  String _buildProxyUrl(String proxyBase, String targetUrl) {
    return '$proxyBase${Uri.encodeComponent(targetUrl)}';
  }

  /// Ottiene gli header per una posizione geografica
  Map<String, String> _getHeadersForLocation(GeoLocation location) {
    final baseHeaders = _geoHeaders[location] ?? _geoHeaders[GeoLocation.usa]!;
    
    return {
      ...baseHeaders,
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Referer': 'https://www.google.com/',
      'Origin': 'https://www.google.com',
      'Sec-Fetch-Dest': 'video',
      'Sec-Fetch-Mode': 'no-cors',
      'Sec-Fetch-Site': 'cross-site',
    };
  }

  /// Verifica se un URL è potenzialmente geoblocked
  /// 
  /// Controlla pattern comuni di URL che potrebbero essere geoblocked
  static bool isPotentiallyGeoblocked(String url) {
    final geoblockedPatterns = [
      'zplaypro.lat',
      'zplaypro.com',
      '.mp4', // URL MP4 diretti potrebbero essere geoblocked
    ];

    return geoblockedPatterns.any((pattern) => url.contains(pattern));
  }
}

/// Risultato della risoluzione proxy
class ResolvedProxyUrl {
  /// URL finale da usare (potrebbe essere originale o proxy)
  final String url;

  /// Header HTTP da usare per la richiesta
  final Map<String, String> headers;

  /// Metodo usato per la risoluzione
  final ProxyMethod method;

  /// Location alternative da provare se questa fallisce
  final List<GeoLocation>? alternativeLocations;

  ResolvedProxyUrl({
    required this.url,
    required this.headers,
    required this.method,
    this.alternativeLocations,
  });
}

/// Metodo usato per risolvere l'URL
enum ProxyMethod {
  /// Usato solo header HTTP personalizzati
  headers,
  
  /// Usato un proxy HTTP
  proxy,
}