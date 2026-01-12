#!/usr/bin/env python3
"""
Script per verificare e aggiornare gli URL dei canali.
Rimuove i canali con URL scaduti o non funzionanti.
"""

import json
import requests
from pathlib import Path
from typing import List, Dict, Any
import time

# Timeout per le richieste
REQUEST_TIMEOUT = 10

def test_url(stream_url: str, license: str = None) -> tuple[bool, str]:
    """
    Testa un URL per verificare se restituisce un errore o video_no_available.
    Restituisce (is_valid, error_message)
    """
    try:
        # Se è uno schema zappr://, non possiamo testarlo direttamente
        # ma lo consideriamo valido (sarà risolto dall'app)
        if stream_url.startswith('zappr://'):
            return (True, "Schema zappr:// (risolto dall'app)")
        
        # Se è un URL mediapolis.rai.it, testa tramite API Vercel
        if 'mediapolis.rai.it' in stream_url:
            api_url = f'https://vercel-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
            try:
                response = requests.get(
                    api_url,
                    timeout=REQUEST_TIMEOUT,
                    allow_redirects=True,
                    stream=True
                )
                # Leggi solo i primi 1KB per verificare errori
                content = b''
                for chunk in response.iter_content(chunk_size=1024):
                    content += chunk
                    if len(content) > 1024:
                        break
                
                content_str = content.decode('utf-8', errors='ignore').lower()
                
                # Verifica se contiene errori comuni
                if 'video_no_available' in content_str or 'error' in content_str or 'unavailable' in content_str:
                    return (False, f"API restituisce errore: {content_str[:200]}")
                
                # Se ha un redirect valido, è OK
                if response.status_code in [200, 302, 301]:
                    return (True, f"Status {response.status_code}")
                else:
                    return (False, f"Status code: {response.status_code}")
            except Exception as e:
                return (False, f"Errore test API: {str(e)}")
        
        # Se è un URL viamotionhsi.netplus.ch, testa tramite API Cloudflare
        if 'viamotionhsi.netplus.ch' in stream_url:
            api_url = f'https://cloudflare-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
            try:
                response = requests.get(
                    api_url,
                    timeout=REQUEST_TIMEOUT,
                    allow_redirects=True,
                    stream=True
                )
                content = b''
                for chunk in response.iter_content(chunk_size=1024):
                    content += chunk
                    if len(content) > 1024:
                        break
                
                content_str = content.decode('utf-8', errors='ignore').lower()
                
                if 'video_no_available' in content_str or 'error' in content_str or 'unavailable' in content_str:
                    return (False, f"API restituisce errore: {content_str[:200]}")
                
                if response.status_code in [200, 302, 301]:
                    return (True, f"Status {response.status_code}")
                else:
                    return (False, f"Status code: {response.status_code}")
            except Exception as e:
                return (False, f"Errore test API: {str(e)}")
        
        # Per altri URL (Dailymotion, CloudFront, etc.), testa tramite API Cloudflare
        if 'dailymotion.com' in stream_url or 'cloudfront.net' in stream_url:
            api_url = f'https://cloudflare-api.zappr.stream/api?{requests.utils.quote(stream_url)}'
            try:
                response = requests.get(
                    api_url,
                    timeout=REQUEST_TIMEOUT,
                    allow_redirects=True,
                    stream=True
                )
                content = b''
                for chunk in response.iter_content(chunk_size=1024):
                    content += chunk
                    if len(content) > 1024:
                        break
                
                content_str = content.decode('utf-8', errors='ignore').lower()
                
                if 'video_no_available' in content_str or 'error' in content_str or 'unavailable' in content_str:
                    return (False, f"API restituisce errore: {content_str[:200]}")
                
                if response.status_code in [200, 302, 301]:
                    return (True, f"Status {response.status_code}")
                else:
                    return (False, f"Status code: {response.status_code}")
            except Exception as e:
                return (False, f"Errore test API: {str(e)}")
        
        # Per URL HLS diretti (.m3u8), prova a fare una richiesta HEAD
        if stream_url.endswith('.m3u8') or '.m3u8' in stream_url:
            try:
                response = requests.head(stream_url, timeout=REQUEST_TIMEOUT, allow_redirects=True)
                if response.status_code in [200, 302, 301]:
                    return (True, f"Status {response.status_code}")
                else:
                    return (False, f"Status code: {response.status_code}")
            except Exception as e:
                return (False, f"Errore HEAD request: {str(e)}")
        
        # Default: prova una richiesta HEAD
        try:
            response = requests.head(stream_url, timeout=REQUEST_TIMEOUT, allow_redirects=True)
            if response.status_code in [200, 302, 301]:
                return (True, f"Status {response.status_code}")
            else:
                return (False, f"Status code: {response.status_code}")
        except Exception as e:
            return (False, f"Errore HEAD request: {str(e)}")
            
    except Exception as e:
        return (False, f"Errore generico: {str(e)}")

def verify_channels(channels_file: Path) -> tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Verifica tutti i canali nel file JSON.
    Restituisce (valid_channels, invalid_channels)
    """
    print(f"📖 Caricamento file: {channels_file}")
    with open(channels_file, 'r', encoding='utf-8') as f:
        channels = json.load(f)
    
    print(f"📺 Trovati {len(channels)} canali da verificare\n")
    
    valid_channels = []
    invalid_channels = []
    
    for i, channel in enumerate(channels, 1):
        channel_id = channel.get('id', 'unknown')
        channel_name = channel.get('name', 'Unknown')
        stream_url = channel.get('streamUrl', '')
        license = channel.get('license')
        
        print(f"[{i}/{len(channels)}] Verificando: {channel_name} ({channel_id})")
        print(f"  URL: {stream_url[:80]}..." if len(stream_url) > 80 else f"  URL: {stream_url}")
        
        is_valid, message = test_url(stream_url, license)
        
        if is_valid:
            print(f"  ✅ Valido: {message}")
            valid_channels.append(channel)
        else:
            print(f"  ❌ Non valido: {message}")
            invalid_channels.append(channel)
        
        # Piccola pausa per non sovraccaricare le API
        time.sleep(0.5)
        print()
    
    return valid_channels, invalid_channels

def main():
    channels_file = Path('channels.json')
    
    if not channels_file.exists():
        print(f"❌ File non trovato: {channels_file}")
        return
    
    print("=" * 60)
    print("🔍 VERIFICA URL CANALI")
    print("=" * 60)
    print()
    
    valid_channels, invalid_channels = verify_channels(channels_file)
    
    print("=" * 60)
    print("📊 RISULTATI")
    print("=" * 60)
    print(f"✅ Canali validi: {len(valid_channels)}")
    print(f"❌ Canali non validi: {len(invalid_channels)}")
    print()
    
    if invalid_channels:
        print("Canali rimossi:")
        for channel in invalid_channels:
            print(f"  - {channel.get('name')} ({channel.get('id')})")
        print()
    
    # Salva i canali validi
    backup_file = channels_file.with_suffix('.json.backup')
    print(f"💾 Backup del file originale: {backup_file}")
    channels_file.rename(backup_file)
    
    output_file = channels_file
    print(f"💾 Salvataggio canali validi: {output_file}")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(valid_channels, f, indent=2, ensure_ascii=False)
    
    print()
    print("✅ Completato!")
    print(f"   File originale salvato come: {backup_file}")
    print(f"   Canali validi salvati in: {output_file}")

if __name__ == '__main__':
    main()
