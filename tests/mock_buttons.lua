-- Fase 3: mine buffer, knappene ved medaljongen, trykk og bekreftelse (SPEC §6.4, §7.3, §7.5, §12.4).
-- Akseptkriteriet: MotW og en flask: mangler → står ute → klikk → på → borte, tallet går ned.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local tray = ns.Tray.Get("right") -- gruppa til venstre, mine til høyre
check(tray and not tray.frame.shown, "tom liste: ingen knapper ute")
check(tray.frame.points[1][1] == "TOPLEFT" and tray.frame.points[1][4] == 32 and tray.frame.points[1][5] == -4,
  "rammen starter i medaljongens midtpunkt (skjult bak sirkelen), 4 px under toppen")
local hit = ns.Medallion.State().hit

-- Slipp Mark of the Wild (rank 2, 5232) på medaljongen
T.cursor = { "spell", 3, "spell", 5232 }
hit.scripts.OnReceiveDrag(hit)
check(T.cursor == nil and Chat("Mark of the Wild er lagt til"), "spell sluppet på medaljongen er lagt til")
local motw = ControlCharDB.self[1]
check(motw and motw.type == "spell" and motw.tier == 1 and motw.short == "MotW", "MotW: spell, tier I, kortnavn")
check(motw.auraNames[1] == "Mark of the Wild" and motw.auraNames[2] == "Gift of the Wild", "Gift of the Wild teller som på (Q9)")
eq(ns.view.count, 1, "MotW mangler: tallet")
eq(ns.view.ring, 2, "MotW mangler: rød")
check(tray.frame.shown and #tray.ids == 1, "MotW står ute")
local b1 = tray.buttons[1]
check(b1:GetAttribute("type") == "spell" and b1:GetAttribute("spell") == "Mark of the Wild" and b1:GetAttribute("unit") == "player",
  "knappen kaster Mark of the Wild på deg selv, etter navn")
check(b1:GetAttribute("type2") == "", "høyreklikk kaster ikke")
check(not b1.band.shown and b1.bandText.text == "" and b1.glowing and b1.glow.alpha == 1 and b1.glowAnim.playing,
  "ikke på: ingen tekst, pulserende glød")
eq(b1.icon.texture, 1000 + 5232, "ikonet er spellens")
eq(tray.frame.width, 2 + 36 + 40 + 6 + 2, "rammen er én knapp bred")
check(32 + b1.points[1][4] == 64 + 6, "første knapp 6 px utenfor medaljongen")

T.cursor = { "spell", 3, "spell", 1126 }
hit.scripts.OnReceiveDrag(hit)
check(#ControlCharDB.self == 1 and Chat("står allerede på lista"), "samme spell (annen rank) legges ikke til to ganger")

-- Slipp en flask: klikk med noe på musepekeren = slipp
T.counts[13510] = 3
T.cursor = { "item", 13510, "[Flask of the Titans]" }
hit.scripts.OnMouseUp(hit, "LeftButton")
local flask = ControlCharDB.self[2]
check(flask and flask.type == "buffitem" and flask.castName == "Flask of the Titans" and flask.short == "Flask", "flask: buffting")
eq(flask.want, 1, "ønsket antall er 1 til du stiller det selv")
eq(ns.view.count, 2, "MotW og flask mangler")
check(#tray.ids == 2 and tray.buttons[2]:GetAttribute("type") == "item" and tray.buttons[2]:GetAttribute("item") == "item:13510",
  "flasken står ute og bruker itemet")
eq(tray.buttons[2].stock.text, "3", "nok på lager: bare tallet")
eq(tray.frame.width, 2 + 36 + 2 * 40 + 6 + 6 + 2, "rammen vokser utover")
check(ns.view.status.self.text == "Mangler  MotW · Flask", "statuslinja (til sidemenyen i fase 4)")

-- Klikk MotW: trykket registreres, kastet bekreftes, buffen kommer, knappen forsvinner
b1.scripts.hookPreClick(b1, "LeftButton")
check(ns.Track.Pending() and ns.Track.Pending().entry == motw, "trykket er registrert")
Fire("UNIT_SPELLCAST_SENT", "player", "", "c1", 5232)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c1", 5232)
check(ns.Track.Pending() == nil, "kastet er bekreftet")
T.auras = { { "Mark of the Wild", 5232, T.now + 3600, 3600 } }
Fire("UNIT_AURA", "player")
eq(ns.view.count, 1, "MotW på: tallet går ned")
check(#tray.ids == 1 and tray.ids[1] == flask.id, "MotW-knappen er borte, flasken står igjen")
eq(ControlCharDB.durations["Mark of the Wild"], 3600, "varigheten huskes til kamp")

-- Bom: klikk, men et annet kast (Wrath) – ingenting endres
local fb = tray.buttons[1]
fb.scripts.hookPreClick(fb, "LeftButton")
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c2", 5176)
check(ns.Track.Pending() ~= nil, "et annet kast bekrefter ikke flasken")
T.now = T.now + 2
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c3", 17626)
check(ns.Scan.confirmed[flask.id] == nil, "for sent (over 1 s uten at kastet startet): ikke bekreftet")

-- Kamp: buffer er hemmelige. Klikk flasken: bekreftet med spell-ID, lageret går ned, knappen står fast.
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
fb.scripts.hookPreClick(fb, "LeftButton")
T.counts[13510] = 2
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c4", 17626)
Fire("BAG_UPDATE_DELAYED")
check(#tray.ids == 1 and tray.ids[1] == flask.id, "i kamp: knappen blir stående til kampen er over")
eq(ns.model.st[flask.id].status, "on", "i kamp: flasken regnes som på etter bekreftet trykk")
eq(fb.stock.text, "2", "lageret leses i kamp (2, nok)")
check(not fb.glowing and fb.glow.alpha == 0, "på: ingen glød")
eq(fb.alpha, 0, "i kamp: ferdig knapp blir usynlig")
fb.scripts.hookOnEnter(fb)
check(T.tooltip.owner ~= fb, "usynlig knapp viser ingen tooltip")
eq(ns.view.count, 0, "flask på og nok igjen: ingenting mangler")
eq(ns.view.ring, 0, "alt i orden: ingen ringfarge")
local clampBefore = ns.Medallion.frame.clamp
ns.Medallion.Update(ns.view)
check(ns.Medallion.frame.clamp == clampBefore, "i kamp: skjermgrensen røres ikke")

-- I kamp teller MotW ned fra det vi visste
T.now = T.now + 3600 - 2 - 30
Tick()
eq(ns.model.st[motw.id].status, "expiring", "i kamp: MotW snart ute (estimat)")
eq(ns.view.count, 1, "i kamp: tallet oppdateres fra estimat")
check(#tray.ids == 1, "i kamp: ingen ny knapp dukker opp")

-- Etter kampen: les alt på nytt, legg ut knappene på nytt
T.combat, T.secret = false, false
T.auras = { { "Mark of the Wild", 5232, T.now + 30, 3600 }, { "Flask of the Titans", 17626, T.now + 7200, 7200 } }
Fire("PLAYER_REGEN_ENABLED")
check(#tray.ids == 1 and tray.ids[1] == motw.id, "etter kampen: flasken borte, MotW (snart ute) står ute")
local mb = tray.buttons[1]
eq(mb.big.text, "0:30", "snart ute: stor nedtelling")
check(not mb.glowing and mb.bandText.text == "", "snart ute: ingen glød, intet bånd")
T.now = T.now + 10
Tick()
eq(mb.big.text, "0:20", "nedtellingen går mellom lesingene")

T.now = T.now + 25
T.auras = { { "Flask of the Titans", 17626, T.now + 7000, 7200 } }
Fire("UNIT_AURA", "player")
check(not mb.band.shown and mb.bandText.text == "", "gått ut: ingen tekst")
check(mb.glowing and mb.glowAnim.playing, "gått ut: glød")
eq(mb.alpha, 1, "utenfor kamp: helt synlig")

-- Tooltip
mb.scripts.hookOnEnter(mb)
check(T.tooltip.text == "Mark of the Wild" and T.tooltip.lines[1] == "Gått ut" and T.tooltip.lines[2] == "Klikk for å kaste på deg selv",
  "tooltip: navn, status, handling")

-- Mat: auraen heter «Well Fed»; trykket holder den «på» mens du spiser
T.counts[21023] = 4
T.cursor = { "item", 21023, "[Chops]" }
hit.scripts.OnReceiveDrag(hit)
local food = ControlCharDB.self[3]
check(food and food.type == "buffitem" and food.auraNames[1] == "Well Fed" and food.short == "Well Fed", "mat: buffen heter Well Fed")
check(ns.view.tray.self[#ns.view.tray.self] == food.id, "maten står ute")
local foodBtn = tray.buttons[#tray.ids]
foodBtn.scripts.hookPreClick(foodBtn, "LeftButton")
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c5", 433)
Fire("UNIT_AURA", "player")
eq(ns.model.st[food.id].status, "on", "mens du spiser: regnes som på")
T.now = T.now + 41
Fire("UNIT_AURA", "player")
eq(ns.model.st[food.id].status, "expired", "ingen Well Fed etter 40 s: tilbake")

-- Potion, bandasje og vanlig mat: bare antall (lagerting), aldri «buff som mangler» (Daniel 4. okt)
for _, id in ipairs({ 13446, 14529, 4540 }) do
  T.counts[id] = 2
  T.cursor = { "item", id, "[x]" }
  hit.scripts.OnReceiveDrag(hit)
end
local list = ControlCharDB.self
check(list[#list - 2].type == "item" and list[#list - 1].type == "item" and list[#list].type == "item",
  "potion, bandasje og brød uten Well Fed er lagerting")
eq(list[#list - 2].short, "Healing", "potion: kortnavn")
for _, e in ipairs({ list[#list - 2], list[#list - 1], list[#list] }) do
  for _, id in ipairs(ns.view.tray.self) do check(id ~= e.id, "lagerting står aldri ute ved knappen") end
end

-- Testdata viser ingen knapper; tilbake til egne data viser dem igjen
SlashCmdList.CONTROL("test")
check(not tray.frame.shown, "testdata: ingen knapper ute")
for _ = 1, 4 do SlashCmdList.CONTROL("test") end
check(tray.frame.shown, "egne data igjen: knappene tilbake")

-- /control tøm
SlashCmdList.CONTROL("tøm")
check(#ControlCharDB.self == 0 and not tray.frame.shown and Chat("Lista er tømt"), "/control tøm")
return n, fails
