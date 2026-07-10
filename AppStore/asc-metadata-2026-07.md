# Lajme 1.1.8 — ASC-metadata (klistra in i App Store Connect)

Upprättad 2026-07-10 efter ASO-audit. Live-listningen hade: 0 screenshots (enligt iTunes API),
subtitel "News Aggregator App", 17+ åldersgräns, samt löften om push-notiser och bokmärken
som appen inte har. Allt nedan fixar det.

> Screenshots, beskrivning, subtitel och keywords kan bara ändras med en NY VERSION.
> Skapa version **1.1.8** i ASC, klistra in nedan, ladda upp build 39.
> **Promotional text kan ändras DIREKT utan ny version** — gör det först av allt!

---

## Promotional text (kan sättas NU på 1.1.7, max 170 tecken)

```
Lajmet nga Kosova, Shqipëria, Maqedonia e diaspora — të gjitha në një aplikacion të shpejtë, të pastër dhe pa llogari.
```

## Subtitel (en-US-lokalen, max 30 tecken — 29 ✓)

```
Lajmet nga Kosova e Shqipëria
```

## Keywords (en-US, max 100 tecken — 93 ✓; upprepa ALDRIG ord från titel/subtitel)

```
shqip,gazeta,portal,prishtina,tirana,maqedoni,diaspora,aktualitet,politike,sporti,bota,kosove
```

## Beskrivning (en-US — albanska, utan push/bokmärkes-claims)

```
Lajme mbledh titujt më të fundit nga 20+ burime të besueshme shqiptare në një vend të vetëm. Nga Telegrafi dhe Gazeta Express te Balkanweb dhe Koha — lajme nga Kosova, Shqipëria, Maqedonia e Veriut dhe diaspora, në një fluks të pastër dhe të shpejtë.

PSE LAJME?
• 20+ burime të besueshme shqiptare në një aplikacion
• "Raportuar edhe nga" — shihni menjëherë kur disa media raportojnë të njëjtin lajm
• Filtro sipas vendit: Kosovë, Shqipëri, Maqedoni ose diaspora
• Filtro sipas kategorisë: Aktuale, Politikë, Ekonomi, Sport, Botë, Kulturë & Showbiz
• Kërko në të gjitha burimet njëherësh
• Ndaj lajmet me miqtë dhe familjen
• Pamje e ndritshme, e errët ose automatike
• Pa llogari, pa regjistrim — plotësisht falas

Lajme shfaq vetëm titujt dhe ju çon te burimi origjinal. Trokitni çdo artikull për të lexuar historinë e plotë në faqen e botuesit — ne i drejtojmë lexuesit te mediat shqiptare, kurrë nuk kopjojmë përmbajtjen e tyre.

Ndërtuar për shqiptarët kudo në botë — në Prishtinë, Tiranë, Shkup, apo në diasporë në Gjermani, Zvicër, SHBA e më gjerë — që duan të informohen pa vizituar 10+ faqe interneti.
```

## What's New 1.1.8 (en-US)

```
• Pamje të reja në App Store
• Përmirësime të shpejtësisë dhe rregullime gabimesh
```

---

## Ny lokalisering: de-DE (diasporan i DE/CH/AT — näst största marknaden)

**Subtitel (26 tecken ✓):**
```
Albanische Nachrichten-App
```

**Keywords (max 100 — 97 ✓):**
```
albanien,kosovo,shqip,lajme,gazeta,nachrichten,mazedonien,diaspora,balkan,prishtina,tirana,news
```

**Beskrivning (de-DE — samma albanska text funkar, men tysk intro ökar konvertering):**
```
Alle albanischen Nachrichten in einer App — aus dem Kosovo, Albanien, Nordmazedonien und der Diaspora. Über 20 vertrauenswürdige Quellen wie Telegrafi, Gazeta Express, Balkanweb und Koha in einem schnellen, übersichtlichen Feed.

Für Albanerinnen und Albaner in Deutschland, Österreich und der Schweiz, die informiert bleiben wollen — ohne zehn verschiedene Webseiten zu besuchen.

• 20+ albanische Nachrichtenquellen in einer App
• „Raportuar edhe nga" — sehen Sie sofort, wenn mehrere Medien dieselbe Nachricht melden
• Nach Land filtern: Kosovo, Albanien, Mazedonien oder Diaspora
• Nach Kategorie filtern: Aktuelles, Politik, Wirtschaft, Sport, Welt, Kultur
• Alle Quellen gleichzeitig durchsuchen
• Heller und dunkler Modus
• Kein Konto nötig — komplett kostenlos

Die App zeigt nur Schlagzeilen und führt Sie zur Originalquelle — wir leiten Leser zu den albanischen Medien, kopieren aber nie deren Inhalte.
```

**What's New (de-DE):**
```
• Neue App-Store-Bilder
• Schnellere Ladezeiten und Fehlerbehebungen
```

---

## Screenshots (ladda upp under iPhone 6,9")

Färdiga filer i `AppStore/screenshots-2026-07/final/` (1320×2868, i denna ordning):

1. `01_feed.png` — "Lajmet shqiptare, në një vend"
2. `02_filter.png` — "Kosovë, Shqipëri, Maqedoni e diaspora"
3. `03_search.png` — "Kërko në të gjitha burimet njëherësh"
4. `04_sport.png` — "Filtro sipas kategorive që të interesojnë"
5. `05_dark.png` — "Pamje e errët për lexim të qetë"

6,9"-bilder skalas automatiskt till alla mindre iPhones. iPad-bilder behövs bara om appen
stödjer iPad (kolla — annars hoppa över).

## Åldersgräns: gör om frågeformuläret → mål 12+

I ASC → App Information → Age Rating → Edit. Dagens 17+ kommer nästan säkert från
frågan **"Unrestricted Web Access" = Yes**. Svara **No**: appen är ingen webbläsare —
den öppnar endast artiklar från en kuraterad lista nyhetskällor i SFSafariViewController.
Sätt "News" = Frequent/Intense (ger 12+, samma som Telegrafi). Allt annat: No/None.

## Övrigt att göra i samma veva

- [ ] Sätt promotional text på 1.1.7 NU (kräver ingen release)
- [ ] Verifiera i ASC att gamla versionen verkligen saknar screenshots (förklarar konverteringen)
- [ ] Kategori: primär News ✓ (behåll). Sekundär: Magazines & Newspapers kan läggas till
- [ ] Bokmärken: BookmarkService + modell finns i koden men ingen UI — bygg vyn i 1.1.9
      och lägg då tillbaka "Ruani artikujt"-punkten i beskrivningen
- [ ] Push-notiser (1.2.0): backend har redan breaking-detection (3+ källor/30 min) —
      koppla till APNs, lägg då tillbaka "Njoftime"-punkten
```
