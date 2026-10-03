# Klar-sjekk – designbrief (original)

> **Historisk dokument.** Kopi av designbriefen i Claude Docs slik den sto 3. oktober 2026 (skrevet 2. oktober). Mye av oppbyggingen her (stripe, panel, rader, pil, farger for «under» og «ikke på») er **erstattet**. Se `../HISTORIKK.md` §3 for hva som er forkastet, og `../SPEC.md` for det som gjelder. Delene om kamp, API-rammer, Byvakt, varselnivåer, stil og ordliste er fortsatt grunnlaget for SPEC.

2026-10-02 · Daniel

## Hva og hvorfor

Klar-sjekk er én addon for World of Warcraft Forever som sier hva du mangler før du drar: buffer som går ut, ting du skal ha med, og om du har glemt noe når du forlater byen. Den slår sammen Klar-sjekk og Buffknapp, og bygger på Klar-sjekk.

For hvem: alle spillere, alle klasser, realmer og fraksjoner. Ingenting er laget for én karakter.

Designprinsipper:

- **Presis.** Én ting å se, med tallet bak. Ingen pynt som ikke bærer informasjon.
- **Enkel, men veldig effektiv.** Alt gjøres med dra og slipp: dra inn = ny oppføring, dra ut = slett.
- **Diskret.** Stille status hele tiden; lyd og tekst midt på skjermen bare når det betyr noe.
- **Stripa er infokanalen.** Du skal kunne bestemme deg uten å åpne noe; knappen åpner når du skal jobbe.

## Oppbygging

Addonen er én stripe med en rund knapp først, som stikker utenfor venstre kant slik portrettene gjør i spillets vinduer. Knappen slipper ned et panel under stripa og trekker det opp igjen. Det finnes ingen tittel, ingen faner og ingen egen flytende knapp.

**Stripa** (høyde 44 px, bredde ca. 540 px ved 100 %), fra venstre. Hvert felt har en liten gul etikett over verdien, som i statistikkpanelet:

| Felt | Viser | Eksempel |
|---|---|---|
| Knappen | Pil + tall for hvor mange ting som mangler; ringen har fargen til det verste på stripa | 3, rød ring |
| Buffer | Bufferen som haster mest, og hvor mange som mangler | Thorns 0:38 · 1 av |
| Ting | Det som er tomt først, så det som er under | Bandage 0/10 · Healthstone 1/3 |
| Byvakt | Hvor du står, eller hva som mangler før du drar | Stormwind |

**Knappen** (64 px rund medaljong som stikker utenfor venstre kant av stripa, som portrettene i spillets vinduer): bronsering, glødende statusring innenfor, mørk kjerne med en gul trekantpil. Pila peker ned når panelet er oppe-trukket og snur seg når det er nede. Tallet sitter i et lite mørkt merke med gullkant nede til høyre, som rangtallene på talentene.

**Panelet** (bredde ca. 320 px) faller ned under stripa, med tre deler over hverandre. Hver del starter med en kategorilinje som i Reputation-vinduet, og kan felles sammen:

1. **Buffer.** Det du har dratt inn fra spellboken, og eliksirer og mat. Hver rad: ikon, navn, tid igjen.
2. **Ting.** Items med ønsket antall. Hver rad: ikon, navn, «har/vil ha».
3. **Byvakt.** Én linje nederst: hvilke byer som er vaktet (hovedstedene fra start) og «+ dette stedet».

Radene er 30 px høye, ikonene 24 px.

## Samhandling

Alt gjøres med musa direkte på stripa og panelet; ingen innstillingsvinduer.

| Handling | Slik | Tilbakemelding |
|---|---|---|
| Slippe ned / trekke opp panelet | Klikk på knappen | Panelet glir ned på ca. 0,3 s; pila snur |
| Felle sammen en del | Klikk på kategorilinja (Buffer, Ting, Byvakt) | «−» blir «+» og radene skjules |
| Se detaljer | Hold musa over en rad | Tooltip i spillets stil: navn, «Har 0 av 10» eller tid igjen, og hjelpelinjer |
| Legge til | Dra et ikon fra baggen eller spellboken hvor som helst inn på stripa eller panelet | Raden dukker opp i riktig del: spell → Buffer, item → Ting |
| Slette | Dra en rad ut av panelet | «Slipp for å fjerne» ved musa; angres med `/klar angre` |
| Bytte rekkefølge | Dra en rad opp eller ned | Gul strek der den lander |
| Antall / minutter | Musehjul på raden (Shift = 5) | Tallet endres med en gang |
| Flytte | Dra i stripa (ikke på knappen) | Stripa følger musa |
| Skalere | Hold musa over et av de fire hjørnene, klikk og dra | Markøren endres og en tynn gullvinkel vises; motsatt hjørne står stille |
| Låse | Hengelåsen (vises bare når musa er over) | Hjørner og flytting slås av |
| Legge til en by | «+ dette stedet» i Byvakt-linja | Stedet du står i, vaktes; knappen er grå når stedet alt er vaktet |

Skalering går i trinn på 5 %, fra 70 % til 150 %.

## Tilstander og varsler

Varsler slites ut hvis de kommer ofte. Derfor er det stillhet hele tiden, og stemme bare når noe endrer seg eller ikke kan angres.

**Fargene** gjelder overalt (rader, stripa, ringen rundt knappen) og er spillets egne tekstfarger:

| Tilstand | Farge | Ting | Buffer |
|---|---|---|---|
| Alt klart | Grønn `#40BF40` | har minst ønsket antall | på, mer enn 40 s igjen |
| Under / snart ute | Gul `#FFD100` | færre enn ønsket | 40 s eller mindre igjen |
| Tomt / mangler | Rød `#FF2020` | 0 | gått ut (du hadde den) |
| Ikke på | Grå `#808080` | – | aldri lagt på i økten; varsles ikke løpende |

**Tre nivåer av varsel:**

1. **Hele tiden – stille.** Tall og farge på stripa og ringen. Aldri lyd.
2. **En buff du hadde, går ut.** Ved 40 s dukker et lite ikon med nedtelling opp nær midten av skjermen. Det forsvinner når du fornyer. Ingen lyd.
3. **Øyeblikk du ikke kan angre** (du forlater en vaktet by, åpner flykartet, tar portal eller båt, køen spretter). Én tekstlinje midt på skjermen og én lyd, bare hvis noe mangler. Tomt = rød tekst og lyd; under = gul tekst uten lyd; alt klart = kort grønn «Alt med» uten lyd. Aldri gjentatt.

I kamp vises aldri lys eller tekst; nedtellingen fortsetter fra tiden vi så før kampen.

## Visuell stil

Klar-sjekk skal se ut som en del av WoW Forevers eget UI, som vinduene for karakter, Reputation og First Aid: mørk brun bakgrunn, dobbel bronsekant, gule kategorilinjer og hvit tekst med svart skygge. Ingen pergament eller tunge ornamenter.

| Element | Verdi |
|---|---|
| Panel og stripe, bakgrunn | `#201812` øverst til `#130E0A` nederst, nesten helt dekkende, med svakt lys i toppen |
| Kant | 2 px bronse, lysere øverst (`#9A7A3E`) og mørkere nederst (`#4F3A1A`), med 1 px svart utenfor og innenfor |
| Skillelinjer | en fure: 1 px svart + 1 px `#4A3920` |
| Hjørner | 4 px på stripa, 5 px på panelet |
| Kategorilinjer | 24 px høye, brune (`#3D2C19` til `#271B10`), 1 px kant `#6A4D27`, gul tekst og «−» til høyre |
| Etiketter | spillets gule `#FFD100`, overskriftsskriften |
| Navn og brødtekst | `#ECE6D8`, 13 px, 1 px svart skygge |
| Tall og tider | spillets smale tallskrift, 14 px, i statusfargen |
| Hjelpetekst | `#A0A0A0` |
| Ikonrammer | 24 px, 1 px svart + 1 px `#4D4535`, 3 px hjørner, innfelt skygge; «ikke på» vises i gråtoner |
| Tooltip | som spillets: mørkeblå `#090A14`, 1 px grå kant `#60636F`, 5 px hjørner |

**Knappen skal se så bra ut at man får lyst til å trykke:** 64 px rund medaljong, som portrettene i spillets vinduer. Ytterst 4 px bronsering (lys `#F0CF86` øverst til venstre, mørk `#6A4A1C` nederst til høyre), så 1 px svart, en 2 px statusring som gløder svakt, og en mørk kjerne `#17110C`. Pila er en fylt gul trekant `#FFD100` med svart kant. Ved mus over vokser den 6 %, bronsen lyser opp med gul glød og pila blir lysere (`#FFF3B0`). Klikk = pila snur 180° mens panelet glir.

I spillet brukes spillets egne skrifter og de ekte ikonene; skissens plassholdere og nettskrift (Marcellus for Friz Quadrata, Archivo Narrow for tallskriften) erstattes.

## Tekster og ordliste

All tekst er på norsk (bokmål), kort og uten emoji. Tall før ord, «har/vil ha» for antall, minutter og sekunder som «24 min» og «0:38».

| Ord | Betyr | Ikke |
|---|---|---|
| Buffer | Spells, eliksirer og mat som gir en buff | «auras», «effekter» |
| Ting | Items du vil ha med, med antall | «inventar» |
| Byvakt | Varsel når du forlater en by | «geofence» |
| mangler | Rød: tomt eller gått ut | «feil» |
| ikke på | Grå: aldri lagt på | «inaktiv» |
| Alt med | Grønn bekreftelse ved byvakt | «OK!» |
| + dette stedet | Legg til stedet du står | «Legg til lokasjon» |

Faste meldinger:

- Byvakt, noe mangler: «Du forlater Stormwind» + «Runecloth Bandage 0/10 · Healthstone 1/3»
- Byvakt, alt klart: «Alt med»
- Dra ut: «Slipp for å fjerne», så i chatten «<navn> er fjernet. Skriv /klar angre for å få den tilbake.»
- Tomt panel: «Dra en ting fra baggen eller en spell fra spellboken hit.»

## Fornye buffer i kamp

Trykker du på en buffrad i kamp, regnes buffen som fornyet og nedtellingen starter på full tid igjen. Spillet skjuler varighet og hvilken spell du kastet, så vi bygger det på det vi vet selv.

**Slik registreres trykket:**

1. **Hvilken rad du trykket på.** Det er addonens egen informasjon og aldri hemmelig.
2. **At du faktisk kastet noe.** Spillet melder fra når du fullfører en spell, men ikke hvilken. Trykk + fullført spell innen 1 sekund = buffen er på. Bommer du (for langt unna, tom for mana), kommer ingen bekreftelse, og vi teller ikke feil.
3. **Hvor lenge den varer.** Husket fra sist vi så buffen utenfor kamp. Aldri sett «på» uten nedtelling til kampen er over.
4. **Eliksirer og mat:** antallet i baggen går ned med én, som ekstra bekreftelse.

**Design:** Buffradene på stripa og i panelet er klikkbare. Ett trykk kaster buffen og registrerer den, så varselet og handlingen er samme sted. Nedtellingsikonet midt på skjermen viser bare tiden: knapper som kaster spells kan ikke lages eller vises midt i en kamp, bare utenfor.

**Begrensning:** Kaster du buffen fra din egen actionbar, eller fornyer en annen spiller den på deg, ser vi det først etter kampen.

Kilder: [Patch 12.0.0/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes), [Secret values](https://warcraft.wiki.gg/wiki/Secret_values).

## Rammer fra spillet og parkerte ideer

Designet må tåle disse reglene i WoW Forever:

- Buffer er «hemmelige» for addons i kamp, i bosskamper og under PvP-kamper. Vi leser utenfor kamp og teller ned fra det vi visste.
- Addons kan vise, men aldri bestemme eller trykke for deg. Hver handling er ett klikk fra spilleren.
- Spillet vet ikke at du *skal* forlate byen. Byvakt reagerer når du går over grensa, åpner flykartet, eller tar portal eller båt.
- Spillet har én markør for skalering; om den kan endres per hjørne, er ikke sjekket.

**Parkert** (ønsket senere, ikke nå):

- Klikkbare infofelt på stripa som tar deg rett til riktig del.
- Party-buffer: sjekke at partyet har buffene før en pull. Må testes i spillet først, sammen med fornying i kamp (kildene gjelder vanlig WoW og må bekreftes i WoW Forever).

Kilder om reglene: [Patch 12.0.5/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.5/API_changes), [C_UnitAuras.GetUnitAuras](https://warcraft.wiki.gg/wiki/API:C_UnitAuras.GetUnitAuras).
