-- Kategorier (Daniel 5. okt): det som ble lagt inn før kategoriene fantes, får kategori ved innlogging.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

T.itemNames[2000] = "Robe of Healing"
T.itemClass[2000] = { 4, 1 } -- rustning
ControlCharDB = { self = {
  { id = "e1", type = "spell", tier = 1, name = "Mark of the Wild", spellId = 5232 },
  { id = "e2", type = "buffitem", tier = 1, itemId = 13510, name = "Flask of the Titans", castName = "Flask of the Titans" },
  { id = "e3", type = "item", tier = 2, itemId = 14529, name = "Runecloth Bandage" },
  { id = "e4", type = "item", tier = 2, itemId = 13446, name = "Major Healing Potion" },
  { id = "e5", type = "item", tier = 1, itemId = 2000, name = "Robe of Healing" },
  { id = "e6", type = "buffitem", tier = 2, itemId = 21023, name = "Dirge's Kickin' Chimaerok Chops" },
}, party = {} }
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local cat = {}
for _, e in ipairs(ControlCharDB.self) do cat[e.id] = e.cat end
eq(cat.e1, "buffs", "spell: Buffer")
eq(cat.e2, "flasks", "flask: Flasks og eliksirer")
eq(cat.e3, "bandages", "bandasje: Bandasjer")
eq(cat.e4, "potions", "potion: Potions")
eq(cat.e5, "gear", "rustning: Utstyr")
eq(cat.e6, "food", "mat: Mat og drikke")
-- I menyen: overskriftene i rekkefølge, bare de som har noe
ns.Menu.SetOpen(true)
ns.Refresh(false)
local order = {}
for _, b in ipairs(ns.Menu.host.buttons) do order[#order + 1] = b.entry.cat end
eq(table.concat(order, ","), "buffs,flasks,food,potions,bandages,gear", "menyen: Buffer, Flasks, Mat, Potions, Bandasjer, Utstyr")

-- Utstyr: musehjulet gjør ingenting, og «1» står ikke på knappen
T.counts[2000] = 1
ns.Refresh(false)
local robe
for _, b in ipairs(ns.Menu.host.buttons) do if b.entry.cat == "gear" then robe = b end end
robe.scripts.OnMouseWheel(robe, 1)
eq(robe.entry.want or 1, 1, "hjul på utstyr: fortsatt 1")
eq(robe.time.text, "", "utstyr du har: ingen «1»")
robe.scripts.hookOnEnter(robe)
local wheel = false
for _, l in ipairs(T.tooltip.lines) do if l:find("Hjul", 1, true) then wheel = true end end
check(not wheel, "tooltip sier ikke noe om hjulet")
T.counts[2000] = 0
ns.Refresh(false)
check(robe.bandText.text == "0/1", "utstyr som mangler: 0/1")

return n, fails
