-- Klikk i kamp: knappen forsvinner og rekka lukker seg med en gang (sikkert skript, Daniel 4. okt).
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local tray = ns.Tray.Get("right")
check(tray.frame.template == "SecureHandlerBaseTemplate", "rammen er en sikker ramme")
local hit = ns.Medallion.State().hit
T.cursor = { "spell", 3, "spell", 5232 }
hit.scripts.OnReceiveDrag(hit)
T.counts[13510] = 3
T.cursor = { "item", 13510, "[Flask]" }
hit.scripts.OnReceiveDrag(hit)
local motw, flask = ControlCharDB.self[1], ControlCharDB.self[2]
check(#tray.ids == 2, "MotW og flask står ute")
local b1, b2 = tray.buttons[1], tray.buttons[2]
check(b1.wrap and b1.wrap.header == tray.frame and b1:GetAttribute("ks-order") == 1 and b2:GetAttribute("ks-order") == 2,
  "knappene har skriptet og sin plass")

-- Utenfor kamp: skriptet gjør ingenting; knappen forsvinner først når buffen er bekreftet
SecureClick(b1, "LeftButton")
check(b1.shown, "utenfor kamp: ikke skjult av skriptet")
ns.Track.OnEvent("UNIT_SPELLCAST_FAILED", "player", "c0", 5232) -- glem trykket

-- I kamp: klikk MotW → borte med en gang, flasken flytter inn, rammen krymper
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
SecureClick(b1, "RightButton")
check(b1.shown, "høyreklikk: ingenting skjer")
SecureClick(b1, "LeftButton")
check(not b1.shown, "venstreklikk i kamp: MotW-knappen er borte")
local p = b2.points[#b2.points]
check(p[1] == "TOPLEFT" and p[4] == 2 + 33, "flasken har flyttet inn på første plass")
eq(tray.frame.width, 2 + 33 + 46 + 2, "rammen er krympet til én knapp")
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c1", 5232)
eq(ns.view.count, 1, "MotW bekreftet: tallet går ned")

-- Flasken: klikket, men kastet feiler (global cooldown) – knappen er borte, men tallet står
SecureClick(b2, "LeftButton")
check(not b2.shown and not tray.frame.shown, "siste knapp borte: rammen skjules")
Fire("UNIT_SPELLCAST_FAILED", "player", "c2", 17626)
eq(ns.view.count, 1, "kastet feilet: flasken teller fortsatt")

-- Etter kampen: MotW er på, flasken ikke → flasken kommer tilbake
T.combat, T.secret = false, false
T.auras = { { "Mark of the Wild", 5232, T.now + 3600, 3600 } }
Fire("PLAYER_REGEN_ENABLED")
check(tray.frame.shown and #tray.ids == 1 and tray.ids[1] == flask.id and tray.buttons[1].shown, "etter kampen: flasken er tilbake")
eq(tray.frame.width, 2 + 33 + 46 + 2, "rammen er én knapp bred")
p = tray.buttons[1].points[#tray.buttons[1].points]
check(p[4] == 2 + 33, "på første plass")

-- Venstre side: speilvendt
ControlCharDB.ui.partySide = "right"
ns.Core.Draw()
local left = ns.Tray.Get("left")
check(left.frame.shown and #left.ids == 1, "mine på venstre side når gruppa er til høyre")
T.combat = true
SecureClick(left.buttons[1], "LeftButton")
check(not left.frame.shown, "venstre side: skriptet virker også speilvendt")
return n, fails
