# 🔗 Integrazione Server Proxy Video

Guida per integrare il server proxy video nell'app Flutter.

---

## ✅ Prerequisiti

1. ✅ **Server proxy deployato** su Cloudflare Workers
   - Vedi `server/README.md` per deploy
   - URL esempio: `https://video-proxy.YOUR_SUBDOMAIN.workers.dev`

2. ✅ **Files creati**:
   - `server/cloudflare-worker.js` ✅
   - `server/wrangler.toml` ✅
   - `lib/core/http/video_proxy_resolver.dart` ✅

---

## 🔧 Configurazione

### 1. Configura URL Proxy in `lib/config/env.dart`

```dart
// Sostituisci con il tuo URL del worker
static const videoProxyBase = 'https://video-proxy.YOUR_SUBDOMAIN.workers.dev';

// Abilita proxy
static const bool useVideoProxy = true;
```

### 2. Integra nel `StreamResolver`

Il proxy viene usato automaticamente per:
- ✅ URL da `zplaypro.lat/com` (server offline)
- ✅ Contenuti italiani (opzionale)

### 3. Integra nel `PlayerPage`

Modifica `lib/features/player/ui/player_page.dart` per usare il proxy quando necessario:

```dart
import '../../../core/http/video_proxy_resolver.dart';

// Nella funzione che apre il video:
String urlToPlay = widget.channel.streamUrl;

// Usa proxy se necessario
if (VideoProxyResolver.shouldUseProxy(
  urlToPlay,
  requiresItalian: true, // Solo contenuti italiani
)) {
  final proxyUrl = VideoProxyResolver.resolve(urlToPlay, italianOnly: true);
  urlToPlay = proxyUrl.toString();
  print('PlayerPage: Usa proxy server: $urlToPlay');
}
```

---

## 🇮🇹 Filtro Contenuti Italiani

### Opzione 1: Filtro lato app (Flutter)

Nel `MoviesRepository`, filtra per domini italiani:

```dart
// Filtra solo contenuti italiani
final isItalian = VideoProxyResolver.isItalianContent(videoUrl);
if (!isItalian) {
  skippedCount++;
  continue;
}
```

### Opzione 2: Filtro lato server (Cloudflare Worker)

Nel `server/cloudflare-worker.js`, abilita il filtro:

```javascript
// Scommenta queste righe:
const isItalian = url.searchParams.get('italian') === 'true';
if (isItalian && !ITALIAN_DOMAINS.some(domain => hostname.includes(domain))) {
  return new Response(
    JSON.stringify({ error: 'Contenuto non italiano richiesto' }),
    { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}
```

---

## 🎬 Repository Solo Italiani

Crea un nuovo repository in `repositories_config.dart`:

```dart
RepositoryConfig(
  id: 'italian-movies-only',
  name: '🇮🇹 Solo Film Italiani',
  description: 'Film italiani filtrati da repository disponibili',
  baseUrl: 'https://iptv-org.github.io/iptv',
  jsonPath: '/languages/ita.m3u',
  enabled: true,
),
```

Poi nel `MoviesRepository`, aggiungi filtro per questo repository:

```dart
// Nel parsing M3U, se è repository italiano:
if (repo.id == 'italian-movies-only' || repo.id == 'iptv-org-italian') {
  final isItalian = VideoProxyResolver.isItalianContent(videoUrl);
  if (!isItalian) {
    print('MoviesRepository: ⚠️ Film non italiano filtrato: "$title"');
    skippedCount++;
    currentMovie = null;
    continue;
  }
}
```

---

## 🧪 Test

### 1. Test Server Proxy

```bash
curl "https://video-proxy.YOUR_SUBDOMAIN.workers.dev?url=https://30a-tv.com/feeds/pzaz/30atvmovies.m3u8"
```

### 2. Test App Flutter

1. Abilita `useVideoProxy = true` in `env.dart`
2. Riavvia l'app
3. Prova a riprodurre un video
4. Verifica nei log che usa il proxy

---

## 📊 Risultato Atteso

### Prima:
- ❌ Video da `zplaypro.lat` non funzionano (server offline)
- ⚠️ Video geoblocked non funzionano
- 🌐 Contenuti misti (italiani e non)

### Dopo:
- ✅ Video da `zplaypro.lat` funzionano tramite proxy
- ✅ Video geoblocked funzionano (bypass con header italiani)
- 🇮🇹 Solo contenuti italiani (se filtro abilitato)

---

## 💡 Vantaggi

1. ✅ **Bypass geoblock** - Header italiani simulati
2. 🇮🇹 **Contenuti italiani** - Filtro automatico
3. ⚡ **Performance** - Edge computing (Cloudflare)
4. 💰 **Gratuito** - 100K richieste/giorno gratis
5. 🔒 **Sicuro** - Validazione URL e whitelist

---

## 🚨 Note Legali

- ⚠️ Il proxy bypassa geoblock ma **non modifica copyright**
- ⚠️ Usa solo per **contenuti legali** e **pubblici**
- ⚠️ Non re-hosting di contenuti protetti da copyright
- ✅ Server fa solo **forwarding** (proxy pass-through)

---

## 📝 Prossimi Passi

1. ✅ Deploy server proxy
2. ✅ Configura `env.dart`
3. ✅ Integra in `StreamResolver` / `PlayerPage`
4. ✅ Test con video italiani
5. ✅ Abilita filtro italiano (opzionale)
