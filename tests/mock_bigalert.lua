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


-- Borte før tiden (Daniel 7. okt: «den skal skrike ut – også når den går ut fra slag»)
ns.Actions.ToggleBigAlert() -- på igjen
T.spellNames[324] = "Lightning Shield"
T.cursor = { "spell", 6, "spell", 324 }
ns.Medallion.State().hit.scripts.OnReceiveDrag(ns.Medallion.State().hit)
local ls = db.self[#db.self]
check(ls.tier == 1, "Lightning Shield: Må ha")
T.auras = { { "Battle Shout", 6673, T.now + 100, 120 }, { "Lightning Shield", 324, T.now + 500, 600, 77 } }
tick(5)
tick()
check(not A.big.shown, "på, lenge igjen: ikke noe varsel")
local s0 = A.bigSounds or 0
-- Utenfor kamp: ladningene brukt opp, buffen borte
T.auras = { { "Battle Shout", 6673, T.now + 95, 120 } }
tick()
check(A.big.shown and A.big.gone and A.big.entry == ls, "slått bort: stort varsel")
eq(A.big.name.text, "Lightning Shield er borte!", "teksten sier at den er borte")
eq(A.big.time.text, "!", "utropstegn i stedet for tall")
check(A.big.icon.desat, "grått ikon")
eq((A.bigSounds or 0) - s0, 1, "lyd")
tick(3.5)
check(not A.big.shown, "borte etter 3 s")

-- I kamp: buffene er hemmelige, men om buffen med kjent nummer finnes, kan sies
T.auras = { { "Battle Shout", 6673, T.now + 90, 120 }, { "Lightning Shield", 324, T.now + 600, 600, 78 } }
tick()
eq(ns.Scan.auraInstance[ls.id], 78, "nummeret er husket utenfor kamp")
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
tick(2)
check(not A.big.shown, "i kamp, fortsatt på: ingenting")
T.auras = { { "Battle Shout", 6673, T.now + 88, 120 } } -- slått bort i kamp
tick()
check(A.big.shown and A.big.gone and A.big.entry == ls, "i kamp: slått bort – stort varsel")
eq(ns.model.st[ls.id].status, "expired", "og medaljongen vet at den er ute")
eq(db.debug.auraGone and db.debug.auraGone.answer, "false", "skrevet ned hva klienten svarte første gang")
tick(3.5)
-- Kastet på nytt i kamp: ingen falsk «borte» (nytt nummer, kjent først etter kampen)
ns.Scan.Confirm(ls, db.durations)
tick()
check(not A.big.shown, "kastet på nytt i kamp: ingen falsk alarm")
-- Kan ikke klienten si det (svaret er hemmelig): vet ikke, ingen alarm
T.combat, T.secret = false, false
Fire("PLAYER_REGEN_ENABLED")
T.auras = { { "Battle Shout", 6673, T.now + 80, 120 }, { "Lightning Shield", 324, T.now + 600, 600, 79 } }
tick()
T.combat, T.secret, T.goneSecret = true, true, true
Fire("PLAYER_REGEN_DISABLED")
T.auras = { { "Battle Shout", 6673, T.now + 79, 120 } }
tick()
check(not (A.big.shown and A.big.gone), "hemmelig svar: ingen alarm (teller videre)")
T.combat, T.secret, T.goneSecret = false, false, false
Fire("PLAYER_REGEN_ENABLED")
tick(4)

-- /ctrl stort: nedtelling fra 10 med den første «Må ha»-buffen, tallet spretter hvert sekund
T.auras = { { "Battle Shout", 6673, T.now + 100, 120 }, { "Lightning Shield", 324, T.now + 600, 600, 80 } }
tick()
SlashCmdList.CONTROL("stort")
check(A.big.shown and A.big.time.text == "10" and A.big.entry == shout, "test: 10 med Battle Shout")
local seq = {}
for i = 1, 9 do tick(1) seq[#seq + 1] = A.big.time.text end
eq(table.concat(seq, " "), "9 8 7 6 5 4 3 2 1", "teller ned 9 8 7 … 1")
A.big.scripts.OnUpdate(A.big)
check(A.big.timeFrame.scale > 1.5, "nytt tall: starter stort (spretter)")
T.now = T.now + 0.4
A.big.scripts.OnUpdate(A.big)
check(math.abs(A.big.timeFrame.scale - 1) < 0.01, "… og faller på plass")
tick(1.5)
check(not A.big.shown, "ferdig etter 10 s")
SlashCmdList.CONTROL("stort borte")
check(A.big.shown and A.big.gone and A.big.name.text == "Battle Shout er borte!", "test: borte")
tick(3.5)
check(not A.big.shown, "test borte: 3 s")


-- /ctrl stortest uten ControlExtra: Battle Shout er borte, med vanlig ikon (aldri en bildesti som ikke finnes)
SlashCmdList.CONTROL("stortest borte")
check(A.big.shown and A.big.gone and A.big.name.text == "Battle Shout er borte!" and not A.big.image, "stortest uten tillegget: vanlig ikon")
tick(3.5)
-- Med tillegget (privat, ikke på GitHub): bildet i stedet for ikonet
local IMG = "Interface\\AddOns\\ControlExtra\\Media\\shout"
ControlExtras = { goneImages = { ["Battle Shout"] = IMG } }
SlashCmdList.CONTROL("stortest")
check(A.big.shown and not A.big.gone and A.big.time.text == "10" and A.big.image == IMG, "stortest: nedtelling med bildet")
tick(10.5)
SlashCmdList.CONTROL("stortest borte")
eq(A.big.image, IMG, "stortest borte: bildet")
eq(A.big.icon.texture, IMG, "bildet står der ikonet sto")
check(not A.big.icon.desat and not A.big.edge.shown, "i farger, uten firkantet kant")
tick(3.5)
-- Ekte Battle Shout: går ut etter nedtellingen – bildet kommer likevel (bare for buffer med eget bilde)
T.auras = { { "Battle Shout", 6673, T.now + 9, 120 }, { "Lightning Shield", 324, T.now + 600, 600, 81 } }
tick()
check(A.big.shown and not A.big.gone and A.big.entry == shout and A.big.image == IMG, "nedtelling for Battle Shout: bildet i stedet for ikonet")
-- Trykk på ikonet: usynlig knapp over det, som kaster Battle Shout (utenfor kamp)
local cb = A.clickButton
check(cb and cb.shown and cb:GetAttribute("type") == "spell" and cb:GetAttribute("spell") == "Battle Shout", "ikonet kan trykkes: kaster Battle Shout")
eq(cb.alpha, 0, "knappen er usynlig (det er ikonet du ser)")
check(cb.stateDriver and cb.stateDriver[2] == "[combat] hide; show", "i kamp skjuler spillet den selv")
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
RegisterStateDriver(cb, "visibility", cb.stateDriver[2]) -- spillets driver
check(not cb.shown, "i kamp: ikke klikkbar")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
T.auras = { { "Lightning Shield", 324, T.now + 600, 600, 81 } }
tick(9)
check(not A.big.shown, "gått ut etter nedtellingen: samme regel som andre – ikke et ekstra varsel")
check(not A.clickButton.shown and not A.clickButton.stateDriver, "ferdig: knappen borte")
-- Slått bort før tiden: «borte» med bildet
T.auras = { { "Battle Shout", 6673, T.now + 100, 120 }, { "Lightning Shield", 324, T.now + 600, 600, 81 } }
tick()
T.auras = { { "Lightning Shield", 324, T.now + 600, 600, 81 } }
tick()
check(A.big.shown and A.big.gone and A.big.image == IMG, "Battle Shout borte før tiden: bildet")
tick(3.5)
ControlExtras = nil

return n, fails
