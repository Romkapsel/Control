# Slik starter du med Claude Code

## 1. Legg mappa på plass

Pakk ut zip-fila til en egen mappe, for eksempel `Dokumenter\Control` (gjort 3. okt.). Ikke inne i spillmappa; Claude Code hjelper deg å koble den til spillet i fase 0.

Innhold:

```
Control/
  CLAUDE.md                 Claude Code leser denne automatisk
  OPPSTART.md               denne fila
  docs/
    SPEC.md                 hva som skal bygges (gjeldende)
    HISTORIKK.md            hvordan vi kom hit, beslutninger, lærdom
    referanse/
      designbrief-original.md
      prototype/            designfilene + utdrag av logikken
      skjermbilder/         alle tilstander og tavler
```

## 2. Start Claude Code i mappa

I PowerShell:

```powershell
cd "$HOME\Documents\Control"
git init
git add .
git commit -m "Spesifikasjon og referanse"
claude
```

(Har du ikke Claude Code installert: se https://docs.claude.com/en/docs/claude-code)

## 3. Lim inn denne første meldingen

```
Hei! Dette er Control, en addon til WoW Forever. Les CLAUDE.md, docs/SPEC.md og docs/HISTORIKK.md, og se på skjermbildene i docs/referanse/skjermbilder.

Gi meg så:
1. En kort oppsummering av hva du har forstått (maks 10 punkter).
2. Spørsmålene i SPEC §15 du trenger svar på før fase 1–3.
3. En plan for fase 0: en minimal addon med TOC og /control debug som sjekker V1–V9 i spillet, og hjelp til å koble mappa inn i spillets AddOns-mappe på Windows.

Ikke skriv kode før jeg har svart.
```

## 4. Når du kommer tilbake i en ny økt

```
Les CLAUDE.md og HISTORIKK.md §5–6. Vi er i fase <N> i SPEC §18. Fortsett derfra.
```

## Tips

- Svar på de åpne spørsmålene (SPEC §15) så tidlig du kan. Q1 og Q2 påvirker regelmotoren i fase 1.
- Fase 0 krever at du logger inn i Forever (beta eller live) og kjører `/control debug`. Lim inn det som skrives i chatten, så fører Claude Code det inn i HISTORIKK §5.
- Designcanvaset og den originale briefen ligger i Claude (lenker i SPEC §20). Claude Code kan ikke åpne dem, men alt som trengs er kopiert inn her.
