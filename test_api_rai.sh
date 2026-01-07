#!/bin/bash

echo "=== Test API Autenticazione Rai ==="
echo ""

echo "1. Test con curl (dovrebbe funzionare):"
AUTH=$(curl -s -X POST "https://zappr.alwaysdata.net/rai-akamai")
echo "Auth ottenuta: $AUTH"
echo "Lunghezza: ${#AUTH}"
echo ""

echo "2. Test con curl verbose (per vedere header):"
curl -v -X POST "https://zappr.alwaysdata.net/rai-akamai" 2>&1 | grep -E "< HTTP|Content-Type|Content-Length" | head -5
echo ""

echo "3. Test con URL Rai completo:"
RAI_URL="https://raiuno1-live.akamaized.net/hls/live/598308/raiuno1/raiuno1/playlist_ma_1800-5000.m3u8"
FULL_URL="${RAI_URL}${AUTH}"
echo "URL completo: ${FULL_URL:0:150}..."
echo ""

echo "4. Test accesso URL con auth:"
curl -s -I "${FULL_URL}" 2>&1 | head -5
echo ""

echo "5. Test accesso URL senza auth (dovrebbe fallire):"
curl -s -I "${RAI_URL}" 2>&1 | head -5
echo ""

echo "=== Fine Test ==="

