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
  /// ✅ Configurato: File channels.json nel repository principale
  static const channelsJsonUrl = 'https://raw.githubusercontent.com/axiona25/AxTV/main/channels.json';
  
  /// Per aggiornare i canali:
  /// 1. Modifica channels.json nel repository
  /// 2. Fai commit e push
  /// 3. L'app caricherà automaticamente i nuovi canali
}

