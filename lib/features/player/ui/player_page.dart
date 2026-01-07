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

  Future<void> _loadVideo({bool useOriginalUrl = false}) async {
    try {
      String urlToPlay;
      
      if (useOriginalUrl) {
        // Prova con URL originale come fallback
        urlToPlay = widget.channel.streamUrl;
        _resolvedUrl = 'URL originale: $urlToPlay';
      } else {
        // Prova prima con risoluzione Zappr asincrona (segue redirect)
        try {
          final playable = await _resolver.resolvePlayableUrlAsync(widget.channel.streamUrl);
          urlToPlay = playable.toString();
          _resolvedUrl = urlToPlay;
        } catch (e) {
          // Se la risoluzione asincrona fallisce, usa quella sincrona
          final playable = _resolver.resolvePlayableUrl(widget.channel.streamUrl);
          urlToPlay = playable.toString();
          _resolvedUrl = '$urlToPlay (fallback sync)';
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Configura il player con opzioni migliorate
      try {
        await _player.open(
          Media(
            urlToPlay,
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://zappr.stream/',
              'Accept': '*/*',
            },
          ),
          play: true,
        );
        
        // Attendi per vedere se parte (ridotto a 3 secondi)
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted) {
          final isPlaying = _player.state.playing;
          if (!isPlaying && _error == null) {
            // Se l'API Zappr fallisce, prova con URL originale
            if (!useOriginalUrl && urlToPlay.contains('zappr.stream')) {
              // ignore: avoid_print
              print('PlayerPage: API Zappr non ha avviato lo stream, provo con URL originale');
              await _loadVideo(useOriginalUrl: true);
              return;
            }
            
            setState(() {
              final urlPreview = urlToPlay.length > 80 ? '${urlToPlay.substring(0, 80)}...' : urlToPlay;
              _error = 'Stream non disponibile.\n\nURL provato: $urlPreview';
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
              _error = null;
            });
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('PlayerPage: Errore nell\'apertura del player: $e');
        if (mounted) {
          // Se l'API Zappr fallisce, prova con URL originale
          if (!useOriginalUrl && urlToPlay.contains('zappr.stream')) {
            // ignore: avoid_print
            print('PlayerPage: Errore con API Zappr, provo con URL originale');
            await _loadVideo(useOriginalUrl: true);
            return;
          }
          
          setState(() {
            final urlPreview = urlToPlay.length > 80 ? '${urlToPlay.substring(0, 80)}...' : urlToPlay;
            _error = 'Errore nell\'apertura dello stream: $e\n\nURL provato: $urlPreview';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Se l'API Zappr fallisce, prova con URL originale come fallback
        if (!useOriginalUrl && _resolvedUrl != null && _resolvedUrl!.contains('zappr.stream')) {
          await _loadVideo(useOriginalUrl: true);
          return;
        }
        
        String errorMsg = 'Errore nel caricamento';
        final errorStr = e.toString();
        
        if (errorStr.contains('Failed to open')) {
          errorMsg = 'Impossibile aprire lo stream.\n\n'
              'L\'API Zappr potrebbe non essere disponibile.\n'
              'URL tentato: ${_resolvedUrl ?? widget.channel.streamUrl}';
        } else {
          errorMsg = 'Errore: ${errorStr.split('\n').first}';
        }
        
        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
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
            fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
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
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadVideo,
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

