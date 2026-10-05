-- Fase 7: kamp. Sidemenyene og menyen kan åpnes/lukkes i kamp (sikkert skript på medaljongen), gruppebuff-
-- knappene går videre til neste som manglet i stedet for å forsvinne, og sverdene skyter ned bak medaljongen.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end
local function near(a, b) return math.abs(a - b) < 0.01 end

T.spellNames[21849] = "Gift of the Wild"
T.party = { party1 = "Brakk", party2 = "Mira" }
T.pa = { party1 = {}, party2 = {} }
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local M = ns.Medallion
local st = M.State()
local hit = st.hit
check(hit.template == "SecureHandlerClickTemplate" and hit.attrs._onclick, "medaljongen har et sikkert klikkskript")
check(hit.refs.sbleft and hit.refs.sbright and hit.refs.trleft and hit.refs.trright and hit.refs.menu, "skriptet kjenner rammene")

-- Flask i tier I (står ute til høyre), MotW til gruppa i tier I (står ute til venstre)
T.counts[13510] = 3
T.cursor = { "item", 13510, "[Flask of the Titans]" }
hit.scripts.OnReceiveDrag(hit)
ns.Actions.DropOn(true, 1)
T.cursor = { "spell", 3, "spell", 1126 }
ns.Actions.DropOn(true, 1)
local g = ControlCharDB.party[1]
check(g and g.tier == 1, "MotW til gruppa, tier I")
local trR, trL = ns.Tray.Get("right"), ns.Tray.Get("left")
check(trR.frame.shown and trL.frame.shown, "begge sider har knapper ute")
local tb = trL.buttons[1]
check(tb:GetAttribute("ks-qn") == 2 and tb:GetAttribute("ks-q1") == "party1" and tb:GetAttribute("ks-q2") == "party2",
  "gruppeknappen kjenner køen: Brakk, så Mira")

-- Sverdene: skjult utenfor kamp
check(not st.swordFrame.shown, "ingen sverd utenfor kamp")

-- Kampen starter
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
check(st.swordFrame.shown and st.swordFrame.scripts.OnUpdate, "kamp: sverdene kommer")
local t0 = T.now
local function at(t) T.now = t0 + t st.swordFrame.scripts.OnUpdate(st.swordFrame) end
at(0.04)
local s1 = st.swords[1]
check(s1.points[1][5] > 0 and st.swordFrame.alpha > 0 and st.swordFrame.alpha < 1, "på vei ned, toner inn")
at(0.2)
check(st.swordFlash.alpha > 0, "glimt når de låses")
at(0.6)
check(near(s1.points[1][4], 0) and near(s1.points[1][5], 0) and st.swordFrame.alpha == 1, "låst i kryss bak medaljongen")
check(st.swordFrame.scripts.OnUpdate == nil, "animasjonen stopper")
check(st.swords[1].ux < 0 and st.swords[2].ux > 0 and st.swords[1].uy > 0, "spissene opp til venstre og høyre")
check(st.swords[1].tex.texture == M.SWORD_TEX and M.SWORD_TEX:find("AddOns", 1, true) and M.SWORD_TEX:find("Control", 1, true),
  "sverdene er bildet fra Control-mappa")
check(st.swords[1].tex.coords == nil and st.swords[2].tex.coords ~= nil, "det høyre sverdet er speilvendt")

-- Sidemenyen i kamp: klikk høyre sone
local sbR = ns.SideBar.Get("right")
T.mousePos = { 0.95, 0.5 }
SecureClick(hit, "LeftButton")
check(sbR.frame.shown and not trR.frame.shown, "i kamp: høyre sidemeny åpnes og dekker knappene")
SecureClick(hit, "LeftButton")
check(not sbR.frame.shown and trR.frame.shown, "i kamp: lukkes, knappene er tilbake")
-- Menyen i kamp: nedre sone
T.mousePos = { 0.5, 0.05 }
SecureClick(hit, "LeftButton")
check(ns.Menu.IsOpen() and #ns.Menu.host.buttons == 2, "i kamp: menyen åpnes, ferdig bygget (flask og MotW)")
SecureClick(hit, "LeftButton")
check(not ns.Menu.IsOpen(), "i kamp: menyen lukkes")
-- Midten og toppen: ingenting
T.mousePos = { 0.5, 0.5 }
SecureClick(hit, "LeftButton")
check(not sbR.frame.shown and not ns.Menu.IsOpen(), "midten: ingenting åpnes")
-- Tooltip: flytting er sperret i kamp, sonene er det ikke
T.mouse = { T.center[1], T.center[2] }
M.TrackMouse()
hit.scripts.OnEnter(hit)
check(T.tooltip.text == "Dra" and T.tooltip.lines[1] == "Ikke i kamp.", "midten i kamp: «Dra» + «Ikke i kamp.»")
T.mouse = { T.center[1] + 20, T.center[2] }
M.TrackMouse()
check(T.tooltip.text == "Meg" and #T.tooltip.lines == 0, "høyre sone i kamp: bare «Meg»")

-- Gruppebuff i kamp: første klikk på Brakk, så går knappen videre til Mira; borte når køen er tom
SecureClick(tb, "LeftButton")
check(ns.Track.Pending() and ns.Track.Pending().cast.target.name == "Brakk", "første klikk: Brakk")
check(tb.shown and tb:GetAttribute("unit") == "party2", "knappen står igjen og peker på Mira")
Fire("UNIT_SPELLCAST_SENT", "player", "Brakk", "c1", 1126)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c1", 1126)
local s = ns.model.st[g.id]
check(s.members[1].has == true and s.members[2].has == false, "Brakk bekreftet, Mira mangler fortsatt")
SecureClick(tb, "LeftButton")
check(ns.Track.Pending() and ns.Track.Pending().cast.target.name == "Mira", "andre klikk: Mira")
check(not tb.shown, "køen er tom: knappen skjules")
Fire("UNIT_SPELLCAST_SENT", "player", "Mira", "c2", 1126)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c2", 1126)
s = ns.model.st[g.id]
check(s.members[2].has == true and #s.missingOn == 0, "Mira bekreftet: alle har den")

-- Kampen er over: sverdene glir ut, alt legges ut på nytt
T.combat, T.secret = false, false
T.pa = { party1 = { { "Mark of the Wild", 1126, T.now + 1800, 1800 } }, party2 = { { "Mark of the Wild", 1126, T.now + 1800, 1800 } } }
Fire("PLAYER_REGEN_ENABLED")
t0 = T.now
at(0.1)
check(st.swordFrame.shown and st.swordFrame.alpha < 1 and st.swords[1].points[1][5] > 0, "sverdene glir ut")
at(0.4)
check(not st.swordFrame.shown, "borte etter kampen")
check(not trL.frame.shown, "gruppa har MotW: ingen knapp ute")

-- Utenfor kamp gjør det sikre skriptet ingenting (Lua åpner som før)
T.mousePos = { 0.95, 0.5 }
SecureClick(hit, "LeftButton")
check(not sbR.frame.shown, "utenfor kamp: skriptet rører ingenting")

-- /reload midt i kamp: sverdene står der med en gang
T.combat = true
M.SetCombat(true, true)
check(st.swordFrame.shown and st.swordFrame.alpha == 1, "rett inn i kamp: sverdene står")
T.combat = false
M.SetCombat(false, true)

-- Lukke-piler (Daniel 5. okt): i hjørnet av sidemenyene og menyen, virker også i kamp
check(sbR.frame.template == "SecureHandlerBaseTemplate" and ns.Menu.frame.template == "SecureHandlerBaseTemplate",
  "sidemenyene og menyen er beskyttede rammer (kan vises/skjules av sikre skript)")
local arrowR = sbR.close
check(arrowR and arrowR.template == "SecureHandlerClickTemplate" and arrowR.refs.bar == sbR.frame and arrowR.refs.tray == trR.frame,
  "høyre sidemeny har lukke-pil som kjenner rammene")
eq(arrowR.points[1][1], "BOTTOMRIGHT", "pila står nederst i ytterste hjørne")
ns.SideBar.SetOpen("right", true)
ns.Refresh(false)
check(sbR.frame.shown and not trR.frame.shown, "utenfor kamp: åpen, knappene dekket")
SecureClick(arrowR, "LeftButton")
check(not sbR.frame.shown and trR.frame.shown, "pil utenfor kamp: lukket, knappene tilbake")
T.combat = true
T.mousePos = { 0.95, 0.5 }
SecureClick(hit, "LeftButton")
check(sbR.frame.shown, "i kamp: åpnet fra medaljongen")
SecureClick(arrowR, "LeftButton")
check(not sbR.frame.shown and trR.frame.shown, "pil i kamp: lukket")
T.combat = false
ns.Menu.SetOpen(true)
ns.Refresh(false)
check(ns.Menu.closeUp.shown and not ns.Menu.closeDown.shown, "menyen under medaljongen: pila peker opp")
SecureClick(ns.Menu.closeUp, "LeftButton")
check(not ns.Menu.IsOpen(), "pil: menyen lukket")

return n, fails
