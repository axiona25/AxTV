import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/dio_client.dart';
import '../data/channels_repository.dart';
import '../data/live_repositories_storage.dart';
import '../model/channel.dart';
import '../model/repository_config.dart';

final channelsRepositoryProvider = Provider<ChannelsRepository>((ref) {
  return ChannelsRepository(dioProvider);
});

/// Provider per lo stato dei repository live (condiviso)
final liveRepositoriesStateProvider =
    FutureProvider<List<RepositoryConfig>>((ref) async {
  return await LiveRepositoriesStorage.loadRepositoriesState();
});

/// StreamProvider per caricare canali progressivamente
/// Emette i canali man mano che vengono caricati/validati dalla cache e dai repository
final channelsStreamProvider = StreamProvider<List<Channel>>((ref) {
  final repo = ref.read(channelsRepositoryProvider);
  return repo.fetchChannelsStream(forceRefresh: false);
});

/// Provider legacy (Future) per compatibilità - [DEPRECATO]
/// Usa channelsStreamProvider per caricamento progressivo
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
  
  /// Refresh forzato che ricarica anche dalla cache
  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    final repo = ref.read(channelsRepositoryProvider);
    // Usa stream per ottenere tutti i canali con refresh forzato
    final stream = repo.fetchChannelsStream(forceRefresh: true);
    final channels = await stream.last;
    state = AsyncValue.data(channels);
  }
}

