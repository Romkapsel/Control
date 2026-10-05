-- Tester for Rules.lua (SPEC §6 og testscenarioet i §19). Kjøres av tests/run.py i en ren Lua 5.1 uten WoW-API.
local ns = NS
local R, L = ns.Rules, ns.L
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end
local function ids(t) return table.concat(t, ",") end

------------------------------------------------------------------------
-- auraStatus
------------------------------------------------------------------------
eq(R.auraStatus(nil, false), "missing", "aldri sett = ikke på")
eq(R.auraStatus(nil, true), "expired", "sett før = gått ut")
eq(R.auraStatus(41, true), "on", "41 s = på")
eq(R.auraStatus(40, true), "expiring", "40 s = snart ute")
eq(R.auraStatus(math.huge, true), "on", "uten tidsgrense = på")

------------------------------------------------------------------------
-- Alvorlighet (§6.2) og kan trykkes (§6.3)
------------------------------------------------------------------------
local spell = { id = "s", type = "spell", tier = 1 }
local buffitem = { id = "b", type = "buffitem", tier = 1, want = 4 }
local item = { id = "i", type = "item", tier = 2, want = 10 }
local pspell = { id = "p", type = "partyspell", tier = 1 }

eq(R.severity(spell, { status = "missing" }), 2, "spell ikke på = rød")
eq(R.severity(spell, { status = "expired" }), 2, "spell gått ut = rød")
eq(R.severity(spell, { status = "expiring" }), 1, "spell snart ute = oransje")
eq(R.severity(spell, { status = "on" }), 0, "spell på = ok")
eq(R.severity(buffitem, { status = "missing", count = 4 }), 2, "buffting ikke på = rød (Q1)")
eq(R.severity(buffitem, { status = "on", count = 3 }), 1, "buffting på, lager 3/4 = oransje")
eq(R.severity(buffitem, { status = "on", count = 0 }), 2, "buffting på, lager tomt = rød")
eq(R.severity(buffitem, { status = "expiring", count = 9 }), 1, "buffting snart ute, fullt lager = oransje")
eq(R.severity(buffitem, { status = "on", count = 4 }), 0, "buffting på, nok = ok")
eq(R.severity(item, { count = 0 }), 1, "lagerting tom i tier II = oransje")
eq(R.severity({ id = "i1", type = "item", tier = 1, want = 10 }, { count = 0 }), 2, "lagerting tom i tier I = rød")
eq(R.severity({ id = "s2", type = "spell", tier = 2 }, { status = "missing" }), 1, "spell som mangler i tier II = oransje")
eq(R.severity({ id = "b2", type = "buffitem", tier = 2, want = 1 }, { status = "missing", count = 3 }), 1, "buffting ikke på i tier II = oransje")
eq(R.severity({ id = "b3", type = "buffitem", tier = 1, want = 1 }, { status = "missing", count = 0 }), 2, "buffting ikke på og tom i tier I = rød")
eq(R.severity({ id = "p2", type = "partyspell", tier = 2 }, { missingOn = { { name = "Brakk" } } }), 1, "gruppebuff i tier II som mangler = oransje")
eq(R.severity(item, { count = 1 }), 1, "lagerting 1/10 = oransje")
eq(R.severity(item, { count = 10 }), 0, "lagerting 10/10 = ok")
eq(R.severity(item, { count = 12 }), 0, "lagerting over ønsket = ok")
eq(R.severity(pspell, { missingOn = { { name = "Brakk" } } }), 2, "gruppebuff som mangler på én = rød")
eq(R.severity(pspell, { missingOn = {} }), 0, "gruppebuff alle har = ok")

check(R.canPress(spell, { status = "missing" }), "spell som mangler kan trykkes")
check(R.canPress(spell, { status = "expiring" }), "spell snart ute kan trykkes")
check(not R.canPress(spell, { status = "on" }), "spell på kan ikke trykkes")
check(R.canPress(buffitem, { status = "missing", count = 1 }), "buffting med 1 i baggen kan trykkes")
check(not R.canPress(buffitem, { status = "missing", count = 0 }), "buffting uten noen i baggen kan ikke trykkes")
check(not R.canPress(buffitem, { status = "on", count = 1 }), "buffting som er på og lav, kan ikke trykkes (lager fikses ikke med klikk)")
check(not R.canPress(item, { count = 0 }), "lagerting kan aldri trykkes")
check(R.canPress(pspell, { missingOn = { { name = "Vesla" } } }), "gruppebuff som mangler kan trykkes")
check(not R.canPress(pspell, { missingOn = {} }), "gruppebuff alle har kan ikke trykkes")

------------------------------------------------------------------------
-- Tider og lager (§7.5)
------------------------------------------------------------------------
eq(R.formatTime(38, L), "0:38", "38 s")
eq(R.formatTime(5.9, L), "0:05", "5,9 s rundes ned")
eq(R.formatTime(60, L), "1 min", "60 s")
eq(R.formatTime(61, L), "2 min", "61 s rundes opp")
eq(R.formatTime(360, L), "6 min", "6 min")
eq(R.formatTime(98 * 60, L), "98 min", "98 min får plass")
eq(R.formatTime(99 * 60 + 30, L), "2 t", "99,5 min = 100 min rundet opp = 2 t")
eq(R.formatTime(7200, L), "2 t", "2 t")
eq(R.formatTime(7201, L), "3 t", "2 t og 1 s rundes opp")
eq(R.formatTime(math.huge, L), nil, "uten tidsgrense: ingen tid")
eq(R.formatTime(360, L, true), "6m", "på knappen: 6m")
eq(R.formatTime(7200, L, true), "2t", "på knappen: 2t")
eq(R.formatTime(38, L, true), "0:38", "på knappen: 0:38 som før")
eq(R.stockText(3, 2), "3", "nok: bare tallet")
eq(R.stockText(3, 4), "3/4", "for lite: har/vil ha")
eq(R.stockText(0, 10), "0/10", "tomt")

------------------------------------------------------------------------
-- Gruppebuff: gruppeversjon eller enkel (§9.5, Daniel 3. okt.)
------------------------------------------------------------------------
local motwP = { id = "pm", type = "partyspell", tier = 1, name = "Mark of the Wild", groupSpell = "Gift of the Wild" }
local three = { missingOn = { { name = "Brakk", unit = "party1" }, { name = "Tosk", unit = "party3" }, { name = "Vesla", unit = "party4" } } }
local two = { missingOn = { { name = "Brakk", unit = "party1" }, { name = "Vesla", unit = "party4" } } }
local c = R.partyCast(motwP, three, { inParty = true, groupUsable = true })
check(c.group and c.spell == "Gift of the Wild" and c.target.unit == "party1", "3 mangler i party, reagens: Gift of the Wild")
c = R.partyCast(motwP, two, { inParty = true, groupUsable = true })
check(not c.group and c.spell == "Mark of the Wild" and c.target.name == "Brakk", "2 mangler: Mark of the Wild på første")
c = R.partyCast(motwP, three, { inParty = true, groupUsable = false })
check(not c.group and c.spell == "Mark of the Wild", "gruppeversjonen kan ikke kastes (reagens, ikke lært): enkeltversjonen")
c = R.partyCast(motwP, three, { inParty = false })
check(not c.group, "ikke i party: enkeltversjonen")
c = R.partyCast({ id = "t", type = "partyspell", name = "Thorns" }, three, { inParty = true })
check(not c.group and c.spell == "Thorns", "uten gruppeversjon: alltid enkel")
check(R.partyCast(motwP, { missingOn = {} }, { inParty = true }) == nil, "ingen mangler: ingenting å kaste")

------------------------------------------------------------------------
-- Testscenarioet (§19)
------------------------------------------------------------------------
local model = {
  party = {
    { id = "p1", type = "partyspell", tier = 1, name = "Mark of the Wild", short = "MotW", groupSpell = "Gift of the Wild" },
    { id = "p2", type = "partyspell", tier = 2, name = "Thorns", short = "Thorns" },
  },
  self = {
    { id = "motw", type = "spell", tier = 1, name = "Mark of the Wild", short = "MotW" },
    { id = "thorns", type = "spell", tier = 1, name = "Thorns", short = "Thorns" },
    { id = "flask", type = "buffitem", tier = 1, name = "Flask of the Titans", short = "Flask", want = 2 },
    { id = "fed", type = "buffitem", tier = 2, name = "Well Fed", short = "Well Fed", want = 10 },
    { id = "mong", type = "buffitem", tier = 2, name = "Elixir of the Mongoose", short = "Mongoose", want = 4 },
    { id = "def", type = "buffitem", tier = 2, name = "Elixir of Superior Defense", short = "Defense", want = 5 },
    { id = "band", type = "item", tier = 2, name = "Runecloth Bandage", short = "Bandage", want = 10 },
    { id = "mana", type = "item", tier = 2, name = "Major Mana Potion", short = "Mana", want = 5 },
  },
  st = {
    p1 = { missingOn = { { name = "Brakk", unit = "party1" }, { name = "Vesla", unit = "party4" } } },
    p2 = { missingOn = { { name = "Brakk", unit = "party1" } } },
    motw = { status = "missing" },
    thorns = { status = "on" },
    flask = { status = "missing", count = 3 },
    fed = { status = "on", count = 10 },
    mong = { status = "on", count = 3 },
    def = { status = "missing", count = 4 },
    band = { count = 0 },
    mana = { count = 5 },
  },
}
local function find(list, id) for _, e in ipairs(list) do if e.id == id then return e end end end
-- Et klikk, slik prototypen gjør det: spell = på; buffting = på og én færre; gruppebuff = første som manglet, har den.
local function click(id)
  local e = find(model.self, id) or find(model.party, id)
  local s = model.st[id]
  if e.type == "partyspell" then table.remove(s.missingOn, 1)
  elseif e.type == "buffitem" then s.status, s.count = "on", s.count - 1
  else s.status = "on" end
end

local v = R.render(model, L)
eq(v.count, 7, "start: tallet")
eq(v.ring, 2, "start: rød ring")
eq(ids(v.tray.party) .. " | " .. ids(v.tray.self), "p1 | motw,flask", "start: ved knappen")
eq(v.status.self.detail, "Mangler  MotW · Flask · Mongoose 3/4 · Defense 4/5 · +1", "start: statuslinje MB")
eq(v.status.party.text, "Party", "start: statuslinje PB er bare navnet")
eq(v.status.self.text, "Meg", "start: statuslinje MB er bare navnet")
check(not v.status.party.ok and #v.status.party.parts == 2, "start: to gruppebuffer mangler noen")
eq(v.status.self.parts[1].nameSev, 2, "MotW (tier I, ikke på): rød")
eq(v.status.self.parts[4].nameSev, 1, "Defense (tier II, ikke på): oransje")
eq(v.status.self.parts[4].stockSev, 1, "Defense: 4/5 oransje")
check(v.status.self.parts[2].stock == nil, "Flask: lageret er nok, ingen brøk")
eq(v.status.self.more, 1, "+1 er Bandage")

click("motw")
v = R.render(model, L)
eq(v.count, 6, "klikk MotW (meg): tallet")
eq(ids(v.tray.party) .. " | " .. ids(v.tray.self), "p1 | flask", "klikk MotW (meg): ved knappen")

click("flask")
v = R.render(model, L)
eq(model.st.flask.count, 2, "Flask 3 → 2")
eq(v.count, 5, "klikk Flask: tallet (2 er fortsatt nok)")
eq(ids(v.tray.party) .. " | " .. ids(v.tray.self), "p1 | ", "klikk Flask: bare gruppeknappen står ute")

click("p1")
v = R.render(model, L)
eq(v.count, 5, "klikk MotW-gruppe (Brakk): tallet")
eq(ids(v.tray.party), "p1", "Vesla mangler fortsatt: gruppeknappen står")
eq(R.partyCast(model.party[1], model.st.p1, { inParty = true, groupUsable = true }).target.name, "Vesla", "neste mål er Vesla")

click("p1")
v = R.render(model, L)
eq(v.count, 4, "klikk MotW-gruppe (Vesla): tallet")
eq(v.ring, 1, "alt som gjenstår er tier II: oransje ring")
eq(#v.tray.party + #v.tray.self, 0, "knappen står alene")
eq(v.status.self.detail, "Mangler  Mongoose 3/4 · Defense 4/5 · Bandage 0/10", "slutt: statuslinje MB")
eq(v.status.party.text, "Party", "slutt: statuslinje PB")

-- Høyreklikk Defense til tier I: dukker opp ved knappen med en gang
find(model.self, "def").tier = 1
v = R.render(model, L)
eq(ids(v.tray.self), "def", "Defense i tier I står ute (ikke på, har 4)")
check(v.count == 4 and v.ring == 2, "Defense i tier I som mangler: rød ring, samme tall")
find(model.self, "def").tier = 2

------------------------------------------------------------------------
-- Sidemenyen (§7.4)
------------------------------------------------------------------------
v = R.render(model, L)
eq(ids(v.side.self.tier1), "motw,thorns,flask", "MB tier I i brukerens rekkefølge")
eq(ids(v.side.self.tier2), "fed,mong,def,band", "MB tier II: mana-tingen har nok, og står ikke i sidemenyen")
check(v.side.self.groove, "fure mellom tier I og II")
eq(v.side.self.slots, 1, "8 knapper: minst én tom rute")
eq(v.side.self.width, 40 + 8 * 46 + 12, "bredde MB")
eq(v.side.party.slots, 1, "2 gruppeknapper: bare én «+»-rute")
eq(v.side.party.width, 40 + 3 * 46 + 12, "bredde PB med fure")

------------------------------------------------------------------------
-- Alt ok, og tom tilstand (§6.5)
------------------------------------------------------------------------
local okModel = { self = { { id = "a", type = "spell", tier = 1, short = "MotW" } }, party = {}, st = { a = { status = "on" } } }
v = R.render(okModel, L)
check(v.count == 0 and v.ring == 0 and v.allOk and not v.empty, "alt ok: hake, ingen farge")
eq(v.status.self.detail, "Status  Alt med", "alt ok: statuslinje MB")
eq(v.status.party.text, "Party", "alt ok: statuslinje PB")
check(v.status.party.ok, "alt ok: PB ok")
v = R.render({ self = {}, party = {}, st = {} }, L)
check(v.empty and v.count == 0 and v.ring == 0, "tom tilstand")
eq(v.side.self.slots, 1, "tom tilstand: én tom slipprute")
eq(v.side.self.width, 40 + 46, "tom tilstand: bredde")

------------------------------------------------------------------------
-- Oransje alene, og stabil rekkefølge (§6.6)
------------------------------------------------------------------------
local warnModel = {
  self = {
    { id = "x", type = "item", tier = 2, short = "A", want = 6 },
    { id = "y", type = "spell", tier = 1, short = "B" },
    { id = "z", type = "item", tier = 2, short = "C", want = 4 },
  },
  party = {}, st = { x = { count = 1 }, y = { status = "expiring" }, z = { count = 3 } },
}
v = R.render(warnModel, L)
eq(v.ring, 1, "bare oransje: oransje ring")
eq(v.status.self.detail, "Mangler  A 1/6 · B · C 3/4", "like alvorlige beholder lista sin rekkefølge")
eq(ids(v.tray.self), "y", "spell snart ute står ute")

------------------------------------------------------------------------
-- Kamp (§6.8): det som stod ute, står fast; tall og ring oppdateres
------------------------------------------------------------------------
local before = R.render(warnModel, L)
warnModel.st.y.status = "on"
local inFight = R.render(warnModel, L, { inCombat = true, prevTray = before.tray })
check(inFight.trayFrozen and ids(inFight.tray.self) == "y", "i kamp: knappen blir stående selv om buffen er på")
eq(inFight.count, 2, "i kamp: tallet oppdateres")
local after = R.render(warnModel, L, { inCombat = false, prevTray = before.tray })
check(not after.trayFrozen and #after.tray.self == 0, "etter kampen: knappen forsvinner")

------------------------------------------------------------------------
-- Byvakt (§10): hva du drar ut uten
------------------------------------------------------------------------
local d = R.departure(warnModel.self, { x = { count = 1 }, y = { status = "on" }, z = { count = 4 } }, L)
eq(d.sev, 1, "byvakt: under ønsket = oransje")
eq(d.text, "A 1/6", "byvakt: bare det som mangler")
d = R.departure(warnModel.self, { x = { count = 0 }, y = { status = "missing" }, z = { count = 4 } }, L)
eq(d.sev, 1, "byvakt: spells telles ikke; A (tier II) tom = oransje")
eq(d.text, "A 0/6", "byvakt: bare lageret")
local flaskModel = {
  { id = "f", type = "buffitem", tier = 1, short = "Flask", want = 1 },
  { id = "b", type = "item", tier = 2, short = "Bandage", want = 10 },
}
d = R.departure(flaskModel, { f = { status = "missing", count = 2 }, b = { count = 4 } }, L)
check(d.sev == 1 and d.text == "Bandage 4/10", "byvakt: flask ikke på, men 2 i baggen = ok; bandasjer under = oransje")
d = R.departure(flaskModel, { f = { status = "on", count = 0 }, b = { count = 0 } }, L)
check(d.sev == 2 and d.text == "Flask 0/1 · Bandage 0/10", "byvakt: tom flask i tier I = rød, verst først")
d = R.departure(warnModel.self, { x = { count = 6 }, y = { status = "on" }, z = { count = 4 } }, L)
check(d.sev == 0 and d.text == "Alt med", "byvakt: alt med")
d = R.departure({}, {}, L)
check(d.sev == 0, "byvakt: tom liste = alt med")

------------------------------------------------------------------------
-- Shouts (Daniel 5. okt): ingen rekkevidde = kastes på deg selv, gjelder alle
------------------------------------------------------------------------
local shout = { id = "s", type = "partyspell", tier = 1, name = "Battle Shout" }
local sst = { missingOn = { { name = "Brakk", unit = "party1" }, { name = "Mira", unit = "party2" } } }
local c = R.partyCast(shout, sst, { inParty = true, selfCast = true })
check(c and c.self and c.group and c.spell == "Battle Shout", "shout: på deg selv, gjelder alle")
c = R.partyCast(shout, sst, { inParty = true })
check(c and not c.self and not c.group and c.target.unit == "party1", "uten selfCast: som før")

------------------------------------------------------------------------
-- Byvakt: reparasjon og bagplass (Daniel 5. okt)
------------------------------------------------------------------------
eq(R.repairSeverity(100), 0, "100 %: ok")
eq(R.repairSeverity(99), 1, "under 100 %: oransje")
eq(R.repairSeverity(49), 2, "under 50 %: rødt")
eq(R.repairSeverity(nil), 0, "ikke sjekket: ok")
eq(R.bagSeverity(5), 0, "5 ledige: ok")
eq(R.bagSeverity(4), 1, "4 ledige: oransje")
eq(R.bagSeverity(0), 2, "ingen ledige: rødt")
d = R.departure({}, {}, L, { repair = 73.4, bags = 2 })
check(d.sev == 1 and d.text == "Reparasjon 73% · Bagplass 2", "byvakt: reparasjon og bagplass i varselet: " .. tostring(d.text))
d = R.departure(flaskModel, { f = { count = 0 }, b = { count = 4 } }, L, { repair = 40, bags = 8 })
check(d.sev == 2 and d.text == "Reparasjon 40% · Flask 0/1 · Bandage 4/10", "byvakt: verst først, reparasjon først blant like")
d = R.departure({}, {}, L, { repair = 100, bags = 12 })
check(d.sev == 0 and d.text == "Alt med", "byvakt: helt utstyr og god plass: alt med")

return n, fails
