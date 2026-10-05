-- Alle UI-tekster i Control (norsk bokmål). Ordlista står i SPEC §3 og §14.
local addonName, ns = ...

ns.L = {
  -- Statuslinja (SPEC §6.6)
  LABEL_MISSING = "Mangler",
  LABEL_STATUS = "Status",
  ALL_OK = "Alt med",
  SEP = " · ",
  LABEL_GAP = "  ",

  -- Tider (SPEC §7.5): «0:38», «24 min», «2 t»
  TIME_SECONDS = "%d:%02d",
  TIME_MINUTES = "%d min",
  TIME_HOURS = "%d t",
  TIME_MINUTES_SHORT = "%dm", -- på knappen
  TIME_HOURS_SHORT = "%dt",

  -- Tier (SPEC §7.7)
  TIER_1 = "I",
  TIER_2 = "II",
  TIER_1_HINT = "Tier I: vises ved medaljongen",
  TIER_2_HINT = "Tier II: bare i sidemenyen",

  -- Tomme ruter (SPEC §14)
  EMPTY_SELF = "Dra en buff eller ting hit",
  EMPTY_PARTY = "Dra en buff eller scroll hit",
  LABEL_PARTY_BUFFS = "Party",
  LABEL_MY_BUFFS = "Meg",
  PARTY_SCROLLS_ONLY = "Bare scrolls kan brukes på andre.",

  -- Medaljongen: sonene og midten (SPEC §14)
  ZONE_LOCK = "Lås",
  ZONE_UNLOCK = "Lås opp",
  -- Kort og presist rett på medaljongen (Daniel 5. okt)
  ZONE_OPEN_PARTY = "Party",
  ZONE_CLOSE_PARTY = "Party",
  ZONE_OPEN_SELF = "Meg",
  ZONE_CLOSE_SELF = "Meg",
  ZONE_MENU_OPEN = "Åpne meny",
  ZONE_MENU_CLOSE = "Lukke meny",
  CLOSE = "Lukke",
  HUB_MOVE = "Dra",
  HUB_LOCKED = "Låst",

  -- Menyen (fase 6, SPEC §7.6)
  MENU_CITY = "Byvakt",
  MENU_DIR = "Oppsett",
  SIDE_LEFT = "venstre",
  SIDE_RIGHT = "høyre",
  NO_PARTY = "Ingen i party",
  FOLLOW_STOP = "Klikk: ikke følg %s",
  FOLLOW_START = "Klikk: følg %s",
  CITY_NONE = "Ingen steder",
  CITY_LIST = "Voktes (%d)",
  CITY_ROW_TIP = "Dra ut: fjern",
  CITY_HERE = "Du er i %s",
  CITY_LEAVING = "Du forlater %s",
  CHECK_REPAIR = "Sjekk reparasjon",
  CHECK_BAGS = "Sjekk bagplass",
  REPAIR_LABEL = "Reparasjon",
  REPAIR_VALUE = "%d%%",
  BAGS_LABEL = "Bagplass",
  CITY_ADD = "Legg til",
  CITY_ALREADY = "Voktes allerede",
  CITY_ADDED = "%s voktes nå.",
  CITY_REMOVED = "%s fjernet (/ctrl angre).",
  DIR_SWAP = "Bytt side på gruppene",
  SCALE = "Størrelse",
  COUNT_LABEL = "Tall i midten",
  OPEN_CORE_LABEL = "Gjennomsiktig midt",
  ON = "På",
  OFF = "Av",
  SCALE_VALUE = "%d %%",
  SCALE_TIP = "Dra eller rull (70–150 %)",
  -- Avstandstest (/ctrl avstand)
  RANGE_BUTTON = "Avstandstest",
  RANGE_TIP = "Lagrer hva spillet sier om avstanden til kompisene i partyet. Trykk nær og langt unna, i og utenfor kamp.",
  RANGE_ON = "Avstandstest er på: knappen står under Oppsett i menyen. Gjør /reload når du er ferdig.",
  RANGE_OFF = "Avstandstest er av.",
  RANGE_SAVED = "Avstand lagret (%d): %d i party, %s.",
  RANGE_IN_COMBAT = "i kamp",
  RANGE_OUT_COMBAT = "utenfor kamp",
  RANGE_NOTHING = "ingenting kunne leses",
  FOLLOW_SET = "%s: bare %s.",
  FOLLOW_ALL = "%s: alle.",

  -- Chat
  NOT_READY = "Ikke lastet ennå.",
  NOT_IN_COMBAT = "Ikke i kamp.",
  LOCKED = "Låst.",
  UNLOCKED = "Låst opp.",
  RESET_DONE = "Tilbakestilt.",
  TEST_SAMPLE = "Testdata: %s.",
  SAMPLE_START = "rød (7 mangler, som i spesifikasjonen)",
  SAMPLE_ORANGE = "oransje (2 under ønsket eller snart ute)",
  SAMPLE_OK = "alt med",
  SAMPLE_EMPTY = "tom liste",
  HELP = "/ctrl test (bla i testdata) · /ctrl varsel (se byvaktvarselet) · /ctrl lås · /ctrl nullstill · /ctrl tøm · /ctrl debug",
  MODE_LIVE = "dine egne buffer og ting",

  -- Tooltip (SPEC §7.7)
  TIP_MISSING = "Ikke på",
  TIP_EXPIRED = "Gått ut",
  TIP_ON = "På",
  TIP_LEFT = "%s igjen",
  TIP_EXPIRING = "%s igjen",
  TIP_IN_BAG = " · %d/%d i baggen",
  TIP_HAVE = "%d av %d",
  TIP_CAST_SELF = "Klikk: kast",
  TIP_USE = "Klikk: bruk",
  TIP_NONE_IN_BAG = "Tom",

  -- Legge til (fase 3: slipp på medaljongen)
  ADDED = "%s lagt til i tier I.",
  DUPLICATE = "%s er allerede med.",
  NOT_ADDABLE = "Bare spells og ting fra baggen.",
  NOT_KNOWN = "Ikke klar, prøv igjen.",
  LIST_CLEARED = "Lista er tømt.",

  -- Sidemenyene (fase 4)
  ADDED_SIDE = "%s lagt til i tier II.",
  DRAG_REMOVE = "Slipp for å fjerne",
  REMOVED = "%s fjernet (/ctrl angre).",
  UNDO_NONE = "Ingenting å angre.",
  UNDONE = "%s er tilbake.",
  TIP_WHEEL = "Hjul: antall (Shift = 5)",
  TIP_RCLICK = "Høyreklikk: tier (nå %s)",
  TIP_DRAG = "Shift + dra: flytt eller fjern",

  -- Gruppebuffer (fase 5, SPEC §7.7)
  TIP_PARTY_MISSING = "%d av %d mangler",
  TIP_PARTY_ALL = "Alle har den",
  TIP_HAS = "har",
  TIP_LACKS = "mangler",
  TIP_UNKNOWN = "ukjent",
  TIP_CAST_ON = "Klikk: kast på %s",
  TIP_CAST_GROUP = "Klikk: %s",
  TIP_PARTY_COMBAT = "I kamp: samme mål som før",
  TIP_ONLY_ON = "Bare på noen (se menyen)",
}
