import 'package:dio/dio.dart';
import '../security/content_validator.dart';

/// Validatore di URL per verificare se sono accessibili e funzionanti
/// 
/// Questo modulo verifica che gli URL siano:
/// - Accessibili (rispondono a richieste HTTP)
/// - Non problematici (pattern noti)
/// - Formato valido (http/https/m3u8/mpd)
class UrlValidator {
  /// Istanza Dio dedicata per validazioni URL con timeout molto brevi
  /// Separata da dioProvider per avere controllo sui timeout specifici per validazioni
  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 500), // Timeout connessione molto breve
      receiveTimeout: const Duration(milliseconds: 800), // Timeout ricezione breve
      sendTimeout: const Duration(milliseconds: 500), // Timeout invio breve
      maxRedirects: 2, // Ridotto per velocità
      headers: {
        'User-Agent': 'AxTV-Flutter-App',
        'Accept': '*/*',
      },
    ),
  );
  
  /// Timeout molto breve per la validazione (1.5 secondi)
  /// Veloce abbastanza da non bloccare l'UI, ma sufficiente per verificare l'accessibilità base
  /// URL che rispondono lentamente (>1.5s) sono considerati problematici e filtrati
  static const Duration _validationTimeout = Duration(milliseconds: 1500);
  
  /// Valida un URL verificando se è accessibile e funzionante
  /// Restituisce true se l'URL è valido, false altrimenti
  /// 
  /// [url] L'URL da validare
  /// [timeout] Timeout personalizzato (opzionale, default 3 secondi)
  Future<bool> validateUrlAccessibility(
    String url, {
    Duration? timeout,
  }) async {
    try {
      // Prima verifica validità base (pattern problematici)
      if (!ContentValidator.validateChannel(streamUrl: url)) {
        // ignore: avoid_print
        print('UrlValidator: ⚠️ URL non valido (pattern problematico): $url');
        return false;
      }
      
      // Verifica se l'URL è problematico noto
      if (ContentValidator.isProblematicUrl(url)) {
        // ignore: avoid_print
        print('UrlValidator: ⚠️ URL problematico noto: $url');
        return false;
      }
      
      final lowerUrl = url.toLowerCase();
      
      // Per URL M3U8/HLS/DASH (live streaming), fai un HEAD request veloce
      // Questi sono i più problematici e devono essere validati completamente
      if (lowerUrl.contains('.m3u8') || lowerUrl.contains('.mpd')) {
        // Filtro pre-validazione rapido per pattern problematici comuni
        // Evita HTTP request per URL chiaramente problematici
        if (lowerUrl.contains('/udp/') || 
            lowerUrl.contains('/play/') ||
            RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/play/').hasMatch(lowerUrl)) {
          return false; // Pattern problematico, skip HTTP request
        }
        
        try {
          // Usa timeout brevi già configurati in _dio (500ms connect, 800ms receive)
          // URL che rispondono lentamente (>800ms) sono considerati problematici
          final response = await _dio.head(
            url,
            options: Options(
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          
          // Accetta solo status 200-299 e 3xx (redirect)
          final statusCode = response.statusCode ?? 0;
          if (statusCode >= 200 && statusCode < 400) {
            return true; // URL valido e accessibile
          } else {
            return false; // Status non valido
          }
        } catch (e) {
          // Per timeout, connessione rifiutata, 404, ecc., considera l'URL non valido
          // Non loggare ogni errore per non intasare - gli URL problematici vengono filtrati silenziosamente
          return false;
        }
      }
      
      // Per altri URL (archive.org, video MP4, ecc.), verifica solo il formato
      // Non facciamo richieste HTTP per non rallentare troppo
      // Questi URL verranno testati al momento della riproduzione
      if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('rtmp://')) {
        try {
          final uri = Uri.parse(url);
          if (uri.host.isNotEmpty && uri.scheme.isNotEmpty) {
            // Per archive.org, considera sempre valido (sono file statici)
            if (lowerUrl.contains('archive.org')) {
              return true; // Archive.org è sempre valido
            }
            
            // Per altri URL, verifica solo il formato base
            // IP diretti senza formato M3U8 devono passare la validazione ContentValidator
            return true;
          }
        } catch (e) {
          return false; // Formato non valido
        }
      }
      
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('UrlValidator: ❌ Errore nella validazione URL: $e');
      return false;
    }
  }
  
  /// Valida una lista di URL in parallelo
  /// Restituisce solo gli URL validi
  /// 
  /// [urls] Lista di URL da validare
  /// [maxConcurrent] Numero massimo di validazioni simultanee (default: 5)
  Future<List<String>> validateUrlsBatch(
    List<String> urls, {
    int maxConcurrent = 5,
  }) async {
    final validUrls = <String>[];
    
    // Processa in batch per non sovraccaricare
    for (var i = 0; i < urls.length; i += maxConcurrent) {
      final batch = urls.skip(i).take(maxConcurrent).toList();
      
      final results = await Future.wait(
        batch.map((url) => validateUrlAccessibility(url)),
      );
      
      for (var j = 0; j < batch.length; j++) {
        if (results[j]) {
          validUrls.add(batch[j]);
        }
      }
      
      // ignore: avoid_print
      print('UrlValidator: 📊 Validati ${i + batch.length}/${urls.length} URL (validi: ${validUrls.length})');
    }
    
    return validUrls;
  }
}
