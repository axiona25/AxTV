import 'package:dio/dio.dart';
import '../../../config/env.dart';
import '../model/channel.dart';

class ChannelsRepository {
  final Dio dio;
  const ChannelsRepository(this.dio);

  Future<List<Channel>> fetchChannels() async {
    const url = Env.channelsJsonUrl;
    if (url.startsWith('PUT_')) {
      throw Exception('Configura Env.channelsJsonUrl con un RAW GitHub URL.');
    }

    final res = await dio.get(url);
    final data = res.data;

    if (data is! List) {
      throw Exception('channels.json deve essere un array JSON');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Channel.fromJson)
        .toList(growable: false);
  }
}

