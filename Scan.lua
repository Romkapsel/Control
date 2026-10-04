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
  local isFood = okI and classID == 0 and subClassID == 5 -- forbruk / mat og drikke (V7: auraen heter «Well Fed»)
  return name, spell, isFood
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

-- For testene
function Scan.Reset() seen, expires, lastStatus, Scan.confirmed = {}, {}, {}, {} end
