# Setup Repository GitHub

## 📋 Passi per creare e pubblicare su GitHub

### 1. Crea il repository su GitHub

1. Vai su [github.com](https://github.com) e accedi
2. Clicca su **"+"** in alto a destra → **"New repository"**
3. Compila i campi:
   - **Repository name**: `axtv` (o un nome a tua scelta)
   - **Description**: "AxTV - Mobile app Flutter per streaming canali TV"
   - **Visibility**: Scegli Public o Private
   - **NON** inizializzare con README, .gitignore o license (già presenti)
4. Clicca **"Create repository"**

### 2. Collega il repository locale a GitHub

✅ **Il commit iniziale è già stato fatto!** 

Dopo aver creato il repository su GitHub, esegui questi comandi:

```bash
# Collega al repository remoto (sostituisci USERNAME con il tuo username GitHub)
git remote add origin https://github.com/USERNAME/axtv.git

# Oppure se usi SSH:
# git remote add origin git@github.com:USERNAME/axtv.git

# Push del codice
git push -u origin main
```

**Nota**: Se il repository GitHub è stato creato con un branch diverso da `main`, usa:
```bash
git push -u origin main:master  # se GitHub usa 'master'
```

### 3. Crea repository separato per channels.json (Opzionale)

Se vuoi mantenere i canali in un repository separato (come ZapprTV/channels):

1. Crea un nuovo repository: `channels` (o `axtv-channels`)
2. Carica il file `channels.json`
3. Copia l'URL RAW e incollalo in `lib/config/env.dart`:
   ```dart
   static const channelsJsonUrl = 'https://raw.githubusercontent.com/USERNAME/channels/main/channels.json';
   ```

### 4. Verifica

Dopo il push, verifica che tutto sia stato caricato correttamente visitando:
- `https://github.com/USERNAME/axtv`

## 🔐 Autenticazione GitHub

Se è la prima volta che usi Git su questo Mac, configura:

```bash
git config --global user.name "Tuo Nome"
git config --global user.email "tua.email@example.com"
```

Per l'autenticazione, GitHub richiede un Personal Access Token:
1. Vai su GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Genera un nuovo token con permessi `repo`
3. Usa il token come password quando Git lo richiede

## 📝 Note

- Il file `channels.json` è nel `.gitignore` (non verrà committato)
- Usa `channels.example.json` come template
- Ricorda di configurare `Env.channelsJsonUrl` dopo aver caricato channels.json su GitHub

