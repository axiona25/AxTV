import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/channels/ui/home_page.dart';
import 'features/player/ui/player_page.dart';
import 'features/settings/ui/region_selection_page.dart';
import 'features/channels/model/channel.dart';
import 'core/theme/app_theme.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final channel = state.extra as Channel;
        return PlayerPage(channel: channel);
      },
    ),
    GoRoute(
      path: '/region',
      builder: (context, state) => const RegionSelectionPage(),
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AxTV',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

