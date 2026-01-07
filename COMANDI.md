# Comandi per Avviare l'App Flutter

## 📱 Opzione 1: Simulatore iOS (Consigliato)

```bash
# Avvia il simulatore iPhone 17 Pro
flutter run -d "iPhone 17 Pro"
```

Oppure più semplice:
```bash
flutter run
```
(Flutter selezionerà automaticamente il primo dispositivo disponibile)

## 📱 Opzione 2: Dispositivo iOS Fisico

Se vuoi usare un iPhone fisico connesso:

```bash
# iPhone Personale
flutter run -d "00008150-001A22D20AD2401C"

# iPhone Lavoro
flutter run -d "00008130-001078900843401C"
```

## 🖥️ Opzione 3: macOS Desktop

```bash
flutter run -d macos
```

## 🌐 Opzione 4: Chrome (Web)

```bash
flutter run -d chrome
```

## 🔧 Comandi Utili

### Lista dispositivi disponibili
```bash
flutter devices
```

### Hot Reload (dopo aver avviato l'app)
Premi `r` nel terminale dove gira l'app

### Hot Restart
Premi `R` (maiuscola) nel terminale

### Stop l'app
Premi `q` nel terminale

### Verifica configurazione
```bash
flutter doctor
```

### Installa dipendenze (se necessario)
```bash
flutter pub get
```

## ⚠️ Note Importanti

1. **Font Poppins**: Prima di avviare, assicurati di aver aggiunto i file font nella cartella `fonts/`:
   - `Poppins-Regular.ttf`
   - `Poppins-Medium.ttf`
   - `Poppins-Bold.ttf`

2. **Configurazione URL Canali**: Ricorda di configurare `lib/config/env.dart` con l'URL RAW del tuo `channels.json` su GitHub.

3. **iOS Pods**: Se è la prima volta che avvii su iOS, potrebbe essere necessario:
```bash
cd ios && pod install && cd ..
```

