"""Kjører alle testene for Control i Lua 5.1 (lupa).

    python tests/run.py

- tests/test_*.lua  regelmotoren, i en helt tom Lua uten WoW-API (beviser at Rules.lua er ren)
- tests/mock_*.lua  hele addonen (alle filer i TOC) mot en falsk WoW-klient
I tillegg sjekkes kildekoden: ingen enkle bakstreker (ukjente teksturstier krasjer klienten) og interface i TOC.
"""
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TESTS = os.path.join(ROOT, "tests")
TOC = os.path.join(ROOT, "Control.toc")
ALLOWED_GLOBALS = {"ControlCharDB", "SLASH_CONTROL1", "SLASH_CONTROL2", "NS", "KlarsjekkDB",
                   "BINDING_HEADER_CONTROL", "BINDING_NAME_CLICK ControlNextBuff:LeftButton"}  # KlarsjekkDB settes av testen

MOCK = r"""
T = { chat = {}, now = 1000, handlers = {}, combat = false, secret = false, party = {}, auras = {},
      bags = { [0] = { 13510, 14529 } }, counts = { [13510] = 3, [14529] = 0 },
      mouse = { 0, 0 }, atlases = { CircleMaskScalable = true }, files = {}, texPaths = {}, atlasUsed = {},
      tooltip = { lines = {} } }
-- En hemmelig verdi: alt annet enn å lagre den eller sende den videre, feiler.
local function boom() error("attempt to use a secret value", 2) end
SECRET = setmetatable({}, { __tostring = boom, __concat = boom, __lt = boom, __le = boom, __add = boom,
                            __sub = boom, __index = boom, __len = boom, __call = boom })
function issecretvalue(v) return v == SECRET end
local function S(v) if T.secret then return SECRET end return v end

local function frame(name, kind)
  local f = { scripts = {}, shown = true, attrs = {}, points = {}, scale = 1, alpha = 1, name = name, kind = kind }
  function f:SetScript(k, fn) self.scripts[k] = fn end
  function f:GetScript(k) return self.scripts[k] end
  function f:HookScript(k, fn) -- som i spillet: flere kroker på samme skript kjøres etter hverandre
    local prev = self.scripts["hook" .. k]
    if prev then self.scripts["hook" .. k] = function(...) prev(...) fn(...) end else self.scripts["hook" .. k] = fn end
  end
  function f:SetRotation(r) self.rotation = r end
  function f:GetWidth() return self.width end
  function f:RegisterEvent(e) T.handlers[e] = T.handlers[e] or {} table.insert(T.handlers[e], self) end
  function f:RegisterUnitEvent(e) self:RegisterEvent(e) end
  function f:Show() self.shown = true end
  function f:Hide() self.shown = false end
  function f:SetShown(v) self.shown = v and true or false end
  function f:IsShown() return self.shown end
  function f:SetAttribute(k, v) self.attrs[k] = v end
  function f:GetAttribute(k) return self.attrs[k] end
  function f:CreateTexture() return frame(nil, "Texture") end
  function f:CreateMaskTexture() return frame(nil, "Mask") end
  function f:CreateLine() return frame(nil, "Line") end
  function f:CreateFontString() return frame(nil, "FontString") end
  function f:SetText(t) self.text = t end
  function f:GetText() return self.text end
  function f:SetFont() return true end
  function f:SetTexture(p) if type(p) == "string" then T.texPaths[p] = true end self.texture = p end
  function f:SetTexCoord(...) self.coords = { ... } end
  function f:SetAtlas(a) T.atlasUsed[a] = true self.atlas = a end
  function f:SetColorTexture(r, g, b, a) self.color = { r, g, b, a } end
  function f:SetVertexColor(r, g, b) self.vertex = { r, g, b } end
  function f:SetAlpha(a) self.alpha = a end
  function f:GetAlpha() return self.alpha end
  function f:SetScale(s) self.scale = s end
  function f:GetScale() return self.scale end
  function f:GetEffectiveScale() return 1 end
  function f:ClearAllPoints() self.points = {} end
  function f:SetPoint(...) table.insert(self.points, { ... }) end
  function f:GetPoint() local p = self.points[1] if p then return p[1], p[2], p[3], p[4], p[5] end end
  function f:GetCenter() return T.center[1], T.center[2] end
  function f:StartMoving() T.startedMoving = (T.startedMoving or 0) + 1 end
  function f:StopMovingOrSizing() if T.dragTo then self.points = { { "CENTER", UIParent, "BOTTOMLEFT", T.dragTo[1], T.dragTo[2] } } end end
  function f:SetClampRectInsets(l, r, t, b) self.clamp = { l, r, t, b } end
  function f:GetName() return name end
  function f:IsMouseOver() return self.mouse or false end
  function f:GetTexture() return self.texture end
  function f:SetFrameLevel(l) self.level = l end
  function f:GetFrameLevel() return self.level or 1 end
  function f:SetDesaturated(v) self.desat = v end
  function f:SetWidth(w) self.width = w end
  function f:SetHeight(h) self.height = h end
  function f:SetSize(w, h) self.width, self.height = w, h end
  function f:SetThickness(t) self.thickness = t end
  function f:EnableMouse(v) self.mouseEnabled = v end
  function f:GetMousePosition() if T.mousePos then return T.mousePos[1], T.mousePos[2] end end
  function f:GetFrameRef(k) return self.refs and self.refs[k] end
  function f:SetMinMaxValues(a, b) self.minv, self.maxv = a, b end
  function f:SetValue(v)
    if self.minv then v = math.max(self.minv, math.min(self.maxv, v)) end
    self.value = v
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
  end
  function f:GetValue() return self.value end
  function f:CreateAnimationGroup()
    local g = frame(nil, "AnimationGroup")
    g.playing = false
    function g:Play() self.playing = true self.plays = (self.plays or 0) + 1 end
    function g:Stop() self.playing = false end
    function g:IsPlaying() return self.playing end
    function g:CreateAnimation() return frame(nil, "Animation") end
    return g
  end
  return setmetatable(f, { __index = function(_, k) if type(k) == "string" and k:match("^%u") then return function() end end end })
end
T.center = { 500, 400 }
function CreateFrame(kind, name, parent, template)
  local f = frame(name, kind)
  f.template = template
  if parent then
    parent.children = parent.children or {}
    table.insert(parent.children, f)
  end
  function f:GetChildren() return unpack(self.children or {}) end
  return f
end
-- Sikre skript (restricted Lua): lagres ved WrapScript og kjøres av SecureClick, som spillet gjør etter OnClick.
function SecureHandlerWrapScript(f, script, header, pre, post) f.wrap = { header = header, pre = pre, post = post } end
function SecureHandlerSetFrameRef(f, k, r) f.refs = f.refs or {} f.refs[k] = r end
local function secureEnv(b, mouse, owner)
  return { self = b, owner = owner, button = mouse,
           SecureCmdOptionParse = function(s) if s:find("[combat]", 1, true) then return T.combat and "k" or "u" end end,
           newtable = function(...) return { ... } end }
end
function SecureClick(b, mouse)
  if b.scripts.hookPreClick then b.scripts.hookPreClick(b, mouse) end
  if b.attrs._onclick then -- SecureHandlerClickTemplate
    local chunk = assert(loadstring(b.attrs._onclick))
    setfenv(chunk, secureEnv(b, mouse))
    chunk()
  end
  if b.wrap and b.wrap.post ~= "" then
    -- Som i spillet: etter-delen kjøres bare når før-delen returnerer en beskjed (andre returverdi ~= nil)
    local message
    if b.wrap.pre and b.wrap.pre ~= "" then
      local pre = assert(loadstring(b.wrap.pre))
      setfenv(pre, secureEnv(b, mouse, b.wrap.header))
      local _, msg = pre()
      message = msg
    end
    if message ~= nil then
      local chunk = assert(loadstring(b.wrap.post))
      setfenv(chunk, secureEnv(b, mouse, b.wrap.header))
      chunk()
    end
  end
  if b.scripts.hookPostClick then b.scripts.hookPostClick(b, mouse) end
end
UIParent = frame("UIParent")
function UIParent:GetHeight() return 768 end
GameTooltip = frame("GameTooltip")
function GameTooltip:SetOwner(o) T.tooltip = { lines = {}, owner = o } end
function GameTooltip:IsOwned(o) return T.tooltip.owner == o and not T.tooltip.hidden end
function GameTooltip:Show() T.tooltip.hidden = false end
NumberFontNormal = {}
function GameTooltip:SetText(t) T.tooltip.text = t end
function GameTooltip:AddLine(t) table.insert(T.tooltip.lines, t) end
function GameTooltip:Hide() T.tooltip.hidden = true end
GameFontNormalHuge = {}
SlashCmdList = {}
NUM_BAG_SLOTS = 4
WOW_PROJECT_ID = 99
function print(s) table.insert(T.chat, s) end
function Chat(p) for _, s in ipairs(T.chat) do if s:find(p, 1, true) then return true end end return false end
function date() return "2026-10-03 23:59:00" end
function GetTime() return T.now end
function GetCursorPosition() return T.mouse[1], T.mouse[2] end
function IsShiftKeyDown() return T.shift or false end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
function GetFileIDFromPath(p) return T.files[p] end
C_Texture = { GetAtlasInfo = function(a) if T.atlases[a] then return { width = 64 } end end }
function GetBuildInfo() return "1.60.1", "70205", "Oct 2 2026", 16001 end
function GetRealZoneText() return S(T.zone or "Stormwind City") end
function UnitFactionGroup() return "Alliance", "Alliance" end
function UnitOnTaxi() return T.onTaxi or false end
StaticPopupDialogs = {}
function StaticPopup_Show(which, a1, a2, data) T.popup = { which = which, a1 = a1, data = data } return {} end
function GetWeaponEnchantInfo()
  local w = T.wench or {}
  return S(w.mh ~= nil), S(w.mh), S(w.mhCharges or 0), S(0), S(w.oh ~= nil), S(w.oh), S(0), S(0)
end
function GetInventoryItemID(unit, slot) return T.equip and T.equip[slot] end
function GetInventoryItemDurability(slot) local d = T.dura and T.dura[slot] if d then return d[1], d[2] end end
function UnitHealth() return S(T.hp or 800) end
function UnitHealthMax() return S(1000) end
function UnitPower(u, t) return S(T.mana or 500) end
function UnitPowerMax(u, t) return S(1000) end
function UnitPowerType() return 0 end
function PlaySoundFile(id, channel) T.soundFiles = T.soundFiles or {} table.insert(T.soundFiles, id) return T.soundOk ~= false end
function PlaySound(id) T.soundKits = T.soundKits or {} table.insert(T.soundKits, id) return true end
function UnitPosition(u) local p = T.pos and T.pos[u] if p then return S(p[1]), S(p[2]), 0, 0 end end
function CheckInteractDistance(u, i) if T.secret then return SECRET end return (T.near and T.near[u]) or false end
C_GossipInfo = { GetOptions = function() return T.gossip or {} end }
function GetSubZoneText() return S("Trade District") end
C_Map = { GetBestMapForUnit = function() return S(T.mapId or 1453) end,
          GetMapInfo = function(id) return T.maps and T.maps[id] end }
function IsInInstance() return false, "none" end
function IsResting() return S(true) end
function InCombatLockdown() return T.combat end
function GetCVar() return "1" end
C_Timer = { After = function(_, fn) fn() end, NewTicker = function(_, fn) T.ticker = fn end }
function Tick() if T.ticker then T.ticker() end end
C_Secrets = { ShouldAurasBeSecret = function() return T.secret end }
C_UnitAuras = { GetAuraDataByIndex = function(unit, i)
  local list = unit == "player" and T.auras or ((T.pa and T.pa[unit]) or T.partyAuras or {})
  local a = list[i]
  if not a then return nil end
  return { name = S(a[1]), spellId = S(a[2]), expirationTime = S(a[3]), duration = S(a[4]), sourceUnit = S("player") }
end }
function UnitExists(u) return T.party[u] ~= nil end
function UnitName(u) if T.namesSecret then return SECRET end return T.party[u] end -- lesbare i kamp (V9); vernet testes med T.namesSecret
function UnitGUID(u) return S("Player-1-" .. tostring(T.party[u])) end
function UnitClass(u) local c = (T.partyClass and T.partyClass[u]) or "WARRIOR" return c, S(c) end
function UnitIsVisible(u) return not (T.hidden and T.hidden[u]) end
function UnitIsConnected(u) return not (T.offline and T.offline[u]) end
function UnitIsDeadOrGhost(u) return (T.deadUnits and T.deadUnits[u]) or false end
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
function UnitInRange() return S(true), true end
C_Container = { GetContainerNumSlots = function(b) return T.bags[b] and #T.bags[b] or 0 end,
                GetContainerNumFreeSlots = function(b) if T.free then local f = T.free[b] if f then return f[1], f[2] or 0 end return 0, 0 end return (b == 0) and 16 or 0, 0 end, -- standard: 16 ledige
                GetContainerItemID = function(b, s) return T.bags[b] and T.bags[b][s] end }
T.itemNames = { [13510] = "Flask of the Titans", [14529] = "Runecloth Bandage", [21023] = "Dirge's Kickin' Chimaerok Chops",
                [13446] = "Major Healing Potion", [4540] = "Tough Hunk of Bread" }
T.itemSpells = { [13510] = { "Flask of the Titans", 17626 }, [21023] = { "Food", 433 }, [13446] = { "Healing Potion", 17534 },
                 [4540] = { "Food", 433 }, [14529] = { "First Aid", 18610 } }
T.itemClass = { [13510] = { 0, 3 }, [14529] = { 0, 7 }, [21023] = { 0, 5 }, [13446] = { 0, 1 }, [4540] = { 0, 5 } }
T.tooltips = { [21023] = { "Dirge's Kickin' Chimaerok Chops", "Use: ... If you spend at least 10 seconds eating you will become well fed and gain 25 Stamina." },
               [4540] = { "Tough Hunk of Bread", "Use: Restores 61 health over 18 sec." } }
C_TooltipInfo = { GetItemByID = function(id)
  local t = T.tooltips[id]
  if not t then return nil end
  local lines = {}
  for i, s in ipairs(t) do lines[i] = { leftText = s } end
  return { lines = lines }
end }
-- Lageret er lesbart i kamp (fase 0, V6). T.secretItems gjør det hemmelig likevel, for å teste vernet.
C_Item = { GetItemCount = function(id) local c = T.counts[id] or 0 if T.secretItems then return SECRET end return c end,
           GetItemSpell = function(id) local s = T.itemSpells[id] if s then return S(s[1]), S(s[2]) end end,
           GetItemNameByID = function(id) return T.itemNames[id] end,
           GetItemInfoInstant = function(id) local c = T.itemClass[id] or {} return id, "", "", "", 100 + id, c[1], c[2] end,
           GetItemIconByID = function(id) return 100 + id end }
Enum = { SpellBookSpellBank = { Player = 0 } }
local BOOK = { { name = "Mark of the Wild", subName = "Rank 3", spellID = 5232 }, { name = "Wrath", spellID = 5176 },
               { name = "Thorns", subName = "Rank 2", spellID = 782 } }
C_SpellBook = { GetNumSpellBookSkillLines = function() return 1 end,
                GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #BOOK } end,
                GetSpellBookItemInfo = function(i) return BOOK[i] end }
T.spellNames = { [1126] = "Mark of the Wild", [5232] = "Mark of the Wild", [17626] = "Flask of the Titans",
                 [19705] = "Well Fed", [433] = "Food", [5176] = "Wrath" }
C_Spell = { GetSpellInfo = function(id) local n = T.spellNames[id] if n then return { name = n, iconID = 1000 + id, maxRange = T.spellRange and T.spellRange[id] } end end,
            IsSpellUsable = function(name) if T.usable and T.usable[name] ~= nil then return T.usable[name] end return true end }
function GetCursorInfo() if T.cursor then return unpack(T.cursor) end end
function ClearCursor() T.cursor = nil end
function Fire(e, ...) for _, f in ipairs(T.handlers[e] or {}) do f.scripts.OnEvent(f, e, ...) end end
function GlobalSnapshot() local s = {} for k in pairs(_G) do s[k] = true end return s end
"""


def toc_files():
    return [ln.strip() for ln in open(TOC, encoding="utf-8") if ln.strip() and not ln.startswith("#")]


def src(rel):
    return open(os.path.join(ROOT, *rel.split("\\")), encoding="utf-8").read()


def collect(n, fails):
    return n, (list(fails.values()) if fails else [])


def run_mock(test_file, prelude=""):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    if prelude:
        lua.execute(prelude)
    lua.execute("GLOBALS_BEFORE = {}; GLOBALS_BEFORE = GlobalSnapshot()")
    ns = lua.table()
    lua.globals().NS = ns
    load = lua.eval('function(src, name, ns) local f = assert(loadstring(src, name)); f("Control", ns) end')
    for f in toc_files():
        load(src(f), f, ns)
    n, fails = collect(*lua.execute(open(os.path.join(TESTS, test_file), encoding="utf-8").read()))
    # Hver bildesti addonen ba om under testen: våre egne må finnes i Media/, og spillets egne filer brukes ikke
    paths = lua.eval('function() local t = {} for p in pairs(T.texPaths) do t[#t+1] = p end return t end')()
    for p in paths.values():
        n += 1
        prefix = "Interface\\AddOns\\Control\\Media\\"
        if not p.startswith(prefix):
            fails.append("teksturfil utenfor Media/: " + p)
        elif not os.path.isfile(os.path.join(ROOT, "Media", p[len(prefix):] + ".tga")):
            fails.append("bildet finnes ikke: " + p)
    leaks = lua.eval('function() local t = {} for k in pairs(_G) do if not GLOBALS_BEFORE[k] then t[#t+1] = tostring(k) end end return t end')()
    extra = [k for k in leaks.values() if k not in ALLOWED_GLOBALS]
    n += 1
    if extra:
        fails.append("nye globale navn: " + ",".join(extra))
    return n, fails


def run_bare(test_file):
    bare = lua51.LuaRuntime(unpack_returned_tuples=True)
    bare.execute("GLOBALS_BEFORE = {}; for k in pairs(_G) do GLOBALS_BEFORE[k] = true end")
    ns = bare.table()
    bare.globals().NS = ns
    load = bare.eval('function(src, name, ns) local f = assert(loadstring(src, name)); f("Control", ns) end')
    for f in ("Locale\\nbNO.lua", "Rules.lua"):
        load(src(f), f, ns)
    leaks = bare.eval('function() local t = {} for k in pairs(_G) do if not GLOBALS_BEFORE[k] and k ~= "NS" then t[#t+1] = tostring(k) end end return table.concat(t, ",") end')()
    n, fails = collect(*bare.execute(open(os.path.join(TESTS, test_file), encoding="utf-8").read()))
    n += 1
    if leaks:
        fails.append("regelmotoren lager globale navn: " + leaks)
    return n, fails


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    total, bad = 0, 0

    def report(label, n, fails):
        nonlocal total, bad
        total += n
        bad += len(fails)
        for m in fails:
            print("FEIL [%s]:" % label, m)

    toc = open(TOC, encoding="utf-8").read()
    static = []
    for f in toc_files():
        if re.search(r'(?<!\\)\\(?![\\nrt"\'0-9])', src(f)):
            static.append("enkel bakstrek i " + f)
    if not re.search(r"^## Interface: 16001", toc, re.M):
        static.append("interface 16001 mangler i TOC")
    # Egne bilder: en sti som ikke finnes, krasjer Forever-klienten. Hvert bilde koden ber om – Style.Image(x, "navn",
    # Style.Media("navn"), eller et navn i anførselstegn som begynner som et av bildene – må ha en Media/navn.tga
    # som spillet kan lese: ukomprimert (type 2), 32 bit med alfa, sider som er potenser av 2.
    # (I tillegg sjekker run_mock hver bildesti testene faktisk satte.)
    media = set()
    for f in toc_files():
        text = src(f)
        media.update(re.findall(r'Style\.(?:Image\(\s*[\w.]+\s*,|Media\()\s*"(\w+)"', text))
        media.update(re.findall(r'"((?:sym|medal|chevron)_\w+)"', text))
    if len(media) < 10:
        static.append("fant for få bilder i koden (%d) – sjekken leter kanskje feil" % len(media))
    for name in sorted(media):
        path = os.path.join(ROOT, "Media", name + ".tga")
        if not os.path.isfile(path):
            static.append("bildet finnes ikke: Media/%s.tga" % name)
            continue
        h = open(path, "rb").read(18)
        w, hgt = h[12] | h[13] << 8, h[14] | h[15] << 8
        if h[2] != 2 or h[16] != 32 or w & (w - 1) or hgt & (hgt - 1):
            static.append("Media/%s.tga: må være ukomprimert 32 bit med sider som er potenser av 2" % name)
    report("kildekode", len(toc_files()) + 2 + len(media), static)

    for name in sorted(os.listdir(TESTS)):
        try:
            if name.startswith("test_") and name.endswith(".lua"):
                report(name, *run_bare(name))
            elif name.startswith("mock_") and name.endswith(".lua"):
                report(name, *run_mock(name))
        except Exception as e:
            report(name, 1, ["krasjet: " + str(e).strip().splitlines()[0]])
    print("%d/%d sjekker ok" % (total - bad, total))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
