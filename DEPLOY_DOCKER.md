# 🐳 Deploy Video Proxy Server su Docker Desktop

Guida completa per deploy del server proxy video su Docker Desktop.

---

## ✅ Prerequisiti

- ✅ **Docker Desktop** installato e avviato
- ✅ **Docker Compose** (incluso in Docker Desktop)
- ✅ **Porta 3000** libera (o modifica porta)

---

## 🚀 Deploy in 3 Passi

### 1. Vai nella cartella server

```bash
cd server
```

### 2. Avvia con Docker Compose

```bash
docker-compose up -d
```

### 3. Verifica che funzioni

```bash
curl http://localhost:3000/health
```

Risposta attesa:
```json
{"status":"ok","service":"video-proxy"}
```

---

## 🧪 Test Rapido

### Health Check
```bash
curl http://localhost:3000/health
```

### Test Video Italiano
```bash
curl "http://localhost:3000?url=https://30a-tv.com/feeds/pzaz/30atvmovies.m3u8"
```

Se funziona, vedrai il contenuto M3U8! ✅

---

## 🔧 Configurazione App Flutter

### Per Test Locale (macOS/Linux/Windows)

Il file `lib/config/env.dart` è già configurato:

```dart
static const videoProxyBase = 'http://localhost:3000';
static const bool useVideoProxy = true;  // ✅ Abilitato
```

### Per Emulatore Android

Se usi emulatore Android, cambia in `env.dart`:

```dart
static const videoProxyBase = 'http://10.0.2.2:3000';  // Android emulator
```

### Per Dispositivo Fisico

Trova IP locale del tuo computer:
```bash
# macOS/Linux
ifconfig | grep "inet "
# Windows
ipconfig
```

Poi modifica `env.dart`:
```dart
static const videoProxyBase = 'http://192.168.1.XXX:3000';  // IP locale
```

E modifica `docker-compose.yml`:
```yaml
ports:
  - "0.0.0.0:3000:3000"  # Espone su tutte le interfacce
```

---

## 📊 Comandi Utili

### Avvia Server
```bash
docker-compose up -d
```

### Ferma Server
```bash
docker-compose down
```

### Vedi Log
```bash
docker-compose logs -f
```

### Ricostruisci (dopo modifiche)
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Stato Container
```bash
docker-compose ps
```

### Rimuovi Container
```bash
docker-compose down -v  # Rimuove anche volumi
```

---

## 🎬 Test App Flutter

### 1. Avvia Docker Server

```bash
cd server
docker-compose up -d
```

### 2. Verifica Health Check

```bash
curl http://localhost:3000/health
```

### 3. Riavvia App Flutter

```bash
flutter run
```

### 4. Prova Video Italiano

Cerca:
- "30A TV Classic Movies" (da 30a-tv.com)
- "7 RadioVisione" (da xdevel.com)

Nei log dovresti vedere:
```
PlayerPage: 🇮🇹 Usa proxy server per contenuto italiano: http://localhost:3000?url=...
```

---

## 🔍 Troubleshooting

### Porta 3000 già in uso

**Soluzione 1**: Cambia porta in `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Host:Container
```

Poi aggiorna `env.dart`:
```dart
static const videoProxyBase = 'http://localhost:3001';
```

**Soluzione 2**: Trova e ferma processo:
```bash
# macOS/Linux
lsof -i :3000
kill -9 PID

# Windows
netstat -ano | findstr :3000
taskkill /PID PID /F
```

### Container non parte

```bash
# Vedi log errori
docker-compose logs video-proxy

# Ricostruisci
docker-compose build --no-cache
docker-compose up -d
```

### Video non funziona

1. ✅ Verifica server originale online:
```bash
curl -I "https://30a-tv.com/feeds/pzaz/30atvmovies.m3u8"
```

2. ✅ Testa proxy:
```bash
curl "http://localhost:3000?url=https://30a-tv.com/feeds/pzaz/30atvmovies.m3u8"
```

3. ✅ Controlla log Docker:
```bash
docker-compose logs -f video-proxy
```

### App non raggiunge Docker

**Per emulatore Android**:
```dart
static const videoProxyBase = 'http://10.0.2.2:3000';
```

**Per dispositivo fisico**:
1. Trova IP locale: `ifconfig` o `ipconfig`
2. Modifica `docker-compose.yml`:
```yaml
ports:
  - "0.0.0.0:3000:3000"
```
3. Aggiorna `env.dart`:
```dart
static const videoProxyBase = 'http://192.168.1.XXX:3000';
```

---

## 📝 Checklist

- [ ] Docker Desktop installato e avviato
- [ ] `docker-compose up -d` eseguito
- [ ] Health check funziona: `curl http://localhost:3000/health`
- [ ] Test video funziona: `curl "http://localhost:3000?url=VIDEO_URL"`
- [ ] `env.dart` configurato con URL corretto
- [ ] `useVideoProxy = true` in `env.dart`
- [ ] App Flutter riavviata
- [ ] Video italiani funzionano

---

## 🎯 Risultato Atteso

### Prima:
- ❌ Video geoblocked non funzionano
- ⚠️ Contenuti misti (italiani e non)

### Dopo:
- ✅ Video geoblocked funzionano (bypass con header italiani)
- 🇮🇹 Solo contenuti italiani (se filtro abilitato)
- 🚀 Server locale Docker funzionante

---

## 📚 Documentazione

- 🐳 `server/README_DOCKER.md` - Documentazione Docker completa
- 🔗 `SERVER_INTEGRATION.md` - Integrazione app Flutter
- 🚀 `SETUP_SERVER_PROXY.md` - Setup generale

---

## 💡 Prossimi Passi

1. ✅ Deploy Docker server
2. ✅ Test health check
3. ✅ Test video italiano
4. ✅ Configura app Flutter
5. ✅ Test app con video italiani

Se hai problemi, dimmi! 🚀
