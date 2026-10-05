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
| V5 | **Ja for deg selv, i alle tre varianter**: `type=spell` med navn, `type=spell` med spellId (5232) og `type=macro` (`/cast [@player] Mark of the Wild`) kastet alle på ett «ned»-klikk når knappen bare er registrert for `AnyDown` (`ActionButtonUseKeyDown` = 1). Klikk under global cooldown gir `UNIT_SPELLCAST_FAILED` + `UI_ERROR_MESSAGE` «Spell is not ready yet.» **Party ikke bekreftet:** første test (`AnyUp`+`AnyDown`, med Blackrocks i gruppa) kastet ikke og ga ingen feil; uten party gir et klikk på `unit=party1` heller ingen feil. Testes igjen med noen i gruppa. Valg for byggingen: `type=spell` med navn, bare `AnyDown` (eller `AnyUp` når CVar er 0). | 4. okt, beta 1.60.1 build 70205, Sommer (Druid) |
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
| 2026-10-04 | Fase 0 ferdig unntatt party-knapp (V5) og kø-popup (V8), som testes når det passer. Sikre knapper: `type=spell` med navn, registrert bare for «ned» (`AnyDown`) når `ActionButtonUseKeyDown` er på | Daniel + Claude |
| 2026-10-04 | **Fase 1 ferdig:** `Rules.lua` (ren Lua) + `Locale/nbNO.lua`. 125/125 tester, inkludert §19 trinn for trinn (7 → 6 → 5 → 5 → 4) og statuslinjene ord for ord. Regeltestene kjøres i en tom Lua uten WoW-API | Claude |
| 2026-10-04 | En tom side i sidemenyen får **én** slipprute (SPEC §6.5), ikke fem som i prototypen | Claude |
| 2026-10-04 | Gruppeversjonen krever reagens bare når `reagents` er oppgitt; `nil` = trengs ikke. Målet er alltid første som mangler | Claude |
| 2026-10-04 | **Fase 2 bygget:** `Core.lua`, `Data.lua`, `UI/Style.lua`, `UI/Medallion.lua`. Medaljong med tall og ring fra testdata (`/control test` blar: rød 7 / oransje 2 / alt med / tom), soner med symboler og lysprikk, flytting fra midten, lås, klemming med sidemenyer og meny utfoldet, posisjon lagret. 182/182 tester. Venter på test i spillet | Claude |
| 2026-10-04 | Medaljongen tegnes med fargeflater, gradienter og streker. Eneste tekstur er den runde masken (atlas `CircleMaskScalable`, ellers `TempPortraitAlphaMask` hvis filen finnes, ellers firkantet) – sjekkes før bruk, så en ukjent sti aldri kan krasje klienten | Claude |
| 2026-10-04 | Lysbuen langs ringen ved mus over (SPEC §7.1) er utsatt til fase 9; lysprikken som peker mot sonen er med. Flytting er av i kamp allerede nå | Claude |
| 2026-10-04 | Fase 2 testet i spillet av Daniel: virker. Finpuss etter skjermbilder: symbolene som tynne konturer, kompakte personsymboler 15 px fra midten, glød i tre lag, lysprikk på bronsekanten. Medaljongen beholdes på 64 px (størrelse kommer i fase 9) | Daniel + Claude |
| 2026-10-04 | **Fase 3 bygget:** `Scan.lua` (egne buffer når de ikke er hemmelige, lager alltid, varigheter huskes), `Track.lua` (trykk + `UNIT_SPELLCAST_SUCCEEDED` med riktig spell-ID innen 1 s, eller innen 10 s når kastet startet i tide), `UI/EntryButton.lua` (40 px sikker knapp, tilstandene i §7.5, tooltip), `UI/Tray.lua` (knappene ved medaljongen, frosset i kamp). 249/249 tester. Venter på test i spillet | Claude |
| 2026-10-04 | **Midlertidig snarvei til fase 4/6:** slipp en spell eller en ting på medaljongen = ny oppføring i **tier I**. `/control tøm` tømmer lista. Spørre Daniel om snarveien skal bli værende | Claude |
| 2026-10-04 | Mat: auraen er «Well Fed» (V7). Et bekreftet trykk holder maten «på» i 40 s mens du spiser; kommer ikke Well Fed, går den tilbake | Claude |
| 2026-10-04 | I kamp: gløden skrus av/på med alpha (aldri Show/Hide under en sikker knapp), skjermgrensen endres ikke, knappene ved medaljongen står fast. Krymp-ut-animasjonen (0,17 s) er ikke med ennå – knappen forsvinner direkte (fase 9) | Claude |
| 2026-10-04 | Fase 3 testet: virker. Kast i kamp bekreftet med spell-ID (MotW 5232). Endret etter Daniels ønske: ingen tekst «ikke på»/«gått ut» på knappene (gløden er signalet); i kamp tones en ferdig knapp ned til 15 % (sikre knapper kan ikke skjules i kamp) og fjernes etter kampen | Daniel + Claude |
| 2026-10-04 | Rammene ved knappen og sidemenyene starter i medaljongens **midtpunkt** (var 18 px fra kanten; hjørnene tittet fram bak sirkelen). Bredde = 40 + plasser × 46 (+12 med fure). Knappene står på samme sted | Daniel + Claude |
| 2026-10-04 | I kamp blir en ferdig knapp **usynlig** (0 %, ingen tooltip), ikke 15 %: «skyggen» var forstyrrende. Plassen står tom til kampen er over. Vurdert og forkastet: skjule knappen med et sikkert skript ved klikk – den ville forsvunnet også når kastet feiler (global cooldown) | Daniel + Claude |
| 2026-10-04 | **Omgjort samme dag (Daniel):** sikkert skript ved klikk i kamp. Knappen forsvinner og rekka lukker seg med en gang; rammen krymper. Feiler kastet, står det i tallet, og knappen kommer tilbake etter kampen. Skriptet bruker `SecureCmdOptionParse("[combat]")` og definerer ingen funksjoner (restricted Lua) | Daniel + Claude |
| 2026-10-04 | **Feil funnet av Daniel:** en potion ble lagt inn som buffting (den har en bruk-effekt) og ble stående rød. Nå: buffting bare for eliksir/flask/scroll og mat med «Well Fed» i tooltipen; resten er lagerting. Feil type rettes ved innlogging. `/control debug` viser itemklasse og undertype, for å sjekke Forever-items | Daniel + Claude |
| 2026-10-04 | Importen fra gamle Klar-sjekk (Q10) har ikke skjedd: Daniel har slått av Klar-sjekk og Buffknapp, og da finnes ikke `KlarsjekkDB`. Spør Daniel om den skal droppes | Claude |
| 2026-10-04 | Ønsket antall er **1** når noe legges til (var: antallet du har). Én eliksir drukket ga ellers et oransje lagervarsel med en gang | Daniel |
| 2026-10-04 | **Tieren styrer fargen:** det som mangler helt (buff ikke på, tomt) er **rødt i tier I** («må ha», f.eks. raid-flask) og **oransje i tier II**. Under ønsket og snart ute er alltid oransje. Gjelder spells, ting og gruppebuffer. Erstatter «tier bestemmer aldri fargen» og Q1 | Daniel |
| 2026-10-04 | Importen fra gamle Klar-sjekk (Q10) er **droppet** | Daniel |
| 2026-10-04 | **Fase 4 bygget:** `UI/SideBar.lua`. Sidemenyene folder ut med venstre/høyre sone (bare utenfor kamp), dekker knappene ved medaljongen på sin side, viser tier I, fure, tier II, tomme ruter (første er slippmål) og statuslinja i farger. Høyreklikk = tier, musehjul = ønsket antall (Shift = 5), slipp en spell/ting på sidemenyen = sist i tier II (spell på gruppesiden = gruppebuff), Shift + dra ut = fjern, Shift + dra på en annen knapp = flytt dit og ta tieren, `/control angre`. Sverd i siste tomme rute i kamp. 326/326 tester | Claude |
| 2026-10-04 | **Dra-ut med Shift** (avvik fra SPEC §8): knappene kaster på «ned» (V5), så et vanlig dra ville kastet eller drukket itemet. `shift-type1` = tom, så Shift + klikk gjør ingenting – som Blizzards egne låste actionbarer | Daniel + Claude |
| 2026-10-04 | Sidemenyene kan ikke åpnes eller lukkes i kamp (de inneholder sikre knapper); tooltipen sier «Ikke i kamp». Det som er åpent når kampen starter, står åpent | Claude |
| 2026-10-05 | **Fase 5 bygget:** gruppebuffene. `Scan.lua` leser partyet (navn, klasse, synlig, online, død) og buffene på hvert medlem når de ikke er hemmelige; ellers brukes det vi visste, telt ned. Knappen kaster på første som mangler (`unit=partyN`), eller gruppeversjonen. En rute per medlem i et bånd nederst på knappen: lys = har, tom med gul kant = mangler, dempet = ukjent. Tooltip med navn i klassefarge. Et bekreftet kast oppdaterer medlemmet (eller alle, for gruppeversjonen), også i kamp. 370/370 tester. Venter på test i spillet | Claude |
| 2026-10-05 | Gruppeversjonen krever at **spillet sier den kan kastes nå** (`C_Spell.IsSpellUsable`: lært, reagens, mana) i stedet for en reagensliste per buff. Treffer alle klasser uten at vi må kjenne reagensene | Claude |
| 2026-10-05 | Ukjent (ute av syne, offline, død) telles **ikke** som mangler. Ute av syne beholder det vi visste sist. I kamp er gruppeknappene dempet til 45 % – vi ser ikke hvem som har buffen før kastet er bekreftet | Claude |
| 2026-10-05 | Kjent begrensning til fase 7: klikker du en gruppeknapp ved medaljongen i kamp, skjules den av det sikre skriptet selv om flere fortsatt mangler. Den kommer tilbake etter kampen | Claude |
| 2026-10-05 | Etter første titt i spillet (Daniel): gruppesidens statuslinje er bare **«Party buffs»** – «Alle har det de skal» sto der selv uten gruppe. Prinsipp: det som ikke lyser eller blinker, er i orden; knappene forteller, ikke teksten | Daniel |
| 2026-10-05 | Sidemenyene har bare **én** tom rute («+») etter knappene (var: fylt opp til 5 plasser). Sida vokser én og én. Gjelder begge sider | Daniel |
| 2026-10-05 | **Scrolls på gruppesiden** (`partyitem`): brukes på den som mangler (`type=item`, `unit=partyN`), viser antall, grå når tom. Andre ting avvises med forklaring. 382/382 tester | Daniel + Claude |
| 2026-10-05 | Min side: statuslinja er bare **«Mine buffs»** (var «Mangler MotW · Flask» / «Status Alt med»). Begge sider har nå bare navnet sitt; glød, ruter og tall på knappene forteller resten | Daniel |
| 2026-10-05 | **Fase 6 bygget:** `UI/Menu.lua`. Nedre sone åpner menyen (ikke i kamp), under medaljongen eller over når den står i nedre halvdel av skjermen. Delene Mine buffs, Party buffs, Byvakt og Oppsett; fell sammen med klikk på kategorilinja (huskes). Slipp inn i rad I/II, Shift + dra mellom radene eller ut (fjern, `/control angre`), velg hvem en gruppebuff følges på ved å klikke navn (Q7), byvakt med «+ dette stedet» og klikk-for-å-fjerne, «Bytt sider». Byvakt fylles med fraksjonens hovedsteder ved første innlogging. 445/445 tester | Claude |
| 2026-10-05 | **Størrelse (Daniel):** slider i menyen, 70–150 %. Bare medaljongen vokser; knappene, sidemenyene og menyen flytter seg utover så sirkelen ikke dekker dem. Skaleringen i hjørnene (§7.9) er dermed ikke nødvendig – spør Daniel før fase 9 | Daniel |
| 2026-10-05 | Q7 besvart: hvem en gruppebuff følges på, velges ved å klikke navnene i menyen. Alle valgt = følges på alle (`onlyOn = nil`) | Claude |
| 2026-10-05 | Menyen etter første titt (Daniel): tynne, sentrerte skillestreker mellom delene. Byvakt: «Du er i …» + **«Legg til»**, og en lang knapp **«Voktes (n)»** som folder ut lista – dra et sted ut av lista for å fjerne det (`/control angre` gir det tilbake). Oppsett: bare én lang, midtstilt knapp **«Bytt side på gruppene»** (teksten blødde inn i knappen). Slideren hakket: menyen tegnes fire ganger i sekundet og satte slideren tilbake til lagret verdi mens du dro – nå står den der musa er. 451/451 tester | Daniel + Claude |
| 2026-10-05 | **Kort tekst på medaljongen (Daniel):** «Lås»/«Lås opp» (uendret), midten «Dra» (låst: «Låst»), venstre/høyre «Party» og «Meg», nede «Åpne meny»/«Lukke meny» (uten tallet). Sidene heter «Meg» og «Party» overalt (statuslinja og menyen). Prinsipp: presis og enkel tekst | Daniel |
| 2026-10-05 | Menyen: bolkene skilles bare av kategorilinja; tynne streker bare **inne i** en bolk (nå mellom «Bytt side på gruppene» og «Størrelse»). «Voktes (n)» og «Bytt side på gruppene» er like brede – bredden kommer fra teksten «Bytt side på gruppene» – og midtstilt; lista med steder har samme bredde | Daniel |
| 2026-10-05 | **Tekstrunde (Daniel: «ta hele lista»):** kortere tekster i tooltip, menyen og chatten – f.eks. «Klikk: kast», «0 av 10», «Hjul: antall (Shift = 5)», «Shift + dra: flytt eller fjern», «Flask fjernet (/control angre).», «MotW: bare Brakk.», «Tilbakestilt.». Lagerlinja («Lagervare: …») og «Ingen å kaste på» er fjernet; fem ubrukte tekster slettet. `Locale/nbNO.lua` er fasiten for tekstene – SPEC §14 er den opprinnelige planen | Daniel |
| 2026-10-05 | Menyen: lik luft (10 px) mellom alt – elementer, rader, kategorilinjer, og over og under tynne streker. Symbolene i medaljongen så «shabby» ut skalert opp: spillet glatter ikke streker, så tykkelsen rundes nå til hele skjermpiksler for hver størrelse (også når spillets UI-skala endres), og knekkpunktene har en liten rund prikk i stedet for hakk | Daniel + Claude |
| 2026-10-05 | **Fase 8 bygget (byvakt):** `CityWatch.lua` + `UI/Alert.lua` + `Rules.departure`. Varsel når du går fra et sted som voktes til et som ikke gjør det (sonebytte, også etter lasteskjerm), eller åpner flykartet der. Aldri to ganger for samme avreise – neste varsel først etter du har vært tilbake på et vaktet sted. Én linje midt på skjermen med det som mangler (alle mine oppføringer, verst først): rød + én lyd (raid warning) når noe er tomt eller mangler i tier I, oransje uten lyd, kort grønn «Alt med». Over: «Du forlater …» i grått. I kamp: vises når kampen er over. Tomt sonenavn ved lasteskjerm ignoreres (V8). `/control varsel` viser varselet når som helst. 492/492 tester | Claude |
| 2026-10-05 | **Nivå 2 (nedtelling midt på skjermen, Q4) er ikke bygget.** SPEC sier «bygg det sist, bak en innstilling», og tier I-knappen viser allerede stor nedtelling ved medaljongen. Spør Daniel | Claude |
| 2026-10-05 | **Q4 avgjort (Daniel): ja, varsel 40 s før en buff går ut.** `UI/Expiry.lua` + `Rules.expiring`: et lite ikon (36 px, oransje kant) med nedtelling over figuren, midt på skjermen, for alle mine buffer som var på (begge tier), kortest først, maks 4. Ingen lyd, ingen mus. Borte når du fornyer eller buffen er gått ut. Vises også i kamp, fra estimatet. Ingen innstilling – Daniel vil ha det. 505/505 tester | Daniel |
| 2026-10-05 | Tallet i medaljongen: «1» så skjevt ut (Daniel). Boksen stod i midten, men i Friz Quadrata står streken i «1» ca. 2 px til høyre for midten (flagg til venstre, bred fot). Optisk korreksjon: «1» flyttes 1,5 px til venstre, tall som begynner på 1 flyttes 1 px | Daniel + Claude |
| 2026-10-05 | Byvakt testet av Daniel (porten og flight master): virker. Endret: **byvakta sjekker bare lageret** (ting og buffting, begge tier) – spells kan kastes hvor som helst, og om flasken er på akkurat nå, er ikke poenget. Rødt + lyd = tomt i tier I | Daniel |
| 2026-10-05 | Byvakt varsler **når samtalen med flight masteren åpnes**, før «I need a ride» (`GOSSIP_SHOW` med flyvalg: type «taxi», ikon 132057 eller teksten «I need a ride» / «Show me where I can fly»). Samtalen lagres i `ControlCharDB.debug.gossip` i tilfelle Forever er annerledes. Flykart uten samtale varsles som før | Daniel |
