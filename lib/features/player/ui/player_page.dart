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

  Future<void> _loadVideo() async {
    try {
      final playable = _resolver.resolvePlayableUrl(widget.channel.streamUrl);
      _resolvedUrl = playable.toString();
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      await _player.open(Media(playable.toString()));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Errore nel caricamento: $e';
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
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.liveRed,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadVideo,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Riprova'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
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

