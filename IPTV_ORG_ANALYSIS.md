# Analisi Repository iptv-org/iptv - Integrazione AxTV

## 📋 Panoramica

Il repository [iptv-org/iptv](https://github.com/iptv-org/iptv) è una collezione pubblica e open-source di playlist IPTV organizzate per paese. Contiene migliaia di canali streaming gratuiti da tutto il mondo.

## 🏗️ Struttura del Repository

Il repository è organizzato in modo gerarchico:

```
iptv-org/iptv/
├── countries/          # Playlist per paese (ISO 3166-1 alpha-2)
│   ├── it.m3u         # Italia
│   ├── us.m3u         # Stati Uniti
│   ├── fr.m3u         # Francia
│   ├── de.m3u         # Germania
│   └── ...
├── subdivisions/      # Playlist per regioni/stati (opzionale)
│   ├── us-ca.m3u      # California, USA
│   ├── us-ny.m3u      # New York, USA
│   └── ...
└── README.md          # Documentazione con lista completa paesi
```

### Formato File M3U

Ogni file `.m3u` contiene canali nel formato standard M3U:

```
#EXTM3U
#EXTINF:-1 tvg-id="Rai1.it" tvg-name="Rai 1" tvg-logo="https://..." group-title="Entertainment",Rai 1
https://stream-url-here.m3u8
#EXTINF:-1 tvg-id="Rai2.it" tvg-name="Rai 2" tvg-logo="https://..." group-title="Entertainment",Rai 2
https://another-stream-url.m3u8
```

## 🌍 Paesi Disponibili

Il repository contiene playlist per **oltre 100 paesi**. Ecco i principali:

### Europa
- 🇮🇹 **Italia** (`it.m3u`) - ~200+ canali
- 🇫🇷 **Francia** (`fr.m3u`) - ~150+ canali
- 🇩🇪 **Germania** (`de.m3u`) - ~100+ canali
- 🇬🇧 **Regno Unito** (`uk.m3u`) - ~150+ canali
- 🇪🇸 **Spagna** (`es.m3u`) - ~100+ canali
- 🇵🇹 **Portogallo** (`pt.m3u`)
- 🇳🇱 **Paesi Bassi** (`nl.m3u`)
- 🇧🇪 **Belgio** (`be.m3u`)
- 🇨🇭 **Svizzera** (`ch.m3u`)
- 🇦🇹 **Austria** (`at.m3u`)
- 🇵🇱 **Polonia** (`pl.m3u`)
- 🇷🇺 **Russia** (`ru.m3u`)
- 🇬🇷 **Grecia** (`gr.m3u`)
- 🇹🇷 **Turchia** (`tr.m3u`)
- 🇷🇴 **Romania** (`ro.m3u`)
- 🇨🇿 **Repubblica Ceca** (`cz.m3u`)
- 🇭🇺 **Ungheria** (`hu.m3u`)
- 🇸🇪 **Svezia** (`se.m3u`)
- 🇳🇴 **Norvegia** (`no.m3u`)
- 🇩🇰 **Danimarca** (`dk.m3u`)
- 🇫🇮 **Finlandia** (`fi.m3u`)
- 🇮🇪 **Irlanda** (`ie.m3u`)
- 🇮🇸 **Islanda** (`is.m3u`)
- 🇪🇪 **Estonia** (`ee.m3u`)
- 🇱🇻 **Lettonia** (`lv.m3u`)
- 🇱🇹 **Lituania** (`lt.m3u`)
- 🇧🇬 **Bulgaria** (`bg.m3u`)
- 🇭🇷 **Croazia** (`hr.m3u`)
- 🇸🇮 **Slovenia** (`si.m3u`)
- 🇸🇰 **Slovacchia** (`sk.m3u`)
- 🇺🇦 **Ucraina** (`ua.m3u`)
- 🇧🇾 **Bielorussia** (`by.m3u`)
- 🇷🇸 **Serbia** (`rs.m3u`)
- 🇧🇦 **Bosnia** (`ba.m3u`)
- 🇲🇰 **Macedonia** (`mk.m3u`)
- 🇦🇱 **Albania** (`al.m3u`)
- 🇲🇹 **Malta** (`mt.m3u`)
- 🇨🇾 **Cipro** (`cy.m3u`)
- 🇱🇺 **Lussemburgo** (`lu.m3u`)

### Americhe
- 🇺🇸 **Stati Uniti** (`us.m3u`) - ~500+ canali (con subdivisions)
- 🇨🇦 **Canada** (`ca.m3u`) - ~100+ canali
- 🇲🇽 **Messico** (`mx.m3u`)
- 🇧🇷 **Brasile** (`br.m3u`)
- 🇦🇷 **Argentina** (`ar.m3u`)
- 🇨🇱 **Cile** (`cl.m3u`)
- 🇨🇴 **Colombia** (`co.m3u`)
- 🇵🇪 **Perù** (`pe.m3u`)
- 🇻🇪 **Venezuela** (`ve.m3u`)
- 🇪🇨 **Ecuador** (`ec.m3u`)
- 🇺🇾 **Uruguay** (`uy.m3u`)
- 🇵🇾 **Paraguay** (`py.m3u`)
- 🇧🇴 **Bolivia** (`bo.m3u`)
- 🇨🇷 **Costa Rica** (`cr.m3u`)
- 🇵🇦 **Panama** (`pa.m3u`)
- 🇩🇴 **Repubblica Dominicana** (`do.m3u`)
- 🇵🇷 **Porto Rico** (`pr.m3u`)
- 🇯🇲 **Giamaica** (`jm.m3u`)

### Asia
- 🇨🇳 **Cina** (`cn.m3u`)
- 🇯🇵 **Giappone** (`jp.m3u`)
- 🇰🇷 **Corea del Sud** (`kr.m3u`)
- 🇮🇳 **India** (`in.m3u`) - ~200+ canali
- 🇵🇰 **Pakistan** (`pk.m3u`)
- 🇧🇩 **Bangladesh** (`bd.m3u`)
- 🇹🇭 **Thailandia** (`th.m3u`)
- 🇻🇳 **Vietnam** (`vn.m3u`)
- 🇮🇩 **Indonesia** (`id.m3u`)
- 🇲🇾 **Malesia** (`my.m3u`)
- 🇸🇬 **Singapore** (`sg.m3u`)
- 🇵🇭 **Filippine** (`ph.m3u`)
- 🇱🇰 **Sri Lanka** (`lk.m3u`)
- 🇦🇪 **Emirati Arabi** (`ae.m3u`)
- 🇸🇦 **Arabia Saudita** (`sa.m3u`)
- 🇮🇱 **Israele** (`il.m3u`)
- 🇮🇷 **Iran** (`ir.m3u`)
- 🇮🇶 **Iraq** (`iq.m3u`)
- 🇯🇴 **Giordania** (`jo.m3u`)
- 🇱🇧 **Libano** (`lb.m3u`)
- 🇰🇼 **Kuwait** (`kw.m3u`)
- 🇶🇦 **Qatar** (`qa.m3u`)
- 🇧🇭 **Bahrain** (`bh.m3u`)
- 🇴🇲 **Oman** (`om.m3u`)
- 🇾🇪 **Yemen** (`ye.m3u`)
- 🇰🇿 **Kazakistan** (`kz.m3u`)
- 🇺🇿 **Uzbekistan** (`uz.m3u`)
- 🇦🇲 **Armenia** (`am.m3u`)
- 🇬🇪 **Georgia** (`ge.m3u`)
- 🇦🇿 **Azerbaigian** (`az.m3u`)

### Africa
- 🇿🇦 **Sudafrica** (`za.m3u`)
- 🇪🇬 **Egitto** (`eg.m3u`)
- 🇳🇬 **Nigeria** (`ng.m3u`)
- 🇰🇪 **Kenya** (`ke.m3u`)
- 🇬🇭 **Ghana** (`gh.m3u`)
- 🇹🇿 **Tanzania** (`tz.m3u`)
- 🇺🇬 **Uganda** (`ug.m3u`)
- 🇪🇹 **Etiopia** (`et.m3u`)
- 🇲🇦 **Marocco** (`ma.m3u`)
- 🇹🇳 **Tunisia** (`tn.m3u`)
- 🇩🇿 **Algeria** (`dz.m3u`)
- 🇱🇾 **Libia** (`ly.m3u`)
- 🇸🇩 **Sudan** (`sd.m3u`)
- 🇸🇴 **Somalia** (`so.m3u`)
- 🇷🇼 **Ruanda** (`rw.m3u`)
- 🇲🇼 **Malawi** (`mw.m3u`)
- 🇿🇼 **Zimbabwe** (`zw.m3u`)
- 🇦🇴 **Angola** (`ao.m3u`)
- 🇲🇿 **Mozambico** (`mz.m3u`)
- 🇨🇲 **Camerun** (`cm.m3u`)
- 🇨🇮 **Costa d'Avorio** (`ci.m3u`)
- 🇸🇳 **Senegal** (`sn.m3u`)
- 🇧🇫 **Burkina Faso** (`bf.m3u`)
- 🇲🇱 **Mali** (`ml.m3u`)
- 🇳🇪 **Niger** (`ne.m3u`)
- 🇹🇩 **Ciad** (`td.m3u`)
- 🇨🇫 **Repubblica Centrafricana** (`cf.m3u`)
- 🇬🇳 **Guinea** (`gn.m3u`)
- 🇸🇱 **Sierra Leone** (`sl.m3u`)
- 🇱🇷 **Liberia** (`lr.m3u`)
- 🇹🇬 **Togo** (`tg.m3u`)
- 🇧🇯 **Benin** (`bj.m3u`)
- 🇬🇲 **Gambia** (`gm.m3u`)
- 🇬🇼 **Guinea-Bissau** (`gw.m3u`)
- 🇨🇻 **Capo Verde** (`cv.m3u`)
- 🇬🇶 **Guinea Equatoriale** (`gq.m3u`)
- 🇸🇹 **São Tomé e Príncipe** (`st.m3u`)
- 🇩🇯 **Gibuti** (`dj.m3u`)
- 🇪🇷 **Eritrea** (`er.m3u`)
- 🇸🇸 **Sud Sudan** (`ss.m3u`)
- 🇨🇩 **Repubblica Democratica del Congo** (`cd.m3u`)
- 🇨🇬 **Repubblica del Congo** (`cg.m3u`)
- 🇬🇦 **Gabon** (`ga.m3u`)
- 🇬🇶 **Guinea Equatoriale** (`gq.m3u`)
- 🇨🇫 **Repubblica Centrafricana** (`cf.m3u`)
- 🇹🇩 **Ciad** (`td.m3u`)
- 🇳🇪 **Niger** (`ne.m3u`)
- 🇲🇱 **Mali** (`ml.m3u`)
- 🇧🇫 **Burkina Faso** (`bf.m3u`)
- 🇸🇳 **Senegal** (`sn.m3u`)
- 🇨🇮 **Costa d'Avorio** (`ci.m3u`)
- 🇨🇲 **Camerun** (`cm.m3u`)
- 🇲🇿 **Mozambico** (`mz.m3u`)
- 🇦🇴 **Angola** (`ao.m3u`)
- 🇿🇼 **Zimbabwe** (`zw.m3u`)
- 🇲🇼 **Malawi** (`mw.m3u`)
- 🇷🇼 **Ruanda** (`rw.m3u`)
- 🇸🇴 **Somalia** (`so.m3u`)
- 🇸🇩 **Sudan** (`sd.m3u`)
- 🇱🇾 **Libia** (`ly.m3u`)
- 🇩🇿 **Algeria** (`dz.m3u`)
- 🇹🇳 **Tunisia** (`tn.m3u`)
- 🇲🇦 **Marocco** (`ma.m3u`)
- 🇪🇹 **Etiopia** (`et.m3u`)
- 🇺🇬 **Uganda** (`ug.m3u`)
- 🇹🇿 **Tanzania** (`tz.m3u`)
- 🇬🇭 **Ghana** (`gh.m3u`)
- 🇰🇪 **Kenya** (`ke.m3u`)
- 🇳🇬 **Nigeria** (`ng.m3u`)
- 🇪🇬 **Egitto** (`eg.m3u`)
- 🇿🇦 **Sudafrica** (`za.m3u`)

### Oceania
- 🇦🇺 **Australia** (`au.m3u`)
- 🇳🇿 **Nuova Zelanda** (`nz.m3u`)
- 🇫🇯 **Fiji** (`fj.m3u`)
- 🇵🇬 **Papua Nuova Guinea** (`pg.m3u`)
- 🇳🇨 **Nuova Caledonia** (`nc.m3u`)
- 🇵🇫 **Polinesia Francese** (`pf.m3u`)
- 🇬🇺 **Guam** (`gu.m3u`)
- 🇵🇼 **Palau** (`pw.m3u`)
- 🇫🇲 **Micronesia** (`fm.m3u`)
- 🇲🇭 **Isole Marshall** (`mh.m3u`)
- 🇳🇷 **Nauru** (`nr.m3u`)
- 🇰🇮 **Kiribati** (`ki.m3u`)
- 🇹🇻 **Tuvalu** (`tv.m3u`)
- 🇼🇸 **Samoa** (`ws.m3u`)
- 🇹🇴 **Tonga** (`to.m3u`)
- 🇻🇺 **Vanuatu** (`vu.m3u`)
- 🇸🇧 **Isole Salomone** (`sb.m3u`)
- 🇳🇺 **Niue** (`nu.m3u`)
- 🇨🇰 **Isole Cook** (`ck.m3u`)
- 🇵🇳 **Pitcairn** (`pn.m3u`)

**Nota**: Il numero esatto di canali varia nel tempo. Per la lista completa e aggiornata, consulta il [README del repository](https://github.com/iptv-org/iptv#readme).

## 🔧 Cosa Possiamo Integrare

### 1. **Sistema di Selezione Paese**
   - Estendere `RegionSelectionPage` per mostrare tutti i paesi disponibili
   - Aggiungere ricerca e filtri per continente
   - Salvare la selezione in SharedPreferences

### 2. **Caricamento Dinamico Playlist**
   - Modificare `ChannelsRepository` per supportare URL M3U
   - Aggiungere parser M3U → JSON (già presente `m3u_to_channels.py`)
   - Caricare playlist dal repository GitHub RAW URL

### 3. **Gestione Multi-Paese**
   - Permettere selezione multipla di paesi
   - Unire canali da più paesi
   - Filtrare per paese nella lista canali

### 4. **Cache e Aggiornamenti**
   - Cache locale delle playlist scaricate
   - Sistema di aggiornamento automatico
   - Gestione versionamento playlist

### 5. **Subdivisions (Regioni/Stati)**
   - Supporto per subdivisions (es. stati USA, regioni Italia)
   - UI per navigare subdivisions
   - Caricamento gerarchico: Paese → Regione → Canali

## 📦 Integrazione Tecnica

### URL Pattern Repository

I file M3U sono accessibili tramite GitHub RAW:

```
https://raw.githubusercontent.com/iptv-org/iptv/master/countries/{country_code}.m3u
https://raw.githubusercontent.com/iptv-org/iptv/master/subdivisions/{country_code}-{subdivision_code}.m3u
```

**Esempi**:
- Italia: `https://raw.githubusercontent.com/iptv-org/iptv/master/countries/it.m3u`
- USA California: `https://raw.githubusercontent.com/iptv-org/iptv/master/subdivisions/us-ca.m3u`

### Modifiche Necessarie

1. **Modello Channel** - Aggiungere campo `country` (opzionale)
2. **ChannelsRepository** - Supportare parsing M3U da URL
3. **RegionSelectionPage** - Lista completa paesi con ricerca
4. **State Management** - Aggiungere provider per paese selezionato
5. **M3U Parser** - Migliorare `m3u_to_channels.py` o creare versione Dart

### Struttura Dati Proposta

```dart
class Channel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;
  final String? license;
  final String? country;        // NEW: Codice paese ISO (es. "it", "us")
  final String? countryName;     // NEW: Nome paese (es. "Italia", "United States")
  final String? groupTitle;      // NEW: Categoria canale (da M3U)
  final String? tvgId;           // NEW: ID EPG (da M3U)
}
```

## 🚀 Piano di Implementazione

### Fase 1: Setup Base
- [ ] Aggiungere lista completa paesi con codici ISO
- [ ] Creare modello dati per paese
- [ ] Estendere `Channel` con campi paese

### Fase 2: Parser M3U
- [ ] Creare parser M3U in Dart (o migliorare script Python)
- [ ] Supportare parsing da URL remoto
- [ ] Gestire metadati M3U (tvg-id, tvg-logo, group-title)

### Fase 3: Repository Enhancement
- [ ] Modificare `ChannelsRepository` per supportare M3U
- [ ] Aggiungere metodo `fetchChannelsByCountry(String countryCode)`
- [ ] Implementare cache locale

### Fase 4: UI Enhancement
- [ ] Aggiornare `RegionSelectionPage` con lista completa
- [ ] Aggiungere ricerca e filtri
- [ ] Mostrare numero canali per paese
- [ ] Aggiungere indicatori di caricamento

### Fase 5: State Management
- [ ] Creare provider per paese selezionato
- [ ] Implementare persistenza selezione
- [ ] Aggiungere supporto multi-paese

### Fase 6: Subdivisions
- [ ] Rilevare subdivisions disponibili
- [ ] UI per navigare subdivisions
- [ ] Caricamento gerarchico

## ⚠️ Considerazioni

### Sicurezza
- ✅ Validazione URL già presente in `ContentValidator`
- ✅ Filtraggio canali non validi già implementato
- ⚠️ Verificare che tutti gli URL da iptv-org siano sicuri

### Performance
- ⚠️ Alcune playlist possono contenere 500+ canali
- 💡 Implementare lazy loading
- 💡 Cache locale per ridurre richieste

### Legalità
- ⚠️ Verificare licenza repository iptv-org
- ⚠️ Assicurarsi che l'uso sia conforme alle leggi locali
- ⚠️ Alcuni canali potrebbero avere restrizioni geografiche

### Manutenzione
- ⚠️ Repository iptv-org viene aggiornato frequentemente
- 💡 Implementare sistema di notifica aggiornamenti
- 💡 Versionamento playlist per gestire breaking changes

## 📊 Statistiche Stimate

- **Paesi totali**: ~150+
- **Canali totali**: ~10,000+
- **Subdivisions**: ~50+ (principalmente USA, Canada, Australia)
- **Aggiornamenti**: Quotidiani/Settimanali

## 🔗 Link Utili

- Repository: https://github.com/iptv-org/iptv
- README: https://github.com/iptv-org/iptv#readme
- Countries Directory: https://github.com/iptv-org/iptv/tree/master/countries
- Subdivisions Directory: https://github.com/iptv-org/iptv/tree/master/subdivisions

## ✅ Prossimi Passi

1. **Decidere approccio**: 
   - Opzione A: Parser M3U lato client (Dart)
   - Opzione B: Script Python lato server (converti M3U → JSON, poi carica JSON)

2. **Priorità paesi**: 
   - Quali paesi integrare per primi?
   - Italia già presente, aggiungere altri paesi europei?

3. **UI/UX**:
   - Come mostrare la selezione paese?
   - Supporto multi-paese o selezione singola?

4. **Testing**:
   - Testare con alcuni paesi prima del rollout completo
   - Verificare qualità e disponibilità stream
