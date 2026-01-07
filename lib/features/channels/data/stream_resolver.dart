import 'package:dio/dio.dart';
import 'dart:io' show HttpClient, HttpClientRequest, HttpClientResponse;
import 'dart:convert';
import '../../../config/env.dart';
import '../../../core/http/dio_client.dart';

class StreamResolver {
  final Dio _dio = dioProvider;
  
  // Cache per autenticazione Rai (come fa Zappr)
  String? _cachedRaiAuth;
  int? _cachedRaiAuthExpiration;

  /// Risolve l'URL originale in un URL riproducibile
  /// Se necessario, chiama le API Zappr per ottenere l'URL finale
  Uri resolvePlayableUrl(String originalUrl) {
    final url = originalUrl.trim();

    final isDailymotion = url.contains('dailymotion.com/video/');
    final isLivestream = url.contains('livestream.com/accounts/');
    final isNetplus = url.contains('viamotionhsi.netplus.ch/live/eds/');

    final isRaiMediapolis = url.contains('mediapolis.rai.it/relinker/relinkerServlet');
    final isBabylonCloud = url.contains('/video/viewlivestreaming');

    // Casi che Zappr risolve con Cloudflare
    // Zappr costruisce: ${backend.host[api]}/api?${url}
    // Env.cloudflareApiBase già include /api
    if (isDailymotion || isLivestream || isNetplus) {
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
    final url = originalUrl.trim();

    final isDailymotion = url.contains('dailymotion.com/video/');
    final isLivestream = url.contains('livestream.com/accounts/');
    final isNetplus = url.contains('viamotionhsi.netplus.ch/live/eds/');

    final isRaiMediapolis = url.contains('mediapolis.rai.it/relinker/relinkerServlet');
    final isBabylonCloud = url.contains('/video/viewlivestreaming');

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
    if (isDailymotion || isLivestream || isNetplus) {
      apiUrl = '${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}';
    } else if (isRaiMediapolis || isBabylonCloud) {
      apiUrl = '${Env.vercelApiBase}?${Uri.encodeComponent(url)}';
    } else {
      // Già riproducibile direttamente (es. HLS diretto)
      return Uri.parse(url);
    }

    // L'API Zappr restituisce un redirect 302 allo stream finale
    // Video.js gestisce i redirect automaticamente, ma media_kit potrebbe non farlo
    // Quindi seguiamo i redirect manualmente per ottenere l'URL finale HLS
    try {
      // ignore: avoid_print
      print('StreamResolver: Risolvo URL API Zappr: $apiUrl');
      
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
      
      // Ottieni l'URL finale dal redirect
      String finalUrl = apiUrl; // Default all'URL API
      
      if (response.redirects.isNotEmpty) {
        // Usa l'ultimo redirect (URL finale)
        final lastRedirect = response.redirects.last;
        finalUrl = lastRedirect.location.toString();
        // ignore: avoid_print
        print('StreamResolver: Redirect trovato: ${lastRedirect.statusCode} -> $finalUrl');
      } else {
        // Se non ci sono redirect, usa l'URL della risposta finale
        finalUrl = response.realUri.toString();
        // ignore: avoid_print
        print('StreamResolver: Nessun redirect, URL finale: $finalUrl');
      }
      
      // Verifica se è un URL di errore
      if (finalUrl.contains('video_no_available') || 
          finalUrl.contains('error') ||
          finalUrl.contains('unavailable')) {
        // ignore: avoid_print
        print('StreamResolver: API restituisce URL di errore: $finalUrl');
        print('StreamResolver: L\'URL del canale potrebbe essere scaduto o non valido');
        print('StreamResolver: Prova a verificare l\'URL sul sito zappr.stream');
        throw Exception('Stream non disponibile: L\'API restituisce un video di errore. L\'URL del canale potrebbe essere scaduto.');
      }
      
      // ignore: avoid_print
      print('StreamResolver: URL finale HLS: $finalUrl');
      return Uri.parse(finalUrl);
    } catch (e) {
      // Se fallisce, lancia eccezione per permettere fallback all'URL originale
      // ignore: avoid_print
      print('StreamResolver: Errore nel risolvere URL: $e');
      rethrow;
    }
  }
}

