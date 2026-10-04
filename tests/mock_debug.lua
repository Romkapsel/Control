-- Fase 0: /control debug skal aldri krasje, også når klienten gir hemmelige verdier (V1–V9).
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end

Fire("ADDON_LOADED", "SomethingElse")
check(ControlCharDB == nil, "ADDON_LOADED for en annen addon rører ingenting")
Fire("ADDON_LOADED", "Control")
local db = ControlCharDB and ControlCharDB.debug
check(db and db.runs and db.casts and db.events and db.clicks and db.combat and db.errors, "loggen er satt opp")
check(ControlCharDB.schema == 1 and ControlCharDB.ui and ControlCharDB.ui.point, "lagringen har standardene fra SPEC §5.2")
check(SlashCmdList.CONTROL and SLASH_CONTROL1 == "/control" and SLASH_CONTROL2 == "/ctl", "/control og /ctl finnes")

-- Vanlige verdier, ute av kamp
T.auras = { { "Mark of the Wild", 1126, 2800, 1800 }, { "Well Fed", 19705, 1900, 900 } }
Fire("PLAYER_ENTERING_WORLD")
check(#db.runs == 1 and db.runs[1].reason == "innlogging", "øyeblikksbilde ved innlogging")
SlashCmdList.CONTROL("debug")
local s = db.runs[#db.runs]
check(s.client.interface == 16001 and s.client.build == "70205", "V1: build og interface lagres")
check(s.zone.zone == "Stormwind City" and s.zone.mapID == 1453, "sted lagres")
check(s.player.n == 2 and s.player.secretFields == 0 and s.player.list[1].name == "Mark of the Wild", "V2: egne buffer leses")
check(#s.items == 2 and s.items[1].count == 3 and s.items[1].spell == "Flask of the Titans", "V6/V7: lager og spell på item")
check(#s.spellbook == 2 and s.spellbook[1].rank == "Rank 3" and s.spellbook[1].id == 5232, "V7: buffer i spellboken med rank og ID")
check(s.ids[1].name == "Mark of the Wild" and s.ids[2].name == nil, "V7: hvilke ID-er klienten kjenner (ukjent = nil, ikke «feil»)")
check(Chat("interface 16001") and Chat("Egne buffer: 2 lest, 0 hemmelige felt") and Chat("Party: ingen"), "sammendrag i chatten")

-- Party
T.party = { party1 = "Brakk" }
T.partyAuras = { { "Battle Shout", 6673, 1100, 120 } }
SlashCmdList.CONTROL("debug")
s = db.runs[#db.runs]
check(#s.party == 1 and s.party[1].name == "Brakk" and s.party[1].auras.n == 1, "V3: party-buffer leses")

-- Kast utenfor kamp
Fire("UNIT_SPELLCAST_SENT", "player", "Brakk", "Cast-1", 1126)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 1126)
check(#db.casts == 2 and db.casts[2].spellID == 1126 and db.casts[2].name == "Mark of the Wild", "V4: kast logges med spell-ID")

-- Sted
Fire("TAXIMAP_OPENED")
Fire("ZONE_CHANGED_NEW_AREA")
check(#db.events >= 3 and db.events[#db.events].ev == "ZONE_CHANGED_NEW_AREA", "V8: steder logges")

-- Alt blir hemmelig (som i kamp i WoW Forever): ingenting skal krasje
T.secret = true
T.secretItems = true
T.combat = true
local ok, err = pcall(Fire, "PLAYER_REGEN_DISABLED")
check(ok, "i kamp med hemmelige verdier: ingen krasj " .. tostring(err))
local c = db.combat[#db.combat]
check(c and c.reason == "i kamp" and c.combat == true, "øyeblikksbilde i kamp")
check(c.player.secretFields == 8 and c.player.list[1].name == "<hemmelig>", "V2: hemmelige felt telles og byttes ut")
check(c.party[1].name == "<hemmelig>" and c.party[1].guid == "<hemmelig>", "V9: hemmelig navn og GUID på party")
check(c.items[1].count == "<hemmelig>", "V6: hemmelig lager")
check(c.zone.zone == "<hemmelig>", "hemmelig sone")
ok, err = pcall(Fire, "UNIT_SPELLCAST_SUCCEEDED", "player", SECRET, SECRET)
check(ok and db.casts[#db.casts].spellID == "<hemmelig>" and db.casts[#db.casts].guidSecret == true, "V4: hemmelig spell-ID i kamp logges uten krasj " .. tostring(err))
ok, err = pcall(SlashCmdList.CONTROL, "debug")
check(ok and Chat("spell-ID hemmelig i kamp: 1"), "/control debug i kamp: ingen krasj " .. tostring(err))
ok, err = pcall(Fire, "ZONE_CHANGED")
check(ok, "sted i kamp: ingen krasj " .. tostring(err))
SlashCmdList.CONTROL("debug knapp")
check(Chat("bare vises og skjules utenfor kamp"), "testknapper avvises i kamp")
T.secret = false
T.secretItems = false
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
check(db.combat[#db.combat].reason == "etter kamp", "øyeblikksbilde etter kamp")

-- Testknapper (V5)
SlashCmdList.CONTROL("debug knapp")
check(Chat("Testknapper vist"), "testknapper vises")
Fire("ADDON_ACTION_BLOCKED", "Control", "CastSpellByID()")
Fire("UI_ERROR_MESSAGE", 51, "Out of range.")
check(#db.errors == 2 and db.errors[1].b == "CastSpellByID()" and db.errors[2].b == "Out of range.", "V5: blokkerte handlinger og feilmeldinger logges")
SlashCmdList.CONTROL("debug tøm")
check(#db.runs == 0 and #db.casts == 0 and #db.errors == 0 and Chat("Loggen er tømt"), "/control debug tøm")
return n, fails
