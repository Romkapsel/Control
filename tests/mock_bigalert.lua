-- Stort varsel midt på skjermen (Daniel 7. okt, kompisens ønske: «in your face»): når en «Må ha»-buff har 10 s igjen,
-- lyser ikonet opp stort midt på skjermen med sekundene som teller ned, og én lyd. Av/på under Oppsett (av som standard).
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

T.now = 1000
T.spellNames[6673] = "Battle Shout"
T.auras = { { "Battle Shout", 6673, T.now + 120, 120 }, { "Mark of the Wild", 5232, T.now + 8, 3600 } }
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
local A = ns.Alert
local db = ControlCharDB
-- Battle Shout som «Må ha» (på medaljongen), Mark of the Wild som «Fint å ha»
T.cursor = { "spell", 3, "spell", 6673 }
ns.Medallion.State().hit.scripts.OnReceiveDrag(ns.Medallion.State().hit)
T.cursor = { "spell", 1, "spell", 5232 }
ns.Actions.DropOn(false, 2)
local shout, motw = db.self[1], db.self[2]
check(shout.tier == 1 and motw.tier == 2, "Battle Shout Må ha, MotW Fint å ha")
local function tick(secs) T.now = T.now + (secs or 0) Fire("UNIT_AURA", "player") Tick() end

-- Av som standard: ingenting, selv om MotW har 8 s igjen
tick()
eq(db.ui.bigAlert, false, "av som standard")
check(not (A.big and A.big.shown), "av: ikke noe stort varsel")

-- Slå på under Oppsett: vises i 3 s med den første «Må ha»-buffen, så du ser hvordan det ser ut
ns.Menu.SetOpen(true)
db.ui.menuSections.setup = true
ns.Refresh(false)
local bb = ns.Menu.bigButton
check(bb and bb.text == "Av", "Oppsett: «Stort varsel ved 10 s» – Av")
bb.scripts.OnClick(bb, "LeftButton")
eq(db.ui.bigAlert, true, "slått på")
check(A.big and A.big.shown and A.big.entry == shout, "forhåndsvisning: Battle Shout")
tick(3.5)
check(not A.big.shown, "forhåndsvisningen er borte etter 3 s (Battle Shout har 2 min igjen)")
ns.Menu.SetOpen(false)

-- «Fint å ha» med 8 s igjen: ikke noe stort varsel (bare «Må ha»)
check(not A.big.shown, "Fint å ha: ikke stort varsel")

-- Battle Shout går mot slutten: ved 10 s lyser den opp, med sekundene og én lyd
local sounds = A.bigSounds or 0
T.now = 1000 + 120 - 11
tick()
check(not A.big.shown, "11 s igjen: ikke ennå")
tick(2)
check(A.big.shown and A.big.entry == shout, "9 s igjen: stort varsel for Battle Shout")
eq(A.big.time.text, "9", "sekundene står på ikonet")
eq(A.big.name.text, "Battle Shout", "navnet under")
eq((A.bigSounds or 0) - sounds, 1, "én lyd")
check(A.big.icon.texture == 1000 + 6673, "ikonet til Battle Shout")
tick(4)
eq(A.big.time.text, "5", "teller ned")
eq((A.bigSounds or 0) - sounds, 1, "fortsatt bare én lyd")

-- I kamp (buffene er hemmelige): teller videre fra det Control vet
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
tick(2)
check(A.big.shown and A.big.time.text == "3", "i kamp: teller videre")
T.combat, T.secret = false, false
Fire("PLAYER_REGEN_ENABLED")

-- Fornyet: borte med en gang
T.auras[1] = { "Battle Shout", 6673, T.now + 120, 120 }
tick()
check(not A.big.shown, "fornyet: borte")
-- Neste runde: lyd igjen
T.now = T.now + 111
tick()
check(A.big.shown, "neste gang den går mot slutten: igjen")
eq((A.bigSounds or 0) - sounds, 2, "ny lyd for ny runde")
-- Går ut: borte (medaljongen sier fra som før)
tick(10)
check(not A.big.shown, "gått ut: borte")

-- Av: aldri
ns.Actions.ToggleBigAlert()
T.auras[1] = { "Battle Shout", 6673, T.now + 5, 120 }
tick()
check(not A.big.shown, "av: aldri stort varsel")

return n, fails
