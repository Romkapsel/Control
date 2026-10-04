-- Fase 2: medaljongen (SPEC §7.1, §7.2, §7.8) mot en falsk klient.
local ns = NS
local M = ns.Medallion
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-- Soner fra vinkel og avstand
eq(M.ZoneAt(0, 0), "hub", "midten")
eq(M.ZoneAt(7, 7), "hub", "innenfor 11 px er midten")
eq(M.ZoneAt(0, 20), "up", "opp")
eq(M.ZoneAt(20, 3), "right", "høyre")
eq(M.ZoneAt(-2, -20), "down", "ned")
eq(M.ZoneAt(-20, 5), "left", "venstre")
eq(M.ZoneAt(40, 0), nil, "utenfor ringen: ingen sone")

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
check(M.State().count == "" and ns.view.empty, "uten oppføringer: ingen tall (tom tilstand)")
SlashCmdList.CONTROL("test") -- testdata: rød, 7 som i spesifikasjonen
local st = M.State()
check(M.frame ~= nil and st.root == M.frame, "medaljongen lages ved innlogging")
eq(st.count, "7", "testdata start: tallet 7")
check(near(st.anim.ringR.to, 1) and near(st.anim.ringG.to, 0x20 / 255), "rød ring")
check(st.anim.glowA.to > 0, "rød ring har glød")
check(T.atlasUsed.CircleMaskScalable and next(T.texPaths) == nil, "runde former med atlas-maske, ingen teksturstier")
local p = st.root.points[1]
check(p[1] == "CENTER" and p[3] == "CENTER" and p[4] == 0 and p[5] == 200, "standardplass: midt på, 200 px opp")
check(st.root.clamp and st.root.clamp[1] <= -138 and st.root.clamp[2] >= 138, "holdes innenfor skjermen med menyen utfoldet (138 px hver side)")
local rv = ns.view.side.self.width
check(st.root.clamp[2] == math.max(138, 32 + rv - 64), "høyre grense regnet med MB-sidemenyen fullt utfoldet")

-- Animasjonene går ferdig og stopper
local function settle() local f = st.root.scripts.OnUpdate if f then f(st.root, 5) end end
settle()
check(st.root.scripts.OnUpdate == nil, "animasjonen stopper når alt står stille")
check(near(st.parts.ring.color[1], 1), "ringen er rød etter overgangen")

-- Mus over øvre sone
local function mouse(dx, dy) T.mouse = { T.center[1] + dx, T.center[2] + dy } end
mouse(0, 20)
st.hit.scripts.OnEnter(st.hit)
eq(M.State().hover, "up", "mus over toppen")
check(st.anim.symA_up.to == 1 and near(st.anim.symA_left.to, 0.45) and st.anim.num.to == 0 and st.anim.grow.to == 1,
  "symbolene inn, tallet ut, medaljongen vokser")
check(st.anim.symS_up.to == 1.25 and st.anim.dot.to == 1 and st.anim.angle.to == 90, "aktivt symbol større, lysprikken peker opp")
eq(T.tooltip.text, "Lås", "tooltip: Lås")
settle()
check(near(st.face.scale, 1.06), "vokser 6 %")
check(near(st.sym.up.scale, 1.25) and near(st.sym.up.points[1][5], 17 / 1.25), "symbolet skaleres uten å flytte seg")

-- Klikk oppe = lås
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
check(ControlCharDB.ui.locked == true and M.State().locked, "klikk oppe låser")
eq(T.tooltip.text, "Lås opp", "tooltip: Lås opp")
check(st.sym.up.closed.shown and not st.sym.up.open.shown, "lukket hengelås")

-- Sidene: gruppa til venstre (to hoder), mine til høyre (ett hode)
check(st.sym.left.two.shown and not st.sym.left.one.shown and st.sym.right.one.shown, "to hoder til venstre, ett til høyre")
mouse(-20, 0)
M.TrackMouse()
eq(M.State().hover, "left", "venstre sone")
eq(T.tooltip.text, "Fold ut gruppa", "tooltip venstre: gruppa")
check(st.anim.angle.to == 180, "lysprikken mot venstre")
mouse(0, -20)
M.TrackMouse()
eq(T.tooltip.text, "Åpne menyen, 7 å gjøre", "tooltip nede: menyen med tallet")

-- Midten, låst: hengelås, ingen flytting
mouse(2, 2)
M.TrackMouse()
eq(M.State().hover, "hub", "midten")
check(st.anim.hubLock.to == 1 and st.anim.hubMove.to == 0 and st.anim.dot.to == 0 and st.anim.symA_up.to == 0, "låst: hengelås i midten, symbolene borte")
eq(T.tooltip.text, "Låst på plass. Lås opp fra toppen av ringen.", "tooltip: låst")
st.hit.scripts.OnMouseDown(st.hit, "LeftButton")
check(T.startedMoving == nil, "låst: kan ikke flyttes")
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")

-- Lås opp og flytt
SlashCmdList.CONTROL("lås")
check(ControlCharDB.ui.locked == false and Chat("Låst opp."), "/control lås låser opp")
M.TrackMouse()
check(st.anim.hubMove.to == 1 and st.anim.hubLock.to == 0, "ulåst: flyttekryss i midten")
eq(T.tooltip.text, "Flytt knappen: dra", "tooltip: flytt")
T.dragTo = { 900, 650 }
st.hit.scripts.OnMouseDown(st.hit, "LeftButton")
eq(T.startedMoving, 1, "dra i midten flytter")
st.hit.scripts.OnMouseUp(st.hit, "LeftButton")
local up = ControlCharDB.ui.point
check(up[1] == "CENTER" and up[2] == "UIParent" and up[3] == "BOTTOMLEFT" and up[4] == 900 and up[5] == 650, "ny plass lagres")
check(ControlCharDB.ui.locked == false, "slipp etter flytting låser ikke")

-- I kamp: ikke flytte
T.combat = true
st.hit.scripts.OnMouseDown(st.hit, "LeftButton")
eq(T.startedMoving, 1, "i kamp: ingen flytting")
T.combat = false

-- Mus ut
st.hit.scripts.OnLeave(st.hit)
check(M.State().hover == nil and st.anim.num.to == 1 and st.anim.grow.to == 0, "mus ut: tallet tilbake")

-- Testdata: rød → oransje → alt ok → tom → rød
SlashCmdList.CONTROL("test")
st = M.State()
eq(st.count, "2", "testdata oransje: tallet 2")
check(near(st.anim.ringG.to, 0x8C / 255), "oransje ring")
SlashCmdList.CONTROL("test")
st = M.State()
check(st.count == "" and ns.view.allOk and st.anim.glowA.to == 0, "alt ok: ingen tall, ingen glød")
settle()
check(near(st.parts.check.alpha, 0.6) and st.parts.count.alpha == 0, "alt ok: dempet hake")
SlashCmdList.CONTROL("test")
check(ns.view.empty and M.State().count == "", "tom liste: hake, intet tall")
SlashCmdList.CONTROL("test")
check(ns.view.empty and Chat("dine egne buffer og ting"), "etter testdataene: tilbake til dine egne")

-- Nullstill
SlashCmdList.CONTROL("nullstill")
p = M.State().root.points[1]
check(p[1] == "CENTER" and p[5] == 200 and Chat("flyttet tilbake"), "/control nullstill")
SlashCmdList.CONTROL("")
check(Chat("/control test"), "hjelpetekst")

return n, fails
