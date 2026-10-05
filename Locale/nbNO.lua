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
  EMPTY_PARTY = "Dra en buff du kan gi, eller en scroll, hit",
  LABEL_PARTY_BUFFS = "Party",
  LABEL_MY_BUFFS = "Meg",
  PARTY_SCROLLS_ONLY = "Bare scrolls kan brukes på andre. Eliksirer, flasks og mat hører til dine egne.",
  FREE_SLOT = "Ledig plass",

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
  HUB_MOVE = "Dra",
  HUB_LOCKED = "Låst",

  -- Menyen (fase 6, SPEC §7.6)
  MENU_CITY = "Byvakt",
  MENU_DIR = "Oppsett",
  SIDE_LEFT = "venstre",
  SIDE_RIGHT = "høyre",
  NO_PARTY = "Ingen i party nå",
  FOLLOW_STOP = "Klikk: slutt å følge %s med %s",
  FOLLOW_START = "Klikk: følg %s med %s",
  CITY_NONE = "Ingen steder voktes",
  CITY_LIST = "Voktes (%d)",
  CITY_ROW_TIP = "Dra ut av lista for å fjerne",
  CITY_HERE = "Du er i %s",
  CITY_ADD = "Legg til",
  CITY_ALREADY = "Stedet voktes allerede",
  CITY_ADDED = "%s voktes nå.",
  CITY_REMOVED = "%s voktes ikke lenger. Skriv /control angre for å få det tilbake.",
  DIR_SWAP = "Bytt side på gruppene",
  SCALE = "Størrelse",
  SCALE_VALUE = "%d %%",
  SCALE_TIP = "Dra eller bruk musehjulet (70–150 %)",
  FOLLOW_SET = "%s følges nå på: %s.",
  FOLLOW_ALL = "%s følges nå på alle.",

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
  LIST_CLEARED = "Lista er tømt.",

  -- Sidemenyene (fase 4)
  ADDED_SIDE = "%s er lagt til (tier II).",
  DRAG_REMOVE = "Slipp for å fjerne",
  REMOVED = "%s er fjernet. Skriv /control angre for å få den tilbake.",
  UNDO_NONE = "Ingenting å angre.",
  UNDONE = "%s er tilbake på lista.",
  TIP_WHEEL = "Musehjul: ønsket antall (Shift = 5)",
  TIP_RCLICK = "Høyreklikk: bytt tier (nå %s)",
  TIP_DRAG = "Shift + dra: flytt, eller slipp utenfor for å fjerne",

  -- Gruppebuffer (fase 5, SPEC §7.7)
  TIP_PARTY_MISSING = "%d av %d mangler",
  TIP_PARTY_ALL = "Alle har den",
  TIP_HAS = "har",
  TIP_LACKS = "mangler",
  TIP_UNKNOWN = "ukjent",
  TIP_CAST_ON = "Klikk: kast på %s",
  TIP_CAST_GROUP = "Klikk: %s på hele gruppa",
  TIP_NO_TARGET = "Ingen å kaste på",
  TIP_PARTY_COMBAT = "I kamp: kaster på den som manglet før kampen",
  TIP_ONLY_ON = "Følges bare på noen (velges i menyen)",
}
