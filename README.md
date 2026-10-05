# Control

En addon for **WoW Forever** som viser hva du mangler av buffer og ting, og lar deg fikse det med ett klikk.
Alt samles i én liten medaljong på skjermen. Lyser det ikke, er alt i orden.

## Installere

1. Last ned **`Control-x.y.z.zip`** under [Releases](https://github.com/Romkapsel/Control/releases/latest).
2. Pakk ut zip-fila i AddOns-mappa til Forever-klienten, for eksempel
   `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\`
   Du skal ende opp med `AddOns\Control\Control.toc`.
3. **Start spillet helt på nytt** (ikke bare `/reload`) – spillet finner nye bildefiler bare ved oppstart.

Ny versjon: slett den gamle `Control`-mappa, pakk ut den nye, og start spillet på nytt.

## Medaljongen

- **Tallet** i midten er hvor mange ting som mangler. Tom midte = alt er i orden.
- **Ringen** er rød når noe du *må* ha mangler (tier I), oransje når noe er *fint å ha* (tier II), snart går ut,
  eller er under antallet du vil ha.
- Hold musa over ringen, så kommer fire soner fram:
  - **Topp – Lås:** låser medaljongen fast.
  - **Venstre og høyre – Meg og Party:** folder ut sidemenyene med dine egne buffer og gruppas buffer.
  - **Nede – Meny:** alt du kan stille på.
- **Midten – Dra:** flytt medaljongen (ikke i kamp, og ikke når den er låst).

## Legge til buffer og ting

- **Dra en spell fra spellboken** eller **en ting fra baggen** og slipp den:
  - på medaljongen → havner i **tier I**
  - på en sidemeny eller i menyen → havner i **tier II** (eller raden du slipper den i)
- **Tier I:** knappen dukker opp ved medaljongen når noe mangler – klikk, så er det fikset.
- **Tier II:** står bare i sidemenyen.
- **Ting du bare skal ha med** (utstyr, bandasjer, potions, reagenser) står i sidemenyen bare når de mangler eller er
  under antallet – med rød eller oransje ramme. Er alt med, er de borte derfra. Menyen viser alltid alt.

Det som kan legges til:
- spells du kaster på deg selv (Mark of the Wild, Arcane Intellect …)
- eliksirer, flasks, scrolls og mat som gir «Well Fed» – addonen ser om buffen er på og hvor mange du har
- **gift, våpenoljer og slipesteiner** – knappen legger dem rett på våpenet (MH = hovedhånda). Dra den samme en gang
  til med et våpen i annen hånd, så får du en knapp for den også (OH). Har våpenet noe på seg fra før, spør spillet
  om du vil bytte
- andre ting du vil ha med deg (bandasjer, potions, reagenser) – addonen passer på antallet

## Knappene

| Du gjør | Det skjer |
|---|---|
| Klikk | Kaster spellen / bruker tingen |
| Høyreklikk | Bytter mellom tier I og II |
| Musehjul | Hvor mange du vil ha (Shift = 5 om gangen) |
| Shift + dra | Flytt den (gullstreken viser hvor), eller dra den ut for å fjerne |
| `/ctrl angre` | Får tilbake det du nettopp fjernet |

Siste 40 sekunder før en buff går ut, teller knappen ned.

**Lys og rammer:** pulserende gull = trykk her. En rolig oransje eller rød ramme viser hva som gjør medaljongen
oransje eller rød, men som du ikke kan fikse med et klikk akkurat nå (for eksempel for få bandasjer i baggen).

## Party

- Dra en buff du kan gi andre (eller en **scroll**) til **Party**-siden.
- Hver knapp har en liten rute per medlem: **lys** = har den, **tom med gul kant** = mangler, **dempet** = vet ikke
  (ute av syne, offline eller død).
- Klikk: kaster på den første som mangler. Mangler **flere enn 2** og du kan kaste gruppeversjonen
  (Gift of the Wild, Prayer of Fortitude …), brukes den.
- **Shouts** og andre buffer uten rekkevidde kastes på deg selv og regnes som gitt til hele gruppa.
- I menyen kan du klikke navn for å velge **hvem** en buff skal følges på (grå = følges ikke).

## Byvakt

Sier fra når du drar fra et sted som voktes – ut porten, med båt eller portal, eller når du snakker med en
flight master – hvis du mangler noe i baggen:

- **Rødt + lyd:** noe i tier I er tomt.
- **Oransje:** noe er tomt i tier II, eller du har færre enn du vil ha.
- **Grønn «Alt med»:** alt er i orden.

Byvakta sjekker også **reparasjon** (dårligste utstyr: under 100 % oransje, under 50 % rødt) og **bagplass**
(4 eller færre ledige plasser oransje, ingen rødt). Reparasjon er på og bagplass av fra start – begge slås av og på under Byvakt i menyen.

Hovedbyene for fraksjonen din voktes fra start. I menyen: **Legg til** stedet du står, og **Voktes (n)** viser lista –
dra et sted ut av lista for å fjerne det.

## Menyen

- **Meg** og **Party:** alle knappene dine i rad I og II.
- **Byvakt:** se over.
- **Oppsett:** **Bytt side på gruppene**, **Tall i midten** (på/av – uten tallet er det ringen som sier fra), **Gjennomsiktig midt** (på/av – verden synes gjennom medaljongen), og **Størrelse** (70–150 %).
- Lukk med pila i hjørnet, eller klikk nederst på medaljongen.

## I kamp

- Knappene virker. Klikker du en knapp ved medaljongen, forsvinner den med en gang.
- Sidemenyene og menyen kan åpnes og lukkes. I menyen virker **Tall i midten**; det andre er grått til kampen er over.
- To sverd låses bak medaljongen så lenge kampen varer.
- Spillet lar deg ikke flytte medaljongen eller legge til/fjerne ting i kamp.

## Kommandoer

`/ctrl`, etterfulgt av:

| Kommando | Gjør |
|---|---|
| `lås` | Låser / låser opp medaljongen |
| `angre` | Får tilbake det du sist fjernet |
| `varsel` | Viser byvaktvarselet akkurat nå |
| `nullstill` | Flytter medaljongen tilbake og gir den vanlig størrelse |
| `tøm` | Tømmer lista over dine egne buffer og ting |
| `test` | Blar gjennom testdata (skriv igjen for å gå tilbake) |

## Greit å vite

- Laget for **WoW Forever** (interface 16001) med **engelsk** spillklient. Tekstene i addonen er på norsk.
- Innstillingene lagres per karakter.
- Party-delen er lite testet ennå – si fra hvis noe ser rart ut.

---

For utviklere: kildekoden, testene (`python tests/run.py`) og bildeverktøyene (`tools/`) ligger her i repoet.
Spesifikasjonen står i `docs/SPEC.md`, og alle beslutninger i `docs/HISTORIKK.md`.
