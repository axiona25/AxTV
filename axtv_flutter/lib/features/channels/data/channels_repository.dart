import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../model/channel.dart';
import '../../../core/security/content_validator.dart';
import '../../../core/http/url_validator.dart';
import '../../channels/model/repository_config.dart';
import 'live_repositories_storage.dart';
import 'channels_cache.dart';

/// Repository per caricare i canali live
/// 
/// Supporta:
/// - Multipli repository configurabili (come MoviesRepository)
/// - Caricamento da repository attivi
/// - Validazione URL in background durante il caricamento
/// - Filtro automatico di URL problematici e non accessibili
/// - Fallback a asset locale se nessun repository attivo
class ChannelsRepository {
  final Dio dio;
  final UrlValidator _urlValidator;
  
  ChannelsRepository(this.dio) : _urlValidator = UrlValidator();

  /// Carica tutti i canali dai repository live attivi o da fallback locale
  /// [DEPRECATO] Usa fetchChannelsStream() per caricamento progressivo
  Future<List<Channel>> fetchChannels() async {
    // Carica i repository live attivi
    final repositories = await LiveRepositoriesStorage.loadRepositoriesState();
    final activeRepositories = repositories.where((repo) => repo.enabled).toList();

    // ignore: avoid_print
    print('ChannelsRepository: 🚀 Trovati ${activeRepositories.length} repository live attivi su ${repositories.length} totali');

    if (activeRepositories.isEmpty) {
      // ignore: avoid_print
      print('ChannelsRepository: ⚠️ Nessun repository live attivo, restituisco lista vuota');
      return <Channel>[]; // Restituisce lista vuota quando tutti i repository sono disabilitati
    }

    // Prova a caricare da ogni repository attivo
    final allChannels = <Channel>[];
    for (final repo in activeRepositories) {
      try {
        // ignore: avoid_print
        print('ChannelsRepository: 📦 Caricamento da repository live: ${repo.name}');
        final channels = await _loadFromRepository(repo);
        
        // Valida gli URL dei canali caricati in background
        // Solo i canali con URL validi e accessibili vengono aggiunti alla lista
        // ignore: avoid_print
        print('ChannelsRepository: 🔍 Validazione URL per ${channels.length} canali...');
        final validChannels = await _validateChannelsUrls(channels);
        allChannels.addAll(validChannels);
        
        // ignore: avoid_print
        print('ChannelsRepository: ✅ Caricati ${validChannels.length}/${channels.length} canali validi da ${repo.name}');
      } catch (e) {
        // ignore: avoid_print
        print('ChannelsRepository: ❌ Errore nel caricamento da ${repo.name}: $e');
        // Continua con il prossimo repository
        continue;
      }
    }

    if (allChannels.isEmpty) {
      // ignore: avoid_print
      print('ChannelsRepository: ⚠️ Nessun canale caricato dai repository attivi, restituisco lista vuota');
      return <Channel>[]; // Restituisce lista vuota se nessun canale è stato caricato dai repository attivi
    }

    // ignore: avoid_print
    print('ChannelsRepository: ✅ Totale canali caricati: ${allChannels.length}');
    return allChannels;
  }
  
  /// Carica i canali progressivamente via Stream
  /// 1. Carica subito i canali dalla cache (per visualizzazione immediata)
  /// 2. Valida/carica nuovi canali in background ed emette progressivamente
  /// 3. Salva in cache man mano che trova nuovi canali validi
  Stream<List<Channel>> fetchChannelsStream({bool forceRefresh = false}) async* {
    try {
      // Carica i repository live attivi
      final repositories = await LiveRepositoriesStorage.loadRepositoriesState();
      final activeRepositories = repositories.where((repo) => repo.enabled).toList();

      // ignore: avoid_print
      print('ChannelsRepository: 🚀 Stream: Trovati ${activeRepositories.length} repository live attivi');

      if (activeRepositories.isEmpty) {
        // ignore: avoid_print
        print('ChannelsRepository: ⚠️ Stream: Nessun repository attivo');
        yield <Channel>[];
        return;
      }

      // FASE 1: Carica cache e emetti immediatamente (se disponibile e valida)
      final cachedChannels = forceRefresh ? null : await ChannelsCache.loadCachedChannels();
      final loadedChannels = <String, Channel>{}; // Mappa per evitare duplicati (key: channel.id)
      bool shouldSkipValidation = false; // Flag per saltare validazione se cache recente
    
      if (cachedChannels != null && cachedChannels.isNotEmpty) {
        // ignore: avoid_print
        print('ChannelsRepository: 📦 Stream: Caricati ${cachedChannels.length} canali dalla cache, emettendo immediatamente...');
        for (final channel in cachedChannels) {
          loadedChannels[channel.id] = channel;
        }
        
        // Verifica se la cache è recente (< 1 ora) per saltare validazione HTTP
        final cacheTimestamp = await _getCacheTimestamp();
        if (cacheTimestamp != null) {
          final cacheAge = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
          );
          if (cacheAge.inHours < 1) {
            shouldSkipValidation = true;
            // ignore: avoid_print
            print('ChannelsRepository: ⚡ Cache recente (< 1h), salto validazione HTTP per velocità');
          }
        }
        
        yield loadedChannels.values.toList(); // Emetti immediatamente i canali cached
      } else {
        // ignore: avoid_print
        print('ChannelsRepository: 📦 Stream: Cache non disponibile o vuota, inizio caricamento da repository...');
        yield <Channel>[]; // Emetti lista vuota iniziale se non c'è cache
      }

      // FASE 2: Carica/valida nuovi canali da repository in background
      // Se la cache è recente, salta la validazione HTTP per velocità
      if (shouldSkipValidation) {
        // ignore: avoid_print
        print('ChannelsRepository: ⚡ Saltando validazione HTTP (cache recente), usando solo cache');
        return; // Esci subito, usa solo cache
      }
      
      // Processa ogni repository in sequenza ma emetti canali progressivamente
      for (final repo in activeRepositories) {
        try {
          // ignore: avoid_print
          print('ChannelsRepository: 📦 Stream: Caricamento da ${repo.name}...');
          final channels = await _loadFromRepository(repo);
          
          if (channels.isEmpty) {
            continue;
          }
          
          // ignore: avoid_print
          print('ChannelsRepository: 🔍 Stream: Validazione URL per ${channels.length} canali da ${repo.name}...');
          
          // Valida canali progressivamente (in batch) ed emetti man mano
          await for (final validatedChannels in _validateChannelsUrlsStream(channels)) {
            // Aggiungi nuovi canali validati (sostituisce quelli esistenti con stesso ID)
            for (final channel in validatedChannels) {
              if (!loadedChannels.containsKey(channel.id)) {
                loadedChannels[channel.id] = channel;
              } else {
                // Aggiorna canale esistente se il nuovo è più recente (es: URL aggiornato)
                loadedChannels[channel.id] = channel;
              }
            }
            
            // Emetti lista aggiornata progressivamente
            yield loadedChannels.values.toList();
            
            // Salva in cache man mano che vengono validati nuovi canali
            // (limita le scritture cache: salva ogni 10 canali nuovi o ogni 5 secondi)
            if (loadedChannels.length % 10 == 0) {
              // ignore: avoid_print
              print('ChannelsCache: 💾 Aggiornamento cache intermedio (${loadedChannels.length} canali)...');
              await ChannelsCache.saveChannels(loadedChannels.values.toList());
            }
          }
          
          // ignore: avoid_print
          print('ChannelsRepository: ✅ Stream: Completato caricamento da ${repo.name}');
        } catch (e) {
          // ignore: avoid_print
          print('ChannelsRepository: ❌ Stream: Errore nel caricamento da ${repo.name}: $e');
          continue;
        }
      }

      // FASE 3: Salva cache finale dopo aver completato il caricamento
      if (loadedChannels.isNotEmpty) {
        // ignore: avoid_print
        print('ChannelsCache: 💾 Salvataggio cache finale (${loadedChannels.length} canali)...');
        await ChannelsCache.saveChannels(loadedChannels.values.toList());
      }

      // Se nessun canale caricato, prova fallback locale (utile su web per CORS)
      if (loadedChannels.isEmpty) {
        // ignore: avoid_print
        print('ChannelsRepository: ⚠️ Stream: Nessun canale caricato dai repository, provo fallback locale...');
        try {
          final localChannels = await _loadFromAssets();
          if (localChannels.isNotEmpty) {
            // ignore: avoid_print
            print('ChannelsRepository: ✅ Stream: Caricati ${localChannels.length} canali da fallback locale');
            yield localChannels;
            // Salva in cache anche i canali locali
            await ChannelsCache.saveChannels(localChannels);
            return; // Esci dopo aver emesso i canali locali
          }
        } catch (e) {
          // ignore: avoid_print
          print('ChannelsRepository: ❌ Stream: Errore nel caricamento fallback locale: $e');
        }
      }
      
      // ignore: avoid_print
      print('ChannelsRepository: ✅ Stream: Caricamento completato, totale: ${loadedChannels.length} canali');
      yield loadedChannels.values.toList(); // Emetti lista finale
    } catch (e, stackTrace) {
      // Gestione errori generale: non fallire completamente lo stream
      // Se c'è un errore, prova prima a caricare dalla cache, poi dagli assets
      // ignore: avoid_print
      print('ChannelsRepository: ❌ Stream: Errore generale nel caricamento: $e');
      // ignore: avoid_print
      print('ChannelsRepository: Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      
      // Prova a caricare dalla cache se disponibile
      try {
        final cachedChannels = await ChannelsCache.loadCachedChannels();
        if (cachedChannels != null && cachedChannels.isNotEmpty) {
          // ignore: avoid_print
          print('ChannelsRepository: ✅ Stream: Caricati ${cachedChannels.length} canali dalla cache (fallback dopo errore)');
          yield cachedChannels;
          return;
        }
      } catch (cacheError) {
        // ignore: avoid_print
        print('ChannelsRepository: ⚠️ Stream: Errore nel caricamento cache (fallback): $cacheError');
      }
      
      // Prova fallback locale come ultima risorsa
      try {
        final localChannels = await _loadFromAssets();
        if (localChannels.isNotEmpty) {
          // ignore: avoid_print
          print('ChannelsRepository: ✅ Stream: Caricati ${localChannels.length} canali da assets locale (fallback dopo errore)');
          yield localChannels;
          return;
        }
      } catch (assetsError) {
        // ignore: avoid_print
        print('ChannelsRepository: ⚠️ Stream: Errore nel caricamento assets (fallback): $assetsError');
      }
      
      // Se tutto fallisce, emetti lista vuota invece di far fallire lo stream
      // ignore: avoid_print
      print('ChannelsRepository: ⚠️ Stream: Tutti i fallback falliti, emetto lista vuota');
      yield <Channel>[];
    }
  }
  
  /// Ottiene il timestamp della cache
  Future<int?> _getCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('channels_cache_timestamp');
    } catch (e) {
      return null;
    }
  }
  
  /// Valida gli URL dei canali progressivamente (in batch) ed emette via Stream
  /// Processa in batch di 5 canali alla volta per velocità (ridotto da 10)
  Stream<List<Channel>> _validateChannelsUrlsStream(List<Channel> channels) async* {
    if (channels.isEmpty) {
      return;
    }
    
    const batchSize = 5; // Processa 5 canali alla volta (ridotto per velocità)
    final validChannels = <Channel>[];
    
    for (var i = 0; i < channels.length; i += batchSize) {
      final batch = channels.skip(i).take(batchSize).toList();
      
      // Filtro pre-validazione rapido (senza HTTP request)
      final preFilteredBatch = <Channel>[];
      for (final channel in batch) {
        if (ContentValidator.validateChannel(
          streamUrl: channel.streamUrl,
          name: channel.name,
        )) {
          final lowerUrl = channel.streamUrl.toLowerCase();
          final hasProblematicPattern = 
              lowerUrl.contains('/udp/') || 
              lowerUrl.contains('/play/') ||
              RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/udp/').hasMatch(lowerUrl) ||
              RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/play/').hasMatch(lowerUrl) ||
              RegExp(r'\d+\.\d+\.\d+\.\d+:\d+.*\d+\.\d+\.\d+\.\d+:\d+').hasMatch(lowerUrl);
          
          if (!hasProblematicPattern) {
            preFilteredBatch.add(channel);
          }
        }
      }
      
      if (preFilteredBatch.isEmpty) {
        continue;
      }
      
      // Validazione HTTP solo per M3U8/MPD (i più problematici)
      final validatedBatch = <Channel>[];
      final validationFutures = preFilteredBatch.map((channel) async {
        final lowerUrl = channel.streamUrl.toLowerCase();
        
        // Log per debug canali per bambini
        if (channel.category?.toLowerCase() == 'bambini' || 
            channel.name.toLowerCase().contains('yoyo') ||
            channel.name.toLowerCase().contains('gulp')) {
          // ignore: avoid_print
          print('ChannelsRepository: 🔍 Validazione canale per bambini: "${channel.name}" (${channel.id})');
          // ignore: avoid_print
          print('ChannelsRepository:    URL: ${channel.streamUrl}');
        }
        
        // Per M3U8/HLS, fai validazione HTTP rapida
        if (lowerUrl.contains('.m3u8') || lowerUrl.contains('.mpd')) {
          final isValid = await _urlValidator.validateUrlAccessibility(channel.streamUrl);
          if (!isValid) {
            // ignore: avoid_print
            print('ChannelsRepository: ⚠️ Canale "${channel.name}" (${channel.id}) filtrato: URL non valido o non accessibile');
            // ignore: avoid_print
            print('ChannelsRepository:    URL: ${channel.streamUrl.length > 100 ? channel.streamUrl.substring(0, 100) + "..." : channel.streamUrl}');
          } else {
            if (channel.category?.toLowerCase() == 'bambini' || 
                channel.name.toLowerCase().contains('yoyo') ||
                channel.name.toLowerCase().contains('gulp')) {
              // ignore: avoid_print
              print('ChannelsRepository: ✅ Canale per bambini "${channel.name}" validato con successo');
            }
          }
          if (isValid) {
            return channel;
          }
          return null;
        } else {
          // Per altri URL (archive.org, MP4, ecc.), considera valido dopo pre-filtro
          // Archive.org è sempre valido (file statici)
          if (lowerUrl.contains('archive.org')) {
            return channel;
          }
          // Altri URL verranno testati al momento della riproduzione
          return channel;
        }
      }).toList();
      
      final validationResults = await Future.wait(validationFutures);
      for (final result in validationResults) {
        if (result != null) {
          validatedBatch.add(result);
        }
      }
      
      if (validatedBatch.isNotEmpty) {
        validChannels.addAll(validatedBatch);
        // Emetti batch validato progressivamente
        yield validatedBatch;
      }
    }
  }

  /// Carica i canali da un singolo repository live
  /// Supporta sia formato JSON che M3U
  Future<List<Channel>> _loadFromRepository(RepositoryConfig repo) async {
    try {
      // ignore: avoid_print
      print('ChannelsRepository: 🚀 Inizio caricamento da: ${repo.fullUrl}');
      final startTime = DateTime.now();

      // Rileva se è un file M3U guardando l'estensione nell'URL
      final isM3U = repo.fullUrl.toLowerCase().endsWith('.m3u') || 
                    (repo.jsonPath?.toLowerCase().endsWith('.m3u') ?? false);

      // Prova a caricare dal repository
      final response = await dio.get(
        repo.fullUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            if (isM3U)
              'Accept': 'application/vnd.apple.mpegurl, application/x-mpegURL, text/plain, */*'
            else
              'Accept': 'application/json',
            'Content-Type': isM3U ? 'text/plain' : 'application/json',
            'User-Agent': 'AxTV-Flutter-App',
          },
          responseType: ResponseType.plain, // Sempre testo per poter gestire sia JSON che M3U
        ),
      );

      final loadTime = DateTime.now().difference(startTime);
      // ignore: avoid_print
      print('ChannelsRepository: ⏱️ Download completato in ${loadTime.inSeconds}s, status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final responseText = response.data as String;
        
        if (isM3U || responseText.trim().startsWith('#EXTM3U')) {
          // Parse formato M3U
          // ignore: avoid_print
          print('ChannelsRepository: 📝 Formato M3U rilevato, parsing...');
          return _parseM3U(responseText, repo);
        } else {
          // Parse formato JSON
          // ignore: avoid_print
          print('ChannelsRepository: 📝 Formato JSON rilevato, parsing...');
          return _parseJSON(responseText, repo);
        }
      } else {
        throw Exception('Risposta non valida (status: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('ChannelsRepository: ❌ Errore nel caricamento da ${repo.name}: $e');
      // ignore: avoid_print
      print('ChannelsRepository: Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      rethrow;
    }
  }

  /// Parsa un file JSON e restituisce la lista di canali
  List<Channel> _parseJSON(String jsonText, RepositoryConfig repo) {
    dynamic data;
    try {
      data = json.decode(jsonText);
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsRepository: ❌ Errore nel parsing JSON: $e');
      throw Exception('Errore nel parsing JSON: $e');
    }

    if (data is! List) {
      throw Exception('Il JSON deve essere un array di canali');
    }

    // Converti e valida i canali
    final channels = <Channel>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      
      try {
        // Supporta anche "group" o "group-title" per regione o categoria
        final groupTitle = item['group-title'] ?? item['group'];
        if (groupTitle != null) {
          final categories = ['news', 'sports', 'entertainment', 'movies', 'documentary', 
                             'music', 'kids', 'educational', 'religious', 'adult', 'general'];
          final isCategory = categories.any((cat) => groupTitle.toString().toLowerCase().contains(cat));
          
          if (isCategory) {
            item['category'] = groupTitle;
          } else {
            item['region'] = groupTitle;
          }
        }
        
        // Supporta anche "category" o "tvg-category" direttamente
        if (item['category'] == null) {
          if (item['tvg-category'] != null) {
            item['category'] = item['tvg-category'];
          }
        }
        
        // Classificazione automatica se mancano region e category
        if (item['region'] == null && item['category'] == null) {
          final name = (item['name'] as String? ?? '').toLowerCase();
          
          // Classifica per categoria in base al nome (traduzioni italiane)
          if (_isNewsChannel(name)) {
            item['category'] = 'Notizie';
          } else if (_isSportsChannel(name)) {
            item['category'] = 'Sport';
          } else if (_isEntertainmentChannel(name)) {
            item['category'] = 'Intrattenimento';
          } else if (_isMoviesChannel(name)) {
            item['category'] = 'Cinema';
          } else if (_isDocumentaryChannel(name)) {
            item['category'] = 'Documentari';
          } else if (_isMusicChannel(name)) {
            item['category'] = 'Musica';
          } else if (_isKidsChannel(name)) {
            item['category'] = 'Bambini';
          } else {
            item['category'] = 'Generale';
          }
          
          // Classifica per regione in base al nome
          if (_isItalianChannel(name)) {
            item['region'] = 'Italia';
          } else if (_isInternationalChannel(name)) {
            item['region'] = 'Internazionale';
          }
        }
        
        final channel = Channel.fromJson(item);
        
        // Log per debug canali per bambini durante parsing
        if (channel.category?.toLowerCase() == 'bambini' || 
            channel.name.toLowerCase().contains('yoyo') ||
            channel.name.toLowerCase().contains('gulp')) {
          // ignore: avoid_print
          print('ChannelsRepository: 🔍 Parsing canale per bambini: "${channel.name}" (${channel.id})');
          // ignore: avoid_print
          print('ChannelsRepository:    URL: ${channel.streamUrl}');
          // ignore: avoid_print
          print('ChannelsRepository:    Category: ${channel.category}');
        }
        
        // Valida ogni canale per sicurezza
        final isValid = ContentValidator.validateChannel(
          streamUrl: channel.streamUrl,
          name: channel.name,
        );
        
        if (isValid) {
          if (channel.category?.toLowerCase() == 'bambini' || 
              channel.name.toLowerCase().contains('yoyo') ||
              channel.name.toLowerCase().contains('gulp')) {
            // ignore: avoid_print
            print('ChannelsRepository: ✅ Canale per bambini "${channel.name}" passato ContentValidator');
          }
          channels.add(channel);
        } else {
          // Log per test di sicurezza
          if (channel.category?.toLowerCase() == 'bambini' || 
              channel.name.toLowerCase().contains('yoyo') ||
              channel.name.toLowerCase().contains('gulp')) {
            // ignore: avoid_print
            print('ChannelsRepository: ❌ Canale per bambini "${channel.name}" BLOCCATO da ContentValidator');
          }
          ContentValidator.logSecurityEvent(
            'Channel blocked',
            {
              'name': channel.name,
              'url': channel.streamUrl.length > 100 
                  ? '${channel.streamUrl.substring(0, 100)}...'
                  : channel.streamUrl,
              'repository': repo.name,
            },
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('ChannelsRepository: ⚠️ Errore nel parsing di un canale: $e');
        // Continua con il prossimo canale
        continue;
      }
    }

    // ignore: avoid_print
    print('ChannelsRepository: ✅ Parsing JSON completato: ${channels.length} canali validi');
    return channels;
  }

  /// Parsa un file M3U e restituisce la lista di canali
  List<Channel> _parseM3U(String m3uText, RepositoryConfig repo) {
    final channels = <Channel>[];
    final lines = m3uText.split('\n');
    
    Map<String, dynamic>? currentChannel;
    int parsedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    
    for (var line in lines) {
      line = line.trim();
      
      if (line.isEmpty || line.startsWith('#EXTM3U')) {
        // Ignora righe vuote e header M3U
        continue;
      }
      
      if (line.startsWith('#EXTINF')) {
        // Parse linea #EXTINF
        // Formato: #EXTINF:-1 tvg-id="ID" tvg-name="Nome" tvg-logo="URL" group-title="Gruppo",Nome Canale
        currentChannel = <String, dynamic>{};
        
        // Estrai nome canale (dopo l'ultima virgola o da tvg-name)
        String? channelName;
        
        // Prova prima con tvg-name
        final tvgNameMatch = RegExp(r'tvg-name="([^"]+)"').firstMatch(line);
        if (tvgNameMatch != null) {
          channelName = tvgNameMatch.group(1)?.trim();
        }
        
        // Se non c'è tvg-name, prova dopo la virgola
        if (channelName == null || channelName.isEmpty) {
          final nameMatch = RegExp(r',(.+)$').firstMatch(line);
          if (nameMatch != null) {
            channelName = nameMatch.group(1)?.trim();
          }
        }
        
        // Rimuovi eventuali informazioni aggiuntive nel nome (es: "(270p)" o "[Geo-blocked]")
        if (channelName != null && channelName.isNotEmpty) {
          channelName = channelName.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
          channelName = channelName.replaceAll(RegExp(r'\s*\[[^\]]*\]\s*$'), '').trim();
        }
        
        currentChannel!['name'] = channelName ?? 'Unknown';
        
        // Estrai logo (tvg-logo="...")
        final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(line);
        if (logoMatch != null) {
          currentChannel!['logo'] = logoMatch.group(1);
        }
        
        // Estrai ID (tvg-id="...")
        final idMatch = RegExp(r'tvg-id="([^"]+)"').firstMatch(line);
        if (idMatch != null) {
          currentChannel!['tvgId'] = idMatch.group(1);
        }
        
        // Estrai group-title (può essere regione o categoria)
        final groupTitleMatch = RegExp(r'group-title="([^"]+)"').firstMatch(line);
        if (groupTitleMatch != null) {
          final groupTitle = groupTitleMatch.group(1)?.trim() ?? '';
          
          // Lista di categorie comuni (non regioni geografiche)
          // Supporta sia inglese che italiano
          final categories = ['news', 'notizie', 'sports', 'sport', 'entertainment', 'intrattenimento',
                             'movies', 'cinema', 'documentary', 'documentari', 'music', 'musica',
                             'kids', 'bambini', 'educational', 'educational', 'religious', 'adult', 
                             'general', 'generale'];
          final groupTitleLower = groupTitle.toLowerCase();
          final isCategory = categories.any((cat) => groupTitleLower.contains(cat));
          
          if (isCategory) {
            // Normalizza le categorie in italiano
            String normalizedCategory = groupTitle;
            if (groupTitleLower.contains('news')) {
              normalizedCategory = 'Notizie';
            } else if (groupTitleLower.contains('sports') || groupTitleLower.contains('sport')) {
              normalizedCategory = 'Sport';
            } else if (groupTitleLower.contains('entertainment') || groupTitleLower.contains('intrattenimento')) {
              normalizedCategory = 'Intrattenimento';
            } else if (groupTitleLower.contains('movies') || groupTitleLower.contains('cinema')) {
              normalizedCategory = 'Cinema';
            } else if (groupTitleLower.contains('documentary') || groupTitleLower.contains('documentari')) {
              normalizedCategory = 'Documentari';
            } else if (groupTitleLower.contains('music') || groupTitleLower.contains('musica')) {
              normalizedCategory = 'Musica';
            } else if (groupTitleLower.contains('kids') || groupTitleLower.contains('bambini')) {
              normalizedCategory = 'Bambini';
            } else if (groupTitleLower.contains('general') || groupTitleLower.contains('generale')) {
              normalizedCategory = 'Generale';
            }
            currentChannel!['category'] = normalizedCategory;
          } else {
            // Altrimenti è probabilmente una regione geografica
            currentChannel!['region'] = groupTitle;
          }
        }
        
        // Estrai anche tvg-category se presente (per EPG)
        final tvgCategoryMatch = RegExp(r'tvg-category="([^"]+)"').firstMatch(line);
        if (tvgCategoryMatch != null && currentChannel!['category'] == null) {
          currentChannel!['category'] = tvgCategoryMatch.group(1)?.trim();
        }
      } else if (!line.startsWith('#') && line.isNotEmpty && currentChannel != null) {
        // Questa è la riga URL
        currentChannel!['streamUrl'] = line;
        parsedCount++;
        
        try {
          // Crea ID slug dal nome se non c'è tvg-id
          final name = currentChannel['name'] as String? ?? 'Unknown';
          final id = currentChannel['tvgId'] as String? ?? _slugify(name);
          final streamUrl = currentChannel['streamUrl'] as String?;
          
          // Verifica che abbiamo almeno nome e URL
          if (streamUrl == null || streamUrl.isEmpty || name.isEmpty || name == 'Unknown') {
            // ignore: avoid_print
            print('ChannelsRepository: ⚠️ Canale M3U invalido (nome: "$name", URL: ${streamUrl != null ? "presente" : "mancante"}), saltato');
            skippedCount++;
            currentChannel = null;
            continue;
          }
          
          // Verifica che l'URL sia valido (http/https/rtmp)
          if (!streamUrl.startsWith('http://') && 
              !streamUrl.startsWith('https://') && 
              !streamUrl.startsWith('rtmp://')) {
            // ignore: avoid_print
            print('ChannelsRepository: ⚠️ Canale M3U con URL non valido: "$streamUrl", saltato');
            skippedCount++;
            currentChannel = null;
            continue;
          }
          
          // Verifica se l'URL è problematico noto
          if (ContentValidator.isProblematicUrl(streamUrl)) {
            // ignore: avoid_print
            print('ChannelsRepository: ⚠️ Canale M3U con URL problematico noto: "$streamUrl", saltato');
            skippedCount++;
            currentChannel = null;
            continue;
          }
          
          // Controlla pattern problematici comuni negli URL (PRIMA della validazione completa)
          // Questo filtro rapido evita di processare URL chiaramente problematici
          final lowerUrl = streamUrl.toLowerCase();
          
          // Pattern problematici noti (filtro rapido)
          final problematicPatterns = [
            '/udp/', // UDP streams tunnelizzati
            '/play/', // Proxy/relay streams (es: http://IP:PORT/play/xxx)
            'streaming101tv.es',
            '188.60.179.180',
            '49.113.179.174',
          ];
          
          bool isProblematic = false;
          for (final pattern in problematicPatterns) {
            if (lowerUrl.contains(pattern)) {
              // ignore: avoid_print
              print('ChannelsRepository: ⚠️ URL con pattern problematico "$pattern": "$streamUrl", saltato');
              isProblematic = true;
              skippedCount++;
              break;
            }
          }
          
          // Filtra anche IP diretti con path /play/ (pattern problematico comune, già incluso in problematicPatterns)
          // Il check regex è ridondante ma lo lasciamo come fallback
          if (!isProblematic && RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/play/').hasMatch(lowerUrl)) {
            // ignore: avoid_print
            print('ChannelsRepository: ⚠️ URL IP diretto con /play/ filtrato: "$streamUrl", saltato');
            isProblematic = true;
            skippedCount++;
          }
          
          // Filtra IP diretti con porte 8000+ e pattern /play/ (molto problematici)
          if (!isProblematic) {
            final ipPortMatch = RegExp(r'http://\d+\.\d+\.\d+\.\d+:(\d+)/').firstMatch(lowerUrl);
            if (ipPortMatch != null) {
              final port = int.tryParse(ipPortMatch.group(1) ?? '') ?? 0;
              // Porte 8000+ su IP diretti sono spesso problematiche
              if (port >= 8000 && (lowerUrl.contains('/play/') || lowerUrl.contains('/udp/'))) {
                // ignore: avoid_print
                print('ChannelsRepository: ⚠️ URL IP diretto con porta $port e pattern problematico filtrato: "$streamUrl", saltato');
                isProblematic = true;
                skippedCount++;
              }
            }
          }
          
          if (isProblematic) {
            currentChannel = null;
            continue;
          }
          
          final channel = Channel(
            id: id,
            name: name,
            logo: currentChannel['logo'] as String?,
            streamUrl: streamUrl,
            region: currentChannel['region'] as String?,
            category: currentChannel['category'] as String?,
          );
          
          // Valida ogni canale per sicurezza e validità
          final isValid = ContentValidator.validateChannel(
            streamUrl: channel.streamUrl,
            name: channel.name,
          );
          
          if (isValid) {
            channels.add(channel);
          } else {
            skippedCount++;
            // Log per test di sicurezza
            ContentValidator.logSecurityEvent(
              'Channel blocked',
              {
                'name': channel.name,
                'url': channel.streamUrl.length > 100 
                    ? '${channel.streamUrl.substring(0, 100)}...'
                    : channel.streamUrl,
                'repository': repo.name,
              },
            );
          }
        } catch (e, stackTrace) {
          errorCount++;
          // ignore: avoid_print
          print('ChannelsRepository: ⚠️ Errore nel parsing di un canale M3U: $e');
          // ignore: avoid_print
          print('ChannelsRepository: Stack: ${stackTrace.toString().split('\n').take(2).join('\n')}');
        }
        
        currentChannel = null;
      }
    }

    // ignore: avoid_print
    print('ChannelsRepository: ✅ Parsing M3U completato: ${channels.length} canali validi su $parsedCount parsati (saltati: $skippedCount, errori: $errorCount)');
    return channels;
  }

  /// Valida gli URL dei canali caricati e filtra quelli non validi/accessibili
  /// Processa in parallelo per velocità (max 10 alla volta)
  /// Usa filtri pre-validazione per velocizzare (evita richieste HTTP per pattern problematici noti)
  Future<List<Channel>> _validateChannelsUrls(List<Channel> channels) async {
    if (channels.isEmpty) {
      return channels;
    }
    
    // FASE 1: Filtro rapido pre-validazione (senza richieste HTTP)
    // Filtra URL problematici noti prima della validazione HTTP per velocità
    final preFilteredChannels = <Channel>[];
    int preFilteredCount = 0;
    
    for (final channel in channels) {
      // Verifica pattern problematici rapidamente (senza HTTP request)
      // ContentValidator.validateChannel() già include molti filtri (IP diretti, /udp/, /play/, ecc.)
      if (ContentValidator.validateChannel(
        streamUrl: channel.streamUrl,
        name: channel.name,
      )) {
        // Verifica aggiuntiva per pattern specifici problematici
        final lowerUrl = channel.streamUrl.toLowerCase();
        
        // Filtra pattern problematici comuni (double-check per sicurezza)
        final hasProblematicPattern = 
            lowerUrl.contains('/udp/') || 
            lowerUrl.contains('/play/') ||
            RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/udp/').hasMatch(lowerUrl) ||
            RegExp(r'http://\d+\.\d+\.\d+\.\d+:\d+/play/').hasMatch(lowerUrl) ||
            RegExp(r'\d+\.\d+\.\d+\.\d+:\d+.*\d+\.\d+\.\d+\.\d+:\d+').hasMatch(lowerUrl);
        
        if (!hasProblematicPattern) {
          preFilteredChannels.add(channel);
        } else {
          preFilteredCount++;
        }
      } else {
        preFilteredCount++;
      }
    }
    
    // ignore: avoid_print
    print('ChannelsRepository: 🔍 Pre-filtro: ${preFilteredChannels.length} canali validi su ${channels.length} (${preFilteredCount} filtrati da pattern problematici)');
    
    if (preFilteredChannels.isEmpty) {
      return preFilteredChannels;
    }
    
    // FASE 2: Validazione HTTP solo per URL che hanno superato il pre-filtro
    // Processa in batch più grandi (10 alla volta) per velocità
    final validChannels = <Channel>[];
    
    // ignore: avoid_print
    print('ChannelsRepository: 🔍 Inizio validazione HTTP per ${preFilteredChannels.length} canali...');
    
    // Processa in batch di 10 alla volta per velocità
    const batchSize = 10;
    for (var i = 0; i < preFilteredChannels.length; i += batchSize) {
      final batch = preFilteredChannels.skip(i).take(batchSize).toList();
      
      // Valida gli URL del batch in parallelo con timeout breve
      final batchResults = await Future.wait(
        batch.map((channel) => _urlValidator.validateUrlAccessibility(channel.streamUrl)),
      );
      
      // Aggiungi solo i canali validi
      for (var j = 0; j < batch.length; j++) {
        if (batchResults[j]) {
          validChannels.add(batch[j]);
        }
      }
      
      // Progress update ogni batch (solo se molti canali)
      if (preFilteredChannels.length > 20 && i + batchSize < preFilteredChannels.length) {
        // ignore: avoid_print
        print('ChannelsRepository: 🔍 Validati ${i + batch.length}/${preFilteredChannels.length} canali (validi: ${validChannels.length})...');
      }
    }
    
    final totalFilteredCount = channels.length - validChannels.length;
    final httpFilteredCount = preFilteredChannels.length - validChannels.length;
    
    // ignore: avoid_print
    print('ChannelsRepository: ✅ Validazione completata:');
    // ignore: avoid_print
    print('ChannelsRepository:   - Totale canali: ${channels.length}');
    // ignore: avoid_print
    print('ChannelsRepository:   - Filtrati da pattern: $preFilteredCount');
    // ignore: avoid_print
    print('ChannelsRepository:   - Filtrati da validazione HTTP: $httpFilteredCount');
    // ignore: avoid_print
    print('ChannelsRepository:   - Canali validi finali: ${validChannels.length}');
    
    return validChannels;
  }

  /// Crea uno slug da un testo (simile alla funzione Python)
  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
  
  /// Verifica se un canale è di tipo News in base al nome
  bool _isNewsChannel(String name) {
    final newsKeywords = ['news', 'tg', 'notizie', 'informazione', '24 ore', 'riforma', 
                         'rai news', 'sky tg', 'cnn', 'bbc news', 'euronews', 'al jazeera',
                         'reuters', 'bloomberg', 'fox news'];
    return newsKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è di tipo Sports in base al nome
  bool _isSportsChannel(String name) {
    final sportsKeywords = ['sport', 'calcio', 'football', 'soccer', 'motogp', 'formula',
                           'tennis', 'basket', 'nba', 'serie a', 'champions', 'eurosport',
                           'rai sport', 'sky sport', 'dazn', 'bein sport'];
    return sportsKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è di tipo Entertainment in base al nome
  bool _isEntertainmentChannel(String name) {
    final entertainmentKeywords = ['rai', 'canale', 'rete', 'italia', 'mediaset', 'sky',
                                  'la7', 'tv8', 'cielo', 'iris', 'focus', 'top crime',
                                  'twentyseven', '20 mediaset', 'real time', 'comedy'];
    return entertainmentKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è di tipo Movies in base al nome
  bool _isMoviesChannel(String name) {
    final moviesKeywords = ['cinema', 'film', 'movie', 'cine', 'hbo', 'sky cinema',
                           'rai movie', 'movie 24', 'studio universal'];
    return moviesKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è di tipo Documentary in base al nome
  bool _isDocumentaryChannel(String name) {
    final documentaryKeywords = ['documentary', 'documentario', 'history', 'storia',
                                'discovery', 'national geographic', 'nat geo',
                                'rai storia', 'focus', 'history channel'];
    return documentaryKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è di tipo Music in base al nome
  bool _isMusicChannel(String name) {
    final musicKeywords = ['music', 'musica', 'mtv', 'viva', 'all music', 'deejay tv',
                          'radio', 'virgin', 'hit', 'kiss'];
    return musicKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è per bambini in base al nome
  bool _isKidsChannel(String name) {
    final kidsKeywords = ['kids', 'bambini', 'cartoon', 'disney', 'nickelodeon', 'boing',
                         'cartoonito', 'super!', 'rai yoyo', 'rai gulp', 'frisbee'];
    return kidsKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è italiano in base al nome
  bool _isItalianChannel(String name) {
    final italianKeywords = ['rai', 'mediaset', 'sky italia', 'la7', 'italia', 'tv8',
                            'cielo', 'iris', 'rete', 'canale', 'focus', 'top crime',
                            'twentyseven', 'tv2000', 'noi', 'super', 'frisbee', 'boing'];
    return italianKeywords.any((keyword) => name.contains(keyword));
  }
  
  /// Verifica se un canale è internazionale in base al nome
  bool _isInternationalChannel(String name) {
    final internationalKeywords = ['bbc', 'cnn', 'fox', 'nbc', 'abc', 'cbs', 'hbo',
                                  'discovery', 'national geographic', 'euronews',
                                  'al jazeera', 'sky uk', 'sky news', 'france', 'deutsch',
                                  'espana', 'espn', 'mtv', 'disney'];
    return internationalKeywords.any((keyword) => name.contains(keyword));
  }

  /// Carica i canali dagli asset locali (fallback)
  Future<List<Channel>> _loadFromAssets() async {
    try {
      // ignore: avoid_print
      print('ChannelsRepository: Caricamento da assets locale (fallback)');
      final String jsonString = await rootBundle.loadString('assets/channels.json');
      final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
      
      // Valida anche i canali da assets locali
      final channels = jsonData
          .whereType<Map<String, dynamic>>()
          .map(Channel.fromJson)
          .where((channel) {
            final isValid = ContentValidator.validateChannel(
              streamUrl: channel.streamUrl,
              name: channel.name,
            );
            if (!isValid) {
              ContentValidator.logSecurityEvent(
                'Channel blocked (from assets)',
                {'name': channel.name},
              );
            }
            return isValid;
          })
          .toList(growable: false);
      
      // ignore: avoid_print
      print('ChannelsRepository: ✅ Caricati ${channels.length} canali da assets locale');
      return channels;
    } catch (e) {
      // ignore: avoid_print
      print('ChannelsRepository: Errore nel caricamento da assets: $e');
      return <Channel>[]; // Restituisce lista vuota invece di lanciare eccezione
    }
  }
}

