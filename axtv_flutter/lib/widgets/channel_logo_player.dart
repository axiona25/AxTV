import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import '../core/http/dio_client.dart';

/// Widget per mostrare il logo del canale nel player
/// Usa fallback multipli come nel listato, ma mostra sempre il logo (non placeholder)
class ChannelLogoPlayer extends StatelessWidget {
  final String? logoUrl;
  final String channelName;
  final double? width;
  final double? height;

  const ChannelLogoPlayer({
    super.key,
    required this.logoUrl,
    required this.channelName,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    final logoWidth = width ?? scaler.s(48);
    final logoHeight = height ?? scaler.s(48);

    if (logoUrl == null || logoUrl!.isEmpty) {
      return _buildPlaceholder(scaler, logoWidth, logoHeight);
    }

    return _ChannelLogoWithFallbacks(
      scaler: scaler,
      logoUrl: logoUrl!,
      channelName: channelName,
      width: logoWidth,
      height: logoHeight,
    );
  }

  Widget _buildPlaceholder(LayoutScaler scaler, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaler.r(10)),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(
          width: 1,
          color: ZapprTokens.neonCyan.withOpacity(0.4),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.tv,
          size: scaler.s(24),
          color: ZapprTokens.neonCyan,
        ),
      ),
    );
  }
}

class _ChannelLogoWithFallbacks extends StatefulWidget {
  final LayoutScaler scaler;
  final String logoUrl;
  final String channelName;
  final double width;
  final double height;

  const _ChannelLogoWithFallbacks({
    required this.scaler,
    required this.logoUrl,
    required this.channelName,
    required this.width,
    required this.height,
  });

  @override
  State<_ChannelLogoWithFallbacks> createState() => _ChannelLogoWithFallbacksState();
}

class _ChannelLogoWithFallbacksState extends State<_ChannelLogoWithFallbacks> {
  final Dio _dio = dioProvider;
  int _currentIndex = 0;
  final List<String> _allUrls = [];

  @override
  void initState() {
    super.initState();
    _buildUrlList();
  }

  void _buildUrlList() {
    // Costruisci lista URL con fallback (stessa logica di channel_tile)
    final baseUrl = widget.logoUrl;
    final slug = widget.channelName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // PRIORITÀ 1: PNG da zappr.stream (più affidabili)
    if (baseUrl != null && baseUrl.isNotEmpty) {
      if (!baseUrl.contains('/it/')) {
        _allUrls.add('https://channels.zappr.stream/logos/it/$slug.png');
        _allUrls.add('https://channels.zappr.stream/logos/it/optimized/$slug.png');
      } else {
        _allUrls.add(baseUrl.replaceAll('.svg', '.png'));
      }
      _allUrls.add('https://channels.zappr.stream/logos/$slug.png');
    } else {
      _allUrls.add('https://channels.zappr.stream/logos/it/$slug.png');
      _allUrls.add('https://channels.zappr.stream/logos/$slug.png');
    }
    
    // PRIORITÀ 2: SVG con /it/
    if (baseUrl != null && baseUrl.isNotEmpty) {
      if (!baseUrl.contains('/it/')) {
        _allUrls.add(baseUrl.replaceAll('/logos/', '/logos/it/'));
      }
    }
    
    // PRIORITÀ 3: SVG originale
    if (baseUrl != null && baseUrl.toLowerCase().endsWith('.svg')) {
      _allUrls.add(baseUrl);
    }
    
    // PRIORITÀ 4: Altri SVG
    if (baseUrl != null && baseUrl.isNotEmpty) {
      final otherSvg = baseUrl.replaceAll('/it/', '/').replaceAll('/optimized/', '/');
      if (otherSvg != baseUrl && otherSvg.toLowerCase().endsWith('.svg')) {
        _allUrls.add(otherSvg);
      }
    }
    
    // Se non ci sono URL, aggiungi almeno quello originale
    if (_allUrls.isEmpty && baseUrl != null) {
      _allUrls.add(baseUrl);
    }
  }

  void _tryNextUrl() {
    if (_currentIndex < _allUrls.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allUrls.isEmpty) {
      return _buildPlaceholder();
    }

    final currentUrl = _allUrls[_currentIndex];
    final isSvg = currentUrl.toLowerCase().endsWith('.svg');

    if (isSvg) {
      // Per SVG, usiamo un widget wrapper che gestisce gli errori
      return _SvgWithErrorHandler(
        url: currentUrl,
        width: widget.width,
        height: widget.height,
        placeholder: _buildPlaceholder(),
        onError: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _tryNextUrl();
            }
          });
        },
      );
    } else {
      return Image.network(
        currentUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _tryNextUrl();
            }
          });
          return _buildPlaceholder();
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.scaler.r(10)),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(
          width: 1,
          color: ZapprTokens.neonCyan.withOpacity(0.4),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.tv,
          size: widget.scaler.s(24),
          color: ZapprTokens.neonCyan,
        ),
      ),
    );
  }
}

/// Widget wrapper per gestire errori SVG
/// SvgPicture.network non ha onError, quindi usiamo un approccio con timer
class _SvgWithErrorHandler extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final Widget placeholder;
  final VoidCallback onError;

  const _SvgWithErrorHandler({
    required this.url,
    required this.width,
    required this.height,
    required this.placeholder,
    required this.onError,
  });

  @override
  State<_SvgWithErrorHandler> createState() => _SvgWithErrorHandlerState();
}

class _SvgWithErrorHandlerState extends State<_SvgWithErrorHandler> {
  bool _hasError = false;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    // Timer per rilevare se l'SVG non si carica entro un certo tempo
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_hasError) {
        // Se dopo 5 secondi non si è caricato, prova il prossimo URL
        setState(() {
          _hasError = true;
        });
        widget.onError();
      }
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.placeholder;
    }

    return SvgPicture.network(
      widget.url,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => widget.placeholder,
    );
  }
}
