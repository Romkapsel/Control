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
-- Likeverdige buffer (SPEC §9.5): navn som også teller som «på». Data, ikke logikk.
------------------------------------------------------------------------

Data.EQUIV = {
  ["Mark of the Wild"] = { "Gift of the Wild" },
  ["Power Word: Fortitude"] = { "Prayer of Fortitude" },
  ["Divine Spirit"] = { "Prayer of Spirit" },
  ["Shadow Protection"] = { "Prayer of Shadow Protection" },
  ["Arcane Intellect"] = { "Arcane Brilliance" },
  ["Blessing of Might"] = { "Greater Blessing of Might" },
  ["Blessing of Wisdom"] = { "Greater Blessing of Wisdom" },
  ["Blessing of Kings"] = { "Greater Blessing of Kings" },
  ["Blessing of Salvation"] = { "Greater Blessing of Salvation" },
  ["Blessing of Sanctuary"] = { "Greater Blessing of Sanctuary" },
  ["Blessing of Light"] = { "Greater Blessing of Light" },
}

-- Kortnavn i statuslinja (SPEC §5.2). Ukjente: regel under, ellers hele navnet.
Data.SHORT = {
  ["Mark of the Wild"] = "MotW", ["Gift of the Wild"] = "MotW", ["Power Word: Fortitude"] = "Fort",
  ["Arcane Intellect"] = "Int", ["Divine Spirit"] = "Spirit", ["Shadow Protection"] = "Shadow",
  ["Blessing of Might"] = "Might", ["Blessing of Wisdom"] = "Wisdom", ["Blessing of Kings"] = "Kings",
  ["Lightning Shield"] = "Shield", ["Water Shield"] = "Shield", ["Battle Shout"] = "Shout",
  ["Well Fed"] = "Well Fed",
}

function Data.ShortName(name)
  if not name then return "?" end
  if Data.SHORT[name] then return Data.SHORT[name] end
  if name:find("Flask") then return "Flask" end
  if name:find("Bandage") then return "Bandage" end
  local rest = name:match("^Elixir of the (.+)$") or name:match("^Elixir of (.+)$")
  if rest then return rest:match("(%S+)$") end
  local potion = name:match("(%S+) Potion$")
  if potion then return potion end
  if #name <= 12 then return name end
  return name:match("^(%S+)")
end

function Data.AuraNames(name)
  local out = { name }
  for _, n in ipairs(Data.EQUIV[name] or {}) do out[#out + 1] = n end
  return out
end

-- Ny oppføring fra det som ble dratt inn. info = { kind = "spell"|"item", spellId, name,
-- itemId, itemName, itemSpell, isFood, wellFed, count }. Ting som gir en buff = buffting, ellers lagerting.
function Data.MakeEntry(db, info, tier)
  db.nextId = (db.nextId or 0) + 1
  local e = { id = "e" .. db.nextId, tier = tier or 2 }
  if info.kind == "spell" then
    e.type, e.spellId, e.name = "spell", info.spellId, info.name
    e.auraNames = Data.AuraNames(info.name)
  elseif info.itemSpell then
    e.type, e.itemId, e.name = "buffitem", info.itemId, info.itemName
    e.castName = info.itemSpell
    local aura = info.isFood and (info.wellFed or "Well Fed") or info.itemSpell
    e.auraNames = { aura }
    e.want = math.max(1, info.want or 1) -- standard 1: varsler bare når du er tom (Daniel 4. okt)
    e.short = info.isFood and Data.ShortName(aura) or nil
  else
    e.type, e.itemId, e.name = "item", info.itemId, info.itemName
    e.want = math.max(1, info.want or 1) -- standard 1: varsler bare når du er tom (Daniel 4. okt)
  end
  e.short = e.short or Data.ShortName(e.name)
  return e
end

-- Forbruk (klasse 0) med disse undertypene gir en buff: 2 eliksir, 3 flask, 4 scroll. Mat (5) bare med «Well Fed».
Data.BUFF_SUBCLASS = { [2] = true, [3] = true, [4] = true }

-- Rett opp type på ting som ligger på lista (buffting ↔ lagerting), f.eks. en potion som ble lagt inn som buffting.
function Data.Reclassify(db, resolve)
  for _, e in ipairs(db.self or {}) do
    if e.itemId and (e.type == "buffitem" or e.type == "item") then
      local info = resolve("item", e.itemId)
      if info then
        if info.itemSpell and e.type == "item" then
          e.type, e.castName = "buffitem", info.itemSpell
          e.auraNames = { info.isFood and (info.wellFed or "Well Fed") or info.itemSpell }
        elseif not info.itemSpell and e.type == "buffitem" then
          e.type, e.castName, e.auraNames = "item", nil, nil
          e.short = Data.ShortName(e.name)
        end
      end
    end
  end
end

function Data.FindDuplicate(list, info)
  for _, e in ipairs(list) do
    if info.kind == "spell" and e.type == "spell" and e.name == info.name then return e end
    if info.kind == "item" and e.itemId == info.itemId then return e end
  end
end

-- Den gamle Klar-sjekk (1.0, KlarsjekkDB per karakter) → MB tier II, én gang (Q10).
-- resolve(kind, id) gir info som til MakeEntry, eller nil hvis spillet ikke kjenner den.
function Data.ImportKlarsjekk(db, old, resolve)
  if db.importedKlarsjekk or type(old) ~= "table" or type(old.list) ~= "table" then return 0 end
  local added = 0
  for _, o in ipairs(old.list) do
    local info
    if o.kind == "buff" then info = resolve("spell", o.id)
    elseif o.kind == "item" or o.kind == "itembuff" then info = resolve("item", o.id) end
    if info then
      if o.need then info.want = o.need end
      if not Data.FindDuplicate(db.self, info) then
        db.self[#db.self + 1] = Data.MakeEntry(db, info, 2)
        added = added + 1
      end
    end
  end
  db.importedKlarsjekk = true
  return added
end

------------------------------------------------------------------------
-- Testdata (SPEC §19): /control test blar gjennom dem
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
