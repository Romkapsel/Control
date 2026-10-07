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

-- WoW Forever (Daniel 7. okt): GetWeaponEnchantInfo svarer «ingenting» selv med Flametongue på – tooltipen sier det
T.wench = nil
T.slotTips = { [16] = { "Gnarled Ash Staff", "Two-Hand", "Flametongue 3 (60 min)", "Durability 40 / 40" } }
local st2 = ns.Scan.State(db, {})
check(st2[ft.id].status == "on" and st2[ft.id].left and st2[ft.id].left > 3500, "fra tooltipen: Flametongue er på, 60 min")
T.slotTips[16][3] = "Flametongue 3 (30 sec)"
st2 = ns.Scan.State(db, {})
check(st2[ft.id].status == "expiring" and st2[ft.id].left <= 30, "30 sek igjen: snart ute")
T.slotTips[16] = { "Gnarled Ash Staff", "Two-Hand", "Durability 40 / 40" }
st2 = ns.Scan.State(db, {})
check(st2[ft.id].status ~= "on", "borte fra tooltipen: ikke på lenger")
-- Linjer som ligner, men ikke er en forsterkning, teller ikke
T.slotTips[16] = { "Gnarled Ash Staff", "Use: Restores mana (5 Min Cooldown)" }
check(ns.Scan.WeaponTipEnchant(16) == false, "«(5 Min Cooldown)» er ikke en forsterkning")
-- /ctrl våpen viser tooltipen
-- Akkurat slik det sto hos Daniel (7. okt)
T.slotTips[16] = { "Heavy Copper Maul", "Soulbound", "Two-Hand", "28 - 43 Damage", "(10.8 damage per second)", "+4 Strength",
                   "Flametongue 1 (59 min)", "Durability 55 / 55", "Requires Level 11", "Sell Price: 595" }
local left = ns.Scan.WeaponTipEnchant(16)
eq(left, 59 * 60, "Daniels maul: Flametongue 1 (59 min)")
T.slotTips[16] = { "Gnarled Ash Staff", "Flametongue 3 (60 min)" }
SlashCmdList.CONTROL("våpen")
check(Chat("Tooltip MH: Gnarled Ash Staff | Flametongue 3 (60 min)"), "våpen: tooltip-linjene")
check(Chat("  → forsterkning: Flametongue 3 (60 min) = 3600 s"), "våpen: hva Control leser ut av den")
T.slotTips = nil

-- Flere forsterkninger samtidig (Daniel 7. okt: «Forever rocker på dette» – Flametongue 60 m og Weightstone 30 m på samme
-- maul). Hver knapp finner sin egen linje i tooltipen.
local frost = db.self[3] -- Frostbrand
T.slotTips = { [16] = { "Heavy Copper Maul", "Two-Hand", "Flametongue 1 (59 min)", "Weighted (+2 Damage) (30 min)",
                        "Durability 55 / 55" } }
local s3 = ns.Scan.State(db, {})
check(s3[ft.id].status == "on" and math.abs(s3[ft.id].left - 59 * 60) < 2, "Flametongue: 59 min")
check(s3[stone.id].status == "on" and math.abs(s3[stone.id].left - 30 * 60) < 2, "Weightstone: 30 min (sin egen linje)")
check(s3[frost.id].status ~= "on", "Frostbrand er ikke på, selv om hånda har andre ting")
-- Flametongue går ut: bare den mangler
T.slotTips[16] = { "Heavy Copper Maul", "Weighted (+2 Damage) (12 min)" }
s3 = ns.Scan.State(db, {})
check(s3[ft.id].status ~= "on" and s3[stone.id].status == "on", "Flametongue borte, Weightstone står")
-- Et navn som ikke ligner: lært første gang du bruker knappen
local odd = { id = "e99", type = "buffitem", tier = 1, itemId = 9999, name = "Odd Stone", castName = "Odd", weaponSlot = 16,
              auraNames = {}, want = 1 }
table.insert(db.self, odd)
s3 = ns.Scan.State(db, {})
eq(s3[odd.id].status, "missing", "Odd Stone: ikke på")
ns.Scan.Confirm(odd, db.durations)
T.slotTips[16] = { "Heavy Copper Maul", "Weighted (+2 Damage) (12 min)", "Sharpened (+3 Damage) (30 min)" }
s3 = ns.Scan.State(db, {})
eq(odd.enchantKey, "sharpened", "lært: «Sharpened» hører til Odd Stone")
check(s3[odd.id].status == "on" and s3[stone.id].status == "on", "begge på, hver med sin linje")
T.slotTips[16] = { "Heavy Copper Maul", "Weighted (+2 Damage) (11 min)" }
s3 = ns.Scan.State(db, {})
check(s3[odd.id].status ~= "on", "Sharpened borte: Odd Stone ikke på")
-- I kamp kan tooltipen være hemmelig: vet ikke, teller videre (ikke «mangler»)
T.slotTips[16] = { "Heavy Copper Maul", "Weighted (+2 Damage) (11 min)" }
ns.Scan.State(db, {})
T.secret = true
s3 = ns.Scan.State(db, {})
check(s3[stone.id].status == "on", "hemmelig tooltip: Weightstone fortsatt på (teller videre)")
T.secret = false
T.slotTips = nil
table.remove(db.self)

return n, fails
