# Control – spesifikasjon

Versjon 1.1 · 3. oktober 2026 · eier: Daniel (1.1: navnet Control, svar på Q1–Q3 og Q9, testverktøy, flytting av gamle data)
Grunnlag: designbrief (2. okt. 2026) og designcanvas versjon 18 (interaktiv prototype).

> **For Claude Code.** Denne fila er gjeldende sannhet for hva som skal bygges. `HISTORIKK.md` forklarer hvordan vi kom hit og hvilke ideer som er forkastet. Er noe uklart eller i konflikt, gjelder denne fila. Spørsmål merket **ÅPENT** (§15) skal du spørre Daniel om; inntil han har svart, bruker du standardvalget i §15-tabellen. Testscenarioet i §19 forutsetter disse standardene. Referanser (prototype, skjermbilder, original brief) ligger i `docs/referanse/`.

---

## 0. Kort fortalt

Control er én addon for **World of Warcraft: Forever** som viser hva du mangler av buffer og ting, og lar deg fikse det med ett klikk.

- En rund **medaljong** (64 px) står alene på skjermen. Tallet i midten sier hvor mange ting som trenger oppmerksomhet, og ringen lyser **rødt**, **oransje** eller ikke i det hele tatt.
- Mangler en **tier I**-buff (eller den går snart ut), dukker en **knapp** opp ved siden av medaljongen. Trykk, så er buffen på, og knappen forsvinner.
- **Sidemenyene** (venstre og høyre del av ringen) folder ut oversikten: alt som mangler helt eller delvis, timere og lager. De vises bare når du åpner dem.
- Den ene siden er **mine buffer og ting (MB)**, den andre er **buffer jeg kan gi gruppa (PB)**. Sidene kan byttes.
- **Menyen** (nederste del av ringen) har innstillinger: tier-rader, hvem i gruppa som følges, Byvakt og retning.
- **Byvakt** sier fra når du forlater en by og noe mangler.

---

## 1. Hva og hvorfor

**Problem:** Du drar ut av byen og har glemt flask, mat eller bandasjer, eller en buff går ut uten at du merker det. I gruppe vet du ikke hvem som mangler buffen du kan gi.

**Bruk (viktigst først):**

1. Ute og quester med en kompis. Mye tid utenfor kamp, så addonen ser nesten alt hele tiden.
2. Dungeon i party. Mye tid mellom pulls, så den er fortsatt nyttig.
3. Før du forlater byen (Byvakt).

**For hvem:** alle spillere, alle klasser, realmer og fraksjoner. Ingenting er laget for én karakter. Druid-eksemplene i prototypen er bare eksempler.

**Designprinsipper:**

- **Presis.** Én ting å se, med tallet bak. Ingen pynt som ikke bærer informasjon.
- **Enkel, men veldig effektiv.** Alt gjøres med musa direkte på knappene: dra inn = ny, dra ut = slett, høyreklikk = bytt tier, musehjul = antall.
- **Diskret.** Stille status hele tiden. Lyd og tekst midt på skjermen bare når det betyr noe.
- **Knappen står alene.** Bare det du kan og bør trykke på nå, står ute. Oversikt får du når du ber om den.
- **Ser ut som spillet.** Skal se ut som en del av spillets eget UI (portrett-medaljonger, bronserammer, gule kategorilinjer).

---

## 2. Spillet: WoW Forever og hva det betyr

Fakta (kilder i §20, sjekket 3. okt. 2026):

- *World of Warcraft: Forever* er Blizzards «Classic+»: Azeroth fra første år (før Molten Core), nivå 60, med nye soner, quester, dungeons og raids. Lansering **4. november 2026**. Beta fra 17. september 2026 (nivå 30-tak, krever Epic-pakke).
- Forever **deler UI-arkitekturen med Mainline** og har «de aller fleste API-ene fra 12.1.5».
- Forever får **de samme addon-begrensningene som Midnight** («secret values»), og de holdes i takt med retail-patcher (12.1, 12.2 …).

Konsekvenser for Control (detaljer i §12):

- Buffer kan være **hemmelige** for addons i kamp, i encounter/dungeon-kart og PvP. Vi leser utenfor kamp og teller ned selv.
- **Beskyttede knapper** (som kaster spells eller bruker items) kan ikke vises, skjules, flyttes eller få nytt mål i kamp. Det som står ute når kampen starter, står fast til kampen er over.
- Addons kan **aldri kaste for deg**. Hver handling er ett klikk fra spilleren på en sikker knapp.

**Må verifiseres i spillet før bygging av det som avhenger av det** (se fase 0 i §18):

| # | Hva | Hvorfor |
|---|-----|---------|
| V1 | Interface-nummer for TOC (`/dump select(4, GetBuildInfo())`) og navnet på AddOns-mappa for Forever. Kjent fra før (2. okt.): betaen ligger i `_classic_beta_`, interface 16001, build 70170; kan endre seg ved lansering | TOC og installasjon |
| V2 | Kan vi lese egne buffer (navn, spellId, `expirationTime`) utenfor kamp? Er de hemmelige i kamp? | Hele regelmotoren |
| V3 | Kan vi lese party-medlemmers buffer utenfor kamp? | Gruppebuffer (PB) |
| V4 | Gir `UNIT_SPELLCAST_SUCCEEDED` for `player` spellId i kamp, eller bare at noe ble kastet? | Registrere trykk i kamp |
| V5 | Fungerer `SecureActionButtonTemplate` med `type=spell`, `unit=partyN` og `type=item` som forventet? Trengs `AnyDown`? | Knappene |
| V6 | `C_Item.GetItemCount` i dungeons (kan være begrenset på «restricted maps») | Lager |
| V7 | Har spellene ranks (ulike spellId per rank)? Hvordan heter auraen fra mat («Well Fed»)? | Gjenkjenning |
| V8 | Hendelser for flykart (`TAXIMAP_OPENED`), sonebytte, båt/portal, og om det finnes kø-popup | Byvakt |
| V9 | Er `UnitName`/`UnitGUID` for party hemmelige i kamp? | PB i kamp |

---

## 3. Begreper og ordliste

UI-tekst er norsk bokmål. Kode, filnavn og identifikatorer er engelske. Bruk denne tabellen konsekvent.

| Norsk (UI og samtale) | Kode | Betyr |
|---|---|---|
| Control | `Control` | Addonen |
| knappen, medaljongen | `Medallion` | Den runde 64 px-knappen |
| ringen | `StatusRing` | Fargeringen i medaljongen (rød/oransje/ingen) |
| sonene | `Zone` (`up`/`down`/`left`/`right`) | De fire kilene i ringen |
| midten, grepet | `Hub` | 22 px-sirkelen i midten (flytte/låst) |
| ved knappen, pop-out | `Tray` | Knappene som står ute ved siden av medaljongen |
| sidemeny, side | `SideBar` | Oversikten som foldes ut til venstre/høyre |
| menyen | `Menu` | Panelet som åpnes nedover (eller oppover) |
| knapp (buff/ting) | `EntryButton` | 40 px-knapp for én oppføring |
| oppføring | `Entry` | Én ting på lista (spell, buffting, lagerting, gruppebuff) |
| mine buffer og ting (MB) | `self` / `SelfList` | Det du gir deg selv eller bruker selv |
| til gruppa (PB) | `party` / `PartyList` | Buffer du kan gi andre i gruppa |
| tier I / tier II | `tier = 1 / 2` | Hvor oppføringen vises (§6.4) |
| buff, buffer | `aura` | Spells, eliksirer, flasks og mat som gir en buff |
| ting | `item` | Items du vil ha med, med antall |
| lager, har/vil ha | `count` / `want` | Antall i baggen / ønsket antall |
| ikke på | `missing` | Buffen er ikke på |
| gått ut | `expired` | Buffen var på og har gått ut |
| snart ute | `expiring` | 40 s eller mindre igjen |
| tom | `empty` | 0 i baggen |
| under | `low` | Færre enn ønsket, men ikke 0 |
| Byvakt | `CityWatch` | Varsel når du forlater en vaktet by |
| Alt med | – | Grønn bekreftelse |

---

## 4. Hvordan alt henger sammen

```
                       [lås]
          PB-side        ▲         MB-side
   ┌──────────────┐  ╭───────╮  ┌──────────────────────┐
   │ (Tray) ◆ ◆   │◀─│   7   │─▶│ ◆ ◆   (Tray)          │   ◆ = 40 px-knapp som står ute
   └──────────────┘  ╰───────╯  └──────────────────────┘
      venstre sone       ▼         høyre sone
                      [meny]

  Venstre sone = fold ut/inn den ene sidemenyen.  Høyre sone = den andre.
  Opp = lås/lås opp.  Ned = meny.  Midten = dra for å flytte (når ulåst).
```

**Dataflyt:**

```
 Spillhendelser ─▶ Lesing (auraer, bagger, gruppe) ─▶ Tilstand per oppføring
   (UNIT_AURA,         bare utenfor kamp,                 (på/snart/ute/ikke på,
    BAG_UPDATE…,        ellers estimat)                    antall, hvem mangler)
    REGEN…)                                                       │
                                                                  ▼
                                                 Regelmotor (rene funksjoner, §6)
                                     alvorlighet · kan trykkes · tall · ringfarge · statuslinje
                                                                  │
                                       ┌──────────────────────────┼──────────────────────┐
                                       ▼                          ▼                      ▼
                                  Medaljong                Tray + sidemenyer           Varsler
                             (tall, ring, soner)      (knapper, tooltips, rekkefølge)  (Byvakt, nivå 2)
```

**Viktig skille:** Regelmotoren er ren Lua uten WoW-kall (testbar utenfor spillet). Lesing og UI er WoW-avhengig. Layout som rører beskyttede knapper skjer bare utenfor kamp.

---

## 5. Datamodell

### 5.1 Typer oppføringer

| Type | Kode | Eksempel | Har buff-del | Har lager-del | Kan trykkes |
|---|---|---|---|---|---|
| Spell på deg selv | `spell` | Mark of the Wild, Thorns | ja | nei | ja, kaster på deg selv |
| Buffting | `buffitem` | Flask of the Titans, Elixir of the Mongoose, mat | ja | ja | ja, bruker itemet |
| Lagerting | `item` | Runecloth Bandage, Major Mana Potion | nei | ja | nei (vises bare) |
| Gruppebuff | `partyspell` | Mark of the Wild til gruppa, Thorns på tanken | ja, per medlem | nei | ja, kaster på neste som mangler |

En oppføring kan altså ha **to deler** (buff og lager) som slås sammen til ett varsel (§6.2).

### 5.2 Lagret (SavedVariablesPerCharacter: `ControlCharDB`)

Alt lagres per karakter (spells og ting er forskjellige per klasse).

```lua
ControlCharDB = {
  schema = 1,
  self = {                       -- MB, i rekkefølge
    { id = "e1", type = "spell",    spellId = 1126, short = "MotW", auraNames = {"Mark of the Wild", "Gift of the Wild"}, tier = 1 },
    { id = "e2", type = "buffitem", itemId = 13510, auraNames = {"Flask of the Titans"}, tier = 1, want = 2 },
    { id = "e3", type = "buffitem", itemId = 20452, auraNames = {"Well Fed"}, tier = 2, want = 10 },
    { id = "e4", type = "item",     itemId = 14529, tier = 2, want = 10 },
  },                             -- (ID-ene er eksempler fra Classic; verifiser i Forever)
  party = {                      -- PB, i rekkefølge
    { id = "p1", type = "partyspell", spellId = 1126, auraNames = {"Mark of the Wild", "Gift of the Wild"}, tier = 1, onlyOn = nil },
    { id = "p2", type = "partyspell", spellId = 467,  auraNames = {"Thorns"}, tier = 2, onlyOn = { ["Brakk-Realm"] = true } },
  },
  ui = {
    point = { "CENTER", "UIParent", "CENTER", 0, 200 },  -- medaljongens midtpunkt
    scale = 1.0,                 -- 0.70–1.50 i steg på 0.05
    locked = false,
    partySide = "left",          -- "left" | "right"; MB er alltid motsatt side
    menuSections = { self = true, party = true, city = true },  -- åpne/lukkede deler i menyen
  },
  durations = { [1126] = 1800 }, -- sist sette full varighet per aura (for estimat i kamp)
  cityWatch = { cities = { "Stormwind City", "Ironforge", "Darnassus" } },
  undo = nil,                    -- sist fjernede oppføring (for /control angre)
}
```

- `auraNames`: buffer som teller som «på». Fyll ut fra spellets eget navn, pluss kjente likeverdige (se §9.5). Navn heller enn spellId, fordi ranks kan gi ulike spellId (V7).
- `short`: kortnavn i statuslinja (§6.6), f.eks. «MotW», «Flask», «Defense», «Bandage». Standard: fra en tabell over kjente forkortelser, ellers det fulle navnet. Kan endres senere (ikke i v1-UI).
- `want`: bare for `buffitem` og `item`. Standard ved innlegging: antallet du har nå, minst 1.
- `onlyOn`: bare for `partyspell`. `nil` = følg alle i gruppa. Ellers et sett med spillernavn.
- Nye oppføringer legges **sist i tier II**.

### 5.3 Kjøretid (ikke lagret)

```lua
state = {
  inCombat = false,
  entries = {
    e1 = { status = "missing", expires = nil, count = nil },   -- status: on | expiring | expired | missing
    e2 = { status = "on", expires = 123456.7, count = 3 },
    p1 = { missingOn = { "Brakk", "Vesla" }, nextTarget = "party1" },
  },
  pending = { entryId = "e1", clickedAt = 1234.5 },  -- trykk som venter på bekreftelse (§12.4)
}
```

- `status` regnes utenfor kamp fra auraene. `expired` skilles fra `missing` ved at vi så buffen tidligere i økten.
- I kamp er `expires` et **estimat** fra sist kjente verdi eller fra `durations` etter et registrert trykk.

---

## 6. Regler (kjernen)

Disse reglene er implementert i prototypen (`docs/referanse/prototype/prototype-logikk.js`, funksjonene `buffSev`, `stockSev`, `sev`, `kanTrykkes`, `bygg`). Skriv dem som rene funksjoner i `Rules.lua` med enhetstester (§19).

### 6.1 Terskler

- **Snart ute:** 40 s eller mindre igjen (`EXPIRING_SECONDS = 40`). Se **ÅPENT Q3**.
- **Lager:** `count == 0` er tomt. `0 < count < want` er under. `count >= want` er nok.

### 6.2 Alvorlighet (0 = ok, 1 = oransje, 2 = rød)

```lua
-- buff-delen
function Rules.buffSeverity(e, st)
  if e.type == "item" then return 0 end
  if st.status == "missing" or st.status == "expired" then return 2 end   -- se ÅPENT Q1 for buffitem
  if st.status == "expiring" then return 1 end
  return 0
end

-- lager-delen
function Rules.stockSeverity(e, st)
  if e.type ~= "item" and e.type ~= "buffitem" then return 0 end
  if st.count <= 0 then return 2 end
  if st.count < e.want then return 1 end
  return 0
end

function Rules.severity(e, st)
  return math.max(Rules.buffSeverity(e, st), Rules.stockSeverity(e, st))
end
```

Dette gir disse avgjorte reglene:

| Situasjon | Farge |
|---|---|
| En buff du kan gi deg selv (spell) mangler eller har gått ut | **Rød.** «Ingen unnskyldning.» |
| En ting på lista er tom (0) | **Rød** |
| Lager under ønsket (f.eks. 1/6, 3/4) | **Oransje** |
| En buff går snart ut | **Oransje** |
| Alt ok | Ingen farge |
| Én oppføring med både buff- og lager-del | Den verste av de to |
| Gruppebuff som mangler på minst én som følges | **Rød** |

> **AVGJORT Q1 (3. okt.): rød, som prototypen.** Opprinnelig spørsmål: Prototypen gir **rødt** når en buffting (eliksir, flask, mat) ikke er på, selv om lageret er fullt. Daniel har sagt at rødt er for spells du kan gi deg selv og for ting som er tomme, og ga «4/5 defense potion» som eksempel på oransje. Bekreft om buffting som ikke er på skal være rød (som nå) eller bare styres av lageret (oransje/rød) mens knappen fortsatt dukker opp. Standard inntil svar: rød, som prototypen.

### 6.3 Kan trykkes

```lua
function Rules.canPress(e, st)
  if e.type == "spell"      then return Rules.buffSeverity(e, st) > 0 end
  if e.type == "buffitem"   then return Rules.buffSeverity(e, st) > 0 and st.count > 0 end
  if e.type == "item"       then return false end
  if e.type == "partyspell" then return #st.missingOn > 0 end
end
```

### 6.4 Tier: hvor en oppføring vises

Tier bestemmer **bare hvor** en oppføring vises, aldri fargen.

| Tier | Ved knappen (Tray) | I sidemenyen | I menyen |
|---|---|---|---|
| **I** | Ja, **bare når den kan trykkes** (mangler, gått ut eller snart ute, og for buffting: har minst 1) | Alltid | Alltid, rad I |
| **II** | Aldri | Alltid | Alltid, rad II |

- Trykker du på en knapp ved knappen og buffen kommer på, er den ikke lenger trykkbar og **forsvinner** (animasjon §7.10).
- Gruppebuff i tier I står ute til **alle** som følges har den. Hvert trykk kaster på neste som mangler.
- Står ingen knapper ute, står medaljongen **alene**.
- Lagerting (`item`) står aldri ute, uansett tier.

### 6.5 Tallet og ringen

```lua
count = antall MB-oppføringer med severity > 0          -- alle tier
      + antall PB-oppføringer der minst én som følges mangler
ring  = verste severity over alt (PB som mangler teller som 2)
```

- Tallet teller **alt som mangler helt eller delvis**, altså det samme som sidemenyene viser i statuslinja. Står knappen alene med et tall, er det et tegn på å åpne sidene. Se **ÅPENT Q2**.
- `count == 0`: dempet hake i stedet for tall, ingen ringfarge.
- Ingen oppføringer i det hele tatt (tom tilstand): dempet hake, ingen farge, intet tall. Sidemenyen viser én tom slipprute med «Dra en spell eller en ting fra baggen hit» ved siden av, og statuslinja «Status –» (se «Tomt» i `tavle-samhandling.png`).
- Ringfarge: 2 → rød `#FF2020` med svak glød; 1 → oransje `#FF8C1A` med svak glød; 0 → svart (ingen lys).

### 6.6 Statuslinja i sidemenyen

Under knappe-raden i hver sidemeny står én linje:

- **MB-side:** etikett «Mangler» (eller «Status» når alt er ok). Deretter oppføringene med severity > 0, verste først (**stabil** sortering: like alvorlige beholder listerekkefølgen; Luas `table.sort` er ikke stabil, så sorter på `(−severity, indeks)`), maks 4, så «+N». Hver: kortnavn farget etter buff-delen (rød/oransje/lys), og lagertall «har/vil ha» farget etter lager-delen hvis lageret er under. Alt ok: grønt «Alt med».
  Eksempel: `Mangler  MotW · Flask · Defense 4/5 · Bandage 0/10 · +1`
- **PB-side:** etikett «Mangler» (eller «Gruppa»). Per gruppebuff: «Kortnavn: navn, navn» (navnene lyse, kortnavn grått). Alt ok: grønt «Alle har det de skal».
  Eksempel: `MotW: Brakk, Vesla · Thorns: Brakk`
- Linja kuttes med «…» hvis den blir for lang.

### 6.7 Rekkefølge

- I sidemenyen og menyen: tier I først, så en fure (skillelinje), så tier II. Innenfor hver tier: brukerens rekkefølge.
- Ved knappen: tier I-knappene som kan trykkes, i brukerens rekkefølge, innerst først (nærmest medaljongen).

### 6.8 I kamp

- Ingen knapper dukker opp eller forsvinner, ingen layout endres (beskyttede knapper, §12.1). Det som stod ute, står fast.
- Knappene kan fortsatt trykkes. Trykket registreres (§12.4), og nedtellingen starter fra full varighet. **Ett venstreklikk i kamp skjuler knappen og lukker rekka med en gang** (Daniel 4. okt): et sikkert skript (`SecureHandlerWrapScript` på knappen, rammen er `SecureHandlerBaseTemplate`) kjører etter klikket. Skriptet ser ikke om kastet lyktes; feiler det, står det fortsatt i tallet, og knappen kommer tilbake når kampen er over.
- Ingen nye lys eller tekster midt på skjermen. Tall og ringfarge kan oppdateres fra estimater.
- Gruppebuff-rutene vises dempet (45 % opasitet) fordi vi ikke kan se hvem som har buffen.
- Når kampen er over (`PLAYER_REGEN_ENABLED`): les alt på nytt, legg ut knappene på nytt.

---

## 7. Brukerflaten

Alle mål gjelder skala 100 %. Se skjermbildene i `docs/referanse/skjermbilder/`.

### 7.1 Medaljongen (64 px)

Lagvis fra utsiden (se `01-hvile.png`):

1. **Bronsering**, 4 px: gradient lys `#F0CF86` øverst til venstre → `#B58A40` → mørk `#6A4A1C` → `#A07A38` nederst til høyre. 1 px svart kant utenfor og svak lys innerkant. Skygge under.
2. 1 px **svart**.
3. **Statusring**, 2 px: rød/oransje/svart etter §6.5, med svak glød (rød: 10 px, 70 %; oransje: 10 px, 65 %). Fargeskifte tones over 0,3 s.
4. **Kjerne**: mørk radial `#3B2F22` → `#17110C` → `#0B0806`, innfelt skygge.
5. **Innhold i kjernen** (hvile): tallet (overskriftsskrift, 25 px, gull `#FFD100`, svart kontur), eller en dempet hake (60 % opasitet) når alt er ok.

**Mus over en av de fire sonene:** medaljongen vokser 6 %, bronsen lyser opp (lysstyrke 115 %). Tallet tones ut (skaleres til 70 %), og fire symboler (13 px) tones inn i kjernen:

| Plass | Symbol | Betyr |
|---|---|---|
| Oppe | Hengelås (åpen når ulåst, lukket når låst) | Lås / lås opp |
| Nede | Tre streker (≡) | Menyen |
| Venstre / høyre | Ett hode = mine (MB), to hoder = gruppa (PB) | Fold ut den siden |

Symbolet for sonen musa står i blir lyst (`#FFF3B0`) og 25 % større. De andre står i gull `#C9A24A` med 45 % opasitet. En myk lysbue langs ringen og en liten lysprikk på kanten peker mot sonen (roterer 0/90/180/−90°, 0,25 s).

**Mus i midten:** tallet og de fire symbolene skjules, ingen lysbue eller prikk. I stedet vises flyttekrysset (ulåst) eller hengelåsen (låst), se §7.2.

### 7.2 Sonene og midten

Medaljongen deles i fire kiler fra midten ut mot hjørnene (opp, høyre, ned, venstre), pluss en sirkel på **22 px** i midten.

| Område | Klikk | Mus over |
|---|---|---|
| Opp | Lås / lås opp | Hengelås lyser |
| Ned | Åpne/lukke menyen | ≡ lyser |
| Venstre | Fold ut/inn sidemenyen på venstre side | Siden sitt symbol lyser |
| Høyre | Fold ut/inn sidemenyen på høyre side | Siden sitt symbol lyser |
| Midten, ulåst | **Dra for å flytte** hele addonen | Flyttekryss (18 px, `#FFF3B0`) i en stiplet sirkel, markør «grab» |
| Midten, låst | Ingenting | **Hengelås** (16 px, `#FFF3B0`) i midten |

- Låst: flytting og skalering er slått av. Ingen annen visuell endring i hvile (bevisst: «det holder at symbolet i midten er en lås»).
- Implementasjonstips: én ramme over medaljongen som regner ut sone fra vinkel og avstand til midten (`r < 11 px` = midten), i stedet for fire trekantede rammer.

### 7.3 Ved knappen (Tray)

- Én tray per side. Den har bare tier I-knapper som kan trykkes (§6.4). Tom tray vises ikke.
- **Endret 4. okt (Daniel): rammen starter i medaljongens midtpunkt**, så hjørnene aldri titter fram bak sirkelen. Første knapp står fortsatt 6 px utenfor medaljongen (2 px kant + 36 px luft). Opprinnelig tekst:
- Ramme: samme ramme som sidemenyen (§13), 56 px høy med kant (2 + 6 + 40 + 6 + 2). Rammen starter **under** medaljongen: kanten på medaljongsiden ligger 18 px fra medaljongens *motsatte* kant (for høyre side: rammens venstre kant = medaljongens venstre kant + 18 px), så rammen stikker 46 px inn under medaljongen. Toppen ligger 4 px under medaljongens topp. Med 2 px kant og 50 px luft på medaljongsiden står første knapp 6 px utenfor medaljongens kant. Knappene står med 6 px mellomrom og vokser utover.
- Nye knapper spretter inn (skala 0,55 → 1, 0,28 s, litt overshoot). Knapper som blir borte, krymper og tones ut (0,17 s).

### 7.4 Sidemenyene (SideBar)

Folder ut fra medaljongen når du klikker venstre eller høyre sone (`04-begge-sider-apne.png`).

- Samme forankring som trayen (§7.3), og dekker trayen på den siden mens den er åpen.
- **Rad 1, knapper:** alle tier I, så en fure (2 px: 1 px svart + 1 px `#4A3920`, 2 px marg), så alle tier II, så tomme ruter. Tomme ruter fyller opp til minst 5 plasser, alltid minst én (unntak: tom tilstand, §6.5). Første tomme rute har et «+» og er slippmål for nye oppføringer. I kamp viser siste tomme rute to kryssede sverd (frosset).
- **Fure** (2 px) under raden.
- **Rad 2, statuslinja** (30 px): §6.6.
- **Bredde:** gitt av innholdet: `40 + (knapper + tomme ruter) × 46 + (12 hvis både tier I og II finnes)` px (rammen starter i medaljongens midtpunkt, se §7.3; var 54 da den startet 18 px fra kanten) (fura er 2 px + 2 × 2 px marg + ett ekstra mellomrom). Prototypen bruker +10, som er 2 px for lite.
- Åpne/lukke: klippes inn/ut fra medaljongsiden, 0,35 s, med opasitet 0,2 s.
- Begge sider kan være åpne samtidig. Sidene er uavhengige av menyen.
- Venstre side vokser mot venstre (knappene speilvendt, innerst nærmest medaljongen).

### 7.5 Knappen (EntryButton, 40 px)

I spillet brukes ekte ikoner og spillets knapperamme. Prototypen bruker tegnede plassholdere. Komponenten er `docs/referanse/prototype/BuffKnapp.dc.html` (`buffknapp-logikk.js`). Se `tavle-tilstander.png`, raden «Knapper: hvor i prosessen».

Prosessen vises med form og bevegelse, ikke bare farge:

| Tilstand | Slik ser den ut |
|---|---|
| **På** (`aktiv`) | Liten tid nederst (12 px fet, svart kontur), f.eks. «6 min». En mørk **tømming ovenfra** (`rgba(8,6,4,.66)` med 1 px lys kant) viser hvor mye av tiden som er brukt. |
| **Snart ute** (`snart`, ≤ 40 s) | **Stor nedtelling** midt på (16 px fet), f.eks. «0:38». Tømmingen står nesten helt nede. Ingen glød (nedtellingen er signalet). |
| **Gått ut** (`gatt`) | **Pulserende gullglød**, ingen tekst (Daniel 4. okt: uten «gått ut»). |
| **Ikke på** (`ikke`) | **Pulserende gullglød**, ingen tekst (Daniel 4. okt: uten «ikke på»). Dette er tilstanden som skal stikke seg mest ut. |
| **Lager på buffting** | Antall øverst til høyre (12 px fet). Nok: bare tallet («3»). Under: «har/vil ha» («3/4»). Tomt: «0/2» i grått `#A0A0A0`, og ikonet i gråtoner og mørkere. |
| **Lagerting** (`item`) | Antallet står nederst der tiden ellers står («5», «3/6»). Tømmingen ovenfra viser hvor mye som mangler opp til ønsket antall. Tomt: mørkt bånd med «0/10» og ikonet i gråtoner. **Lyser aldri.** |
| **Gruppebuff** | Én rute (5 px) per medlem som følges, i et 11 px-bånd nederst. Fylt lys rute = har buffen; tom rute med gul kant = mangler. Ikonet flyttes litt opp. Gløder når noen mangler. Dempet til 45 % i kamp. |
| **Mus over** | Tynn lys innerkant (`rgba(255,236,170,.75)`) og 12 % lysere. |
| **Trykket** | Skala 0,93 og et gyllent lysglimt fra midten (~0,17 s). |

- **Glød** = pulserende gull (2,4 s syklus): 2 px innerkant `#FFE98A`→`#FFF6C8` og ytre glød opptil 14 px. Vises når buffen er **ikke på** eller **gått ut** og oppføringen kan trykkes (§6.3), og på gruppeknapper når noen mangler. Ikke for «snart ute», aldri for lagerting. Respekter innstillinger for redusert bevegelse hvis spillet har det.
- Tidsformat: under 1 min: «0:SS»; under 100 min: «N min» (rundet opp, «98 min» får plass); fra 100 min: «N t» (rundet opp, som spillets egne buff-tider). Teksten må aldri bryte over to linjer (sett `SetWordWrap(false)`). Bekreft med Daniel hvis det ser rart ut i spillet.

### 7.6 Menyen

Åpnes med nedre sone (`05-sider-og-meny-apne.png`). 340 px bred, sentrert under medaljongen (venstre kant 138 px til venstre for medaljongens venstre kant). Toppen 72 px under medaljongens topp (100 px når en sidemeny er åpen, så den ikke dekker statuslinja). Glir og klippes ned på 0,3 s.

**Retning:** står medaljongen i nedre halvdel av skjermen, åpner menyen **oppover** (bunnen 8 px over medaljongen) og glir opp.

Innhold, ovenfra. Hver del har en kategorilinje i Reputation-stil (24 px, klikk = fell sammen, «−»/«+» til høyre):

1. **Mine buffer og ting** (ikon: ett hode; til høyre: «høyre»/«venstre», hvilken side den står på)
   - Rad **I** og rad **II**: tier-tall (overskriftsskrift, gull, 22 px bred kolonne med fure til høyre) og knappene, som brytes over flere linjer ved behov.
   - Tom rad: en tom rute + «Dra en buff eller ting hit».
2. **Til gruppa** (ikon: to hoder; side)
   - «Følger med på: Brakk · Lirael · Tosk · Vesla» i klassefarger.
   - Rad I og II som over. En gruppebuff som bare følges på noen, får «bare Brakk» i grått ved siden av.
   - Tom rad: «Dra en buff du kan gi hit».
3. **Byvakt** (ikon: skjold)
   - Byene som vaktes: «Stormwind · Ironforge · Darnassus».
   - «Du er i Stormwind» + knappen «+ dette stedet» (grå/deaktivert når stedet alt er vaktet).
4. **Retning** (ikon: to piler, ikke sammenleggbar)
   - «Gruppa til venstre · mine til høyre» + knappen «Bytt sider».

Knappene i menyen oppfører seg som overalt ellers (klikk, høyreklikk, hjul, dra).

### 7.7 Tooltip

Spillets egen tooltip-stil (`GameTooltip` er greit). Innhold (`06-tooltip-gruppebuff.png`, `07-tooltip-min-buff.png`):

| Linje | Spell (MB) | Buffting | Lagerting | Gruppebuff |
|---|---|---|---|---|
| Tittel (hvit) | Navn | Navn på buffen | Navn | Navn |
| Status (hvit) | «Ikke på» / «Gått ut» / «6 min igjen» / «0:38 igjen, snart ute» | som spell + « · 3 av 2 i baggen» | «Har 0 av 10» | «2 av 4 mangler» / «Alle har den» |
| Medlemmer | – | – | – | Én linje per medlem: navn i klassefarge (+ «(tank)» hvis rolle), «har» grått / «mangler» rødt |
| Handling | grønn «Klikk for å kaste på deg selv» | grønn «Klikk for å bruke (Smoked Desert Dumplings)» / grå «Ingen i baggen» | grå «Lagervare: tom / under ønsket / nok» | grønn «Klikk: kast på Brakk» / grå «Ingen å kaste på» |
| Hjelp (grå) | – | «Musehjul: ønsket antall (Shift = 5)» | samme | «I kamp: kaster på den som manglet før kampen» eller «Følges bare på Brakk» |
| Hjelp (grå) | «Høyreklikk: bytt tier (nå I)» | samme | samme | samme |

I menyen kommer i tillegg tier-forklaringen: «Tier I: dukker opp ved knappen når den mangler» / «Tier II: bare i sidemenyen».

### 7.8 Plassering, klemming og retning

- Hele addonen (medaljong, tray, sidemenyer, meny) flyttes som én enhet ved å dra i midten.
- **Holdes innenfor skjermen** som `SetClampedToScreen`, men regnet med **begge sidemenyene fullt utfoldet og menyen**, så ingenting kan havne utenfor kanten når du åpner noe. Medaljongen hopper aldri når du åpner en side; grensene gjelder der du kan plassere den.
- Står knappen langt til én side på skjermen, er det brukerens valg å bytte sider i menyen (Retning › Bytt sider). Symbolene i medaljongen følger med.
- Posisjon, skala, lås og side lagres per karakter.

### 7.9 Skala

- 70–150 % i steg på 5 %. Hele addonen skaleres rundt medaljongens midtpunkt.
- Når ulåst: hold musa over et ytterhjørne av trayen/sidemenyen, så vises en tynn gullvinkel og markøren endres. Dra for å skalere. Motsatt side står stille. (Se `tavle-samhandling.png`, «Låse og skalere».) Se **ÅPENT Q5** om plasseringen.
- Låst: ingen skalering.

### 7.10 Animasjoner (oppsummert)

| Hva | Tid |
|---|---|
| Medaljong mus over (vokse 6 %) | 0,15 s |
| Symboler inn/ut, tall ut | 0,15 s |
| Lysbue/prikk roterer | 0,25 s |
| Ringfarge skifter | 0,3 s |
| Sidemeny ut/inn | 0,35 s |
| Meny ned/opp | 0,3 s |
| Knapp spretter inn | 0,28 s |
| Knapp trykket (glimt) og krymper ut | samtidig, ~0,17 s |
| Glød pulserer | 2,4 s syklus |

---

## 8. Samhandling (alt)

Alt gjøres med musa direkte på medaljongen og knappene. Ingen innstillingsvinduer.

| Handling | Slik | Tilbakemelding |
|---|---|---|
| Kaste/bruke | Venstreklikk på en knapp (tray, sidemeny eller meny) | Trykket-effekt. Når buffen er bekreftet på: knappen ved medaljongen forsvinner, tallet går ned. |
| Gi gruppebuff | Venstreklikk på gruppeknappen | Kastes på neste som mangler (gruppas rekkefølge). Ruta fylles. Knappen forsvinner når alle har den. |
| Bytte tier | **Høyreklikk** på en knapp hvor som helst, eller dra den til den andre raden | Flytter I ↔ II. En tier I som mangler, dukker opp ved knappen med en gang. |
| Ønsket antall | **Musehjul** over en buffting eller lagerting (Shift = 5) | «har/vil ha» endres med en gang. Minst 1. |
| Legge til | **Dra** en spell fra spellboken eller et item fra baggen og slipp på en sidemeny eller i menyen | Havner sist i tier II på riktig side. Spell på gruppesiden = gruppebuff. Item som gir en buff = buffting, ellers lagerting. |
| Slette | **Dra en knapp ut** av sidemenyen/menyen og slipp utenfor | «Slipp for å fjerne» ved musa mens du drar. I chatten: «[Control] Thorns er fjernet. Skriv /control angre for å få den tilbake.» |
| Angre sletting | `/control angre` | Oppføringen kommer tilbake på samme plass. |
| Bytte rekkefølge | Dra en knapp til en ny plass i samme rad | Gul strek der den lander. |
| Fold ut/inn side | Klikk venstre/høyre sone | §7.4 |
| Meny | Klikk nedre sone | §7.6 |
| Låse | Klikk øvre sone | Hengelås lukkes. Midten viser lås ved mus over. |
| Flytte | Dra i midten (ulåst) | Alt følger musa, holdt innenfor skjermen. |
| Skalere | Dra i et ytterhjørne (ulåst) | §7.9 |
| Bytte sider | Meny › Retning › «Bytt sider» | PB og MB bytter side. Åpne sider følger med. |
| Fell sammen menydel | Klikk kategorilinja | «−» blir «+». |
| Vakte stedet | Meny › Byvakt › «+ dette stedet» | Stedet legges til. Knappen blir grå. |
| Velg hvem en gruppebuff følges på | Se **ÅPENT Q7** | «bare Brakk» vises i menyen |

**Kamp:** dra, slette, bytte tier, flytte og skalere er av i kamp (beskyttede rammer). Klikk for å kaste virker.

**Slash-kommandoer:** `/control` og kortformen `/ctl`. `/control angre` (fra briefen). Forslag i tillegg: `/control` (åpne/lukke menyen), `/control lås`, `/control nullstill` (posisjon og skala), `/control debug` (skriv tilstand i chatten).

---

## 9. Gruppebuffer (PB)

### 9.1 Hvem følges

- Party-medlemmene (party1–4), ikke deg selv. Deg selv dekker MB-siden.
- «Følger med på» i menyen viser hvem som er i gruppa nå, i klassefarger.
- En gruppebuff kan settes til å følges bare på noen (`onlyOn`), f.eks. Thorns bare på tanken.
- Raid er utenfor v1 (§16).

### 9.2 Hvem mangler

- Utenfor kamp: les auraene på hvert medlem som følges. Mangler = ingen av `auraNames` er på.
- Ute av rekkevidde eller ikke synlig: regnes som ukjent, ikke mangler (vis ruta dempet). Se **ÅPENT Q8**.
- Døde/frakoblede medlemmer telles ikke.

### 9.3 Klikk

- Knappen er en sikker knapp med `type=spell`, `spell=<id>` og `unit=<neste som mangler>`.
- «Neste» er første som mangler i gruppas rekkefølge. Målet settes på nytt **utenfor kamp** hver gang lista endres.
- I kamp kan målet ikke endres: knappen kaster på den som manglet sist vi kunne se. Tooltip sier det.
- Etter et bekreftet kast (§12.4): marker medlemmet som «har» (estimat i kamp, lest på nytt etter kampen).

### 9.4 Visning

- Rutene på knappen: én per medlem som følges, i gruppas rekkefølge.
- Tooltip: liste over medlemmer med «har»/«mangler».
- Statuslinja: «MotW: Brakk, Vesla».
- Gruppebuff som mangler på noen, gir rød ring (§6.5).

### 9.5 Likeverdige buffer

Én oppføring kan godta flere auraer. Lag en tabell over kjente par for Forever og bruk den når en spell legges til, f.eks.:

- Mark of the Wild ↔ Gift of the Wild
- Power Word: Fortitude ↔ Prayer of Fortitude
- Arcane Intellect ↔ Arcane Brilliance
- Blessing of X ↔ Greater Blessing of X
- Mat: buffen heter «Well Fed» uansett hvilken mat (V7)

Sjekk navnene i Forever. Tabellen er data, ikke logikk. Likeverdige buffer fylles inn automatisk (Q9).

**Gruppeversjonen foreslås bare når den lønner seg** (Daniel, 3. okt.): knappen for en gruppebuff kaster gruppeversjonen (Gift of the Wild, Prayer of Fortitude, Arcane Brilliance …) bare når du er i party, **flere enn 2** av dem som følges mangler buffen, og du har reagensen i baggen. Ellers kaster den enkeltversjonen (Mark of the Wild osv.) på neste som mangler. Begge teller som «på». Valget gjøres utenfor kamp, sammen med målet (§9.3).

---

## 10. Byvakt

Sier fra når du forlater en by og noe mangler.

- **Vaktede steder:** hovedstedene for din fraksjon fra start (Alliance: Stormwind City, Ironforge, Darnassus; Horde: Orgrimmar, Thunder Bluff, Undercity). Bruk spillets egne sonenavn (`GetRealZoneText`). «+ dette stedet» legger til sonen (eller underområdet) du står i.
- **Utløses** (spillet vet ikke at du *skal* dra, så vi reagerer når det skjer):
  - du går over grensa ut av et vaktet sted (sonebytte fra vaktet til ikke-vaktet),
  - du åpner flykartet i et vaktet sted,
  - du tar portal eller båt ut (sonebytte),
  - køen spretter (hvis Forever har kø, V8).
- **Hva som sjekkes:** alle MB-oppføringer, begge tier.
- **Visning:** nivå 3-varsel (§11). Aldri gjentatt for samme avreise.
- **Tekster:** «Du forlater Stormwind» + linje med det som mangler, f.eks. «Runecloth Bandage 0/10 · Superior Defense 4/5». Alt klart: «Alt med».

---

## 11. Varsler

Varsler slites ut hvis de kommer ofte. Derfor er det stille hele tiden, og stemme bare når noe endrer seg eller ikke kan angres (`tavle-varsler.png`).

| Nivå | Når | Slik | Lyd |
|---|---|---|---|
| **1. Hele tiden** | Alltid | Tall og ringfarge i medaljongen, knapper ved medaljongen. | Aldri |
| **2. En buff du hadde, går ut** | 40 s igjen på en buff som var på | Et lite ikon med nedtelling nær midten av skjermen. Forsvinner når du fornyer. Viser bare tid (kan ikke være en kastknapp i kamp). Se **ÅPENT Q4**. | Ingen |
| **3. Øyeblikk du ikke kan angre** | Byvakt (§10) | Én tekstlinje midt på skjermen. Noe tomt: **rød** tekst + én lyd. Noe under: **oransje** tekst, ingen lyd. Alt klart: kort grønn «Alt med», tones ut, ingen lyd. | Bare ved tomt |

I kamp: ingen nye lys eller tekster. Nedtellinger fortsetter fra det vi visste før kampen.

---

## 12. Kamp og API-begrensninger (teknisk)

### 12.1 Beskyttede knapper

- Alle knapper som kaster eller bruker noe, lages med `SecureActionButtonTemplate` (`type=spell` / `type=item`, `unit=player` / `partyN`).
- I kamp (`InCombatLockdown()`) kan de ikke vises, skjules, flyttes, få nye attributter eller nytt foreldre-element. All layout som rører dem, legges i en kø og kjøres ved `PLAYER_REGEN_ENABLED`.
- Høyreklikk skal **ikke** kaste: sett `type2` til tom og håndter tier-bytte i `PostClick` (ikke beskyttet) utenfor kamp.
- Musehjul (`OnMouseWheel`) og tooltip (`OnEnter`) er lov på sikre knapper.
- Medaljongen og sonene er **ikke** sikre rammer (de kaster ingenting), så tall, ring og hover virker alltid. Men flytting av en ramme som har sikre barn, er blokkert i kamp.

### 12.2 Hemmelige verdier (Midnight-reglene)

- Aura-API-ene (`C_UnitAuras.GetUnitAuras`, `C_UnitAuras.GetAuraDataBySpellName`, `C_UnitAuras.GetPlayerAuraBySpellID` m.fl.) kan returnere hemmelige verdier i kamp, i encounter/dungeon-kart og PvP.
- Med en hemmelig verdi kan ikke addon-kode regne, sammenligne, teste eller bruke den som tabellnøkkel. Sjekk alltid `issecretvalue(v)` før bruk, og fall tilbake til sist kjente verdi.
- Les og lagre `expirationTime` og `duration` utenfor kamp. Tell ned selv med `GetTime()`.
- `durations[auraId]` lagres når vi ser full varighet, så vi kan estimere etter et kast i kamp.

### 12.3 Lesing

- Egne auraer: på `UNIT_AURA` for `player` og ved `PLAYER_ENTERING_WORLD` / `PLAYER_REGEN_ENABLED`.
- Party: på `UNIT_AURA` for `party1–4` og `GROUP_ROSTER_UPDATE`.
- Bagger: `BAG_UPDATE_DELAYED` → `C_Item.GetItemCount(itemId)`.
- Throttle omregning (f.eks. maks hvert 0,1 s) og oppdater timere med én felles ticker (f.eks. 0,2 s), ikke `OnUpdate` per knapp.

### 12.4 Registrere et trykk (særlig i kamp)

Spillet skjuler i kamp både varighet og (trolig) hvilken spell du kastet, så vi bygger på det vi vet selv:

1. **Hvilken knapp du trykket.** Addonens egen informasjon, aldri hemmelig. Lagre `pending = { entryId, clickedAt }` i `PreClick`.
2. **At du faktisk kastet noe.** `UNIT_SPELLCAST_SUCCEEDED` for `player` innen **1 s** etter trykket (lenger for spells med kastetid: vent på `SUCCEEDED`/`FAILED`/`INTERRUPTED`) = buffen er på. Bommer du (for langt unna, tom for mana), kommer ingen bekreftelse, og vi teller ikke feil. Hvis spellId er lesbar (V4), sammenlign den også.
3. **Hvor lenge den varer.** Fra `durations` (sist sett utenfor kamp). Aldri vist som «på» uten nedtelling før kampen er over.
4. **Buffting:** antallet i baggen går ned med én, som ekstra bekreftelse.
5. **Mat:** «Well Fed» kommer først etter at du har spist ferdig (sitter i 10–30 s). Vis knappen som «trykket/venter» til auraen kommer eller du reiser deg.

Utenfor kamp: bekreft med `UNIT_AURA` (buffen er faktisk på) før knappen fjernes. Kommer ingen bekreftelse innen rimelig tid, gå tilbake til forrige tilstand.

**Begrensning:** kaster du buffen fra din egen actionbar, eller en annen spiller fornyer den på deg i kamp, ser vi det først etter kampen.

### 12.5 Dra og slipp

- Inn: `OnReceiveDrag` på sidemenyen/menyen → `GetCursorInfo()` gir `"spell"` eller `"item"` + ID → `ClearCursor()`. For items: `C_Item.GetItemSpell(itemId)` avgjør buffting eller lagerting.
- Ut: `OnDragStart` på en knapp (bare utenfor kamp) → spøkelsesikon følger musa → slipp utenfor = fjern.

---

## 13. Visuell stil

Control skal se ut som en del av spillets eget UI (vinduene for karakter, Reputation og First Aid): mørk brun bakgrunn, dobbel bronsekant, gule kategorilinjer og hvit tekst med svart skygge. Ingen pergament, ingen tunge ornamenter. I spillet brukes spillets egne skrifter, teksturer og ikoner.

### 13.1 Farger

| Bruk | Farge |
|---|---|
| Rød (mangler, tomt) | `#FF2020` |
| Oransje (under, snart ute) | `#FF8C1A` |
| Grønn (alt med, handlinger i tooltip) | `#40BF40` |
| Gull (etiketter, tallet, tier-tall) | `#FFD100` |
| Lys gull (mus over, aktive symboler) | `#FFF3B0` |
| Dempet gull (symboler i hvile) | `#C9A24A` |
| Brødtekst, navn | `#ECE6D8` |
| Hjelpetekst | `#A0A0A0` |
| Grå (tomme ting, deaktivert) | `#808080` |
| Klassefarger | spillets (`RAID_CLASS_COLORS`), f.eks. Warrior `#C79C6E`, Mage `#69CCF0`, Priest `#FFFFFF`, Rogue `#FFF569` |

Gult brukes bare til tekst/etiketter, aldri som varselfarge (derfor oransje for «under»).

### 13.2 Rammer

| Element | Verdi |
|---|---|
| Bakgrunn (tray, sidemeny, meny) | `#201812` øverst → `#130E0A` nederst, nesten dekkende, svakt varmt lys i toppen |
| Kant | 2 px bronse: `#9A7A3E` topp, `#6E5328` sider, `#4F3A1A` bunn, med 1 px svart utenfor og innenfor. Skygge under. |
| Fure (skillelinje) | 1 px svart + 1 px `#4A3920` |
| Hjørner | 4 px (tray, sidemeny), 5 px (meny) |
| Kategorilinje | 24 px, `#3D2C19` → `#271B10`, 1 px kant `#6A4D27`, gul tekst, «−»/«+» til høyre. Mus over: lysere og kant `#8A6A36`. |
| Tom rute | 40 px, svart kant, `#0B0907`, innfelt skygge, «+» i `#5E5446` på første |
| Knapper i menyen («Bytt sider», «+ dette stedet») | 22 px høye, brun gradient, 1 px kant `#7A6040`, gul tekst. Deaktivert: grå. |
| Tooltip | spillets: mørkeblå `#090A14` (95 %), 1 px kant `#60636F`, 5 px hjørner |

### 13.3 Skrift

| Bruk | I spillet | I prototypen |
|---|---|---|
| Overskrifter, etiketter, tallet i medaljongen, tier-tall | Friz Quadrata (`GameFontNormal`-familien) | Marcellus |
| Tall og tider på knappene, hjelpetekst | spillets smale tallskrift (`NumberFontNormal`-familien) | Archivo Narrow |
| Brødtekst | 13 px, `#ECE6D8`, 1 px svart skygge | |

---

## 14. Tekster

Norsk bokmål, kort, uten emoji. Tall før ord. «har/vil ha» for antall. Tider som «24 min», «2 t» og «0:38».

| Ord | Betyr | Ikke |
|---|---|---|
| Buffer | Spells, eliksirer og mat som gir en buff | «auras», «effekter» |
| Ting | Items du vil ha med, med antall | «inventar» |
| Byvakt | Varsel når du forlater en by | «geofence» |
| mangler | Rød: tomt, gått ut eller ikke på | «feil» |
| ikke på | Buffen er ikke på | «inaktiv» |
| Alt med | Grønn bekreftelse | «OK!» |
| + dette stedet | Legg til stedet du står | «Legg til lokasjon» |

**Faste tekster:**

- Byvakt, noe mangler: «Du forlater Stormwind» + «Runecloth Bandage 0/10 · Superior Defense 4/5»
- Byvakt, alt klart: «Alt med»
- Dra ut: «Slipp for å fjerne», så i chatten «[Control] <navn> er fjernet. Skriv /control angre for å få den tilbake.»
- Tom sidemeny, første rute: «Dra en spell eller en ting fra baggen hit» (MB) / «Dra en buff du kan gi, fra spellboken hit» (PB)
- Tom tier-rad i menyen: «Dra en buff eller ting hit» (MB) / «Dra en buff du kan gi hit» (PB)
- Statuslinje: «Mangler», «Status», «Gruppa», «Alt med», «Alle har det de skal»
- Menydeler: «Mine buffer og ting», «Til gruppa», «Følger med på:», «Byvakt», «Du er i …», «Retning», «Gruppa til venstre · mine til høyre», «Bytt sider»
- Tier-hjelp: «Tier I: dukker opp ved knappen når den mangler», «Tier II: bare i sidemenyen»
- Midten: «Flytt knappen: dra» (ulåst), «Låst på plass. Lås opp fra toppen av ringen.» (låst). (Prototypen nevner også piltaster; det var bare for nettleseren.)
- Sonene (tooltip/skjermleser): «Lås» / «Lås opp», «Fold ut gruppa» / «Fold inn gruppa», «Fold ut mine buffer» / «Fold inn mine buffer», «Åpne menyen, 7 å gjøre» / «Lukk menyen, 7 å gjøre»
- Tomme ruter: første «Dra …» (over), resten «Ledig plass»

---

## 15. Åpne spørsmål

Spør Daniel. Inntil han har svart, bruk standardvalget i høyre kolonne (og si fra at du gjorde det).

| # | Spørsmål | Standard inntil avklart |
|---|---|---|
| **Q1** | Skal en buffting (eliksir/flask/mat) som ikke er på, være **rød**, eller skal fargen bare styres av lageret? | **Avgjort 3. okt.: rød** |
| **Q2** | Skal tallet telle **alt** som mangler helt eller delvis, eller bare det du kan trykke på nå? | **Avgjort 3. okt.: alt** |
| **Q3** | Er 40 s riktig terskel for «snart ute»? | **Avgjort 3. okt.: 40 s** |
| **Q4** | Trengs nivå 2-varselet (nedtellingsikon midt på skjermen) når tier I-knappen uansett dukker opp ved medaljongen med stor nedtelling? | Bygg det sist, bak en innstilling |
| **Q5** | Hvor skal skala-hjørnene sitte i den nye modellen (ytterhjørnene på tray/sidemeny, eller rundt medaljongen)? | Ytterhjørnene på sidemenyen når den er åpen |
| **Q6** | Fjerne en by fra Byvakt: hvordan? | Høyreklikk på bynavnet i menyen + `/control angre` |
| **Q7** | Hvordan velges hvem en gruppebuff følges på? | Klikk på navnene i tooltip-lista eller i menyen for å slå av/på |
| **Q8** | Medlem ute av rekkevidde: ukjent (dempet) eller mangler (rød)? | Ukjent, dempet rute, teller ikke |
| **Q9** | Skal kjente likeverdige buffer (§9.5) fylles inn automatisk, eller velges? | **Avgjort 3. okt.: automatisk.** Gruppeversjonen kastes bare i party når flere enn 2 mangler (§9.5) |
| **Q10** | Skal lista fra den gamle Klar-sjekk (1.0, `KlarsjekkDB`) flyttes over? | **Avgjort 3. okt.: ja**, som MB tier II, én gang, mens den gamle addonen fortsatt er lastet |

---

## 16. Utenfor v1 (parkert)

- **Raid** (flere enn 5). Gruppebuffer er bygd for party.
- **Tier III** (ble droppet; enkelt å legge til igjen som «bare i menyen»).
- **«Støpt» låst utseende** (tung bronsekrage med nagler og kraftigere rammer når låst). Prøvd i prototypen, lagt til side. Låst vises nå bare med hengelås i midten.
- **Klikkbare infofelt** som tar deg rett til riktig del (fra briefen).
- **Lyd-/tekstinnstillinger** utover standard.
- **Andre språk** enn norsk bokmål (men legg tekster i en `Locale`-tabell så det er mulig).

---

## 17. Teknisk arkitektur (anbefalt)

```
Control/
  Control.toc            ## Interface: <V1>  ## SavedVariablesPerCharacter: ControlCharDB
  Locale/nbNO.lua          alle UI-tekster
  Core.lua                 navnerom, events, init, slash, kø for kamp (RunAfterCombat)
  Data.lua                 skjema, migrering, standarder, likeverdige buffer (§9.5), byer per fraksjon
  Scan.lua                 lesing: auraer (med issecretvalue), bagger, gruppe, estimat i kamp
  Rules.lua                REN LUA: severity, canPress, tray-lister, tall, ringfarge, statuslinje, tidsformat
  Track.lua                registrering av trykk (§12.4), pending, durations
  UI/Style.lua             farger, rammer, skrifter, felles teksturfunksjoner
  UI/Medallion.lua         medaljong, soner, midten, hover, lås, flytting, klemming
  UI/EntryButton.lua       40 px sikker knapp, alle visuelle tilstander, tooltip, høyreklikk, hjul, dra
  UI/Tray.lua              knapper ved medaljongen per side
  UI/SideBar.lua           sidemenyer med statuslinje
  UI/Menu.lua              menyen med delene
  CityWatch.lua            Byvakt
  Alerts.lua               nivå 2 og 3
tests/                     tester i Lua 5.1 via Python + lupa (python tests/run.py); se HISTORIKK §6
```

- Lua 5.1, ingen globale variabler utenom `ControlCharDB` og slash-kommandoen. Bruk `local addonName, ns = ...`.
- Ingen biblioteker er nødvendige. LibStub/Ace er greit hvis det forenkler, men ikke et krav.
- `Rules.lua` skal ikke kalle WoW-API. Den får inn oppføringer og tilstand, og gir ut alt UI-et trenger (som `renderVals()` i prototypen).
- Én tegnerunde: tilstand endres → `ns:Refresh()` (throttlet) → regler → UI oppdaterer det som har endret seg.

---

## 18. Faser og akseptkriterier

| Fase | Innhold | Ferdig når |
|---|---|---|
| **0. Sjekk spillet** | Tom addon med TOC og `/control debug` som skriver ut svar på V1–V9 (der det går med kode). | Daniel har kjørt den i Forever (beta eller live) og svarene er skrevet inn i `HISTORIKK.md` › Verifisert. |
| **1. Regler** | `Rules.lua` + tester for alt i §6 og scenarioet i §19. | `python tests/run.py` grønn. Tallene i §19 stemmer. |
| **2. Medaljong** | Tall, ring, hover-symboler, soner, midten, flytting, lås, klemming, lagring av posisjon. | Kan flyttes og låses. Tall og ring følger testdata. |
| **3. Mine buffer** | Lesing av egne auraer og bagger. Sikre knapper. Tray for tier I. Klikk kaster/bruker, bekreftelse, knappen forsvinner. | MotW og en flask: mangler → står ute → klikk → på → borte, tallet går ned. |
| **4. Sidemenyer** | Begge sider, statuslinje, tooltip, høyreklikk tier, musehjul antall. | Som `04-begge-sider-apne.png`. |
| **5. Gruppebuffer** | Party-lesing, ruter, neste mål, «bare på». | MotW til en kompis: ruta fylles, knappen borte når alle har den. |
| **6. Meny** | Delene i §7.6, dra inn, dra ut, `/control angre`, rekkefølge, bytt sider, menyretning. | Som `05-sider-og-meny-apne.png`. |
| **7. Kamp** | Fryse layout, kø, estimat, registrering i kamp, dempede ruter, sverd. | Trykk i kamp teller ned. Etter kampen stemmer alt med virkeligheten. |
| **8. Byvakt og varsler** | §10 og §11. | Gå ut av Stormwind med 0 bandasjer: rød tekst + lyd én gang. |
| **9. Skala og finpuss** | §7.9, animasjoner, ytelse. | 70–150 %, ingen merkbar FPS-kostnad. |

Etter hver fase: kort sjekkliste for Daniel å teste i spillet (`/reload`).

---

## 19. Testscenario (fra prototypen)

Bruk dette som fixture i testene for `Rules.lua`. Det er samme data som prototypen starter med.

**Gruppa:** Brakk (Warrior, tank), Lirael (Mage), Tosk (Priest), Vesla (Rogue).

**PB (til gruppa):**

| Oppføring | Tier | Har | Følges på |
|---|---|---|---|
| Mark of the Wild | I | Lirael, Tosk | alle |
| Thorns | II | – | bare Brakk |

**MB (mine):**

| Oppføring | Type | Tier | Buff | Lager |
|---|---|---|---|---|
| Mark of the Wild | spell | I | ikke på | – |
| Thorns | spell | I | 6 min igjen | – |
| Flask of the Titans | buffitem | I | ikke på | 3 / vil ha 2 |
| Well Fed (Smoked Desert Dumplings) | buffitem | II | 12 min | 10 / 10 |
| Elixir of the Mongoose | buffitem | II | 48 min | 3 / 4 |
| Elixir of Superior Defense | buffitem | II | ikke på | 4 / 5 |
| Runecloth Bandage | item | II | – | 0 / 10 |
| Major Mana Potion | item | II | – | 5 / 5 |

**Forventet (med Q1 = rød):**

| Steg | Ved knappen (PB-side ‖ MB-side) | Tall | Ring |
|---|---|---|---|
| Start | MotW-gruppe ‖ MotW, Flask | **7** | rød |
| Klikk MotW (meg) | MotW-gruppe ‖ Flask | **6** | rød |
| Klikk Flask (3 → 2, fortsatt nok) | MotW-gruppe ‖ – | **5** | rød |
| Klikk MotW-gruppe (Brakk får) | MotW-gruppe (Vesla mangler) ‖ – | **5** | rød |
| Klikk MotW-gruppe (Vesla får) | – ‖ – (knappen alene) | **4** | rød (Thorns til Brakk, Defense ikke på, Bandage 0/10) |

De 4 som er igjen: Thorns til Brakk (PB, tier II), Mongoose 3/4, Defense ikke på 4/5, Bandage 0/10.

Statuslinje MB ved start: `Mangler  MotW · Flask · Defense 4/5 · Bandage 0/10 · +1`
Statuslinje PB ved start: `Mangler  MotW: Brakk, Vesla · Thorns: Brakk`

Høyreklikk Defense til tier I → Defense dukker opp ved knappen med en gang (ikke på, har 4).

---

## 20. Kilder og lenker

**Prosjektet (private lenker, åpnes av Daniel):**

- Designcanvas (prototype, versjon 18): https://claude.ai/artifact/Ew5JD6xxBBdFNY8kVZyUUF
- Original designbrief: https://claude.ai/code/artifact/42403d92-5a33-4ea5-89d7-2e4e9dc3192b (kopi i `docs/referanse/designbrief-original.md`)

**WoW Forever:**

- Icy Veins, «Addons in WoW Forever? Blizzard Devs Just Addressed the Big Question» (17. sep. 2026): https://www.icy-veins.com/wow-forever/news/addons-in-wow-forever-blizzard-devs-just-addressed-the-big-question/
- Kami Labs, «WoW Forever Addons: As Restricted As Midnight»: https://kami-labs.fr/en/wow-classic/wow-forever-addons-restreints-comme-sur-midnight/
- TechSpot, lansering 4. november 2026: https://www.techspot.com/news/113832-world-warcraft-forever-launches-november-4-new-race.html

**API:**

- Secret values: https://warcraft.wiki.gg/wiki/Secret_values
- Patch 12.0.0 API changes: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- Patch 12.0.5 API changes: https://warcraft.wiki.gg/wiki/Patch_12.0.5/API_changes
- C_UnitAuras.GetUnitAuras: https://warcraft.wiki.gg/wiki/API:C_UnitAuras.GetUnitAuras
