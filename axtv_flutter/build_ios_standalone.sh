#!/bin/bash

# Script per build iOS standalone (Release)
# Questo script crea un build release che funziona standalone senza Xcode

set -e

echo "🔨 Build iOS Standalone - AXTV"
echo "================================"
echo ""

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica che siamo nella directory corretta
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Errore: pubspec.yaml non trovato. Esegui questo script dalla directory axtv_flutter"
    exit 1
fi

echo "📱 Verifica dispositivo iOS collegato..."
DEVICES=$(flutter devices | grep -i "ios.*mobile" || true)

if [ -z "$DEVICES" ]; then
    echo "⚠️  Nessun dispositivo iOS rilevato."
    echo "   Collega il dispositivo via USB e riprova."
    exit 1
fi

echo "✅ Dispositivi iOS trovati:"
echo "$DEVICES"
echo ""

# Clean build precedente
echo "🧹 Pulizia build precedente..."
flutter clean > /dev/null 2>&1 || true

# Get dependencies
echo "📦 Installazione dipendenze..."
flutter pub get

# Build iOS in modalità Release
echo "🔨 Building iOS in modalità Release (Standalone)..."
flutter build ios --release

echo ""
echo "${GREEN}✅ Build completato con successo!${NC}"
echo ""
echo "📱 Prossimi passi per installare l'app standalone:"
echo ""
echo "   1. Apri Xcode:"
echo "      ${YELLOW}open ios/Runner.xcworkspace${NC}"
echo ""
echo "   2. In Xcode:"
echo "      - Seleziona il dispositivo fisico dalla barra superiore"
echo "      - Vai a: Product > Scheme > Edit Scheme"
echo "      - Nella sezione 'Run', tab 'Info'"
echo "      - Imposta 'Build Configuration' su 'Release'"
echo "      - Clicca 'Close'"
echo "      - Premi Cmd+R per build e installazione"
echo ""
echo "   3. Dopo l'installazione:"
echo "      - Chiudi completamente Xcode"
echo "      - L'app funzionerà standalone sul dispositivo"
echo ""
echo "   OPPURE usa Archive per distribuzione Ad Hoc:"
echo "      - Product > Archive"
echo "      - Window > Organizer"
echo "      - Distribute App > Ad Hoc/Development"
echo ""
