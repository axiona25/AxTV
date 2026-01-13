import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:dio/dio.dart';
import '../../channels/model/channel.dart';
import '../../channels/data/stream_resolver.dart';
import '../../../core/http/proxy_resolver.dart' show ProxyResolver, GeoLocation, ProxyMethod;
import '../../../core/http/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../theme/zappr_tokens.dart';
import '../../../widgets/neon_glass.dart';

class PlayerPage extends StatefulWidget {
  final Channel channel;
  const PlayerPage({super.key, required this.channel});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final Player _player;
  late final VideoController _controller;
  final _resolver = StreamResolver();
  final _proxyResolver = ProxyResolver();
  final _dio = dioProvider;
  
  bool _isLoading = true;
  String? _error;
  String? _resolvedUrl;
  bool _hasTriedFallback = false; // Evita loop infiniti
  bool _isRetrying = false; // Evita retry multipli
  int? _lastLoggedPositionSeconds; // Per limitare i log della posizione
  List<GeoLocation>? _alternativeGeoLocations; // Location alternative per retry geoblock
  int _currentGeoLocationIndex = 0; // Indice della location corrente da provare
  int _errorRetryCount = 0; // Contatore retry errori (massimo 5 prima di mostrare errore)
  static const int _maxErrorRetries = 5; // Massimo numero di retry prima di mostrare errore
  bool _isDisposing = false; // Flag per prevenire operazioni durante dispose
  Timer? _loadingTimeoutTimer; // Timer per timeout caricamento
  bool _showTimeoutPlaceholder = false; // Flag per mostrare placeholder timeout
  static const Duration _loadingTimeout = Duration(seconds: 15); // Timeout caricamento (15 secondi)

  @override
  void initState() {
    super.initState();

    _player = Player();
    _controller = VideoController(_player);

    // Ascolta gli eventi del player con protezione contro race conditions
    _player.stream.playing.listen((playing) {
      // Ignora eventi se stiamo disattivando
      if (_isDisposing || !mounted) return;
      
      // ignore: avoid_print
      print('PlayerPage: [EVENT] Playing changed: $playing');
      if (mounted && !_isDisposing) {
        setState(() {
          _isLoading = !playing;
          if (playing) {
            // Video in riproduzione - rimuovi errori e reset contatori
            _error = null;
            _errorRetryCount = 0;
            _showTimeoutPlaceholder = false;
            _stopLoadingTimeout(); // Ferma il timer quando il video parte
          }
        });
        // ignore: avoid_print
        print('PlayerPage: [EVENT] Loading state updated: $_isLoading');
      }
    });

    _player.stream.error.listen((error) {
      // Gestisci errori solo se non stiamo disattivando
      if (!_isDisposing && mounted) {
        _handlePlayerError(error);
      }
    });

    _player.stream.completed.listen((completed) {
      // ignore: avoid_print
      print('PlayerPage: [EVENT] Completed changed: $completed');
      if (mounted && completed) {
        setState(() {
          _isLoading = false;
        });
        // ignore: avoid_print
        print('PlayerPage: [EVENT] Loading state updated dopo completamento: $_isLoading');
      }
    });
    
    // Ascolta anche altri eventi utili per debug
    _player.stream.buffering.listen((buffering) {
      // Log solo quando cambia lo stato di buffering
      // ignore: avoid_print
      print('PlayerPage: [EVENT] Buffering: $buffering');
    });
    
    _player.stream.duration.listen((duration) {
      // Log solo quando la durata cambia (utile per stream live che iniziano senza durata)
      if (duration.inSeconds > 0) {
        // ignore: avoid_print
        print('PlayerPage: [EVENT] Duration: $duration');
      }
    });
    
    _player.stream.position.listen((position) {
      // Log solo ogni 5 secondi per non intasare i log
      final currentSeconds = position.inSeconds;
      if (_lastLoggedPositionSeconds == null || 
          currentSeconds - _lastLoggedPositionSeconds! >= 5) {
        // ignore: avoid_print
        print('PlayerPage: [EVENT] Position: $position');
        _lastLoggedPositionSeconds = currentSeconds;
      }
    });

    // Risolvi e carica l'URL
    _loadVideo();
  }

  /// Gestisce gli errori del player con retry automatico per geoblock
  Future<void> _handlePlayerError(dynamic error) async {
    // Ignora errori se stiamo disattivando o se il widget non è montato
    if (_isDisposing || !mounted) {
      // ignore: avoid_print
      print('PlayerPage: [EVENT_ERROR] Errore ignorato (disposing o non mounted)');
      return;
    }
    
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════════');
    print('PlayerPage: [EVENT_ERROR] Errore del player rilevato!');
    print('PlayerPage: [EVENT_ERROR] Tipo: ${error.runtimeType}');
    print('PlayerPage: [EVENT_ERROR] Messaggio: $error');
    print('PlayerPage: [EVENT_ERROR] Stack: ${StackTrace.current}');
    print('PlayerPage: [EVENT_ERROR] Retry count: $_errorRetryCount/$_maxErrorRetries');
    print('═══════════════════════════════════════════════════════════');
    
    String? errorMessage;
    final errorString = error.toString().toLowerCase();
    
    // Sistema di retry automatico per geoblock
    // Se l'errore è legato a geoblock/server offline e abbiamo location alternative, prova con altre location
    final isGeoblockError = errorString.contains('failed to open') || 
                            errorString.contains('could not open') ||
                            errorString.contains('521') || // Server offline
                            errorString.contains('522') || // Connection timeout
                            errorString.contains('403') || // Access denied
                            errorString.contains('geoblock');
    
    // ⚠️ IMPORTANTE: Se l'URL è già proxato, NON fare retry con location alternative
    // Il proxy server ha già tentato di recuperare il video
    // Il retry con location alternative NON aiuta perché l'URL è già passato attraverso il proxy
    final streamUrl = widget.channel.streamUrl;
    final isAlreadyProxied = streamUrl.contains('localhost:3000?url=') ||
                             streamUrl.contains('localhost:3000&url=') ||
                             streamUrl.contains('localhost:3000/');
    
    if (isAlreadyProxied) {
      // URL già proxato - NON fare retry con location alternative
      // ignore: avoid_print
      print('PlayerPage: ⚠️ URL già proxato, NON fare retry con location alternative: ${streamUrl.substring(0, streamUrl.length > 100 ? 100 : streamUrl.length)}...');
    }
    
    // ⚠️ CRITICO: Se l'URL è già proxato, NON fare retry con location alternative
    // Il proxy server ha già gestito geoblock/server offline
    // Il retry con location alternative NON aiuta e spreca tempo
    if (isAlreadyProxied) {
      // URL già proxato - mostra errore direttamente senza retry
      // ignore: avoid_print
      print('PlayerPage: ⚠️ URL già proxato, NON fare retry con location alternative - mostra errore direttamente');
      
      // Determina tipo di errore
      final isMovie = widget.channel.name.length > 0 && 
                     (streamUrl.contains('zplaypro.lat') ||
                      streamUrl.contains('.mp4') ||
                      streamUrl.contains('/movie/'));
      
      final isServerOffline = errorString.contains('521') || errorString.contains('522');
      
      String errorMessage;
      if (isMovie) {
        if (isServerOffline) {
          errorMessage = 'Server video offline.\n\n'
              'Il server video non è raggiungibile (errore 521/522).\n\n'
              'Il video è stato tentato attraverso il proxy server,\n'
              'ma il server originale non risponde.\n\n'
              'Il server potrebbe essere:\n'
              '• Temporaneamente offline\n'
              '• Rimosso o non più disponibile\n'
              '• Con problemi di rete\n\n'
              'Nota: I repository pubblici gratuiti possono avere server instabili.\n'
              'Prova con un altro film o riprova più tardi.';
        } else {
          errorMessage = 'Impossibile aprire il film.\n\n'
              'Il video è stato tentato attraverso il proxy server,\n'
              'ma non è stato possibile recuperarlo.\n\n'
              'Il server video potrebbe essere:\n'
              '• Temporaneamente non disponibile\n'
              '• Geoblocked (non accessibile anche tramite proxy)\n'
              '• Richiedere autenticazione o subscription\n\n'
              'Nota: I repository pubblici gratuiti possono avere URL instabili.\n'
              'Prova con un altro film o riprova più tardi.';
        }
      } else {
        if (isServerOffline) {
          errorMessage = 'Server stream offline.\n\n'
              'Il server video non è raggiungibile (errore 521/522).\n\n'
              'Il video è stato tentato attraverso il proxy server,\n'
              'ma il server originale non risponde.\n\n'
              'Prova con un altro canale.';
        } else {
          errorMessage = 'Impossibile aprire lo stream.\n\n'
              'Il video è stato tentato attraverso il proxy server,\n'
              'ma non è stato possibile recuperarlo.\n\n'
              'L\'URL potrebbe essere:\n'
              '• Scaduto o non più disponibile\n'
              '• Non accessibile anche tramite proxy\n'
              '• Rimosso dal server\n\n'
              'Prova con un altro canale.';
        }
      }
      
      if (mounted) {
        // URL proxati: mostra errore direttamente (non possono beneficiare di retry)
        setState(() {
            _error = errorMessage;
            _isLoading = false;
            _showTimeoutPlaceholder = false; // Nascondi placeholder se c'è errore
            _stopLoadingTimeout(); // Ferma il timer
          });
          // ignore: avoid_print
          print('PlayerPage: [EVENT_ERROR] Stato aggiornato (URL proxato, nessun retry): error=$_error, loading=$_isLoading');
      }
      return; // Esci senza fare retry
    }
    
    // URL NON proxato - può essere geoblocked, implementa retry automatici
    _errorRetryCount++;
    
    // Non mostrare errori se non abbiamo raggiunto il massimo numero di retry
    // Questo permette retry automatici più aggressivi senza disturbare l'utente
    if (_errorRetryCount < _maxErrorRetries) {
      // ignore: avoid_print
      print('PlayerPage: [EVENT_ERROR] Retry automatico $_errorRetryCount/$_maxErrorRetries - NON mostro errore, continuo con retry');
      // Non mostrare errore, permettere ai retry automatici di funzionare
      // Il sistema di retry geoblock continuerà automaticamente
      return;
    }
    
    // URL NON proxato - può essere geoblocked
    final isGeoblockedUrl = streamUrl.contains('zplaypro.lat') ||
                            streamUrl.contains('zplaypro.com') ||
                            streamUrl.contains('.mp4') ||
                            streamUrl.contains('cloudfront.net') || // IPTV-org
                            streamUrl.contains('mediaset.net') || // IPTV-org
                            streamUrl.contains('xdevel.com') || // IPTV-org
                            (streamUrl.contains('/play/') && streamUrl.contains('.m3u8')); // IPTV-org proxy
    
    // Retry automatico con location alternative SOLO se URL NON è già proxato
    if (isGeoblockError && isGeoblockedUrl && _alternativeGeoLocations != null && _alternativeGeoLocations!.isNotEmpty) {
      // Se non abbiamo ancora provato tutte le location alternative, prova con la prossima
      if (_currentGeoLocationIndex < _alternativeGeoLocations!.length) {
        final nextLocation = _alternativeGeoLocations![_currentGeoLocationIndex];
        _currentGeoLocationIndex++;
        
        // ignore: avoid_print
        print('PlayerPage: [GEOBLOCK_RETRY] Provo con location alternativa: $nextLocation (${_currentGeoLocationIndex}/${_alternativeGeoLocations!.length})');
        
        // Ritenta con la prossima location dopo un delay progressivo
        // Delay più lungo per evitare di sovraccaricare il server e dare tempo al server di rispondere
        final delayMs = 1000 + (_currentGeoLocationIndex * 200); // 1s, 1.2s, 1.4s, ecc.
        // ignore: avoid_print
        print('PlayerPage: [GEOBLOCK_RETRY] Attendo ${delayMs}ms prima del prossimo tentativo...');
        await Future.delayed(Duration(milliseconds: delayMs));
        
        if (mounted) {
          await _retryWithDifferentLocation(nextLocation);
          return; // Esci senza mostrare errore ancora
        }
      } else {
        // ignore: avoid_print
        print('PlayerPage: [GEOBLOCK_RETRY] Tutte le location sono state provate, mostra errore');
        
        // Se tutte le location falliscono con 521/522, il server è probabilmente offline
        if (errorString.contains('521') || errorString.contains('522')) {
          // Server offline - non è un problema di geoblock
          if (mounted) {
            setState(() {
              _error = 'Server video non raggiungibile.\n\n'
                  'Il server video è offline o non disponibile (errore 521/522).\n\n'
                  'Ho provato con ${_alternativeGeoLocations!.length + 1} location diverse:\n'
                  '• USA, UK, Germany, Canada, France, Spain, Italy\n\n'
                  'Il problema non è il geoblock ma il server che non risponde.\n\n'
                  'Possibili cause:\n'
                  '• Server temporaneamente offline\n'
                  '• Problema di rete tra Cloudflare e il server\n'
                  '• Server rimosso o non più disponibile\n\n'
                  'Prova con un altro film o riprova più tardi.';
              _isLoading = false;
            });
          }
          return;
        }
      }
    }
    
    // Messaggi di errore più user-friendly
    if (errorString.contains('failed to open') || 
        errorString.contains('could not open') ||
        errorString.contains('404') ||
        errorString.contains('not found') ||
        errorString.contains('521') || // Cloudflare: Web Server Is Down
        errorString.contains('522') || // Cloudflare: Connection Timed Out
        errorString.contains('523') || // Cloudflare: Origin Is Unreachable
        errorString.contains('524')) { // Cloudflare: A Timeout Occurred
      // Determina se è un film on-demand o un canale live
      final isMovie = widget.channel.name.length > 0 && 
                     (widget.channel.streamUrl.contains('zplaypro.lat') ||
                      widget.channel.streamUrl.contains('.mp4') ||
                      widget.channel.streamUrl.contains('/movie/'));
      
      // Se abbiamo provato tutte le location e tutte falliscono con 521/522,
      // il server è probabilmente offline (non geoblock)
      final hasTriedAllLocations = _alternativeGeoLocations != null && 
                                   _currentGeoLocationIndex >= _alternativeGeoLocations!.length;
      final isServerOffline = errorString.contains('521') || errorString.contains('522');
      
      if (isMovie) {
        // Verifica se l'URL è già proxato (passato attraverso proxy server)
        final isAlreadyProxied = widget.channel.streamUrl.contains('localhost:3000?url=') ||
                                widget.channel.streamUrl.contains('localhost:3000&url=');
        
        if (isServerOffline) {
          // Server offline - se è già proxato, il proxy ha già tentato
          if (isAlreadyProxied || hasTriedAllLocations) {
            errorMessage = 'Server video offline.\n\n'
                'Il server video non è raggiungibile (errore 521/522).\n\n'
                'Il video è stato tentato attraverso il proxy server,\n'
                'ma il server originale non risponde.\n\n'
                'Il server potrebbe essere:\n'
                '• Temporaneamente offline\n'
                '• Rimosso o non più disponibile\n'
                '• Con problemi di rete\n\n'
                'Nota: I repository pubblici gratuiti possono avere server instabili.\n'
                'Prova con un altro film o riprova più tardi.';
          } else {
            errorMessage = 'Server video offline.\n\n'
                'Il server video non è raggiungibile (errore 521/522).\n\n'
                'Ho provato automaticamente con ${_alternativeGeoLocations!.length + 1} location diverse,\n'
                'ma il server non risponde. Non è un problema di geoblock.\n\n'
                'Il server potrebbe essere:\n'
                '• Temporaneamente offline\n'
                '• Rimosso o non più disponibile\n'
                '• Con problemi di rete\n\n'
                'Nota: I repository pubblici gratuiti possono avere server instabili.\n'
                'Prova con un altro film o riprova più tardi.';
          }
        } else {
          // Altri errori (non 521/522)
          if (isAlreadyProxied) {
            // URL già proxato - il proxy ha già tentato
            errorMessage = 'Impossibile aprire il film.\n\n'
                'Il video è stato tentato attraverso il proxy server,\n'
                'ma non è stato possibile recuperarlo.\n\n'
                'Il server video potrebbe essere:\n'
                '• Temporaneamente non disponibile\n'
                '• Geoblocked (non accessibile anche tramite proxy)\n'
                '• Richiedere autenticazione o subscription\n\n'
                'Nota: I repository pubblici gratuiti possono avere URL instabili.\n'
                'Prova con un altro film o riprova più tardi.';
          } else {
            // URL non proxato - potrebbero essere geoblock o altri problemi
            errorMessage = 'Impossibile aprire il film.\n\n'
                'Il server video potrebbe essere:\n'
                '• Temporaneamente non disponibile\n'
                '• Geoblocked (non accessibile dal tuo paese)\n'
                '• Richiedere autenticazione o subscription\n\n'
                'Nota: I repository pubblici gratuiti possono avere URL instabili.\n'
                'Prova con un altro film o riprova più tardi.';
          }
        }
      } else {
        if (hasTriedAllLocations && isServerOffline) {
          errorMessage = 'Server stream offline.\n\n'
              'Il server video non è raggiungibile (errore 521/522).\n\n'
              'Ho provato automaticamente con ${_alternativeGeoLocations!.length + 1} location diverse,\n'
              'ma il server non risponde. Non è un problema di geoblock.\n\n'
              'Prova con un altro canale.';
        } else {
          errorMessage = 'Impossibile aprire lo stream.\n\n'
              'L\'URL potrebbe essere:\n'
              '• Scaduto o non più disponibile\n'
              '• Non accessibile dal tuo paese (geoblocked)\n'
              '• Rimosso dal server\n\n'
              'Prova con un altro canale.';
        }
      }
    } else if (errorString.contains('connection') || 
               errorString.contains('timeout') ||
               errorString.contains('network')) {
      errorMessage = 'Errore di connessione.\n\n'
          'Verifica la tua connessione internet e riprova.';
    } else if (errorString.contains('format') || 
               errorString.contains('codec') ||
               errorString.contains('decode')) {
      errorMessage = 'Formato stream non supportato.\n\n'
          'Lo stream potrebbe usare un formato non compatibile con il player.';
    } else {
      // Errore generico
      errorMessage = 'Errore durante la riproduzione.\n\n'
          'Errore: ${error.toString().split('\n').first}\n\n'
          'Lo stream potrebbe non essere disponibile o accessibile.';
    }
    
    // Mostra errore SOLO se abbiamo raggiunto il massimo numero di retry
    // Questo permette retry automatici senza disturbare l'utente
    if (_errorRetryCount >= _maxErrorRetries) {
      setState(() {
        _error = errorMessage;
        _isLoading = false;
        _showTimeoutPlaceholder = false; // Nascondi placeholder se c'è errore
        _stopLoadingTimeout(); // Ferma il timer
      });
      // ignore: avoid_print
      print('PlayerPage: [EVENT_ERROR] Stato aggiornato (max retry raggiunto): error=$_error, loading=$_isLoading');
    } else {
      // ignore: avoid_print
      print('PlayerPage: [EVENT_ERROR] Retry $_errorRetryCount/$_maxErrorRetries - errore non mostrato, continuo con retry');
      // Non mostrare errore, continuare con retry automatici
      _isLoading = true; // Mantieni loading per mostrare che sta tentando
    }
  }

  Future<void> _loadVideo({bool useOriginalUrl = false, bool isRetry = false}) async {
    // Non caricare se stiamo disattivando o se il widget non è montato
    if (_isDisposing || !mounted) {
      // ignore: avoid_print
      print('PlayerPage: [LOAD_VIDEO] Caricamento annullato (disposing o non mounted)');
      return;
    }
    
    // Evita loop infiniti
    if (_isRetrying && !isRetry) {
      return;
    }

    if (isRetry) {
      _isRetrying = true;
    }
    
    // Reset error retry count quando si carica un nuovo video
    if (!isRetry) {
      _errorRetryCount = 0;
    }
    
    try {
      String urlToPlay;
      
      // Se abbiamo già provato entrambi, non riprovare
      if (_hasTriedFallback && useOriginalUrl) {
        // ignore: avoid_print
        print('PlayerPage: Già provato entrambi gli URL, fermo il loop');
        if (mounted) {
          setState(() {
            _error = 'Impossibile caricare lo stream.\n\n'
                'Sia l\'API Zappr che l\'URL originale non sono disponibili.\n'
                'Lo stream potrebbe essere offline o richiedere autenticazione.';
            _isLoading = false;
          });
        }
        return;
      }
      
      if (useOriginalUrl) {
        // Prova con URL originale come fallback (solo una volta)
        urlToPlay = widget.channel.streamUrl;
        _resolvedUrl = 'URL originale: $urlToPlay';
        _hasTriedFallback = true;
        
        // ignore: avoid_print
        print('PlayerPage: [FALLBACK] Uso URL originale (non risolto): $urlToPlay');
      } else {
        // Prova prima con risoluzione Zappr (gestisce anche autenticazione Rai)
        try {
          // ignore: avoid_print
          print('PlayerPage: Risolvo URL per canale ${widget.channel.name}');
          print('PlayerPage: URL originale: ${widget.channel.streamUrl}');
          print('PlayerPage: License: ${widget.channel.license ?? "nessuna"}');
          
          final playable = await _resolver.resolvePlayableUrlAsync(
            widget.channel.streamUrl,
            license: widget.channel.license,
          );
          urlToPlay = playable.toString();
          _resolvedUrl = urlToPlay;
          
          // ignore: avoid_print
          print('PlayerPage: URL risolto: ${urlToPlay.substring(0, urlToPlay.length > 150 ? 150 : urlToPlay.length)}...');
          
          // Verifica che per canali Rai l'URL contenga l'autenticazione
          // MA: 
          // - Se usiamo API Vercel/Cloudflare, l'auth è gestita internamente (token JWT o redirect)
          // - Se è URL akamaized.net diretto, deve contenere hdnea=
          // - Se è URL da API (zappr.stream), l'auth è gestita dall'API
          if (widget.channel.license == 'rai-akamai' && 
              !urlToPlay.contains('hdnea=') && 
              !urlToPlay.contains('vercel-api.zappr.stream') &&
              !urlToPlay.contains('cloudflare-api.zappr.stream') &&
              !urlToPlay.contains('zappr.stream') &&
              !urlToPlay.contains('tok_') && // Token JWT da API Cloudflare
              urlToPlay.contains('akamaized.net')) {
            // Solo per URL akamaized.net diretti (non passati da API) serve hdnea=
            throw Exception('URL Rai senza autenticazione! L\'auth potrebbe non essere stata aggiunta correttamente.');
          }
        } catch (e) {
          // Se la risoluzione fallisce e non è un canale Rai, prova con URL originale
          // Per canali Rai invece mostra errore perché senza auth non funzionerà
          // ignore: avoid_print
          print('PlayerPage: Risoluzione Zappr fallita: $e');
          if (widget.channel.license == 'rai-akamai') {
            // Canali Rai richiedono autenticazione, non provare con URL originale
            if (mounted) {
              await _player.stop();
              setState(() {
                _error = 'Impossibile ottenere autenticazione Rai.\n\n'
                    'Errore: ${e.toString().split('\n').first}\n\n'
                    'L\'autenticazione è necessaria per i canali Rai.';
                _isLoading = false;
              });
            }
            return;
          } else {
            // Per altri canali/film, prova con URL originale
            // ignore: avoid_print
            print('PlayerPage: Provo con URL originale come fallback');
            urlToPlay = widget.channel.streamUrl;
            _resolvedUrl = 'URL originale (fallback): $urlToPlay';
            _hasTriedFallback = true;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _showTimeoutPlaceholder = false;
        });
        
        // Avvia timer di timeout per mostrare placeholder se il caricamento impiega troppo
        _startLoadingTimeout();
      }

      // Ferma il player se sta già riproducendo qualcosa
      if (_player.state.playing) {
        await _player.stop();
      }
      
      // Reset retry geoblock per nuovo tentativo
      _alternativeGeoLocations = null;
      _currentGeoLocationIndex = 0;

          // Configura il player con opzioni migliorate
          // Se l'URL è dall'API Zappr, specifica il tipo HLS come fa Video.js
          final isZapprApi = urlToPlay.contains('zappr.stream');
          final isHlsUrl = urlToPlay.contains('.m3u8') || isZapprApi;
          
          try {
            // ignore: avoid_print
            print('═══════════════════════════════════════════════════════════');
            print('PlayerPage: [OPEN_START] Apro player con URL');
            print('PlayerPage: [OPEN] URL: ${urlToPlay.length > 200 ? '${urlToPlay.substring(0, 200)}...' : urlToPlay}');
            print('PlayerPage: [OPEN] URL length: ${urlToPlay.length} caratteri');
            print('PlayerPage: [OPEN] Is Zappr API: $isZapprApi');
            print('PlayerPage: [OPEN] Is HLS URL: $isHlsUrl');
            
            // Header per simulare meglio un browser web
            // Se l'URL potrebbe essere geoblocked, prova a risolverlo tramite proxy
            Map<String, String> headers = {};
            
            // ⚠️ CRITICO: Verifica se l'URL è già proxato PRIMA di controllare geoblock
            // Se è già proxato, NON fare retry con location alternative (non serve)
            final isAlreadyProxied = urlToPlay.contains('localhost:3000?url=') ||
                                   urlToPlay.contains('localhost:3000&url=') ||
                                   urlToPlay.contains('localhost:3000/');
            
            // Verifica se l'URL è potenzialmente geoblocked SOLO se NON è già proxato
            // Se è già proxato, il proxy server ha già gestito geoblock/server offline
            final isPotentiallyGeoblocked = !isAlreadyProxied && (
                                           urlToPlay.contains('zplaypro.lat') || 
                                           urlToPlay.contains('zplaypro.com') ||
                                           urlToPlay.contains('.mp4') ||
                                           urlToPlay.contains('cloudfront.net') || // IPTV-org
                                           urlToPlay.contains('mediaset.net') || // IPTV-org
                                           urlToPlay.contains('xdevel.com') || // IPTV-org
                                           (urlToPlay.contains('/play/') && urlToPlay.contains('.m3u8'))); // IPTV-org proxy
            
            if (isAlreadyProxied) {
              // URL già proxato - NON fare retry con location alternative
              // ignore: avoid_print
              print('PlayerPage: ⚠️ URL già proxato, NON fare retry con location alternative: ${urlToPlay.substring(0, urlToPlay.length > 100 ? 100 : urlToPlay.length)}...');
            }
            
            // Verifica se è un file MP4 diretto (richiede configurazione speciale)
            final isDirectMp4 = urlToPlay.contains('.mp4') && 
                               !urlToPlay.contains('.m3u8') && 
                               !urlToPlay.contains('zappr.stream');
            
            if (isPotentiallyGeoblocked) {
              // ignore: avoid_print
              print('PlayerPage: [GEOBLOCK] Rilevato URL potenzialmente geoblocked (non proxato), provo risoluzione proxy con multiple location');
              
              // Prova a risolvere tramite proxy per bypassare geoblocking
              // Prova con multiple location per aumentare le possibilità di successo
              try {
                final proxyResult = await _proxyResolver.resolveGeoblockedUrl(
                  urlToPlay,
                  preferredLocation: GeoLocation.usa,
                  useProxy: true, // Prova prima con proxy reale
                  tryMultipleLocations: true, // ✅ Prova più location se necessario
                );
                
                // Se il proxy ha risolto un URL diverso, usalo
                if (proxyResult.method == ProxyMethod.proxy) {
                  urlToPlay = proxyResult.url;
                  // ignore: avoid_print
                  print('PlayerPage: [PROXY] Uso URL proxy: ${urlToPlay.substring(0, urlToPlay.length > 150 ? 150 : urlToPlay.length)}...');
                }
                
                // Usa gli header personalizzati dal proxy resolver
                headers = proxyResult.headers;
                
                // Salva le location alternative per retry automatico in caso di errore
                if (proxyResult.alternativeLocations != null && proxyResult.alternativeLocations!.isNotEmpty) {
                  _alternativeGeoLocations = proxyResult.alternativeLocations;
                  _currentGeoLocationIndex = 0; // Reset indice
                  // ignore: avoid_print
                  print('PlayerPage: [GEOBLOCK] Location alternative salvate per retry: ${_alternativeGeoLocations!.length} location');
                }
                // Aggiungi header specifici per video streaming
                headers.addAll({
                  'Accept': isHlsUrl 
                      ? 'application/vnd.apple.mpegurl, application/x-mpegURL, */*'
                      : isDirectMp4
                          ? 'video/mp4, video/*, */*'
                          : '*/*',
                  'Accept-Encoding': 'gzip, deflate, br',
                  'Sec-Fetch-Dest': 'video',
                  'Sec-Fetch-Mode': 'no-cors',
                  'Sec-Fetch-Site': 'cross-site',
                  // Header specifici per MP4 streaming
                  if (isDirectMp4) ...{
                    'Range': 'bytes=0-', // Supporto per streaming parziale
                    'Cache-Control': 'no-cache',
                  },
                });
              } catch (e) {
                // Se il proxy fallisce, usa solo header personalizzati
                // ignore: avoid_print
                print('PlayerPage: [PROXY_ERROR] Proxy fallito: $e, uso solo header personalizzati');
                headers = {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Referer': 'https://www.google.com/',
                  'Origin': 'https://www.google.com',
                  'Accept': isHlsUrl 
                      ? 'application/vnd.apple.mpegurl, application/x-mpegURL, */*'
                      : isDirectMp4
                          ? 'video/mp4, video/*, */*'
                          : '*/*',
                  'Accept-Language': 'en-US,en;q=0.9', // Simula USA
                  'Accept-Encoding': 'gzip, deflate, br',
                  'Connection': 'keep-alive',
                  'CF-IPCountry': 'US', // Header Cloudflare per indicare USA
                  'X-Forwarded-For': '8.8.8.8', // IP pubblico USA (Google DNS)
                  'Sec-Fetch-Dest': 'video',
                  'Sec-Fetch-Mode': 'no-cors',
                  'Sec-Fetch-Site': 'cross-site',
                  // Header specifici per MP4 streaming
                  if (isDirectMp4) ...{
                    'Range': 'bytes=0-', // Supporto per streaming parziale
                    'Cache-Control': 'no-cache',
                  },
                };
              }
            } else {
              // Header standard per URL normali
              headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://zappr.stream/',
                'Origin': 'https://zappr.stream',
                // Se è HLS o API Zappr, usa header specifici per HLS
                'Accept': isHlsUrl 
                    ? 'application/vnd.apple.mpegurl, application/x-mpegURL, */*'
                    : '*/*',
                'Accept-Language': 'it-IT,it;q=0.9,en;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
                'Sec-Fetch-Dest': 'video',
                'Sec-Fetch-Mode': 'no-cors',
                'Sec-Fetch-Site': 'cross-site',
              };
            }
            
            // ignore: avoid_print
            print('PlayerPage: [OPEN] Header configurati:');
            headers.forEach((key, value) {
              print('PlayerPage: [HEADER] $key: $value');
            });
            
            // Per URL MP4 da zplaypro, testa l'accessibilità prima di aprire il player
            // Per URL M3U8 IPTV-org, non facciamo test HEAD perché spesso sono geoblocked
            // e il test HEAD potrebbe bloccare il caricamento inutilmente
            
            if (isDirectMp4 && (urlToPlay.contains('zplaypro.lat') || urlToPlay.contains('zplaypro.com'))) {
              // ignore: avoid_print
              print('═══════════════════════════════════════════════════════════');
              print('PlayerPage: [TEST] Testo accessibilità URL MP4 prima di aprire player...');
              print('PlayerPage: [TEST] URL da testare: $urlToPlay');
              print('PlayerPage: [TEST] URL è proxato: ${urlToPlay.contains('localhost:3000')}');
              print('PlayerPage: [TEST] Header inviati:');
              headers.forEach((key, value) {
                print('PlayerPage: [TEST]   $key: $value');
              });
              
              try {
                final testStart = DateTime.now();
                // ignore: avoid_print
                print('PlayerPage: [TEST] Invio richiesta HEAD al server...');
                
                // Fai una richiesta HEAD per verificare se l'URL è accessibile
                // Usa timeout breve per non bloccare l'UI
                final response = await _dio.head(
                  urlToPlay,
                  options: Options(
                    headers: headers,
                    followRedirects: true,
                    maxRedirects: 5,
                    validateStatus: (status) => status! < 500,
                    receiveTimeout: const Duration(seconds: 10),
                    sendTimeout: const Duration(seconds: 10),
                  ),
                );
                
                final testDuration = DateTime.now().difference(testStart);
                // ignore: avoid_print
                print('PlayerPage: [TEST] Risposta HEAD ricevuta in ${testDuration.inMilliseconds}ms');
                print('PlayerPage: [TEST] Status code: ${response.statusCode}');
                print('PlayerPage: [TEST] Status message: ${response.statusMessage}');
                print('PlayerPage: [TEST] Header risposta:');
                response.headers.forEach((key, values) {
                  print('PlayerPage: [TEST]   $key: ${values.join(", ")}');
                });
                
                // Per risposte di errore (4xx, 5xx), prova a leggere il body JSON se presente
                if (response.statusCode != null && response.statusCode! >= 400) {
                  try {
                    // Per HEAD, il body potrebbe non essere disponibile, prova comunque
                    if (response.data != null) {
                      final bodyStr = response.data.toString();
                      // ignore: avoid_print
                      print('PlayerPage: [TEST] Body risposta errore (primi 500 caratteri): ${bodyStr.length > 500 ? bodyStr.substring(0, 500) : bodyStr}');
                      
                      // Se sembra JSON, provalo a parsare
                      if (bodyStr.trim().startsWith('{')) {
                        try {
                          final jsonBody = jsonDecode(bodyStr);
                          // ignore: avoid_print
                          print('PlayerPage: [TEST] JSON body parsato: $jsonBody');
                          if (jsonBody is Map && jsonBody.containsKey('error')) {
                            // ignore: avoid_print
                            print('PlayerPage: [TEST] ⚠️ Errore dal proxy: ${jsonBody['error']}');
                            if (jsonBody.containsKey('message')) {
                              // ignore: avoid_print
                              print('PlayerPage: [TEST] ⚠️ Messaggio: ${jsonBody['message']}');
                            }
                            if (jsonBody.containsKey('hostname')) {
                              // ignore: avoid_print
                              print('PlayerPage: [TEST] ⚠️ Hostname originale: ${jsonBody['hostname']}');
                            }
                          }
                        } catch (e) {
                          // ignore: avoid_print
                          print('PlayerPage: [TEST] Impossibile parsare body come JSON: $e');
                        }
                      }
                    }
                  } catch (e) {
                    // ignore: avoid_print
                    print('PlayerPage: [TEST] Errore leggendo body risposta: $e');
                  }
                }
                
                // ignore: avoid_print
                print('═══════════════════════════════════════════════════════════');
                
                if (response.statusCode != null && response.statusCode! >= 400) {
                  // URL non accessibile dal test HEAD
                  String statusMessage = 'Errore ${response.statusCode}';
                  if (response.statusCode == 403) {
                    statusMessage = 'Accesso negato (403) - Geoblocked o richiede autenticazione';
                  } else if (response.statusCode == 404) {
                    statusMessage = 'Video non trovato (404)';
                  } else if (response.statusCode == 521) {
                    statusMessage = 'Server offline (521) - Cloudflare non può raggiungere il server';
                  }
                  
                  // Se abbiamo location alternative, proviamo comunque - il test HEAD potrebbe fallire
                  // ma il player con un'altra location potrebbe funzionare
                  if (_alternativeGeoLocations != null && _alternativeGeoLocations!.isNotEmpty &&
                      (response.statusCode == 521 || response.statusCode == 522 || response.statusCode == 403)) {
                    // ignore: avoid_print
                    print('PlayerPage: [TEST] Test HEAD fallito (${response.statusCode}) ma ho location alternative, provo comunque con il player (triggererà retry automatico)');
                    // Continua e lascia che il player provi - se fallisce, il retry automatico userà altre location
                  } else if (response.statusCode == 404) {
                    // 404 è definitivo - il video non esiste
                    // ignore: avoid_print
                    print('PlayerPage: [TEST] Video non trovato (404), mostro errore');
                    if (mounted) {
                      await _player.stop();
                      setState(() {
                        _error = 'Impossibile accedere al video.\n\n'
                            '$statusMessage\n\n'
                            'L\'URL potrebbe essere:\n'
                            '• Offline o non più disponibile\n'
                            '• Rimosso dal server\n\n'
                            'Prova con un altro film.';
                        _isLoading = false;
                      });
                    }
                    return;
                  } else {
                    // Per altri errori (403, 521, 522), proviamo comunque - potrebbe funzionare
                    // o il retry automatico userà altre location se disponibili
                    // ignore: avoid_print
                    print('PlayerPage: [TEST] Test HEAD fallito (${response.statusCode}) ma provo comunque con il player');
                  }
                }
                
                // ignore: avoid_print
                print('PlayerPage: [TEST] URL accessibile, procedo con il player');
              } catch (e) {
                // Se il test HEAD fallisce, verifica se abbiamo location alternative
                // Se abbiamo alternative, proviamo comunque - potrebbe funzionare con altra location
                // ignore: avoid_print
                print('═══════════════════════════════════════════════════════════');
                print('PlayerPage: [TEST] ❌ ERRORE durante test HEAD');
                print('PlayerPage: [TEST] Tipo errore: ${e.runtimeType}');
                print('PlayerPage: [TEST] Errore completo: $e');
                
                // Se è un DioException, mostra più dettagli
                if (e is DioException) {
                  print('PlayerPage: [TEST] DioException details:');
                  print('PlayerPage: [TEST]   - Type: ${e.type}');
                  print('PlayerPage: [TEST]   - Message: ${e.message}');
                  print('PlayerPage: [TEST]   - Response: ${e.response}');
                  if (e.response != null) {
                    print('PlayerPage: [TEST]   - Response status: ${e.response!.statusCode}');
                    
                    // Prova a leggere e parsare il body JSON se presente
                    if (e.response!.data != null) {
                      try {
                        final bodyStr = e.response!.data.toString();
                        print('PlayerPage: [TEST]   - Response data (raw): ${bodyStr.length > 200 ? bodyStr.substring(0, 200) + "..." : bodyStr}');
                        
                        // Se sembra JSON, provalo a parsare
                        if (bodyStr.trim().startsWith('{') || bodyStr.trim().startsWith('[')) {
                          try {
                            final jsonBody = jsonDecode(bodyStr);
                            print('PlayerPage: [TEST]   - Response data (JSON): $jsonBody');
                            
                            if (jsonBody is Map) {
                              if (jsonBody.containsKey('error')) {
                                print('PlayerPage: [TEST]   ⚠️ Errore dal proxy: ${jsonBody['error']}');
                              }
                              if (jsonBody.containsKey('message')) {
                                print('PlayerPage: [TEST]   ⚠️ Messaggio: ${jsonBody['message']}');
                              }
                              if (jsonBody.containsKey('hostname')) {
                                print('PlayerPage: [TEST]   ⚠️ Hostname originale: ${jsonBody['hostname']}');
                              }
                              if (jsonBody.containsKey('status')) {
                                print('PlayerPage: [TEST]   ⚠️ Status originale: ${jsonBody['status']}');
                              }
                            }
                          } catch (jsonError) {
                            print('PlayerPage: [TEST]   - Impossibile parsare response.data come JSON: $jsonError');
                          }
                        }
                      } catch (readError) {
                        print('PlayerPage: [TEST]   - Errore leggendo response.data: $readError');
                      }
                    }
                    
                    print('PlayerPage: [TEST]   - Response headers: ${e.response!.headers}');
                  }
                  print('PlayerPage: [TEST]   - Request options: ${e.requestOptions.uri}');
                  print('PlayerPage: [TEST]   - Request headers: ${e.requestOptions.headers}');
                }
                print('PlayerPage: [TEST] Stack trace: ${StackTrace.current}');
                print('═══════════════════════════════════════════════════════════');

                final errorString = e.toString().toLowerCase();
                final isServerError = errorString.contains('521') || // Server offline
                                    errorString.contains('522') || // Connection timeout
                                    errorString.contains('503') || // Service unavailable
                                    errorString.contains('timeout') ||
                                    errorString.contains('connection');
                
                // Se abbiamo location alternative E l'errore è del server (non 403/404 definitivi),
                // proviamo comunque con il player - potrebbe funzionare o triggerare retry automatico
                if ((_alternativeGeoLocations != null && _alternativeGeoLocations!.isNotEmpty) &&
                    isServerError) {
                  // ignore: avoid_print
                  print('PlayerPage: [TEST] Test HEAD fallito ma ho location alternative, provo comunque con il player (triggererà retry automatico)');
                  // Continua e lascia che il player provi - se fallisce, il retry automatico userà altre location
                } else if (errorString.contains('timeoutexception') || 
                          errorString.contains('connection') ||
                          (errorString.contains('failed') && !errorString.contains('521') && !errorString.contains('522'))) {
                  // Solo per errori definitivi di connessione/timeout (non 521/522 che potrebbero essere geoblock)
                  // Se è un vero errore di rete senza alternative, mostra errore
                  // ignore: avoid_print
                  print('PlayerPage: [TEST] Test HEAD fallito con errore di rete definitivo, mostro errore');
                  if (mounted) {
                    await _player.stop();
                    setState(() {
                      _error = 'Impossibile raggiungere il server video.\n\n'
                          'Il server ${
                            urlToPlay.contains('zplaypro.lat') ? 'zplaypro.lat' : 
                            urlToPlay.contains('zplaypro.com') ? 'zplaypro.com' :
                            urlToPlay.contains('cloudfront.net') ? 'cloudfront.net' :
                            'video'
                          } non risponde.\n\n'
                          'Possibili cause:\n'
                          '• Server offline o non più disponibile\n'
                          '• Problema di rete o firewall\n'
                          '• Il server potrebbe richiedere autenticazione\n\n'
                          'Nota: I repository pubblici gratuiti possono avere server instabili.\n'
                          'Prova con un altro film o riprova più tardi.';
                      _isLoading = false;
                    });
                  }
                  return;
                } else {
                  // Per altri errori (inclusi 521/522), proviamo comunque - media_kit potrebbe gestirlo meglio
                  // o potrebbe essere un problema geoblock che il player gestirà con retry
                  // ignore: avoid_print
                  print('PlayerPage: [TEST] Test HEAD fallito ma provo comunque - potrebbe essere geoblock o problema temporaneo');
                }
              }
            }
            
            final openStart = DateTime.now();
            // ignore: avoid_print
            print('═══════════════════════════════════════════════════════════');
            print('PlayerPage: [OPEN] Chiamata _player.open()...');
            print('PlayerPage: [OPEN] URL finale: $urlToPlay');
            print('PlayerPage: [OPEN] URL length: ${urlToPlay.length} caratteri');
            print('PlayerPage: [OPEN] Is proxato: ${urlToPlay.contains('localhost:3000')}');
            print('PlayerPage: [OPEN] Header finali:');
            headers.forEach((key, value) {
              print('PlayerPage: [OPEN]   $key: ${value.toString().length > 100 ? '${value.toString().substring(0, 100)}...' : value}');
            });

            try {
              // Controlla se stiamo disattivando prima di aprire
              if (_isDisposing || !mounted) {
                // ignore: avoid_print
                print('PlayerPage: [OPEN] Operazione annullata (disposing o non mounted)');
                return;
              }
              
              await _player.open(
                Media(
                  urlToPlay,
                  httpHeaders: headers,
                ),
                play: true,
              ).timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Timeout durante apertura player', const Duration(seconds: 30));
                },
              );

              final openDuration = DateTime.now().difference(openStart);
              // ignore: avoid_print
              print('PlayerPage: [OPEN] ✅ _player.open() completato in ${openDuration.inMilliseconds}ms');
              print('═══════════════════════════════════════════════════════════');
            } catch (e) {
              final openDuration = DateTime.now().difference(openStart);
              // ignore: avoid_print
              print('PlayerPage: [OPEN] ❌ ERRORE durante _player.open() dopo ${openDuration.inMilliseconds}ms');
              print('PlayerPage: [OPEN] Tipo errore: ${e.runtimeType}');
              print('PlayerPage: [OPEN] Errore: $e');
              print('PlayerPage: [OPEN] Stack trace: ${StackTrace.current}');
              print('═══════════════════════════════════════════════════════════');
              rethrow; // Rilancia per essere gestito dal catch esterno
            }
            print('PlayerPage: [OPEN] Stato player dopo open:');
            print('PlayerPage: [OPEN] - Playing: ${_player.state.playing}');
            print('PlayerPage: [OPEN] - Duration: ${_player.state.duration}');
            print('PlayerPage: [OPEN] - Position: ${_player.state.position}');
            print('PlayerPage: [OPEN] - Rate: ${_player.state.rate}');
            print('PlayerPage: [OPEN] - Volume: ${_player.state.volume}');
            print('PlayerPage: [OPEN] - Playlist mode: ${_player.state.playlistMode}');
            
            // Configura opzioni avanzate per gestire errori di decoding
            // Ignora errori minori di timestamp e pacchetti corrotti
            // ignore: avoid_print
            print('PlayerPage: [CONFIG] Configuro playlist mode...');
            await _player.setPlaylistMode(PlaylistMode.none);
            // ignore: avoid_print
            print('PlayerPage: [CONFIG] Playlist mode configurato');
            
            // Nota: Le opzioni mpv avanzate (video-sync, audio-buffer, demuxer-lavf-o)
            // non sono disponibili tramite setProperty in questa versione di media_kit.
            // Il player userà le impostazioni di default di mpv che gestiscono già
            // la maggior parte degli errori di decoding comuni negli stream live.
        
        // Attendi per vedere se parte (5 secondi)
        // ignore: avoid_print
        print('PlayerPage: [WAIT] Attendo 5 secondi per verificare se lo stream parte...');
        final waitStart = DateTime.now();
        await Future.delayed(const Duration(seconds: 5));
        final waitDuration = DateTime.now().difference(waitStart);
        // ignore: avoid_print
        print('PlayerPage: [WAIT] Attesa completata (${waitDuration.inMilliseconds}ms)');
        
        if (mounted) {
          final isPlaying = _player.state.playing;
          // ignore: avoid_print
          print('PlayerPage: [CHECK] Verifica stato dopo attesa:');
          print('PlayerPage: [CHECK] - Playing: $isPlaying');
          print('PlayerPage: [CHECK] - Error: $_error');
          print('PlayerPage: [CHECK] - Loading: $_isLoading');
          
          if (!isPlaying && _error == null) {
            // ignore: avoid_print
            print('PlayerPage: [CHECK] Stream non in riproduzione e nessun errore, verifico fallback...');
            // Se l'API Zappr fallisce e non abbiamo ancora provato il fallback, prova con URL originale
            if (!_hasTriedFallback && urlToPlay.contains('zappr.stream')) {
              // ignore: avoid_print
              print('PlayerPage: API Zappr non ha avviato lo stream, provo con URL originale');
              await _player.stop();
              _hasTriedFallback = true;
              await _loadVideo(useOriginalUrl: true);
              return;
            }
            
            // Se abbiamo già provato entrambi, mostra errore definitivo
            await _player.stop();
            setState(() {
              final urlPreview = urlToPlay.length > 80 ? '${urlToPlay.substring(0, 80)}...' : urlToPlay;
              if (_hasTriedFallback) {
                _error = 'Impossibile caricare lo stream.\n\n'
                    'L\'URL potrebbe essere scaduto, non accessibile o geoblocked.\n'
                    'Prova con un altro canale o verifica la tua connessione.\n\n'
                    'URL: $urlPreview\n\n'
                    'L\'URL del canale potrebbe essere scaduto.\n\n'
                    'Verifica sul sito zappr.stream se il canale funziona\n'
                    'e aggiorna l\'URL nel channels.json.';
              } else {
                _error = 'Stream non disponibile.\n\nURL provato: $urlPreview\n\n'
                    'L\'API Zappr potrebbe restituire un errore.\n'
                    'Verifica sul sito zappr.stream se il canale funziona.';
              }
              _isLoading = false;
            });
          } else if (isPlaying) {
            // Funziona! Rimuovi errori e reset flag
            setState(() {
              _isLoading = false;
              _error = null;
              _hasTriedFallback = false; // Reset per permettere retry
              _errorRetryCount = 0; // Reset contatore retry
            });
          }
        }
      } catch (e, stackTrace) {
        // ignore: avoid_print
        print('PlayerPage: [EXCEPTION] Errore nell\'apertura del player');
        print('PlayerPage: [EXCEPTION] Tipo: ${e.runtimeType}');
        print('PlayerPage: [EXCEPTION] Messaggio: $e');
        print('PlayerPage: [EXCEPTION] Stack trace:');
        print(stackTrace);
        print('═══════════════════════════════════════════════════════════');
        
        if (mounted) {
          // Ferma il player
          try {
            await _player.stop();
          } catch (_) {}
          
          // Se l'API Zappr fallisce e non abbiamo ancora provato il fallback, prova con URL originale
          if (!_hasTriedFallback && urlToPlay.contains('zappr.stream')) {
            // ignore: avoid_print
            print('PlayerPage: Errore con API Zappr, provo con URL originale');
            await _player.stop();
            _hasTriedFallback = true;
            await _loadVideo(useOriginalUrl: true);
            return;
          }
          
          // Se abbiamo già provato entrambi, mostra errore definitivo
          if (_hasTriedFallback) {
            setState(() {
              _error = 'Impossibile caricare lo stream.\n\n'
                  'Sia l\'API Zappr che l\'URL originale non sono disponibili.\n'
                  'Lo stream potrebbe essere offline o richiedere autenticazione.';
              _isLoading = false;
            });
            return;
          }
          
          // Mostra errore e ferma
          setState(() {
            final errorStr = e.toString();
            String errorMsg;
            
            // Controlla se è un URL zappr://
            final isZapprProtocol = widget.channel.streamUrl.startsWith('zappr://');
            
            if (isZapprProtocol) {
              // Verifica se l'errore contiene informazioni specifiche dall'API
              if (errorStr.contains('non sono supportati dalle API pubbliche')) {
                // Usa il messaggio dettagliato dall'API
                errorMsg = errorStr.split('\n\n').skip(1).join('\n\n');
              } else {
                errorMsg = 'Impossibile caricare lo stream.\n\n'
                    'Il canale utilizza uno schema URL personalizzato (zappr://) che non è supportato dalle API pubbliche di Zappr.\n\n'
                    'Questi URL funzionano solo nell\'applicazione web Zappr e richiedono autenticazione/cookie di sessione.\n\n'
                    'Soluzione: Verifica sul sito zappr.stream se il canale ha un URL diretto (es. .m3u8) da usare invece di zappr://.';
              }
            } else if (errorStr.contains('Failed to open')) {
              errorMsg = 'Impossibile aprire lo stream.\n\n'
                  'L\'API Zappr potrebbe non essere disponibile o lo stream non è accessibile.';
            } else {
              final urlPreview = urlToPlay.length > 80 ? '${urlToPlay.substring(0, 80)}...' : urlToPlay;
              errorMsg = 'Errore: ${errorStr.split('\n').first}\n\nURL: $urlPreview';
            }
            _error = errorMsg;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Ferma il player
        try {
          await _player.stop();
        } catch (_) {}
        
        // Se l'API Zappr fallisce e non abbiamo ancora provato il fallback, prova con URL originale
        if (!_hasTriedFallback && _resolvedUrl != null && _resolvedUrl!.contains('zappr.stream')) {
          try {
            await _player.stop();
          } catch (_) {}
          _hasTriedFallback = true;
          await _loadVideo(useOriginalUrl: true);
          return;
        }
        
        // Se abbiamo già provato entrambi, mostra errore definitivo
        if (_hasTriedFallback) {
          setState(() {
            _error = 'Impossibile caricare lo stream.\n\n'
                'Sia l\'API Zappr che l\'URL originale non sono disponibili.\n'
                'Lo stream potrebbe essere offline o richiedere autenticazione.';
            _isLoading = false;
          });
          return;
        }
        
        String errorMsg = 'Errore nel caricamento dello stream';
        final errorStr = e.toString();
        
        if (errorStr.contains('Failed to open')) {
          errorMsg = 'Impossibile aprire lo stream.\n\n'
              'L\'API Zappr potrebbe non essere disponibile.\n'
              'Prova a verificare la connessione o riprova più tardi.';
        } else {
          errorMsg = 'Errore: ${errorStr.split('\n').first}';
        }
        
        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    } finally {
      if (isRetry) {
        _isRetrying = false;
      }
    }
  }

  /// Avvia il timer di timeout per il caricamento
  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(_loadingTimeout, () {
      if (mounted && _isLoading && !_player.state.playing && !_isDisposing) {
        // ignore: avoid_print
        print('PlayerPage: ⏱️ Timeout caricamento raggiunto (${_loadingTimeout.inSeconds}s), mostro placeholder');
        setState(() {
          _showTimeoutPlaceholder = true;
        });
      }
    });
  }
  
  /// Ferma il timer di timeout
  void _stopLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
  }

  @override
  void dispose() {
    // Marca che stiamo disattivando per prevenire operazioni concorrenti
    _isDisposing = true;
    
    // Ferma il timer di timeout
    _stopLoadingTimeout();
    
    // Ripristina l'orientamento verticale quando si esce dal player
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e) {
      // Ignora errori durante il ripristino dell'orientamento
    }
    
    // Ferma e dispose il player con gestione errori robusta
    // IMPORTANTE: Su iOS, dispose del player può causare crash se chiamato durante operazioni FFI
    // Aspettiamo un breve delay per permettere al player di completare le operazioni in corso
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // Stop del player con gestione errori
        if (_player.state.playing || _player.state.loading) {
          await _player.stop();
        }
      } catch (e) {
        // Ignora errori durante lo stop
        // ignore: avoid_print
        print('PlayerPage: ⚠️ Errore durante stop player (ignorato): $e');
      }

      // Dispose del player con timeout e gestione errori più robusta
      try {
        // Aspetta ancora un po' prima di fare dispose per evitare race conditions con FFI
        await Future.delayed(const Duration(milliseconds: 200));
        _player.dispose();
      } catch (e) {
        // Ignora errori durante il dispose (bug noto di media_kit su iOS con FFI callbacks)
        // ignore: avoid_print
        print('PlayerPage: ⚠️ Errore durante dispose player (ignorato): $e');
      }
    });
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          widget.channel.name,
          style: const TextStyle(
            // fontFamily: 'Poppins', // Commentato per risolvere problemi di caricamento font
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_resolvedUrl != null)
            IconButton(
              icon: const Icon(Icons.info_outline, color: AppTheme.textPrimary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    title: const Text('URL Risolto', style: TextStyle(color: AppTheme.textPrimary)),
                    content: SelectableText(
                      _resolvedUrl!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Chiudi'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Video player
              Video(controller: _controller),
              
              // Loading indicator (solo se non c'è timeout placeholder)
              if (_isLoading && !_showTimeoutPlaceholder)
                Container(
                  color: AppTheme.darkBackground,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Caricamento stream...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            // fontFamily: 'Poppins', // Commentato per risolvere problemi di caricamento font
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Placeholder timeout (quando il caricamento impiega troppo tempo)
              if (_showTimeoutPlaceholder && _error == null)
                _buildTimeoutPlaceholder(),
              
              // Error message
              if (_error != null)
                Container(
                  color: AppTheme.darkBackground,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.liveRed,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Errore',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            // fontFamily: 'Poppins', // Commentato per risolvere problemi di caricamento font
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              // fontFamily: 'Poppins', // Commentato per risolvere problemi di caricamento font
                              fontSize: 12,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Reset flags e riprova
                            _hasTriedFallback = false;
                            _isRetrying = false;
                            _error = null;
                            _alternativeGeoLocations = null;
                            _currentGeoLocationIndex = 0;
                            _loadVideo(isRetry: true);
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Riprova'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
  
  /// Ritenta il caricamento con una location geografica diversa
  Future<void> _retryWithDifferentLocation(GeoLocation location) async {
    try {
      // ignore: avoid_print
      print('PlayerPage: [GEOBLOCK_RETRY] Ritento con location: $location');
      
      // Ferma il player corrente
      await _player.stop();
      
      // Risolvi URL con la nuova location
      final proxyResult = await _proxyResolver.resolveGeoblockedUrl(
        widget.channel.streamUrl,
        preferredLocation: location,
        useProxy: false, // Non usare proxy, solo header
        tryMultipleLocations: false, // Non provare altre location, stiamo già facendo retry manuale
      );
      
      // Prepara header per il retry
      final urlToPlay = proxyResult.url;
      final headers = proxyResult.headers;
      
      // Aggiungi header specifici per video
      final isHlsUrl = urlToPlay.contains('.m3u8');
      final isDirectMp4 = urlToPlay.contains('.mp4') && !urlToPlay.contains('.m3u8');
      
      headers.addAll({
        'Accept': isHlsUrl 
            ? 'application/vnd.apple.mpegurl, application/x-mpegURL, */*'
            : isDirectMp4
                ? 'video/mp4, video/*, */*'
                : '*/*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Sec-Fetch-Dest': 'video',
        'Sec-Fetch-Mode': 'no-cors',
        'Sec-Fetch-Site': 'cross-site',
        if (isDirectMp4) ...{
          'Range': 'bytes=0-',
          'Cache-Control': 'no-cache',
        },
      });
      
      // ignore: avoid_print
      print('PlayerPage: [GEOBLOCK_RETRY] Provo a riaprire con location $location...');
      
      // Apri il player con i nuovi header
      await _player.open(
        Media(
          urlToPlay,
          httpHeaders: headers,
        ),
        play: true,
      );
      
      // ignore: avoid_print
      print('PlayerPage: [GEOBLOCK_RETRY] Retry completato con location $location');
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null; // Reset errore durante retry
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('PlayerPage: [GEOBLOCK_RETRY] Retry fallito: $e');
      // Se il retry fallisce, l'errore verrà gestito dal listener degli errori
    }
  }
  
  /// Costruisce il placeholder grafico per timeout/errore
  Widget _buildTimeoutPlaceholder() {
    return Container(
      color: ZapprTokens.bg0, // Nero puro come sfondo
      child: Center(
        child: NeonGlass(
          radius: ZapprTokens.r22,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          margin: const EdgeInsets.all(24),
          glowStrength: 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona con effetto glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ZapprTokens.electricBlueGradient,
                  boxShadow: ZapprTokens.electricBlueGlow(1.0),
                ),
                child: const Icon(
                  Icons.signal_wifi_off_rounded,
                  color: ZapprTokens.textPrimary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              
              // Titolo con gradiente
              ShaderMask(
                shaderCallback: (bounds) => ZapprTokens.electricBlueGradient.createShader(bounds),
                child: const Text(
                  'Canale non disponibile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Messaggio
              Text(
                'in questo momento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ZapprTokens.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              // Pulsante Riprova con stile neon
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ZapprTokens.r12),
                  gradient: ZapprTokens.electricBlueGradient,
                  boxShadow: ZapprTokens.electricBlueGlow(0.6),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _stopLoadingTimeout();
                      setState(() {
                        _showTimeoutPlaceholder = false;
                        _hasTriedFallback = false;
                        _isRetrying = false;
                        _error = null;
                        _alternativeGeoLocations = null;
                        _currentGeoLocationIndex = 0;
                        _errorRetryCount = 0;
                      });
                      _loadVideo(isRetry: true);
                    },
                    borderRadius: BorderRadius.circular(ZapprTokens.r12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            color: ZapprTokens.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Riprova',
                            style: TextStyle(
                              color: ZapprTokens.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Nome canale
              Text(
                widget.channel.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ZapprTokens.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

