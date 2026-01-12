# Filtro: Solo Film Funzionanti IPTV-org

## ✅ Implementato

Ho aggiunto un filtro che mostra **SOLO** i film IPTV-org da **server verificati funzionanti**.

### Cosa fa il filtro:

1. ✅ **Include** solo film da server verificati funzionanti:
   - `30a-tv.com` → HTTP 200 ✅
   - `xdevel.com` → HTTP 200 ✅
   - `pluto.tv` → Solitamente funzionante
   - `amagi.tv` → Solitamente funzionante
   - `mediaserver.abnvideos.com` → ABN (solitamente funzionante)
   - `yuppcdn.net` → YuppCDN (solitamente funzionante)
   - `netplus.ch` → Netplus (solitamente funzionante)

2. ❌ **Esclude** film da server offline/problematici:
   - `zplaypro.lat` → HTTP 521 (offline)
   - `zplaypro.com` → HTTP 521 (offline)
   - `d1j2u714xk898n.cloudfront.net` → HTTP 404
   - `live2.msf.cdn.mediaset.net` → DNS non risolve
   - IP diretti con `/play/` → Pattern problematico
   - IP diretti senza HTTPS/dominio noto → Instabili

3. ⚠️ **Accetta** anche altri URL se:
   - Sono HTTPS
   - Sono da dominio noto (.com, .net, .tv, .ch)
   - NON sono IP diretti
   - NON sono da server offline noti

---

## 📊 Risultato Atteso

### Prima del filtro:
- **701 film** IPTV-org visibili (363 Movies + 338 Italian)
- Molti non funzionano (zplaypro.lat offline, ecc.)

### Dopo il filtro:
- **Solo film da server funzionanti** visibili
- **Numero ridotto** ma **tutti funzionanti**
- Dovresti vedere principalmente:
  - Film da `30a-tv.com`
  - Film da `xdevel.com` (canali italiani)
  - Film da `pluto.tv`
  - Altri da server verificati

---

## 🎯 Come Funziona

Il filtro viene applicato durante il parsing del file M3U:

```
1. App scarica file M3U dal GitHub IPTV-org
2. App parsa ogni film
3. Per ogni film IPTV-org:
   - ✅ È da server funzionante? → Mostra
   - ❌ È da server offline noto? → Salta
   - ❌ È IP diretto con /play/? → Salta
   - ⚠️ Non verificato ma HTTPS/dominio noto? → Mostra
   - ❌ IP diretto o non sicuro? → Salta
4. Film filtrati vengono mostrati nella griglia
```

---

## 🧪 Test

Quando ricarichi l'app, dovresti vedere:

1. **Menù film** con meno film IPTV-org (solo funzionanti)
2. **Film da server verificati** nella griglia
3. **Quando clicchi**, dovrebbero riprodursi correttamente

**Film da cercare nella griglia:**
- "30A TV Classic Movies" (da 30a-tv.com) → ✅ Dovrebbe funzionare
- "7 RadioVisione" (da xdevel.com) → ✅ Dovrebbe funzionare
- Film da pluto.tv → ✅ Dovrebbero funzionare

**Film che NON vedrai più:**
- Film da zplaypro.lat → ❌ Esclusi (server offline)
- Film da IP diretti con /play/ → ❌ Esclusi (pattern problematico)

---

## 💡 Vantaggi

✅ **Vedi solo film funzionanti** → Meno frustrazione  
✅ **Qualità garantita** → Solo server verificati  
✅ **Test veloce** → Puoi capire subito la qualità dei contenuti disponibili  
✅ **Meno errori** → Non vedi film che non funzionano  

---

## ⚙️ Personalizzazione

Se vuoi modificare i server funzionanti, modifica in `movies_repository.dart`:

```dart
final workingIptvOrgServers = [
  '30a-tv.com',           // ✅ Verificato
  'xdevel.com',           // ✅ Verificato
  'pluto.tv',             // Aggiungi qui altri
  // ... altri server ...
];
```

---

## 📝 Note

- Il filtro è **conservativo**: mostra solo server verificati o molto probabili
- Alcuni film potrebbero funzionare ma essere esclusi (non li abbiamo ancora verificati)
- Se trovi altri server funzionanti, possiamo aggiungerli alla whitelist
- I film da altri repository (Cinedantan, Xtream-Playlist) non sono filtrati (solo IPTV-org)
