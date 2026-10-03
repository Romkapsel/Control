# Klar-sjekk – WoW Forever-addon

Klar-sjekk viser hva du mangler av buffer og ting, og lar deg fikse det med ett klikk. En rund medaljong står alene på skjermen; tier I-buffer som mangler, dukker opp ved siden av og forsvinner når du trykker. Sidemenyene viser oversikten. Eier: Daniel (snakker norsk).

## Les først

1. `docs/SPEC.md` – gjeldende sannhet. Bygg etter denne.
2. `docs/HISTORIKK.md` – hvorfor ting er som de er, og hva som er forkastet (§3: ikke bygg dette).
3. `docs/referanse/` – prototype (`prototype/prototype-logikk.js` er referanseoppførselen for reglene), skjermbilder av alle tilstander, og den originale designbriefen (historisk).

## Regler for arbeidet

- **Åpne spørsmål** (SPEC §15): spør Daniel. Inntil han har svart, bruk standardvalget i tabellen og si fra at du gjorde det. Noe som ikke er verifisert i spillet (SPEC §2, V1–V9), skal sjekkes i fase 0 før du bygger på det.
- **Jobb i fasene** i SPEC §18. Avslutt hver fase med en kort sjekkliste Daniel kan teste i spillet (`/reload`).
- **Oppdater dokumentasjonen** når noe avgjøres: SPEC (det som gjelder) og HISTORIKK §6 (beslutningslogg med dato). Svar fra spillet skrives i HISTORIKK §5.
- **Svar Daniel på norsk.** Kode, identifikatorer og commit-meldinger på engelsk. UI-tekst på norsk bokmål, samlet i `Locale/nbNO.lua`. Bruk ordlista i SPEC §3.

## Tekniske regler

- Lua 5.1 (WoW). Ingen globale variabler utenom `KlarSjekkCharDB` og slash-kommandoen. Bruk `local addonName, ns = ...`.
- `Rules.lua` er ren Lua uten WoW-API, med `busted`-tester i `spec/`. Testscenarioet i SPEC §19 skal alltid være grønt.
- **Kamp:** sjekk `InCombatLockdown()` før alt som rører sikre knapper (vise, skjule, flytte, `SetAttribute`). Legg det i en kø som kjøres ved `PLAYER_REGEN_ENABLED`.
- **Hemmelige verdier:** sjekk `issecretvalue(v)` før du regner med, sammenligner eller bruker en verdi fra aura-, enhets- eller kast-API-er. Fall tilbake til sist kjente verdi.
- **Aldri** kast eller bruk noe automatisk. Bare sikre knapper (`SecureActionButtonTemplate`) som spilleren klikker på.
- Throttle omregning og bruk én felles ticker for nedtellinger, ikke `OnUpdate` per knapp.
- Kjør `luacheck .` og `busted` før du sier at noe er ferdig.

## Kommandoer

```
busted                 # tester for regelmotoren
luacheck .             # lint
```

I spillet: `/reload`, `/klar debug`, `/klar angre`.

## Installasjon i spillet

Addon-mappa heter `KlarSjekk` og skal ligge i spillets `Interface/AddOns`. Navnet på Forever-installasjonens mappe (f.eks. `_forever_`) og Interface-nummeret i TOC er ikke verifisert ennå (SPEC V1). Spør Daniel.
