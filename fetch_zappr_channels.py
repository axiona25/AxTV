#!/usr/bin/env python3
"""
Script per scaricare e confrontare i canali dal repository ZapprTV/channels.
"""

import json
import requests
from pathlib import Path

ZAPPR_CHANNELS_URL = 'https://raw.githubusercontent.com/ZapprTV/channels/main/channels.json'

def main():
    print("📥 Download canali da ZapprTV/channels...")
    try:
        response = requests.get(ZAPPR_CHANNELS_URL, timeout=30)
        response.raise_for_status()
        zappr_channels = response.json()
        print(f"✅ Scaricati {len(zappr_channels)} canali da ZapprTV")
        
        # Salva in un file temporaneo
        temp_file = Path('zappr_channels.json')
        with open(temp_file, 'w', encoding='utf-8') as f:
            json.dump(zappr_channels, f, indent=2, ensure_ascii=False)
        print(f"💾 Salvati in: {temp_file}")
        
        # Cerca canali italiani
        italian_ids = {'rai1', 'rai2', 'rai3', 'rai4', 'rai5', 'raimovie', 'raiyoyo', 'raipremium',
                      'rete4', 'canale5', 'italia1', 'la7', 'tv8', 'nove', '20mediaset', 'iris'}
        
        italian_channels = [ch for ch in zappr_channels if ch.get('id', '').lower() in italian_ids]
        
        print(f"\n🇮🇹 Canali italiani trovati: {len(italian_channels)}")
        print("\nURL canali italiani da ZapprTV:")
        for ch in italian_channels:
            print(f"  {ch.get('name')} ({ch.get('id')}):")
            print(f"    URL: {ch.get('streamUrl', 'N/A')}")
            print(f"    License: {ch.get('license', 'N/A')}")
            print()
        
    except Exception as e:
        print(f"❌ Errore: {e}")

if __name__ == '__main__':
    main()
