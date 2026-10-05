-- Fase 9: animasjonene (SPEC §7.10) og gløden. Lysbuen langs ringen, knapper som krymper ut (også i kamp),
-- sidemenyene og menyen folder seg ut, gullstreken ved Shift + dra, og gløden som ett mykt bilde.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end
local function near(a, b) return math.abs(a - b) < 0.01 end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local M = ns.Medallion
local st = M.State()
local function mouse(dx, dy) T.mouse = { T.center[1] + dx, T.center[2] + dy } end
local function settle() local f = st.animFrame.scripts.OnUpdate if f then f(st.animFrame, 5) end end

-- 1. Lysbuen: følger lysprikken mot sonen
local arc = st.parts.arc
check(arc and arc.texture:find("medal_arc", 1, true), "lysbuen er et bilde")
eq(arc.alpha, 0, "ingen bue uten mus")
mouse(20, 0)
st.hit.scripts.OnEnter(st.hit)
M.TrackMouse()
settle()
check(arc.alpha > 0.5 and near(arc.rotation, 0), "mus på høyre sone: buen lyser mot høyre")
mouse(0, 20)
M.TrackMouse()
settle()
check(near(arc.rotation, math.pi / 2), "mus på toppen: buen roterer opp")
mouse(0, 0)
M.TrackMouse()
settle()
eq(arc.alpha, 0, "midten: ingen bue")
st.hit.scripts.OnLeave(st.hit)

-- 6. Gløden: ett mykt bilde, ikke bånd av rektangler
T.cursor = { "spell", 3, "spell", 5232 }
st.hit.scripts.OnReceiveDrag(st.hit)
local tray = ns.Tray.Get("right")
local b = tray.buttons[1]
check(b.glowTex and b.glowTex.texture:find("glow_btn", 1, true) and b.glowTex.width == 64, "gløden er glow_btn, 64 × 64")
check(b.glowing and b.glow.alpha == 1, "MotW mangler: gløder")

-- 2. Knapp som forsvinner utenfor kamp: kopien krymper der den stod
T.auras = { { "Mark of the Wild", 5232, T.now + 1800, 1800 } }
Fire("UNIT_AURA", "player")
local g = ns.Tray.lastGhost
check(g and g.shown and g.anim.playing and g.tex.texture == b.icon.texture, "buffen er på: kopien av knappen krymper ut")
eq(g.mouseEnabled, false, "kopien tar ikke musa")
g.anim.scripts.OnFinished()
check(not g.shown, "kopien er borte etterpå")

-- ... og i kamp: det sikre skriptet skjuler knappen, kopien krymper
T.auras = {}
Fire("UNIT_AURA", "player")
b = tray.buttons[1]
check(b.shown, "MotW mangler igjen: står ute")
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
ns.Tray.lastGhost = nil
SecureClick(b, "LeftButton")
check(not b.shown and ns.Tray.lastGhost and ns.Tray.lastGhost.shown, "klikk i kamp: knappen skjules, kopien krymper")
T.combat, T.secret = false, false
Fire("PLAYER_REGEN_ENABLED")

-- 3. Sidemenyen folder seg ut fra medaljongen; ingen vannrett strek under knappene
local mb = ns.SideBar.Get("right")
check(mb.hA == nil and mb.hB == nil, "ingen vannrett strek under knappene")
mouse(20, 0)
M.TrackMouse()
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(mb.frame.shown and mb.frame.unfold.playing, "sidemenyen folder seg ut")

-- 5. Gullstreken ved Shift + dra: på kanten av knappen du står over
T.cursor = { "item", 13510, "[Flask]" }
T.counts[13510] = 3
mb.frame.scripts.OnReceiveDrag(mb.frame)
local b1, b2 = mb.buttons[1], mb.buttons[2]
check(b1.shown and b2.shown, "to knapper i sidemenyen")
T.shift = true
b1.scripts.OnDragStart(b1)
mb.frame.mouse, b2.mouse = true, true
for _, f in ipairs(UIParent.children or {}) do if f.scripts.OnUpdate and f ~= st.animFrame then f.scripts.OnUpdate(f) end end
local m = ns.SideBar.marker
check(m and m.shown and m.points[1][2] == b2 and m.points[1][3] == "RIGHT", "dra MotW over flasken: streken står på høyre kant av flasken")
b2.mouse = false
for _, f in ipairs(UIParent.children or {}) do if f.scripts.OnUpdate and f ~= st.animFrame then f.scripts.OnUpdate(f) end end
check(not m.shown, "ikke over en knapp: ingen strek")
b1.scripts.OnDragStop(b1)
check(not m.shown, "slipp: streken er borte")
T.shift = false
mb.frame.mouse = false

-- 4. Menyen glir ut fra medaljongen
mouse(0, -20)
M.TrackMouse()
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(ns.Menu.IsOpen() and ns.Menu.frame.unfold.playing, "menyen glir ut")

-- Diskret ramme i ringens farge: bandasjer under ønsket antall (oransje), mens MotW som lyser, ikke får den
T.counts[14529] = 2
T.cursor = { "item", 14529, "[Runecloth Bandage]" }
ns.Actions.DropOn(false, 2)
local bandBtn, motwBtn
for _, x in ipairs(mb.buttons) do
  if x.shown and x.entry and x.entry.itemId == 14529 then bandBtn = x end
  if x.shown and x.entry and x.entry.name == "Mark of the Wild" then motwBtn = x end
end
bandBtn.entry.want = 5
ns.Refresh(false)
check(bandBtn.warn.alpha > 0.4 and near(bandBtn.warn.vertex[1], 1) and near(bandBtn.warn.vertex[2], 0x8C / 255),
  "bandasjer 2 av 5: diskret oransje ramme")
check(not bandBtn.glowing, "... og den lyser ikke")
check(motwBtn.glowing and motwBtn.warn.alpha == 0, "MotW mangler og lyser: ingen ekstra ramme")
bandBtn.entry.tier = 1
T.counts[14529] = 0
ns.Refresh(false)
for _, x in ipairs(mb.buttons) do if x.shown and x.entry and x.entry.itemId == 14529 then bandBtn = x end end -- ny plass i rad I
check(near(bandBtn.warn.vertex[1], 1) and near(bandBtn.warn.vertex[2], 0x20 / 255), "tom i tier I: rød ramme")
T.counts[14529] = 5
ns.Refresh(false)
eq(bandBtn.warn.alpha, 0, "nok på lager: ingen ramme")

return n, fails
