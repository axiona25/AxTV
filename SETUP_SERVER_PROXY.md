# 🎬 Setup Server Proxy Video

Guida completa per configurare il server proxy video per contenuti italiani.

---

## ✅ Cosa Fa il Server Proxy

1. ✅ **Bypassa geoblock** - Simula header italiani
2. 🇮🇹 **Filtra contenuti italiani** - Solo domini verificati
3. ⚠️ **Blocca server offline** - zplaypro.lat/com esclusi
4. 🚀 **Supporta HLS/MP4** - Streaming diretto

---

## 🚀 Deploy Cloudflare Workers

### 1. Installa Wrangler

```bash
npm install -g wrangler
# oppure
npx wrangler login
```

### 2. Login Cloudflare

```bash
wrangler login
```

### 3. Deploy

```bash
cd server
npm install
wrangler publish
```

### 4. Ottieni URL

Dopo il deploy:
```
https://video-proxy.YOUR_SUBDOMAIN.workers.dev
```

---

## 🔧 Configurazione App Flutter

### 1. Configura `lib/config/env.dart`

```dart
// Sostituisci con il tuo URL del worker
static const videoProxyBase = 'https://video-proxy.YOUR_SUBDOMAIN.workers.dev';

// Abilita proxy
static const bool useVideoProxy = true;
```

### 2. Riavvia App

```bash
flutter run
```

---

## 🇮🇹 Filtro Contenuti Italiani

### Opzione 1: Lato App (Flutter)

Il filtro è già integrato in `VideoProxyResolver.isItalianContent()`.

Domini italiani verificati:
- ✅ `xdevel.com` - 7 RadioVisione
- ✅ `30a-tv.com` - 30A TV
- ✅ `mediaset.net` - MediaSet
- ✅ `rai.it` - Rai
- ✅ `netplus.ch` - Netplus (Rai)
- ✅ `cloudfront.net` - AWS (IPTV-org italiano)

### Opzione 2: Lato Server (Cloudflare Worker)

Nel `server/cloudflare-worker.js`, abilita filtro:

```javascript
// Scommenta queste righe (linea ~70):
const isItalian = url.searchParams.get('italian') === 'true';
if (isItalian && !ITALIAN_DOMAINS.some(domain => hostname.includes(domain))) {
  return new Response(
    JSON.stringify({ error: 'Contenuto non italiano richiesto' }),
    { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
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
2. Riavvia app
3. Prova video italiano (es: 30A TV, 7 RadioVisione)
4. Verifica nei log: `PlayerPage: 🇮🇹 Usa proxy server`

---

## 📊 Repository Solo Italiani

### Filtro Repository IPTV-org Italian

Il repository `iptv-org-italian` è già configurato. Per filtrare solo italiani, modifica `MoviesRepository`:

```dart
// Nel parsing M3U, se è repository italiano:
if (repo.id == 'iptv-org-italian') {
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

## 💰 Costi

**Cloudflare Workers**: 
- ✅ **Gratuito**: 100.000 richieste/giorno
- 💰 **$5/mese**: 10M richieste
- 💰 **$0.50/1M**: Richieste aggiuntive

Per uso normale: **GRATUITO** ✅

---

## 🔒 Sicurezza

- ✅ **CORS abilitato** - Accesso cross-origin
- ✅ **Validazione URL** - Previene SSRF
- ✅ **Filtro server offline** - Evita errori
- ✅ **Whitelist domini** - Solo contenuti verificati

---

## 📝 Checklist

- [ ] Deploy server proxy su Cloudflare Workers
- [ ] Configura `videoProxyBase` in `env.dart`
- [ ] Abilita `useVideoProxy = true`
- [ ] Test con video italiano
- [ ] Verifica log proxy funzionante
- [ ] (Opzionale) Abilita filtro lato server

---

## 🆘 Troubleshooting

### Proxy non funziona

1. ✅ Verifica URL worker configurato correttamente
2. ✅ Verifica `useVideoProxy = true`
3. ✅ Controlla log app per errori proxy
4. ✅ Testa server proxy direttamente con curl

### Video ancora offline

1. ✅ Verifica che server originale sia online
2. ✅ Controlla che dominio non sia in `OFFLINE_SERVERS`
3. ✅ Verifica header CORS nel worker

### Contenuti non italiani

1. ✅ Aggiungi dominio in `ITALIAN_DOMAINS` (worker)
2. ✅ Verifica `VideoProxyResolver.isItalianContent()` (app)

---

## 📚 Documentazione

- 📖 `server/README.md` - Documentazione server
- 🔗 `SERVER_INTEGRATION.md` - Integrazione app
- 🇮🇹 `SETUP_SERVER_PROXY.md` - Questa guida
