# Setup Canali - Completato ✅

## ✅ Configurazione Completata

Il file `channels.json` è stato caricato su GitHub Gist e l'URL è stato configurato nell'app.

### 📍 URL Canali

- **Gist GitHub**: https://gist.github.com/axiona25/76be0f53dd8ee97efb8e7f642aed9379
- **URL RAW**: https://gist.githubusercontent.com/axiona25/76be0f53dd8ee97efb8e7f642aed9379/raw/c14a3bb13be23f0e65d20647b09748ffdef2d64d/channels.json
- **Configurato in**: `lib/config/env.dart` → `Env.channelsJsonUrl`

### 📺 Canali Disponibili

L'app caricherà automaticamente questi 5 canali:

1. **Rai 1** - Stream URL risolto via API Vercel
2. **Rai 2** - Stream URL risolto via API Vercel
3. **Rai 3** - Stream URL risolto via API Vercel
4. **LA7** - Stream URL risolto via API Cloudflare
5. **TV8** - Stream URL risolto via API Cloudflare

## 🔄 Come Aggiornare i Canali

### Opzione 1: Modifica il Gist (Veloce)

1. Vai su: https://gist.github.com/axiona25/76be0f53dd8ee97efb8e7f642aed9379
2. Clicca "Edit" (matita in alto a destra)
3. Modifica il file `channels.json`
4. Clicca "Update public gist"
5. L'app caricherà automaticamente i nuovi canali al prossimo refresh

### Opzione 2: Crea Repository Dedicato (Consigliato per Produzione)

1. Crea un nuovo repository: `axtv-channels`
2. Carica `channels.json` nel repository
3. Copia l'URL RAW del file
4. Aggiorna `lib/config/env.dart`:
   ```dart
   static const channelsJsonUrl = 'https://raw.githubusercontent.com/axiona25/axtv-channels/main/channels.json';
   ```

## 🧪 Test

Per verificare che tutto funzioni:

1. Avvia l'app: `flutter run -d chrome` (o altro dispositivo)
2. L'app dovrebbe caricare automaticamente i 5 canali
3. Clicca su un canale per vedere il player

## 📝 Note

- Il file `channels.json` locale è nel `.gitignore` (non viene committato)
- Usa `channels.example.json` come template per nuovi canali
- Lo StreamResolver gestisce automaticamente la risoluzione degli URL:
  - Link Rai → API Vercel
  - Link Dailymotion → API Cloudflare
  - URL HLS diretti → riproduzione diretta

