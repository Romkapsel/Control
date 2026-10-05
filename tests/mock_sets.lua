-- Sett (Daniel 5. okt): «Solo» og «Healing», hver med sine egne ting og sin egen «Må ha». Party er felles.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

-- Lagring fra før settene fantes: lista blir settet «Solo»
ControlCharDB = { self = {
  { id = "e1", type = "spell", tier = 1, name = "Mark of the Wild", spellId = 5232 },
  { id = "e2", type = "item", tier = 2, itemId = 14529, name = "Runecloth Bandage" },
}, party = {} }
local old = ControlCharDB.self
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
local db = ControlCharDB
check(db.sets and db.sets.Solo == old and db.self == old, "gammel liste blir settet «Solo»")
eq(db.activeSet, "Solo", "Solo er valgt")
eq(#db.setOrder, 1, "ett sett")
eq(db.sets.Solo[2].cat, "bandages", "settene får kategori ved innlogging")

-- Menyen: «Sett:»-raden øverst i Meg, Solo i gull, og «+»
ns.Menu.SetOpen(true)
ns.Refresh(false)
local sb = ns.Menu.setButtons
check(sb and #sb == 1 and sb[1].setName == "Solo" and sb[1].active, "menyen: Solo, valgt")
check(ns.Menu.newSetButton and ns.Menu.newSetButton.shown, "menyen: «+» for nytt sett")
-- Med bare ett sett står ikke settnavnet i sidemenyen
local mb = ns.SideBar.Get("right")
ns.SideBar.SetOpen("right", true)
ns.Refresh(false)
check(not mb.status.text:find("Solo", 1, true), "ett sett: bare «Meg» i sidemenyen")

-- «+»: spillets dialog spør om navnet; «Healing» blir en kopi av Solo, og du står i den
ns.Menu.newSetButton.scripts.OnClick(ns.Menu.newSetButton, "LeftButton")
eq(T.popup and T.popup.which, "CONTROL_SET_NEW", "«+» åpner dialogen for navn")
local dlg = { editBox = { GetText = function() return "  Healing " end } }
StaticPopupDialogs.CONTROL_SET_NEW.OnAccept(dlg)
eq(db.activeSet, "Healing", "nytt sett er valgt (navnet uten mellomrom rundt)")
check(Chat("Nytt sett: Healing."), "melding: nytt sett")
eq(#db.sets.Healing, 2, "kopi: samme to ting")
check(db.sets.Healing[1] ~= db.sets.Solo[1], "kopi: egne oppføringer, ikke de samme")
check(mb.status.text:find("Healing", 1, true), "sidemenyen: «Meg · Healing»")

-- «Må ha» per sett: gjør bandasjen til «Må ha» i Healing – Solo er urørt
ns.Actions.SetTier(db.self[2], 1)
eq(db.sets.Healing[2].tier, 1, "Healing: bandasjen er Må ha")
eq(db.sets.Solo[2].tier, 2, "Solo: bandasjen er fortsatt Fint å ha")
-- Fjerne i Healing rører ikke Solo
local before = #db.sets.Solo
table.remove(db.self, 1)
ns.Refresh(true)
eq(#db.sets.Solo, before, "fjerne i Healing: Solo har alt sitt")

-- Bytte tilbake med klikk på knappen i menyen
ns.Refresh(false)
local soloBtn
for _, b in ipairs(ns.Menu.setButtons) do if b.setName == "Solo" then soloBtn = b end end
check(soloBtn and not soloBtn.active, "Solo-knappen er ikke valgt")
soloBtn.scripts.OnClick(soloBtn, "LeftButton")
check(db.activeSet == "Solo" and db.self == db.sets.Solo, "klikk: Solo er valgt")
check(Chat("Sett: Solo."), "melding: byttet sett")

-- Ikke i kamp: knappene og handlingene står stille
T.combat = true
ns.Refresh(false)
local healBtn
for _, b in ipairs(ns.Menu.setButtons) do if b.setName == "Healing" then healBtn = b end end
healBtn.scripts.OnClick(healBtn, "LeftButton")
ns.Actions.UseSet("Healing")
ns.Actions.NewSet("PvP")
eq(db.activeSet, "Solo", "i kamp: ikke bytte")
check(not db.sets.PvP, "i kamp: ikke nytt sett")
T.combat = false

-- Høyreklikk: nytt navn
healBtn.scripts.OnClick(healBtn, "RightButton")
check(T.popup.which == "CONTROL_SET_EDIT" and T.popup.data == "Healing", "høyreklikk: dialogen for Healing")
eq(StaticPopupDialogs.CONTROL_SET_EDIT.button3, "Slett", "to sett: Slett-knappen finnes")
StaticPopupDialogs.CONTROL_SET_EDIT.OnAccept({ editBox = { GetText = function() return "Heal" end } }, "Healing")
check(db.sets.Heal and not db.sets.Healing and db.setOrder[2] == "Heal", "nytt navn: Heal")
-- Navn som er brukt eller tomt: nei
ns.Actions.RenameSet("Heal", "Solo")
ns.Actions.NewSet("")
check(db.sets.Heal and #db.setOrder == 2, "brukt eller tomt navn: ingenting skjer")
check(Chat("Settet trenger et navn som ikke er brukt."), "melding: dårlig navn")

-- Slette settet du står i: tilbake til det første
ns.Actions.UseSet("Heal")
StaticPopupDialogs.CONTROL_SET_EDIT.OnAlt({}, "Heal")
check(not db.sets.Heal and db.activeSet == "Solo" and db.self == db.sets.Solo, "slettet: tilbake til Solo")
check(Chat("Heal er slettet."), "melding: slettet")
-- Det siste settet kan ikke slettes
ns.Actions.DeleteSet("Solo")
check(db.sets.Solo and #db.setOrder == 1, "siste sett: kan ikke slettes")
ns.Actions.AskEditSet("Solo")
eq(StaticPopupDialogs.CONTROL_SET_EDIT.button3, nil, "ett sett: ingen Slett-knapp")

-- /ctrl tøm tømmer settet du står i, og settet følger med
SlashCmdList.CONTROL("tøm")
check(db.self == db.sets.Solo and #db.sets.Solo == 0, "tøm: Solo er tom, fortsatt samme liste")

-- Etter /reload: settet du sto i, er valgt
ns.Actions.NewSet("Raid")
local saved = ControlCharDB
ns.Data.EnsureSets(saved, "Solo")
check(saved.activeSet == "Raid" and saved.self == saved.sets.Raid, "lagret: Raid er valgt etter reload")

return n, fails
