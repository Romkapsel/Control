-- Fase 6: menyen (SPEC §7.6). Delene, slipp inn i rad I/II, Shift + dra (flytt tier, fjern, angre),
-- fell sammen, hvem en gruppebuff følges på (Q7), byvakt, bytt sider, retning, og størrelse (slider, Daniel 5. okt):
-- bare medaljongen vokser, alt annet flytter seg utover.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local M, Menu = ns.Medallion, ns.Menu
local st = M.State()
local function mouse(dx, dy) T.mouse = { T.center[1] + dx, T.center[2] + dy } end
local function zoneClick(dx, dy) mouse(dx, dy) M.TrackMouse() st.hit.scripts.OnMouseUp(st.hit, "LeftButton") end
local function shown(list) local out = {} for _, x in ipairs(list) do if x.shown then out[#out + 1] = x end end return out end
local function findLink(text)
  for _, c in ipairs(Menu.frame.children or {}) do if c.shown and c.text == text and c.onClick then return c end end
end
local function slot(party, tier)
  for _, s in ipairs(Menu.host.slots) do if s.shown and s.drop.party == party and s.drop.tier == tier then return s end end
end

local cities = ControlCharDB.cityWatch.cities
check(#cities == 3 and cities[1] == "Stormwind City" and cities[3] == "Darnassus", "byvakt: Alliance-byene fra start")

-- Åpne med nedre sone
check(not Menu.IsOpen() and not Menu.frame.shown, "menyen er lukket fra start")
mouse(0, -20)
M.TrackMouse()
st.hit.scripts.OnEnter(st.hit)
eq(T.tooltip.text, "Åpne meny", "tooltip: Åpne meny")
zoneClick(0, -20)
eq(T.tooltip.text, "Lukke meny", "tooltip: Lukke meny")
zoneClick(0, -20)
zoneClick(0, -20)
check(Menu.IsOpen() and Menu.frame.shown, "nedre sone åpner menyen")
local p = Menu.frame.points[1]
check(p[1] == "TOP" and p[3] == "TOP" and p[5] == -70, "under medaljongen: 6 px luft (toppen 70 px under medaljongens topp)")
eq(Menu.frame.width, 356, "like bred som to sidemenyer med 2 knapper og 1 pluss")
local sb2 = ns.SideBar.Get("right")
eq(#Menu.heads, 4, "fire deler")
check(Menu.heads[1].title.text == "Meg" and Menu.heads[2].title.text == "Party"
  and Menu.heads[3].title.text == "Byvakt" and Menu.heads[4].title.text == "Oppsett", "delene i rekkefølge")
check(Menu.heads[1].right.text == "høyre" and Menu.heads[2].right.text == "venstre", "hvilken side de står på")
check(Menu.heads[4].pm.text == "", "Oppsett kan ikke felles sammen")

-- Slipp inn i rad I og rad II
check(slot(false, 1) and slot(false, 2) and slot(true, 1) and slot(true, 2), "tomme rader: én «+»-rute hver")
T.counts[13510] = 3
T.cursor = { "item", 13510, "[Flask of the Titans]" }
slot(false, 1).scripts.OnReceiveDrag(slot(false, 1))
local flask = ControlCharDB.self[1]
check(flask and flask.tier == 1 and Chat("Flask of the Titans lagt til i tier I."), "slipp i rad I: tier I")
T.cursor = { "spell", 3, "spell", 5232 }
slot(false, 2).scripts.OnReceiveDrag(slot(false, 2))
local motw = ControlCharDB.self[2]
check(motw and motw.tier == 2 and Chat("Mark of the Wild lagt til i tier II."), "slipp i rad II: tier II")
eq(#Menu.host.buttons, 2, "to knapper i menyen")
local bm = Menu.host.buttons[2]
check(bm.entry == motw and bm:GetAttribute("spell") == "Mark of the Wild", "knappen i menyen kaster som overalt ellers")
bm.scripts.hookOnEnter(bm)
local hasHint = false
for _, l in ipairs(T.tooltip.lines) do if l == "Tier II: bare i sidemenyen" then hasHint = true end end
check(hasHint, "tooltip i menyen forklarer tieren")

-- Shift + dra MotW til «+» i rad I: bytter tier
T.shift = true
bm.scripts.OnDragStart(bm)
Menu.frame.mouse = true
slot(false, 1).mouse = true
bm.scripts.OnDragStop(bm)
slot(false, 1).mouse = false
eq(motw.tier, 1, "dra til rad I: tier I")
-- Shift + dra ut av menyen: fjernet, og /control angre gir den tilbake
bm = Menu.host.buttons[2]
check(bm.entry == motw, "MotW står sist i rad I")
bm.scripts.OnDragStart(bm)
Menu.frame.mouse = false
bm.scripts.OnDragStop(bm)
check(#ControlCharDB.self == 1 and Chat("Mark of the Wild fjernet (/control angre)."), "dra ut: fjernet")
SlashCmdList.CONTROL("angre")
check(#ControlCharDB.self == 2, "angre: tilbake")
T.shift = false

-- Fell sammen
Menu.heads[1].scripts.OnClick(Menu.heads[1])
check(ControlCharDB.ui.menuSections.self == false and Menu.heads[1].pm.text == "+", "Mine buffs felt sammen")
eq(#Menu.host.buttons, 0, "ingen knapper fra en sammenfelt del")
Menu.heads[1].scripts.OnClick(Menu.heads[1])
eq(#Menu.host.buttons, 2, "foldet ut igjen")

-- Party buffs: hvem den følges på (Q7)
T.cursor = { "spell", 3, "spell", 1126 }
slot(true, 1).scripts.OnReceiveDrag(slot(true, 1))
local g = ControlCharDB.party[1]
check(g and g.type == "partyspell" and g.tier == 1, "gruppebuff i rad I")
T.party = { party1 = "Brakk", party2 = "Mira" }
T.partyClass = { party1 = "WARRIOR", party2 = "MAGE" }
T.pa = { party1 = {}, party2 = {} }
Fire("GROUP_ROSTER_UPDATE")
local mira = findLink("Mira")
check(findLink("Brakk") and mira and mira.followed, "navnene står i menyen, alle følges")
eq(mira.color[1], 0.25, "Mira i klassefarge (mage)")
mira.scripts.OnClick(mira)
check(g.onlyOn and g.onlyOn.Brakk and not g.onlyOn.Mira, "klikk Mira: følges bare på Brakk")
eq(#ns.model.st[g.id].members, 1, "bare Brakk telles")
check(Chat("MotW: bare Brakk."), "sier fra i chatten")
mira = findLink("Mira")
check(mira and not mira.followed, "Mira står grå")
mira.scripts.OnClick(mira)
check(g.onlyOn == nil and Chat("MotW: alle."), "klikk igjen: alle")

-- Byvakt: «Legg til» for stedet du står, og «Voktes (n)» som folder ut lista
local add = Menu.cityButton
check(add and add.text == "Legg til" and not add.enabled, "i Stormwind: «Legg til» er grå (voktes alt)")
local function cityRows()
  local out = {}
  for _, c in ipairs(Menu.frame.children or {}) do if c.shown and c.city then out[#out + 1] = c end end
  return out
end
check(Menu.cityListButton.text == "Voktes (3)" and #cityRows() == 0 and not Menu.cityBox, "lista er foldet inn fra start")
local listH = Menu.frame.height
Menu.cityListButton.scripts.OnClick(Menu.cityListButton)
local rowsNow = cityRows()
check(#rowsNow == 3 and rowsNow[1].city == "Stormwind City" and Menu.cityBox and Menu.cityBox.shown, "klikk: lista med tre steder")
check(Menu.frame.height > listH, "menyen blir høyere når lista er ute")
T.zone = "Goldshire"
ns.Refresh(false)
add = Menu.cityButton
check(add.enabled, "i Goldshire: kan legges til")
add.scripts.OnClick(add)
check(#cities == 4 and cities[4] == "Goldshire" and Chat("Goldshire voktes nå."), "Goldshire lagt til")
check(not Menu.cityButton.enabled and Menu.cityListButton.text == "Voktes (4)", "nå grå, og telleren følger")
-- Dra Darnassus ut av lista: fjernet. Slipp inni lista: ingenting skjer.
local darn
for _, r in ipairs(cityRows()) do if r.city == "Darnassus" then darn = r end end
darn.scripts.OnDragStart(darn)
Menu.cityBox.mouse = true
darn.scripts.OnDragStop(darn)
eq(#cities, 4, "slipp inni lista: ingenting fjernet")
darn.scripts.OnDragStart(darn)
Menu.cityBox.mouse = false
darn.scripts.OnDragStop(darn)
check(#cities == 3 and Chat("Darnassus fjernet (/control angre)."), "dra ut: Darnassus fjernet")
SlashCmdList.CONTROL("angre")
check(#cities == 4 and cities[3] == "Darnassus", "angre: Darnassus tilbake på plassen sin")
Menu.cityListButton.scripts.OnClick(Menu.cityListButton)
check(#cityRows() == 0, "klikk igjen: lista foldes inn")

-- Bytt side: én lang knapp, midtstilt
local sw = Menu.swapButton
check(sw.text == "Bytt side på gruppene", "Bytt side på gruppene")
eq(sw.width, Menu.cityListButton.width, "Voktes og Bytt side er like brede")
eq(sw.points[1][4], math.floor((Menu.frame.width - sw.width) / 2), "midtstilt")
check(sw.width < 300, "bredden kommer fra teksten, ikke fra menyen")
sw.scripts.OnClick(sw)
eq(ControlCharDB.ui.partySide, "right", "byttet")
check(Menu.heads[1].right.text == "venstre" and Menu.heads[2].right.text == "høyre", "kategorilinjene sier hvor de står")
check(ns.Tray.Get("left").ids[1] == flask.id, "flasken står ute på venstre side")
Menu.swapButton.scripts.OnClick(Menu.swapButton)

-- Størrelse: bare medaljongen vokser; knappene og menyen flytter seg utover
local sl = Menu.slider
eq(sl:GetValue(), 100, "slideren står på 100 %")
sl.scripts.OnMouseDown(sl)
sl:SetValue(150)
eq(ControlCharDB.ui.scale, 1.0, "mens du drar: ingen endring ennå")
eq(sl.label.text, "150 %", "tallet følger med")
ns.Refresh(false) -- menyen tegnes på nytt mens du drar
eq(sl:GetValue(), 150, "slideren hopper ikke tilbake mens du drar")
sl.scripts.OnMouseUp(sl)
eq(ControlCharDB.ui.scale, 1.5, "slipp: 150 %")
eq(M.Extra(), 16, "kanten står 16 px lenger ut")
eq(M.frame.scale, 1, "selve rammen skaleres ikke: knappene og menyene har samme størrelse")
eq(st.hit.width, 96, "klikkflaten følger sirkelen")
local whole = #M.Lines() > 0
for _, it in ipairs(M.Lines()) do
  local px = it.l.thickness * 1.5
  if math.abs(px - math.floor(px + 0.5)) > 1e-6 or px < 1 then whole = false end
end
check(whole, "150 %: alle strekene i symbolene er hele skjermpiksler")
local tray = ns.Tray.Get("right")
eq(tray.buttons[1].points[1][4], 2 + 33 + 16, "knappen ved medaljongen flyttet 16 px ut")
eq(Menu.frame.points[1][5], -86, "menyen 16 px lenger ned")
zoneClick(30, 0) -- høyre sone, 30 px ut: innenfor den større sirkelen
local mb = ns.SideBar.Get("right")
check(mb.frame.shown, "sonene følger den større sirkelen")
eq(mb.buttons[1].points[1][4], 2 + 33 + 16, "sidemenyens første knapp flyttet 16 px ut")
eq(Menu.frame.points[1][5], -96, "menyen et hakk under sidemenyen")
eq(Menu.frame.width, 356 + 2 * 16, "150 %: menyen blir bredere like mye som sidemenyene flytter seg ut")
zoneClick(30, 0)
sl.scripts.OnMouseWheel(sl, -1)
eq(ControlCharDB.ui.scale, 1.45, "musehjul: 5 % ned")

-- I kamp: menyen kan ikke åpnes eller lukkes, og ingenting endres
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
zoneClick(0, -20)
check(Menu.IsOpen(), "i kamp: lukkes ikke")
sl.scripts.OnMouseUp(sl)
sl:SetValue(100)
eq(ControlCharDB.ui.scale, 1.45, "i kamp: størrelsen endres ikke")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
SlashCmdList.CONTROL("nullstill")
eq(ControlCharDB.ui.scale, 1.0, "nullstill: vanlig størrelse")
eq(M.Extra(), 0, "nullstill: ingen ekstra luft")

-- Medaljongen i nedre halvdel: menyen åpner oppover
T.center = { 500, 200 }
ns.Refresh(false)
p = Menu.frame.points[1]
check(p[1] == "BOTTOM" and p[3] == "TOP" and p[5] == 6, "nedre halvdel: menyen åpner oppover")
T.center = { 500, 400 }
zoneClick(0, -20)
check(not Menu.IsOpen(), "klikk igjen: lukket")

return n, fails
