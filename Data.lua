-- Control: lagring (SPEC §5.2), standarder og testdata.
local addonName, ns = ...

local Data = {}
ns.Data = Data

Data.SCHEMA = 1
Data.SCALE_MIN, Data.SCALE_MAX, Data.SCALE_STEP = 0.70, 1.50, 0.05

local function defaults(t, d)
  for k, v in pairs(d) do
    if t[k] == nil then
      if type(v) == "table" then
        t[k] = {}
        defaults(t[k], v)
      else
        t[k] = v
      end
    elseif type(v) == "table" and type(t[k]) == "table" then
      defaults(t[k], v)
    end
  end
end

local DEFAULTS = {
  schema = Data.SCHEMA,
  self = {},
  party = {},
  ui = {
    point = { "CENTER", "UIParent", "CENTER", 0, 200 },
    scale = 1.0,
    locked = false,
    partySide = "left",
    menuSections = { self = true, party = true, city = true },
  },
  durations = {},
  cityWatch = { cities = {} },
}

-- Gjør lagringen komplett uten å røre det som alt står der (fase 0 la data under .debug).
function Data.Init(db)
  if type(db) ~= "table" then db = {} end
  defaults(db, DEFAULTS)
  return db
end

------------------------------------------------------------------------
-- Testdata (SPEC §19), brukt av medaljongen til buffene kobles på i fase 3
------------------------------------------------------------------------

local function scenarioStart()
  return {
    party = {
      { id = "p1", type = "partyspell", tier = 1, name = "Mark of the Wild", short = "MotW", groupSpell = "Gift of the Wild" },
      { id = "p2", type = "partyspell", tier = 2, name = "Thorns", short = "Thorns" },
    },
    self = {
      { id = "motw", type = "spell", tier = 1, name = "Mark of the Wild", short = "MotW" },
      { id = "thorns", type = "spell", tier = 1, name = "Thorns", short = "Thorns" },
      { id = "flask", type = "buffitem", tier = 1, name = "Flask of the Titans", short = "Flask", want = 2 },
      { id = "fed", type = "buffitem", tier = 2, name = "Well Fed", short = "Well Fed", want = 10 },
      { id = "mong", type = "buffitem", tier = 2, name = "Elixir of the Mongoose", short = "Mongoose", want = 4 },
      { id = "def", type = "buffitem", tier = 2, name = "Elixir of Superior Defense", short = "Defense", want = 5 },
      { id = "band", type = "item", tier = 2, name = "Runecloth Bandage", short = "Bandage", want = 10 },
      { id = "mana", type = "item", tier = 2, name = "Major Mana Potion", short = "Mana", want = 5 },
    },
    st = {
      p1 = { missingOn = { { name = "Brakk", unit = "party1" }, { name = "Vesla", unit = "party4" } } },
      p2 = { missingOn = { { name = "Brakk", unit = "party1" } } },
      motw = { status = "missing" },
      thorns = { status = "on" },
      flask = { status = "missing", count = 3 },
      fed = { status = "on", count = 10 },
      mong = { status = "on", count = 3 },
      def = { status = "missing", count = 4 },
      band = { count = 0 },
      mana = { count = 5 },
    },
  }
end

-- Fire tilstander å bla gjennom med /control test: rød (7), oransje (2), alt ok, tom.
Data.SAMPLES = { "start", "orange", "ok", "empty" }

function Data.Sample(kind)
  if kind == "empty" then return { self = {}, party = {}, st = {} } end
  local m = scenarioStart()
  if kind == "orange" then
    m.party = {}
    m.st.motw.status, m.st.flask.status, m.st.def.status = "on", "on", "on"
    m.st.band.count, m.st.mong.count, m.st.def.count = 3, 4, 5
    m.st.thorns.status = "expiring"
  elseif kind == "ok" then
    m.party = {}
    for _, e in ipairs(m.self) do
      local s = m.st[e.id]
      s.status = "on"
      if e.want then s.count = e.want end
    end
  end
  return m
end
