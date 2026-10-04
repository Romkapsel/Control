-- Control: registrering av et trykk (SPEC §12.4).
-- 1. Hvilken knapp du trykket: vår egen informasjon, aldri hemmelig (PreClick).
-- 2. At du faktisk kastet den: UNIT_SPELLCAST_SUCCEEDED for player. Spell-ID er lesbar også i kamp (fase 0, V4),
--    så vi sjekker at det var riktig spell. Er den hemmelig, godtar vi et kast som kommer like etter trykket.
-- 3. Bommer du (for langt unna, tom for mana), kommer ingen bekreftelse, og ingenting endres.
local addonName, ns = ...

local Track = {}
ns.Track = Track

local WINDOW = 1.0     -- et kast må starte (SENT) eller lykkes innen så lenge etter trykket
local CAST_MAX = 10.0  -- når SENT kom i tide, venter vi så lenge på SUCCEEDED (spells med kastetid)

local pending -- { entry, at, sent }

local function castName(e)
  if e.type == "buffitem" then return e.castName end
  return e.name
end

function Track.Pressed(e)
  if not e then return end
  pending = { entry = e, at = GetTime(), sent = false }
end

local function matches(spellID)
  if not pending then return false end
  if ns.Scan.isSecret(spellID) then return true end
  local name = ns.Scan.SpellInfo(spellID)
  return name ~= nil and name == castName(pending.entry)
end

local function alive(t)
  if not pending then return false end
  local limit = pending.sent and CAST_MAX or WINDOW
  if t - pending.at > limit then pending = nil return false end
  return true
end

-- Returnerer oppføringen som ble bekreftet, eller nil.
function Track.OnEvent(event, unit, a, b, c)
  if unit ~= "player" then return nil end
  local t = GetTime()
  if not alive(t) then return nil end
  if event == "UNIT_SPELLCAST_SENT" then
    if matches(c) then pending.sent = true end -- SENT: unit, target, castGUID, spellID
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if matches(b) then                          -- SUCCEEDED: unit, castGUID, spellID
      local e = pending.entry
      pending = nil
      return e
    end
  elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
    if matches(b) then pending = nil end
  end
  return nil
end

function Track.Pending() return pending end
