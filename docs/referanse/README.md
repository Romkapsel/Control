# Referanse

Alt her er grunnlag for `../SPEC.md`. Ved konflikt gjelder SPEC.

## prototype/

Filene fra designcanvaset (versjon 18). De statiske tavlene (Tilstander, Gruppa, Samhandling, Varsler) er illustrasjoner og kan avvike i detaljer (f.eks. antall punkter i statuslinja); `Main.dc.html` og SPEC er fasit. Filene er laget i et designverktøy med egen malsyntaks (`{{…}}`, `<sc-for>`, `<sc-if>`, `<dc-import>`). De kan ikke kjøres direkte, men logikken er lesbar JavaScript.

| Fil | Hva |
|---|---|
| `prototype-logikk.js` | **Les denne.** Logikken i den interaktive prototypen: testdata, alvorlighet (`buffSev`, `stockSev`, `sev`), `kanTrykkes`, hva som står ute (`bygg`), tall og ringfarge, statuslinje, tooltip-tekster, klemming, menyretning. |
| `buffknapp-logikk.js` | Logikken i 40 px-knappen: hvilke visuelle lag som vises i hvilken tilstand. |
| `Main.dc.html` | Interaktiv prototype (mal + logikk). |
| `BuffKnapp.dc.html` | Knappekomponenten. |
| `Tilstander.dc.html` | Medaljongens tilstander, knappenes prosess, tier-eksempel. |
| `Gruppa.dc.html` | Gruppebuffer og begge sider utfoldet. |
| `Samhandling.dc.html` | Tomt, legge til, slette, bytte tier, i kamp, låse og skalere. |
| `Varsler.dc.html` | Varselnivå 2 og 3 (Byvakt). |
| `Sammenligning.dc.html` | Prototypen ved siden av et skjermbilde av spillets Reputation-vindu (bildet er ikke med). |
| `canvas.json` | Hvordan tavlene ligger på canvaset. |

## skjermbilder/

| Fil | Viser |
|---|---|
| `01-hvile.png` | Startscenarioet (SPEC §19): tallet 7, rød ring, tre knapper ute |
| `02-mus-over-hoyre-sone.png` | Symbolene ved mus over, høyre sone aktiv |
| `03-mus-i-midten-flytt.png` | Midten ulåst: flyttekryss |
| `04-begge-sider-apne.png` | Begge sidemenyer, statuslinjer |
| `05-sider-og-meny-apne.png` | Sidemenyer og meny |
| `06-tooltip-gruppebuff.png` | Tooltip for gruppebuff |
| `07-tooltip-min-buff.png` | Tooltip for egen buff |
| `08-last-mus-i-midten.png` | Låst: hengelås i midten |
| `09-klikkrekke-knappen-alene.png` | Klikkrekka 7 → 6 → 5 → 5 → 4, til knappen står alene |
| `tavle-*.png` | Hele tavlene |

## designbrief-original.md

Den første briefen (2. okt. 2026). Historisk; mye er erstattet. Se `../HISTORIKK.md` §3.
