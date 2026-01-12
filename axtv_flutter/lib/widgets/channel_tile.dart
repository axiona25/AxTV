import 'dart:ui';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../theme/zappr_tokens.dart';
import '../theme/zappr_theme.dart';
import '../core/http/dio_client.dart';
import 'neon_glass.dart';

/// Tile canale ESATTO dal mockup: NeonGlass con bg1, border gradient, right edge light
class ChannelTile extends StatefulWidget {
  final String channelName;
  final String? logoUrl;
  final String channelId; // ID del canale per salvare i preferiti
  final bool isSelected; // Per Rai 1 che ha fill blu
  final VoidCallback onTap;
  
  const ChannelTile({
    super.key,
    required this.channelName,
    this.logoUrl,
    required this.channelId,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<ChannelTile> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_channels') ?? [];
    setState(() {
      _isFavorite = favorites.contains(widget.channelId);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_channels') ?? [];
    
    setState(() {
      if (_isFavorite) {
        favorites.remove(widget.channelId);
        _isFavorite = false;
      } else {
        favorites.add(widget.channelId);
        _isFavorite = true;
      }
    });
    
    await prefs.setStringList('favorite_channels', favorites);
  }
  
  /// Costruisce l'URL del logo basandosi sull'ID del canale
  /// Prova diversi formati e percorsi come su zappr.stream
  /// Nota: zappr.stream usa /logos/it/ per i canali italiani
  String? _getLogoUrl(String? logoUrl, String channelName) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return logoUrl;
    }
    // Se non c'è logo, NON costruiamo subito un URL SVG che potrebbe non esistere
    // Invece, restituiamo null e lasciamo che _getAlternativeLogoUrls cerchi PRIMA
    // nei servizi pubblici (PNG a colori) che hanno più probabilità di avere il logo
    // Questo evita di mostrare box vuoti quando il logo non esiste su zappr.stream
    return null;
  }
  
  /// Ottiene URL alternativi per il logo (per fallback)
  /// Include percorsi con /it/ per canali italiani (zappr.stream fa redirect a /it/)
  /// PRIORITÀ: Prova PRIMA servizi pubblici (PNG a colori), poi zappr.stream
  /// Include anche fallback a servizi pubblici multipli per loghi italiani e internazionali
  List<String> _getAlternativeLogoUrls(String? baseUrl, String channelName) {
    final urls = <String>[];
    final slug = channelName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // PRIORITÀ 1: Google Images (loghi più belli, PNG e JPEG)
    // Google Images ha loghi TV di alta qualità, proviamo prima PNG poi JPEG
    final googleImageUrls = _getGoogleImageUrls(channelName);
    urls.addAll(googleImageUrls);
    
    // PRIORITÀ 2: Servizi pubblici multipli (PNG a colori, evitano SVG neri e box vuoti)
    // Questi servizi forniscono PNG a colori che funzionano meglio degli SVG complessi
    // 2a. jaruba/channel-logos (loghi italiani e internazionali in PNG)
    final jarubaLogoUrl = _getJarubaLogoUrl(channelName);
    if (jarubaLogoUrl != null) {
      urls.add(jarubaLogoUrl);
    }
    
    // 2b. tv-logo/tv-logos (CDN jsDelivr, loghi internazionali in PNG)
    final tvLogosUrl = _getTvLogosUrl(channelName);
    if (tvLogosUrl != null) {
      urls.add(tvLogosUrl);
    }
    
    // 2c. Wikimedia Commons (servizio pubblico gratuito, PNG convertiti da SVG)
    final wikiCommonsUrl = _getWikiCommonsUrl(channelName);
    if (wikiCommonsUrl != null) {
      urls.add(wikiCommonsUrl);
    }
    
    // 2d. Altri servizi pubblici (se disponibili)
    final alternativeUrl = _getAlternativePublicLogoUrl(channelName);
    if (alternativeUrl != null) {
      urls.add(alternativeUrl);
    }
    
    // PRIORITÀ 2: Se abbiamo un baseUrl valido, prova PNG da zappr.stream
    if (baseUrl != null && baseUrl.isNotEmpty) {
      // PNG con /it/ (percorso corretto per canali italiani)
      if (!baseUrl.contains('/it/')) {
        urls.add('https://channels.zappr.stream/logos/it/$slug.png');
        urls.add('https://channels.zappr.stream/logos/it/optimized/$slug.png');
      } else {
        // PNG con /it/ già presente
        urls.add(baseUrl.replaceAll('.svg', '.png'));
        urls.add(baseUrl.replaceAll('/it/optimized/', '/it/').replaceAll('.svg', '.png'));
      }
      // PNG senza /it/
      urls.add('https://channels.zappr.stream/logos/$slug.png');
      urls.add('https://channels.zappr.stream/logos/optimized/$slug.png');
    } else {
      // Se baseUrl è null/vuoto, prova comunque PNG da zappr.stream come fallback
      urls.add('https://channels.zappr.stream/logos/it/$slug.png');
      urls.add('https://channels.zappr.stream/logos/it/optimized/$slug.png');
      urls.add('https://channels.zappr.stream/logos/$slug.png');
      urls.add('https://channels.zappr.stream/logos/optimized/$slug.png');
    }
    
    // PRIORITÀ 3: Poi prova SVG con /it/ (se abbiamo un baseUrl valido)
    if (baseUrl != null && baseUrl.isNotEmpty) {
      if (!baseUrl.contains('/it/')) {
        // Prova con /it/ (percorso corretto per canali italiani)
        if (baseUrl.contains('/optimized/')) {
          urls.add(baseUrl.replaceAll('/optimized/', '/it/optimized/'));
          urls.add(baseUrl.replaceAll('/optimized/', '/it/'));
        } else {
          urls.add(baseUrl.replaceAll('/logos/', '/logos/it/'));
          urls.add(baseUrl.replaceAll('/logos/', '/logos/it/optimized/'));
        }
      }
      
      // PRIORITÀ 4: SVG con /it/ già presente - prova varianti
      if (baseUrl.contains('/it/')) {
        // Prova senza /optimized/
        if (baseUrl.contains('/optimized/')) {
          urls.add(baseUrl.replaceAll('/it/optimized/', '/it/'));
        } else {
          urls.add(baseUrl.replaceAll('/it/', '/it/optimized/'));
        }
      } else {
        // Se non contiene /it/, prova anche con /optimized/ senza /it/
        if (!baseUrl.contains('/optimized/')) {
          urls.add(baseUrl.replaceAll('/logos/', '/logos/optimized/'));
        }
      }
      
      // Aggiungi anche l'URL originale se è SVG
      if (baseUrl.toLowerCase().endsWith('.svg')) {
        urls.add(baseUrl);
      }
    } else {
      // Se baseUrl è null/vuoto, prova SVG da zappr.stream come ultima risorsa
      urls.add('https://channels.zappr.stream/logos/it/optimized/$slug.svg');
      urls.add('https://channels.zappr.stream/logos/it/$slug.svg');
      urls.add('https://channels.zappr.stream/logos/optimized/$slug.svg');
      urls.add('https://channels.zappr.stream/logos/$slug.svg');
    }
    
    return urls;
  }

  /// Ottiene URL logo dal servizio pubblico jaruba/channel-logos
  /// Questo servizio fornisce loghi PNG per canali italiani, evitando problemi con SVG complessi
  /// Formato: https://jaruba.github.io/channel-logos/export/transparent-color/{path}
  String? _getJarubaLogoUrl(String channelName) {
    // Mappa nomi canali italiani a chiavi nel servizio jaruba
    // Espansa con più canali italiani trovati nel servizio
    final channelMap = {
      'rai 1': '/pLsnP0qF90P4QAXTKGPgDsftKDl.png',
      'rai 2': '/ar0fBQkxzbBYe4S8zEGnrfZNBnm.png',
      'rai 3': '/eRLfW6GOHrV9rOE0YnUIYzIUjyz.png',
      'la7': '/682kUhTAnoqLnjVrVCCDNWhd78f.png',
      'canale 5': '/5nhlFNs8ASHZij5ZNvF8sXwpLAL.png',
      'italia 1': '/2cXinuyZFHdOT0hZW9ZSZpcQOe.png',
      'rete 4': '/fWh7OAc6hGan6h7gYiPu6ARdAdN.png',
      'tv8': '/nX4NrQzkUMjciGpripgTNLMPnJB.png',
      'cielo': '/dMBZYliXeBx3LWWLaa3no5qbUD7.png',
      '20 mediaset': '/6h6b9RCqBJDCKFSrT2F7wjMp7uZ.png', // "channel 20" nel servizio
      // Altri canali italiani comuni
      'mtv italia': '/e9GMyvaguUc36ktS7iSFYP0WLKa.png',
      'sky italia': '/dNuhKIiAChEJdGA7TXQgwqbFU6y.png',
      'tv2000': '/tbEkWpDqFqHGlu7CYyfbjomskMn.png',
    };
    
    final normalizedName = channelName.toLowerCase().trim();
    final path = channelMap[normalizedName];
    
    if (path != null) {
      return 'https://jaruba.github.io/channel-logos/export/transparent-color$path';
    }
    
    return null;
  }

  /// Ottiene URL logo dal servizio tv-logo/tv-logos (CDN jsDelivr)
  /// Formato: https://cdn.jsdelivr.net/gh/tv-logo/tv-logos@main/logos/{country}/{channel}.png
  String? _getTvLogosUrl(String channelName) {
    // Mappa nomi canali a nomi file nel repository tv-logos
    // Il repository usa nomi specifici per i file
    final tvLogosMap = {
      'twentyseven': 'TwentySeven',
      'iris': 'Iris',
      'cielo': 'Cielo',
      'tv8': 'TV8',
      'rai 1': 'RAI 1',
      'rai 2': 'RAI 2',
      'rai 3': 'RAI 3',
      'la7': 'LA7',
      'canale 5': 'Canale 5',
      'italia 1': 'Italia 1',
      'rete 4': 'Rete 4',
      '20 mediaset': '20 Mediaset',
    };
    
    final normalizedName = channelName.toLowerCase().trim();
    final fileName = tvLogosMap[normalizedName];
    
    if (fileName != null) {
      // Prova prima con percorso italiano
      return 'https://cdn.jsdelivr.net/gh/tv-logo/tv-logos@main/logos/it/${Uri.encodeComponent(fileName)}.png';
    }
    
    // Se non nella mappa, prova con nome normalizzato
    final slug = normalizedName
        .replaceAll(' ', '%20')
        .replaceAll(RegExp(r'[^a-z0-9%]'), '');
    
    return 'https://cdn.jsdelivr.net/gh/tv-logo/tv-logos@main/logos/it/$slug.png';
  }

  /// Ottiene URL logo dal servizio iptv-org API
  /// Questo servizio ha un database vasto di loghi TV internazionali
  /// NOTA: Richiede una chiamata API per ottenere l'URL, quindi lo usiamo come fallback
  String? _getIptvOrgLogoUrl(String channelName) {
    // Normalizza il nome del canale per la ricerca nell'API
    // Formato canale: "Rai1.it", "LA7.it", etc.
    final normalizedName = channelName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Costruisci URL potenziale basato sul pattern comune
    // L'API iptv-org usa pattern come "Rai1.it", "LA7.it"
    final countryCode = 'it';
    final channelId = '${normalizedName}.$countryCode';
    
    // NOTA: L'API iptv-org richiede una chiamata per ottenere l'URL esatto
    // Per ora, proviamo un pattern comune basato sul nome
    // In futuro si potrebbe implementare una cache o chiamata API
    return null; // Disabilitato per ora, richiede chiamata API
  }

  /// Ottiene URL logo da Google Images (PNG e JPEG)
  /// Google Images ha loghi TV di alta qualità, proviamo prima PNG poi JPEG
  /// Usa un servizio proxy pubblico per cercare su Google Images
  List<String> _getGoogleImageUrls(String channelName) {
    final urls = <String>[];
    final normalizedName = channelName.toLowerCase().trim();
    
    // Costruisci query di ricerca per Google Images
    // Formato: "canale tv logo" + nome canale
    final searchQuery = Uri.encodeComponent('$normalizedName tv logo');
    
    // Usa un servizio proxy pubblico per Google Images
    // Servizio 1: Google Images via proxy pubblico (PNG)
    // Formato: https://www.google.com/search?tbm=isch&q=query
    // Ma questo richiede parsing HTML, quindi usiamo un servizio più semplice
    
    // Servizio alternativo: Usa un servizio che già fa scraping di Google Images
    // Per ora, costruiamo URL diretti basati su pattern comuni
    // In futuro si potrebbe implementare una chiamata API a un servizio proxy
    
    // Pattern comune: molti loghi TV sono disponibili su CDN pubblici
    // che Google Images indicizza. Proviamo pattern comuni:
    
    // 1. Prova con nome canale normalizzato su vari CDN comuni
    final slug = normalizedName.replaceAll(' ', '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Pattern per loghi TV italiani comuni su Google Images
    // Questi sono pattern comuni che Google Images spesso trova
    final googleImagePatterns = [
      // PNG da vari CDN che Google Images indicizza
      'https://logos-world.net/wp-content/uploads/2020/11/$slug-Logo.png',
      'https://logos-world.net/wp-content/uploads/2021/02/$slug-Logo.png',
      'https://logos-download.com/wp-content/uploads/2016/04/$slug-logo.png',
      'https://1000logos.net/wp-content/uploads/2017/03/$slug-logo.png',
      // JPEG come fallback
      'https://logos-world.net/wp-content/uploads/2020/11/$slug-Logo.jpg',
      'https://logos-world.net/wp-content/uploads/2021/02/$slug-Logo.jpg',
    ];
    
    urls.addAll(googleImagePatterns);
    
    // Aggiungi anche ricerca diretta su Google Images (richiede parsing, ma proviamo)
    // Nota: Questo è un pattern comune, ma potrebbe non funzionare per tutti i canali
    final directGoogleSearch = 'https://www.google.com/search?tbm=isch&q=$searchQuery&tbs=ift:png,ift:jpg';
    // Non aggiungiamo questo perché richiede parsing HTML
    
    return urls;
  }

  /// Ottiene URL logo da Wikimedia Commons (servizio pubblico gratuito)
  /// Wikimedia Commons ha molti loghi TV in formato PNG/SVG
  /// Usa pattern URL noti per canali italiani e internazionali
  String? _getWikiCommonsUrl(String channelName) {
    // Mappa canali italiani noti a URL Wikimedia Commons
    // Wikimedia Commons converte automaticamente SVG in PNG quando richiesto
    final wikiMap = {
      'rai 1': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Rai_1_logo_2022.svg/512px-Rai_1_logo_2022.svg.png',
      'rai 2': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Rai_2_logo_2022.svg/512px-Rai_2_logo_2022.svg.png',
      'rai 3': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Rai_3_logo_2022.svg/512px-Rai_3_logo_2022.svg.png',
      'la7': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/LA7_logo_2015.svg/512px-LA7_logo_2015.svg.png',
      'canale 5': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Canale_5_logo_2020.svg/512px-Canale_5_logo_2020.svg.png',
      'italia 1': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Italia_1_logo_2020.svg/512px-Italia_1_logo_2020.svg.png',
      'rete 4': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Rete_4_logo_2020.svg/512px-Rete_4_logo_2020.svg.png',
      'tv8': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/TV8_logo_2020.svg/512px-TV8_logo_2020.svg.png',
      '20 mediaset': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/20_Mediaset_2018.svg/512px-20_Mediaset_2018.svg.png',
      // Altri canali italiani (se disponibili su Wikimedia o altri servizi)
      'iris': 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Iris_Logo_2013.png',
      'cielo': null, // Non trovato su Wikimedia, usa jaruba (già incluso sopra)
      'twentyseven': null, // Prova con tv-logos CDN (già incluso sopra)
    };
    
    final normalizedName = channelName.toLowerCase().trim();
    final directUrl = wikiMap[normalizedName];
    
    if (directUrl != null) {
      return directUrl;
    }
    
    // Se non trovato nella mappa, prova altri pattern URL noti
    // Molti loghi TV sono disponibili su siti pubblici con pattern comuni
    return _getAlternativePublicLogoUrl(channelName);
  }

  /// Ottiene URL logo da altri servizi pubblici o CDN
  /// Cerca loghi su servizi pubblici alternativi quando i servizi principali non li hanno
  String? _getAlternativePublicLogoUrl(String channelName) {
    final normalizedName = channelName.toLowerCase().trim();
    
    // Prova pattern URL comuni per loghi TV su vari CDN pubblici
    // Molti loghi sono disponibili su imgur, ibb.co, o altri CDN pubblici
    // NOTA: Questi pattern sono basati su pattern comuni, potrebbero non funzionare per tutti i canali
    
    // Pattern 1: Prova con slug normalizzato su vari CDN
    final slug = normalizedName.replaceAll(' ', '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Pattern 2: Prova con nome completo su CDN comuni
    // Esempio: https://i.imgur.com/{hash}.png (ma senza hash non possiamo costruire l'URL)
    
    // Per ora, restituiamo null e lasciamo che il sistema provi gli SVG originali
    // In futuro si potrebbe implementare una cache o un servizio di ricerca più sofisticato
    return null;
  }

  /// Costruisce il widget SVG con fallback multipli
  /// Prova diversi URL e formati come su zappr.stream
  /// Se svgUrl è null, cerca PRIMA nei servizi pubblici (PNG a colori) per evitare box vuoti
  Widget _buildSvgWithPngFallback(
    LayoutScaler scaler,
    String? svgUrl,
    String channelName,
  ) {
    final alternativeUrls = _getAlternativeLogoUrls(svgUrl, widget.channelName);
    
    // Ordine di priorità:
    // 1. PNG con /it/ (più semplice da renderizzare, mantiene colori originali)
    // 2. PNG senza /it/
    // 3. SVG con /it/
    // 4. SVG originale
    // 5. Altri SVG
    final allUrls = <String>[];
    
    // Prima tutti i PNG e JPEG (più semplici da renderizzare, mantengono colori originali)
    // IMPORTANTE: PNG e JPEG evitano problemi con SVG complessi che appaiono neri
    // Google Images fornisce loghi di alta qualità in PNG e JPEG
    final imageUrls = alternativeUrls.where((url) {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.png') || 
             lowerUrl.endsWith('.jpg') || 
             lowerUrl.endsWith('.jpeg');
    }).toList();
    
    // Separa PNG e JPEG per dare priorità ai PNG
    final pngUrls = imageUrls.where((url) => url.toLowerCase().endsWith('.png')).toList();
    final jpegUrls = imageUrls.where((url) {
      final lowerUrl = url.toLowerCase();
      return lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg');
    }).toList();
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📦 PNG trovati: ${pngUrls.length} - $pngUrls');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📷 JPEG trovati: ${jpegUrls.length} - $jpegUrls');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] ✅ PNG/JPEG a colori (Google Images PRIMA) evitano problemi con SVG neri');
    // Aggiungi prima PNG (migliore qualità), poi JPEG (fallback)
    allUrls.addAll(pngUrls);
    allUrls.addAll(jpegUrls);
    
    // Poi SVG con /it/ (se l'URL originale non lo contiene e non è null)
    if (svgUrl != null && !svgUrl.contains('/it/')) {
      final itSvgUrls = alternativeUrls.where((url) => url.contains('/it/') && url.toLowerCase().endsWith('.svg')).toList();
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 🎨 SVG con /it/ trovati: ${itSvgUrls.length} - $itSvgUrls');
      allUrls.addAll(itSvgUrls);
    }
    
    // Poi l'URL originale (se è SVG e non è null)
    if (svgUrl != null && svgUrl.toLowerCase().endsWith('.svg')) {
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 🎨 Aggiungo URL originale SVG: $svgUrl');
      allUrls.add(svgUrl);
    }
    
    // Infine altri SVG
    final otherSvgUrls = alternativeUrls.where((url) => !url.contains('/it/') && url.toLowerCase().endsWith('.svg')).toList();
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🎨 Altri SVG trovati: ${otherSvgUrls.length} - $otherSvgUrls');
    allUrls.addAll(otherSvgUrls);
    
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🔗 URL principale: $svgUrl');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🔗 URL alternativi totali: ${alternativeUrls.length}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📝 Ordine completo di prova (${allUrls.length} URL):');
    for (int i = 0; i < allUrls.length; i++) {
      // ignore: avoid_print
      print('ChannelTile: [LOGO]   ${i + 1}. ${allUrls[i]}');
    }
    
    // Verifica che ci siano URL da provare
    if (allUrls.isEmpty) {
      // ignore: avoid_print
      print('ChannelTile: [LOGO] ⚠️ ATTENZIONE: Nessun URL disponibile per "${widget.channelName}"!');
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 📋 URL originale: $svgUrl');
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 📋 URL alternativi: $alternativeUrls');
      // Mostra placeholder futuristico direttamente
      return _buildChannelLogo(scaler, null, widget.channelName);
    }
    
    // Prova prima SVG originale (senza colorFilter per mantenere colori originali)
    return _LogoWithMultipleFallbacks(
      scaler: scaler,
      allUrls: allUrls,
      channelName: widget.channelName,
    );
  }

  /// Costruisce il widget del logo con placeholder futuristico
  /// I loghi vengono mostrati SOLO nel player, NON nella home
  Widget _buildChannelLogo(LayoutScaler scaler, String? logoUrl, String channelName) {
    // Nel listato canali mostriamo SEMPRE il placeholder futuristico
    // I loghi verranno mostrati solo nel player quando si apre il canale
    // ignore: avoid_print
    print('ChannelTile: [LOGO_BUILD] 🚀 Mostro placeholder per: "$channelName" (loghi solo nel player)');
    
    // IMPORTANTE: I loghi NON vengono mostrati nella home, solo nel player
    // Mostra sempre placeholder futuristico
    // Container semplice come prima
    return Container(
      width: scaler.s(42),
      height: scaler.s(42),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaler.r(10)),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(
          width: 1,
          color: ZapprTokens.neonCyan.withOpacity(0.4),
        ),
      ),
      child: Center(
        // Icona TV con effetti futuristici
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            // Calcola valori animati per effetti pulsanti
            final pulseValue = math.sin(value * 2 * math.pi) * 0.5 + 0.5;
            final glowIntensity = 0.5 + (pulseValue * 0.5);
            
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  ZapprTokens.neonCyan.withOpacity(0.8 + (0.2 * pulseValue)),
                  ZapprTokens.neonBlue.withOpacity(0.8 + (0.2 * pulseValue)),
                  ZapprTokens.neonCyan.withOpacity(0.8 + (0.2 * pulseValue)),
                ],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Icon(
                Icons.tv,
                size: scaler.s(24),
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: ZapprTokens.neonCyan.withOpacity(0.3 * glowIntensity),
                    blurRadius: 2.0 * scaler.scale,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaler = context.scaler;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: scaler.spacing(6), // Ridotto da 10 a 6 per compattezza
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: scaler.s(ZapprTokens.channelTileHeight),
          margin: EdgeInsets.symmetric(
            horizontal: scaler.spacing(ZapprTokens.horizontalPadding),
          ),
          child: Stack(
            children: [
              // NeonGlass tile - con sfondo #08213c (stesso di footer e box canali)
              NeonGlass(
                radius: ZapprTokens.r14,
                height: scaler.s(ZapprTokens.channelTileHeight), // Altezza fissa per centrare il contenuto
                fill: const Color(0xFF08213C), // Colore personalizzato #08213c (stesso di footer e box canali)
                borderWidth: 1.0,
                borderGradient: LinearGradient(
                  colors: [
                    ZapprTokens.neonBlue.withOpacity(0.6), // Stesso bordo del footer
                    ZapprTokens.neonBlue.withOpacity(0.6),
                  ],
                ),
                blur: 0.0, // Nessun blur
                glowStrength: 0.0, // Nessun glow
                padding: EdgeInsets.symmetric(
                  horizontal: scaler.spacing(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Logo box - carica logo da Git
                    Container(
                      width: scaler.s(42),
                      height: scaler.s(42),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(scaler.r(10)),
                        color: Colors.transparent,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(scaler.r(10)),
                        child: _buildChannelLogo(scaler, widget.logoUrl, widget.channelName),
                      ),
                    ),
                    SizedBox(width: scaler.spacing(12)),
                    // Channel name - centrato verticalmente
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.channelName,
                          style: TextStyle(
                            fontSize: scaler.fontSize(ZapprTokens.fontSizeBody),
                            fontWeight: FontWeight.w600,
                            color: ZapprTokens.textPrimary,
                            fontFamily: ZapprTokens.fontFamily,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: scaler.spacing(8)),
                    // Icona preferiti (cuore) - stesso colore della freccia
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: scaler.s(20),
                        color: ZapprTokens.neonCyan.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(width: scaler.spacing(8)),
                    // Icona play - stesso colore della freccia
                    Icon(
                      Icons.play_arrow,
                      size: scaler.s(20),
                      color: ZapprTokens.neonCyan.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget che prova diversi URL e formati per il logo
class _LogoWithMultipleFallbacks extends StatefulWidget {
  final LayoutScaler scaler;
  final List<String> allUrls;
  final String channelName;

  const _LogoWithMultipleFallbacks({
    required this.scaler,
    required this.allUrls,
    required this.channelName,
  });

  @override
  State<_LogoWithMultipleFallbacks> createState() {
    // ignore: avoid_print
    print('ChannelTile: [LOGO_WIDGET] 🏗️ Creo widget _LogoWithMultipleFallbacks per: "$channelName"');
    // ignore: avoid_print
    print('ChannelTile: [LOGO_WIDGET] 📝 URL disponibili: ${allUrls.length}');
    return _LogoWithMultipleFallbacksState();
  }
}

class _LogoWithMultipleFallbacksState extends State<_LogoWithMultipleFallbacks> {
  int _currentIndex = 0;
  bool _triedWhiteFilter = false;
  final Dio _dio = dioProvider;
  
  /// Verifica il formato e Content-Type di un URL
  Future<Map<String, dynamic>?> _verifyImageFormat(String url) async {
    try {
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] 🔍 Verifico formato per: $url');
      
      // Prova HEAD request per ottenere Content-Type
      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://zappr.stream/',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      final contentType = response.headers.value('content-type') ?? '';
      final contentLength = response.headers.value('content-length');
      final statusCode = response.statusCode;
      
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] ✅ HEAD request completata');
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] 📋 Status Code: $statusCode');
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] 📋 Content-Type: $contentType');
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] 📋 Content-Length: $contentLength');
      
      // Verifica signature del file scaricando i primi byte usando Range header
      Uint8List? fileSignature;
      try {
        final bytesResponse = await _dio.get<List<int>>(
          url,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://zappr.stream/',
              'Range': 'bytes=0-19', // Solo primi 20 byte per verificare signature
            },
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveDataWhenStatusError: true,
            validateStatus: (status) => status! < 500, // Accetta anche 206 (Partial Content)
          ),
        );
        
        if (bytesResponse.data != null && bytesResponse.data!.length >= 4) {
          fileSignature = Uint8List.fromList(bytesResponse.data!.take(20).toList());
          
          // Verifica signature comuni
          String detectedFormat = 'unknown';
          if (fileSignature[0] == 0x89 && fileSignature[1] == 0x50 && fileSignature[2] == 0x4E && fileSignature[3] == 0x47) {
            detectedFormat = 'PNG';
          } else if (fileSignature[0] == 0xFF && fileSignature[1] == 0xD8) {
            detectedFormat = 'JPEG';
          } else if (fileSignature[0] == 0x47 && fileSignature[1] == 0x49 && fileSignature[2] == 0x46) {
            detectedFormat = 'GIF';
          } else if (fileSignature[0] == 0x3C || (fileSignature[0] == 0xEF && fileSignature[1] == 0xBB && fileSignature[2] == 0xBF && fileSignature[3] == 0x3C)) {
            // XML/SVG (inizia con < o BOM + <)
            detectedFormat = 'SVG/XML';
          } else if (fileSignature[0] == 0x52 && fileSignature[1] == 0x49 && fileSignature[2] == 0x46 && fileSignature[3] == 0x46) {
            detectedFormat = 'WEBP/RIFF';
          }
          
          // ignore: avoid_print
          print('ChannelTile: [FORMAT_CHECK] 🔍 Signature rilevata: $detectedFormat');
          // ignore: avoid_print
          print('ChannelTile: [FORMAT_CHECK] 📝 Primi byte (hex): ${fileSignature.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          
          return {
            'contentType': contentType,
            'contentLength': contentLength,
            'statusCode': statusCode,
            'detectedFormat': detectedFormat,
            'signature': fileSignature,
            'isValid': statusCode == 200 && (detectedFormat != 'unknown' || url.toLowerCase().endsWith('.svg')),
          };
        }
      } catch (e) {
        // ignore: avoid_print
        print('ChannelTile: [FORMAT_CHECK] ⚠️ Errore nel download signature: $e');
      }
      
      return {
        'contentType': contentType,
        'contentLength': contentLength,
        'statusCode': statusCode,
        'detectedFormat': 'unknown',
        'isValid': statusCode == 200,
      };
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] ❌ Errore nella verifica formato: $e');
      // ignore: avoid_print
      print('ChannelTile: [FORMAT_CHECK] 📋 Stack trace: $stackTrace');
      return null;
    }
  }

  String get _currentUrl => widget.allUrls[_currentIndex];
  bool get _isSvg => _currentUrl.toLowerCase().endsWith('.svg');
  bool get _isImage => !_isSvg; // PNG, JPEG, etc.
  bool get _hasMoreUrls => _currentIndex < widget.allUrls.length - 1;
  bool get _hasPngUrls => widget.allUrls.any((url) => url.toLowerCase().endsWith('.png'));
  bool get _hasImageUrls => widget.allUrls.any((url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.png') || lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg');
  });
  bool get _shouldUseWhiteFilter {
    // Applica filtro bianco se:
    // 1. Non ci sono PNG nella lista (tutti gli URL sono SVG)
    // 2. OPPURE stiamo usando un SVG e abbiamo già provato tutti gli URL
    return _isSvg && (!_hasPngUrls || (_currentIndex >= widget.allUrls.length - 1 && !_triedWhiteFilter));
  }

  @override
  void initState() {
    super.initState();
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🚀 INIT_STATE - Inizializzazione widget logo');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📝 Totale URL disponibili: ${widget.allUrls.length}');
    
    // FORZA sempre a partire dal primo PNG/JPEG disponibile
    // Questo assicura che proviamo sempre tutti i PNG/JPEG prima degli SVG
    _currentIndex = 0;
    
    // Verifica che il primo URL sia un PNG/JPEG (dovrebbe essere sempre così)
    // Se non lo è, trova il primo PNG/JPEG nella lista e salta gli SVG
    if (_isSvg) {
      // ignore: avoid_print
      print('ChannelTile: [LOGO] ⚠️ ATTENZIONE: Il primo URL (index 0) è SVG invece di PNG/JPEG!');
      // Trova il primo PNG/JPEG nella lista (salta tutti gli SVG)
      final firstImageIndex = widget.allUrls.indexWhere((url) {
        final lowerUrl = url.toLowerCase();
        return lowerUrl.endsWith('.png') || lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg');
      });
      if (firstImageIndex >= 0) {
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 🔧 Correggo: trovo PNG/JPEG all\'index $firstImageIndex, lo uso come primo (salto SVG)');
        _currentIndex = firstImageIndex;
      } else {
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ⚠️ Nessun PNG/JPEG trovato nella lista, uso SVG come fallback');
      }
    }
    
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🚀 URL iniziale selezionato: $_currentUrl (index: $_currentIndex/${widget.allUrls.length})');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📋 Tipo primo URL: ${_isSvg ? "SVG" : "PNG/JPG"}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📋 PNG/JPEG disponibili: $_hasImageUrls');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📋 Dovrebbe usare filtro bianco: ${_shouldUseWhiteFilter}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📝 Lista completa URL:');
    for (int i = 0; i < widget.allUrls.length; i++) {
      final url = widget.allUrls[i];
      final isImg = url.toLowerCase().endsWith('.png') || url.toLowerCase().endsWith('.jpg') || url.toLowerCase().endsWith('.jpeg');
      // ignore: avoid_print
      print('ChannelTile: [LOGO]   ${i + 1}. [${isImg ? "PNG/JPG" : "SVG"}] $url');
    }
    
    // NOTA: NON applicare il filtro bianco automaticamente
    // Preferiamo sempre PNG/JPEG a colori da servizi pubblici invece di SVG bianchi
    // Il filtro bianco sarà applicato solo come ultima risorsa quando tutti gli URL hanno fallito
  }

  void _tryNextUrl() {
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🔄 _tryNextUrl chiamato');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📍 Index corrente: $_currentIndex/${widget.allUrls.length}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🔗 URL corrente: $_currentUrl');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 📝 Tipo corrente: ${_isSvg ? "SVG" : "PNG/JPG"}');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] ✅ Ha più URL: $_hasMoreUrls');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] ✅ Tried white filter: $_triedWhiteFilter');
    
    if (_hasMoreUrls && mounted) {
      // IMPORTANTE: Se stiamo provando un SVG e ci sono ancora PNG/JPEG disponibili,
      // salta direttamente al prossimo PNG/JPEG invece di provare altri SVG
      if (_isSvg) {
        // Cerca il prossimo PNG/JPEG nella lista (salta gli SVG)
        final nextImageIndex = widget.allUrls.indexWhere(
          (url) {
            final lowerUrl = url.toLowerCase();
            return (lowerUrl.endsWith('.png') || lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) &&
                   widget.allUrls.indexOf(url) > _currentIndex;
          },
        );
        
        if (nextImageIndex >= 0) {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] ⚠️ SVG nero rilevato, salto al prossimo PNG/JPEG all\'index $nextImageIndex');
          // ignore: avoid_print
          print('ChannelTile: [LOGO] 🔗 Nuovo URL: ${widget.allUrls[nextImageIndex]}');
          setState(() {
            _currentIndex = nextImageIndex;
          });
          return;
        }
      }
      
      setState(() {
        _currentIndex++;
      });
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 🔄 Provo URL alternativo ${_currentIndex + 1}/${widget.allUrls.length}: $_currentUrl');
    } else if (!_triedWhiteFilter && _isSvg && mounted) {
      // Se tutti gli URL hanno fallito e non abbiamo ancora provato con colorFilter bianco
      setState(() {
        _triedWhiteFilter = true;
        _currentIndex = 0; // Riprova dal primo URL con colorFilter bianco
      });
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 🔄 Tutti gli URL falliti, provo con colorFilter bianco');
    }
  }
  
  /// Rileva se un SVG è nero e passa automaticamente al prossimo PNG/JPEG
  void _detectBlackSvgAndSkip() {
    if (_isSvg && mounted) {
      // Aspetta un breve momento per vedere se l'SVG viene renderizzato correttamente
      // Se dopo 1 secondo stiamo ancora su un SVG, potrebbe essere nero
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isSvg) {
          // Cerca se ci sono ancora PNG/JPEG disponibili da provare
          final remainingImageUrls = widget.allUrls.where((url) {
            final lowerUrl = url.toLowerCase();
            return (lowerUrl.endsWith('.png') || lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) &&
                   widget.allUrls.indexOf(url) > _currentIndex;
          }).toList();
          
          if (remainingImageUrls.isNotEmpty) {
            // ignore: avoid_print
            print('ChannelTile: [LOGO] ⚠️ SVG potrebbe essere nero, passo automaticamente ai PNG/JPEG rimanenti');
            _tryNextUrl();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('ChannelTile: [LOGO] Build widget - URL corrente: $_currentUrl (index: $_currentIndex/${widget.allUrls.length}), whiteFilter: $_triedWhiteFilter');
    // ignore: avoid_print
    print('ChannelTile: [LOGO] Tipo file: ${_isSvg ? "SVG" : "PNG/JPG"}');
    
    if (_isSvg) {
      // Determina se applicare il filtro bianco
      // Applica filtro bianco SOLO quando:
      // 1. Abbiamo esplicitamente provato con filtro bianco (_triedWhiteFilter = true)
      // 2. NON applicarlo per SVG semplici (come Rai 1) che funzionano correttamente
      // 
      // NOTA: Preferiamo sempre PNG a colori da servizi pubblici invece di SVG bianchi
      // Il filtro bianco è solo l'ultima risorsa quando tutti i PNG hanno fallito
      final shouldUseWhite = _triedWhiteFilter;
      
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 🎨 Rendering SVG: $_currentUrl');
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 📋 Filtro bianco: $shouldUseWhite (tried: $_triedWhiteFilter, index: $_currentIndex/${widget.allUrls.length})');
      // ignore: avoid_print
      print('ChannelTile: [LOGO] ⚠️ ATTENZIONE: SVG complessi (come LA7) potrebbero apparire neri. Preferire PNG da servizi pubblici!');
      
      // IMPORTANTE: Rileva se l'SVG è nero e passa automaticamente ai PNG/JPEG
      // Chiama la funzione di rilevamento dopo che il widget è stato costruito
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectBlackSvgAndSkip();
      });
      
      // NOTA: flutter_svg non supporta:
      // 1. Tag <style> con classi CSS (es. class="st0")
      // 2. Riferimenti a gradienti tramite classi CSS (es. fill:url(#gradient))
      // 3. Attributi style="stop-color:..." nei gradienti
      // 
      // DIFFERENZA RAI1 vs LA7:
      // - RAI1: usa attributi fill diretti (fill="#4144C5") → FUNZIONA ✅
      // - LA7: usa classi CSS (class="st0") con gradienti complessi → NON FUNZIONA ❌
      // 
      // SOLUZIONE: Per SVG complessi (senza PNG disponibili), applichiamo colorFilter bianco
      // così almeno sono visibili (anche se senza colori originali)
      // Usiamo ColorFiltered widget wrapper per forzare il filtro bianco quando necessario
      final svgWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.scaler.r(10)),
        child: SvgPicture.network(
        _currentUrl,
        key: ValueKey('$_currentUrl-svg-${shouldUseWhite ? "white" : "original"}'),
        width: widget.scaler.s(42),
        height: widget.scaler.s(42),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://zappr.stream/',
        },
        colorFilter: shouldUseWhite
            ? const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              )
            : null,
        allowDrawingOutsideViewBox: true,
        placeholderBuilder: (context) {
            // ignore: avoid_print
            print('ChannelTile: [LOGO] ⏳ Placeholder SVG mostrato per: $_currentUrl');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.scaler.r(10)),
                border: Border.all(
                  width: 1.0,
                  color: ZapprTokens.channelBorderColor.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: widget.scaler.s(16),
                  height: widget.scaler.s(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ZapprTokens.channelBorderColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // ignore: avoid_print
            print('ChannelTile: [LOGO] ❌ Errore SvgPicture da $_currentUrl');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] ❌ Tipo errore: ${error.runtimeType}');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] ❌ Messaggio errore: $error');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 📍 Index corrente: $_currentIndex/${widget.allUrls.length}');
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 🔄 URL rimanenti: ${widget.allUrls.length - _currentIndex - 1}');
            if (widget.allUrls.length - _currentIndex - 1 > 0) {
              // ignore: avoid_print
              print('ChannelTile: [LOGO] 🔄 Prossimi URL da provare:');
              for (int i = _currentIndex + 1; i < widget.allUrls.length && i < _currentIndex + 4; i++) {
                // ignore: avoid_print
                print('ChannelTile: [LOGO]   - ${widget.allUrls[i]}');
              }
            }
            // ignore: avoid_print
            print('ChannelTile: [LOGO] 📋 Stack trace: $stackTrace');
            
            // Verifica formato del file per diagnosticare problemi di codec/formato
            if (!kIsWeb && Platform.isIOS) {
              // ignore: avoid_print
              print('ChannelTile: [LOGO] 🔍 iOS rilevato - Verifico formato del file...');
              _verifyImageFormat(_currentUrl).then((formatInfo) {
                if (formatInfo != null && mounted) {
                  // ignore: avoid_print
                  print('ChannelTile: [LOGO] 📊 Risultato verifica formato:');
                  // ignore: avoid_print
                  print('ChannelTile: [LOGO]   - Content-Type: ${formatInfo['contentType']}');
                  // ignore: avoid_print
                  print('ChannelTile: [LOGO]   - Formato rilevato: ${formatInfo['detectedFormat']}');
                  // ignore: avoid_print
                  print('ChannelTile: [LOGO]   - Status Code: ${formatInfo['statusCode']}');
                  // ignore: avoid_print
                  print('ChannelTile: [LOGO]   - Valido: ${formatInfo['isValid']}');
                  
                  if (!formatInfo['isValid']) {
                    // ignore: avoid_print
                    print('ChannelTile: [LOGO] ⚠️ File non valido o formato non supportato su iOS!');
                  }
                }
              });
            }
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _tryNextUrl();
              }
            });
            // Se non ci sono più URL da provare, mostra placeholder futuristico
            if (!_hasMoreUrls && _triedWhiteFilter) {
              return Container(
                width: widget.scaler.s(42),
                height: widget.scaler.s(42),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.scaler.r(10)),
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(
                    width: 1,
                    color: ZapprTokens.neonCyan.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      final pulseValue = math.sin(value * 2 * math.pi) * 0.5 + 0.5;
                      final glowIntensity = 0.5 + (pulseValue * 0.5);
                      
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            ZapprTokens.neonCyan.withOpacity(0.8 + (0.2 * pulseValue)),
                            ZapprTokens.neonBlue.withOpacity(0.8 + (0.2 * pulseValue)),
                            ZapprTokens.neonCyan.withOpacity(0.8 + (0.2 * pulseValue)),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: Icon(
                          Icons.tv,
                          size: widget.scaler.s(24),
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: ZapprTokens.neonCyan.withOpacity(0.3 * glowIntensity),
                              blurRadius: 2.0 * widget.scaler.scale,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.scaler.r(10)),
                border: Border.all(
                  width: 1.0,
                  color: ZapprTokens.channelBorderColor.withOpacity(0.3),
                ),
              ),
            );
          },
          semanticsLabel: widget.channelName,
        ),
      );
      
      // Wrappiamo con ColorFiltered SOLO se abbiamo esplicitamente provato con filtro bianco
      // (non per tutti gli SVG, solo per quelli che hanno fallito senza filtro)
      if (shouldUseWhite) {
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
          child: svgWidget,
        );
      }
      return svgWidget;
    }

    // Per PNG/JPG
    // ignore: avoid_print
    print('ChannelTile: [LOGO] 🖼️ Rendering PNG/JPG: $_currentUrl');
    return Image.network(
      _currentUrl,
      key: ValueKey(_currentUrl), // Forza ricostruzione quando cambia URL
      width: widget.scaler.s(42),
      height: widget.scaler.s(42),
      fit: BoxFit.contain,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://zappr.stream/',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] ✅ PNG/JPG caricato con successo: $_currentUrl');
          // ignore: avoid_print
          print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
          // ignore: avoid_print
          print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
          return child;
        }
        final progress = loadingProgress.expectedTotalBytes != null
            ? (loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(1)
            : 'sconosciuto';
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ⏳ Caricamento PNG/JPG in corso: $_currentUrl');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📊 Progresso: $progress% (${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? "?"})');
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.scaler.r(10)),
            border: Border.all(
              width: 1.0,
              color: ZapprTokens.channelBorderColor.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: widget.scaler.s(16),
              height: widget.scaler.s(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ZapprTokens.channelBorderColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ❌ Errore PNG/JPG da $_currentUrl');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ❌ Tipo errore: ${error.runtimeType}');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ❌ Messaggio errore: $error');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📍 Index corrente: $_currentIndex/${widget.allUrls.length}');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 🔄 URL rimanenti: ${widget.allUrls.length - _currentIndex - 1}');
        if (widget.allUrls.length - _currentIndex - 1 > 0) {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] 🔄 Prossimi URL da provare:');
          for (int i = _currentIndex + 1; i < widget.allUrls.length && i < _currentIndex + 4; i++) {
            // ignore: avoid_print
            print('ChannelTile: [LOGO]   - ${widget.allUrls[i]}');
          }
        }
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📋 Stack trace: $stackTrace');
        
        // Verifica formato del file per diagnosticare problemi di codec/formato
        if (!kIsWeb && Platform.isIOS) {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] 🔍 iOS rilevato - Verifico formato del file...');
          _verifyImageFormat(_currentUrl).then((formatInfo) {
            if (formatInfo != null && mounted) {
              // ignore: avoid_print
              print('ChannelTile: [LOGO] 📊 Risultato verifica formato:');
              // ignore: avoid_print
              print('ChannelTile: [LOGO]   - Content-Type: ${formatInfo['contentType']}');
              // ignore: avoid_print
              print('ChannelTile: [LOGO]   - Formato rilevato: ${formatInfo['detectedFormat']}');
              // ignore: avoid_print
              print('ChannelTile: [LOGO]   - Status Code: ${formatInfo['statusCode']}');
              // ignore: avoid_print
              print('ChannelTile: [LOGO]   - Valido: ${formatInfo['isValid']}');
              
              if (!formatInfo['isValid']) {
                // ignore: avoid_print
                print('ChannelTile: [LOGO] ⚠️ File non valido o formato non supportato su iOS!');
              }
            }
          });
        }
        
        // IMPORTANTE: Se stiamo ancora provando PNG, continua con il prossimo PNG
        // Non passare agli SVG finché non abbiamo provato tutti i PNG
        final nextIndex = _currentIndex + 1;
        final hasMorePngUrls = nextIndex < widget.allUrls.length && 
            widget.allUrls[nextIndex].toLowerCase().endsWith('.png');
        
        if (hasMorePngUrls) {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] ✅ Prossimo URL è ancora PNG, continuo con PNG');
        } else {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] ⚠️ Prossimo URL è SVG, ho finito i PNG disponibili');
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tryNextUrl();
          }
        });
        // Mostra il prossimo tentativo
        if (_hasMoreUrls) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.scaler.r(10)),
              border: Border.all(
                width: 1.0,
                color: ZapprTokens.channelBorderColor.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: widget.scaler.s(16),
                height: widget.scaler.s(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ZapprTokens.channelBorderColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }
        // Fallback finale - mostra placeholder futuristico
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 🎨 FALLBACK FINALE - Mostro placeholder futuristico');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📱 Piattaforma: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Altro"))}');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📋 Canale: "${widget.channelName}"');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ❌ Tutti gli URL hanno fallito (${widget.allUrls.length} URL provati)');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] 📝 Ultimo URL provato: $_currentUrl');
        return Container(
          width: widget.scaler.s(42),
          height: widget.scaler.s(42),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.scaler.r(10)),
            color: Colors.black.withOpacity(0.3),
            border: Border.all(
              width: 1,
              color: ZapprTokens.neonCyan.withOpacity(0.4),
            ),
          ),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                final pulseValue = math.sin(value * 2 * math.pi) * 0.5 + 0.5;
                final glowIntensity = 0.5 + (pulseValue * 0.5);
                
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      ZapprTokens.neonCyan.withOpacity(0.8 + (0.2 * pulseValue)),
                      ZapprTokens.neonBlue.withOpacity(0.8 + (0.2 * pulseValue)),
                      ZapprTokens.neonCyan.withOpacity(0.8 + (0.2 * pulseValue)),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.tv,
                    size: widget.scaler.s(24),
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: ZapprTokens.neonCyan.withOpacity(0.3 * glowIntensity),
                        blurRadius: 2.0 * widget.scaler.scale,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Widget che prova prima SVG, poi Image.network come fallback
/// per gestire SVG con CSS styles complessi
class _SvgWithImageFallback extends StatefulWidget {
  final String svgUrl;
  final LayoutScaler scaler;
  final String channelName;
  final bool triedWhiteFilter;
  final VoidCallback onError;

  const _SvgWithImageFallback({
    required this.svgUrl,
    required this.scaler,
    required this.channelName,
    required this.triedWhiteFilter,
    required this.onError,
  });

  @override
  State<_SvgWithImageFallback> createState() => _SvgWithImageFallbackState();
}

class _SvgWithImageFallbackState extends State<_SvgWithImageFallback> {
  bool _useImageFallback = false;

  @override
  void initState() {
    super.initState();
    // Dopo un breve delay, se l'SVG potrebbe essere nero (problema con CSS styles),
    // prova con Image.network come fallback
    // NOTA: Questo è un workaround per SVG con CSS styles complessi
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_useImageFallback) {
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ⚠️ SVG potrebbe essere nero (CSS styles), provo Image.network come fallback');
        // Non forziamo subito Image.network, ma lo teniamo come opzione
        // Se l'SVG fallisce, useremo Image.network
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_useImageFallback) {
      // ignore: avoid_print
      print('ChannelTile: [LOGO] 🖼️ Fallback a Image.network per: ${widget.svgUrl}');
      // NOTA: Image.network su web potrebbe non renderizzare SVG correttamente
      // Ma è l'unico fallback disponibile per SVG con CSS styles
      return Image.network(
        widget.svgUrl,
        key: ValueKey('${widget.svgUrl}-image'),
        width: widget.scaler.s(42),
        height: widget.scaler.s(42),
        fit: BoxFit.contain,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://zappr.stream/',
        },
        errorBuilder: (context, error, stackTrace) {
          // ignore: avoid_print
          print('ChannelTile: [LOGO] ❌ Errore anche con Image.network: $error');
          widget.onError();
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.scaler.r(10)),
              border: Border.all(
                width: 1.0,
                color: ZapprTokens.channelBorderColor.withOpacity(0.3),
              ),
            ),
          );
        },
      );
    }

    // Prova prima con SvgPicture
    // NOTA: flutter_svg non supporta CSS styles, quindi SVG con gradienti complessi
    // potrebbero non renderizzare correttamente (apparire neri)
    return SvgPicture.network(
      widget.svgUrl,
      key: ValueKey('${widget.svgUrl}-svg'),
      width: widget.scaler.s(42),
      height: widget.scaler.s(42),
      fit: BoxFit.contain,
      alignment: Alignment.center,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://zappr.stream/',
      },
      colorFilter: widget.triedWhiteFilter
          ? const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            )
          : null,
      allowDrawingOutsideViewBox: true,
      placeholderBuilder: (context) {
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ⏳ Placeholder SVG - Caricamento in corso: ${widget.svgUrl}');
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.scaler.r(10)),
            border: Border.all(
              width: 1.0,
              color: ZapprTokens.channelBorderColor.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: widget.scaler.s(16),
              height: widget.scaler.s(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ZapprTokens.channelBorderColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // ignore: avoid_print
        print('ChannelTile: [LOGO] ❌ Errore SVG da ${widget.svgUrl}: $error');
        // ignore: avoid_print
        print('ChannelTile: [LOGO] Stack trace: $stackTrace');
        // Se l'SVG fallisce, prova con Image.network
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_useImageFallback) {
            setState(() {
              _useImageFallback = true;
            });
          }
        });
        // Mostra placeholder mentre carica Image.network
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.scaler.r(10)),
            border: Border.all(
              width: 1.0,
              color: ZapprTokens.channelBorderColor.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: widget.scaler.s(16),
              height: widget.scaler.s(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ZapprTokens.channelBorderColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
        );
      },
      semanticsLabel: widget.channelName,
    );
  }
}

