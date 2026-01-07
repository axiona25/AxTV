import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../config/env.dart';
import '../model/channel.dart';
import '../../../core/security/content_validator.dart';

class ChannelsRepository {
  final Dio dio;
  const ChannelsRepository(this.dio);

  Future<List<Channel>> fetchChannels() async {
    // Prova prima con asset locale (fallback per sviluppo/web)
    try {
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
      
      return channels;
    } catch (e) {
      // Se l'asset locale fallisce, prova con URL remoto
      try {
        const url = Env.channelsJsonUrl;
        if (url.startsWith('PUT_')) {
          throw Exception('Configura Env.channelsJsonUrl con un RAW GitHub URL.');
        }

        final res = await dio.get(
          url,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );
        final data = res.data;

        if (data is! List) {
          throw Exception('channels.json deve essere un array JSON');
        }

        // Filtra e valida i canali per sicurezza
        final channels = data
            .whereType<Map<String, dynamic>>()
            .map(Channel.fromJson)
            .where((channel) {
              // Valida ogni canale per sicurezza
              final isValid = ContentValidator.validateChannel(
                streamUrl: channel.streamUrl,
                name: channel.name,
              );
              
              if (!isValid) {
                // Log per test di sicurezza
                ContentValidator.logSecurityEvent(
                  'Channel blocked',
                  {
                    'name': channel.name,
                    'url': channel.streamUrl.length > 100 
                        ? '${channel.streamUrl.substring(0, 100)}...'
                        : channel.streamUrl,
                  },
                );
              }
              
              return isValid;
            })
            .toList(growable: false);

        return channels;
      } catch (remoteError) {
        // Se anche il remoto fallisce, riprova con asset locale come ultimo tentativo
        try {
          final String jsonString = await rootBundle.loadString('assets/channels.json');
          final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;
          return jsonData
              .whereType<Map<String, dynamic>>()
              .map(Channel.fromJson)
              .toList(growable: false);
        } catch (_) {
          throw Exception(
            'Impossibile caricare i canali.\n'
            'Errore remoto: $remoteError\n'
            'Verifica la connessione e Env.channelsJsonUrl.'
          );
        }
      }
    }
  }
}

