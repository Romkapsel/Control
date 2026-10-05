-- Avstandstest (Daniel 5. okt): /control avstand viser knappen «Avstandstest» under Oppsett i menyen.
-- Hvert trykk lagrer hva spillet sier om avstanden til hver kompis, også i kamp, i ControlCharDB.debug.range.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

T.party = { party1 = "Brakk" }
T.pa = { party1 = {} }
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local Menu = ns.Menu
Menu.SetOpen(true)
ns.Refresh(false)
check(Menu.rangeButton == nil, "knappen er skjult som standard")

SlashCmdList.CONTROL("avstand")
check(ControlCharDB.debug.rangeButton and Chat("Avstandstest er på"), "/control avstand slår den på")
local b = Menu.rangeButton
check(b and b.shown and b.text == "Avstandstest", "knappen står under Oppsett")

-- Utenfor kamp: posisjonene kan leses, 5 yards
T.pos = { player = { 0, 0 }, party1 = { 3, 4 } }
T.near = { party1 = true }
b.scripts.OnClick(b)
local r = ControlCharDB.debug.range
eq(#r, 1, "ett bilde lagret")
local m = r[1].members[1]
check(m and m.name == "Brakk" and m.yards == 5 and m.interact[1] == true, "Brakk: 5 yards, nær")
check(r[1].combat == false and Chat("Brakk: 5 yd"), "utenfor kamp, og svaret står i chatten")

-- I kamp: knappen virker, og det som er hemmelig, lagres som det
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
b.scripts.OnClick(b)
eq(#r, 2, "trykk i kamp: nytt bilde")
m = r[2].members[1]
check(r[2].combat == true and m.pos[1] == "<hemmelig>" and m.interact[1] == "<hemmelig>" and m.yards == nil, "i kamp: hemmelig")
check(Chat("ingenting kunne leses"), "chatten sier at ingenting kunne leses")
T.combat, T.secret = false, false
Fire("PLAYER_REGEN_ENABLED")

SlashCmdList.CONTROL("avstand")
check(Menu.rangeButton == nil and Chat("Avstandstest er av."), "/control avstand igjen: knappen er borte")

return n, fails
