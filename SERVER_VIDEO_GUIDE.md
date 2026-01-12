# Guida: Creare il Proprio Server Video Proxy

## 🎯 Cosa si può fare

Sì, **tecnically si può creare un server video proxy** simile alle API Zappr. Ecco come:

### Opzione 1: Proxy Server (Raccomandato) ⭐

**Come funziona:**
- Il tuo server fa da intermediario tra l'app e i server video originali
- L'app chiama: `https://tuo-server.com/api?URL_ORIGINALE`
- Il server:
  1. Riceve la richiesta
  2. Aggiunge header personalizzati (per bypass geoblock)
  3. Fa richiesta al server video originale
  4. Riflette lo stream all'app (streaming proxy)

**Vantaggi:**
- ✅ Legale (solo riflette contenuti esistenti)
- ✅ Non serve storage (streaming diretto)
- ✅ Bassa larghezza di banda (solo stream pass-through)
- ✅ Può aggiungere header per bypass geoblock

**Svantaggi:**
- ⚠️ Costi server (ma bassi per streaming)
- ⚠️ Dipende dai server originali

### Opzione 2: CDN/Storage Proprio

**Come funziona:**
- Scarichi e ri-hosting contenuti sul tuo server/CDN
- L'app carica direttamente dal tuo server

**Vantaggi:**
- ✅ Controllo completo
- ✅ Performance garantite

**Svantaggi:**
- ⚠️ **LEGALE solo per contenuti pubblico dominio**
- ⚠️ Costi storage molto alti (terabyte di video)
- ⚠️ Costi bandwidth molto alti

---

## 🛠️ Implementazione: Proxy Server con Vercel/Cloudflare

### Architettura

```
App Flutter → Tuo Server Proxy → Server Video Originale → Stream
```

### Implementazione Vercel (Node.js)

Crea un file `api/proxy.js` in un progetto Vercel:

```javascript
export default async function handler(req, res) {
  const { url } = req.query;
  
  if (!url) {
    return res.status(400).json({ error: 'URL mancante' });
  }

  try {
    // Decodifica URL
    const videoUrl = decodeURIComponent(url);
    
    // Header personalizzati per bypass geoblock
    const headers = {
      'Accept': 'video/mp4, video/*, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'CF-IPCountry': 'US',
      'X-Forwarded-For': '8.8.8.8',
      'Referer': 'https://www.google.com/',
      'Origin': 'https://www.google.com',
    };

    // Fetch stream dal server originale
    const response = await fetch(videoUrl, {
      method: 'GET',
      headers: headers,
    });

    if (!response.ok) {
      return res.status(response.status).json({ 
        error: `Server risponde con ${response.status}` 
      });
    }

    // Stream diretto (no buffering)
    res.setHeader('Content-Type', response.headers.get('content-type') || 'video/mp4');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Accept-Ranges', 'bytes');
    
    // Pipe stream direttamente al client
    response.body.pipeTo(
      new WritableStream({
        write(chunk) {
          res.write(chunk);
        },
        close() {
          res.end();
        }
      })
    );
    
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
```

### Deploy su Vercel

1. **Crea progetto Vercel:**
   ```bash
   npm install -g vercel
   vercel init
   ```

2. **Crea struttura:**
   ```
   tuo-progetto/
   ├── api/
   │   └── proxy.js
   ├── vercel.json
   └── package.json
   ```

3. **vercel.json:**
   ```json
   {
     "functions": {
       "api/proxy.js": {
         "maxDuration": 300
       }
     }
   }
   ```

4. **Deploy:**
   ```bash
   vercel --prod
   ```

5. **Ottieni URL:** `https://tuo-progetto.vercel.app/api/proxy`

---

## 🔧 Integrazione nell'App Flutter

### 1. Aggiungi URL Server in `env.dart`

```dart
class Env {
  // API esistenti Zappr
  static const cloudflareApiBase = 'https://cloudflare-api.zappr.stream/api';
  static const vercelApiBase = 'https://vercel-api.zappr.stream/api';
  
  // ⭐ Il TUO server proxy
  static const yourProxyApiBase = 'https://tuo-progetto.vercel.app/api/proxy';
  
  // ... resto del codice
}
```

### 2. Usa il tuo server nel `StreamResolver`

Modifica `lib/features/channels/data/stream_resolver.dart`:

```dart
Future<Uri> resolvePlayableUrlAsync(String originalUrl, {String? license}) async {
  // ... codice esistente ...
  
  // ⭐ Per URL problematici, usa il tuo server proxy
  final isProblematicUrl = originalUrl.contains('zplaypro.lat') ||
                          originalUrl.contains('zplaypro.com') ||
                          originalUrl.contains('.mp4');
  
  if (isProblematicUrl) {
    // Usa il TUO server proxy invece di provare direttamente
    final proxyUrl = '${Env.yourProxyApiBase}?${Uri.encodeComponent(originalUrl)}';
    print('StreamResolver: Uso server proxy personalizzato: $proxyUrl');
    return Uri.parse(proxyUrl);
  }
  
  // ... resto del codice ...
}
```

---

## 🌐 Alternativa: Cloudflare Workers (Gratis)

Cloudflare Workers è **gratuito** per 100.000 richieste/giorno:

### `worker.js`:

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const videoUrl = url.searchParams.get('url');
    
    if (!videoUrl) {
      return new Response('URL mancante', { status: 400 });
    }

    // Header per bypass geoblock
    const headers = {
      'Accept': 'video/mp4, video/*, */*',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'CF-IPCountry': 'US',
      'X-Forwarded-For': '8.8.8.8',
    };

    // Fetch e proxy stream
    const response = await fetch(videoUrl, { headers });
    
    return new Response(response.body, {
      headers: {
        'Content-Type': response.headers.get('content-type') || 'video/mp4',
        'Cache-Control': 'no-cache',
      },
    });
  }
};
```

### Deploy:

```bash
npm install -g wrangler
wrangler publish
```

**URL:** `https://tuo-worker.tuonome.workers.dev?url=...`

---

## ⚖️ Aspetti Legali IMPORTANTI

### ✅ LEGALE (Proxy Server):
- Riflettere stream pubblici esistenti
- Aggiungere header per bypass geoblock
- Servire contenuti pubblico dominio
- Proxy per contenuti che l'utente ha già accesso

### ❌ ILLEGALE:
- Scaricare e ri-hosting contenuti protetti da copyright
- Bypassare DRM o protezioni
- Redistribuire contenuti premium senza permessi
- Violare termini di servizio dei provider originali

### ⚠️ Nota:
I repository come IPTV-org contengono URL pubblici. Usare un proxy per accedervi è generalmente legale, MA:
- Non garantiamo che tutti gli URL siano legittimi
- Alcuni potrebbero violare copyright
- Usa solo per contenuti che sai essere legittimi

---

## 💰 Costi Stimati

### Vercel (Proxy):
- **Free tier:** 100 GB bandwidth/mese
- **Pro:** $20/mese per 1 TB bandwidth
- **Bandwidth video:** ~500 MB/ora per HD
- **Stima:** ~200 ore/mese gratis, poi $20/mese per ~2000 ore

### Cloudflare Workers (Proxy):
- **Free tier:** 100.000 richieste/giorno
- **Bandwidth:** Illimitato (ma rate limits)
- **Costo:** $0/mese per uso moderato

### Storage/CDN (Non raccomandato):
- **AWS S3 + CloudFront:** ~$0.10/GB storage + $0.085/GB transfer
- **1 TB video:** ~$100/mese + bandwidth
- **Non sostenibile** per contenuti grandi

---

## 🎯 Raccomandazione

**Usa un Proxy Server (opzione 1)** perché:
1. ✅ Legale
2. ✅ Basso costo (gratis con Cloudflare Workers)
3. ✅ Facile da implementare
4. ✅ Non serve storage
5. ✅ Può migliorare l'accessibilità degli URL esistenti

**Implementazione suggerita:**
1. Deploy un Cloudflare Worker (gratis)
2. Aggiungi URL in `env.dart`
3. Usa per URL problematici (`zplaypro.lat`, ecc.)
4. Testa con alcuni film

---

## 📝 Prossimi Passi

1. **Crea account Cloudflare** (gratis)
2. **Deploy Worker** con il codice sopra
3. **Ottieni URL** del worker
4. **Aggiungi in `env.dart`**
5. **Modifica `StreamResolver`** per usare il tuo proxy
6. **Testa** con URL problematici

Vuoi che implementi direttamente nel codice Flutter?
