class Env {
  /// API pubbliche Zappr (nessun tuo server).
  static const cloudflareApiBase = 'https://cloudflare-api.zappr.stream/api';
  static const vercelApiBase = 'https://vercel-api.zappr.stream/api';

  /// URL del file JSON dei canali.
  /// 
  /// Opzioni:
  /// 1. URL RAW GitHub: https://raw.githubusercontent.com/<ORG>/<REPO>/main/channels.json
  /// 2. File locale (solo per test): usa un servizio come GitHub Gist o simili
  /// 
  /// Per produzione, carica channels.json su GitHub e usa l'URL RAW.
  static const channelsJsonUrl = 'PUT_YOUR_RAW_GITHUB_CHANNELS_JSON_URL_HERE';
  
  /// Per test locale, puoi usare un Gist GitHub temporaneo:
  /// static const channelsJsonUrl = 'https://gist.githubusercontent.com/.../raw/channels.json';
}

