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
local pending       -- vaktet sted vi kanskje har forlatt, men kartet sa fortsatt «inne» (sjekkes igjen)

CW.onDepart = nil -- (zone): Core viser varselet

local lastAlert -- { place, t, source }: siste varsel, så flykartet ikke varsler rett etter samtalen
local function now() local ok, t = pcall(GetTime) return (ok and type(t) == "number") and t or 0 end
local function depart(place, source)
  lastAlert = { place = place, t = now(), source = source }
  if CW.onDepart then CW.onDepart(place) end
end

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
    pending = nil
    return
  end
  if was and CW.Watched(was) and not alerted then
    if ns.Scan and ns.Scan.InsideZone(was) then
      -- Inn på et vertshus i byen (eget sted for spillet, men kartet sier byen) – eller kartet henger litt etter
      -- ved porten. Husk byen og sjekk igjen (CW.Check), så avreisen ikke går tapt.
      pending = was
    else
      alerted = true
      depart(was)
    end
  end
end

-- Kalles på klokka: har vi forlatt et vaktet sted som kartet først sa vi fortsatt var i? (Også: hearthstone eller
-- portal rett fra et vertshus i byen.)
function CW.Check()
  if not pending or alerted then return end
  if CW.Watched(last) then pending = nil return end
  if not (ns.Scan and ns.Scan.InsideZone(pending)) then
    local from = pending
    pending, alerted = nil, true
    depart(from)
  end
end

-- Lukket samtalen med flight masteren (eller flykartet) uten å fly, og står fortsatt på et vaktet sted:
-- da gjelder neste avreise igjen (Core kaller denne litt etter GOSSIP_CLOSED/TAXIMAP_CLOSED)
function CW.Rearm()
  if last and CW.Watched(last) then alerted = false end
end

-- Flykartet åpnet på et sted som voktes: si fra før du flyr (og ikke igjen når du forlater sonen)
-- source = "gossip" (samtalen med flight masteren) eller "map" (flykartet)
function CW.Taxi(source)
  if last and CW.Watched(last) and not alerted then
    alerted = true
    -- Samtalen med flight masteren varslet nettopp: flykartet som åpnes etterpå, skal ikke varsle en gang til
    -- (uansett hvor lang tid spillet bruker fra samtalen lukkes til kartet åpnes)
    if source == "map" and lastAlert and lastAlert.source == "gossip" and lastAlert.place == last
      and now() - lastAlert.t < 30 then return end
    depart(last, source)
  end
end

function CW.Current() return last end

-- For testene
function CW.Reset() last, alerted, pending = nil, false, nil end
