# Come Aggiornare gli URL dei Canali

## Problema Attuale

L'API Zappr restituisce `video_no_available.mp4` perché gli URL nel `channels.json` sono **scaduti o non validi**.

## Soluzione

Devi aggiornare gli URL dei canali nel file `channels.json` con URL validi e aggiornati.

### Opzione 1: Usa gli URL da zappr.stream

1. Vai su https://zappr.stream
2. Apri gli strumenti sviluppatore del browser (F12)
3. Vai alla tab "Network"
4. Clicca su un canale (es. Rai 1)
5. Cerca la richiesta che carica lo stream
6. Copia l'URL originale del canale (prima che venga passato all'API)
7. Aggiorna `channels.json` con l'URL corretto

### Opzione 2: Usa il repository ZapprTV/channels

Il repository ufficiale Zappr ha gli URL aggiornati:
- Repository: https://github.com/ZapprTV/channels
- Potresti dover estrarre gli URL da lì

### Opzione 3: Verifica manualmente

1. Prova l'URL direttamente nel browser
2. Se restituisce un errore o "video non disponibile", l'URL è scaduto
3. Cerca un URL più recente

## Formato channels.json

```json
[
  {
    "id": "rai1",
    "name": "Rai 1",
    "logo": "https://...",
    "streamUrl": "URL_AGGIORNATO_QUI"
  }
]
```

## Nota Importante

Gli URL dei canali Rai (mediapolis.rai.it) possono scadere e cambiare frequentemente. 
Potresti dover aggiornare il `channels.json` periodicamente.

