import 'package:dio/dio.dart';
import '../../../config/env.dart';
import '../../../core/http/dio_client.dart';

/// Risolutore dedicato per URL con schema zappr://
/// 
/// Questo componente gestisce la risoluzione degli URL personalizzati Zappr
/// seguendo il comportamento dell'applicazione web Zappr.
class ZapprProtocolResolver {
  final Dio _dio = dioProvider;
  
  /// Risolve un URL zappr:// in un URL riproducibile
  /// 
  /// Prova prima a seguire i redirect per ottenere l'URL finale dello stream.
  /// Se fallisce, passa l'URL API direttamente al player.
  Future<Uri> resolve(String zapprUrl) async {
    final startTime = DateTime.now();
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════════');
    print('ZapprProtocolResolver: [START] Risolvo URL: $zapprUrl');
    print('ZapprProtocolResolver: Timestamp: ${startTime.toIso8601String()}');
    
    // Estrai provider e path
    final uri = Uri.parse(zapprUrl);
    final provider = uri.host;
    final path = uri.path;
    
    // ignore: avoid_print
    print('ZapprProtocolResolver: [PARSING] Provider="$provider", Path="$path"');
    print('ZapprProtocolResolver: [PARSING] Schema="${uri.scheme}", Host="${uri.host}", Path="${uri.path}"');
    
    final apiUrl = '${Env.cloudflareApiBase}?${Uri.encodeComponent(zapprUrl)}';
    
    // ignore: avoid_print
    print('ZapprProtocolResolver: [API_URL] Costruito: $apiUrl');
    print('ZapprProtocolResolver: [API_URL] Lunghezza: ${apiUrl.length} caratteri');
    
    // Prova a seguire i redirect per ottenere l'URL finale dello stream
    try {
      // ignore: avoid_print
      print('ZapprProtocolResolver: [HTTP_REQUEST] Inizio richiesta GET a Cloudflare API...');
      final requestStart = DateTime.now();
      
      final response = await _dio.get(
        apiUrl,
        options: Options(
          followRedirects: true,
          maxRedirects: 10,
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://zappr.stream/',
            'Accept': 'application/vnd.apple.mpegurl, application/x-mpegURL, */*',
          },
        ),
      );
      
      final requestDuration = DateTime.now().difference(requestStart);
      // ignore: avoid_print
      print('ZapprProtocolResolver: [HTTP_RESPONSE] Richiesta completata in ${requestDuration.inMilliseconds}ms');
      print('ZapprProtocolResolver: [HTTP_RESPONSE] Status Code: ${response.statusCode}');
      print('ZapprProtocolResolver: [HTTP_RESPONSE] Real URI: ${response.realUri}');
      print('ZapprProtocolResolver: [HTTP_RESPONSE] Numero redirect: ${response.redirects.length}');
      
      // Log di tutti i redirect
      if (response.redirects.isNotEmpty) {
        // ignore: avoid_print
        print('ZapprProtocolResolver: [REDIRECTS] Trovati ${response.redirects.length} redirect:');
        for (var i = 0; i < response.redirects.length; i++) {
          final redirect = response.redirects[i];
          print('ZapprProtocolResolver: [REDIRECT_$i] ${redirect.statusCode} -> ${redirect.location}');
        }
      }
      
      // Log degli header della risposta
      // ignore: avoid_print
      print('ZapprProtocolResolver: [HEADERS] Response headers:');
      response.headers.forEach((key, values) {
        print('ZapprProtocolResolver: [HEADER] $key: ${values.join(", ")}');
      });
      
      // Se ci sono redirect, usa l'URL finale
      if (response.redirects.isNotEmpty) {
        final finalUrl = response.redirects.last.location.toString();
        // ignore: avoid_print
        print('ZapprProtocolResolver: [REDIRECT_FINAL] URL finale dal redirect: $finalUrl');
        print('ZapprProtocolResolver: [REDIRECT_FINAL] Lunghezza: ${finalUrl.length} caratteri');
        
        // Verifica che non sia un URL di errore
        final hasError = finalUrl.contains('error') || 
            finalUrl.contains('video_no_available') ||
            finalUrl.contains('404') ||
            finalUrl.contains('unavailable');
        
        // ignore: avoid_print
        print('ZapprProtocolResolver: [VALIDATION] Controllo URL finale per errori...');
        print('ZapprProtocolResolver: [VALIDATION] Contiene "error": ${finalUrl.contains('error')}');
        print('ZapprProtocolResolver: [VALIDATION] Contiene "video_no_available": ${finalUrl.contains('video_no_available')}');
        print('ZapprProtocolResolver: [VALIDATION] Contiene "404": ${finalUrl.contains('404')}');
        print('ZapprProtocolResolver: [VALIDATION] Contiene "unavailable": ${finalUrl.contains('unavailable')}');
        print('ZapprProtocolResolver: [VALIDATION] URL valido: ${!hasError}');
        
        if (!hasError) {
          // ignore: avoid_print
          print('ZapprProtocolResolver: [SUCCESS] URL finale valido, restituisco: $finalUrl');
          print('ZapprProtocolResolver: [END] Completato in ${DateTime.now().difference(startTime).inMilliseconds}ms');
          print('═══════════════════════════════════════════════════════════');
          return Uri.parse(finalUrl);
        } else {
          // ignore: avoid_print
          print('ZapprProtocolResolver: [ERROR] Redirect a pagina di errore, continuo con fallback');
        }
      }
      
      // Se restituisce 200, verifica il content-type e il contenuto
      if (response.statusCode == 200) {
        final contentType = response.headers.value('content-type') ?? '';
        // ignore: avoid_print
        print('ZapprProtocolResolver: [CONTENT] Status 200, analizzo contenuto...');
        print('ZapprProtocolResolver: [CONTENT] Content-Type: "$contentType"');
        print('ZapprProtocolResolver: [CONTENT] Data type: ${response.data.runtimeType}');
        print('ZapprProtocolResolver: [CONTENT] Data is null: ${response.data == null}');
        
        // Verifica se la risposta contiene un errore
        if (response.data != null) {
          final responseText = response.data.toString();
          final responseLength = responseText.length;
          // ignore: avoid_print
          print('ZapprProtocolResolver: [CONTENT] Lunghezza risposta: $responseLength caratteri');
          
          // Mostra i primi 200 caratteri della risposta per debug
          final preview = responseLength > 200 ? '${responseText.substring(0, 200)}...' : responseText;
          // ignore: avoid_print
          print('ZapprProtocolResolver: [CONTENT] Preview: $preview');
          
          final hasErrorInContent = responseText.contains('error') || 
              responseText.contains('not found') ||
              responseText.contains('unavailable');
          
          // ignore: avoid_print
          print('ZapprProtocolResolver: [CONTENT] Contiene "error": ${responseText.contains('error')}');
          print('ZapprProtocolResolver: [CONTENT] Contiene "not found": ${responseText.contains('not found')}');
          print('ZapprProtocolResolver: [CONTENT] Contiene "unavailable": ${responseText.contains('unavailable')}');
          print('ZapprProtocolResolver: [CONTENT] Ha errori nel contenuto: $hasErrorInContent');
          
          if (hasErrorInContent) {
            // ignore: avoid_print
            print('ZapprProtocolResolver: [ERROR] API restituisce errore nel contenuto');
            throw Exception('API Zappr restituisce errore: URL zappr:// non supportato o canale non disponibile');
          }
        }
        
        // Verifica se è uno stream valido
        final isValidStream = contentType.contains('application/vnd.apple.mpegurl') ||
            contentType.contains('video/') ||
            contentType.contains('application/x-mpegURL') ||
            contentType.contains('text/plain');
        
        // ignore: avoid_print
        print('ZapprProtocolResolver: [CONTENT] È stream valido: $isValidStream');
        print('ZapprProtocolResolver: [CONTENT] Contiene "mpegurl": ${contentType.contains('mpegurl')}');
        print('ZapprProtocolResolver: [CONTENT] Contiene "video/": ${contentType.contains('video/')}');
        print('ZapprProtocolResolver: [CONTENT] Contiene "x-mpegURL": ${contentType.contains('x-mpegURL')}');
        print('ZapprProtocolResolver: [CONTENT] Contiene "text/plain": ${contentType.contains('text/plain')}');
        
        if (isValidStream) {
          final finalUrl = response.realUri.toString();
          // ignore: avoid_print
          print('ZapprProtocolResolver: [SUCCESS] Stream valido trovato: $finalUrl');
          print('ZapprProtocolResolver: [END] Completato in ${DateTime.now().difference(startTime).inMilliseconds}ms');
          print('═══════════════════════════════════════════════════════════');
          return Uri.parse(finalUrl);
        } else {
          // ignore: avoid_print
          print('ZapprProtocolResolver: [WARNING] Content-Type non riconosciuto come stream valido');
        }
      }
      
      // Se restituisce un errore HTTP
      if (response.statusCode != null && response.statusCode! >= 400) {
        // ignore: avoid_print
        print('ZapprProtocolResolver: [ERROR] API restituisce errore HTTP ${response.statusCode}');
        print('ZapprProtocolResolver: [ERROR] Response data: ${response.data}');
        
        // Analizza il contenuto dell'errore per capire meglio il problema
        String errorMessage = 'API Zappr restituisce errore ${response.statusCode}';
        if (response.data != null) {
          try {
            final errorData = response.data;
            if (errorData is Map) {
              final apiError = errorData['error']?.toString() ?? '';
              final apiInfo = errorData['info']?.toString() ?? '';
              // ignore: avoid_print
              print('ZapprProtocolResolver: [ERROR] Messaggio API: $apiError');
              print('ZapprProtocolResolver: [ERROR] Info API: $apiInfo');
              
              // Se l'API dice esplicitamente che l'URL non è supportato
              if (apiError.contains('non è supportato') || 
                  apiError.contains('non è valido') ||
                  apiError.contains('formato corretto') ||
                  apiError.contains('non è nel formato')) {
                // ignore: avoid_print
                print('ZapprProtocolResolver: [ERROR] API conferma che URL zappr:// non è supportato');
                errorMessage = 'Gli URL con schema zappr:// non sono supportati dalle API pubbliche di Zappr.\n\n'
                    'Messaggio API: $apiError\n\n'
                    'Questi URL funzionano solo nell\'applicazione web Zappr (zappr.stream) perché richiedono:\n'
                    '- Autenticazione/cookie di sessione del browser\n'
                    '- Accesso a risorse interne non esposte via API pubblica\n\n'
                    'Soluzione:\n'
                    '1. Verifica sul sito zappr.stream se il canale è ancora disponibile\n'
                    '2. Se disponibile, cerca un URL diretto (es. .m3u8) nel codice sorgente della pagina\n'
                    '3. Aggiorna il file channels.json con l\'URL diretto invece di zappr://\n\n'
                    'Documentazione API: https://github.com/ZapprTV/cloudflare-api#readme';
              }
            }
          } catch (e) {
            // ignore: avoid_print
            print('ZapprProtocolResolver: [ERROR] Impossibile analizzare errore: $e');
          }
        }
        
        throw Exception(errorMessage);
      }
      
      // ignore: avoid_print
      print('ZapprProtocolResolver: [WARNING] Nessuna condizione soddisfatta, status=${response.statusCode}');
    } catch (e, stackTrace) {
      final errorDuration = DateTime.now().difference(startTime);
      // ignore: avoid_print
      print('ZapprProtocolResolver: [EXCEPTION] Errore dopo ${errorDuration.inMilliseconds}ms');
      print('ZapprProtocolResolver: [EXCEPTION] Tipo: ${e.runtimeType}');
      print('ZapprProtocolResolver: [EXCEPTION] Messaggio: $e');
      print('ZapprProtocolResolver: [EXCEPTION] Stack trace:');
      print(stackTrace);
      
      // Se è un'eccezione che abbiamo lanciato noi, rilanciarla
      // Non provare fallback se l'API ha esplicitamente rifiutato l'URL
      if (e.toString().contains('API Zappr restituisce errore') ||
          e.toString().contains('non sono supportati dalle API pubbliche') ||
          e.toString().contains('non è supportato') ||
          e.toString().contains('non è valido')) {
        // ignore: avoid_print
        print('ZapprProtocolResolver: [EXCEPTION] Errore previsto, rilancio senza fallback');
        rethrow;
      }
      
      // Altrimenti, prova con la strategia di fallback
      // ignore: avoid_print
      print('ZapprProtocolResolver: [FALLBACK] Errore inatteso, provo strategia di fallback');
      return await resolveWithFallback(zapprUrl);
    }
    
    // Se arriviamo qui, non abbiamo trovato uno stream valido
    // Prova con la strategia di fallback
    // ignore: avoid_print
    print('ZapprProtocolResolver: [FALLBACK] Nessuno stream valido trovato, provo fallback');
    return await resolveWithFallback(zapprUrl);
  }
  
  /// Risolve un URL zappr:// con strategia alternativa
  /// Prova diverse API e endpoint
  Future<Uri> resolveWithFallback(String zapprUrl) async {
    final fallbackStart = DateTime.now();
    // ignore: avoid_print
    print('ZapprProtocolResolver: [FALLBACK_START] Risolvo con fallback: $zapprUrl');
    
    final uri = Uri.parse(zapprUrl);
    final provider = uri.host;
    final path = uri.path;
    
    // ignore: avoid_print
    print('ZapprProtocolResolver: [FALLBACK] Provider="$provider", Path="$path"');
    
    // Lista di API da provare
    final apis = [
      Env.cloudflareApiBase,
      Env.vercelApiBase,
    ];
    
    // ignore: avoid_print
    print('ZapprProtocolResolver: [FALLBACK] Provo ${apis.length} API diverse');
    
    for (var i = 0; i < apis.length; i++) {
      final apiBase = apis[i];
      // ignore: avoid_print
      print('ZapprProtocolResolver: [FALLBACK_$i] Provo API: $apiBase');
      
      try {
        final apiUrl = '$apiBase?${Uri.encodeComponent(zapprUrl)}';
        // ignore: avoid_print
        print('ZapprProtocolResolver: [FALLBACK_$i] URL completo: $apiUrl');
        
        final requestStart = DateTime.now();
        final response = await _dio.get(
          apiUrl,
          options: Options(
            followRedirects: true,
            maxRedirects: 10,
            validateStatus: (status) => status! < 500,
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://zappr.stream/',
              'Accept': 'application/vnd.apple.mpegurl, application/x-mpegURL, */*',
            },
          ),
        );
        
        final requestDuration = DateTime.now().difference(requestStart);
        // ignore: avoid_print
        print('ZapprProtocolResolver: [FALLBACK_$i] Risposta ricevuta in ${requestDuration.inMilliseconds}ms');
        print('ZapprProtocolResolver: [FALLBACK_$i] Status: ${response.statusCode}');
        print('ZapprProtocolResolver: [FALLBACK_$i] Redirect: ${response.redirects.length}');
        
        if (response.redirects.isNotEmpty) {
          final finalUrl = response.redirects.last.location.toString();
          // ignore: avoid_print
          print('ZapprProtocolResolver: [FALLBACK_$i] URL finale: $finalUrl');
          
          final hasError = finalUrl.contains('error') || 
              finalUrl.contains('video_no_available') ||
              finalUrl.contains('404');
          
          // ignore: avoid_print
          print('ZapprProtocolResolver: [FALLBACK_$i] URL ha errori: $hasError');
          
          if (!hasError) {
            // ignore: avoid_print
            print('ZapprProtocolResolver: [FALLBACK_$i] SUCCESS - URL valido trovato');
            print('ZapprProtocolResolver: [FALLBACK_END] Completato in ${DateTime.now().difference(fallbackStart).inMilliseconds}ms');
            return Uri.parse(finalUrl);
          }
        } else if (response.statusCode == 200) {
          final contentType = response.headers.value('content-type') ?? '';
          // ignore: avoid_print
          print('ZapprProtocolResolver: [FALLBACK_$i] Content-Type: "$contentType"');
          
          final isValid = contentType.contains('mpegurl') || 
              contentType.contains('video/') ||
              contentType.contains('x-mpegURL');
          
          // ignore: avoid_print
          print('ZapprProtocolResolver: [FALLBACK_$i] È stream valido: $isValid');
          
          if (isValid) {
            final finalUrl = response.realUri.toString();
            // ignore: avoid_print
            print('ZapprProtocolResolver: [FALLBACK_$i] SUCCESS - Stream diretto: $finalUrl');
            print('ZapprProtocolResolver: [FALLBACK_END] Completato in ${DateTime.now().difference(fallbackStart).inMilliseconds}ms');
            return Uri.parse(finalUrl);
          }
        }
        
        // Se l'API restituisce 400, non continuare con altre API
        // perché sappiamo che tutte rifiuteranno lo stesso URL
        if (response.statusCode == 400) {
          // ignore: avoid_print
          print('ZapprProtocolResolver: [FALLBACK_$i] API restituisce 400, interrompo fallback');
          throw Exception('Tutte le API pubbliche di Zappr rifiutano l\'URL zappr://.\n\n'
              'Gli URL con schema zappr:// non sono supportati dalle API pubbliche.\n\n'
              'Soluzione: Verifica sul sito zappr.stream se il canale ha un URL diretto (es. .m3u8) da usare invece di zappr://.');
        }
        
        // ignore: avoid_print
        print('ZapprProtocolResolver: [FALLBACK_$i] API non ha restituito stream valido');
      } catch (e, stackTrace) {
        // Se è un'eccezione che abbiamo lanciato noi (400), rilanciarla
        if (e.toString().contains('Tutte le API pubbliche')) {
          // ignore: avoid_print
          print('ZapprProtocolResolver: [FALLBACK_$i] Errore previsto, rilancio');
          rethrow;
        }
        // ignore: avoid_print
        print('ZapprProtocolResolver: [FALLBACK_$i] EXCEPTION: $e');
        print('ZapprProtocolResolver: [FALLBACK_$i] Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
        continue;
      }
    }
    
    // Se tutte le API falliscono, NON restituire l'URL API perché sappiamo che non funziona
    // Lancia un'eccezione invece di passare un URL che sicuramente fallirà
    // ignore: avoid_print
    print('ZapprProtocolResolver: [FALLBACK_FINAL] Tutte le API fallite');
    print('ZapprProtocolResolver: [FALLBACK_FINAL] Non restituisco URL API perché sappiamo che non funziona');
    print('ZapprProtocolResolver: [FALLBACK_END] Completato in ${DateTime.now().difference(fallbackStart).inMilliseconds}ms');
    print('═══════════════════════════════════════════════════════════');
    throw Exception('Impossibile risolvere URL zappr://: tutte le API pubbliche di Zappr hanno restituito errore.\n\n'
        'Gli URL con schema zappr:// non sono supportati dalle API pubbliche.\n\n'
        'Soluzione: Verifica sul sito zappr.stream se il canale ha un URL diretto (es. .m3u8) da usare invece di zappr://.');
  }
}
