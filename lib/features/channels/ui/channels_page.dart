import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/channels_controller.dart';
import '../model/channel.dart';

class ChannelsPage extends ConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canali'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(channelsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (channels) => _ChannelsList(channels: channels),
      ),
    );
  }
}

class _ChannelsList extends StatelessWidget {
  final List<Channel> channels;
  const _ChannelsList({required this.channels});

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Center(child: Text('Nessun canale'));
    }

    return ListView.separated(
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = channels[i];
        return ListTile(
          leading: c.logo == null
              ? const CircleAvatar(child: Icon(Icons.tv))
              : CircleAvatar(backgroundImage: NetworkImage(c.logo!)),
          title: Text(c.name),
          subtitle: Text(c.id),
          onTap: () => context.push('/player', extra: c),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Errore:\n$error\n\nControlla Env.channelsJsonUrl e il formato JSON.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

