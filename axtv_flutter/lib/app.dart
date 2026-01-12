import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/channels/ui/home_page.dart';
import 'features/player/ui/player_page.dart';
import 'features/settings/ui/settings_page.dart';
import 'features/advert/ui/advert_page.dart';
import 'features/channels/model/channel.dart';
import 'theme/zappr_theme.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Channel) {
          return PlayerPage(channel: extra);
        }
        throw Exception('Tipo non supportato per il player');
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/advert',
      builder: (context, state) => const AdvertPage(),
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zappr',
      theme: ZapprTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
