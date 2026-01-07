import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../channels/model/channel.dart';
import '../../channels/data/stream_resolver.dart';
import '../../../core/theme/app_theme.dart';

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
  
  bool _isLoading = true;
  String? _error;
  String? _resolvedUrl;
  bool _hasTriedFallback = false; // Evita loop infiniti
  bool _isRetrying = false; // Evita retry multipli

  @override
  void initState() {
    super.initState();

    _player = Player();
    _controller = VideoController(_player);

    // Ascolta gli eventi del player
    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isLoading = !playing;
        });
      }
    });

    _player.stream.error.listen((error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    });

    _player.stream.completed.listen((completed) {
      if (mounted && completed) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Risolvi e carica l'URL
    _loadVideo();
  }

  Future<void> _loadVideo({bool useOriginalUrl = false, bool isRetry = false}) async {
    // Evita loop infiniti
    if (_isRetrying && !isRetry) {
      return;
    }
    
    if (isRetry) {
      _isRetrying = true;
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
      } else {
        // Prova prima con risoluzione Zappr (restituisce URL API)
        try {
          final playable = await _resolver.resolvePlayableUrlAsync(widget.channel.streamUrl);
          urlToPlay = playable.toString();
          _resolvedUrl = urlToPlay;
        } catch (e) {
          // Se la risoluzione fallisce, prova con URL originale
          // ignore: avoid_print
          print('PlayerPage: Risoluzione Zappr fallita: $e. Uso URL originale.');
          urlToPlay = widget.channel.streamUrl;
          _resolvedUrl = 'URL originale (fallback): $urlToPlay';
          _hasTriedFallback = true;
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Ferma il player se sta già riproducendo qualcosa
      if (_player.state.playing) {
        await _player.stop();
      }

      // Configura il player con opzioni migliorate
      // Se l'URL è dall'API Zappr, specifica il tipo HLS come fa Video.js
      final isZapprApi = urlToPlay.contains('zappr.stream');
      final isHlsUrl = urlToPlay.contains('.m3u8') || isZapprApi;
      
      try {
        await _player.open(
          Media(
            urlToPlay,
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://zappr.stream/',
              'Accept': '*/*',
              // Se è HLS, aggiungi header specifici
              if (isHlsUrl) 'Accept': 'application/vnd.apple.mpegurl, application/x-mpegURL, */*',
            },
          ),
          play: true,
        );
        
        // Attendi per vedere se parte (5 secondi)
        await Future.delayed(const Duration(seconds: 5));
        
        if (mounted) {
          final isPlaying = _player.state.playing;
          if (!isPlaying && _error == null) {
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
                    'Sia l\'API Zappr che l\'URL originale non sono disponibili.\n'
                    'Lo stream potrebbe essere offline o richiedere autenticazione.';
              } else {
                _error = 'Stream non disponibile.\n\nURL provato: $urlPreview\n\n'
                    'Lo stream potrebbe non essere disponibile o richiedere autenticazione.';
              }
              _isLoading = false;
            });
          } else if (isPlaying) {
            // Funziona! Rimuovi errori e reset flag
            setState(() {
              _isLoading = false;
              _error = null;
              _hasTriedFallback = false; // Reset per permettere retry
            });
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('PlayerPage: Errore nell\'apertura del player: $e');
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
            if (errorStr.contains('Failed to open')) {
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

  @override
  void dispose() {
    _player.dispose();
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
              
              // Loading indicator
              if (_isLoading)
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
}

