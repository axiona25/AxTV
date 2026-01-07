# Analisi API e Player di Zappr.stream

## Come funziona Zappr sul web

### 1. Configurazione API

Zappr usa un file `config.json` con questa struttura:

```json
{
  "config": {
    "backend": {
      "host": {
        "vercel": "https://vercel-api.zappr.stream",
        "cloudflare": "https://cloudflare-api.zappr.stream",
        "alwaysdata": "https://zappr.alwaysdata.net"
      }
    }
  }
}
```

### 2. Costruzione URL API

Quando un canale richiede l'uso di un'API, Zappr costruisce l'URL così:

```javascript
if (api) {
    url = `${window["zappr"].config.backend.host[api]}/api?${url}`;
}
```

**Esempio:**
- URL originale: `https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=2606803`
- API: `"vercel"`
- URL finale: `https://vercel-api.zappr.stream/api?https%3A%2F%2Fmediapolis.rai.it%2Frelinker%2FrelinkerServlet.htm%3Fcont%3D2606803`

### 3. Player Video.js

Zappr usa **Video.js** come player, che:
- Supporta HLS, DASH, e altri formati
- Gestisce automaticamente i redirect e gli stream
- Ha `retryOnError: true` per riprovare automaticamente
- Supporta DRM e EME

### 4. Gestione Errori

Zappr gestisce gli errori del player così:
- **Codice 2 (NETWORK)**: Errore di rete, mostra modal con dettagli
- **Codice 3 (DECODE)**: Errore di decodifica
- **Codice 4 (SRC_NOT_SUPPORTED)**: Formato non supportato
- **Fallback**: Se c'è un `fallbackType` e `fallbackURL`, prova automaticamente

### 5. Differenze con la nostra implementazione

**Zappr (web):**
- Passa l'URL dell'API direttamente a Video.js
- Video.js gestisce automaticamente redirect e stream
- Non fa chiamate HTTP per verificare l'URL prima

**La nostra app Flutter:**
- Usiamo `media_kit` che è diverso da Video.js
- Potremmo dover gestire i redirect manualmente
- L'API Zappr potrebbe restituire direttamente lo stream o fare redirect

## Raccomandazioni per Flutter

1. **L'API Zappr funziona come proxy diretto**: L'URL `https://vercel-api.zappr.stream/api?URL_ENCODED` restituisce direttamente lo stream HLS/M3U8

2. **Non serve seguire redirect manualmente**: `media_kit` dovrebbe gestire automaticamente gli stream HLS

3. **Possibile problema**: L'API potrebbe richiedere header specifici o potrebbe non funzionare correttamente con `media_kit` su tutte le piattaforme

4. **Soluzione**: Verificare se l'API restituisce direttamente lo stream o fa redirect, e gestire di conseguenza

