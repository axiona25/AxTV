# Analisi API StreamingCommunity - Integrazione AxTV

## 📋 Panoramica

**StreamingCommunity** (https://streamingcommunityz.army/) è una piattaforma di streaming per film e serie TV che utilizza Laravel con Inertia.js. Il sito è protetto da Cloudflare e utilizza sessioni per l'autenticazione.

## 🔍 Struttura del Sito

- **Framework**: Laravel (PHP)
- **Frontend**: Inertia.js (React/Vue)
- **Protection**: Cloudflare
- **Authentication**: Session-based (cookie `streamingcommunity_session`)
- **CSRF Protection**: Laravel Sanctum (`XSRF-TOKEN`)

## ✅ API Pubbliche Disponibili

### 1. **GET /api/search**
Ricerca pubblica di film e serie TV.

**Endpoint**: `https://streamingcommunityz.army/api/search`

**Query Parameters**:
- `q` (string): Query di ricerca

**Esempio**:
```bash
curl -X GET "https://streamingcommunityz.army/api/search?q=test" \
  -H "Accept: application/json"
```

**Risposta**:
```json
{
  "current_page": 1,
  "data": [
    {
      "id": 14268,
      "slug": "test",
      "name": "Test",
      "type": "movie",
      "score": "5.4",
      "sub_ita": 0,
      "last_air_date": "2025-04-04",
      "age": 12,
      "seasons_count": 0,
      "images": [
        {
          "imageable_id": 14268,
          "imageable_type": "title",
          "filename": "b2a6c26b-c830-4bb2-8c69-096f29a53764.webp",
          "type": "poster",
          "lang": "en",
          "original_url_field": null
        }
      ],
      "translations": []
    }
  ]
}
```

**Campi Principali**:
- `id`: ID univoco del titolo
- `slug`: Slug URL-friendly
- `name`: Nome del titolo
- `type`: Tipo (`"movie"` o `"tv"`)
- `score`: Punteggio (0-10)
- `sub_ita`: Sottotitoli italiani (0 o 1)
- `last_air_date`: Data ultima trasmissione
- `age`: Età minima consigliata
- `seasons_count`: Numero di stagioni (solo per serie TV)
- `images`: Array di immagini (poster, cover, background, logo, cover_mobile)

### 2. **GET /api/archive**
Archivio pubblico di contenuti aggiunti di recente.

**Endpoint**: `https://streamingcommunityz.army/api/archive`

**Esempio**:
```bash
curl -X GET "https://streamingcommunityz.army/api/archive" \
  -H "Accept: application/json"
```

**Risposta**:
```json
{
  "titles": [
    {
      "id": 50246,
      "slug": "gomorrah-the-origins",
      "name": "Gomorrah: The Origins",
      "type": "tv",
      "score": "6.5",
      "sub_ita": 0,
      "last_air_date": "2026-01-09",
      "age": 12,
      "seasons_count": 1,
      "images": [...],
      "translations": []
    }
  ]
}
```

### 3. **GET /api/browse/{slider_name}**
Sfoglia contenuti per categoria (es. trending, nuovi arrivi).

**Endpoint**: `https://streamingcommunityz.army/api/browse/{slider_name}`

**Note**: 
- ⚠️ Restituisce errore "Server Error" in alcuni casi
- Potrebbe richiedere parametri aggiuntivi o autenticazione per alcune categorie

**Esempi di slider_name**:
- `in-trending`
- `latest-movies`
- `latest-tv-shows`
- `top-rated`

### 4. **POST /api/sliders/fetch**
Ottiene gli slider disponibili per la homepage.

**Endpoint**: `https://streamingcommunityz.army/api/sliders/fetch`

**Note**: 
- ⚠️ Attualmente restituisce "Server Error"
- Potrebbe richiedere parametri nel body o autenticazione

## 🔒 API che Richiedono Autenticazione

### 1. **GET /api/video/{video_id}**
Informazioni dettagliate su un video specifico.

**Endpoint**: `https://streamingcommunityz.army/api/video/{video_id}`

**Note**: 
- Richiede autenticazione (cookie di sessione)
- Restituisce informazioni sul video incluso URL di streaming

### 2. **GET /api/title-requests/search/{type}**
Cerca richieste di titoli (solo per utenti autenticati).

**Endpoint**: `https://streamingcommunityz.army/api/title-requests/search/{type}`

**Parametri**:
- `type`: `"movie"` o `"tv"`

**Risposta senza autenticazione**: `{"message":"Unauthenticated."}`

### 3. **GET /api/mylist**
Lista dei contenuti salvati dall'utente.

**Endpoint**: `https://streamingcommunityz.army/api/mylist`

**Note**: Richiede autenticazione

### 4. **POST /api/favourites/toggle/{title_id}**
Aggiunge/rimuove un titolo dai preferiti.

**Endpoint**: `https://streamingcommunityz.army/api/favourites/toggle/{title_id}`

**Note**: Richiede autenticazione

### 5. **POST /api/ratings/rate/{title_id}**
Valuta un titolo.

**Endpoint**: `https://streamingcommunityz.army/api/ratings/rate/{title_id}`

**Note**: Richiede autenticazione

### 6. **GET /api/titles/preview/{id}**
Anteprima di un titolo (potrebbe includere video trailer).

**Endpoint**: `https://streamingcommunityz.army/api/titles/preview/{id}`

**Note**: Richiede POST method

## 🔗 Altre Route Identificate

Dal file Ziggy routes, ho identificato queste route aggiuntive (non tutte testate):

### Pagine Web (non API):
- `/{locale}/tv-shows` - Lista serie TV
- `/{locale}/movies` - Lista film
- `/{locale}/titles/{id}-{slug}` - Dettagli titolo
- `/{locale}/watch/{title_id}` - Pagina di riproduzione
- `/{locale}/iframe/{title_id}` - Iframe per riproduzione

**Parametri**:
- `locale`: Codice lingua (es. `it`, `en`)

## 📊 Formato Dati

### Struttura Titolo (Movie/TV Show)

```typescript
interface Title {
  id: number;
  slug: string;
  name: string;
  type: "movie" | "tv";
  score: string; // 0-10
  sub_ita: 0 | 1; // Sottotitoli italiani
  last_air_date: string; // YYYY-MM-DD
  age: number | null; // Età minima consigliata
  seasons_count: number; // Solo per serie TV
  images: Image[];
  translations: Translation[];
}

interface Image {
  imageable_id: number;
  imageable_type: string;
  filename: string;
  type: "poster" | "cover" | "background" | "logo" | "cover_mobile";
  lang: string | null;
  original_url_field: string | null;
}
```

### URL Immagini

Le immagini sono accessibili tramite:
```
https://streamingcommunityz.army/storage/{filename}
```

Esempio:
```
https://streamingcommunityz.army/storage/b2a6c26b-c830-4bb2-8c69-096f29a53764.webp
```

## 🚀 Possibilità di Integrazione con AxTV

### ✅ Cosa Possiamo Fare (API Pubbliche)

1. **Ricerca Contenuti**
   - Implementare ricerca in tempo reale
   - Utilizzare `/api/search` per cercare film e serie

2. **Catalogo Contenuti**
   - Utilizzare `/api/archive` per ottenere contenuti recenti
   - Implementare browsing per categoria (se `/api/browse` funziona)

3. **Metadati e Immagini**
   - Ottenere informazioni complete sui titoli
   - Caricare poster, cover e immagini di background
   - Mostrare score, data uscita, sottotitoli italiani

### ❌ Limitazioni

1. **URL Video**
   - Gli URL di streaming non sono disponibili tramite API pubbliche
   - L'endpoint `/api/video/{video_id}` richiede autenticazione
   - Non possiamo riprodurre i video direttamente

2. **Autenticazione**
   - Le API pubbliche sono limitate
   - Per ottenere URL video, serve autenticazione con sessione Laravel
   - Autenticazione basata su cookie di sessione (non semplice da implementare)

3. **Rate Limiting**
   - Non testato, ma probabile presenza di rate limiting (Cloudflare)
   - Potrebbe essere necessario gestire limiti di richieste

4. **Legalità**
   - ⚠️ StreamingCommunity è un sito di streaming che potrebbe contenere contenuti protetti da copyright
   - L'uso delle API potrebbe violare i termini di servizio
   - Verificare la legalità prima dell'integrazione

## 🔧 Esempio di Implementazione

### Dart/Flutter - Ricerca Contenuti

```dart
import 'package:dio/dio.dart';

class StreamingCommunityRepository {
  final Dio dio;
  static const baseUrl = 'https://streamingcommunityz.army';
  
  StreamingCommunityRepository(this.dio);
  
  /// Cerca contenuti
  Future<List<Title>> search(String query) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/search',
        queryParameters: {'q': query},
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );
      
      final data = response.data['data'] as List;
      return data.map((json) => Title.fromJson(json)).toList();
    } catch (e) {
      print('Errore ricerca: $e');
      return [];
    }
  }
  
  /// Ottiene contenuti archivio
  Future<List<Title>> getArchive() async {
    try {
      final response = await dio.get(
        '$baseUrl/api/archive',
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );
      
      final data = response.data['titles'] as List;
      return data.map((json) => Title.fromJson(json)).toList();
    } catch (e) {
      print('Errore archivio: $e');
      return [];
    }
  }
  
  /// Costruisce URL immagine
  String getImageUrl(String filename) {
    return '$baseUrl/storage/$filename';
  }
}
```

## ⚠️ Considerazioni Importanti

### Sicurezza
- ⚠️ **Non validare URL di StreamingCommunity** - Potrebbe contenere contenuti illegali
- ⚠️ **Non permettere riproduzione diretta** - Gli URL video non sono pubblicamente accessibili
- ⚠️ **Rate limiting** - Implementare throttling per evitare blocchi

### Legalità
- ⚠️ Verificare che l'uso delle API sia conforme ai termini di servizio
- ⚠️ StreamingCommunity potrebbe essere un sito di streaming non autorizzato
- ⚠️ L'integrazione potrebbe avere implicazioni legali

### Performance
- Le API sono protette da Cloudflare (potenziale latenza)
- Implementare cache locale per ridurre richieste
- Gestire timeout e errori di rete

### Manutenzione
- Le API potrebbero cambiare senza preavviso
- Nessuna documentazione ufficiale disponibile
- Possibile chiusura del sito

## 📝 Conclusioni

### ✅ Cosa Funziona
- **Ricerca pubblica**: `/api/search` funziona senza autenticazione
- **Archivio**: `/api/archive` funziona senza autenticazione
- **Metadati**: Ottimo formato dati con immagini e informazioni complete

### ❌ Cosa Non Funziona
- **URL Video**: Non accessibili pubblicamente
- **Riproduzione**: Richiede autenticazione
- **Alcuni endpoint**: `/api/browse` e `/api/sliders/fetch` restituiscono errori

### 🎯 Raccomandazioni

1. **Utilizzo Limitato**: 
   - Usare solo per metadati (ricerca, immagini, informazioni)
   - NON integrare per riproduzione diretta di video

2. **Alternative**:
   - Considerare API legali come TMDB per metadati
   - Utilizzare solo fonti di streaming legali e autorizzate

3. **Se si vuole procedere**:
   - Implementare solo ricerca e catalogazione
   - NON esporre URL di StreamingCommunity nella UI
   - Implementare sistema di autenticazione solo se strettamente necessario

## 🔗 Riferimenti

- **Sito Web**: https://streamingcommunityz.army/
- **Framework**: Laravel + Inertia.js
- **Protection**: Cloudflare

## 📅 Data Analisi

Analisi effettuata il: 09 Gennaio 2026
