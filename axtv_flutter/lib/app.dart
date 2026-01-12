import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/channels/ui/home_page.dart';
import 'features/player/ui/player_page.dart';
import 'features/settings/ui/settings_page.dart';
import 'features/advert/ui/advert_page.dart';
import 'features/radio/ui/radio_page.dart';
import 'features/favorites/ui/favorites_page.dart';
import 'features/profile/ui/profile_page.dart';
import 'features/channels/model/channel.dart';
import 'theme/zappr_theme.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const HomePage(),
      ),
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is Channel) {
          return NoTransitionPage<void>(
            key: state.pageKey,
            child: PlayerPage(channel: extra),
          );
        }
        throw Exception('Tipo non supportato per il player');
      },
    ),
    GoRoute(
      path: '/radio',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const RadioPage(),
      ),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const FavoritesPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const SettingsPage(),
      ),
    ),
    GoRoute(
      path: '/advert',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const AdvertPage(),
      ),
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
