-- Control, fase 0 (SPEC §18): finn ut hva WoW Forever lar en addon lese, før vi bygger på det (SPEC §2, V1–V9).
-- /control debug        tar et øyeblikksbilde nå og skriver et sammendrag i chatten
-- /control debug knapp  viser to testknapper (V5): dra en spell eller et item på dem og klikk
-- /control debug tøm    tømmer loggen
-- Alt lagres i ControlCharDB.debug. Spillet skriver det til disk ved /reload og utlogging; Claude leser det derfra.
-- Regel: en hemmelig verdi blir aldri regnet med, sammenlignet eller skrevet ut, bare byttet med «<hemmelig>».

local addonName, ns = ...

local isSecretFn = issecretvalue
local MAX_LOG, MAX_RUNS, MAX_COMBAT = 60, 12, 8

-- Navn på buffer vi ser etter i spellboken (V7) og ID-er vi vil vite om finnes i klienten.
local WATCH_NAMES = {
  "Mark of the Wild", "Gift of the Wild", "Thorns", "Omen of Clarity",
  "Power Word: Fortitude", "Prayer of Fortitude", "Divine Spirit", "Inner Fire",
  "Arcane Intellect", "Arcane Brilliance", "Frost Armor", "Ice Armor", "Mage Armor",
  "Blessing of", "Devotion Aura", "Retribution Aura", "Concentration Aura",
  "Demon Skin", "Demon Armor", "Lightning Shield", "Battle Shout", "Trueshot Aura",
}
local WATCH_IDS = { 1126, 21849, 467, 1243, 21562, 1459, 23028, 19740, 19742, 20217, 465, 6673, 324, 706, 19705 }

local db

------------------------------------------------------------------------
-- Trygge verdier
------------------------------------------------------------------------

local function isSecret(v)
  if not isSecretFn then return false end
  local ok, res = pcall(isSecretFn, v)
  return (not ok) or res == true
end

-- Gjør en verdi trygg å lagre og skrive ut.
local function safe(v)
  if isSecret(v) then return "<hemmelig>" end
  local t = type(v)
  if t == "number" or t == "string" or t == "boolean" or t == "nil" then return v end
  return "<" .. t .. ">"
end

-- Svar fra et pcall: «<feil>» bare når kallet feilet, ellers selve verdien (også nil og false).
local function try(ok, v)
  if not ok then return "<feil>" end
  return safe(v)
end

local function str(v)
  local s = safe(v)
  if s == nil then return "nil" end
  return tostring(s)
end

local function Say(msg) print("|cffffd100[Control]|r " .. msg) end

local function push(list, item, max)
  list[#list + 1] = item
  while #list > max do table.remove(list, 1) end
end

local function inCombat()
  local ok, v = pcall(InCombatLockdown)
  return ok and v == true
end

local function stamp()
  local ok, s = pcall(date, "%Y-%m-%d %H:%M:%S")
  return ok and s or "?"
end

local function now()
  local ok, t = pcall(GetTime)
  if ok and not isSecret(t) then return t end
  return 0
end

------------------------------------------------------------------------
-- V1: klient og sted
------------------------------------------------------------------------

local function buildInfo()
  local ok, version, build, bdate, toc = pcall(GetBuildInfo)
  if not ok then return { error = str(version) } end
  return { version = safe(version), build = safe(build), date = safe(bdate), interface = safe(toc),
           project = safe(WOW_PROJECT_ID) }
end

local function zoneInfo()
  local z = {}
  z.zone = safe(GetRealZoneText and GetRealZoneText())
  z.sub = safe(GetSubZoneText and GetSubZoneText())
  local okMap, mapID = pcall(function() return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") end)
  z.mapID = try(okMap, mapID)
  local okI, inside, kind = pcall(IsInInstance)
  z.inInstance, z.instanceType = try(okI, inside), try(okI, kind)
  z.resting = safe(IsResting and IsResting())
  return z
end

------------------------------------------------------------------------
-- V2, V3, V9: buffer på deg og på gruppa
------------------------------------------------------------------------

local function auraAt(unit, i)
  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    local a = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
    if a == nil then return nil end
    return { name = a.name, spellId = a.spellId, expirationTime = a.expirationTime, duration = a.duration,
             sourceUnit = a.sourceUnit }
  end
  local name, _, _, _, duration, expires, source, _, _, spellId = UnitBuff(unit, i)
  if name == nil then return nil end
  return { name = name, spellId = spellId, expirationTime = expires, duration = duration, sourceUnit = source }
end

local FIELDS = { "name", "spellId", "expirationTime", "duration" }

local function scanAuras(unit, keep)
  local out = { n = 0, secretFields = 0, list = {} }
  if C_Secrets and C_Secrets.ShouldAurasBeSecret then
    local ok, v = pcall(C_Secrets.ShouldAurasBeSecret)
    out.shouldBeSecret = try(ok, v)
  end
  for i = 1, 40 do
    local ok, a = pcall(auraAt, unit, i)
    if not ok then out.error = str(a) break end
    if a == nil then break end
    out.n = out.n + 1
    local e = {}
    for _, k in ipairs(FIELDS) do
      e[k] = safe(a[k])
      if e[k] == "<hemmelig>" then out.secretFields = out.secretFields + 1 end
    end
    e.sourceUnit = safe(a.sourceUnit)
    if #out.list < keep then out.list[#out.list + 1] = e end
  end
  return out
end

local function scanParty(keep)
  local out = {}
  for i = 1, 4 do
    local unit = "party" .. i
    local okE, exists = pcall(UnitExists, unit)
    if okE and exists == true then
      local m = { unit = unit }
      m.name = safe(UnitName(unit))
      m.guid = safe(UnitGUID(unit))
      local okC, _, class = pcall(UnitClass, unit)
      m.class = try(okC, class)
      local okR, inRange = pcall(UnitInRange, unit)
      m.inRange = try(okR, inRange)
      m.auras = scanAuras(unit, keep)
      out[#out + 1] = m
    end
  end
  return out
end

------------------------------------------------------------------------
-- V6: lager. V7: spellboken og ID-er
------------------------------------------------------------------------

local function itemCount(id)
  if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(id) end
  return GetItemCount(id)
end

local function bagItemID(bag, slot)
  if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
  return GetContainerItemID and GetContainerItemID(bag, slot)
end

local function numSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function scanItems(keep)
  local out, seen = {}, {}
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    local okN, n = pcall(numSlots, bag)
    for slot = 1, (okN and not isSecret(n) and n or 0) do
      local okI, id = pcall(bagItemID, bag, slot)
      if okI and id ~= nil and not isSecret(id) and not seen[id] and #out < keep then
        seen[id] = true
        local okC, c = pcall(itemCount, id)
        local okS, spellName, spellID = pcall(function()
          if C_Item and C_Item.GetItemSpell then return C_Item.GetItemSpell(id) end
          return GetItemSpell(id)
        end)
        local okT, _, _, _, _, _, classID, subClassID = pcall(function()
          if C_Item and C_Item.GetItemInfoInstant then return C_Item.GetItemInfoInstant(id) end
          return GetItemInfoInstant(id)
        end)
        out[#out + 1] = { id = id, count = try(okC, c),
                          spell = try(okS, spellName), spellID = try(okS, spellID),
                          class = try(okT, classID), subclass = try(okT, subClassID) }
      end
    end
  end
  return out
end

local function spellbookEntries()
  local list = {}
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and Enum and Enum.SpellBookSpellBank then
    for t = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local line = C_SpellBook.GetSpellBookSkillLineInfo(t)
      if line then
        for i = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
          local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
          if info then list[#list + 1] = { name = info.name, sub = info.subName, id = info.spellID } end
        end
      end
    end
  elseif GetNumSpellTabs then
    for t = 1, GetNumSpellTabs() do
      local _, _, offset, num = GetSpellTabInfo(t)
      for i = offset + 1, offset + num do
        local name, sub = GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell")
        local _, id = GetSpellBookItemInfo(i, BOOKTYPE_SPELL or "spell")
        list[#list + 1] = { name = name, sub = sub, id = id }
      end
    end
  end
  return list
end

local function scanSpellbook()
  local out = {}
  local ok, entries = pcall(spellbookEntries)
  if not ok then return { error = str(entries) } end
  for _, e in ipairs(entries) do
    if not isSecret(e.name) and type(e.name) == "string" then
      for _, w in ipairs(WATCH_NAMES) do
        if e.name:find(w, 1, true) then
          out[#out + 1] = { name = e.name, rank = safe(e.sub), id = safe(e.id) }
          break
        end
      end
    end
  end
  return out
end

local function spellName(id)
  if C_Spell and C_Spell.GetSpellInfo then
    local i = C_Spell.GetSpellInfo(id)
    return i and i.name
  end
  return GetSpellInfo and (GetSpellInfo(id))
end

local function checkIDs()
  local out = {}
  for _, id in ipairs(WATCH_IDS) do
    local ok, name = pcall(spellName, id)
    out[#out + 1] = { id = id, name = try(ok, name) }
  end
  return out
end

------------------------------------------------------------------------
-- Øyeblikksbilder
------------------------------------------------------------------------

local function snapshot(reason, full)
  local s = { reason = reason, at = stamp(), t = now(), combat = inCombat() }
  s.client = buildInfo()
  s.zone = zoneInfo()
  local ok, res = pcall(scanAuras, "player", full and 40 or 10)
  s.player = ok and res or { error = str(res) }
  ok, res = pcall(scanParty, full and 12 or 6)
  s.party = ok and res or { error = str(res) }
  ok, res = pcall(scanItems, 10)
  s.items = ok and res or { error = str(res) }
  if full then
    ok, res = pcall(scanSpellbook)
    s.spellbook = ok and res or { error = str(res) }
    ok, res = pcall(checkIDs)
    s.ids = ok and res or { error = str(res) }
    local okCV, keyDown = pcall(GetCVar, "ActionButtonUseKeyDown")
    s.useKeyDown = try(okCV, keyDown)
  end
  return s
end

------------------------------------------------------------------------
-- V4 og V8: hendelseslogg
------------------------------------------------------------------------

local CAST_EVENTS = { UNIT_SPELLCAST_SENT = true, UNIT_SPELLCAST_SUCCEEDED = true, UNIT_SPELLCAST_FAILED = true,
                      UNIT_SPELLCAST_INTERRUPTED = true }
local PLACE_EVENTS = { "TAXIMAP_OPENED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
                       "PLAYER_UPDATE_RESTING", "UPDATE_BATTLEFIELD_STATUS", "LFG_PROPOSAL_SHOW",
                       "TRANSPORT_ARRIVED", "CONFIRM_SUMMON" }

-- Hvorfor et klikk ikke ble til et kast: blokkert av taint, eller en feilmelding fra spillet (for langt unna osv.).
local ERROR_EVENTS = { "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "UI_ERROR_MESSAGE" }
local ERROR_SET = {}
for _, e in ipairs(ERROR_EVENTS) do ERROR_SET[e] = true end

local function logCast(event, ...)
  local args = { ... }
  -- SENT: unit, target, castGUID, spellID · de andre: unit, castGUID, spellID
  local spellID = (event == "UNIT_SPELLCAST_SENT") and args[4] or args[3]
  local guid = (event == "UNIT_SPELLCAST_SENT") and args[3] or args[2]
  push(db.casts, { ev = event, t = now(), combat = inCombat(), spellID = safe(spellID),
                   guidSecret = isSecret(guid), name = safe(spellID and not isSecret(spellID) and spellName(spellID)) },
       MAX_LOG)
end

local function logPlace(event)
  local e = zoneInfo()
  e.ev, e.t, e.at, e.combat = event, now(), stamp(), inCombat()
  push(db.events, e, MAX_LOG)
end

------------------------------------------------------------------------
-- V5: testknapper
------------------------------------------------------------------------

-- Fire varianter, fordi «Party1» med spell-ID ikke kastet noe 4. okt: spell etter navn, etter ID og som makro.
-- Klikket registreres bare på «ned» når ActionButtonUseKeyDown er på (ellers «opp»), så det ikke kommer to ganger.
local holder
local function spellNameOf(id)
  local ok, n = pcall(spellName, id)
  if ok and type(n) == "string" and not isSecret(n) then return n end
end

local function makeTestButton(parent, label, unit, mode, x)
  local b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
  b:SetSize(40, 40)
  b:SetPoint("LEFT", parent, "LEFT", x, 0)
  local okCV, keyDown = pcall(GetCVar, "ActionButtonUseKeyDown")
  if okCV and keyDown == "1" then b:RegisterForClicks("AnyDown") else b:RegisterForClicks("AnyUp") end
  b:SetAttribute("unit", unit)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetColorTexture(0.2, 0.2, 0.2, 1)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.label:SetPoint("TOP", b, "BOTTOM", 0, -2)
  b.label:SetText(label)
  b:SetScript("OnReceiveDrag", function(self)
    if inCombat() then return Say("Ikke i kamp.") end
    local kind, a, _, d = GetCursorInfo()
    if kind == "spell" then
      local id = d or a
      local name = spellNameOf(id)
      if mode == "macro" then
        if not name then return Say("Fant ikke navnet på spellen.") end
        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", "/cast [@" .. unit .. "] " .. name)
        self.what = "makro /cast [@" .. unit .. "] " .. name
      elseif mode == "name" then
        if not name then return Say("Fant ikke navnet på spellen.") end
        self:SetAttribute("type", "spell")
        self:SetAttribute("spell", name)
        self.what = "spell navn " .. name
      else
        self:SetAttribute("type", "spell")
        self:SetAttribute("spell", id)
        self.what = "spell ID " .. str(id)
      end
      local okI, info = pcall(function() return C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id) end)
      if okI and info and info.iconID then self.icon:SetTexture(info.iconID) end
    elseif kind == "item" then
      self:SetAttribute("type", "item")
      self:SetAttribute("item", "item:" .. a)
      self.what = "item " .. str(a)
      local okI, icon = pcall(function() return C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(a) end)
      if okI and icon then self.icon:SetTexture(icon) end
    else
      return
    end
    ClearCursor()
    Say(label .. ": " .. self.what .. " lagt på. Klikk for å teste.")
  end)
  b:HookScript("PostClick", function(self, mouse, down)
    push(db.clicks, { t = now(), at = stamp(), button = label, what = self.what or "tom", mouse = safe(mouse),
                      down = safe(down), combat = inCombat(), type = safe(self:GetAttribute("type")),
                      unit = safe(self:GetAttribute("unit")) }, MAX_LOG)
  end)
  return b
end

local function toggleTestButtons()
  if inCombat() then return Say("Testknappene kan bare vises og skjules utenfor kamp.") end
  if not holder then
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(240, 60)
    holder:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
    local t = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("BOTTOM", holder, "TOP", 0, 0)
    t:SetText("Control test (V5): dra samme spell på alle fire")
    makeTestButton(holder, "Meg navn", "player", "name", 6)
    makeTestButton(holder, "Meg ID", "player", "id", 64)
    makeTestButton(holder, "Meg makro", "player", "macro", 122)
    makeTestButton(holder, "Party1", "party1", "name", 180)
    holder:Hide()
  end
  if holder:IsShown() then holder:Hide() else holder:Show() end
  Say(holder:IsShown() and "Testknapper vist. Dra en spell eller et item på dem, og klikk (også i kamp)."
      or "Testknapper skjult.")
end

------------------------------------------------------------------------
-- Sammendrag i chatten
------------------------------------------------------------------------

local function summary(s)
  local c = s.client or {}
  Say(("Klient %s (%s), interface %s · %s%s · instans: %s"):format(str(c.version), str(c.build), str(c.interface),
      str(s.zone.zone), (s.zone.sub and s.zone.sub ~= "" and s.zone.sub ~= "<hemmelig>") and (" / " .. str(s.zone.sub)) or "",
      str(s.zone.instanceType)))
  local p = s.player or {}
  Say(("Egne buffer: %s lest, %s hemmelige felt%s"):format(str(p.n), str(p.secretFields),
      p.error and (" · feil: " .. p.error) or ""))
  if s.party and #s.party > 0 then
    for _, m in ipairs(s.party) do
      Say(("  %s: %s, %s buffer, %s hemmelige felt"):format(m.unit, str(m.name), str(m.auras.n), str(m.auras.secretFields)))
    end
  else
    Say("Party: ingen (V3 og V9 krever en kompis i gruppa).")
  end
  local inC, secret = 0, 0
  for _, e in ipairs(db.casts) do
    if e.combat then
      inC = inC + 1
      if e.spellID == "<hemmelig>" then secret = secret + 1 end
    end
  end
  Say(("Kast logget: %d, i kamp: %d, spell-ID hemmelig i kamp: %d · klikk på testknapper: %d · steder: %d · feil/blokkert: %d"):format(
      #db.casts, inC, secret, #db.clicks, #db.events, #db.errors))
  Say("Lagret. /reload eller logg ut, så kan Claude lese svarene.")
end

------------------------------------------------------------------------
-- Avstand (Daniel 5. okt): hvilke måter å måle avstand til en kompis virker i Forever, i og utenfor kamp?
-- Til shouts: telle bare de som var nær nok, og la knappen lyse bare når noen som mangler er innenfor.
-- Knappen «Avstandstest» under Oppsett i menyen (slås på med /control avstand) lagrer ett bilde per trykk
-- i ControlCharDB.debug.range. Stå nær og langt unna en kompis, i og utenfor kamp, trykk, og gjør /reload.
------------------------------------------------------------------------

local MAX_RANGE = 40
-- Ting med kjent rekkevidde på vennlige mål (svaret fra IsItemInRange): bandasje, mistelteinen, scroll
local RANGE_ITEMS = { 1251, 21519, 1180, 1478 }
local RANGE_SPELLS = { "Mark of the Wild", "Battle Shout", "Power Word: Fortitude", "Arcane Intellect", "Blessing of Might" }

local function call(fn, ...)
  if not fn then return { "<finnes ikke>" } end
  local res = { pcall(fn, ...) }
  if not res[1] then return { "<feil>" } end
  local out = {}
  for i = 2, math.max(2, #res) do out[#out + 1] = safe(res[i]) end
  return out
end

local function mapPos(mapID, unit)
  if not (C_Map and C_Map.GetPlayerMapPosition) or not mapID then return { "<finnes ikke>" } end
  local ok, pos = pcall(C_Map.GetPlayerMapPosition, mapID, unit)
  if not ok then return { "<feil>" } end
  if pos == nil then return { "nil" } end
  if isSecret(pos) then return { "<hemmelig>" } end
  local ok2, x, y = pcall(function() return pos:GetXY() end)
  if not ok2 then return { "<feil>" } end
  return { safe(x), safe(y) }
end

local function rangeOf(unit, mapID, me)
  local r = { unit = unit }
  r.name = call(UnitName, unit)[1]
  r.visible = call(UnitIsVisible, unit)[1]
  r.pos = call(UnitPosition, unit)
  r.dist2 = call(UnitDistanceSquared, unit)
  r.inRange = call(UnitInRange, unit)
  r.interact = {}
  for i = 1, 4 do r.interact[i] = call(CheckInteractDistance, unit, i)[1] end
  r.items = {}
  local itemInRange = (C_Item and C_Item.IsItemInRange) or IsItemInRange
  for _, id in ipairs(RANGE_ITEMS) do r.items[tostring(id)] = call(itemInRange, id, unit)[1] end
  r.spells = {}
  local spellInRange = (C_Spell and C_Spell.IsSpellInRange) or IsSpellInRange
  for _, sp in ipairs(RANGE_SPELLS) do r.spells[sp] = call(spellInRange, sp, unit)[1] end
  r.map = mapPos(mapID, unit)
  -- Regnet avstand når begge posisjonene kan leses (UnitPosition gir y, x)
  local y1, x1, y2, x2 = me[1], me[2], r.pos[1], r.pos[2]
  if type(y1) == "number" and type(x1) == "number" and type(y2) == "number" and type(x2) == "number" then
    r.yards = math.floor(math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) * 10 + 0.5) / 10
  end
  return r
end

local function readable(v) return v ~= nil and v ~= "nil" and v ~= "<hemmelig>" and v ~= "<feil>" and v ~= "<finnes ikke>" end

function ns.RangeProbe()
  if not db then return end
  db.range = db.range or {}
  local okM, mapID = pcall(function() return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") end)
  if not okM or isSecret(mapID) then mapID = nil end
  local me = call(UnitPosition, "player")
  local s = { at = stamp(), t = now(), combat = inCombat(), zone = zoneInfo(), me = me, meMap = mapPos(mapID, "player"),
              members = {} }
  for i = 1, 4 do
    local unit = "party" .. i
    local okE, exists = pcall(UnitExists, unit)
    if okE and not isSecret(exists) and exists then s.members[#s.members + 1] = rangeOf(unit, mapID, me) end
  end
  push(db.range, s, MAX_RANGE)
  -- Kort svar i chatten: hva kunne leses for hver kompis
  Say(string.format(ns.L.RANGE_SAVED, #db.range, #s.members, s.combat and ns.L.RANGE_IN_COMBAT or ns.L.RANGE_OUT_COMBAT))
  for _, m in ipairs(s.members) do
    local got = {}
    if m.yards then got[#got + 1] = m.yards .. " yd" end
    if readable(m.dist2[1]) then got[#got + 1] = "avstand²" end
    if readable(m.inRange[1]) then got[#got + 1] = "i rekkevidde" end
    for i = 1, 4 do if readable(m.interact[i]) then got[#got + 1] = "nær(" .. i .. ")" break end end
    for _, v in pairs(m.items) do if readable(v) then got[#got + 1] = "ting" break end end
    for _, v in pairs(m.spells) do if readable(v) then got[#got + 1] = "spell" break end end
    if readable(m.map[1]) then got[#got + 1] = "kart" end
    Say("  " .. str(m.name) .. ": " .. (#got > 0 and table.concat(got, ", ") or ns.L.RANGE_NOTHING))
  end
  return s
end

------------------------------------------------------------------------
-- Hendelser og kommandoer
------------------------------------------------------------------------

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= addonName then return end
    ControlCharDB = ControlCharDB or {}
    db = ControlCharDB
    db.debug = db.debug or {}
    db = db.debug
    db.runs, db.casts, db.events, db.clicks, db.combat = db.runs or {}, db.casts or {}, db.events or {}, db.clicks or {}, db.combat or {}
    db.errors = db.errors or {}
    for _, e in ipairs(ERROR_EVENTS) do pcall(self.RegisterEvent, self, e) end
    for e in pairs(CAST_EVENTS) do pcall(self.RegisterUnitEvent, self, e, "player") end
    for _, e in ipairs(PLACE_EVENTS) do pcall(self.RegisterEvent, self, e) end
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    return
  end
  if not db then return end
  if CAST_EVENTS[event] then
    pcall(logCast, event, ...)
  elseif ERROR_SET[event] then
    local a, b = ...
    push(db.errors, { ev = event, t = now(), at = stamp(), combat = inCombat(), a = safe(a), b = safe(b) }, MAX_LOG)
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Ett sekund inn i kampen: les det samme som utenfor, og se hva som er hemmelig.
    C_Timer.After(1, function()
      local ok, s = pcall(snapshot, "i kamp", false)
      if ok then push(db.combat, s, MAX_COMBAT) end
    end)
  elseif event == "PLAYER_REGEN_ENABLED" then
    local ok, s = pcall(snapshot, "etter kamp", false)
    if ok then push(db.combat, s, MAX_COMBAT) end
  elseif event == "PLAYER_ENTERING_WORLD" then
    pcall(logPlace, event)
    local ok, s = pcall(snapshot, "innlogging", true)
    if ok then push(db.runs, s, MAX_RUNS) end
  else
    pcall(logPlace, event)
  end
end)

-- Kalles fra Core.lua for «/control debug …» (raw = teksten uten å endre bokstavene).
function ns.DebugCommand(raw)
  local msg = raw:lower()
  if not db then return Say("Ikke lastet ennå.") end
  if msg == "debug" then
    local ok, s = pcall(snapshot, "manuell", true)
    if not ok then return Say("Feil i øyeblikksbildet: " .. str(s)) end
    push(db.runs, s, MAX_RUNS)
    summary(s)
  elseif msg == "debug knapp" then
    toggleTestButtons()
  elseif raw == "debug tøm" or raw == "debug Tøm" or msg == "debug tom" then
    db.runs, db.casts, db.events, db.clicks, db.combat, db.errors = {}, {}, {}, {}, {}, {}
    Say("Loggen er tømt.")
  else
    Say("Skriv /control debug, /control debug knapp eller /control debug tøm.")
  end
end

-- For testene
ns.snapshot = snapshot
ns.safe = safe
