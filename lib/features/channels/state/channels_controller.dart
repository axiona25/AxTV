import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/dio_client.dart';
import '../data/channels_repository.dart';
import '../model/channel.dart';

final channelsRepositoryProvider = Provider<ChannelsRepository>((ref) {
  return ChannelsRepository(dioProvider);
});

final channelsControllerProvider =
    AsyncNotifierProvider<ChannelsController, List<Channel>>(ChannelsController.new);

class ChannelsController extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() async {
    final repo = ref.read(channelsRepositoryProvider);
    return repo.fetchChannels();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(channelsRepositoryProvider).fetchChannels());
  }
}

