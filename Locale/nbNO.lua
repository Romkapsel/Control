-- Alle UI-tekster i Control (norsk bokmål). Ordlista står i SPEC §3 og §14.
local addonName, ns = ...

ns.L = {
  -- Statuslinja (SPEC §6.6)
  LABEL_MISSING = "Mangler",
  LABEL_STATUS = "Status",
  LABEL_PARTY = "Gruppa",
  ALL_OK = "Alt med",
  PARTY_ALL_OK = "Alle har det de skal",
  SEP = " · ",
  LABEL_GAP = "  ",

  -- Tider (SPEC §7.5): «0:38», «24 min», «2 t»
  TIME_SECONDS = "%d:%02d",
  TIME_MINUTES = "%d min",
  TIME_HOURS = "%d t",

  -- Tier (SPEC §7.7)
  TIER_1 = "I",
  TIER_2 = "II",
  TIER_1_HINT = "Tier I: dukker opp ved knappen når den mangler",
  TIER_2_HINT = "Tier II: bare i sidemenyen",

  -- Tomme ruter (SPEC §14)
  EMPTY_SELF = "Dra en spell eller en ting fra baggen hit",
  EMPTY_PARTY = "Dra en buff du kan gi, fra spellboken hit",
  FREE_SLOT = "Ledig plass",

  -- Medaljongen: sonene og midten (SPEC §14)
  ZONE_LOCK = "Lås",
  ZONE_UNLOCK = "Lås opp",
  ZONE_OPEN_PARTY = "Fold ut gruppa",
  ZONE_CLOSE_PARTY = "Fold inn gruppa",
  ZONE_OPEN_SELF = "Fold ut mine buffer",
  ZONE_CLOSE_SELF = "Fold inn mine buffer",
  ZONE_MENU_OPEN = "Åpne menyen, %d å gjøre",
  ZONE_MENU_CLOSE = "Lukk menyen, %d å gjøre",
  HUB_MOVE = "Flytt knappen: dra",
  HUB_LOCKED = "Låst på plass. Lås opp fra toppen av ringen.",
  COMING_SIDES = "Sidemenyene kommer i fase 4.",
  COMING_MENU = "Menyen kommer i fase 6.",

  -- Chat
  NOT_READY = "Ikke lastet ennå.",
  NOT_IN_COMBAT = "Ikke i kamp.",
  LOCKED = "Låst.",
  UNLOCKED = "Låst opp.",
  RESET_DONE = "Knappen er flyttet tilbake og har vanlig størrelse.",
  TEST_SAMPLE = "Testdata: %s.",
  SAMPLE_START = "rød (7 mangler, som i spesifikasjonen)",
  SAMPLE_ORANGE = "oransje (2 under ønsket eller snart ute)",
  SAMPLE_OK = "alt med",
  SAMPLE_EMPTY = "tom liste",
  HELP = "/control test (bla i testdata) · /control lås · /control nullstill · /control tøm · /control debug",
  MODE_LIVE = "dine egne buffer og ting",

  -- Knappen (SPEC §7.5)
  BTN_MISSING = "ikke på",
  BTN_EXPIRED = "gått ut",

  -- Tooltip (SPEC §7.7)
  TIP_MISSING = "Ikke på",
  TIP_EXPIRED = "Gått ut",
  TIP_ON = "På",
  TIP_LEFT = "%s igjen",
  TIP_EXPIRING = "%s igjen, snart ute",
  TIP_IN_BAG = " · %d av %d i baggen",
  TIP_HAVE = "Har %d av %d",
  TIP_CAST_SELF = "Klikk for å kaste på deg selv",
  TIP_USE = "Klikk for å bruke (%s)",
  TIP_NONE_IN_BAG = "Ingen i baggen",
  TIP_STOCK_EMPTY = "Lagervare: tom",
  TIP_STOCK_LOW = "Lagervare: under ønsket",
  TIP_STOCK_OK = "Lagervare: nok",

  -- Legge til (fase 3: slipp på medaljongen)
  ADDED = "%s er lagt til (tier I).",
  DUPLICATE = "%s står allerede på lista.",
  NOT_ADDABLE = "Bare spells fra spellboken og ting fra baggen kan legges på lista.",
  NOT_KNOWN = "Fant ikke navnet ennå. Prøv igjen om et øyeblikk.",
  IMPORTED = "%d ting fra den gamle Klar-sjekk er flyttet over (tier II).",
  LIST_CLEARED = "Lista er tømt.",
}
