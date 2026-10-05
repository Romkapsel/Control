-- Control: lesing av egne buffer og bagger (SPEC §12.2, §12.3). Gir tilstanden Rules.lua trenger (SPEC §5.3).
-- Buffer leses bare når spillet tillater det (C_Secrets.ShouldAurasBeSecret, fase 0: stengt i all kamp).
-- Ellers teller vi ned fra det vi visste, eller fra et bekreftet trykk (Track.lua). Lageret kan alltid leses (V6).
local addonName, ns = ...

local Scan = {}
ns.Scan = Scan

local isSecretFn = issecretvalue
local function isSecret(v)
  if not isSecretFn then return false end
  local ok, res = pcall(isSecretFn, v)
  return (not ok) or res == true
end
Scan.isSecret = isSecret

local function now() return GetTime() end

------------------------------------------------------------------------
-- Spill-API med vern
------------------------------------------------------------------------

function Scan.AurasSecret()
  if C_Secrets and C_Secrets.ShouldAurasBeSecret then
    local ok, v = pcall(C_Secrets.ShouldAurasBeSecret)
    if not ok or isSecret(v) then return true end
    return v == true
  end
  return false
end

function Scan.SpellInfo(id)
  if not id then return nil end
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, i = pcall(C_Spell.GetSpellInfo, id)
    if ok and i and not isSecret(i.name) then return i.name, i.iconID end
    return nil
  end
  if GetSpellInfo then
    local name, _, icon = GetSpellInfo(id)
    return name, icon
  end
end

-- Kan spellen kastes nå (lært, reagens, mana)? Brukes for gruppeversjonen (Gift of the Wild osv.).
function Scan.SpellUsable(name)
  if not name then return false end
  local ok, usable = pcall(function()
    if C_Spell and C_Spell.IsSpellUsable then return C_Spell.IsSpellUsable(name) end
    return IsUsableSpell(name)
  end)
  return ok and not isSecret(usable) and usable == true
end

-- Har spellen ingen rekkevidde (kastes på deg selv og treffer gruppa, som warrior shouts)? Fra maxRange i
-- spillets spell-info: 0 = ingen rekkevidde. Vet vi ikke, svarer vi nei – da oppfører knappen seg som før.
local selfCastCache = {}
function Scan.SelfCast(e)
  local key = e.spellId or e.name
  if key == nil then return false end
  if selfCastCache[key] ~= nil then return selfCastCache[key] end
  local result = false
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, key)
    if ok and type(info) == "table" and not isSecret(info.maxRange) and type(info.maxRange) == "number" then
      result = info.maxRange == 0
    end
  elseif GetSpellInfo then
    local ok, _, _, _, _, _, maxRange = pcall(GetSpellInfo, key)
    if ok and not isSecret(maxRange) and type(maxRange) == "number" then result = maxRange == 0 end
  end
  selfCastCache[key] = result
  return result
end

function Scan.ItemCount(id)
  if not id then return 0 end
  local ok, c = pcall(function()
    if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(id) end
    return GetItemCount(id)
  end)
  if not ok or isSecret(c) or type(c) ~= "number" then return nil end
  return c
end

function Scan.ItemIcon(id)
  if C_Item and C_Item.GetItemIconByID then
    local ok, icon = pcall(C_Item.GetItemIconByID, id)
    if ok and icon and not isSecret(icon) then return icon end
  end
  return nil
end

function Scan.ItemInfo(id)
  local name, spell
  local okN, n = pcall(function()
    if C_Item and C_Item.GetItemNameByID then return C_Item.GetItemNameByID(id) end
    return (GetItemInfo(id))
  end)
  if okN and not isSecret(n) then name = n end
  local okS, s = pcall(function()
    if C_Item and C_Item.GetItemSpell then return C_Item.GetItemSpell(id) end
    return GetItemSpell(id)
  end)
  if okS and not isSecret(s) then spell = s end
  -- GetItemInfoInstant: itemID, type, subType, equipLoc, icon, classID, subClassID (pcall legger ok først)
  local okI, _, _, _, _, _, classID, subClassID = pcall(function()
    if C_Item and C_Item.GetItemInfoInstant then return C_Item.GetItemInfoInstant(id) end
    return GetItemInfoInstant(id)
  end)
  if not okI then classID, subClassID = nil, nil end
  return name, spell, classID, subClassID
end

-- Står «Well Fed» i itemets tooltip? (Ikke all mat gir buffen; vanlig brød og vann gjør det ikke.)
function Scan.TooltipHas(id, text)
  if not (C_TooltipInfo and C_TooltipInfo.GetItemByID) or not text then return false end
  local ok, data = pcall(C_TooltipInfo.GetItemByID, id)
  if not ok or not data or not data.lines then return false end
  for _, line in ipairs(data.lines) do
    local t = line.leftText
    if type(t) == "string" and not isSecret(t) and t:find(text, 1, true) then return true end
  end
  return false
end

------------------------------------------------------------------------
-- Egne buffer: navn → { left, duration } (nil = hemmelig eller ikke lesbar nå)
------------------------------------------------------------------------

function Scan.ReadAuras()
  if Scan.AurasSecret() then return nil end
  local out, t = {}, now()
  for i = 1, 40 do
    local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
    if not ok then return nil end
    if a == nil then break end
    local name, exp, dur = a.name, a.expirationTime, a.duration
    if isSecret(name) or isSecret(exp) or isSecret(dur) then return nil end
    if name then
      local expiresAt = (exp and exp > 0) and exp or math.huge -- tidspunkt, ikke «igjen»: lagret mellom lesinger
      local cur = out[name]
      if not cur or expiresAt > cur.expires then out[name] = { expires = expiresAt, duration = dur } end
    end
  end
  return out
end

------------------------------------------------------------------------
-- Tilstand per oppføring (SPEC §5.3)
------------------------------------------------------------------------

local seen = {}      -- id → buffen har vært på i økten (skiller «gått ut» fra «ikke på»)
local expires = {}   -- id → GetTime() da buffen går ut (math.huge = uten grense), sist kjent
local lastStatus = {}
Scan.confirmed = {}  -- id → { at, expires, waiting } fra Track.lua: et trykk som er bekreftet

local function hasBuff(e) return e.type == "spell" or e.type == "buffitem" end

-- Et bekreftet trykk (Track.lua): buffen regnes som på fra nå, med full varighet hvis vi kjenner den.
function Scan.Confirm(e, durations)
  local d
  for _, n in ipairs(e.auraNames or {}) do d = d or durations[n] end
  local t = now()
  seen[e.id] = true
  expires[e.id] = d and (t + d) or math.huge
  local food = false
  for _, n in ipairs(e.auraNames or {}) do if n == "Well Fed" or n == Scan.wellFed then food = true end end
  Scan.confirmed[e.id] = { at = t, waiting = food }
end

function Scan.State(db, auras)
  local st, t = {}, now()
  local durations = db.durations
  for _, e in ipairs(db.self or {}) do
    local s = {}
    if e.itemId then s.count = Scan.ItemCount(e.itemId) or (lastStatus[e.id] and lastStatus[e.id].count) or 0 end
    if hasBuff(e) then
      local conf = Scan.confirmed[e.id]
      if auras then
        local best
        for _, n in ipairs(e.auraNames or { e.name }) do
          local a = auras[n]
          if a and (not best or a.expires > best.expires) then best = a end
          if a and a.duration and a.duration > 0 then durations[n] = a.duration end
        end
        if best then
          seen[e.id] = true
          expires[e.id] = best.expires
          s.duration = best.duration
          Scan.confirmed[e.id] = nil
        elseif conf and conf.waiting and t - conf.at < 40 then
          -- Mat: «Well Fed» kommer først når du har spist ferdig (10–30 s). Trykket holder den «på» så lenge.
        else
          expires[e.id] = nil
          Scan.confirmed[e.id] = nil
        end
      end
      local exp = expires[e.id]
      local left
      if exp then left = (exp == math.huge) and math.huge or (exp - t) end
      if left and left <= 0 then left = nil end
      if not auras and not exp and lastStatus[e.id] and lastStatus[e.id].status then
        s.status = lastStatus[e.id].status -- hemmelig og ingenting å telle fra: som sist
      else
        s.status = ns.Rules.auraStatus(left, seen[e.id])
      end
      s.left = left
      if not s.duration then
        for _, n in ipairs(e.auraNames or {}) do s.duration = s.duration or durations[n] end
      end
    end
    lastStatus[e.id] = s
    st[e.id] = s
  end
  return st
end

------------------------------------------------------------------------
-- Gruppa (SPEC §9). Navn og GUID er lesbare i kamp (V9), buffene ikke (V3), rekkevidde aldri (V3).
-- Et medlem som er ute av syne, offline eller dødt, er ukjent: vist dempet, telles ikke (Q8).
------------------------------------------------------------------------

local function safe1(fn, ...)
  if not fn then return nil end
  local ok, a = pcall(fn, ...)
  if not ok or isSecret(a) then return nil end
  return a
end

function Scan.Party()
  local out = {}
  for i = 1, 4 do
    local unit = "party" .. i
    if safe1(UnitExists, unit) then
      local okC, _, class = pcall(UnitClass, unit)
      if not okC or isSecret(class) then class = nil end
      out[#out + 1] = {
        unit = unit,
        name = safe1(UnitName, unit),
        class = class,
        visible = safe1(UnitIsVisible, unit) ~= false,
        online = safe1(UnitIsConnected, unit) ~= false,
        dead = safe1(UnitIsDeadOrGhost, unit) == true,
      }
    end
  end
  return out
end

-- Buffene på ett medlem: navn → { expires, duration }, eller nil når de er hemmelige eller uleselige
function Scan.ReadUnitAuras(unit)
  if Scan.AurasSecret() then return nil end
  local out = {}
  for i = 1, 40 do
    local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
    if not ok then return nil end
    if a == nil then break end
    local name, exp, dur = a.name, a.expirationTime, a.duration
    if isSecret(name) or isSecret(exp) or isSecret(dur) then return nil end
    if name then
      local e = (exp and exp > 0) and exp or math.huge
      if not out[name] or e > out[name].expires then out[name] = { expires = e, duration = dur } end
    end
  end
  return out
end

function Scan.ReadPartyAuras(members)
  local out = {}
  for _, m in ipairs(members) do
    if m.visible and m.online and not m.dead then out[m.unit] = Scan.ReadUnitAuras(m.unit) end
  end
  return out
end

local partyKnown = {} -- entryId → navn → utløpstidspunkt (sist lest eller bekreftet); false = manglet
Scan.partyConfirmed = partyKnown

local function followed(e, m)
  if not e.onlyOn then return true end
  return m.name ~= nil and e.onlyOn[m.name] == true
end

-- Tilstand for gruppebuffene: members (alle som følges, med has = true/false/nil) og missingOn (bare de som mangler)
function Scan.PartyState(list, members, partyAuras, durations)
  local st, t = {}, now()
  for _, e in ipairs(list or {}) do
    local known = partyKnown[e.id] or {}
    partyKnown[e.id] = known
    local s = { members = {}, missingOn = {} }
    for _, m in ipairs(members) do
      if followed(e, m) then
        local has
        local auras = partyAuras and partyAuras[m.unit]
        if m.dead or not m.online then
          has = nil
        elseif auras then
          local best
          for _, n in ipairs(e.auraNames or { e.name }) do
            local a = auras[n]
            if a and (not best or a.expires > best) then best = a.expires end
            if a and a.duration and a.duration > 0 then durations[n] = a.duration end
          end
          if m.name then known[m.name] = best or false end
          has = best ~= nil
        elseif m.name and known[m.name] ~= nil then
          local exp = known[m.name]
          has = exp ~= false and exp > t -- i kamp eller ute av syne: det vi visste, telt ned
        end
        s.members[#s.members + 1] = { name = m.name or "?", unit = m.unit, class = m.class, has = has }
        if has == false then s.missingOn[#s.missingOn + 1] = { name = m.name or "?", unit = m.unit } end
      end
    end
    st[e.id] = s
  end
  return st
end

-- Et bekreftet kast på et medlem (eller på alle, for gruppeversjonen)
function Scan.ConfirmParty(e, targetName, group, members, durations)
  local d
  for _, n in ipairs(e.auraNames or {}) do d = d or durations[n] end
  if group then d = durations[e.groupSpell] or d end
  local exp = d and (now() + d) or math.huge
  local known = partyKnown[e.id] or {}
  partyKnown[e.id] = known
  if group then
    for _, m in ipairs(members) do if m.name then known[m.name] = exp end end
  elseif targetName then
    known[targetName] = exp
  end
end

------------------------------------------------------------------------
-- Samtale med en flight master (Daniel 5. okt): byvakta skal si fra før du trykker «I need a ride».
-- Kjennes igjen på et flyvalg i samtalen: type «taxi», taxi-ikonet (132057) eller teksten på valget.
-- Det samtalen inneholdt, lagres i ControlCharDB.debug.gossip, i tilfelle Forever gjør det annerledes.
------------------------------------------------------------------------

local TAXI_ICON = 132057 -- Interface/GossipFrame/TaxiGossipIcon
local TAXI_TEXT = { "I need a ride", "Show me where I can fly" }

local function taxiText(name)
  if type(name) ~= "string" or isSecret(name) then return false end
  for _, t in ipairs(TAXI_TEXT) do if name:find(t, 1, true) then return true end end
  return false
end

function Scan.GossipHasTaxi()
  local seen, found = {}, false
  if C_GossipInfo and C_GossipInfo.GetOptions then
    local ok, opts = pcall(C_GossipInfo.GetOptions)
    if ok and type(opts) == "table" then
      for _, o in ipairs(opts) do
        local icon, name, kind = o.icon, o.name, o.type
        if isSecret(icon) then icon = nil end
        if isSecret(name) then name = nil end
        if isSecret(kind) then kind = nil end
        seen[#seen + 1] = { icon = icon, name = name, type = kind }
        if icon == TAXI_ICON or kind == "taxi" or taxiText(name) then found = true end
      end
    end
  end
  if not found and GetGossipOptions then -- eldre klienter: tittel, type, tittel, type …
    local ok, list = pcall(function() return { GetGossipOptions() } end)
    if ok then
      for i = 1, #list - 1, 2 do
        seen[#seen + 1] = { name = list[i], type = list[i + 1] }
        if list[i + 1] == "taxi" or taxiText(list[i]) then found = true end
      end
    end
  end
  return found, seen
end

-- Er du fortsatt inne i stedet «name» ifølge kartet? (Et vertshus i Stormwind ligger på Stormwinds kart.)
-- Byvakta varsler ikke da, selv om spillet kaller vertshuset et eget sted. Kan ikke kartet leses: nei.
function Scan.InsideZone(name)
  if not name or not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then return false end
  local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
  if not ok or isSecret(id) or type(id) ~= "number" then return false end
  for _ = 1, 8 do
    local ok2, info = pcall(C_Map.GetMapInfo, id)
    if not ok2 or type(info) ~= "table" or isSecret(info.name) then return false end
    if info.name == name then return true end
    id = info.parentMapID
    if isSecret(id) or not id or id == 0 then return false end
  end
  return false
end

-- For testene
function Scan.Reset() seen, expires, lastStatus, Scan.confirmed = {}, {}, {}, {} end
