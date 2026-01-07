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
  /// 
  /// ✅ Configurato: Gist GitHub con canali di esempio
  static const channelsJsonUrl = 'https://gist.githubusercontent.com/axiona25/76be0f53dd8ee97efb8e7f642aed9379/raw/c14a3bb13be23f0e65d20647b09748ffdef2d64d/channels.json';
  
  /// Per aggiornare i canali, modifica il Gist su:
  /// https://gist.github.com/axiona25/76be0f53dd8ee97efb8e7f642aed9379
}

