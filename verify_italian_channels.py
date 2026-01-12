#!/usr/bin/env python3
"""
Script per verificare e aggiornare SOLO i canali italiani.
Rimuove i canali con URL scaduti o non funzionanti.
"""

import json
import requests
from pathlib import Path
from typing import List, Dict, Any
import time

# Timeout per le richieste
REQUEST_TIMEOUT = 8

# Canali italiani da verificare
ITALIAN_CHANNEL_IDS = {
    'rai1', 'rai2', 'rai3', 'rai4', 'rai5', 'raimovie', 'raiyoyo', 'raipremium',
    'rete4', 'canale5', 'italia1', 'la7', 'tv8', 'nove', '20mediaset', 'iris',
    'realtime', 'topcrime', 'focus', 'dmax', 'giallo', 'mediaset_extra',
    'boing', 'cartoonito', 'super', 'k2', 'frisbee', 'food_network'
}

def test_url_fast(stream_url: str, license: str = None) -> tuple[bool, str]:
    """
    Testa un URL in modo veloce verificando se restituisce un errore.
    """
    try:
        # Schema zappr:// è sempre valido (risolto dall'app)
        if stream_url.startswith('zappr://'):
            return (True, "Schema zappr://")
        
        # Determina quale API usare
        api_url = None
        if 'mediapolis.rai.it' in stream_url or 'akamaized.net' in stream_url:
            api_url = f'https://vercel-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
        elif 'viamotionhsi.netplus.ch' in stream_url or 'dailymotion.com' in stream_url or 'cloudfront.net' in stream_url:
            api_url = f'https://cloudflare-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
        
        if api_url:
            # Test veloce: solo HEAD request con timeout breve
            response = requests.head(
                api_url,
                timeout=REQUEST_TIMEOUT,
                allow_redirects=True
            )
            
            # Se ha un redirect valido, è probabilmente OK
            if response.status_code in [200, 302, 301, 307, 308]:
                # Verifica anche l'URL finale per errori comuni
                final_url = response.url if hasattr(response, 'url') else api_url
                if 'video_no_available' in final_url.lower() or 'error' in final_url.lower():
                    return (False, f"URL finale contiene errore: {final_url[:100]}")
                return (True, f"Status {response.status_code}")
            else:
                return (False, f"Status {response.status_code}")
        
        # Per URL HLS diretti, prova HEAD
        if stream_url.endswith('.m3u8') or '.m3u8' in stream_url or stream_url.endswith('.mpd'):
            try:
                response = requests.head(stream_url, timeout=REQUEST_TIMEOUT, allow_redirects=True)
                if response.status_code in [200, 302, 301]:
                    return (True, f"Status {response.status_code}")
                else:
                    return (False, f"Status {response.status_code}")
            except:
                return (False, "Errore connessione")
        
        # Default: prova HEAD
        try:
            response = requests.head(stream_url, timeout=REQUEST_TIMEOUT, allow_redirects=True)
            if response.status_code in [200, 302, 301]:
                return (True, f"Status {response.status_code}")
            else:
                return (False, f"Status {response.status_code}")
        except Exception as e:
            return (False, f"Errore: {str(e)[:50]}")
            
    except Exception as e:
        return (False, f"Errore: {str(e)[:50]}")

def main():
    channels_file = Path('channels.json')
    
    if not channels_file.exists():
        print(f"❌ File non trovato: {channels_file}")
        return
    
    print("=" * 70)
    print("🔍 VERIFICA CANALI ITALIANI")
    print("=" * 70)
    print()
    
    # Carica tutti i canali
    print(f"📖 Caricamento file: {channels_file}")
    with open(channels_file, 'r', encoding='utf-8') as f:
        all_channels = json.load(f)
    
    # Filtra solo i canali italiani
    italian_channels = [ch for ch in all_channels if ch.get('id', '').lower() in ITALIAN_CHANNEL_IDS]
    other_channels = [ch for ch in all_channels if ch.get('id', '').lower() not in ITALIAN_CHANNEL_IDS]
    
    print(f"📺 Totale canali nel file: {len(all_channels)}")
    print(f"🇮🇹 Canali italiani da verificare: {len(italian_channels)}")
    print(f"🌍 Altri canali (mantenuti): {len(other_channels)}")
    print()
    
    valid_italian = []
    invalid_italian = []
    
    # Verifica solo i canali italiani
    for i, channel in enumerate(italian_channels, 1):
        channel_id = channel.get('id', 'unknown')
        channel_name = channel.get('name', 'Unknown')
        stream_url = channel.get('streamUrl', '')
        license = channel.get('license')
        
        print(f"[{i}/{len(italian_channels)}] {channel_name} ({channel_id})")
        print(f"  URL: {stream_url[:70]}..." if len(stream_url) > 70 else f"  URL: {stream_url}")
        
        is_valid, message = test_url_fast(stream_url, license)
        
        if is_valid:
            print(f"  ✅ Valido: {message}")
            valid_italian.append(channel)
        else:
            print(f"  ❌ Non valido: {message}")
            invalid_italian.append(channel)
        
        time.sleep(0.3)  # Pausa breve
        print()
    
    # Combina canali validi italiani + tutti gli altri canali
    final_channels = valid_italian + other_channels
    
    print("=" * 70)
    print("📊 RISULTATI")
    print("=" * 70)
    print(f"✅ Canali italiani validi: {len(valid_italian)}/{len(italian_channels)}")
    print(f"❌ Canali italiani rimossi: {len(invalid_italian)}")
    print(f"🌍 Altri canali mantenuti: {len(other_channels)}")
    print(f"📺 Totale canali finali: {len(final_channels)}")
    print()
    
    if invalid_italian:
        print("Canali italiani rimossi:")
        for channel in invalid_italian:
            print(f"  ❌ {channel.get('name')} ({channel.get('id')})")
        print()
    
    if valid_italian:
        print("Canali italiani validi mantenuti:")
        for channel in valid_italian:
            print(f"  ✅ {channel.get('name')} ({channel.get('id')})")
        print()
    
    # Backup e salvataggio
    backup_file = channels_file.with_suffix('.json.backup')
    if backup_file.exists():
        print(f"⚠️  Backup esistente trovato, lo sovrascrivo...")
    
    print(f"💾 Backup del file originale: {backup_file}")
    import shutil
    shutil.copy2(channels_file, backup_file)
    
    print(f"💾 Salvataggio file aggiornato: {channels_file}")
    with open(channels_file, 'w', encoding='utf-8') as f:
        json.dump(final_channels, f, indent=2, ensure_ascii=False)
    
    print()
    print("✅ Completato!")
    print(f"   File originale salvato come: {backup_file}")
    print(f"   File aggiornato: {channels_file}")
    print(f"   Canali rimossi: {len(invalid_italian)}")

if __name__ == '__main__':
    main()
