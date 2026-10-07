-- Våpenbuffer som sto som manglende (Daniel 7. okt, shaman): Flametongue Weapon er en spell, men ligger på våpenet – ikke
-- som en buff på deg. Og en slipestein som ble lagret før spillet hadde lastet tooltipen, ble aldri en våpenbuff.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

T.spellNames[8024] = "Flametongue Weapon"
T.spellNames[8033] = "Frostbrand" -- (tenkt navn uten «Weapon»: kjennes på beskrivelsen)
T.spellNames[6673] = "Battle Shout"
local desc = { [8024] = "Imbue the Shaman's weapon with fire, increasing total spell damage by 5.",
               [8033] = "Imbue the Shaman's weapon with frost.",
               [6673] = "The warrior shouts, increasing the melee attack power of all party members." }
C_Spell.GetSpellDescription = function(id) return desc[id] end
-- Weightstone, lagret med en eldre versjon som vanlig buffting (uten våpen) – slik det skjedde når tooltipen ikke var lastet
T.itemNames[3241] = "Heavy Weightstone"
T.itemSpells[3241] = { "Weighted", 3114 }
T.itemClass[3241] = { 0, 6 }
T.tooltips[3241] = { "Heavy Weightstone", "Use: Increase the damage of a blunt weapon by 2 for 30 minutes." }
T.counts[3241] = 5
ControlCharDB = { self = {
  { id = "e1", type = "buffitem", tier = 1, itemId = 3241, name = "Heavy Weightstone", castName = "Weighted",
    auraNames = { "Weighted" }, want = 1 },
}, party = {} }

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
local db = ControlCharDB
local stone = db.self[1]
check(stone.weaponSlot == 16 and #stone.auraNames == 0 and stone.cat == "weapon", "slipesteinen er rettet ved innlogging: våpenbuff på hovedhånda")

-- Flametongue Weapon på medaljongen: våpenbuff (navnet slutter på «Weapon»)
T.cursor = { "spell", 3, "spell", 8024 }
ns.Medallion.State().hit.scripts.OnReceiveDrag(ns.Medallion.State().hit)
local ft = db.self[2]
check(ft and ft.type == "spell" and ft.weaponSlot == 16, "Flametongue Weapon: spell på hovedhånda")
check(#ft.auraNames == 0 and ft.cat == "weapon", "leses fra våpenet, kategori Utbedring")
-- Kjennes også på beskrivelsen
T.cursor = { "spell", 4, "spell", 8033 }
ns.Actions.DropOn(false, 2)
check(db.self[3].weaponSlot == 16, "«Imbue … weapon» i beskrivelsen: våpenbuff")
-- Battle Shout er en vanlig buff
T.cursor = { "spell", 5, "spell", 6673 }
ns.Actions.DropOn(false, 2)
local bs = db.self[4]
check(not bs.weaponSlot and bs.auraNames[1] == "Battle Shout" and bs.cat == "buffs", "Battle Shout: vanlig buff")

-- Ingenting på våpenet: begge mangler
ns.Refresh(true)
local st = ns.model and ns.Scan.State(db, {})
eq(st[ft.id].status, "missing", "uten forsterkning: Flametongue mangler")
eq(st[stone.id].status, "missing", "uten forsterkning: slipesteinen mangler")
-- Flametongue på våpenet (Daniel: «den var på»): nå er den på
T.wench = { mh = 300 * 1000 }
st = ns.Scan.State(db, {})
check(st[ft.id].status ~= "missing" and st[ft.id].left and st[ft.id].left > 290, "på våpenet: Flametongue er på, 5 min igjen")
check(st[stone.id].status ~= "missing", "slipesteinen leser det samme våpenet")
-- Knappen kaster spellen (ikke en makro som for ting)
ns.Refresh(true)
local btn
for _, b in ipairs(ns.Tray.Get("right").buttons) do if b.entry == ft then btn = b end end
T.wench = nil
ns.Refresh(true)
for _, b in ipairs(ns.Tray.Get("right").buttons) do if b.entry == ft and b.shown then btn = b end end
check(btn and btn:GetAttribute("type") == "spell" and btn:GetAttribute("spell") == "Flametongue Weapon", "knappen kaster Flametongue Weapon")

-- /ctrl våpen: hva spillet sier om våpenet og buffene, rett i chatten
T.wench = { mh = 300 * 1000 }
T.auras = { { "Lightning Shield", 324, T.now + 600, 600 } }
SlashCmdList.CONTROL("våpen")
check(Chat("Våpen (GetWeaponEnchantInfo): true, 300000, 0, 0, false"), "våpen: rådata fra spillet")
check(Chat("Buffer på deg: Lightning Shield (324)"), "buffene dine med navn og id")
check(ControlCharDB.debug.weaponProbe and ControlCharDB.debug.weaponProbe.raw[1] == "true", "lagret til lagringsfila")

return n, fails
