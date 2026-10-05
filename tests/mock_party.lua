-- Fase 5: gruppebuffene (SPEC §7.5, §9). Akseptkriteriet: MotW til en kompis – ruta fylles, knappen borte
-- når alle har den. Pluss: Gift of the Wild når flere enn 2 mangler, ukjente medlemmer, og kamp.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

T.spellNames[21849] = "Gift of the Wild"
T.party = { party1 = "Brakk" }
T.pa = { party1 = {} }
T.partyClass = { party1 = "WARRIOR" }
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local M = ns.Medallion
local st = M.State()
local pb = ns.SideBar.Get("left") -- gruppa til venstre
local tray = ns.Tray.Get("left")
local function mouse(dx, dy) T.mouse = { T.center[1] + dx, T.center[2] + dy } end
local function toggleParty() mouse(-20, 0) M.TrackMouse() st.hit.scripts.OnMouseUp(st.hit, "LeftButton") end

-- Slipp MotW på gruppesiden
toggleParty()
check(pb.frame.shown, "gruppesiden er åpen")
T.cursor = { "spell", 3, "spell", 1126 }
pb.frame.scripts.OnReceiveDrag(pb.frame)
local g = ControlCharDB.party[1]
check(g and g.type == "partyspell", "MotW er gruppebuff")
local s = ns.model.st[g.id]
eq(#s.members, 1, "ett medlem følges")
check(s.members[1].name == "Brakk" and s.members[1].has == false and s.members[1].class == "WARRIOR", "Brakk mangler MotW")
eq(#s.missingOn, 1, "én mangler")
check(s.cast and s.cast.spell == "Mark of the Wild" and not s.cast.group and s.cast.target.unit == "party1", "kaster MotW på Brakk")
eq(ns.view.ring, 1, "tier II som mangler på en kompis: oransje")

local b = pb.buttons[1]
check(b.shown and b.entry == g, "knappen står i sidemenyen")
check(b:GetAttribute("type") == "spell" and b:GetAttribute("spell") == "Mark of the Wild" and b:GetAttribute("unit") == "party1",
  "knappen kaster MotW på party1, etter navn")
check(b.glowing, "gløder når noen mangler")
check(b.partyBand and b.partyBand.shown and b.squares[1].edge.shown, "én rute i båndet nederst")
eq(b.squares[1].edge.color[1], ns.Style.C.gold[1], "tom rute med gul kant: mangler")

-- Tooltip: hvem som mangler, og hva klikket gjør
b.scripts.hookOnEnter(b)
local function hasLine(t) for _, l in ipairs(T.tooltip.lines) do if l == t then return true end end return false end
check(hasLine("1 av 1 mangler") and hasLine("Klikk: kast på Brakk"), "tooltip: hvem som mangler og hva klikket gjør")

-- Tier I: står ute ved medaljongen når sidemenyen er lukket
b.scripts.hookPostClick(b, "RightButton")
eq(g.tier, 1, "høyreklikk: tier I")
eq(ns.view.ring, 2, "tier I som mangler: rød")
toggleParty()
check(not pb.frame.shown, "gruppesiden lukket")
check(tray.frame.shown and #tray.ids == 1 and tray.ids[1] == g.id, "MotW står ute på gruppesiden av medaljongen")
local tb = tray.buttons[1]
eq(tb:GetAttribute("unit"), "party1", "knappen ved medaljongen kaster på Brakk")

-- Klikk: kastet bekreftes, buffen kommer på Brakk, ruta fylles og knappen forsvinner
tb.scripts.hookPreClick(tb, "LeftButton")
check(ns.Track.Pending() and ns.Track.Pending().cast.target.name == "Brakk", "trykket husker målet")
T.pa.party1 = { { "Mark of the Wild", 1126, T.now + 1800, 1800 } }
Fire("UNIT_SPELLCAST_SENT", "player", "Brakk", "c1", 1126)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c1", 1126)
check(ns.Track.Pending() == nil, "kastet er bekreftet")
s = ns.model.st[g.id]
check(s.members[1].has == true and #s.missingOn == 0 and s.cast == nil, "Brakk har MotW")
check(ns.view.allOk, "alt i orden")
check(not tray.frame.shown or #tray.ids == 0, "knappen er borte når alle har den")
eq(ControlCharDB.durations["Mark of the Wild"], 1800, "varigheten huskes")

-- Gift of the Wild når flere enn 2 mangler, og spillet sier den kan kastes
T.party = { party1 = "Brakk", party2 = "Mira", party3 = "Tok" }
T.pa = { party1 = {}, party2 = {}, party3 = {} }
T.partyClass = { party1 = "WARRIOR", party2 = "MAGE", party3 = "WARRIOR" }
Fire("GROUP_ROSTER_UPDATE")
s = ns.model.st[g.id]
eq(#s.missingOn, 3, "tre mangler")
check(s.cast and s.cast.group and s.cast.spell == "Gift of the Wild", "3 mangler: Gift of the Wild")
tb = tray.buttons[1]
eq(tb:GetAttribute("spell"), "Gift of the Wild", "knappen er satt opp med gruppeversjonen")
T.usable = { ["Gift of the Wild"] = false }
ns.Refresh(true)
s = ns.model.st[g.id]
check(s.cast and not s.cast.group and s.cast.spell == "Mark of the Wild", "uten reagens: enkeltversjonen")
eq(tray.buttons[1]:GetAttribute("spell"), "Mark of the Wild", "knappen byttet tilbake")
T.usable = nil
T.pa.party3 = { { "Mark of the Wild", 1126, T.now + 1800, 1800 } }
ns.Refresh(true)
s = ns.model.st[g.id]
check(s.cast and not s.cast.group and s.cast.target.name == "Brakk", "2 mangler: enkeltversjonen på den første")

-- Gruppeversjonen bekreftet: alle regnes som buffet
T.pa = { party1 = {}, party2 = {}, party3 = {} }
ns.Refresh(true)
tb = tray.buttons[1]
eq(tb:GetAttribute("spell"), "Gift of the Wild", "tilbake til gruppeversjonen")
tb.scripts.hookPreClick(tb, "LeftButton")
T.combat, T.secret = true, true -- kampen starter mens kastet går: buffene kan ikke leses
Fire("PLAYER_REGEN_DISABLED")
eq(tray.buttons[1].alpha, 0.45, "i kamp: dempet, vi ser ikke hvem som har den")
Fire("UNIT_SPELLCAST_SENT", "player", "", "c2", 21849)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c2", 21849)
s = ns.model.st[g.id]
check(#s.missingOn == 0 and s.members[2].has == true, "Gift of the Wild bekreftet: alle har den, også i kamp")
eq(tray.buttons[1]:GetAttribute("spell"), "Gift of the Wild", "ingen attributter endret i kamp")
eq(tray.buttons[1].alpha, 0, "alle har den: knappen tones bort i kamp")

-- Etter kampen: les på nytt
T.combat, T.secret = false, false
T.pa = { party1 = {}, party2 = { { "Gift of the Wild", 21849, T.now + 3600, 3600 } }, party3 = {} }
Fire("PLAYER_REGEN_ENABLED")
s = ns.model.st[g.id]
eq(#s.missingOn, 2, "etter kampen: det spillet sier gjelder")
check(s.members[2].has == true, "Gift of the Wild teller som MotW")

-- Ukjente medlemmer: offline, død og ute av syne telles ikke som mangler
T.offline = { party1 = true }
T.deadUnits = { party3 = true }
ns.Refresh(true)
s = ns.model.st[g.id]
check(s.members[1].has == nil and s.members[3].has == nil, "offline og død: ukjent")
eq(#s.missingOn, 0, "ukjente telles ikke")
tb = tray.buttons[1]
check(not tray.frame.shown or #tray.ids == 0, "ingen å kaste på: knappen borte")
T.offline, T.deadUnits = nil, nil
T.hidden = { party1 = true }
ns.Refresh(true)
s = ns.model.st[g.id]
check(s.members[1].has == false, "ute av syne: det vi visste sist (manglet)")
T.hidden = nil

-- Uten party: ingen medlemmer, ingenting mangler
T.party = {}
Fire("GROUP_ROSTER_UPDATE")
s = ns.model.st[g.id]
eq(#s.members, 0, "alene: ingen ruter")
check(ns.view.allOk, "alene: alt i orden")
check(not tray.frame.shown or #tray.ids == 0, "alene: ingen knapp ute")
toggleParty()
check(pb.status.text:find("Party", 1, true) and not pb.status.text:find("Alle", 1, true), "alene: bare «Party», ingen påstand om gruppa")
check(not pb.buttons[1].glowing, "alene: ingenting lyser")

-- Scroll på gruppesiden: brukes på den som mangler (Daniel 5. okt)
T.itemNames[1711] = "Scroll of Stamina II"
T.itemSpells[1711] = { "Stamina", 8099 }
T.itemClass[1711] = { 0, 4 }
T.spellNames[8099] = "Stamina"
T.counts[1711] = 2
T.party = { party1 = "Brakk" }
T.pa = { party1 = {} }
Fire("GROUP_ROSTER_UPDATE")
T.cursor = { "item", 1711, "[Scroll of Stamina II]" }
pb.frame.scripts.OnReceiveDrag(pb.frame)
local sc = ControlCharDB.party[2]
check(sc and sc.type == "partyitem" and sc.castName == "Stamina" and sc.auraNames[1] == "Stamina", "scrollen er en gruppebuff")
s = ns.model.st[sc.id]
check(s.cast and s.cast.target.unit == "party1" and s.count == 2, "scrollen brukes på Brakk, 2 på lager")
local sb = pb.buttons[2].entry == sc and pb.buttons[2] or pb.buttons[1]
check(sb.entry == sc and sb:GetAttribute("type") == "item" and sb:GetAttribute("item") == "item:1711" and sb:GetAttribute("unit") == "party1",
  "knappen bruker scrollen på party1")
check(sb.glowing and sb.stock.text == "2", "gløder, og viser hvor mange du har")
sb.scripts.hookPreClick(sb, "LeftButton")
T.pa.party1 = { { "Mark of the Wild", 1126, T.now + 1800, 1800 }, { "Stamina", 8099, T.now + 1800, 1800 } }
T.counts[1711] = 1
Fire("UNIT_SPELLCAST_SENT", "player", "Brakk", "c3", 8099)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c3", 8099)
s = ns.model.st[sc.id]
check(#s.missingOn == 0 and s.count == 1 and not sb.glowing, "Brakk har Stamina, én scroll igjen, ingenting lyser")
T.pa.party1 = { { "Mark of the Wild", 1126, T.now + 1800, 1800 } }
T.counts[1711] = 0
ns.Refresh(true)
check(not sb.glowing and not ns.Rules.canPress(sc, ns.model.st[sc.id]), "tom for scrolls: ingenting å trykke")

-- Eliksirer og flasks kan ikke brukes på andre
T.cursor = { "item", 13510, "[Flask]" }
pb.frame.scripts.OnReceiveDrag(pb.frame)
check(#ControlCharDB.party == 2 and Chat("Bare scrolls kan brukes på andre"), "flask på gruppesiden avvises med forklaring")

return n, fails
