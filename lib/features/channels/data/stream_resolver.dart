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

    // L'API Zappr funziona come proxy: restituisce redirect 302 allo stream finale HLS
    // Video.js sul web passa l'URL dell'API direttamente con tipo "application/x-mpegURL"
    // e gestisce i redirect automaticamente
    // 
    // Per media_kit, proviamo a seguire il redirect manualmente per ottenere l'URL finale
    // Se fallisce, restituiamo l'URL dell'API e lasciamo che media_kit provi
    try {
      // ignore: avoid_print
      print('StreamResolver: Risolvo URL API Zappr: $apiUrl');
      
      // Fai una richiesta HEAD per seguire i redirect senza scaricare tutto
      final response = await _dio.head(
        apiUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      // Ottieni l'URL finale
      String finalUrl;
      if (response.redirects.isNotEmpty) {
        finalUrl = response.redirects.last.location.toString();
      } else {
        finalUrl = response.realUri.toString();
      }
      
      // Verifica se è un URL di errore
      if (finalUrl.contains('video_no_available') || 
          finalUrl.contains('error') ||
          finalUrl.contains('unavailable')) {
        // ignore: avoid_print
        print('StreamResolver: API restituisce URL di errore, uso URL API direttamente');
        return Uri.parse(apiUrl);
      }
      
      // ignore: avoid_print
      print('StreamResolver: URL finale dopo redirect: $finalUrl');
      return Uri.parse(finalUrl);
    } catch (e) {
      // Se fallisce, usa l'URL dell'API direttamente
      // media_kit potrebbe gestirlo
      // ignore: avoid_print
      print('StreamResolver: Errore nel seguire redirect, uso URL API: $e');
      return Uri.parse(apiUrl);
    }
  }
}

