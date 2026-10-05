-- Control: byvakt (SPEC §10). Sier fra når du forlater et sted som voktes – ut porten, med båt/portal
-- (sonebytte), eller når du åpner flykartet der. Aldri to ganger for samme avreise: neste varsel kommer
-- først etter at du har vært tilbake på et sted som voktes.
-- Fase 0 (V8): GetRealZoneText kan være tom rett ved PLAYER_ENTERING_WORLD; tomt navn ignoreres.
local addonName, ns = ...

local CW = {}
ns.CityWatch = CW

local db
local last          -- siste sone vi kjenner
local alerted = false -- har vi sagt fra for denne avreisen?

CW.onDepart = nil -- (zone): Core viser varselet

function CW.Init(database) db = database end

function CW.Watched(z)
  if not z or not db then return false end
  for _, c in ipairs(db.cityWatch.cities) do if c == z then return true end end
  return false
end

-- Ny sone. Fra et sted som voktes til et som ikke gjør det = avreise.
function CW.Zone(z)
  if type(z) ~= "string" or z == "" or z == last then return end
  local was = last
  last = z
  if CW.Watched(z) then
    if not CW.Watched(was) then alerted = false end -- framme på et vaktet sted: neste avreise varsles igjen
    return
  end
  -- Inn på et vertshus i byen: spillet kaller det et eget sted, men kartet sier at du fortsatt er i byen
  if was and CW.Watched(was) and not alerted and not (ns.Scan and ns.Scan.InsideZone(was)) then
    alerted = true
    if CW.onDepart then CW.onDepart(was) end
  end
end

-- Flykartet åpnet på et sted som voktes: si fra før du flyr (og ikke igjen når du forlater sonen)
function CW.Taxi()
  if last and CW.Watched(last) and not alerted then
    alerted = true
    if CW.onDepart then CW.onDepart(last) end
  end
end

function CW.Current() return last end

-- For testene
function CW.Reset() last, alerted = nil, false end
