# 🇮🇹 Repository Italiani da Attivare

Guida per attivare i repository italiani dalle impostazioni dell'app.

---

## 📱 Come Accedere alle Impostazioni

1. **Apri l'app Flutter**
2. **Vai in Impostazioni** (icona ⚙️ o menu)
3. **Clicca su "Repository On-Demand"** (o "Repository")
4. **Seleziona tab "On-Demand"** (non "Live")

---

## ✅ Repository da Attivare per Contenuti Italiani

### 1. IPTV-org 🇮🇹 Italian Channels ⭐ **CONSIGLIATO**

**ID Repository**: `iptv-org-italian`

**Cosa contiene**:
- ✅ **Canali italiani** (Live TV)
- ✅ **Contenuti italiani** verificati
- ✅ **Server funzionanti** (30a-tv.com, xdevel.com, ecc.)

**Come riconoscerlo**:
- Nome: **"IPTV-org 🇮🇹 Italian Channels"**
- Descrizione: "Canali italiani da iptv-org/iptv (Live TV)"
- Gruppo: **"IPTV-org"**

**✅ Attiva questo per vedere solo contenuti italiani!**

---

### 2. IPTV-org 🎬 Movies

**ID Repository**: `iptv-org-movies`

**Cosa contiene**:
- ✅ **Film** da vari server
- ⚠️ **Alcuni italiani**, ma principalmente internazionali
- ✅ **Server funzionanti** verificati

**Come riconoscerlo**:
- Nome: **"IPTV-org 🎬 Movies"**
- Descrizione: "Canali film da iptv-org/iptv (principalmente Live TV, meno on-demand)"
- Gruppo: **"IPTV-org"**

**⚠️ Attiva questo se vuoi anche film internazionali (non solo italiani)**

---

## 🔧 Istruzioni Passo-Passo

### Passo 1: Apri Impostazioni Repository

1. Apri l'app
2. Vai in **Impostazioni** (menu laterale o icona ⚙️)
3. Clicca su **"Repository On-Demand"**

### Passo 2: Trova Gruppo "IPTV-org"

1. Nella lista, cerca il gruppo **"IPTV-org"**
2. Espandi il gruppo cliccando sulla freccia

### Passo 3: Attiva Repository Italiani

1. **Cerca**: "IPTV-org 🇮🇹 Italian Channels"
2. **Attiva** lo switch a destra (deve diventare blu)
3. **(Opzionale)**: Attiva anche "IPTV-org 🎬 Movies" se vuoi più contenuti

### Passo 4: Verifica Attivazione

1. Controlla che lo switch sia **attivo** (blu)
2. Il repository dovrebbe avere un **bordo blu** e **glow**
3. Vedrai: **"1 / 2 attivi"** o **"2 / 2 attivi"** nel gruppo

### Passo 5: Torna alla Pagina Film

1. Esci dalle impostazioni
2. Vai alla pagina **"On-Demand"** (Film)
3. I contenuti italiani si caricheranno automaticamente

---

## 📊 Risultato Atteso

### Prima (Nessun Repository Attivo):
- ⚠️ **0 film** o solo film da altri repository
- ❌ Nessun contenuto italiano

### Dopo (Repository Italiani Attivi):
- ✅ **~336 contenuti italiani** (da IPTV-org Italian Channels)
- ✅ **~398 film** (da IPTV-org Movies, se attivato)
- ✅ **Solo server funzionanti** (30a-tv.com, xdevel.com, ecc.)

---

## 🎬 Contenuti che Vedrai

### Da IPTV-org 🇮🇹 Italian Channels:
- "7 RadioVisione" (da xdevel.com) ✅
- "7 STORIA" (da xdevel.com) ✅
- "7 YOU & ME" (da xdevel.com) ✅
- Altri canali italiani funzionanti ✅

### Da IPTV-org 🎬 Movies:
- "30A TV Classic Movies" (da 30a-tv.com) ✅
- "70s Cinema" (da pluto.tv) ✅
- "80s Rewind" (da pluto.tv) ✅
- Altri film da server funzionanti ✅

---

## 🔍 Come Verificare

### Verifica nei Log:
Quando ricarichi la pagina Film, vedrai nei log:
```
MoviesRepository: ✅ Caricati 336/336 film validi da IPTV-org 🇮🇹 Italian Channels
MoviesRepository: ✅ Caricati 398/398 film validi da IPTV-org 🎬 Movies
```

### Verifica nella Griglia:
Nella pagina Film, dovresti vedere:
- Film italiani (con bandiera 🇮🇹 nel nome)
- Film da server verificati (30a-tv.com, xdevel.com)

---

## 💡 Suggerimenti

### Solo Contenuti Italiani:
- ✅ Attiva solo **"IPTV-org 🇮🇹 Italian Channels"**
- ❌ Disattiva "IPTV-org 🎬 Movies" (contiene anche internazionali)

### Più Contenuti:
- ✅ Attiva entrambi i repository
- 🇮🇹 Vedrai contenuti italiani + internazionali

### Massima Qualità:
- ✅ Usa il **proxy server Docker** (già configurato)
- ✅ Attiva solo repository verificati (già filtrati)

---

## 🆘 Troubleshooting

### Repository non visibile:
1. ✅ Verifica di essere nella tab **"On-Demand"** (non "Live")
2. ✅ Controlla che il gruppo "IPTV-org" sia espanso
3. ✅ Scrolla la lista per trovare il repository

### Switch non si attiva:
1. ✅ Riavvia l'app
2. ✅ Verifica connessione internet
3. ✅ Controlla log per errori

### Film non appaiono:
1. ✅ Verifica che repository sia attivo (switch blu)
2. ✅ Controlla log: `MoviesRepository: ✅ Caricati ...`
3. ✅ Aspetta alcuni secondi (caricamento in background)
4. ✅ Ricarica pagina Film (pull-to-refresh)

---

## ✅ Checklist

- [ ] Aperto Impostazioni → Repository On-Demand
- [ ] Trovato gruppo "IPTV-org"
- [ ] Attivato "IPTV-org 🇮🇹 Italian Channels" ⭐
- [ ] (Opzionale) Attivato "IPTV-org 🎬 Movies"
- [ ] Verificato switch attivi (blu)
- [ ] Tornato alla pagina Film
- [ ] Contenuti italiani visibili

---

## 📝 Note

- ✅ I repository sono già configurati con **solo server funzionanti**
- ✅ I contenuti da `zplaypro.lat` sono **automaticamente filtrati** (server offline)
- ✅ Il **proxy server Docker** è già attivo e bypassa geoblock
- ✅ Contenuti italiani usano automaticamente il proxy

---

**🎬 Dopo l'attivazione, vedrai solo contenuti italiani funzionanti!**
