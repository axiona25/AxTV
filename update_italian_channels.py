#!/usr/bin/env python3
"""
Script per aggiornare i canali italiani con URL aggiornati.
Cerca URL aggiornati e testa con GET invece di HEAD per evitare falsi negativi.
"""

import json
import requests
from pathlib import Path
from typing import List, Dict, Any, Optional
import time

REQUEST_TIMEOUT = 10

# URL aggiornati da testare (potrebbero essere più recenti)
UPDATED_URLS = {
    'rai1': [
        'https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=2606803',
        'https://viamotionhsi.netplus.ch/live/eds/rai1/browser-HLS8/rai1.m3u8',
    ],
    'rai2': [
        'https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=308718',
        'https://viamotionhsi.netplus.ch/live/eds/rai2/browser-HLS8/rai2.m3u8',
    ],
    'rai3': [
        'https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=308719',
        'https://viamotionhsi.netplus.ch/live/eds/rai3/browser-HLS8/rai3.m3u8',
    ],
    'la7': [
        'https://d15umi5iaezxgx.cloudfront.net/LA7/DRM/DASH/Live.mpd',
        'zappr://la7/live',
    ],
}

def test_url_with_get(stream_url: str, license: str = None) -> tuple[bool, str, Optional[str]]:
    """
    Testa un URL con GET (più affidabile di HEAD).
    Restituisce (is_valid, message, final_url)
    """
    try:
        # Schema zappr:// è sempre valido
        if stream_url.startswith('zappr://'):
            return (True, "Schema zappr://", stream_url)
        
        # Determina quale API usare
        api_url = None
        if 'mediapolis.rai.it' in stream_url or 'akamaized.net' in stream_url:
            api_url = f'https://vercel-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
        elif 'viamotionhsi.netplus.ch' in stream_url or 'dailymotion.com' in stream_url or 'cloudfront.net' in stream_url:
            api_url = f'https://cloudflare-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
        
        if api_url:
            # Usa GET con stream=True per non scaricare tutto
            response = requests.get(
                api_url,
                timeout=REQUEST_TIMEOUT,
                allow_redirects=True,
                stream=True
            )
            
            # Leggi solo i primi 2KB per verificare errori
            content = b''
            for chunk in response.iter_content(chunk_size=512):
                content += chunk
                if len(content) > 2048:
                    break
            
            content_str = content.decode('utf-8', errors='ignore').lower()
            final_url = str(response.url)
            
            # Verifica se contiene errori comuni
            if 'video_no_available' in content_str or 'video_no_available' in final_url.lower():
                return (False, "API restituisce video_no_available", final_url)
            if 'error' in content_str[:500] and ('unavailable' in content_str[:500] or 'not found' in content_str[:500]):
                return (False, f"Contiene errore: {content_str[:100]}", final_url)
            
            # Se ha un redirect valido e non contiene errori, è OK
            if response.status_code in [200, 302, 301, 307, 308]:
                # Verifica che l'URL finale non sia un errore
                if 'video_no_available' not in final_url.lower() and 'error' not in final_url.lower():
                    return (True, f"Status {response.status_code}, redirect OK", final_url)
                else:
                    return (False, f"URL finale contiene errore: {final_url[:100]}", final_url)
            else:
                return (False, f"Status {response.status_code}", final_url)
        
        # Per URL HLS diretti, prova GET limitato
        if stream_url.endswith('.m3u8') or '.m3u8' in stream_url or stream_url.endswith('.mpd'):
            try:
                response = requests.get(
                    stream_url,
                    timeout=REQUEST_TIMEOUT,
                    allow_redirects=True,
                    stream=True
                )
                # Leggi solo l'header
                content = b''
                for chunk in response.iter_content(chunk_size=512):
                    content += chunk
                    if len(content) > 1024:
                        break
                
                if response.status_code in [200, 302, 301]:
                    return (True, f"Status {response.status_code}", str(response.url))
                else:
                    return (False, f"Status {response.status_code}", str(response.url))
            except Exception as e:
                return (False, f"Errore: {str(e)[:50]}", None)
        
        # Default: prova GET
        try:
            response = requests.get(
                stream_url,
                timeout=REQUEST_TIMEOUT,
                allow_redirects=True,
                stream=True
            )
            # Leggi solo l'header
            for chunk in response.iter_content(chunk_size=512):
                if len(chunk) > 0:
                    break
            
            if response.status_code in [200, 302, 301]:
                return (True, f"Status {response.status_code}", str(response.url))
            else:
                return (False, f"Status {response.status_code}", str(response.url))
        except Exception as e:
            return (False, f"Errore: {str(e)[:50]}", None)
            
    except Exception as e:
        return (False, f"Errore: {str(e)[:50]}", None)

def find_best_url(channel_id: str, current_url: str, license: str = None) -> tuple[bool, str, str]:
    """
    Trova il miglior URL per un canale testando diverse opzioni.
    Restituisce (found_valid, best_url, message)
    """
    # Se è zappr://, è sempre valido
    if current_url.startswith('zappr://'):
        return (True, current_url, "Schema zappr:// valido")
    
    # Testa l'URL corrente
    is_valid, message, final_url = test_url_with_get(current_url, license)
    if is_valid:
        return (True, current_url, message)
    
    # Se l'URL corrente non funziona, prova URL alternativi
    if channel_id in UPDATED_URLS:
        print(f"  🔄 Provo URL alternativi per {channel_id}...")
        for alt_url in UPDATED_URLS[channel_id]:
            if alt_url == current_url:
                continue  # Già testato
            time.sleep(0.5)
            is_valid, message, _ = test_url_with_get(alt_url, license)
            if is_valid:
                print(f"  ✅ Trovato URL alternativo valido!")
                return (True, alt_url, f"URL alternativo: {message}")
    
    return (False, current_url, message)

def main():
    channels_file = Path('channels.json')
    backup_file = channels_file.with_suffix('.json.backup')
    
    # Ripristina il backup se esiste
    if backup_file.exists() and not channels_file.exists():
        print(f"📂 Ripristino backup: {backup_file} -> {channels_file}")
        import shutil
        shutil.copy2(backup_file, channels_file)
    
    if not channels_file.exists():
        print(f"❌ File non trovato: {channels_file}")
        return
    
    print("=" * 70)
    print("🔄 AGGIORNAMENTO CANALI ITALIANI")
    print("=" * 70)
    print()
    
    # Carica tutti i canali
    print(f"📖 Caricamento file: {channels_file}")
    with open(channels_file, 'r', encoding='utf-8') as f:
        all_channels = json.load(f)
    
    # Identifica canali italiani (quelli che vogliamo verificare/aggiornare)
    italian_channel_ids = {
        'rai1', 'rai2', 'rai3', 'rai4', 'rai5', 'raimovie', 'raiyoyo', 'raipremium',
        'rete4', 'canale5', 'italia1', 'la7', 'tv8', 'nove', '20mediaset', 'iris',
        'realtime', 'topcrime', 'focus', 'dmax', 'giallo', 'mediaset_extra',
        'boing', 'cartoonito', 'super', 'k2', 'frisbee', 'food_network'
    }
    
    updated_count = 0
    valid_count = 0
    invalid_count = 0
    
    # Processa ogni canale
    for channel in all_channels:
        channel_id = channel.get('id', '').lower()
        
        # Se non è un canale italiano, salta
        if channel_id not in italian_channel_ids:
            continue
        
        channel_name = channel.get('name', 'Unknown')
        current_url = channel.get('streamUrl', '')
        license = channel.get('license')
        
        print(f"🔍 {channel_name} ({channel_id})")
        print(f"   URL corrente: {current_url[:70]}..." if len(current_url) > 70 else f"   URL corrente: {current_url}")
        
        found_valid, best_url, message = find_best_url(channel_id, current_url, license)
        
        if found_valid:
            if best_url != current_url:
                print(f"   ✅ URL aggiornato: {message}")
                channel['streamUrl'] = best_url
                updated_count += 1
            else:
                print(f"   ✅ URL valido: {message}")
            valid_count += 1
        else:
            print(f"   ❌ URL non valido: {message}")
            invalid_count += 1
        
        time.sleep(0.5)
        print()
    
    print("=" * 70)
    print("📊 RISULTATI")
    print("=" * 70)
    print(f"✅ Canali validi: {valid_count}")
    print(f"🔄 Canali aggiornati: {updated_count}")
    print(f"❌ Canali non validi: {invalid_count}")
    print()
    
    # Rimuovi i canali non validi
    if invalid_count > 0:
        print("⚠️  Rimuovo canali non validi...")
        all_channels = [ch for ch in all_channels 
                       if ch.get('id', '').lower() not in italian_channel_ids or 
                       test_url_with_get(ch.get('streamUrl', ''), ch.get('license'))[0]]
        print(f"📺 Canali rimanenti: {len(all_channels)}")
        print()
    
    # Backup e salvataggio
    if not backup_file.exists():
        print(f"💾 Backup del file originale: {backup_file}")
        import shutil
        shutil.copy2(channels_file, backup_file)
    
    print(f"💾 Salvataggio file aggiornato: {channels_file}")
    with open(channels_file, 'w', encoding='utf-8') as f:
        json.dump(all_channels, f, indent=2, ensure_ascii=False)
    
    print()
    print("✅ Completato!")

if __name__ == '__main__':
    main()
