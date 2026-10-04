# Klar-sjekk – historikk, beslutninger og lærdom

Denne fila forklarer **hvordan** vi kom fram til `SPEC.md`, og **hvorfor**. Den er bakgrunn. Det som gjelder, står i `SPEC.md`. Bruk den til å forstå intensjonen bak en regel, og for å unngå å bygge noe vi allerede har forkastet.

---

## 1. Tidslinje

Alt skjedde 2.–3. oktober 2026, i samtale mellom Daniel og Claude (Cowork), først som designbrief i Claude Docs, så som interaktiv prototype i et designcanvas (18 versjoner).

| # | Hva Daniel sa (kort) | Hva det førte til |
|---|---|---|
| 1 | Designbrief: én addon for WoW Forever som slår sammen «Klar-sjekk» og «Buffknapp». | Første modell: en **stripe** (44 px) med rund knapp til venstre som stikker ut som spillets portretter. Knappen slipper ned et **panel** med tre deler: Buffer, Ting, Byvakt. Varselfarger, tre varselnivåer, fornying i kamp, Byvakt. Party-buffer ble parkert. (Se `referanse/designbrief-original.md`.) |
| 2 | «Ta en helt ny runde på selve designet … dette skal være i WoW … så det virkelig sitter, visuelt.» (6 skjermbilder av spillets vinduer) | Visuell stil hentet fra spillets egne vinduer: bronserammer, Friz-aktig skrift, gule kategorilinjer i Reputation-stil, tooltip i spillets stil, klassefarger. |
| 3 | «Det bra ut.» | Stilen ble låst. |
| 4 | «Knappene eller ikon … veldig enkelt å trykke på. Byvakt inn i menyen? Buffs mer som knapper … som vokser bortover?» | Buffer og ting ble **40 px-knapper** i en rad som vokser bortover. Byvakt flyttet inn i menyen. |
| 5 | «Ikke på må jo være den som stikker seg mest ut. Prøv noe annet enn farger for å signalisere hvor i prosessen de er. Feltene like lange.» | Prosess vist med form: **tømming ovenfra** for brukt tid, **stor nedtelling** når den snart går ut, **pulserende gullglød** når den mangler og kan trykkes. Like brede felt (stripe, knapperad, meny). |
| 6 | «Den er i knappen først – ringen lyser rødt, orange og ingenting når alt er ok … Venstre side folder seg ut til venstre og vice versa … diskret, kul indikator når du hovrer … hovrer og trykker ned – får man menyen.» + «Opp er lås.» | Stor modellendring: **medaljongen først**. Ringen lyser rødt/oransje/ingenting. Fire soner: venstre/høyre folder ut sider, ned = meny, opp = lås. |
| 7 | «Kanskje den bare har tallet i midten, og når du hovrer, så får du de ulike pilene og låsesymbol? Kanskje pilene også skal være symboler.» | **Tallet i midten.** Symboler (ikke piler) vises bare ved mus over. |
| 8 | «Tier-liste 1, 2 og 3? Tier 1 synes utenfor sirkelen med en gang, så de kan trykkes direkte.» | Tier-system innført. Tier I sto alltid ute ved medaljongen. |
| 9 | «Items må også inn her – viktige flasks som må være på til enhver tid.» | Items (flasks, eliksirer, mat, bandasjer) inn i samme system. |
| 10 | «Hva skal tier 2 og 3 gjøre? … Addon kan ikke lese data i combat. Mest i bruk når jeg quester med en kompis … overvåke buffs jeg kan gi (PB) som mangler hos andre. PB vokser én vei, mine (MB) den andre. Legge til og trekke fra PB. Skifte retning i meny.» | **PB og MB** på hver sin side. Gruppeknapper med én rute per medlem. «Bytt sider» i menyen. Kampbegrensningene ble en del av designet (frys i kamp, kast på den som manglet før kampen). |
| 11 | «Vi dropper tier 3. … En buff jeg kan gi meg selv (spell) – alltid rødt varsel, ingen unnskyldning. En ting som mangler helt – rødt. 1/6 – oransje … Tier-lista handler mer om hva som skal poppe opp av seg selv … Items skal havne der hvis de kan gi en buff og jeg ikke har buffen på, men fortsatt signalisere oransje hvis det kun mangler 3/4 av en eliksir … to deler slått sammen.» | **Tier III droppet.** Varselreglene i SPEC §6.2: buff-del og lager-del, verste vinner. Tier = hvor ting vises, ikke farge. Tier II dukket opp av seg selv når den kunne trykkes. |
| 12 | «Buffs forsvant ikke når jeg trykket på dem – tallet gikk ikke ned. Hvor skal man trykke på knappen når den ikke er låst? Alt areal er tatt opp av interne knapper … uten at knappen blir mye større. Låst på en kulere måte, «støpt» til skjermen med en mer beefy ramme? Test dette.» | Klikkfeil i prototypen rettet. **Midten (22 px) ble grepet** for å flytte. Prøvde «støpt» låst utseende (bronsekrage med nagler). Testet i nettleser. Holdt innenfor skjermen, meny oppover når lavt, «2 t» i stedet for «120 min». |
| 13 | «Det holder at symbolet i midten er låsesymbol når knappen er låst. Vi legger støperiet til siden. Målet er at knappen skal være alene. Når en tier 1-buff mangler, vises den ved siden av knappen – når man trykker den, er buffen på og den forsvinner. Sidemenyen viser det som mangler helt og delvis og timere, men kun hvis man åpner den.» | **Gjeldende modell** (SPEC): knappen alene, bare tier I som kan trykkes står ute og forsvinner ved trykk, tier II bare i sidemenyen, lås = hengelås i midten. |
| 14 | «Lag en fullverdig spec jeg kan ta med til Claude Code.» | Denne pakka. |

---

## 2. Beslutninger som gjelder

| Beslutning | Hvorfor |
|---|---|
| Medaljongen er hovedelementet, med tall og ringfarge | Én ting å se. Ringen lyser bare når noe er galt. |
| Fire soner + midten | Alle funksjoner på 64 px uten å gjøre knappen større. Midten er fritt område for å gripe. |
| Knappen står alene; bare tier I som kan trykkes, står ute | Mindre støy. Det som står ute, er en oppgave. Trykk = ferdig = borte. |
| Tier II bare i sidemenyen | Oversikt når du ber om den. Tier bestemmer bare hvor ting vises. |
| PB og MB på hver sin side, kan byttes | Gruppebuffer og egne buffer er ulike oppgaver. Plassering på skjermen avgjør hvilken vei som er praktisk. |
| Rødt: spell du kan gi deg selv mangler, eller noe er tomt. Oransje: under ønsket, eller snart ute. | Daniels regler (punkt 11). Buff-del og lager-del slås sammen, verste vinner. Om buffting som ikke er på er rød eller oransje, er åpent (SPEC Q1). |
| Oransje i stedet for gult for «under» | Gult er spillets tekst- og etikettfarge; varselet må skille seg ut. |
| Prosess vist med form (tømming, nedtelling, glød), ikke bare farge | «Ikke på» skal stikke seg mest ut, og farge alene er svakt. |
| Lagerting lyser aldri | Du kan ikke fikse lager med et klikk. Det vises i tall og farge. |
| Fullt lager vises som bare tallet («3»), under som «3/4» | Mindre støy; brøken betyr «for lite». |
| Låst = hengelås i midten ved mus over | Enkelt. «Støpt» utseende lagt til side. |
| Holdt innenfor skjermen med alt utfoldet; meny oppover når lavt | Ingenting skal havne utenfor kanten når du åpner noe. |
| Tidsformat «N t» / «N min» / «0:SS» | «120 min» brøt over to linjer i en 40 px-knapp. |
| I kamp fryses layout; trykk registreres og telles ned | Spillet tillater ikke å vise/skjule sikre knapper i kamp, og skjuler auradata. |

---

## 3. Forkastet eller erstattet (ikke bygg dette)

| Var | Ble | Når |
|---|---|---|
| Stripe (44 px) med felt for Buffer/Ting/Byvakt og et panel som slippes ned | Medaljong + sider + meny | 6 |
| Gul trekantpil i knappen som snur seg | Tall i midten, symboler ved mus over | 7 |
| Tallet i et lite merke nede til høyre på knappen | Tallet i midten | 7 |
| Flytte ved å dra i stripa | Dra i midten av medaljongen | 12 |
| Rader (30 px, ikon 24 px, navn, tid) i panelet | 40 px-knapper i rader | 4 |
| Gul `#FFD100` for «under / snart ute» | Oransje `#FF8C1A` | 11 |
| Grå «ikke på» som ikke varsles løpende | «Ikke på» stikker seg mest ut; rød for spells du kan gi deg selv | 5, 11 |
| Tier III | Droppet (kan komme tilbake som «bare i menyen») | 11 |
| Tier I står alltid ute | Tier I står ute bare når den kan trykkes | 13 |
| Tier II dukker opp av seg selv når den kan trykkes | Tier II bare i sidemenyen | 13 |
| Lite gullmerke med lås øverst på medaljongen når låst | Hengelås i midten ved mus over | 12 |
| «Støpt» låst: tung bronsekrage med fire nagler og kraftigere rammer med nagler | Lagt til side (parkert) | 13 |
| Hjørne-skalering av stripa | Skalering beholdt, plassering åpen (SPEC Q5) | 6 |
| Party-buffer parkert | Party-buffer (PB) er en kjernedel | 10 |

---

## 4. Hva vi har lært

**Om brukeren og bruken**

- Addonen brukes mest utenfor kamp (questing med en kompis), og ellers mellom pulls. Det gjør kampbegrensningene til et mindre problem enn fryktet.
- «Tallet gikk ikke ned» kom opp to ganger. Brukeren forventer at et klikk gir synlig og umiddelbar effekt: knappen forsvinner og tallet går ned. Lagervarsler som står igjen etter et klikk (f.eks. flask 1/2 etter bruk) oppleves som feil hvis det ikke er tydelig hvorfor. Derfor: fullt lager vises som bare tallet, og «har/vil ha» bare når det er for lite (og SPEC Q2 er åpent).
- Daniel tenker i to deler for ting: «gir den en buff som ikke er på?» (skal kunne trykkes) og «har jeg nok?» (farge). Hold dem adskilt i koden, slå dem sammen bare til slutt.
- Han vil at knappen skal være liten og alene, men at alt skal være ett klikk unna.

**Om spillet**

- WoW Forever bruker Mainline-UI og Midnight-reglene: auraer kan være hemmelige, og beskyttede knapper kan ikke endres i kamp. Design må tåle det fra start.
- Addons kan aldri kaste for deg. Hvert kast er et klikk på en sikker knapp.
- I kamp kan vi ikke vite sikkert hva som skjedde. Bygg på det vi vet selv: hvilken knapp ble trykket, og at et kast ble fullført like etter.
- Mat gir buff først etter at du har spist ferdig. Gruppe-versjoner av buffer (Gift of the Wild osv.) teller som den vanlige.

**Om designet**

- Alt areal i en 64 px-knapp var tatt av soner. Løsning: en fri sirkel i midten (22 px) som grep, og symbolene flyttet ut mot kanten.
- Knapper som vises og forsvinner trenger en kort trykket-effekt og en ut-animasjon, ellers ser det ut som de bare blinker bort.
- Lange tider bryter i 40 px-knapper. Teksten må aldri bryte linje.
- Grensene for flytting må regnes med alt utfoldet, ellers havner sidemenyen utenfor skjermen.

**Om prototypen (designverktøyet, ikke relevant for Lua)**

- Klikk på en knapp som var pakket rundt en innebygd komponent nådde ikke fram (egen React-rot). Løst med en gjennomsiktig knapp over komponenten. I WoW tilsvarer dette at klikk-området må være selve den sikre knappen.

---

## 5. Verifisert i spillet

Fylles ut i fase 0 (SPEC §18). Skriv dato, klient (beta/live, build) og svar for V1–V9 fra SPEC §2.

| # | Svar | Dato / build |
|---|---|---|
| V1 | Interface **16001**, build **70205** (var 70170 2. okt), `WOW_PROJECT_ID` 18. Mappe `_classic_beta_`. Addonen laster uten «utdatert»-avkrysning. | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) |
| V2 | **Utenfor kamp: ja**, også i dungeon: navn, spellId, `duration`, `expirationTime`, `sourceUnit`. **I kamp: nei – både i dungeon (Stockade) og i åpen verden (Elwynn)**: `GetAuraDataByIndex` feiler med «Auras cannot be accessed when secret while tainted». `C_Secrets.ShouldAurasBeSecret()` gir `true` da og `false` ellers: spør den før lesing. | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) + Blackrocks (Rogue) i party |
| V3 | **Ja, utenfor kamp** (Blackrocks: Camp Benefits, Blessing of Might). **Nei i kamp** (samme feil som V2). `UnitInRange` er **hemmelig også utenfor kamp** → rekkevidde må finnes på annen måte eller regnes som ukjent (Q8). | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) + Blackrocks (Rogue) i party |
| V4 | **Ja: spellId er lesbar i kamp** i åpen verden (`UNIT_SPELLCAST_SENT/SUCCEEDED` for Wrath 5178 midt i kampen). Trykk i kamp kan altså bekreftes med riktig spell (SPEC §12.4 punkt 2), ikke bare «noe ble kastet». | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) + Blackrocks (Rogue) i party |
| V5 | **Problem:** «Party1» (`type=spell`, `spell=5232` som ID, `unit=party1`, `AnyUp`+`AnyDown`) ble klikket 5 ganger med Blackrocks i gruppa uten at noe kast ble forsøkt (ingen SENT/FAILED). Testknappene er utvidet (navn / ID / makro / party, bare «ned»-klikk, logg av `ADDON_ACTION_BLOCKED` og `UI_ERROR_MESSAGE`) for å finne årsaken. Venter på ny test. | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) + Blackrocks (Rogue) i party |
| V6 | **Ja, også i kamp i dungeon.** `C_Item.GetItemCount` er ikke hemmelig. | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) |
| V7 | **Ranks har egne spellId** (MotW 1126/5232, Thorns 467/782); auraen bærer ID-en til ranken som ble kastet → gjenkjenn på navn. Mat: auraen heter **«Well Fed»** (spellId 1249519, 15 min); spising = «Nutritious Food» (1249500) + «Food» (433). Varigheter: MotW 60 min, Thorns 10 min, Blessing of Might/Fortitude 60 min. Nye Forever-items finnes (f.eks. 247755 Elixir of Minor Force, 279956 Mana Well). | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) |
| V8 | `TAXIMAP_OPENED` kommer (Stormwind). Ut porten: `ZONE_CHANGED_NEW_AREA` Stormwind City → Elwynn Forest + `PLAYER_UPDATE_RESTING` (resting av). Båt Darkshore → Stormwind Harbor = lasteskjerm + `PLAYER_ENTERING_WORLD`. Dungeon: `instanceType` = `party`. `GetRealZoneText` kan være tom rett ved `PLAYER_ENTERING_WORLD`. Kø-popup ikke testet. | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) |
| V9 | **Navn og GUID på party er lesbare i kamp** (Blackrocks, Player-4619-…). Klasse lesbar. Rekkevidde hemmelig (se V3). | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) + Blackrocks (Rogue) i party |

---

## 6. Beslutningslogg (fortsett her)

Når noe avgjøres under byggingen, skriv det her med dato, og oppdater SPEC.

| Dato | Beslutning | Hvem |
|---|---|---|
| 2026-10-03 | Spesifikasjon v1.0 skrevet fra designcanvas v18 | Daniel + Claude |
| 2026-10-03 | Addonen heter **Control** (mappe, TOC, `ControlCharDB`, `/control` og `/ctl`). Utvikling i `Documents\Control`; den gamle Klar-sjekk og Buffknapp røres ikke | Daniel |
| 2026-10-03 | Q1 rød, Q2 alt, Q3 40 s, Q9 automatisk (standardvalgene) | Daniel |
| 2026-10-03 | Gruppeversjonen (Gift of the Wild osv.) kastes bare i party når flere enn 2 mangler buffen og reagensen finnes; ellers enkeltversjonen (SPEC §9.5) | Daniel |
| 2026-10-03 | Lista fra gamle Klar-sjekk flyttes over som MB tier II (Q10) | Daniel |
| 2026-10-03 | Tester kjøres i Lua 5.1 via Python + lupa (`python tests/run.py`) i stedet for busted/luacheck, som ikke er installert. Samme oppsett som wow-forever (300+ tester) | Daniel + Claude |
| 2026-10-03 | Mappa kobles inn i spillet med en junction fra `_classic_beta_\Interface\AddOns\Control` | Daniel + Claude |
| 2026-10-03 | Fase 0 bygget: `Control.toc` (interface 16001) + `Debug.lua` (`/control debug`, `debug knapp`, `debug tøm`). 30/30 tester. Junction opprettet. Venter på Daniels test i spillet | Claude |
