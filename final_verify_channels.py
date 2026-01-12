#!/usr/bin/env python3
"""
Script finale per verificare e pulire i canali italiani.
Testa accuratamente gli URL e rimuove solo quelli che chiaramente non funzionano.
"""

import json
import requests
from pathlib import Path
from typing import List, Dict, Any
import time

REQUEST_TIMEOUT = 12

# Canali italiani da verificare
ITALIAN_CHANNEL_IDS = {
    'rai1', 'rai2', 'rai3', 'rai4', 'rai5', 'raimovie', 'raiyoyo', 'raipremium',
    'rete4', 'canale5', 'italia1', 'la7', 'tv8', 'nove', '20mediaset', 'iris',
    'realtime', 'topcrime', 'focus', 'dmax', 'giallo', 'mediaset_extra',
    'boing', 'cartoonito', 'super', 'k2', 'frisbee', 'food_network'
}

def test_channel_url(stream_url: str, license: str = None) -> tuple[bool, str]:
    """
    Testa accuratamente un URL di canale.
    Restituisce (is_valid, reason)
    """
    try:
        # Schema zappr:// è sempre valido (risolto dall'app)
        if stream_url.startswith('zappr://'):
            return (True, "Schema zappr:// valido")
        
        # Determina quale API usare (come fa l'app)
        api_url = None
        if 'mediapolis.rai.it' in stream_url or 'akamaized.net' in stream_url:
            api_url = f'https://vercel-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
        elif 'viamotionhsi.netplus.ch' in stream_url or 'dailymotion.com' in stream_url or 'cloudfront.net' in stream_url:
            api_url = f'https://cloudflare-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
        
        if api_url:
            # Usa GET con stream per non scaricare tutto
            response = requests.get(
                api_url,
                timeout=REQUEST_TIMEOUT,
                allow_redirects=True,
                stream=True,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
            )
            
            # Leggi i primi 4KB per verificare errori
            content = b''
            try:
                for chunk in response.iter_content(chunk_size=1024):
                    content += chunk
                    if len(content) > 4096:
                        break
            except:
                pass
            
            content_str = content.decode('utf-8', errors='ignore').lower()
            final_url = str(response.url).lower()
            
            # Verifica errori comuni
            if 'video_no_available' in content_str or 'video_no_available' in final_url:
                return (False, "API restituisce video_no_available")
            
            if 'error' in content_str[:1000] and ('unavailable' in content_str[:1000] or 'not found' in content_str[:1000] or '404' in content_str[:1000]):
                return (False, f"Contiene errore: {content_str[:150]}")
            
            # Se ha un redirect valido e non contiene errori, è OK
            if response.status_code in [200, 302, 301, 307, 308]:
                # Verifica che l'URL finale non sia un errore
                if 'video_no_available' not in final_url and 'error' not in final_url:
                    return (True, f"Status {response.status_code}, redirect valido")
                else:
                    return (False, f"URL finale contiene errore")
            elif response.status_code == 404:
                return (False, "404 Not Found")
            elif response.status_code >= 500:
                return (False, f"Server error {response.status_code}")
            else:
                # Altri status code potrebbero essere OK (es. 405 Method Not Allowed con HEAD, ma GET funziona)
                # In questo caso, se non contiene errori nel contenuto, proviamo a considerarlo valido
                if 'video_no_available' not in content_str and 'error' not in content_str[:500]:
                    return (True, f"Status {response.status_code}, nessun errore nel contenuto")
                return (False, f"Status {response.status_code}")
        
        # Per URL HLS diretti (.m3u8, .mpd), prova GET limitato
        if stream_url.endswith('.m3u8') or '.m3u8' in stream_url or stream_url.endswith('.mpd') or stream_url.endswith('.isml'):
            try:
                response = requests.get(
                    stream_url,
                    timeout=REQUEST_TIMEOUT,
                    allow_redirects=True,
                    stream=True,
                    headers={
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                    }
                )
                # Leggi solo l'header (primi 2KB)
                content = b''
                for chunk in response.iter_content(chunk_size=512):
                    content += chunk
                    if len(content) > 2048:
                        break
                
                if response.status_code in [200, 302, 301]:
                    # Verifica che non sia un errore
                    content_str = content.decode('utf-8', errors='ignore').lower()
                    if 'video_no_available' in content_str or ('error' in content_str and 'not found' in content_str):
                        return (False, "Contiene errore nel contenuto")
                    return (True, f"Status {response.status_code}")
                elif response.status_code == 404:
                    return (False, "404 Not Found")
                else:
                    return (False, f"Status {response.status_code}")
            except requests.exceptions.Timeout:
                return (False, "Timeout")
            except requests.exceptions.ConnectionError:
                return (False, "Errore connessione")
            except Exception as e:
                return (False, f"Errore: {str(e)[:50]}")
        
        # Default: prova GET
        try:
            response = requests.get(
                stream_url,
                timeout=REQUEST_TIMEOUT,
                allow_redirects=True,
                stream=True,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
            )
            # Leggi solo l'header
            for chunk in response.iter_content(chunk_size=512):
                if len(chunk) > 0:
                    break
            
            if response.status_code in [200, 302, 301]:
                return (True, f"Status {response.status_code}")
            elif response.status_code == 404:
                return (False, "404 Not Found")
            else:
                return (False, f"Status {response.status_code}")
        except requests.exceptions.Timeout:
            return (False, "Timeout")
        except requests.exceptions.ConnectionError:
            return (False, "Errore connessione")
        except Exception as e:
            return (False, f"Errore: {str(e)[:50]}")
            
    except Exception as e:
        return (False, f"Errore generico: {str(e)[:50]}")

def main():
    channels_file = Path('channels.json')
    
    if not channels_file.exists():
        print(f"❌ File non trovato: {channels_file}")
        return
    
    print("=" * 70)
    print("🔍 VERIFICA FINALE CANALI ITALIANI")
    print("=" * 70)
    print()
    
    # Carica tutti i canali
    print(f"📖 Caricamento file: {channels_file}")
    with open(channels_file, 'r', encoding='utf-8') as f:
        all_channels = json.load(f)
    
    # Separa canali italiani e altri
    italian_channels = [ch for ch in all_channels if ch.get('id', '').lower() in ITALIAN_CHANNEL_IDS]
    other_channels = [ch for ch in all_channels if ch.get('id', '').lower() not in ITALIAN_CHANNEL_IDS]
    
    print(f"📺 Totale canali: {len(all_channels)}")
    print(f"🇮🇹 Canali italiani da verificare: {len(italian_channels)}")
    print(f"🌍 Altri canali (mantenuti): {len(other_channels)}")
    print()
    
    valid_italian = []
    invalid_italian = []
    
    # Verifica ogni canale italiano
    for i, channel in enumerate(italian_channels, 1):
        channel_id = channel.get('id', 'unknown')
        channel_name = channel.get('name', 'Unknown')
        stream_url = channel.get('streamUrl', '')
        license = channel.get('license')
        
        print(f"[{i}/{len(italian_channels)}] {channel_name} ({channel_id})")
        print(f"  URL: {stream_url[:75]}..." if len(stream_url) > 75 else f"  URL: {stream_url}")
        
        is_valid, reason = test_channel_url(stream_url, license)
        
        if is_valid:
            print(f"  ✅ Valido: {reason}")
            valid_italian.append(channel)
        else:
            print(f"  ❌ Non valido: {reason}")
            invalid_italian.append(channel)
        
        time.sleep(0.4)  # Pausa per non sovraccaricare
        print()
    
    # Combina canali validi italiani + tutti gli altri
    final_channels = valid_italian + other_channels
    
    print("=" * 70)
    print("📊 RISULTATI FINALI")
    print("=" * 70)
    print(f"✅ Canali italiani validi: {len(valid_italian)}/{len(italian_channels)}")
    print(f"❌ Canali italiani rimossi: {len(invalid_italian)}")
    print(f"🌍 Altri canali mantenuti: {len(other_channels)}")
    print(f"📺 Totale canali finali: {len(final_channels)}")
    print()
    
    if invalid_italian:
        print("❌ Canali italiani rimossi:")
        for channel in invalid_italian:
            print(f"   - {channel.get('name')} ({channel.get('id')})")
        print()
    
    if valid_italian:
        print("✅ Canali italiani validi mantenuti:")
        for channel in valid_italian:
            print(f"   - {channel.get('name')} ({channel.get('id')})")
        print()
    
    # Backup e salvataggio
    backup_file = channels_file.with_suffix('.json.backup')
    if not backup_file.exists():
        print(f"💾 Backup del file originale: {backup_file}")
        import shutil
        shutil.copy2(channels_file, backup_file)
    else:
        print(f"💾 Backup già esistente: {backup_file}")
    
    print(f"💾 Salvataggio file aggiornato: {channels_file}")
    with open(channels_file, 'w', encoding='utf-8') as f:
        json.dump(final_channels, f, indent=2, ensure_ascii=False)
    
    print()
    print("✅ Completato!")
    print(f"   Canali rimossi: {len(invalid_italian)}")
    print(f"   File aggiornato: {channels_file}")

if __name__ == '__main__':
    main()
