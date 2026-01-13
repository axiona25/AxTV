import '../../channels/model/repository_config.dart';

/// Lista di tutti i repository live (canali) disponibili
class LiveRepositoriesConfig {
  /// Repository live predefiniti disponibili
  static List<RepositoryConfig> get defaultRepositories => [
    // Repository principale AxTV (JSON)
    RepositoryConfig(
      id: 'axtv-channels',
      name: 'AxTV Canali',
      description: 'Canali live dal repository principale AxTV',
      baseUrl: 'https://raw.githubusercontent.com/axiona25/AxTV/feature/ios-app-config-v1.0.2',
      jsonPath: '/channels.json',
      enabled: true, // Attivo di default
    ),
    
    // Repository iptv-org/iptv - Europa
    RepositoryConfig(
      id: 'iptv-org-it',
      name: 'IPTV-org 🇮🇹 Italia',
      description: 'Canali live italiani da iptv-org/iptv (~200 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/it.m3u',
      enabled: false, // Disattivato di default - attiva dalle impostazioni
    ),
    RepositoryConfig(
      id: 'iptv-org-fr',
      name: 'IPTV-org 🇫🇷 Francia',
      description: 'Canali live francesi da iptv-org/iptv (~150 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/fr.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-de',
      name: 'IPTV-org 🇩🇪 Germania',
      description: 'Canali live tedeschi da iptv-org/iptv (~100 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/de.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-uk',
      name: 'IPTV-org 🇬🇧 Regno Unito',
      description: 'Canali live britannici da iptv-org/iptv (~150 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/gb.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-es',
      name: 'IPTV-org 🇪🇸 Spagna',
      description: 'Canali live spagnoli da iptv-org/iptv (~100 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/es.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-nl',
      name: 'IPTV-org 🇳🇱 Paesi Bassi',
      description: 'Canali live olandesi da iptv-org/iptv (~80 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/nl.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-pl',
      name: 'IPTV-org 🇵🇱 Polonia',
      description: 'Canali live polacchi da iptv-org/iptv (~60 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/pl.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-ru',
      name: 'IPTV-org 🇷🇺 Russia',
      description: 'Canali live russi da iptv-org/iptv (~100 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/ru.m3u',
      enabled: false,
    ),
    
    // Repository iptv-org/iptv - Americhe
    RepositoryConfig(
      id: 'iptv-org-us',
      name: 'IPTV-org 🇺🇸 Stati Uniti',
      description: 'Canali live statunitensi da iptv-org/iptv (~500 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/us.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-ca',
      name: 'IPTV-org 🇨🇦 Canada',
      description: 'Canali live canadesi da iptv-org/iptv (~100 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/ca.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-br',
      name: 'IPTV-org 🇧🇷 Brasile',
      description: 'Canali live brasiliani da iptv-org/iptv (~150 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/br.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-mx',
      name: 'IPTV-org 🇲🇽 Messico',
      description: 'Canali live messicani da iptv-org/iptv (~80 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/mx.m3u',
      enabled: false,
    ),
    
    // Repository iptv-org/iptv - Asia
    RepositoryConfig(
      id: 'iptv-org-in',
      name: 'IPTV-org 🇮🇳 India',
      description: 'Canali live indiani da iptv-org/iptv (~200 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/in.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-jp',
      name: 'IPTV-org 🇯🇵 Giappone',
      description: 'Canali live giapponesi da iptv-org/iptv (~80 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/jp.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'iptv-org-cn',
      name: 'IPTV-org 🇨🇳 Cina',
      description: 'Canali live cinesi da iptv-org/iptv (~100 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/cn.m3u',
      enabled: false,
    ),
    
    // Repository iptv-org/iptv - Oceania
    RepositoryConfig(
      id: 'iptv-org-au',
      name: 'IPTV-org 🇦🇺 Australia',
      description: 'Canali live australiani da iptv-org/iptv (~80 canali)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/countries/au.m3u',
      enabled: false,
    ),
    
    // Repository m3u8-xtream-playlist - Canali TV per categoria (da iptv-org)
    RepositoryConfig(
      id: 'm3u8-xtream-entertainment',
      name: 'M3U8-Xtream 🎬 Entertainment',
      description: 'Canali live Entertainment da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/categories/entertainment.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'm3u8-xtream-movies',
      name: 'M3U8-Xtream 🎥 Movies',
      description: 'Canali live Movies da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/categories/movies.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'm3u8-xtream-news',
      name: 'M3U8-Xtream 📰 News',
      description: 'Canali live News da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/categories/news.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'm3u8-xtream-sports',
      name: 'M3U8-Xtream ⚽ Sports',
      description: 'Canali live Sports da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/categories/sports.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'm3u8-xtream-documentary',
      name: 'M3U8-Xtream 📚 Documentary',
      description: 'Canali live Documentary da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/categories/documentary.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'm3u8-xtream-music',
      name: 'M3U8-Xtream 🎵 Music',
      description: 'Canali live Music da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/categories/music.m3u',
      enabled: false,
    ),
    RepositoryConfig(
      id: 'm3u8-xtream-all',
      name: 'M3U8-Xtream 🌍 Tutti i Canali',
      description: 'Tutti i canali live da m3u8-xtream-playlist (via iptv-org)',
      baseUrl: 'https://iptv-org.github.io/iptv',
      jsonPath: '/index.m3u',
      enabled: false,
    ),
    
    // Puoi aggiungere altri paesi seguendo lo stesso pattern
    // Per aggiungere un nuovo paese:
    // RepositoryConfig(
    //   id: 'iptv-org-{codice-paese}',
    //   name: 'IPTV-org 🇺🇳 Nome Paese',
    //   description: 'Canali live da iptv-org/iptv',
    //   baseUrl: 'https://iptv-org.github.io/iptv',
    //   jsonPath: '/countries/{codice-paese}.m3u',
    //   enabled: false,
    // ),
  ];

  /// Trova un repository live per ID
  static RepositoryConfig? findById(String id) {
    try {
      return defaultRepositories.firstWhere((repo) => repo.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ottieni solo i repository live attivi
  static List<RepositoryConfig> getActiveRepositories(
      List<RepositoryConfig> allRepositories) {
    return allRepositories.where((repo) => repo.enabled).toList();
  }
}
