# Repository GitHub Pubblici per Film On-Demand Multi-Lingua

## 📋 Elenco dei Servizi e Repository Disponibili

### 1. **TMDB-To-VOD-Playlist** ⭐ (CONSIGLIATO)
- **Repository**: `https://github.com/gogetta69/TMDB-To-VOD-Playlist`
- **Tipo**: Script Python/PHP/Node.js che genera playlist dinamiche
- **Contenuti**: 
  - Film e Serie TV on-demand
  - Live TV (oltre 7.000 canali)
  - Integrazione con TMDB per metadati completi
- **Lingue**: Multi-lingua (tramite TMDB)
- **Qualità**: Variabile (HD/4K disponibili)
- **Funzionalità**:
  - Genera playlist Xtream Codes o M3U8
  - Integrazione con Real-Debrid e Premiumize (opzionale)
  - Cache dei link per ~3 ore
  - Supporto EPG per Live TV
  - Over 10.000 film adulti (disabilitato di default)
- **Vantaggi**:
  - ✅ Ricerca dinamica dei link (più affidabile)
  - ✅ Metadati completi (poster, descrizioni, trailer)
  - ✅ Supporto multi-lingua tramite TMDB
  - ✅ Compatibile con TiviMate, iMplayer, XCIPTV
- **Svantaggi**:
  - ⚠️ Richiede TMDB API Key (gratuita)
  - ⚠️ Richiede server PHP/Python/Node.js
  - ⚠️ I link vengono cercati al momento della richiesta (latenza)

---

### 2. **iptv-org/iptv** ⭐ (CONSIGLIATO - SEMPLICE)
- **Repository**: `https://github.com/iptv-org/iptv`
- **Tipo**: Collezione M3U di canali pubblici
- **Contenuti**:
  - Live TV da tutto il mondo
  - Categoria "Movies" con canali film
  - Organizzati per paese, lingua, categoria
- **Lingue**: Multi-lingua mondiale
- **Qualità**: Variabile
- **Funzionalità**:
  - Playlist M3U standard
  - Categorie: `movies.m3u`, `documentary.m3u`, ecc.
  - EPG disponibile
- **Vantaggi**:
  - ✅ Molto semplice da usare (solo URL)
  - ✅ Link diretti, no server richiesto
  - ✅ Mantenuto attivamente dalla community
  - ✅ Solo contenuti legali/pubblici
- **Svantaggi**:
  - ⚠️ Principalmente canali live, meno film on-demand
  - ⚠️ Qualità variabile
- **URL di esempio**:
  - Movies: `https://iptv-org.github.io/iptv/categories/movies.m3u`
  - Per paese: `https://iptv-org.github.io/iptv/countries/it.m3u`
  - Per lingua: `https://iptv-org.github.io/iptv/languages/ita.m3u`

---

### 3. **matjava/xtream-playlist**
- **Repository**: `https://github.com/matjava/xtream-playlist`
- **Tipo**: Collezione curata di playlist M3U8
- **Contenuti**:
  - Film trending 2024-2025
  - Serie TV popolari
  - Categorie: Action, Adventure, Animation, Comedy, ecc.
- **Lingue**: Multi-lingua
- **Qualità**: HD/4K
- **Vantaggi**:
  - ✅ Collezione curata e aggiornata
  - ✅ Link diretti M3U8
- **Svantaggi**:
  - ⚠️ Link possono diventare obsoleti
  - ⚠️ Meno documentazione

---

### 4. **m3u8-xtream/m3u8-xtream-playlist** (GIÀ INTEGRATO)
- **Repository**: `https://github.com/m3u8-xtream/m3u8-xtream-playlist`
- **Tipo**: Collezione M3U8 e Xtream playlists
- **Contenuti**: 
  - Film on-demand per genere
  - Live TV
- **Status**: ✅ Già integrato nel progetto, ma alcuni server sono offline

---

### 5. **fyildirim-debug/xtreamcodesapitom3u**
- **Repository**: `https://github.com/fyildirim-debug/xtreamcodesapitom3u`
- **Tipo**: Tool di conversione Xtream Codes API → M3U
- **Funzionalità**:
  - Converte API Xtream Codes in playlist M3U
  - Supporto Live TV e VOD (film)
  - Filtri per contenuto
  - EPG e catch-up
- **Vantaggi**:
  - ✅ Utile per convertire servizi Xtream esistenti
  - ✅ Supporto PHP, Python, Node.js
- **Svantaggi**:
  - ⚠️ Richiede server Xtream Codes esistente

---

### 6. **GOgo8Go/iptv-all**
- **Repository**: `https://github.com/GOgo8Go/iptv-all`
- **Tipo**: Collezione IPTV mondiale
- **Contenuti**: Canali da tutto il mondo organizzati per lingua
- **Lingue**: Multi-lingua mondiale
- **Vantaggi**:
  - ✅ Collezione ampia
  - ✅ Organizzata per lingua/paese
- **Svantaggi**:
  - ⚠️ Principalmente Live TV
  - ⚠️ Meno film on-demand

---

### 7. **ovosimpatico/xtream2m3u**
- **Repository**: `https://github.com/ovosimpatico/xtream2m3u`
- **Tipo**: Tool di conversione Xtream → M3U
- **Funzionalità**: Converte servizi Xtream IPTV in playlist M3U
- **Vantaggi**:
  - ✅ Semplice da usare
  - ✅ Filtri per gruppi/canali
- **Svantaggi**:
  - ⚠️ Richiede server Xtream esistente

---

## 🎯 Raccomandazioni per l'Integrazione

### Opzione 1: TMDB-To-VOD-Playlist (MIGLIORE)
**Perché**:
- Ricerca dinamica dei link (più affidabile)
- Metadati completi
- Multi-lingua garantito tramite TMDB
- Aggiornato attivamente

**Come integrare**:
1. Richiedere TMDB API Key (gratuita)
2. Deployare script su server PHP/Python/Node.js
3. Usare come server Xtream Codes o generare M3U8

### Opzione 2: iptv-org/iptv (PIÙ SEMPLICE)
**Perché**:
- Molto semplice (solo URL)
- Link diretti, no server richiesto
- Mantenuto attivamente
- Solo contenuti legali

**Come integrare**:
- Aggiungere URL direttamente: `https://iptv-org.github.io/iptv/categories/movies.m3u`
- Parsing M3U standard

### Opzione 3: Combinazione
**Strategia**:
- Usare `iptv-org/iptv` come fonte principale (affidabile)
- Usare `TMDB-To-VOD-Playlist` per metadati e ricerca link
- Aggiungere altri repository come fallback

---

## 📊 Confronto Rapido

| Repository | Semplicità | Affidabilità | Multi-Lingua | Film On-Demand | Manutenzione |
|------------|------------|--------------|--------------|----------------|--------------|
| TMDB-To-VOD-Playlist | Media | Alta | ✅ Sì | ✅ Sì | Attiva |
| iptv-org/iptv | Alta | Alta | ✅ Sì | ⚠️ Limitato | Attiva |
| matjava/xtream-playlist | Alta | Media | ✅ Sì | ✅ Sì | Media |
| m3u8-xtream-playlist | Alta | Bassa | ✅ Sì | ✅ Sì | Media |

---

## 🔗 Link Utili

- **TMDB API**: https://www.themoviedb.org/settings/api
- **Lista completa IPTV-org**: https://iptv-org.github.io/iptv/index.json
- **Documentazione M3U**: https://en.wikipedia.org/wiki/M3U

---

## ⚠️ Note Legali

Tutti questi repository forniscono link a contenuti pubblici o legali. Tuttavia:
- La disponibilità dei contenuti può variare per regione
- Alcuni link potrebbero violare copyright in alcune giurisdizioni
- È responsabilità dell'utente verificare la legalità nella propria area
- I repository vengono forniti solo per scopi educativi
