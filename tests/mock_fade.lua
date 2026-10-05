-- Nedtoning (Daniel 5. okt): er alt i orden en stund, tones medaljongen ned. Mus over, noe som mangler, kamp eller en
-- meny åpen: helt fram igjen. Kan slås av under Oppsett.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end
local function near(a, b) return math.abs(a - b) < 0.01 end

T.now = 100
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
local M = ns.Medallion
local st = M.State()
local face = st.face
local function settle() local f = st.animFrame.scripts.OnUpdate if f then f(st.animFrame, 5) end end
local function after(secs) T.now = T.now + secs Tick() settle() end
local function mouse(dx, dy) T.mouse = { T.center[1] + dx, T.center[2] + dy } end

-- Alt i orden: først full styrke, etter 3 sekunder nedtonet
Tick()
settle()
check(near(face.alpha or 1, 1), "rett etter: full styrke")
after(1)
check(near(face.alpha or 1, 1), "etter 1 s: fortsatt full")
after(3)
check(near(face.alpha, M.FadeAlpha()), "alt i orden en stund: nedtonet")
check(st.hit.shown ~= false, "klikkflaten står (bare bildet tones)")

-- Mus over: helt fram med en gang
mouse(20, 0)
st.hit.scripts.OnEnter(st.hit)
M.TrackMouse()
settle()
check(near(face.alpha, 1), "mus over: full styrke")
after(5)
check(near(face.alpha, 1), "mus fortsatt over: forblir full")
st.hit.scripts.OnLeave(st.hit)
after(1)
check(near(face.alpha, 1), "musa borte: venter litt før nedtoning")
after(3)
check(near(face.alpha, M.FadeAlpha()), "musa borte en stund: nedtonet igjen")

-- Noe du må ha, mangler: fram med en gang
T.counts[14529] = 0
T.cursor = { "item", 14529, "[Runecloth Bandage]" }
st.hit.scripts.OnReceiveDrag(st.hit)
settle()
check(ControlCharDB.self[1] and ControlCharDB.self[1].tier == 1, "Må ha lagt til")
check(near(face.alpha, 1), "noe mangler: full styrke")
after(10)
check(near(face.alpha, 1), "så lenge noe mangler: full")
-- Fikset: ned igjen etter en stund
T.counts[14529] = 5
Fire("BAG_UPDATE_DELAYED")
after(0.5)
check(near(face.alpha, 1), "rett etter fikset: full")
after(3)
check(near(face.alpha, M.FadeAlpha()), "fikset en stund: nedtonet")

-- Kamp: full
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
settle()
check(near(face.alpha, 1), "kamp: full styrke")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
after(4)
check(near(face.alpha, M.FadeAlpha()), "etter kampen: nedtonet igjen")

-- Menyen åpen: full
ns.Menu.SetOpen(true)
after(5)
check(near(face.alpha, 1), "menyen åpen: full styrke")
-- Av/på under Oppsett
ControlCharDB.ui.menuSections.setup = true
ns.Refresh(false)
local fb = ns.Menu.fadeButton
check(fb and fb.text == "På", "Oppsett: «Nedtoning» – På")
eq(M.FadeAlpha(), 0.2, "standard: 20 %")
local lv = ns.Menu.fadeLevels
check(#lv == 3 and lv[1].text == "0 %" and lv[2].text == "20 %" and lv[3].text == "50 %", "valgene: 0 %, 20 %, 50 %")
check(lv[2].chosen and not lv[1].chosen and not lv[3].chosen, "20 % er valgt")
lv[3].scripts.OnClick(lv[3], "LeftButton")
eq(ControlCharDB.ui.fadeLevel, 0.5, "50 % valgt")
check(ns.Menu.fadeLevels[3].chosen, "50 % i gull")
ns.Menu.SetOpen(false)
after(0.25)
after(4)
check(near(face.alpha, 0.5), "nedtonet til 50 %")
ns.Menu.SetOpen(true)
ControlCharDB.ui.menuSections.setup = true
ns.Refresh(false)
lv = ns.Menu.fadeLevels
lv[1].scripts.OnClick(lv[1], "LeftButton")
ns.Menu.SetOpen(false)
after(0.25)
after(4)
check(near(face.alpha, 0), "0 %: helt borte")
st.hit.scripts.OnEnter(st.hit)
T.mouse = { T.center[1] + 20, T.center[2] }
M.TrackMouse()
settle()
check(near(face.alpha, 1), "0 %: mus over gir den tilbake")
st.hit.scripts.OnLeave(st.hit)
ns.Menu.SetOpen(true)
ControlCharDB.ui.menuSections.setup = true
ns.Refresh(false)
fb = ns.Menu.fadeButton
fb.scripts.OnClick(fb, "LeftButton")
eq(ControlCharDB.ui.fadeOk, false, "slått av")
check(fb.text == "Av", "knappen sier Av")
check(#ns.Menu.fadeLevels == 0, "av: ingen valg for styrke")
ns.Menu.SetOpen(false)
after(10)
check(near(face.alpha, 1), "slått av: aldri nedtonet")
ns.Actions.ToggleFade()
after(4)
check(near(face.alpha, M.FadeAlpha()), "på igjen: nedtonet")

return n, fails
