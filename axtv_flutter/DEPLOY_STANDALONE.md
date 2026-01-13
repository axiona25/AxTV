# Deploy Standalone iOS - Guida Completa

L'app **deve essere installata in modalità Release** per funzionare standalone (senza dipendere da Xcode).

## ⚠️ Problema Comune

Quando installi l'app da Xcode in modalità **Debug**, l'app è collegata al debugger di Xcode. Se chiudi Xcode, l'app potrebbe smettere di funzionare perché dipende dal debugger.

## ✅ Soluzione: Installazione in Modalità Release

### Metodo 1: Script Automatico (Consigliato)

```bash
cd axtv_flutter
./build_ios_standalone.sh
```

Lo script:
1. Verifica che ci sia un dispositivo iOS collegato
2. Pulisce i build precedenti
3. Installa le dipendenze
4. Crea un build Release
5. Ti guida nei passaggi successivi

### Metodo 2: Manuale con Flutter CLI

```bash
cd axtv_flutter

# 1. Build release
flutter build ios --release

# 2. Apri Xcode workspace
open ios/Runner.xcworkspace
```

Poi in Xcode:
1. Seleziona il dispositivo fisico dalla barra superiore
2. Vai a: **Product > Scheme > Edit Scheme**
3. Nella sezione "Run", tab "Info"
4. Imposta **"Build Configuration"** su **"Release"** (non Debug!)
5. Clicca "Close"
6. Premi **Cmd+R** per build e installazione

### Metodo 3: Archive e Distribuzione Ad Hoc

Per distribuzione ad altri dispositivi:

```bash
cd axtv_flutter
flutter build ios --release
open ios/Runner.xcworkspace
```

In Xcode:
1. Seleziona "Any iOS Device (arm64)" dalla barra superiore
2. Vai a: **Product > Archive**
3. Attendi che l'archive sia completato
4. Vai a: **Window > Organizer**
5. Seleziona l'archive e clicca **"Distribute App"**
6. Scegli **"Ad Hoc"** o **"Development"**
7. Segui la procedura guidata per creare un file .ipa
8. Installa il .ipa sul dispositivo (via Finder, Xcode, o strumenti di terze parti)

## 🔍 Verifica Installazione Standalone

Dopo l'installazione:
1. ✅ Chiudi completamente Xcode (Cmd+Q)
2. ✅ Chiudi l'app sul dispositivo (swipe up dalla schermata multitasking)
3. ✅ Riapri l'app dal dispositivo
4. ✅ L'app dovrebbe funzionare completamente standalone
5. ✅ L'app può richiamare servizi pubblici e API integrate normalmente

## 📋 Configurazioni Verificate

- ✅ **Bundle Identifier**: `com.axtv.axtvFlutter`
- ✅ **Display Name**: `AXTV`
- ✅ **Development Team**: Configurato (`X9XM6P4N7B`)
- ✅ **Code Signing**: Automatico
- ✅ **Build Configuration Release**: Ottimizzato per produzione (`SWIFT_OPTIMIZATION_LEVEL = "-O"`)
- ✅ **Network Security**: Configurata per servizi pubblici (NSAppTransportSecurity)

## 🔧 Troubleshooting

### L'app si chiude quando chiudo Xcode

**Causa**: L'app è stata installata in modalità Debug.
**Soluzione**: Reinstalla l'app in modalità Release seguendo i passaggi sopra.

### Errore di Code Signing

**Causa**: Certificato di sviluppo non valido o provisioning profile mancante.
**Soluzione**: 
1. Vai a Xcode > Settings > Accounts
2. Seleziona il tuo Apple ID
3. Clicca "Download Manual Profiles"
4. In Xcode, seleziona il progetto Runner > Target Runner > Signing & Capabilities
5. Assicurati che "Automatically manage signing" sia selezionato

### L'app non si connette ai servizi

**Causa**: Problemi di rete o configurazione.
**Soluzione**: 
- Verifica che il dispositivo abbia connessione internet
- L'app è configurata per funzionare standalone e richiamare servizi pubblici
- Non ci sono dipendenze da Xcode per le chiamate API

## 📝 Note Importanti

1. **Debug vs Release**: 
   - **Debug**: Collegato al debugger, dipende da Xcode
   - **Release**: Standalone, funziona indipendentemente da Xcode

2. **Servizi Pubblici**: 
   - L'app è configurata per richiamare servizi pubblici e API integrate
   - Non ci sono dipendenze da Xcode per le chiamate di rete
   - L'app funziona completamente standalone dopo l'installazione corretta

3. **Code Signing**: 
   - L'app deve essere firmata con un certificato valido
   - Il provisioning profile deve corrispondere al dispositivo
   - Xcode gestisce automaticamente il code signing se configurato correttamente
