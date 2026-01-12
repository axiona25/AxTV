# Integrazione TMDB-To-VOD-Playlist

## ✅ Implementazione Completata

L'integrazione di TMDB-To-VOD-Playlist è stata completata! Ora l'app può utilizzare l'API TMDB per cercare film con metadati completi (poster, descrizioni, generi, cast, etc.).

## 📋 Funzionalità Implementate

1. **Servizio TMDB** (`lib/features/ondemand/data/tmdb_service.dart`)
   - Ricerca film tramite API TMDB Discover
   - Filtri per lingua, genere, anno, etc.
   - Metadati completi: poster, descrizioni, cast, generi, trailer
   - Supporto multi-lingua (italiano incluso)

2. **Servizio Stream Resolver** (`lib/features/ondemand/data/tmdb_stream_resolver.dart`)
   - Genera URL placeholder per i film TMDB
   - Può essere esteso per cercare link da fonti pubbliche

3. **Repository TMDB Configurati** (`lib/features/ondemand/data/repositories_config.dart`)
   - Film Italiani (`tmdb-italian-movies`)
   - Film Popolari (`tmdb-popular-movies`)
   - Top Rated (`tmdb-top-rated-movies`)
   - Ultime Uscite (`tmdb-latest-movies`)
   - Per genere (Action, Comedy, Drama, Horror, Sci-Fi, Thriller, Animation)

4. **Integrazione in MoviesRepository**
   - Riconosce repository TMDB (schema `tmdb://`)
   - Carica film da TMDB API
   - Converte i film TMDB nel formato Movie usato dall'app

## 🔧 Configurazione Necessaria

### 1. Ottieni una TMDB API Key (GRATUITA)

1. Vai su https://www.themoviedb.org/
2. Crea un account (se non ce l'hai)
3. Vai in **Settings** > **API** > **Request API Key**
4. Scegli "Developer" e compila il form
5. Copia la tua API key

### 2. Configura la API Key nell'App

Apri `lib/config/env.dart` e sostituisci:

```dart
static const tmdbApiKey = 'YOUR_TMDB_API_KEY'; // Sostituisci con la tua API key
```

Con:

```dart
static const tmdbApiKey = 'la_tua_api_key_qui'; // La tua API key TMDB
```

### 3. Attiva i Repository TMDB

1. Apri l'app
2. Vai in **Impostazioni** > **Repository On-Demand**
3. Trova i repository TMDB (iniziano con "TMDB")
4. Attiva i repository che vuoi usare

**Repository Consigliati per iniziare:**
- ✅ TMDB 🇮🇹 Film Italiani (film italiani originali)
- ✅ TMDB 🎬 Film Popolari (film più popolari, tutte le lingue)

## 📖 Come Funziona

### Flusso di Caricamento

1. L'app rileva i repository TMDB (quelli con `baseUrl` che inizia con `tmdb://`)
2. Parse i parametri dal `jsonPath` (es: `language=it-IT&original_language=it`)
3. Chiama l'API TMDB Discover con i parametri specificati
4. Carica più pagine di risultati (fino a 5 pagine = ~100 film)
5. Converte i film TMDB nel formato `Movie` usato dall'app
6. Genera URL placeholder (`tmdb://movie/{id}`) per ogni film

### URL Placeholder

I film TMDB usano URL placeholder (`tmdb://movie/{id}`) perché:
- TMDB non fornisce direttamente link di streaming
- TMDB-To-VOD-Playlist cerca i link da varie fonti al momento della riproduzione
- Per ora, l'app usa placeholder che possono essere risolti in futuro

**Nota:** Attualmente, gli URL placeholder non sono riproducibili direttamente. Per renderli riproducibili, dovresti:

1. Implementare la ricerca di link da fonti pubbliche (come fa TMDB-To-VOD-Playlist)
2. O integrare con un servizio che fornisce link di streaming (es: Real-Debrid, Premiumize)

## 🎯 Repository TMDB Disponibili

| ID | Nome | Descrizione | Parametri |
|----|------|-------------|-----------|
| `tmdb-italian-movies` | TMDB 🇮🇹 Film Italiani | Film italiani originali | `language=it-IT&original_language=it` |
| `tmdb-popular-movies` | TMDB 🎬 Film Popolari | Film più popolari | `language=it-IT&sort_by=popularity.desc` |
| `tmdb-top-rated-movies` | TMDB ⭐ Top Rated | Film meglio votati | `language=it-IT&sort_by=vote_average.desc` |
| `tmdb-latest-movies` | TMDB 🆕 Ultime Uscite | Film più recenti | `language=it-IT&sort_by=release_date.desc` |
| `tmdb-action-movies` | TMDB 🎬 Action Movies | Film d'azione | `language=it-IT&with_genres=28` |
| `tmdb-comedy-movies` | TMDB 😄 Comedy Movies | Film comici | `language=it-IT&with_genres=35` |
| `tmdb-drama-movies` | TMDB 🎭 Drama Movies | Film drammatici | `language=it-IT&with_genres=18` |
| `tmdb-horror-movies` | TMDB 👻 Horror Movies | Film horror | `language=it-IT&with_genres=27` |
| `tmdb-scifi-movies` | TMDB 🚀 Sci-Fi Movies | Film di fantascienza | `language=it-IT&with_genres=878` |
| `tmdb-thriller-movies` | TMDB 🔪 Thriller Movies | Film thriller | `language=it-IT&with_genres=53` |
| `tmdb-animation-movies` | TMDB 🎨 Animation Movies | Film d'animazione | `language=it-IT&with_genres=16` |

## 🔮 Prossimi Passi (Opzionali)

### 1. Implementare Ricerca Link Streaming

Attualmente, i film TMDB usano URL placeholder. Per renderli riproducibili, puoi:

- Implementare la ricerca da fonti pubbliche (come fa TMDB-To-VOD-Playlist)
- Integrare con Real-Debrid o Premiumize (richiedono account a pagamento)
- Usare API proxy pubbliche che risolvono link di streaming

### 2. Aggiungere Dettagli Film

Per ottenere informazioni complete (cast, regista, runtime, trailer), chiama `getMovieDetails()` per ogni film. Questo richiede una chiamata API aggiuntiva per film.

### 3. Cercare Film per Query

Il servizio TMDB supporta anche la ricerca testuale (`searchMovies()`). Puoi aggiungere una funzione di ricerca nell'app.

## 📚 Risorse

- **TMDB API Documentation**: https://developers.themoviedb.org/3
- **TMDB-To-VOD-Playlist GitHub**: https://github.com/gogetta69/TMDB-To-VOD-Playlist
- **Ottieni API Key**: https://www.themoviedb.org/settings/api

## ⚠️ Note Importanti

1. **API Key Necessaria**: L'integrazione TMDB richiede una API key gratuita. Senza di essa, i repository TMDB non funzioneranno.

2. **Limiti API TMDB**: 
   - API gratuita: 40 richieste ogni 10 secondi
   - L'app carica fino a 5 pagine (~100 film) per repository
   - Questo è generalmente sufficiente per l'uso normale

3. **URL Placeholder**: I film TMDB attualmente usano URL placeholder (`tmdb://`). Questi non sono riproducibili direttamente finché non implementi la risoluzione dei link di streaming.

4. **Link Streaming**: TMDB non fornisce link di streaming. Devi implementare tu stesso la ricerca da fonti pubbliche o usare servizi come Real-Debrid.

## ✅ Verifica

Per verificare che tutto funzioni:

1. ✅ Configura la TMDB API key in `lib/config/env.dart`
2. ✅ Attiva almeno un repository TMDB nelle impostazioni
3. ✅ Vai nella pagina On-Demand
4. ✅ Dovresti vedere i film caricati da TMDB con poster e metadati

Se vedi un messaggio di errore relativo all'API key, verifica che sia configurata correttamente.
