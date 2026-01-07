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

  /// Risolve l'URL seguendo i redirect delle API Zappr
  /// Restituisce l'URL finale riproducibile
  Future<Uri> resolvePlayableUrlAsync(String originalUrl) async {
    final url = originalUrl.trim();

    final isDailymotion = url.contains('dailymotion.com/video/');
    final isLivestream = url.contains('livestream.com/accounts/');
    final isNetplus = url.contains('viamotionhsi.netplus.ch/live/eds/');

    final isRaiMediapolis = url.contains('mediapolis.rai.it/relinker/relinkerServlet');
    final isBabylonCloud = url.contains('/video/viewlivestreaming');

    String apiUrl;
    
    // Determina quale API usare
    // Zappr costruisce: ${backend.host[api]}/api?${url}
    // Env.cloudflareApiBase e Env.vercelApiBase già includono /api
    if (isDailymotion || isLivestream || isNetplus) {
      apiUrl = '${Env.cloudflareApiBase}?${Uri.encodeComponent(url)}';
    } else if (isRaiMediapolis || isBabylonCloud) {
      apiUrl = '${Env.vercelApiBase}?${Uri.encodeComponent(url)}';
    } else {
      // Già riproducibile direttamente
      return Uri.parse(url);
    }

    // L'API Zappr restituisce un redirect 302 allo stream finale
    // Dobbiamo seguire il redirect per ottenere l'URL finale
    try {
      // ignore: avoid_print
      print('StreamResolver: Risolvo URL API Zappr: $apiUrl');
      
      // Segui il redirect per ottenere l'URL finale
      // Usa maxRedirects per limitare i redirect infiniti
      final response = await _dio.get(
        apiUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status! < 500, // Accetta anche 4xx per vedere l'errore
        ),
      );
      
      // Ottieni l'URL finale dal redirect o dalla risposta
      String finalUrl;
      if (response.redirects.isNotEmpty) {
        // Se ci sono redirect, usa l'URL finale del redirect
        finalUrl = response.redirects.last.location.toString();
      } else {
        // Altrimenti usa l'URL della risposta
        finalUrl = response.realUri.toString();
      }
      
      // Verifica se l'URL finale è un video di errore
      if (finalUrl.contains('video_no_available') || 
          finalUrl.contains('error') ||
          finalUrl.contains('unavailable')) {
        // ignore: avoid_print
        print('StreamResolver: L\'API ha restituito un URL di errore: $finalUrl');
        // Lancia un'eccezione per permettere il fallback
        throw Exception('Stream non disponibile dall\'API Zappr');
      }
      
      // ignore: avoid_print
      print('StreamResolver: URL finale dopo redirect: $finalUrl');
      
      return Uri.parse(finalUrl);
    } catch (e) {
      // Se il redirect fallisce o restituisce un errore, prova con l'URL originale
      // ignore: avoid_print
      print('StreamResolver: Errore nel seguire redirect: $e');
      // Non restituire l'URL dell'API, ma lancia un'eccezione per permettere il fallback
      rethrow;
    }
  }
}

