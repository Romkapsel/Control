-- Control: regelmotoren (SPEC §6). Ren Lua 5.1 uten WoW-API, så den kan testes utenfor spillet.
-- Inn: oppføringene (SPEC §5.2) og tilstanden per oppføring (SPEC §5.3). Ut: alt UI-et trenger:
-- alvorlighet, hva som kan trykkes, tallet, ringfargen, hva som står ute, sidemenyene og statuslinja.
--
-- Oppføring (entry): { id, type = "spell"|"buffitem"|"item"|"partyspell"|"partyitem", tier = 1|2, short, name, want,
--                      groupSpell (gruppeversjonen, bare partyspell) }
-- Tilstand (state):  MB: { status = "on"|"expiring"|"expired"|"missing", count = antall i baggen }
--                    PB: { missingOn = { { name = "Brakk", unit = "party1" }, ... } }  (bare de som følges og mangler;
--                        ute av rekkevidde = ukjent og står ikke her, SPEC Q8)

local addonName, ns = ...
ns = ns or {}

local Rules = {}
ns.Rules = Rules

Rules.EXPIRING_SECONDS = 40 -- SPEC §6.1, Q3
Rules.STATUS_MAX = 4        -- SPEC §6.6: maks fire i statuslinja, så «+N»
-- Rammene (ved knappen og sidemenyene) starter i medaljongens midtpunkt, så venstre ende alltid ligger skjult
-- bak sirkelen (Daniel 4. okt; SPEC hadde 18 px fra kanten, og hjørnene tittet fram). Første knapp står fortsatt
-- 6 px utenfor medaljongen: 2 px kant + 36 px luft. Bredde = 2 + 36 + plasser × 46 + 2.
Rules.FRAME_BASE = 40

local SEV_OK, SEV_WARN, SEV_BAD = 0, 1, 2
Rules.SEV_OK, Rules.SEV_WARN, Rules.SEV_BAD = SEV_OK, SEV_WARN, SEV_BAD

local function hasStock(e) return e.type == "item" or e.type == "buffitem" end
-- Gruppebuff: en spell du kaster på andre, eller en scroll du bruker på dem (Daniel 5. okt)
local function isParty(e) return e.type == "partyspell" or e.type == "partyitem" end
Rules.isParty = isParty

------------------------------------------------------------------------
-- Status fra auraen (SPEC §5.3)
------------------------------------------------------------------------

-- left: sekunder igjen (math.huge = uten tidsgrense), nil = ikke på.
-- seen: buffen har vært på tidligere i økten (skiller «gått ut» fra «ikke på»).
function Rules.auraStatus(left, seen)
  if left == nil then return seen and "expired" or "missing" end
  if left <= Rules.EXPIRING_SECONDS then return "expiring" end
  return "on"
end

------------------------------------------------------------------------
-- Alvorlighet (SPEC §6.2): 0 = ok, 1 = oransje, 2 = rød
-- Tieren sier hvor viktig noe er (Daniel 4. okt): det som mangler helt (buff ikke på, tomt), er rødt i tier I
-- («må ha») og oransje i tier II («fint å ha»). Under ønsket antall og snart ute er alltid oransje.
------------------------------------------------------------------------

local function missingSev(e) return e.tier == 1 and SEV_BAD or SEV_WARN end

function Rules.buffSeverity(e, st)
  if e.type == "item" or isParty(e) then return SEV_OK end
  local s = st and st.status
  if s == "missing" or s == "expired" then return missingSev(e) end
  if s == "expiring" then return SEV_WARN end
  return SEV_OK
end

function Rules.stockSeverity(e, st)
  if not hasStock(e) then return SEV_OK end
  local count = (st and st.count) or 0
  if count <= 0 then return missingSev(e) end
  if count < (e.want or 1) then return SEV_WARN end
  return SEV_OK
end

function Rules.partyMissing(st)
  return (st and st.missingOn) or {}
end

function Rules.severity(e, st)
  if isParty(e) then
    return #Rules.partyMissing(st) > 0 and missingSev(e) or SEV_OK
  end
  return math.max(Rules.buffSeverity(e, st), Rules.stockSeverity(e, st))
end

------------------------------------------------------------------------
-- Kan trykkes (SPEC §6.3)
------------------------------------------------------------------------

function Rules.canPress(e, st)
  if e.type == "spell" then return Rules.buffSeverity(e, st) > 0 end
  if e.type == "buffitem" then return Rules.buffSeverity(e, st) > 0 and ((st and st.count) or 0) > 0 end
  if e.type == "partyspell" then return #Rules.partyMissing(st) > 0 end
  if e.type == "partyitem" then return #Rules.partyMissing(st) > 0 and ((st and st.count) or 0) > 0 end
  return false
end

------------------------------------------------------------------------
-- Gruppebuff: hva kastes og på hvem (SPEC §9.3, §9.5)
------------------------------------------------------------------------

-- ctx = { inParty = true/false, groupUsable = spillet sier at gruppeversjonen kan kastes nå (kjent, reagens, mana),
--         selfCast = spellen har ingen rekkevidde (warrior shouts o.l.): kastes på deg selv og treffer gruppa }
-- Gruppeversjonen bare i party, når flere enn 2 mangler, og reagensen finnes. Ellers enkeltversjonen på neste som mangler.
function Rules.partyCast(e, st, ctx)
  local missing = Rules.partyMissing(st)
  if #missing == 0 then return nil end
  ctx = ctx or {}
  if ctx.selfCast then -- Daniel 5. okt: shouts kastes på deg selv; ett kast gjelder alle i nærheten
    return { spell = e.castName or e.spellName or e.name, group = true, self = true, target = missing[1] }
  end
  local useGroup = e.groupSpell ~= nil and ctx.inParty == true and #missing > 2
    and ctx.groupUsable == true
  return {
    spell = useGroup and e.groupSpell or (e.castName or e.spellName or e.name), -- scroll: spellen den kaster
    group = useGroup,
    target = missing[1],
  }
end

------------------------------------------------------------------------
-- Tekst: tider og lager (SPEC §7.5)
------------------------------------------------------------------------

-- Under 1 min: «0:SS». Under 100 min: «N min» (rundet opp). Fra 100 min: «N t» (rundet opp).
-- short = på knappen: «6m», «2t» (Daniel 5. okt: «6 min» på knappen så billig ut). Tooltipen bruker den lange.
function Rules.formatTime(secs, L, short)
  if secs == nil or secs == math.huge then return nil end
  if secs < 0 then secs = 0 end
  if secs < 60 then
    return string.format(L.TIME_SECONDS, 0, math.floor(secs))
  end
  local minutes = math.ceil(secs / 60)
  if minutes < 100 then return string.format(short and L.TIME_MINUTES_SHORT or L.TIME_MINUTES, minutes) end
  return string.format(short and L.TIME_HOURS_SHORT or L.TIME_HOURS, math.ceil(secs / 3600))
end

-- Nok: bare tallet («3»). For lite: «har/vil ha» («3/4», «0/10»).
function Rules.stockText(count, want)
  count, want = count or 0, want or 1
  if count >= want then return tostring(count) end
  return count .. "/" .. want
end

------------------------------------------------------------------------
-- Rekkefølge
------------------------------------------------------------------------

-- Stabil sortering på (-alvorlighet, indeks): table.sort er ikke stabil (SPEC §6.6).
local function worstFirst(list)
  local idx = {}
  for i = 1, #list do idx[i] = i end
  table.sort(idx, function(a, b)
    if list[a].sev ~= list[b].sev then return list[a].sev > list[b].sev end
    return a < b
  end)
  local out = {}
  for i, k in ipairs(idx) do out[i] = list[k] end
  return out
end

local function byTier(entries)
  local t1, t2 = {}, {}
  for _, e in ipairs(entries) do
    if e.tier == 1 then t1[#t1 + 1] = e else t2[#t2 + 1] = e end
  end
  return t1, t2
end

------------------------------------------------------------------------
-- Sidemenyen (SPEC §7.4) og ved knappen (SPEC §6.4, §6.7)
------------------------------------------------------------------------

-- Ting du bare skal ha med (lagerting: utstyr, bandasjer, potions …) står i sidemenyen bare når de mangler eller
-- er under ønsket antall (Daniel 5. okt: et helt utstyrssett i sidemenyen er bare støy når alt er med).
-- Buffer og buffting står alltid (de viser tid og kan klikkes). Menyen viser alt.
local function shownInSide(e, st)
  return e.type ~= "item" or Rules.stockSeverity(e, st[e.id]) > 0
end

local function sideBar(entries, st)
  local shown = {}
  for _, e in ipairs(entries) do if shownInSide(e, st or {}) then shown[#shown + 1] = e end end
  entries = shown
  local t1, t2 = byTier(entries)
  local n = #t1 + #t2
  -- Bare én tom rute («+»), etter det som er lagt til: sida vokser én og én (Daniel 5. okt)
  local slots = 1
  local groove = #t1 > 0 and #t2 > 0
  local ids1, ids2 = {}, {}
  for _, e in ipairs(t1) do ids1[#ids1 + 1] = e.id end
  for _, e in ipairs(t2) do ids2[#ids2 + 1] = e.id end
  return {
    tier1 = ids1, tier2 = ids2, groove = groove, slots = slots,
    width = Rules.FRAME_BASE + (n + slots) * 46 + (groove and 12 or 0),
  }
end

-- Tier I som kan trykkes, i brukerens rekkefølge, innerst først. Tier II og lagerting står aldri ute.
local function tray(entries, st)
  local ids = {}
  for _, e in ipairs(entries) do
    if e.tier == 1 and Rules.canPress(e, st[e.id]) then ids[#ids + 1] = e.id end
  end
  return ids
end

------------------------------------------------------------------------
-- Statuslinja (SPEC §6.6)
------------------------------------------------------------------------

local function selfStatus(entries, st, L)
  local problems = {}
  for i, e in ipairs(entries) do
    local s = Rules.severity(e, st[e.id])
    if s > 0 then problems[#problems + 1] = { e = e, sev = s, i = i } end
  end
  if #problems == 0 then
    return { label = L.LABEL_MY_BUFFS, ok = true, parts = {}, text = L.LABEL_MY_BUFFS,
             detail = L.LABEL_STATUS .. L.LABEL_GAP .. L.ALL_OK }
  end
  local sorted = worstFirst(problems)
  local parts, texts = {}, {}
  for k = 1, math.min(Rules.STATUS_MAX, #sorted) do
    local e, s = sorted[k].e, st[sorted[k].e.id]
    local ss = Rules.stockSeverity(e, s)
    local p = { id = e.id, name = e.short or e.name, nameSev = Rules.buffSeverity(e, s), stockSev = ss }
    if hasStock(e) and ss > 0 then p.stock = Rules.stockText(s and s.count, e.want) end
    parts[#parts + 1] = p
    texts[#texts + 1] = p.stock and (p.name .. " " .. p.stock) or p.name
  end
  local more = #sorted - Rules.STATUS_MAX
  if more > 0 then texts[#texts + 1] = "+" .. more end
  -- Linja under knappene er bare navnet på sida (Daniel 5. okt); detail er den lange forklaringen (tester, senere tooltip)
  return { label = L.LABEL_MY_BUFFS, ok = false, parts = parts, more = more > 0 and more or 0, text = L.LABEL_MY_BUFFS,
           detail = L.LABEL_MISSING .. L.LABEL_GAP .. table.concat(texts, L.SEP) }
end

local function partyStatus(entries, st, L)
  local parts, texts = {}, {}
  for _, e in ipairs(entries) do
    local missing = Rules.partyMissing(st[e.id])
    if #missing > 0 then
      local names = {}
      for i, m in ipairs(missing) do names[i] = m.name end
      local p = { id = e.id, name = e.short or e.name, members = table.concat(names, ", ") }
      parts[#parts + 1] = p
      texts[#texts + 1] = p.name .. ": " .. p.members
    end
  end
  -- Bare navnet på sida (Daniel 5. okt): hvem som mangler, sier knappene (glød og ruter), ikke teksten
  return { label = L.LABEL_PARTY_BUFFS, ok = #parts == 0, parts = parts, text = L.LABEL_PARTY_BUFFS }
end

------------------------------------------------------------------------
-- Alt UI-et trenger (som renderVals() i prototypen)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Byvakt (SPEC §10, §11 nivå 3): hva du drar ut uten. Bare det du må hente i byen – lageret av ting og
-- buffting, begge tier (Daniel 5. okt: spells kan kastes hvor som helst, og om flasken er på nå, er ikke poenget).
-- sev 2 = tomt i tier I (rød + lyd), 1 = tomt i tier II eller under ønsket (oransje), 0 = alt med.
------------------------------------------------------------------------

function Rules.departure(entries, st, L)
  local problems = {}
  local sev = SEV_OK
  for i, e in ipairs(entries or {}) do
    local s = Rules.stockSeverity(e, st[e.id])
    if s > 0 then
      problems[#problems + 1] = { e = e, sev = s, i = i }
      sev = math.max(sev, s)
    end
  end
  if sev == SEV_OK then return { sev = SEV_OK, parts = {}, more = 0, text = L.ALL_OK } end
  local sorted = worstFirst(problems)
  local parts, texts = {}, {}
  for k = 1, math.min(Rules.STATUS_MAX, #sorted) do
    local e, s = sorted[k].e, st[sorted[k].e.id]
    local p = { id = e.id, name = e.short or e.name, nameSev = sorted[k].sev, stockSev = sorted[k].sev,
                stock = Rules.stockText(s and s.count, e.want) }
    parts[#parts + 1] = p
    texts[#texts + 1] = p.name .. " " .. p.stock
  end
  local more = #sorted - Rules.STATUS_MAX
  if more > 0 then texts[#texts + 1] = "+" .. more end
  return { sev = sev, parts = parts, more = math.max(0, more), text = table.concat(texts, L.SEP) }
end

-- model = { self = { entries }, party = { entries }, st = { [id] = state } }
-- opts  = { inCombat = true/false, prevTray = forrige view.tray }: i kamp står det som stod ute (SPEC §6.8)
function Rules.render(model, L, opts)
  opts = opts or {}
  local selfList, partyList, st = model.self or {}, model.party or {}, model.st or {}

  local count, ring = 0, SEV_OK
  for _, e in ipairs(selfList) do
    local s = Rules.severity(e, st[e.id])
    if s > 0 then count = count + 1 end
    if s > ring then ring = s end
  end
  for _, e in ipairs(partyList) do
    local s = Rules.severity(e, st[e.id])
    if s > 0 then count = count + 1 end
    if s > ring then ring = s end
  end

  local newTray = { self = tray(selfList, st), party = tray(partyList, st) }
  local frozen = opts.inCombat and opts.prevTray ~= nil

  return {
    count = count,
    ring = ring,
    allOk = count == 0,
    empty = #selfList == 0 and #partyList == 0,
    tray = frozen and opts.prevTray or newTray,
    trayFrozen = frozen,
    side = { self = sideBar(selfList, st), party = sideBar(partyList, st) },
    status = { self = selfStatus(selfList, st, L), party = partyStatus(partyList, st, L) },
  }
end

return Rules
