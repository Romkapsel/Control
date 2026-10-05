-- Snart ute (SPEC §11 nivå 2, Daniel 5. okt): 40 s før en buff du hadde går ut, et ikon med nedtelling
-- midt på skjermen. Borte når du fornyer eller buffen er gått ut. Også i kamp (estimat).
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local X = ns.Expiry
local hit = ns.Medallion.State().hit

-- MotW i tier II (snart ute skal varsles uansett tier), på med 100 s igjen
T.cursor = { "spell", 3, "spell", 5232 }
hit.scripts.OnReceiveDrag(hit)
ControlCharDB.self[1].tier = 2
T.auras = { { "Mark of the Wild", 5232, T.now + 100, 1800 } }
Fire("UNIT_AURA", "player")
eq(X.shown, 0, "100 s igjen: ingen varsel")

-- 35 s igjen
T.now = T.now + 65
Tick()
eq(X.shown, 1, "40 s eller mindre: varsel")
local it = X.Icons()[1]
check(it.shown and it.time.text == "0:35", "ikon med nedtelling: " .. tostring(it.time.text))
eq(it.icon.texture, 1000 + 5232, "spellens ikon")
eq(X.frame.mouseEnabled, false, "tar ikke musa")
T.now = T.now + 10
Tick()
eq(it.time.text, "0:25", "teller ned")

-- Fornyet: borte
T.auras = { { "Mark of the Wild", 5232, T.now + 1800, 1800 } }
Fire("UNIT_AURA", "player")
check(X.shown == 0 and not it.shown, "fornyet: borte")

-- I kamp: buffene er hemmelige, men nedtellingen fortsetter fra det vi visste
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
T.now = T.now + 1770
Tick()
check(X.shown == 1 and it.shown and it.time.text == "0:30", "i kamp: varsel fra estimatet")

-- Gått ut: borte herfra (medaljongen viser den som manglende)
T.now = T.now + 31
Tick()
eq(X.shown, 0, "gått ut: borte")
T.combat, T.secret = false, false
T.auras = {}
Fire("PLAYER_REGEN_ENABLED")
eq(X.shown, 0, "etter kampen: ingen varsel for en buff som ikke er på")

-- Aldri for en buff som aldri var på
T.cursor = { "item", 13510, "[Flask of the Titans]" }
hit.scripts.OnReceiveDrag(hit)
Tick()
eq(X.shown, 0, "flask som ikke er på: ingen nedtelling")

return n, fails
