-- «Lag selv» (Daniel 5. okt): kan du lage tingen og har for få, viser tooltipen hva som trengs for å komme opp på
-- grønt (ikke for 1), og hva du har. Oppskriftene leses når yrkesvinduet er åpent, og huskes.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end
local function has(t) for _, l in ipairs(T.tooltip.lines) do if l == t then return true end end return false end
local function hasPrefix(p) for _, l in ipairs(T.tooltip.lines) do if l:sub(1, #p) == p then return true end end return false end

T.itemNames[2581] = "Heavy Linen Bandage"
T.itemNames[2589] = "Linen Cloth"
T.itemNames[2592] = "Wool Cloth"
T.itemClass[2581] = { 0, 7 }
T.counts[14529] = 3  -- Runecloth Bandage: 3 av 10
T.counts[2581] = 0   -- Heavy Linen Bandage: 0 av 5
T.counts[2589] = 4
T.counts[14047] = 12 -- Runecloth
T.itemNames[14047] = "Runecloth"

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
for _, id in ipairs({ 14529, 2581 }) do
  T.cursor = { "item", id, "[" .. T.itemNames[id] .. "]" }
  ns.Actions.DropOn(false, 2)
end
T.cursor = nil
local db = ControlCharDB
local rune, linen = db.self[1], db.self[2]
rune.want, linen.want = 10, 5
ns.Menu.SetOpen(true)
ns.Refresh(false)
local function hover(e)
  for _, b in ipairs(ns.Menu.host.buttons) do
    if b.entry == e then b.scripts.hookOnEnter(b) return end
  end
end

-- Før yrkesvinduet har vært åpent: ingenting om å lage
hover(rune)
check(not hasPrefix("Lag selv"), "uten oppskrifter: ingen «Lag selv»")

-- Åpne yrkesvinduet: oppskriftene leses (overskrifter hoppes over)
T.trade = {
  { name = "Bandasjer", header = true },
  { name = "Runecloth Bandage", out = 14529, made = 1, reagents = { { id = 14047, name = "Runecloth", n = 1 } } },
  { name = "Heavy Linen Bandage", out = 2581, made = 2, reagents = { { id = 2589, name = "Linen Cloth", n = 2 },
                                                                     { id = 2592, name = "Wool Cloth", n = 1 } } },
}
Fire("TRADE_SKILL_SHOW")
check(db.recipes and db.recipes[14529] and db.recipes[2581], "oppskriftene er husket")
check(not db.recipes.Bandasjer, "overskriften er ikke en oppskrift")
eq(db.debug.craft.api, "classic", "classic yrkes-API")
eq(db.debug.craft.read, 2, "to oppskrifter lest")

-- Runecloth Bandage: 3 av 10 → 7 ganger, du har 12 Runecloth – alt grønt
hover(rune)
check(has("Lag selv, 7 ganger (7 til):"), "7 ganger for å nå 10")
check(has("  Runecloth 12/7"), "Runecloth 12/7")

-- Heavy Linen Bandage: 0 av 5, gir 2 per gang → 3 ganger (6 til); 6 Linen og 3 Wool trengs
hover(linen)
check(has("Lag selv, 3 ganger (6 til):"), "3 ganger, 2 per gang")
check(has("  Linen Cloth 4/6") and has("  Wool Cloth 0/3"), "Linen 4/6, Wool 0/3")

-- Én gang holder: «1 gang»
T.counts[2581] = 4
Fire("BAG_UPDATE_DELAYED")
hover(linen)
check(has("Lag selv, 1 gang (2 til):"), "én gang igjen")

-- Grønt: ingenting om å lage (ikke for 1, bare opp til ønsket antall)
T.counts[14529] = 10
Fire("BAG_UPDATE_DELAYED")
hover(rune)
check(not hasPrefix("Lag selv"), "nok: ingen «Lag selv»")

-- Huskes etter at vinduet er lukket, og mister ikke det som ble lest før (sammenfelt gruppe neste gang)
T.trade = { { name = "Bandasjer", header = true } }
Fire("TRADE_SKILL_UPDATE")
check(db.recipes[14529] and db.recipes[2581], "sammenfelt neste gang: oppskriftene står")

-- Den nye API-en (C_TradeSkillUI): bare lærte oppskrifter, vanlige ingredienser
local classic = GetNumTradeSkills
GetNumTradeSkills = nil
C_TradeSkillUI = {
  GetAllRecipeIDs = function() return { 1, 2 } end,
  GetRecipeInfo = function(id) return { learned = id == 1, name = id == 1 and "Silk Bandage" or "Ukjent" } end,
  GetRecipeSchematic = function(id) return { outputItemID = id == 1 and 6450 or 9999, quantityMin = 1,
    reagentSlotSchematics = { { reagentType = 1, quantityRequired = 1, reagents = { { itemID = 4306 } } } } } end,
}
ns.Craft.Read(db)
GetNumTradeSkills = classic
C_TradeSkillUI = nil
eq(db.debug.craft.api, "ny", "ny yrkes-API")
check(db.recipes[6450] and db.recipes[6450].r[1].id == 4306 and not db.recipes[9999], "bare lærte oppskrifter")

return n, fails
