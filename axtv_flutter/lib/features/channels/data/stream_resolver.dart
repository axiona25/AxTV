import 'package:dio/dio.dart';
import 'dart:io' show HttpClient, HttpClientRequest, HttpClientResponse;
import 'dart:convert';
import '../../../config/env.dart';
import '../../../core/http/dio_client.dart';
import '../../../core/security/content_validator.dart';
import 'zappr_protocol_resolver.dart';

class StreamResolver {
  final Dio _dio = dioProvider;
  final _zapprResolver = ZapprProtocolResolver();
  
  // Cache per autenticazione Rai (come fa Zappr)
  String? _cachedRaiAuth;
  int? _cachedRaiAuthExpiration;
  
  /// Risolve un URL con schema zappr://
  /// Usa il risolutore dedicato
  Future<Uri> _resolveZapprProtocol(String zapprUrl) async {
    // Usa il componente dedicato per risolvere URL zappr://
    // Prova prima con la strategia principale, poi con fallback
    try {
      return await _zapprResolver.resolve(zapprUrl);
    } catch (e) {
      // ignore: avoid_print
      print('StreamResolver: Strategia principale fallita, provo fallback: $e');
      return await _zapprResolver.resolveWithFallback(zapprUrl);
    }
  }
  

  /// Risolve l'URL originale in un URL riproducibile
  /// Se necessario, chiama le API Zappr per ottenere l'URL finale
  Uri resolvePlayableUrl(String originalUrl) {
    final url = originalUrl.trim();
    
    // URL con schema zappr:// sono sempre validi (schema personalizzato Zappr)
    final isZapprProtocol = url.startsWith('zappr://');
    
    // TMDB non supportato - gli URL TMDB non sono riproducibili direttamente
    // if (url.startsWith('tmdb://')) {
    //   return Uri.parse('${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}');
    // }
    
    // Validazione sicurezza (skip per URL zappr://)
    if (!isZapprProtocol && !ContentValidator.validateUrl(url)) {
      ContentValidator.logSecurityEvent(
        'Blocked URL in resolvePlayableUrl',
        {'url': url.substring(0, 100)},
      );
      throw Exception('URL non autorizzato rilevato per test di sicurezza');
    }

    final isDailymotion = url.contains('dailymotion.com/video/');
    final isLivestream = url.contains('livestream.com/accounts/');
    final isNetplus = url.contains('viamotionhsi.netplus.ch/live/eds/');

    final isRaiMediapolis = url.contains('mediapolis.rai.it/relinker/relinkerServlet');
    final isBabylonCloud = url.contains('/video/viewlivestreaming');

    // Casi che Zappr risolve con Cloudflare
    // Zappr costruisce: ${backend.host[api]}/api?${url}
    // Env.cloudflareApiBase già include /api
    // URL zappr:// vengono risolti tramite API Cloudflare
    if (isZapprProtocol || isDailymotion || isLivestream || isNetplus) {
      return Uri.parse('${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}');
    }

    // Casi che Zappr risolve con Vercel
    // Zappr costruisce: ${backend.host[api]}/api?${url}
    // Env.vercelApiBase già include /api
    if (isRaiMediapolis || isBabylonCloud) {
      return Uri.parse('${Env.vercelApiBase}?${Uri.encodeComponent(url)}');
    }

    // Già riproducibile (es. .m3u8 diretto)
    return Uri.parse(url);
  }

  /// Ottiene l'autenticazione Rai Akamai dall'API Zappr
  /// Restituisce la stringa di autenticazione da aggiungere all'URL
  Future<String> _getRaiAkamaiAuth() async {
    // Cache check (come fa Zappr: expiration - Math.floor(Date.now() / 1000) > 10)
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_cachedRaiAuth != null && 
        _cachedRaiAuthExpiration != null && 
        _cachedRaiAuthExpiration! - now > 10) {
      // ignore: avoid_print
      print('StreamResolver: Usa auth Rai dalla cache (expires in ${_cachedRaiAuthExpiration! - now}s)');
      return _cachedRaiAuth!;
    }
    
    try {
      // ignore: avoid_print
      print('StreamResolver: Richiedo autenticazione Rai Akamai da ${Env.alwaysdataApiBase}/rai-akamai');
      
      // Crea un Dio instance separato con timeout più lunghi per questa richiesta
      // Usa la stessa configurazione di Zappr web: fetch con POST e response.text()
      // Prova prima con configurazione minimale
      Dio dio;
      try {
        dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Accept': '*/*',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Origin': 'https://zappr.stream',
              'Referer': 'https://zappr.stream/',
            },
          ),
        );
      } catch (e) {
        // Se fallisce, prova con configurazione ancora più semplice
        // ignore: avoid_print
        print('StreamResolver: Errore creazione Dio, uso configurazione minimale: $e');
        dio = Dio();
      }
      
      // Zappr usa: fetch(`${window["zappr"].config.backend.host["alwaysdata"]}/rai-akamai`, { method: "POST" })
      // Poi: response.text() per ottenere la stringa
      // NON specifica contentType, quindi Dio userà il default
      final response = await dio.post(
        '${Env.alwaysdataApiBase}/rai-akamai',
        options: Options(
          validateStatus: (status) => status! < 500,
          responseType: ResponseType.plain, // Restituisce testo, non JSON (come response.text() in JS)
          followRedirects: true,
          // NON specificare contentType - Zappr non lo fa
        ),
      );
      
      // Verifica che la risposta sia valida
      if (response.statusCode != 200) {
        throw Exception('API autenticazione Rai restituisce status ${response.statusCode}');
      }
      
      // L'API restituisce direttamente la stringa di autenticazione (es. "?hdnea=...")
      String auth = response.data.toString().trim();
      
      // ignore: avoid_print
      print('StreamResolver: Status code: ${response.statusCode}, Data type: ${response.data.runtimeType}');
      
      // ignore: avoid_print
      print('StreamResolver: Risposta raw (tipo: ${response.data.runtimeType}, lunghezza: ${auth.length}): ${auth.substring(0, auth.length > 80 ? 80 : auth.length)}...');
      
      // Verifica che l'auth non sia vuota
      if (auth.isEmpty) {
        throw Exception('Autenticazione Rai vuota ricevuta dall\'API');
      }
      
      // Assicurati che inizi con "?" se non c'è già
      if (!auth.startsWith('?')) {
        auth = '?$auth';
      }
      
      // ignore: avoid_print
      print('StreamResolver: Autenticazione finale (lunghezza: ${auth.length}): ${auth.substring(0, auth.length > 80 ? 80 : auth.length)}...');
      
      // Estrai expiration dall'auth (come fa Zappr)
      // Format: ?hdnea=st=...~exp=1767796701~acl=...
      try {
        final expMatch = RegExp(r'exp=(\d+)').firstMatch(auth);
        if (expMatch != null) {
          _cachedRaiAuthExpiration = int.parse(expMatch.group(1)!);
          _cachedRaiAuth = auth;
          // ignore: avoid_print
          print('StreamResolver: Auth Rai memorizzata in cache (expires: $_cachedRaiAuthExpiration)');
        }
      } catch (e) {
        // ignore: avoid_print
        print('StreamResolver: Impossibile estrarre expiration da auth: $e');
      }
      
      // Chiudi il Dio instance dopo aver ottenuto l'auth
      dio.close();
      
      return auth;
    } on DioException catch (dioError) {
      // Se Dio fallisce con connection error, prova con HttpClient standard
      // ignore: avoid_print
      print('StreamResolver: DioException: ${dioError.type} - ${dioError.message}');
      if (dioError.type == DioExceptionType.connectionError || 
          dioError.type == DioExceptionType.connectionTimeout) {
        // ignore: avoid_print
        print('StreamResolver: Errore di connessione Dio, provo con HttpClient standard...');
        try {
          final client = HttpClient();
          final request = await client.postUrl(
            Uri.parse('${Env.alwaysdataApiBase}/rai-akamai'),
          );
          request.headers.set('Accept', '*/*');
          request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
          request.headers.set('Origin', 'https://zappr.stream');
          request.headers.set('Referer', 'https://zappr.stream/');
          
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();
          
          if (response.statusCode != 200) {
            throw Exception('API autenticazione Rai restituisce status ${response.statusCode}');
          }
          
          String auth = responseBody.trim();
          
          if (auth.isEmpty) {
            throw Exception('Autenticazione Rai vuota ricevuta dall\'API');
          }
          
          if (!auth.startsWith('?')) {
            auth = '?$auth';
          }
          
          // ignore: avoid_print
          print('StreamResolver: Autenticazione ottenuta con HttpClient (lunghezza: ${auth.length})');
          
          // Estrai expiration e salva in cache
          try {
            final expMatch = RegExp(r'exp=(\d+)').firstMatch(auth);
            if (expMatch != null) {
              _cachedRaiAuthExpiration = int.parse(expMatch.group(1)!);
              _cachedRaiAuth = auth;
            }
          } catch (e) {
            // ignore: avoid_print
            print('StreamResolver: Impossibile estrarre expiration da auth: $e');
          }
          
          client.close();
          return auth;
        } catch (httpError) {
          // ignore: avoid_print
          print('StreamResolver: Anche HttpClient fallito: $httpError');
          rethrow;
        }
      }
      rethrow;
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('StreamResolver: Errore nell\'ottenere autenticazione Rai: $e');
      print('StreamResolver: Tipo errore: ${e.runtimeType}');
      if (e is DioException) {
        print('StreamResolver: DioException type: ${e.type}');
        print('StreamResolver: DioException message: ${e.message}');
        print('StreamResolver: DioException response: ${e.response?.statusCode}');
        if (e.type == DioExceptionType.connectionError) {
          print('StreamResolver: Errore di connessione - verifica connessione internet');
        }
      }
      print('StreamResolver: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Risolve l'URL seguendo i redirect delle API Zappr
  /// Restituisce l'URL finale riproducibile
  /// [license] può essere "rai-akamai" per canali Rai che richiedono autenticazione
  Future<Uri> resolvePlayableUrlAsync(String originalUrl, {String? license}) async {
    final resolverStart = DateTime.now();
    final url = originalUrl.trim();
    
    // TMDB non supportato - gli URL TMDB non sono riproducibili direttamente
    // if (url.startsWith('tmdb://')) {
    //   throw Exception('Film TMDB non riproducibile - richiedono ricerca link streaming');
    // }
    
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════════');
    print('StreamResolver: [RESOLVE_START] Risolvo URL');
    print('StreamResolver: [RESOLVE] URL originale: $url');
    print('StreamResolver: [RESOLVE] License: ${license ?? "nessuna"}');
    print('StreamResolver: [RESOLVE] Timestamp: ${resolverStart.toIso8601String()}');
    
    // URL con schema zappr:// sono sempre validi (schema personalizzato Zappr)
    final isZapprProtocol = url.startsWith('zappr://');
    
    // ignore: avoid_print
    print('StreamResolver: [RESOLVE] URL trimmed: $url');
    print('StreamResolver: [RESOLVE] È zappr://: $isZapprProtocol');
    
    // Validazione sicurezza (skip per URL zappr://)
    if (!isZapprProtocol && !ContentValidator.validateUrl(url)) {
      // ignore: avoid_print
      print('StreamResolver: [SECURITY] URL bloccato dalla validazione');
      ContentValidator.logSecurityEvent(
        'Blocked URL in resolvePlayableUrlAsync',
        {'url': url.substring(0, 100), 'license': license},
      );
      throw Exception('URL non autorizzato rilevato per test di sicurezza');
    }
    
    // ignore: avoid_print
    print('StreamResolver: [RESOLVE] Validazione superata');

    final isDailymotion = url.contains('dailymotion.com/video/');
    final isLivestream = url.contains('livestream.com/accounts/');
    final isNetplus = url.contains('viamotionhsi.netplus.ch/live/eds/');

    final isRaiMediapolis = url.contains('mediapolis.rai.it/relinker/relinkerServlet');
    final isBabylonCloud = url.contains('/video/viewlivestreaming');
    final isTurnerStreamity = url.contains('feapi.turner.streamity.com') || url.contains('turner.streamity.com');

    // Se è un canale Rai con license rai-akamai
    if (license == 'rai-akamai') {
      // Se è un URL mediapolis.rai.it, usa API Vercel (come fa Zappr)
      if (url.contains('mediapolis.rai.it')) {
        // ignore: avoid_print
        print('StreamResolver: Canale Rai Mediapolis, uso API Vercel (come Zappr)');
        final apiUrl = '${Env.vercelApiBase}?${Uri.encodeComponent(url)}';
        // L'API Vercel gestisce l'autenticazione internamente
        return Uri.parse(apiUrl);
      }
      
      // Se l'URL è già un HLS diretto (es. akamaized.net), prova auth
      if (url.contains('akamaized.net')) {
        try {
          // ignore: avoid_print
          print('StreamResolver: Canale Rai HLS diretto, provo autenticazione...');
          final auth = await _getRaiAkamaiAuth();
          
          // L'auth restituisce già "?hdnea=..." quindi aggiungilo direttamente
          final urlWithAuth = '$url$auth';
          
          // ignore: avoid_print
          print('StreamResolver: URL finale con auth: ${urlWithAuth.substring(0, urlWithAuth.length > 200 ? 200 : urlWithAuth.length)}...');
          
          // Verifica che l'URL sia valido
          final uri = Uri.parse(urlWithAuth);
          if (uri.scheme.isEmpty || uri.host.isEmpty) {
            throw Exception('URL non valido dopo aggiunta autenticazione: $urlWithAuth');
          }
          
          return uri;
        } catch (e) {
          // Se l'autenticazione fallisce, usa API Vercel come fallback
          // L'API Vercel potrebbe gestire l'autenticazione internamente
          // ignore: avoid_print
          print('StreamResolver: Errore nell\'ottenere autenticazione Rai: $e');
          print('StreamResolver: Fallback: uso API Vercel per canale Rai HLS');
          final apiUrl = '${Env.vercelApiBase}?${Uri.encodeComponent(url)}';
          return Uri.parse(apiUrl);
        }
      }
    }
    
    String apiUrl;
    
    // Determina quale API usare
    // Zappr costruisce: ${backend.host[api]}/api?${url}
    // Env.cloudflareApiBase e Env.vercelApiBase già includono /api
    
    // URL con schema zappr:// vengono risolti con sistema dedicato
    if (isZapprProtocol) {
      // ignore: avoid_print
      print('StreamResolver: [RESOLVE] Rilevato URL zappr://, uso risolutore dedicato');
      final result = await _resolveZapprProtocol(url);
      final resolverDuration = DateTime.now().difference(resolverStart);
      // ignore: avoid_print
      print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
      print('StreamResolver: [RESOLVE] URL risolto: ${result.toString().length > 200 ? '${result.toString().substring(0, 200)}...' : result}');
      print('═══════════════════════════════════════════════════════════');
      return result;
    } else if (isDailymotion || isLivestream || isNetplus) {
      // ignore: avoid_print
      print('StreamResolver: [RESOLVE] Rilevato URL che richiede API Cloudflare');
      apiUrl = '${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}';
    } else if (isRaiMediapolis || isBabylonCloud) {
      apiUrl = '${Env.vercelApiBase}?${Uri.encodeComponent(url)}';
    } else if (isTurnerStreamity) {
      // URL Turner Streamity restituiscono JSON con l'URL dello stream dentro
      // Devo chiamare l'API, parsare il JSON e estrarre l'URL dello stream
      // ignore: avoid_print
      print('StreamResolver: [TURNER] Rilevato URL Turner Streamity API, risolvo JSON...');
      try {
        final response = await _dio.get(
          url,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://zappr.stream/',
              'Origin': 'https://zappr.stream',
              'Accept': 'application/json, */*',
            },
            validateStatus: (status) => status! < 500,
            responseType: ResponseType.json,
          ),
        );
        
        // ignore: avoid_print
        print('StreamResolver: [TURNER] Response status: ${response.statusCode}');
        print('StreamResolver: [TURNER] Response data type: ${response.data.runtimeType}');
        
        // Se la risposta è String invece di JSON, potrebbe essere un errore HTML/text
        if (response.data is String) {
          // ignore: avoid_print
          print('StreamResolver: [TURNER] ⚠️ Risposta è String (non JSON): ${(response.data as String).substring(0, (response.data as String).length > 200 ? 200 : (response.data as String).length)}');
        }
        
        if (response.statusCode == 200 && response.data != null && response.data is Map) {
          final jsonData = response.data;
          // ignore: avoid_print
          print('StreamResolver: [TURNER] JSON keys: ${jsonData is Map ? jsonData.keys.toList() : "not a map"}');
          
          // Cerca l'URL dello stream nel JSON (potrebbe essere in vari campi)
          String? streamUrl;
          if (jsonData is Map) {
            // Prova vari campi comuni
            streamUrl = jsonData['streamUrl'] as String? ??
                       jsonData['url'] as String? ??
                       jsonData['hlsUrl'] as String? ??
                       jsonData['m3u8'] as String? ??
                       jsonData['playlistUrl'] as String?;
            
            // Se non trovato, cerca in oggetti annidati
            if (streamUrl == null && jsonData.containsKey('data')) {
              final data = jsonData['data'];
              if (data is Map) {
                streamUrl = data['streamUrl'] as String? ??
                           data['url'] as String? ??
                           data['hlsUrl'] as String? ??
                           data['m3u8'] as String?;
              }
            }
            
            // Se ancora non trovato, cerca in config
            if (streamUrl == null && jsonData.containsKey('config')) {
              final config = jsonData['config'];
              if (config is Map) {
                streamUrl = config['streamUrl'] as String? ??
                           config['url'] as String? ??
                           config['hlsUrl'] as String?;
              }
            }
          }
          
          if (streamUrl != null && streamUrl.isNotEmpty) {
            // ignore: avoid_print
            print('StreamResolver: [TURNER] ✅ URL stream trovato nel JSON: ${streamUrl.length > 200 ? streamUrl.substring(0, 200) + "..." : streamUrl}');
            final resolverDuration = DateTime.now().difference(resolverStart);
            print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
            print('═══════════════════════════════════════════════════════════');
            return Uri.parse(streamUrl);
          } else {
            // ignore: avoid_print
            print('StreamResolver: [TURNER] ⚠️ URL stream non trovato nel JSON');
            print('StreamResolver: [TURNER] JSON completo: $jsonData');
            throw Exception('URL stream non trovato nella risposta JSON di Turner Streamity');
          }
        } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
          // ignore: avoid_print
          print('StreamResolver: [TURNER] ❌ API restituisce ${response.statusCode} (${response.statusCode == 401 ? "Unauthorized" : (response.statusCode == 403 ? "Forbidden" : "Not Found")})');
          print('StreamResolver: [TURNER] ⚠️ L\'API Turner Streamity potrebbe non essere accessibile direttamente da iOS');
          print('StreamResolver: [TURNER] 🔄 Fallback: provo a usare API Zappr come proxy...');
          
          // Fallback: usa API Zappr come proxy per accedere all'API Turner
          try {
            final proxyUrl = '${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}';
            // ignore: avoid_print
            print('StreamResolver: [TURNER] 🔄 Provo con proxy Zappr: $proxyUrl');
            
            final proxyResponse = await _dio.get(
              proxyUrl,
              options: Options(
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Referer': 'https://zappr.stream/',
                  'Origin': 'https://zappr.stream',
                  'Accept': 'application/json, */*',
                },
                validateStatus: (status) => status! < 500,
                responseType: ResponseType.json,
                followRedirects: true,
                maxRedirects: 10,
              ),
            );
            
            // ignore: avoid_print
            print('StreamResolver: [TURNER] Proxy response status: ${proxyResponse.statusCode}');
            print('StreamResolver: [TURNER] Proxy response data type: ${proxyResponse.data.runtimeType}');
            
            // Il proxy Zappr potrebbe restituire direttamente lo stream HLS invece di JSON
            // Controlla se è un redirect o se contiene un URL HLS
            if (proxyResponse.redirects.isNotEmpty) {
              final finalUrl = proxyResponse.redirects.last.location.toString();
              // ignore: avoid_print
              print('StreamResolver: [TURNER] ✅ Proxy Zappr ha fatto redirect a: ${finalUrl.length > 200 ? finalUrl.substring(0, 200) + "..." : finalUrl}');
              final resolverDuration = DateTime.now().difference(resolverStart);
              print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
              print('═══════════════════════════════════════════════════════════');
              return Uri.parse(finalUrl);
            }
            
            if (proxyResponse.statusCode == 200 && proxyResponse.data != null) {
              // Prova prima come JSON
              if (proxyResponse.data is Map) {
                final jsonData = proxyResponse.data as Map;
                // ignore: avoid_print
                print('StreamResolver: [TURNER] ✅ Proxy Zappr restituisce JSON!');
                
                // Cerca l'URL dello stream nel JSON (stessa logica di prima)
                String? streamUrl;
                streamUrl = jsonData['streamUrl'] as String? ??
                           jsonData['url'] as String? ??
                           jsonData['hlsUrl'] as String? ??
                           jsonData['m3u8'] as String? ??
                           jsonData['playlistUrl'] as String?;
                
                if (streamUrl == null && jsonData.containsKey('data')) {
                  final data = jsonData['data'];
                  if (data is Map) {
                    streamUrl = data['streamUrl'] as String? ??
                               data['url'] as String? ??
                               data['hlsUrl'] as String? ??
                               data['m3u8'] as String?;
                  }
                }
                
                if (streamUrl == null && jsonData.containsKey('config')) {
                  final config = jsonData['config'];
                  if (config is Map) {
                    streamUrl = config['streamUrl'] as String? ??
                               config['url'] as String? ??
                               config['hlsUrl'] as String?;
                  }
                }
                
                if (streamUrl != null && streamUrl.isNotEmpty) {
                  // ignore: avoid_print
                  print('StreamResolver: [TURNER] ✅ URL stream trovato tramite proxy: ${streamUrl.length > 200 ? streamUrl.substring(0, 200) + "..." : streamUrl}');
                  final resolverDuration = DateTime.now().difference(resolverStart);
                  print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
                  print('═══════════════════════════════════════════════════════════');
                  return Uri.parse(streamUrl);
                }
              } else if (proxyResponse.data is String) {
                // Se è una stringa, potrebbe essere un URL HLS diretto o un messaggio di errore
                final dataString = proxyResponse.data as String;
                // ignore: avoid_print
                print('StreamResolver: [TURNER] Proxy restituisce String: ${dataString.length > 200 ? dataString.substring(0, 200) + "..." : dataString}');
                
                // Se contiene .m3u8 o http:// o https://, potrebbe essere un URL
                if (dataString.contains('.m3u8') || dataString.startsWith('http://') || dataString.startsWith('https://')) {
                  // ignore: avoid_print
                  print('StreamResolver: [TURNER] ✅ Stringa contiene URL stream, uso come URL diretto');
                  final resolverDuration = DateTime.now().difference(resolverStart);
                  print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
                  print('═══════════════════════════════════════════════════════════');
                  return Uri.parse(dataString.trim());
                }
              }
            }
          } catch (proxyError) {
            // ignore: avoid_print
            print('StreamResolver: [TURNER] ❌ Anche il proxy Zappr fallito: $proxyError');
          }
          
          // Se anche il proxy fallisce, usa l'URL originale (potrebbe funzionare su web)
          // ignore: avoid_print
          print('StreamResolver: [TURNER] ⚠️ Fallback finale: uso URL originale (potrebbe funzionare su web)');
          return Uri.parse(url);
        } else {
          // ignore: avoid_print
          print('StreamResolver: [TURNER] ❌ Errore API: status ${response.statusCode}');
          // Prova comunque con il proxy Zappr come fallback
          // ignore: avoid_print
          print('StreamResolver: [TURNER] 🔄 Provo comunque con proxy Zappr come fallback...');
          try {
            final proxyUrl = '${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}';
            final proxyResponse = await _dio.get(
              proxyUrl,
              options: Options(
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Referer': 'https://zappr.stream/',
                  'Origin': 'https://zappr.stream',
                },
                validateStatus: (status) => status! < 500,
                followRedirects: true,
                maxRedirects: 10,
              ),
            );
            
            if (proxyResponse.redirects.isNotEmpty) {
              final finalUrl = proxyResponse.redirects.last.location.toString();
              // ignore: avoid_print
              print('StreamResolver: [TURNER] ✅ Proxy Zappr fallback ha fatto redirect a: ${finalUrl.length > 200 ? finalUrl.substring(0, 200) + "..." : finalUrl}');
              final resolverDuration = DateTime.now().difference(resolverStart);
              print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
              print('═══════════════════════════════════════════════════════════');
              return Uri.parse(finalUrl);
            }
          } catch (proxyError) {
            // ignore: avoid_print
            print('StreamResolver: [TURNER] ❌ Anche il proxy fallback fallito: $proxyError');
          }
          
          // Fallback finale: usa l'URL originale
          // ignore: avoid_print
          print('StreamResolver: [TURNER] ⚠️ Fallback finale: uso URL originale');
          return Uri.parse(url);
        }
      } catch (e, stackTrace) {
        // ignore: avoid_print
        print('StreamResolver: [TURNER] ❌ Errore nella risoluzione: $e');
        print('StreamResolver: [TURNER] Stack trace: $stackTrace');
        // Fallback: prova a usare l'URL originale (potrebbe funzionare su web)
        // ignore: avoid_print
        print('StreamResolver: [TURNER] Fallback: uso URL originale');
        return Uri.parse(url);
      }
    } else {
      // Già riproducibile direttamente (es. HLS diretto, URL MP4, URL da m3u8-xtream-playlist)
      // NOTA: Gli URL da m3u8-xtream-playlist (es. zplaypro.lat) NON sono URL Zappr
      // e non devono essere risolti tramite API Zappr - vanno usati direttamente
      return Uri.parse(url);
    }

    // L'API Zappr restituisce un redirect 302 allo stream finale
    // Video.js gestisce i redirect automaticamente, ma media_kit potrebbe non farlo
    // Quindi seguiamo i redirect manualmente per ottenere l'URL finale HLS
    try {
      // ignore: avoid_print
      print('StreamResolver: [API_REQUEST] Risolvo URL API Zappr: $apiUrl');
      final apiRequestStart = DateTime.now();
      
      // Usa GET con followRedirects per seguire i redirect
      // Timeout breve per non scaricare tutto lo stream
      final response = await _dio.get(
        apiUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      
      final apiRequestDuration = DateTime.now().difference(apiRequestStart);
      // ignore: avoid_print
      print('StreamResolver: [API_RESPONSE] Richiesta completata in ${apiRequestDuration.inMilliseconds}ms');
      print('StreamResolver: [API_RESPONSE] Status: ${response.statusCode}');
      print('StreamResolver: [API_RESPONSE] Redirect: ${response.redirects.length}');
      print('StreamResolver: [API_RESPONSE] Real URI: ${response.realUri}');
      
      // Ottieni l'URL finale dal redirect
      String finalUrl = apiUrl; // Default all'URL API
      
      if (response.redirects.isNotEmpty) {
        // Usa l'ultimo redirect (URL finale)
        final lastRedirect = response.redirects.last;
        finalUrl = lastRedirect.location.toString();
        // ignore: avoid_print
        print('StreamResolver: [REDIRECT] Redirect trovato: ${lastRedirect.statusCode} -> $finalUrl');
        print('StreamResolver: [REDIRECT] URL finale length: ${finalUrl.length} caratteri');
      } else {
        // Se non ci sono redirect, usa l'URL della risposta finale
        finalUrl = response.realUri.toString();
        // ignore: avoid_print
        print('StreamResolver: [NO_REDIRECT] Nessun redirect, URL finale: $finalUrl');
      }
      
      // Verifica se è un URL di errore
      final hasError = finalUrl.contains('video_no_available') || 
          finalUrl.contains('error') ||
          finalUrl.contains('unavailable');
      
      // ignore: avoid_print
      print('StreamResolver: [VALIDATION] Verifica URL finale per errori...');
      print('StreamResolver: [VALIDATION] Contiene "video_no_available": ${finalUrl.contains('video_no_available')}');
      print('StreamResolver: [VALIDATION] Contiene "error": ${finalUrl.contains('error')}');
      print('StreamResolver: [VALIDATION] Contiene "unavailable": ${finalUrl.contains('unavailable')}');
      print('StreamResolver: [VALIDATION] URL ha errori: $hasError');
      
      if (hasError) {
        // ignore: avoid_print
        print('StreamResolver: [ERROR] API restituisce URL di errore: $finalUrl');
        print('StreamResolver: [ERROR] L\'URL del canale potrebbe essere scaduto o non valido');
        print('StreamResolver: [ERROR] Prova a verificare l\'URL sul sito zappr.stream');
        throw Exception('Stream non disponibile: L\'API restituisce un video di errore. L\'URL del canale potrebbe essere scaduto.');
      }
      
      // ignore: avoid_print
      print('StreamResolver: [SUCCESS] URL finale HLS valido: $finalUrl');
      final resolverDuration = DateTime.now().difference(resolverStart);
      print('StreamResolver: [RESOLVE_END] Completato in ${resolverDuration.inMilliseconds}ms');
      print('═══════════════════════════════════════════════════════════');
      return Uri.parse(finalUrl);
    } catch (e, stackTrace) {
      final resolverDuration = DateTime.now().difference(resolverStart);
      // ignore: avoid_print
      print('StreamResolver: [EXCEPTION] Errore dopo ${resolverDuration.inMilliseconds}ms');
      print('StreamResolver: [EXCEPTION] Tipo: ${e.runtimeType}');
      print('StreamResolver: [EXCEPTION] Messaggio: $e');
      print('StreamResolver: [EXCEPTION] Stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════════════════');
      // Se fallisce, lancia eccezione per permettere fallback all'URL originale
      rethrow;
    }
  }
}

