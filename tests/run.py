"""Kjører Control i Lua 5.1 (lupa) mot en falsk WoW-klient.

    python tests/run.py

Fase 0: Debug.lua skal laste, svare på /control debug og aldri krasje eller lekke globale navn,
også når klienten gir «hemmelige» verdier (secret values) slik WoW Forever gjør i kamp.
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC = os.path.join(ROOT, "Control.toc")

MOCK = r"""
T = { chat = {}, now = 1000, handlers = {}, combat = false, secret = false, party = {}, auras = {},
      bags = { [0] = { 13510, 14529 } }, counts = { [13510] = 3, [14529] = 0 }, timers = {} }
-- En hemmelig verdi: alt annet enn å lagre den eller sende den videre, feiler.
local function boom() error("attempt to use a secret value", 2) end
SECRET = setmetatable({}, { __tostring = boom, __concat = boom, __lt = boom, __le = boom, __add = boom,
                            __sub = boom, __index = boom, __len = boom, __call = boom })
function issecretvalue(v) return v == SECRET end
local function S(v) if T.secret then return SECRET end return v end

local function frame()
  local f = { scripts = {}, shown = true, attrs = {} }
  function f:SetScript(k, fn) self.scripts[k] = fn end
  function f:HookScript(k, fn) self.scripts["hook" .. k] = fn end
  function f:RegisterEvent(e) T.handlers[e] = self end
  function f:RegisterUnitEvent(e) T.handlers[e] = self end
  function f:Show() self.shown = true end
  function f:Hide() self.shown = false end
  function f:IsShown() return self.shown end
  function f:SetAttribute(k, v) self.attrs[k] = v end
  function f:CreateTexture() return frame() end
  function f:CreateFontString() return frame() end
  return setmetatable(f, { __index = function(_, k) if type(k) == "string" and k:match("^%u") then return function() end end end })
end
function CreateFrame() return frame() end
UIParent = frame()
SlashCmdList = {}
NUM_BAG_SLOTS = 4
WOW_PROJECT_ID = 99
function print(s) table.insert(T.chat, s) end
function Chat(p) for _, s in ipairs(T.chat) do if s:find(p, 1, true) then return true end end return false end
function date() return "2026-10-03 23:59:00" end
function GetTime() return T.now end
function GetBuildInfo() return "1.60.1", "70170", "Oct 1 2026", 16001 end
function GetRealZoneText() return S("Stormwind City") end
function GetSubZoneText() return S("Trade District") end
C_Map = { GetBestMapForUnit = function() return S(1453) end }
function IsInInstance() return false, "none" end
function IsResting() return S(true) end
function InCombatLockdown() return T.combat end
function GetCVar() return "1" end
C_Timer = { After = function(_, fn) fn() end }
C_Secrets = { ShouldAurasBeSecret = function() return T.secret end }
C_UnitAuras = { GetAuraDataByIndex = function(unit, i)
  local list = unit == "player" and T.auras or (T.partyAuras or {})
  local a = list[i]
  if not a then return nil end
  return { name = S(a[1]), spellId = S(a[2]), expirationTime = S(a[3]), duration = S(a[4]), sourceUnit = S("player") }
end }
function UnitExists(u) return T.party[u] ~= nil end
function UnitName(u) return S(T.party[u]) end
function UnitGUID(u) return S("Player-1-" .. tostring(T.party[u])) end
function UnitClass(u) return "Warrior", S("WARRIOR") end
function UnitInRange() return S(true), true end
C_Container = { GetContainerNumSlots = function(b) return T.bags[b] and #T.bags[b] or 0 end,
                GetContainerItemID = function(b, s) return T.bags[b] and T.bags[b][s] end }
C_Item = { GetItemCount = function(id) return S(T.counts[id] or 0) end,
           GetItemSpell = function(id) if id == 13510 then return S("Flask of the Titans"), S(17626) end end,
           GetItemIconByID = function(id) return 100 + id end }
Enum = { SpellBookSpellBank = { Player = 0 } }
local BOOK = { { name = "Mark of the Wild", subName = "Rank 3", spellID = 5232 }, { name = "Wrath", spellID = 5176 },
               { name = "Thorns", subName = "Rank 2", spellID = 782 } }
C_SpellBook = { GetNumSpellBookSkillLines = function() return 1 end,
                GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #BOOK } end,
                GetSpellBookItemInfo = function(i) return BOOK[i] end }
C_Spell = { GetSpellInfo = function(id) if id == 1126 then return { name = "Mark of the Wild", iconID = 1 } end end }
function GetCursorInfo() if T.cursor then return unpack(T.cursor) end end
function ClearCursor() T.cursor = nil end
function Fire(e, ...) local f = T.handlers[e] if f then f.scripts.OnEvent(f, e, ...) end end
function GlobalSnapshot() local s = {} for k in pairs(_G) do s[k] = true end return s end
"""

SCENARIO = r"""
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end

Fire("ADDON_LOADED", "SomethingElse")
check(ControlCharDB == nil, "ADDON_LOADED for en annen addon rører ingenting")
Fire("ADDON_LOADED", "Control")
local db = ControlCharDB and ControlCharDB.debug
check(db and db.runs and db.casts and db.events and db.clicks and db.combat, "lagringen er satt opp")
check(SlashCmdList.CONTROL and SLASH_CONTROL1 == "/control" and SLASH_CONTROL2 == "/ctl", "/control og /ctl finnes")

-- Vanlige verdier, ute av kamp
T.auras = { { "Mark of the Wild", 1126, 2800, 1800 }, { "Well Fed", 19705, 1900, 900 } }
Fire("PLAYER_ENTERING_WORLD")
check(#db.runs == 1 and db.runs[1].reason == "innlogging", "øyeblikksbilde ved innlogging")
SlashCmdList.CONTROL("debug")
local s = db.runs[#db.runs]
check(s.client.interface == 16001 and s.client.build == "70170", "V1: build og interface lagres")
check(s.zone.zone == "Stormwind City" and s.zone.mapID == 1453, "sted lagres")
check(s.player.n == 2 and s.player.secretFields == 0 and s.player.list[1].name == "Mark of the Wild", "V2: egne buffer leses")
check(#s.items == 2 and s.items[1].count == 3 and s.items[1].spell == "Flask of the Titans", "V6/V7: lager og spell på item")
check(#s.spellbook == 2 and s.spellbook[1].rank == "Rank 3" and s.spellbook[1].id == 5232, "V7: buffer i spellboken med rank og ID")
check(s.ids[1].name == "Mark of the Wild" and s.ids[2].name == nil, "V7: hvilke ID-er klienten kjenner")
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

-- Bare tillatte globale navn
local extra = {}
for k in pairs(_G) do
  if not GLOBALS_BEFORE[k] and k ~= "ControlCharDB" and k ~= "SLASH_CONTROL1" and k ~= "SLASH_CONTROL2" then extra[#extra + 1] = tostring(k) end
end
check(#extra == 0, "nye globale navn: " .. table.concat(extra, ","))
return n, fails
"""


def toc_files():
    files = []
    for ln in open(TOC, encoding="utf-8"):
        ln = ln.strip()
        if ln and not ln.startswith("#"):
            files.append(ln)
    return files


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    total, bad = 0, 0

    # Kildekoden: ingen enkle bakstreker (ukjente teksturstier krasjer klienten), og versjonen står i TOC.
    toc = open(TOC, encoding="utf-8").read()
    for f in toc_files():
        src = open(os.path.join(ROOT, f), encoding="utf-8").read()
        total += 1
        if re.search(r'(?<!\\)\\(?![\\nrt"\'0-9])', src):
            bad += 1
            print("FEIL [kildekode]: enkel bakstrek i", f)
    total += 1
    if not re.search(r"^## Interface: 16001", toc, re.M):
        bad += 1
        print("FEIL [toc]: interface 16001 mangler")

    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute("GLOBALS_BEFORE = {}; GLOBALS_BEFORE = GlobalSnapshot()")
    ns = lua.table()
    lua.globals().NS = ns
    load = lua.eval('function(src, name, ns) local f = assert(loadstring(src, name)); f("Control", ns) end')
    for f in toc_files():
        load(open(os.path.join(ROOT, f), encoding="utf-8").read(), f, ns)
    lua.execute("GLOBALS_BEFORE.NS = true")
    try:
        n, fails = lua.execute(SCENARIO)
        fails = list(fails.values()) if fails else []
    except Exception as e:
        n, fails = 1, ["krasjet: " + str(e).strip().splitlines()[0]]
    total += n
    bad += len(fails)
    for m in fails:
        print("FEIL [fase 0]:", m)

    # Regelmotoren: i en helt tom Lua 5.1 uten WoW-API, så den beviselig er ren (SPEC §4, §17).
    for name in sorted(os.listdir(os.path.join(ROOT, "tests"))):
        if not (name.startswith("test_") and name.endswith(".lua")):
            continue
        bare = lua51.LuaRuntime(unpack_returned_tuples=True)
        bare.execute("GLOBALS_BEFORE = {}; for k in pairs(_G) do GLOBALS_BEFORE[k] = true end")
        ns = bare.table()
        bare.globals().NS = ns
        bload = bare.eval('function(src, name, ns) local f = assert(loadstring(src, name)); f("Control", ns) end')
        try:
            for f in ("Locale\\nbNO.lua", "Rules.lua"):
                bload(open(os.path.join(ROOT, f), encoding="utf-8").read(), f, ns)
            leaks = bare.eval('function() local t = {} for k in pairs(_G) do if not GLOBALS_BEFORE[k] and k ~= "NS" then t[#t+1] = tostring(k) end end return table.concat(t, ",") end')()
            n, fails = bare.execute(open(os.path.join(ROOT, "tests", name), encoding="utf-8").read())
            fails = list(fails.values()) if fails else []
            n += 1
            if leaks:
                fails.append("regelmotoren lager globale navn: " + leaks)
        except Exception as e:
            n, fails = 1, ["krasjet: " + str(e).strip().splitlines()[0]]
        total += n
        bad += len(fails)
        for m in fails:
            print("FEIL [%s]:" % name, m)
    print("%d/%d sjekker ok" % (total - bad, total))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
