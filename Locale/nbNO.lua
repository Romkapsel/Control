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
  HELP = "/control test (bla i testdata) · /control lås · /control nullstill · /control debug",
}
