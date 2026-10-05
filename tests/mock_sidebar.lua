-- Fase 4: sidemenyene (SPEC §7.4, §6.6, §8): åpne/lukke, rader, fure, tomme ruter, statuslinje,
-- høyreklikk = tier, musehjul = antall, slipp inn, Shift + dra ut = fjern, dra på en annen = flytt, /control angre.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local M = ns.Medallion
local st = M.State()
local mb, pb = ns.SideBar.Get("right"), ns.SideBar.Get("left") -- mine til høyre, gruppa til venstre
check(mb and pb and not mb.frame.shown and not pb.frame.shown, "sidemenyene er lukket fra start")
check(mb.frame.points[1][4] == 32, "samme forankring som knappene: medaljongens midtpunkt")

-- Klikk høyre sone: fold ut mine
local function mouse(dx, dy) T.mouse = { T.center[1] + dx, T.center[2] + dy } end
mouse(20, 0)
st.hit.scripts.OnEnter(st.hit)
eq(T.tooltip.text, "Fold ut mine buffer", "tooltip før")
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(mb.frame.shown, "høyre sone folder ut mine")
eq(T.tooltip.text, "Fold inn mine buffer", "tooltip etter")
check(mb.slots[1].shown and mb.slots[1].plus.shown and mb.slots[1].hint == "Dra en spell eller en ting fra baggen hit",
  "tom side: én slipprute med «+» og hjelpetekst")
check(not (mb.slots[2] and mb.slots[2].shown), "tom side: bare én rute")
eq(mb.frame.width, 40 + 46, "tom side: bredde")
eq(mb.status.text, "", "tom side: ingen statuslinje (får ikke plass)")

-- Slipp på sidemenyen: sist i tier II
T.cursor = { "spell", 3, "spell", 5232 }
mb.frame.scripts.OnReceiveDrag(mb.frame)
local motw = ControlCharDB.self[1]
check(motw and motw.tier == 2 and Chat("Mark of the Wild er lagt til (tier II)"), "spell sluppet på sidemenyen havner i tier II")
T.counts[13510] = 3
T.cursor = { "item", 13510, "[Flask]" }
mb.slots[1].scripts.OnReceiveDrag(mb.slots[1])
local flask = ControlCharDB.self[2]
check(flask and flask.tier == 2 and flask.type == "buffitem", "item sluppet på den tomme ruta: tier II")
eq(ns.view.ring, 1, "tier II som mangler: oransje")
check(#mb.ids == 2 and mb.buttons[1].entry == motw and mb.buttons[2].entry == flask, "knappene i lista sin rekkefølge")
eq(mb.frame.width, 40 + 3 * 46, "2 knapper + én «+»-rute: sida vokser én og én")
check(not mb.vA.shown, "bare tier II: ingen fure")
check(mb.status.text:find("Mangler", 1, true) and mb.status.text:find("MotW", 1, true) and mb.status.text:find("Flask", 1, true),
  "statuslinja: Mangler MotW · Flask")
check(not ns.Tray.Get("right").frame.shown, "sidemenyen dekker knappene ved medaljongen")

-- Høyreklikk MotW: tier I. Fure kommer, MotW blir rød.
local b1 = mb.buttons[1]
b1.scripts.hookPostClick(b1, "RightButton")
eq(motw.tier, 1, "høyreklikk: tier I")
eq(ns.view.ring, 2, "tier I som mangler: rød")
check(mb.vA.shown, "tier I og II: fure mellom")
eq(mb.frame.width, 40 + 3 * 46 + 12, "bredde med fure")
local p2 = mb.buttons[2].points[#mb.buttons[2].points]
eq(p2[4], 2 + 36 + 46 + 12, "tier II starter etter fura")
b1.scripts.hookOnEnter(b1)
local found = false
for _, l in ipairs(T.tooltip.lines) do if l == "Høyreklikk: bytt tier (nå I)" then found = true end end
check(found, "tooltip: høyreklikk-hjelp med tier")

-- Musehjul på flasken: ønsket antall
local b2 = mb.buttons[2]
b2.scripts.OnMouseWheel(b2, 1)
eq(flask.want, 2, "hjul opp: 2")
T.shift = true
b2.scripts.OnMouseWheel(b2, 1)
T.shift = false
eq(flask.want, 7, "Shift + hjul: +5")
for _ = 1, 20 do b2.scripts.OnMouseWheel(b2, -1) end
eq(flask.want, 1, "aldri under 1")
b1.scripts.OnMouseWheel(b1, 1)
check(motw.want == nil, "hjul på en spell gjør ingenting")

-- Dra uten Shift: ingenting (et vanlig dra ville kastet). Med Shift: ut av sidemenyen = fjernet.
b2.scripts.OnDragStart(b2)
b2.scripts.OnDragStop(b2)
eq(#ControlCharDB.self, 2, "dra uten Shift: ingenting skjer")
check(b2:GetAttribute("shift-type1") == "", "Shift + klikk kaster ikke")
T.shift = true
b2.scripts.OnDragStart(b2)
mb.frame.mouse = false
b2.scripts.OnDragStop(b2)
T.shift = false
eq(#ControlCharDB.self, 1, "Shift + dra ut: flasken er fjernet")
check(Chat("Flask of the Titans er fjernet. Skriv /control angre"), "sier fra i chatten")
SlashCmdList.CONTROL("angre")
check(#ControlCharDB.self == 2 and ControlCharDB.self[2] == flask and Chat("er tilbake på lista"), "/control angre: tilbake på samme plass")
SlashCmdList.CONTROL("angre")
check(Chat("Ingenting å angre"), "angre to ganger")

-- Shift + dra flasken (tier II) på MotW (tier I): flytter dit og tar tier I
mb.frame.mouse = true
T.shift = true
local fb = mb.buttons[2]
fb.scripts.OnDragStart(fb)
mb.buttons[1].mouse = true
fb.scripts.OnDragStop(fb)
mb.buttons[1].mouse = false
T.shift = false
check(ControlCharDB.self[1] == flask and flask.tier == 1, "flasken flyttet først og har tatt tier I")

-- Lukk igjen
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(not mb.frame.shown, "klikk igjen: folder inn")
check(ns.Tray.Get("right").frame.shown, "knappene ved medaljongen er tilbake")

-- Gruppesiden: en spell blir gruppebuff; et item avvises
mouse(-20, 0)
M.TrackMouse()
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(pb.frame.shown and pb.slots[1].hint == "Dra en buff du kan gi, eller en scroll, hit", "gruppesiden åpnes med egen hjelpetekst")
T.cursor = { "spell", 3, "spell", 1126 }
pb.frame.scripts.OnReceiveDrag(pb.frame)
local g = ControlCharDB.party[1]
check(g and g.type == "partyspell" and g.tier == 2 and g.groupSpell == "Gift of the Wild", "gruppebuff med gruppeversjon")
check(pb.status.text:find("Party buffs", 1, true) and not pb.status.text:find("Alle", 1, true), "gruppesiden: bare «Party buffs»")
T.cursor = { "item", 13510, "[Flask]" }
pb.frame.scripts.OnReceiveDrag(pb.frame)
eq(#ControlCharDB.party, 1, "item på gruppesiden avvises")

-- Kamp: ingen åpning/lukking, ingen hjul, ingen tier-bytte; sverd i siste tomme rute
mouse(20, 0)
M.TrackMouse()
st.hit.scripts.OnMouseUp(st.hit, "LeftButton") -- åpne mine igjen
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(mb.frame.shown, "i kamp: sidemenyen kan ikke lukkes")
local before = flask.want
mb.buttons[1].scripts.OnMouseWheel(mb.buttons[1], 1)
eq(flask.want, before, "i kamp: hjulet gjør ingenting")
mb.buttons[1].scripts.hookPostClick(mb.buttons[1], "RightButton")
eq(flask.tier, 1, "i kamp: høyreklikk bytter ikke tier")
local last
for _, s in ipairs(mb.slots) do if s.shown then last = s end end
check(last and last.swords[1].alpha == 1, "i kamp: sverd i siste tomme rute")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
check(last.swords[1].alpha == 0, "etter kamp: ingen sverd")
return n, fails
