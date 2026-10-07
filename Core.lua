-- Control: navnerom, oppstart, hendelser, kø for etter kamp og kommandoer (SPEC §17).
local addonName, ns = ...

local Core = {}
ns.Core = Core

local function Say(msg) print("|cffffd100[Control]|r " .. msg) end
ns.Say = Say

------------------------------------------------------------------------
-- Kø: det som rører sikre knapper, venter til kampen er over (SPEC §12.1)
------------------------------------------------------------------------

local afterCombat = {}
function ns.RunAfterCombat(fn)
  if InCombatLockdown() then
    afterCombat[#afterCombat + 1] = fn
  else
    fn()
  end
end

------------------------------------------------------------------------
-- Tegning: tilstand → regler → UI (SPEC §17: én tegnerunde)
------------------------------------------------------------------------

Core.sample = nil -- nil = ekte data; ellers indeks i Data.SAMPLES (/ctrl test)
local prevTray, auraCache, partyAuraCache
local members = {}

function Core.Model()
  if Core.sample then return ns.Data.Sample(ns.Data.SAMPLES[Core.sample]) end
  local st = ns.Scan.State(ns.db, auraCache)
  members = ns.Scan.Party()
  local pst = ns.Scan.PartyState(ns.db.party, members, partyAuraCache, ns.db.durations)
  for _, e in ipairs(ns.db.party) do
    local s = pst[e.id]
    -- Hva knappen kaster og på hvem (SPEC §9.3, §9.5); gruppeversjonen bare når spillet sier den kan kastes nå
    s.cast = ns.Rules.partyCast(e, s, { inParty = #members > 0, groupUsable = e.groupSpell and ns.Scan.SpellUsable(e.groupSpell),
                                        selfCast = e.type == "partyspell" and ns.Scan.SelfCast(e) })
    if e.itemId then s.count = ns.Scan.ItemCount(e.itemId) or 0 end
    st[e.id] = s
  end
  return { self = ns.db.self, party = ns.db.party, st = st }
end

local function byId(list)
  local t = {}
  for _, e in ipairs(list) do t[e.id] = e end
  return t
end

local function trayEntries(ids, map)
  local out = {}
  for _, id in ipairs(ids) do if map[id] then out[#out + 1] = map[id] end end
  return out
end

local function mbSide() return ns.db.ui.partySide == "right" and "left" or "right" end
local function pbSide() return mbSide() == "right" and "left" or "right" end

local function iconOf(e)
  if e.spellId then return select(2, ns.Scan.SpellInfo(e.spellId)) end
  if e.itemId then return ns.Scan.ItemIcon(e.itemId) end
end

-- Det store varselet: den «Må ha»-buffen (egen, med tid) som har minst tid igjen under 10 s. Etter at det slås på
-- under Oppsett, vises det i 3 s med den første «Må ha»-buffen, så du ser hvordan det ser ut.
-- Per oppføring: var den på sist, og har den fått nedtellingen i denne runden?
local bigSeen = {}
local GONE_HOLD = 3

local function firstMustHave()
  for _, e in ipairs(ns.db.self) do
    if e.tier == 1 and (e.type == "spell" or e.type == "buffitem") then return e end
  end
  return { id = "preview", name = ns.L.BIG_PREVIEW }
end

-- Eget bilde for en buff som går ut (tillegget ControlExtra, privat – ikke på GitHub). Leses, skrives aldri.
local function goneImage(e)
  local x = ControlExtras
  local img = type(x) == "table" and type(x.goneImages) == "table" and x.goneImages[e.name]
  return type(img) == "string" and img or nil
end

-- Test (Daniel 7. okt): /ctrl stort = nedtelling fra 10, /ctrl stort borte = buffen forsvant,
-- /ctrl stortest = Battle Shout går ut (med bildet fra ControlExtra, om det er installert)
function Core.BigTest(gone, name)
  local e = firstMustHave()
  if name then e = { id = "test", name = name, spellId = 6673 } end
  Core.bigTest = { at = GetTime() or 0, gone = gone, entry = e }
  Core.Draw()
end

local function bigAlert(model)
  if not ns.Alert.Big then return end
  local now = GetTime() or 0
  local test = Core.bigTest
  if test or (Core.bigPreview and now < Core.bigPreview) then ns.Alert.BigClick(nil) end
  if test then
    local dt = now - test.at
    if test.gone and dt < GONE_HOLD then
      return ns.Alert.Big(test.entry, 0, iconOf(test.entry), true, goneImage(test.entry))
    end
    if not test.gone and dt < ns.Alert.BIG_AT then return ns.Alert.Big(test.entry, ns.Alert.BIG_AT - dt, iconOf(test.entry)) end
    Core.bigTest = nil
  end
  if Core.bigPreview and now < Core.bigPreview then
    local e = Core.bigPreviewEntry or { id = "preview", name = ns.L.BIG_PREVIEW }
    return ns.Alert.Big(e, ns.Alert.BIG_AT - (now - (Core.bigPreview - 3)), iconOf(e))
  end
  if ns.db.ui.bigAlert ~= true then
    ns.Alert.BigClick(nil)
    return ns.Alert.Big(nil)
  end
  local pick, pickLeft
  for _, e in ipairs(model.self or {}) do
    local s = model.st[e.id]
    if e.tier == 1 and (e.type == "spell" or e.type == "buffitem") and s then
      local b = bigSeen[e.id] or {}
      bigSeen[e.id] = b
      local on = s.status == "on" or s.status == "expiring"
      local timed = s.left and s.left ~= math.huge
      if on and timed and s.left > ns.Alert.BIG_AT + 1 then b.counted = false end -- ny runde
      if on and timed and s.left > 0 and s.left <= ns.Alert.BIG_AT then
        b.counted = true
        if not pickLeft or s.left < pickLeft then pick, pickLeft = e, s.left end
      end
      -- Borte før tiden (slått bort, ladningene brukt opp): skrik – men ikke etter en nedtelling (Daniel 7. okt).
      -- Har buffen et eget bilde (ControlExtra), vises det også når den går ut etter nedtellingen.
      if b.wasOn and not on and (not b.counted or goneImage(e)) then b.goneAt = now end
      if on then b.goneAt = nil end
      b.wasOn = on
    end
  end
  -- «Borte!» går foran nedtellingen, i 3 sekunder. Trykk på ikonet = kast/bruk den (utenfor kamp).
  for _, e in ipairs(model.self or {}) do
    local b = bigSeen[e.id]
    if b and b.goneAt and now - b.goneAt < GONE_HOLD then
      ns.Alert.BigClick(e, model.st)
      return ns.Alert.Big(e, 0, iconOf(e), true, goneImage(e))
    end
  end
  ns.Alert.BigClick(pick, model.st)
  ns.Alert.Big(pick, pickLeft, pick and iconOf(pick))
end

function Core.Draw()
  if not ns.Medallion.frame then return end
  local model = Core.Model()
  local inCombat = InCombatLockdown()
  local view = ns.Rules.render(model, ns.L, { inCombat = inCombat, prevTray = prevTray })
  ns.view, ns.model = view, model
  ns.Medallion.Update(view)
  if not Core.sample then bigAlert(model) end
  if Core.sample then
    ns.Tray.Layout(mbSide(), {}, {}, ns.L) -- testdata har ingen ekte spells å kaste
    prevTray = nil
    return
  end
  local map = byId(model.self)
  local pmap = byId(model.party)
  local mb, pb = mbSide(), pbSide()
  if inCombat then
    ns.Tray.Paint(mb, map, model.st, ns.L) -- frosset: bare tider, lager og glød
    ns.Tray.Paint(pb, pmap, model.st, ns.L)
    ns.SideBar.Paint(mb, model.self, model.st, view, false, ns.L)
    ns.SideBar.Paint(pb, model.party, model.st, view, true, ns.L)
    ns.Menu.Paint(model)
  else
    -- Sidemenyen dekker knappene ved medaljongen på sin side mens den er åpen (SPEC §7.4)
    -- (Knappene legges ut også når sidemenyen dekker dem, så de er klare hvis den lukkes i kamp.)
    ns.Tray.Layout(mb, trayEntries(view.tray.self, map), model.st, ns.L, ns.SideBar.IsOpen(mb))
    ns.Tray.Layout(pb, trayEntries(view.tray.party, pmap), model.st, ns.L, ns.SideBar.IsOpen(pb))
    ns.SideBar.Layout(mb, model.self, model.st, view, false, ns.L)
    ns.SideBar.Layout(pb, model.party, model.st, view, true, ns.L)
    ns.Tray.UpdateNext(mb, pb) -- tasten «neste buff»: den første knappen ved medaljongen
    ns.Medallion.SetFlipped(ns.Menu.OpensUp()) -- menyen åpner oppover: menysymbolet øverst, låsen nederst
    ns.Menu.Layout(model, members, ns.SideBar.IsOpen(mb) or ns.SideBar.IsOpen(pb))
    prevTray = view.tray
  end
end

-- Throttlet: mange hendelser på rad gir én tegning (SPEC §12.3)
local scheduled = false
function ns.Refresh(readAuras)
  if readAuras then Core.readAuras = true end
  if scheduled then return end
  scheduled = true
  C_Timer.After(0.1, function()
    scheduled = false
    if Core.readAuras then
      auraCache = ns.Scan.ReadAuras()
      partyAuraCache = ns.Scan.ReadPartyAuras(ns.Scan.Party())
      Core.readAuras = false
    end
    Core.Draw()
  end)
end

------------------------------------------------------------------------
-- Legge til: slipp en spell eller en ting på medaljongen (tier I), en sidemeny (tier II) eller en rad i menyen
------------------------------------------------------------------------

local function wellFedName() return (ns.Scan.SpellInfo(19705)) or "Well Fed" end

-- Info om en spell eller et item, som Data.MakeEntry tar. nil hvis spillet ikke kjenner den (ennå).
function Core.Resolve(kind, id)
  if kind == "spell" then
    local name = ns.Scan.SpellInfo(id)
    if not name then return nil end
    -- Våpenbuff som spell (Daniel 7. okt: Flametongue Weapon sto som manglende selv om den var på): den ligger på
    -- våpenet, ikke som en buff på deg. Kjennes på navnet («… Weapon») eller beskrivelsen («Imbue … weapon»).
    local desc = (ns.Scan.SpellDescription(id) or ""):lower()
    local isWeapon = name:find(" Weapon$") ~= nil or (desc:find("imbue", 1, true) ~= nil and desc:find("weapon", 1, true) ~= nil)
    return { kind = "spell", spellId = id, name = name, isWeapon = isWeapon, weaponSlot = isWeapon and 16 or nil }
  end
  local name, spell, classID, subClassID = ns.Scan.ItemInfo(id)
  if not name then return nil end
  -- Buffting bare for eliksir, flask, scroll og mat som gir «Well Fed». Potions, bandasjer og healthstones har
  -- også en bruk-effekt, men gir ingen buff å vente på: de er lagerting (Daniel 4. okt, en potion som ble rød).
  local isFood = classID == 0 and subClassID == 5 and ns.Scan.TooltipHas(id, wellFedName())
  -- Gift, olje, slipestein (Daniel 5. okt): har en bruk-effekt og nevner våpenet i tooltipen, og er ikke selv utstyr
  local isWeapon = spell ~= nil and classID ~= 2 and classID ~= 4 and ns.Scan.TooltipHas(id, "weapon")
  local givesBuff = spell and (isWeapon or (classID == 0 and (ns.Data.BUFF_SUBCLASS[subClassID] or isFood)))
  return { kind = "item", itemId = id, itemName = name, itemSpell = givesBuff and spell or nil, isFood = isFood,
           isWeapon = isWeapon, classID = classID, subClassID = subClassID,
           isScroll = givesBuff and subClassID == 4 or false,
           wellFed = wellFedName(), count = ns.Scan.ItemCount(id) }
end

------------------------------------------------------------------------
-- Handlinger fra knappene og sidemenyene (SPEC §8)
------------------------------------------------------------------------

local Actions = {}
ns.Actions = Actions
local undo

local function listOf(isParty) return isParty and ns.db.party or ns.db.self end
local function indexOf(list, e) for i, x in ipairs(list) do if x == e or x.id == e.id then return i end end end
local function isPartyEntry(e) return ns.Rules.isParty(e) end

function Actions.ToggleTier(e)
  if InCombatLockdown() then return end
  e.tier = e.tier == 1 and 2 or 1
  ns.Refresh(false)
end

function Actions.Wheel(e, delta, step)
  if InCombatLockdown() or not (e.type == "buffitem" or e.type == "item") then return end
  if e.cat == "gear" then return end -- utstyr: du har det eller ikke; antallet er alltid 1 (Daniel 5. okt)
  e.want = math.max(1, math.min(999, (e.want or 1) + (delta > 0 and step or -step)))
  ns.Refresh(false)
end

function Actions.Remove(e)
  if InCombatLockdown() then return end
  local list = listOf(isPartyEntry(e))
  local i = indexOf(list, e)
  if not i then return end
  table.remove(list, i)
  undo = { entry = e, index = i, party = isPartyEntry(e) }
  Say(string.format(ns.L.REMOVED, e.name or "?"))
  ns.Refresh(true)
end

function Actions.Undo()
  if not undo then return Say(ns.L.UNDO_NONE) end
  if undo.city then
    local cities = ns.db.cityWatch.cities
    table.insert(cities, math.min(undo.index, #cities + 1), undo.city)
    Say(string.format(ns.L.CITY_ADDED, undo.city))
    undo = nil
    return Core.Draw()
  end
  local list = listOf(undo.party)
  table.insert(list, math.min(undo.index, #list + 1), undo.entry)
  Say(string.format(ns.L.UNDONE, undo.entry.name or "?"))
  undo = nil
  ns.Refresh(true)
end

-- Flytt e til plassen der target står, og ta tieren dens (dra til den andre raden = bytt tier)
function Actions.Move(e, targetId)
  if InCombatLockdown() then return end
  local list = listOf(isPartyEntry(e))
  local from = indexOf(list, e)
  local to
  for i, x in ipairs(list) do if x.id == targetId then to = i end end
  if not from or not to or from == to then return end
  e.tier = list[to].tier
  table.remove(list, from)
  table.insert(list, to, e)
  ns.Refresh(false)
end

-- Gift/olje på våpnet: første gang hovedhånda; samme ting en gang til, med et våpen i annen hånd: annen hånd.
-- Gir tilbake den eksisterende oppføringen når begge er tatt (eller annen hånd ikke har noe våpen).
local function weaponSlot(list, info)
  local has = {}
  for _, e in ipairs(list) do if e.itemId == info.itemId and e.weaponSlot then has[e.weaponSlot] = e end end
  if not has[16] then return 16 end
  if not has[17] and ns.Scan.OffHandWeapon() then return 17 end
  return nil, has[17] or has[16]
end

local function findDuplicate(list, info)
  if info.isWeapon and info.kind == "item" then
    local slot, dup = weaponSlot(list, info)
    info.weaponSlot = slot
    return dup
  end
  return ns.Data.FindDuplicate(list, info)
end

function ns.AddFromCursor()
  if InCombatLockdown() then return end -- som å slippe på sidemenyene: ikke i kamp
  local kind, a, _, d = GetCursorInfo()
  local info
  if kind == "spell" then
    info = Core.Resolve("spell", d or a)
  elseif kind == "item" then
    info = Core.Resolve("item", a)
  else
    if kind then ClearCursor() Say(ns.L.NOT_ADDABLE) end
    return
  end
  ClearCursor()
  if not info then return Say(ns.L.NOT_KNOWN) end
  local dup = findDuplicate(ns.db.self, info)
  if dup then return Say(string.format(ns.L.DUPLICATE, dup.name)) end
  local e = ns.Data.MakeEntry(ns.db, info, 1)
  table.insert(ns.db.self, e)
  Say(string.format(ns.L.ADDED, e.name))
  ns.Refresh(true)
end

-- «+» i yrkesvinduet: legg tingen til i settet du står i (Fint å ha), som å slippe den i menyen
function Actions.AddItem(id)
  if InCombatLockdown() or not id then return end
  local info = Core.Resolve("item", id)
  if not info then return Say(ns.L.NOT_KNOWN) end
  local dup = findDuplicate(ns.db.self, info)
  if dup then return Say(string.format(ns.L.DUPLICATE, dup.name)) end
  local e = ns.Data.MakeEntry(ns.db, info, 2)
  e.tier = 2
  table.insert(ns.db.self, e)
  Say(string.format(ns.L.ADDED_SIDE, e.name))
  ns.Refresh(true)
end

-- Slipp på en sidemeny: sist i tier II på den siden. En spell på gruppesiden = gruppebuff (SPEC §8).
function Actions.DropOnSide(sideKey)
  return Actions.DropOn(sideKey == pbSide(), 2)
end

-- Slipp i menyen: i raden du slapp på (tier I eller II)
function Actions.DropOn(party, tier)
  if InCombatLockdown() then return end
  local kind, a, _, d = GetCursorInfo()
  local info
  if kind == "spell" then
    info = Core.Resolve("spell", d or a)
  elseif kind == "item" then
    info = Core.Resolve("item", a)
    -- Gruppesiden tar bare scrolls: eliksirer, flasks og mat kan ikke brukes på andre
    if party and info and not info.isScroll then ClearCursor() return Say(ns.L.PARTY_SCROLLS_ONLY) end
  else
    if kind then ClearCursor() Say(party and ns.L.EMPTY_PARTY or ns.L.NOT_ADDABLE) end
    return
  end
  ClearCursor()
  if not info then return Say(ns.L.NOT_KNOWN) end
  local list = party and ns.db.party or ns.db.self
  local dup = party and ns.Data.FindDuplicate(list, info) or findDuplicate(list, info)
  if dup then return Say(string.format(ns.L.DUPLICATE, dup.name)) end
  local e = party and ns.Data.MakePartyEntry(ns.db, info) or ns.Data.MakeEntry(ns.db, info, tier or 2)
  e.tier = tier or 2
  table.insert(list, e)
  Say(string.format(e.tier == 1 and ns.L.ADDED or ns.L.ADDED_SIDE, e.name))
  ns.Refresh(true)
end

function Actions.SetTier(e, tier)
  if InCombatLockdown() or e.tier == tier then return end
  e.tier = tier
  ns.Refresh(false)
end

-- Hvem en gruppebuff følges på (Q7). names = de som er i party nå. Alle valgt igjen = onlyOn nil (følg alle).
function Actions.ToggleFollow(e, name, names)
  if InCombatLockdown() then return end
  local set = {}
  if e.onlyOn then
    for n, v in pairs(e.onlyOn) do set[n] = v end
  else
    for _, n in ipairs(names) do set[n] = true end
  end
  set[name] = (not set[name]) or nil
  local all = true
  for _, n in ipairs(names) do if not set[n] then all = false end end
  for n in pairs(set) do
    local present = false
    for _, m in ipairs(names) do if m == n then present = true end end
    if not present then all = false end
  end
  e.onlyOn = (not all) and set or nil
  if e.onlyOn then
    local list = {}
    for n in pairs(e.onlyOn) do list[#list + 1] = n end
    table.sort(list)
    Say(string.format(ns.L.FOLLOW_SET, e.short or e.name, #list > 0 and table.concat(list, ", ") or "–"))
  else
    Say(string.format(ns.L.FOLLOW_ALL, e.short or e.name))
  end
  ns.Refresh(true)
end

function Actions.AddCity(zone)
  if InCombatLockdown() or not zone then return end
  for _, c in ipairs(ns.db.cityWatch.cities) do if c == zone then return end end
  table.insert(ns.db.cityWatch.cities, zone)
  Say(string.format(ns.L.CITY_ADDED, zone))
  Core.Draw()
end

function Actions.RemoveCity(zone)
  if InCombatLockdown() then return end
  local cities = ns.db.cityWatch.cities
  for i, c in ipairs(cities) do
    if c == zone then
      table.remove(cities, i)
      undo = { city = zone, index = i }
      Say(string.format(ns.L.CITY_REMOVED, zone))
      break
    end
  end
  Core.Draw()
end

-- Bytt sider: gruppa og mine buffer bytter plass. Sidemenyene lukkes, alt legges ut på nytt.
function Actions.ToggleBigAlert()
  ns.db.ui.bigAlert = not ns.db.ui.bigAlert
  if ns.db.ui.bigAlert then
    -- Vis hvordan det ser ut, med den første «Må ha»-buffen
    Core.bigPreview = (GetTime() or 0) + 3
    Core.bigPreviewEntry = nil
    for _, e in ipairs(ns.db.self) do
      if e.tier == 1 and (e.type == "spell" or e.type == "buffitem") then Core.bigPreviewEntry = e break end
    end
  else
    Core.bigPreview = nil
  end
  Core.Draw()
end

function Actions.ToggleFade()
  ns.db.ui.fadeOk = ns.db.ui.fadeOk == false
  Core.Draw()
end

function Actions.SetFadeLevel(level)
  ns.db.ui.fadeLevel = level
  Core.Draw()
end

function Actions.ToggleCount()
  ns.db.ui.showCount = ns.db.ui.showCount == false
  Core.Draw()
end

-- Reparasjon/bagplass i byvakta av/på (standardene settes av Data.Init, så verdien er alltid true eller false)
function Actions.ToggleCityCheck(key)
  ns.db.cityWatch[key] = not ns.db.cityWatch[key]
  Core.Draw()
end

-- Utstyret i settet (kategorien Utstyr): hva som er på, hva som skal på (og på hvilken plass), hva som ikke finnes.
-- Ringer, trinkets og enhånds våpen har to plasser: en ting fra settet som alt sitter på én av dem, får stå, og den
-- neste går på den andre (ellers ville den andre ringen i settet tatt av den første).
local PAIRS = { INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_WEAPON = { 16, 17 } }
function Core.GearPlan(list)
  local worn = ns.Scan.Equipped()
  local taken, rest, todo, missing, total = {}, {}, {}, {}, 0
  for _, e in ipairs(list or {}) do
    if e.cat == "gear" and e.itemId then
      total = total + 1
      local found
      for slot = 1, 19 do
        if worn[slot] == e.itemId and not taken[slot] then found = slot break end
      end
      if found then taken[found] = true else rest[#rest + 1] = e end
    end
  end
  for _, e in ipairs(rest) do
    if ns.Scan.ItemCount(e.itemId) == 0 then
      missing[#missing + 1] = e
    else
      local pair, dst = PAIRS[ns.Scan.EquipLoc(e.itemId) or ""], nil
      if pair then
        for _, s in ipairs(pair) do if not taken[s] then dst = s break end end
        if dst then taken[dst] = true end
      end
      todo[#todo + 1] = { e = e, slot = dst }
    end
  end
  return { todo = todo, missing = missing, total = total, off = #todo + #missing }
end

local function names(list, get)
  local out = {}
  for _, x in ipairs(list) do out[#out + 1] = get(x).name or "?" end
  return table.concat(out, ", ")
end

-- «Ta på» (Daniel 5. okt): utstyret i settet du står i. Spillet bytter én og én ting; menyen tegnes på nytt etterpå.
function Actions.EquipSet()
  if InCombatLockdown() then return Say(ns.L.NOT_IN_COMBAT) end
  local plan = Core.GearPlan(ns.db.self)
  for _, t in ipairs(plan.todo) do ns.Scan.Equip(t.e.itemId, t.slot) end
  if #plan.todo > 0 then
    Say(string.format(ns.L.EQUIP_DONE, names(plan.todo, function(t) return t.e end)))
  elseif #plan.missing == 0 then
    Say(string.format(ns.L.EQUIP_ALL_ON, ns.db.activeSet or ""))
  end
  if #plan.missing > 0 then
    Say(string.format(ns.L.EQUIP_MISSING, names(plan.missing, function(e) return e end)))
  end
end

-- Beskjed når du bytter sett (Daniel 5. okt): det samme som byvakta sier, pluss utstyr som ikke er på. Uten lyd.
function Core.SetStatus(name)
  local model = Core.Model()
  local plan = Core.GearPlan(ns.db.self)
  local extra = { repair = ns.Scan.Durability(), gearOff = #plan.todo, gearTotal = plan.total }
  ns.Alert.Show(string.format(ns.L.SET_STATUS, name), ns.Rules.departure(model.self, model.st, ns.L, extra), true)
end

-- Sett: bytte, nytt, nytt navn, slette (ikke i kamp – knappene ville byttet midt i kampen)
function Actions.UseSet(name)
  if InCombatLockdown() or name == ns.db.activeSet then return end
  if ns.Data.UseSet(ns.db, name) then
    undo = nil -- «angre» gjelder settet du sto i
    Say(string.format(ns.L.SET_USED, name))
    ns.Refresh(true)
    Core.SetStatus(name)
  end
end

function Actions.NewSet(name)
  if InCombatLockdown() then return end
  name = name and name:match("^%s*(.-)%s*$")
  if not ns.Data.NewSet(ns.db, name) then return Say(ns.L.SET_BAD_NAME) end
  ns.Data.UseSet(ns.db, name)
  undo = nil
  Say(string.format(ns.L.SET_CREATED, name))
  ns.Refresh(true)
end

function Actions.RenameSet(old, new)
  if InCombatLockdown() then return end
  new = new and new:match("^%s*(.-)%s*$")
  if not ns.Data.RenameSet(ns.db, old, new) then return Say(ns.L.SET_BAD_NAME) end
  Core.Draw()
end

function Actions.DeleteSet(name)
  if InCombatLockdown() then return end
  if ns.Data.DeleteSet(ns.db, name) then
    undo = nil
    Say(string.format(ns.L.SET_DELETED, name))
    ns.Refresh(true)
  end
end

-- Dialoger: navn på nytt sett, og nytt navn / slette (spillets egne vinduer med tekstfelt)
local function popupText(self)
  local eb = self.editBox or self.EditBox
  return eb and eb:GetText() or nil
end
-- Bare egne nøkler i spillets tabell. Aldri `StaticPopupDialogs = …`: å skrive selve det globale navnet (også med
-- samme tabell) smitter det, og da kjører spillets egen kode «tainted by Control» – karaktervinduet krasjet på
-- hemmelige helsetall (Daniel 5. okt).
StaticPopupDialogs.CONTROL_SET_NEW = {
  text = "", button1 = "", button2 = "", hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
  OnShow = function(self) local eb = self.editBox or self.EditBox if eb then eb:SetText("") end end,
  OnAccept = function(self) Actions.NewSet(popupText(self)) end,
  EditBoxOnEnterPressed = function(eb) local p = eb:GetParent() Actions.NewSet(eb:GetText()) p:Hide() end,
}
StaticPopupDialogs.CONTROL_SET_EDIT = {
  text = "", button1 = "", button2 = "", button3 = "", hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
  OnShow = function(self, data) local eb = self.editBox or self.EditBox if eb then eb:SetText(data or "") end end,
  OnAccept = function(self, data) Actions.RenameSet(data, popupText(self)) end,
  OnAlt = function(self, data) Actions.DeleteSet(data) end,
  EditBoxOnEnterPressed = function(eb, data) local p = eb:GetParent() Actions.RenameSet(p.data, eb:GetText()) p:Hide() end,
}

function Actions.AskNewSet()
  if InCombatLockdown() then return end
  local d = StaticPopupDialogs.CONTROL_SET_NEW
  d.text, d.button1, d.button2 = ns.L.SET_NEW_TITLE, ns.L.SET_CREATE, ns.L.CANCEL
  StaticPopup_Show("CONTROL_SET_NEW")
end

function Actions.AskEditSet(name)
  if InCombatLockdown() then return end
  local d = StaticPopupDialogs.CONTROL_SET_EDIT
  d.text, d.button1, d.button2 = string.format(ns.L.SET_EDIT_TITLE, name), ns.L.SET_RENAME, ns.L.CANCEL
  d.button3 = #ns.db.setOrder > 1 and ns.L.SET_DELETE or nil -- det siste settet kan ikke slettes
  StaticPopup_Show("CONTROL_SET_EDIT", name, nil, name)
end

function Actions.ToggleOpenCore()
  ns.db.ui.openCore = not ns.db.ui.openCore
  ns.Medallion.ApplyCore()
  Core.Draw()
end

function Actions.SwapSides()
  if InCombatLockdown() then return end
  ns.db.ui.partySide = ns.db.ui.partySide == "right" and "left" or "right"
  ns.SideBar.SetOpen("left", false)
  ns.SideBar.SetOpen("right", false)
  prevTray = nil
  Core.Draw()
end

function Actions.SetScale(s)
  if InCombatLockdown() then return end
  local D = ns.Data
  s = math.max(D.SCALE_MIN, math.min(D.SCALE_MAX, math.floor(s / D.SCALE_STEP + 0.5) * D.SCALE_STEP))
  s = math.floor(s * 100 + 0.5) / 100 -- 1.45, ikke 1.4500000000000002
  ns.Medallion.SetScale(s)
  Core.Draw()
end

------------------------------------------------------------------------
-- Byvakt (SPEC §10): varsel når du forlater et sted som voktes. I kamp: vises når kampen er over (§11).
------------------------------------------------------------------------

function Core.Depart(zone)
  local function show()
    local model = Core.Model()
    local cw = ns.db.cityWatch
    local extra = {
      repair = cw.checkRepair ~= false and ns.Scan.Durability() or nil,
      bags = cw.checkBags == true and ns.Scan.FreeBagSlots() or nil,
    }
    ns.Alert.Show(string.format(ns.L.CITY_LEAVING, zone or "?"), ns.Rules.departure(model.self, model.st, ns.L, extra))
  end
  if InCombatLockdown() then ns.RunAfterCombat(show) else show() end
end

------------------------------------------------------------------------
-- Hendelser
------------------------------------------------------------------------

local CAST = { UNIT_SPELLCAST_SENT = true, UNIT_SPELLCAST_SUCCEEDED = true, UNIT_SPELLCAST_FAILED = true,
               UNIT_SPELLCAST_INTERRUPTED = true }

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, arg1, ...)
  if event == "ADDON_LOADED" then
    if arg1 ~= addonName then return end
    ControlCharDB = ns.Data.Init(ControlCharDB)
    ns.db = ControlCharDB
    ns.Data.EnsureSets(ns.db, ns.L.SET_DEFAULT) -- det du hadde, blir settet «Solo»
    return
  end
  if event == "PLAYER_LOGIN" then
    ns.Scan.wellFed = wellFedName()
    ns.Data.Reclassify(ns.db, Core.Resolve) -- ting som ble lagt inn med feil type (potion som buffting)
    ns.Medallion.Create(ns.db, ns.L)
    ns.Medallion.onDrop = ns.AddFromCursor
    ns.Tray.Create(ns.Medallion.frame, "left")
    ns.Tray.Create(ns.Medallion.frame, "right")
    ns.SideBar.Create(ns.Medallion.frame, "left")
    ns.SideBar.Create(ns.Medallion.frame, "right")
    ns.SideBar.onDrop = Actions.DropOnSide
    ns.SideBar.onRemove = Actions.Remove
    ns.SideBar.onMove = Actions.Move
    ns.Medallion.isSideOpen = ns.SideBar.IsOpen
    local okF, faction = pcall(UnitFactionGroup, "player")
    if okF and not ns.Scan.isSecret(faction) then ns.Data.SeedCities(ns.db, faction) end
    ns.CityWatch.Init(ns.db)
    ns.CityWatch.onDepart = Core.Depart
    ns.Menu.Create(ns.Medallion.frame, ns.db, ns.L)
    ns.Menu.onChange = Core.Draw
    ns.Menu.onDrop = Actions.DropOn
    ns.Menu.onFollow = Actions.ToggleFollow
    ns.Menu.onAddCity = Actions.AddCity
    ns.Menu.onRemoveCity = Actions.RemoveCity
    ns.Menu.onSwap = Actions.SwapSides
    ns.Menu.onToggleCount = Actions.ToggleCount
    ns.Menu.onToggleOpenCore = Actions.ToggleOpenCore
    ns.Menu.onToggleFade = Actions.ToggleFade
    ns.Menu.onFadeLevel = Actions.SetFadeLevel
    ns.Menu.onToggleBigAlert = Actions.ToggleBigAlert
    ns.Medallion.isBusy = function()
      return ns.Menu.IsOpen() or ns.SideBar.IsOpen("left") or ns.SideBar.IsOpen("right") or false
    end
    ns.Menu.onUseSet = Actions.UseSet
    ns.Menu.onNewSet = Actions.AskNewSet
    ns.Menu.onEditSet = Actions.AskEditSet
    ns.Menu.onEquip = Actions.EquipSet
    ns.Menu.gearPlan = function() return Core.GearPlan(ns.db.self) end
    ns.Menu.onToggleCityCheck = Actions.ToggleCityCheck
    ns.Menu.onScale = Actions.SetScale
    ns.Medallion.isMenuOpen = ns.Menu.IsOpen
    -- Det sikre skriptet på medaljongen åpner/lukker disse i kamp (fase 7)
    -- (Referansene kan ikke settes i kamp; /reload midt i kamp: de settes når kampen er over.)
    ns.Tray.CreateNext()
    ns.RunAfterCombat(function()
      ns.Tray.SetNextRefs()
      ns.Medallion.SetRefs({
        sbleft = ns.SideBar.Get("left").frame, sbright = ns.SideBar.Get("right").frame,
        trleft = ns.Tray.Get("left").frame, trright = ns.Tray.Get("right").frame,
        menu = ns.Menu.frame,
      })
      ns.SideBar.SetRefs("left", ns.Tray.Get("left").frame)
      ns.SideBar.SetRefs("right", ns.Tray.Get("right").frame)
      ns.Menu.SetRefs()
    end)
    ns.Medallion.onSecureToggle = Core.Draw
    ns.SideBar.onClosed = function() Core.Draw() end
    if InCombatLockdown() then ns.Medallion.SetCombat(true, true) end
    ns.Medallion.onZoneClick = function(z)
      if InCombatLockdown() then return end
      if z == "left" or z == "right" then
        ns.SideBar.SetOpen(z, not ns.SideBar.IsOpen(z))
        Core.Draw()
      elseif z == "down" then
        ns.Menu.SetOpen(not ns.Menu.IsOpen())
        Core.Draw()
      end
    end
    pcall(self.RegisterUnitEvent, self, "UNIT_AURA", "player")
    -- Partyets buffer: egne små rammer (RegisterUnitEvent tar to enheter), så vi aldri må sammenligne enhetsnavn
    for _, pair in ipairs({ { "party1", "party2" }, { "party3", "party4" } }) do
      local pf = CreateFrame("Frame")
      pcall(pf.RegisterUnitEvent, pf, "UNIT_AURA", pair[1], pair[2])
      pf:SetScript("OnEvent", function() ns.Refresh(true) end)
    end
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    for e in pairs(CAST) do pcall(self.RegisterUnitEvent, self, e, "player") end
    for _, e in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                         "PLAYER_ENTERING_WORLD", "GET_ITEM_INFO_RECEIVED",
                         "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "TAXIMAP_OPENED", "GOSSIP_SHOW",
                         "TAXIMAP_CLOSED", "GOSSIP_CLOSED", "PLAYER_EQUIPMENT_CHANGED",
                         "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_CLOSE" }) do
      pcall(self.RegisterEvent, self, e)
    end
    C_Timer.NewTicker(0.25, function()
      -- Byvakt: les stedet selv også. Ut av et hus (Anvilmar, et vertshus) gir ikke alltid ZONE_CHANGED_NEW_AREA
      -- (Daniel 5. okt: ingen advarsel ut av Anvilmar). CityWatch.Zone gjør ingenting når stedet er det samme.
      ns.CityWatch.Zone(ns.Menu.Zone())
      ns.CityWatch.Check()
      Core.Draw()
      if Core.tradeOpen and ns.Craft and ns.Craft.UpdateButton then ns.Craft.UpdateButton(true) end
    end) -- én felles klokke for nedtellingene
    ns.Refresh(true)
    return
  end
  if CAST[event] then
    local e, cast = ns.Track.OnEvent(event, arg1, ...)
    if e then
      if ns.Rules.isParty(e) then
        ns.Scan.ConfirmParty(e, cast and cast.target and cast.target.name, cast and cast.group, members, ns.db.durations)
      else
        ns.Scan.Confirm(e, ns.db.durations)
      end
      ns.Refresh(true)
    end
  elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
    ns.CityWatch.Zone(ns.Menu.Zone())
    ns.Refresh(false) -- «Du er i …» i menyen
  elseif event == "TAXIMAP_OPENED" then
    Core.taxiOpen = true
    ns.CityWatch.Taxi("map")
  elseif event == "TAXIMAP_CLOSED" or event == "GOSSIP_CLOSED" then
    -- Lukket uten å fly? Da skal varselet gjelde neste gang du drar (sjekkes litt etterpå: du er ikke i lufta,
    -- og verken samtalen eller kartet er åpne)
    if event == "TAXIMAP_CLOSED" then Core.taxiOpen = false else Core.gossipOpen = false end
    C_Timer.After(1.5, function()
      if Core.taxiOpen or Core.gossipOpen then return end
      local ok, flying = pcall(UnitOnTaxi, "player")
      if ok and not ns.Scan.isSecret(flying) and flying == false then ns.CityWatch.Rearm() end
    end)
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_LIST_UPDATE" then
    -- Yrkesvinduet: les oppskriftene litt etterpå (lista fylles etter at vinduet er åpnet), til «Lag selv» i tooltipen
    -- (ns.Craft finnes ikke hvis spillet ikke er startet på nytt etter at Craft.lua kom i TOC – /reload leser ikke TOC)
    C_Timer.After(0.3, function() if ns.Craft then ns.Craft.Read(ns.db) end end)
    if event == "TRADE_SKILL_SHOW" then
      Core.tradeOpen = true
      C_Timer.After(0.5, function() if ns.Craft and ns.Craft.ProbeUI then ns.Craft.ProbeUI(ns.db) end end)
    end
  elseif event == "TRADE_SKILL_CLOSE" then
    Core.tradeOpen = false
    if ns.Craft and ns.Craft.UpdateButton then ns.Craft.UpdateButton(false) end
  elseif event == "GOSSIP_SHOW" then
    Core.gossipOpen = true
    -- Flight master: si fra før du trykker «I need a ride» (Daniel 5. okt). Flykartet gir ikke et varsel til.
    local taxi, seen = ns.Scan.GossipHasTaxi()
    ns.db.debug = ns.db.debug or {}
    ns.db.debug.gossip = { at = date and date("%Y-%m-%d %H:%M:%S") or nil, zone = ns.Menu.Zone(), taxi = taxi, options = seen }
    if taxi then ns.CityWatch.Taxi("gossip") end
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Båt, portal og hearthstone gir lasteskjerm. Sonenavnet kan være tomt akkurat nå (V8): prøv igjen om litt.
    ns.CityWatch.Zone(ns.Menu.Zone())
    C_Timer.After(1, function() ns.CityWatch.Zone(ns.Menu.Zone()) end)
    ns.Refresh(true)
  elseif event == "PLAYER_REGEN_ENABLED" then
    ns.Medallion.SetCombat(false)
    ns.EntryButton.ResetBindings()
    local queue = afterCombat
    afterCombat = {}
    for _, fn in ipairs(queue) do pcall(fn) end
    ns.Refresh(true) -- les alt på nytt, legg ut knappene på nytt (SPEC §6.8)
  elseif event == "PLAYER_REGEN_DISABLED" then
    ns.Medallion.SetCombat(true)
    auraCache, partyAuraCache = nil, nil
    Core.Draw()
  else
    ns.Refresh(event == "UNIT_AURA" or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE")
  end
end)

------------------------------------------------------------------------
-- Tasteoppsettet (Bindings.xml): «Control» › «Neste buff»
BINDING_HEADER_CONTROL = "Control"
_G["BINDING_NAME_CLICK ControlNextBuff:LeftButton"] = "Neste buff"

-- Kommandoer: /ctrl (Daniel 5. okt: alltid /ctrl). /control virker fortsatt, men nevnes ikke noe sted.
------------------------------------------------------------------------

SLASH_CONTROL1 = "/ctrl"
SLASH_CONTROL2 = "/control"
SlashCmdList.CONTROL = function(msg)
  -- Ikke lower() på hele teksten: den ødelegger «æøå» i noen klienter. Sammenlign råteksten også.
  local raw = (msg or ""):match("^%s*(.-)%s*$")
  local cmd = raw:lower()
  if not ns.db then return Say(ns.L.NOT_READY) end
  if cmd:sub(1, 5) == "debug" then
    return ns.DebugCommand(raw)
  elseif cmd == "test" then
    -- Testdata rød → oransje → alt med → tom → dine egne
    if Core.sample == nil then Core.sample = 1
    elseif Core.sample >= #ns.Data.SAMPLES then Core.sample = nil
    else Core.sample = Core.sample + 1 end
    Core.Draw()
    Say(string.format(ns.L.TEST_SAMPLE,
      Core.sample and ns.L["SAMPLE_" .. ns.Data.SAMPLES[Core.sample]:upper()] or ns.L.MODE_LIVE))
  elseif raw == "lås" or raw == "Lås" or cmd == "las" or cmd == "lock" then
    ns.Medallion.SetLocked(not ns.db.ui.locked)
    Say(ns.db.ui.locked and ns.L.LOCKED or ns.L.UNLOCKED)
  elseif cmd == "avstand" then
    -- Viser/skjuler knappen «Avstandstest» under Oppsett i menyen (data til shouts, Daniel 5. okt)
    ns.db.debug = ns.db.debug or {}
    ns.db.debug.rangeButton = not ns.db.debug.rangeButton
    Say(ns.db.debug.rangeButton and ns.L.RANGE_ON or ns.L.RANGE_OFF)
    Core.Draw()
  elseif cmd == "stort" or cmd == "stort borte" then
    Core.BigTest(cmd == "stort borte")
  elseif cmd == "stortest" then
    Core.BigTest(true, "Battle Shout")
  elseif raw == "våpen" or raw == "Våpen" or cmd == "vapen" then
    -- Hva spillet sier om våpenet og buffene dine akkurat nå (Daniel 7. okt: Flametongue sto som «Gått ut»)
    local function show(v)
      if ns.Scan.isSecret(v) then return "<hemmelig>" end
      return tostring(v)
    end
    local probe = { at = date and date("%Y-%m-%d %H:%M:%S") or nil }
    if GetWeaponEnchantInfo then
      local w = { pcall(GetWeaponEnchantInfo) }
      probe.raw = {}
      for i = 2, #w do probe.raw[i - 1] = show(w[i]) end
      Say(string.format("Våpen (GetWeaponEnchantInfo): %s", w[1] and table.concat(probe.raw, ", ") or ("feil: " .. tostring(w[2]))))
    else
      Say("Våpen: GetWeaponEnchantInfo finnes ikke")
    end
    local names = {}
    for i = 1, 40 do
      local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
      if not ok or not a then break end
      names[#names + 1] = show(a.name) .. " (" .. show(a.spellId) .. ")"
    end
    probe.auras = names
    Say("Buffer på deg: " .. (#names > 0 and table.concat(names, ", ") or "ingen"))
    -- Våpenets tooltip (der står forsterkningen i grønt, «Flametongue 3 (60 min)»)
    probe.tips = {}
    for _, slot in ipairs({ 16, 17 }) do
      local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
      local lines = {}
      if ok and type(data) == "table" and type(data.lines) == "table" then
        for _, l in ipairs(data.lines) do lines[#lines + 1] = show(l.leftText) end
      end
      probe.tips[slot] = lines
      if #lines > 0 then
        local left, line = ns.Scan.WeaponTipEnchant(slot)
        Say(string.format("Tooltip %s: %s", slot == 16 and "MH" or "OH", table.concat(lines, " | ")))
        Say(string.format("  → forsterkning: %s", left and (line .. " = " .. left .. " s") or "ingen"))
      end
    end
    ns.db.debug = ns.db.debug or {}
    ns.db.debug.weaponProbe = probe
  elseif cmd == "varsel" then
    Core.Depart(ns.Menu.Zone() or "?") -- se hvordan byvaktvarselet ser ut akkurat nå
  elseif cmd == "angre" then
    Actions.Undo()
  elseif raw == "tøm" or raw == "Tøm" or cmd == "tom" then
    if InCombatLockdown() then return Say(ns.L.NOT_IN_COMBAT) end
    for i = #ns.db.self, 1, -1 do ns.db.self[i] = nil end -- tøm settet du står i (samme tabell, så settet følger med)
    ns.Refresh(true)
    Say(ns.L.LIST_CLEARED)
  elseif cmd == "nullstill" or cmd == "reset" then
    if InCombatLockdown() then return Say(ns.L.NOT_IN_COMBAT) end
    ns.db.ui.point = { "CENTER", "UIParent", "CENTER", 0, 200 }
    ns.db.ui.scale = 1.0
    ns.Medallion.ApplyPosition()
    ns.Medallion.SetScale(1.0)
    Core.Draw()
    Say(ns.L.RESET_DONE)
  else
    Say(ns.L.HELP)
  end
end
