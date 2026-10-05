-- Utstyret i settet (Daniel 5. okt): «Ta på» ved Utstyr i menyen, og beskjed når du bytter sett.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

-- Healing-utstyr: en robe, to ringer, en trinket og en enhånds mace
T.itemNames[3001] = "Robe of Healing"
T.itemNames[3002] = "Ring of Mending"
T.itemNames[3003] = "Band of Grace"
T.itemNames[3004] = "Idol of Light"
T.itemNames[3005] = "Mace of Mercy"
T.itemNames[3006] = "Lost Gloves"
T.itemClass[3001] = { 4, 1, "INVTYPE_ROBE" }
T.itemClass[3002] = { 4, 0, "INVTYPE_FINGER" }
T.itemClass[3003] = { 4, 0, "INVTYPE_FINGER" }
T.itemClass[3004] = { 4, 0, "INVTYPE_TRINKET" }
T.itemClass[3005] = { 2, 4, "INVTYPE_WEAPON" }
T.itemClass[3006] = { 4, 1, "INVTYPE_HAND" }
T.slotOf = { [3001] = 5, [3006] = 10 }
for id = 3001, 3005 do T.counts[id] = 1 end
T.counts[3006] = 0
-- På deg nå: ring 3002 på plass 12, en annen ring (9999) på 11, en annen trinket på 13
T.equip = { [11] = 9999, [12] = 3002, [13] = 8888 }
T.dura = { [5] = { 100, 100 } }

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
for _, id in ipairs({ 3001, 3002, 3003, 3004, 3005, 3006 }) do
  T.cursor = { "item", id, "[" .. T.itemNames[id] .. "]" }
  ns.Actions.DropOn(false, 2)
end
T.cursor = nil
local db = ControlCharDB
eq(#db.self, 6, "seks ting lagt til")
local allGear = true
for _, e in ipairs(db.self) do if e.cat ~= "gear" then allGear = false end end
check(allGear, "alle står under Utstyr")

-- Planen: ringen som sitter, får stå; den andre ringen går på 11 (ikke over den første på 12)
local plan = ns.Core.GearPlan(db.self)
eq(plan.total, 6, "seks utstyrsting i settet")
eq(#plan.todo, 4, "fire skal på (ringen på 12 er alt på)")
eq(#plan.missing, 1, "hanskene er ikke i baggen")
local slotFor = {}
for _, t in ipairs(plan.todo) do slotFor[t.e.itemId] = t.slot or "auto" end
eq(slotFor[3003], 11, "andre ring: plass 11")
eq(slotFor[3004], 13, "trinket: første ledige trinketplass")
eq(slotFor[3005], 16, "enhånds våpen: hovedhånda")
eq(slotFor[3001], "auto", "robe: spillet velger plassen")

-- Menyen: «Ta på» ved Utstyr, på når noe kan tas på
ns.Menu.SetOpen(true)
ns.Refresh(false)
local b = ns.Menu.equipButton
check(b and b.shown and b.enabled and b.text == "Ta på", "menyen: «Ta på» ved Utstyr")
eq(b.tip, "Ta på utstyret i settet (4 ting).", "tooltip: hvor mange")

-- Ikke i kamp
T.combat = true
ns.Actions.EquipSet()
check(not T.equipCalls, "i kamp: ingenting tas på")
check(Chat("Ikke i kamp."), "i kamp: melding")
T.combat = false

-- Klikk: alt som finnes, tas på, på riktig plass
b.scripts.OnClick(b, "LeftButton")
eq(T.equipCalls and #T.equipCalls, 4, "fire ting tas på")
check(T.equip[11] == 3003 and T.equip[12] == 3002, "ringene: begge på, den første ble stående")
check(T.equip[13] == 3004 and T.equip[16] == 3005 and T.equip[5] == 3001, "trinket, mace og robe er på")
check(Chat("Tar på: Robe of Healing, Band of Grace, Idol of Light, Mace of Mercy."), "melding: hva som tas på")
check(Chat("Ikke i baggen: Lost Gloves."), "melding: hva som mangler")
Fire("PLAYER_EQUIPMENT_CHANGED")
b = ns.Menu.equipButton
check(b and not b.enabled, "alt som finnes er på: knappen er grå")
eq(b.tip, "Det som mangler, er ikke i baggen.", "tooltip: resten er ikke i baggen")

-- Klikk igjen når alt er på (hanskene fjernet fra settet)
for i, e in ipairs(db.self) do if e.itemId == 3006 then table.remove(db.self, i) break end end
T.equipCalls = nil
ns.Actions.EquipSet()
check(not T.equipCalls and Chat("Utstyret i Solo er på."), "alt er på: bare beskjed")

-- Beskjed når du bytter sett: tittel med settnavnet, utstyr som ikke er på, reparasjon – og ingen lyd
ns.Actions.NewSet("Healing")
T.equip = { [11] = 9999, [13] = 8888 } -- tok av healing-utstyret
T.dura = { [5] = { 40, 100 } }
ns.Actions.UseSet("Solo")
local sounds = ns.Alert.sounds or 0
ns.Actions.UseSet("Healing")
eq(ns.Alert.title.text, "Sett: Healing", "varsel: tittel med settet")
local main = ns.Alert.main.text or ""
check(main:find("Utstyr på", 1, true) and main:find("0/5", 1, true), "varsel: «Utstyr på 0/5»")
check(main:find("Reparasjon", 1, true) and main:find("40%", 1, true), "varsel: reparasjon 40 %")
eq(ns.Alert.sev, 2, "varsel: rødt (reparasjon under 50 %)")
eq(ns.Alert.sounds or 0, sounds, "bytte sett: ingen «Watch it!»")
-- Alt i orden: grønt
T.equip = { [5] = 3001, [11] = 3003, [12] = 3002, [13] = 3004, [16] = 3005 }
T.dura = { [5] = { 100, 100 } }
ns.Actions.UseSet("Solo")
eq(ns.Alert.sev, 0, "alt i orden: grønt varsel")

return n, fails
