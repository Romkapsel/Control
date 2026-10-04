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
}
