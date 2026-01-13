#!/bin/bash

# Script per installazione standalone su dispositivi iOS wireless
# Questo script builda e installa l'app in modalità Release (standalone)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "📱 Installazione Standalone iOS - AXTV"
echo "======================================"
echo ""

# Verifica che siamo nella directory corretta
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Errore: pubspec.yaml non trovato. Esegui questo script dalla directory axtv_flutter"
    exit 1
fi

# Mostra dispositivi disponibili
echo "🔍 Cercando dispositivi iOS wireless..."
DEVICES=$(flutter devices 2>&1 | grep -i "ios.*mobile\|wireless" || true)

if [ -z "$DEVICES" ]; then
    echo "⚠️  Nessun dispositivo iOS rilevato."
    echo "   Collega il dispositivo via USB o assicurati che sia collegato wireless."
    exit 1
fi

echo "✅ Dispositivi iOS trovati:"
echo "$DEVICES"
echo ""

# Seleziona dispositivo se non specificato come argomento
DEVICE_ID="$1"
if [ -z "$DEVICE_ID" ]; then
    echo "Dispositivi disponibili:"
    echo "1. iPhone Lavoro: 00008130-001078900843401C"
    echo "2. iPhone Personale: 00008150-001A22D20AD2401C"
    echo ""
    read -p "Inserisci l'ID del dispositivo (o premi Invio per iPhone Lavoro): " DEVICE_ID
    DEVICE_ID=${DEVICE_ID:-00008130-001078900843401C}
fi

echo ""
echo "${BLUE}🔨 Step 1: Pulizia build precedente...${NC}"
flutter clean > /dev/null 2>&1 || true

echo "${BLUE}📦 Step 2: Installazione dipendenze...${NC}"
flutter pub get > /dev/null 2>&1

echo "${BLUE}🔨 Step 3: Build iOS in modalità Release (Standalone)...${NC}"
flutter build ios --release

echo ""
echo "${BLUE}📱 Step 4: Installazione sul dispositivo wireless...${NC}"
flutter install --device-id "$DEVICE_ID"

echo ""
echo "${GREEN}✅ Installazione completata con successo!${NC}"
echo ""
echo "📝 Note importanti:"
echo "   - L'app è stata installata in modalità Release (standalone)"
echo "   - L'app funzionerà anche se chiudi Xcode"
echo "   - L'app può richiamare servizi pubblici e API integrate normalmente"
echo ""
echo "🧪 Per verificare:"
echo "   1. Chiudi completamente Xcode (se aperto)"
echo "   2. Apri l'app dal dispositivo"
echo "   3. L'app dovrebbe funzionare completamente standalone"
echo ""
