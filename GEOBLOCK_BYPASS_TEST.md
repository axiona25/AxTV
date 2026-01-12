# Sistema di Bypass Geoblock e Test Riproducibilità

## ✅ Implementazioni Completate

### 1. **Repository Attivati**
- ✅ **matjava/xtream-playlist** (5 repository attivati)
  - Top IMDB Movies
  - Action Movies
  - Comedy Movies
  - Drama Movies
  - Horror Movies

### 2. **Sistema Bypass Geoblock Migliorato**

#### **Retry Automatico con Multiple Location**
- Prova automaticamente con **7 location diverse** se la prima fallisce:
  1. Location preferita (USA di default)
  2. USA (priorità alta)
  3. UK (fallback)
  4. Germania
  5. Canada
  6. Francia
  7. Italia (ultimo tentativo)

#### **Header HTTP Personalizzati per Location**
Ogni location ha header specifici:
- `Accept-Language`: Lingua del paese
- `CF-IPCountry`: Codice paese Cloudflare
- `X-Forwarded-For`: IP pubblico del paese
- `User-Agent`: Browser user agent standard

#### **Test Automatico Prima della Riproduzione**
- Per URL MP4 da `zplaypro.lat/com`, esegue test HEAD preliminare
- Verifica accessibilità con timeout breve (5 secondi)
- Se il test fallisce, mostra errore specifico prima di aprire il player

### 3. **Sistema di Retry Automatico**

#### **Come Funziona**
1. **Prima Prova**: Prova con location USA (o preferita)
2. **In Caso di Errore Geoblock**: 
   - Rileva automaticamente errori 521, 522, 403, "failed to open"
   - Prova automaticamente con la prossima location alternativa
   - Ripete fino a esaurire tutte le location o fino a successo
3. **Log Dettagliati**: Log completo di tutti i tentativi

---

## 🧪 Test Automatici Implementati

### **Test HEAD Preliminare** (per URL MP4 zplaypro)
```dart
// Testa accessibilità prima di aprire player
final response = await _dio.head(urlToPlay, options: ...);
if (response.statusCode >= 400) {
  // Mostra errore specifico senza aprire player
}
```

**Status Code Gestiti**:
- **403**: Accesso negato - Geoblocked
- **404**: Video non trovato
- **521**: Server offline (Cloudflare)
- **522/523/524**: Timeout/Connection errors

### **Retry Automatico con Location Alternative**
```dart
// In caso di errore, prova automaticamente con:
- Location 1: USA
- Location 2: UK
- Location 3: Germania
- ... fino a 7 location
```

---

## 📊 Repository Attivati per Test

| Repository | Film | Link Riproducibili? | Status |
|------------|------|---------------------|--------|
| **matjava/xtream-playlist** | Varia | ✅ SÌ (M3U8) | ✅ Attivo (5 categorie) |
| **m3u8-xtream-playlist** | ~100-400/genere | ⚠️ Dipende (alcuni offline) | ✅ Attivo (3 categorie) |
| **Cinedantan** | ~2.100 | ✅ SÌ (Archive.org) | ✅ Attivo |

**Totale repository attivi**: 9 (5 matjava + 3 m3u8-xtream + 1 Cinedantan)

---

## 🔧 Come Funziona il Bypass Geoblock

### **Passo 1: Rilevamento URL Geoblocked**
```dart
final isPotentiallyGeoblocked = urlToPlay.contains('zplaypro.lat') || 
                               urlToPlay.contains('zplaypro.com') ||
                               urlToPlay.contains('.mp4');
```

### **Passo 2: Risoluzione con Multiple Location**
```dart
final proxyResult = await _proxyResolver.resolveGeoblockedUrl(
  urlToPlay,
  preferredLocation: GeoLocation.usa,
  useProxy: true,
  tryMultipleLocations: true, // ✅ Prova più location
);
```

### **Passo 3: Test HEAD (solo per MP4 zplaypro)**
```dart
if (isDirectMp4 && urlToPlay.contains('zplaypro.lat')) {
  final response = await _dio.head(urlToPlay, ...);
  // Verifica accessibilità
}
```

### **Passo 4: Apertura Player con Header Personalizzati**
```dart
await _player.open(
  Media(urlToPlay, httpHeaders: headers),
  play: true,
);
```

### **Passo 5: Retry Automatico in Caso di Errore**
```dart
if (errore geoblock && location alternative disponibili) {
  await _retryWithDifferentLocation(nextLocation);
}
```

---

## 🎯 Strategia Bypass Geoblock

### **Livello 1: Header Personalizzati**
- Simula browser da paese specifico
- Header Cloudflare (`CF-IPCountry`)
- IP forwarding (`X-Forwarded-For`)

### **Livello 2: Multiple Location**
- Prova automaticamente 7 location diverse
- Ordine: USA → UK → Germania → Canada → Francia → Italia

### **Livello 3: Test Preliminare**
- Test HEAD prima di aprire player
- Evita tentativi inutili se URL non accessibile
- Mostra errore specifico immediatamente

### **Livello 4: Retry Automatico**
- Se la prima location fallisce, prova automaticamente con la prossima
- Continua fino a successo o esaurimento location
- Log dettagliati di tutti i tentativi

---

## 📝 Log e Debug

Il sistema genera log dettagliati per:
- ✅ Rilevamento URL geoblocked
- ✅ Scelta location
- ✅ Risultato test HEAD
- ✅ Retry con location alternative
- ✅ Errori e fallimenti

**Esempio log**:
```
PlayerPage: [GEOBLOCK] Rilevato URL potenzialmente geoblocked
ProxyResolver: [MULTI-LOCATION] Provo più location per bypassare geoblock
PlayerPage: [TEST] Testo accessibilità URL MP4...
PlayerPage: [GEOBLOCK_RETRY] Provo con location alternativa: uk (1/7)
```

---

## ⚠️ Limitazioni Note

1. **Server Offline**: Se il server `zplaypro.lat` è completamente offline (HTTP 521), nessun bypass può aiutare
2. **Geoblock Rigido**: Alcuni server potrebbero usare geoblock basato su IP reale (non bypassabile solo con header)
3. **Autenticazione Richiesta**: Se il server richiede autenticazione/token, header non bastano

---

## 🧪 Come Testare

1. **Avvia l'app**: `flutter run`
2. **Vai alla pagina On-Demand**
3. **Prova a riprodurre un film** da uno dei repository attivi
4. **Osserva i log** per vedere:
   - Quale location viene usata
   - Se ci sono retry con location alternative
   - Se il film si riproduce o fallisce

### **Test Manuale**
Per testare il bypass geoblock:
1. Trova un film con URL `zplaypro.lat` o `.mp4`
2. Prova a riprodurlo
3. Controlla i log per vedere se prova location alternative
4. Verifica se si riproduce o mostra errore

---

## 🔍 Verifica Repository

Per verificare quanti film riproducibili hai:

1. Controlla i log durante il caricamento:
   ```
   MoviesRepository: ✅ Caricati X film validi da [repository]
   ```

2. Prova a riprodurre alcuni film:
   - Se funziona → ✅ Repository riproducibile
   - Se mostra errore geoblock → ⚠️ Serve bypass migliore
   - Se mostra errore server offline → ❌ Server non disponibile

---

## 💡 Prossimi Passi (Opzionali)

1. **Implementare Proxy HTTP Reale** (richiede server proprio o servizio)
2. **Aggiungere Cache dei Link Funzionanti** (per evitare retry multipli)
3. **Implementare Fallback a Repository Alternativi** (se uno fallisce, prova altro)

---

## ✅ Risultati Attesi

Dopo questi cambiamenti:
- ✅ **Repository attivati**: 9 repository riproducibili disponibili
- ✅ **Bypass geoblock**: Prova automaticamente 7 location diverse
- ✅ **Retry automatico**: Se una location fallisce, prova la prossima
- ✅ **Test preliminare**: Evita tentativi inutili con URL non accessibili
- ✅ **Log dettagliati**: Puoi vedere esattamente cosa sta succedendo

**Prova ora l'app e verifica se i film si riproducono!**
