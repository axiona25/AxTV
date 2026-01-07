# AxTV - Mobile App Flutter

App mobile Flutter collegata alle API Zappr per la riproduzione di canali streaming.

## 🚀 Setup

1. Installa le dipendenze:
```bash
flutter pub get
```

2. Genera i file di serializzazione JSON:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Configura l'URL dei canali in `lib/config/env.dart`:
   - **Opzione 1 (Consigliata)**: Carica `channels.json` su GitHub e usa l'URL RAW
   - **Opzione 2 (Test)**: Usa un GitHub Gist temporaneo per testare

4. Per iOS, assicurati che il Podfile abbia almeno:
```ruby
platform :ios, '12.0'
```
Poi esegui:
```bash
cd ios && pod install && cd ..
```

## 📋 Preparazione Canali

### Opzione 1: Usa channels.json locale

Il file `channels.json` nella root contiene un esempio pronto. Per usarlo:

1. Carica `channels.json` su GitHub (crea un repo o usa un Gist)
2. Copia l'URL RAW
3. Incollalo in `lib/config/env.dart` → `Env.channelsJsonUrl`

### Opzione 2: Converti M3U → channels.json

Usa lo script Python incluso per convertire una playlist M3U in `channels.json`:

```bash
# 1. Metti il tuo playlist.m3u nella root del progetto
# 2. Esegui lo script
python3 m3u_to_channels.py

# 3. Verrà creato channels.json
# 4. Caricalo su GitHub e usa l'URL RAW in lib/config/env.dart
```

**Requisiti**: Python ≥3.9 (solo librerie standard)

Lo script estrae automaticamente:
- Nome canale (da `#EXTINF`)
- Logo (da `tvg-logo`)
- URL stream
- Genera ID slug automatico

## 🔄 Flusso Completo (Zero Backend)

```
GitHub RAW (channels.json)
        ↓
Flutter App (carica lista)
        ↓
StreamResolver (risolve URL)
        ↓
Zappr API pubbliche
  ├─ Cloudflare API (Dailymotion, Livestream, Netplus)
  └─ Vercel API (Rai Mediapolis, Babylon Cloud)
        ↓
media_kit Player (riproduzione HLS/DASH)
```

**Nota**: L'app gestisce automaticamente la risoluzione degli URL:
- Link Rai → passano automaticamente da API Vercel
- Link Dailymotion → passano automaticamente da API Cloudflare
- URL HLS diretti (.m3u8) → riprodotti direttamente

## 📁 Struttura

- `lib/config/env.dart` - Configurazione URL API e canali
- `lib/core/http/dio_client.dart` - Client HTTP con Dio
- `lib/features/channels/` - Feature canali (modello, repository, UI, state)
- `lib/features/player/` - Feature player video con media_kit
- `m3u_to_channels.py` - Script Python per convertire M3U
- `channels.json` - File JSON canali (locale, da caricare su GitHub)
- `channels.example.json` - Esempio di formato JSON

## 📝 Formato JSON Canali

Il file `channels.json` deve essere un array di oggetti:

```json
[
  {
    "id": "rai1",
    "name": "Rai 1",
    "logo": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Rai_1_-_Logo_2016.svg/512px-Rai_1_-_Logo_2016.svg.png",
    "streamUrl": "https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=2606803"
  },
  {
    "id": "rai2",
    "name": "Rai 2",
    "logo": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Rai_2_-_Logo_2016.svg/512px-Rai_2_-_Logo_2016.svg.png",
    "streamUrl": "https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=308718"
  }
]
```

**Campi**:
- `id` (string, richiesto): Identificatore univoco slug
- `name` (string, richiesto): Nome del canale
- `logo` (string, opzionale): URL del logo
- `streamUrl` (string, richiesto): URL dello stream (verrà risolto automaticamente se necessario)

## 🛠 Stack

- Flutter 3.x
- Dio (HTTP)
- Riverpod (state management)
- go_router (routing)
- media_kit (video player per HLS/DASH)
- json_serializable (modelli)

## 🚀 Prossimi Step (Opzionali)

- ⭐ Preferiti (locali)
- 🔎 Ricerca canali
- 📺 Categorie / gruppi
- 🔄 Fallback automatico se una API non risponde
- 📱 Modalità landscape + fullscreen
- 🧪 Test su Android TV / Fire TV (stesso codice)
