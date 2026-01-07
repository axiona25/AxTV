import 'package:dio/dio.dart';
import '../../../config/env.dart';
import '../../../core/http/dio_client.dart';

class StreamResolver {
  final Dio _dio = dioProvider;

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
    try {
      // ignore: avoid_print
      print('StreamResolver: Richiedo autenticazione Rai Akamai...');
      final response = await _dio.post(
        '${Env.alwaysdataApiBase}/rai-akamai',
        options: Options(
          validateStatus: (status) => status! < 500,
          responseType: ResponseType.plain, // Restituisce testo, non JSON
        ),
      );
      
      // L'API restituisce direttamente la stringa di autenticazione (es. "?hdnea=...")
      // response.data potrebbe essere una String o un ResponseBody
      String auth;
      if (response.data is String) {
        auth = (response.data as String).trim();
      } else {
        auth = response.data.toString().trim();
      }
      
      // Verifica che l'auth non sia vuota
      if (auth.isEmpty) {
        throw Exception('Autenticazione Rai vuota ricevuta dall\'API');
      }
      
      // Assicurati che inizi con "?" se non c'è già
      if (!auth.startsWith('?')) {
        auth = '?$auth';
      }
      
      // ignore: avoid_print
      print('StreamResolver: Autenticazione ottenuta (lunghezza: ${auth.length}): ${auth.substring(0, auth.length > 60 ? 60 : auth.length)}...');
      return auth;
    } catch (e) {
      // ignore: avoid_print
      print('StreamResolver: Errore nell\'ottenere autenticazione Rai: $e');
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

    // Se è un canale Rai con license rai-akamai, ottieni l'autenticazione e aggiungila all'URL
    if (license == 'rai-akamai') {
      try {
        final auth = await _getRaiAkamaiAuth();
        // L'auth restituisce già "?hdnea=..." quindi aggiungilo direttamente
        final urlWithAuth = '$url$auth';
        // ignore: avoid_print
        print('StreamResolver: URL Rai originale: $url');
        print('StreamResolver: Auth ottenuta: ${auth.substring(0, auth.length > 50 ? 50 : auth.length)}...');
        print('StreamResolver: URL Rai completo: ${urlWithAuth.substring(0, urlWithAuth.length > 150 ? 150 : urlWithAuth.length)}...');
        return Uri.parse(urlWithAuth);
      } catch (e) {
        // Se l'autenticazione fallisce, prova comunque con l'URL originale
        // ignore: avoid_print
        print('StreamResolver: Fallback a URL senza autenticazione: $e');
        // Ma l'URL senza auth non funzionerà, quindi lancia eccezione
        throw Exception('Impossibile ottenere autenticazione Rai: $e');
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

