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

Core.sample = nil -- nil = ekte data; ellers indeks i Data.SAMPLES (/control test)
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
    s.cast = ns.Rules.partyCast(e, s, { inParty = #members > 0, groupUsable = e.groupSpell and ns.Scan.SpellUsable(e.groupSpell) })
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

function Core.Draw()
  if not ns.Medallion.frame then return end
  local model = Core.Model()
  local inCombat = InCombatLockdown()
  local view = ns.Rules.render(model, ns.L, { inCombat = inCombat, prevTray = prevTray })
  ns.view, ns.model = view, model
  ns.Medallion.Update(view)
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
  else
    -- Sidemenyen dekker knappene ved medaljongen på sin side mens den er åpen (SPEC §7.4)
    local mbOut = ns.SideBar.IsOpen(mb) and {} or trayEntries(view.tray.self, map)
    ns.Tray.Layout(mb, mbOut, model.st, ns.L)
    local pbOut = ns.SideBar.IsOpen(pb) and {} or trayEntries(view.tray.party, pmap)
    ns.Tray.Layout(pb, pbOut, model.st, ns.L)
    ns.SideBar.Layout(mb, model.self, model.st, view, false, ns.L)
    ns.SideBar.Layout(pb, model.party, model.st, view, true, ns.L)
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
-- Legge til: slipp en spell eller en ting på medaljongen (snarvei til sidemenyene kommer i fase 4)
------------------------------------------------------------------------

local function wellFedName() return (ns.Scan.SpellInfo(19705)) or "Well Fed" end

-- Info om en spell eller et item, som Data.MakeEntry tar. nil hvis spillet ikke kjenner den (ennå).
function Core.Resolve(kind, id)
  if kind == "spell" then
    local name = ns.Scan.SpellInfo(id)
    if not name then return nil end
    return { kind = "spell", spellId = id, name = name }
  end
  local name, spell, classID, subClassID = ns.Scan.ItemInfo(id)
  if not name then return nil end
  -- Buffting bare for eliksir, flask, scroll og mat som gir «Well Fed». Potions, bandasjer og healthstones har
  -- også en bruk-effekt, men gir ingen buff å vente på: de er lagerting (Daniel 4. okt, en potion som ble rød).
  local isFood = classID == 0 and subClassID == 5 and ns.Scan.TooltipHas(id, wellFedName())
  local givesBuff = spell and classID == 0 and (ns.Data.BUFF_SUBCLASS[subClassID] or isFood)
  return { kind = "item", itemId = id, itemName = name, itemSpell = givesBuff and spell or nil, isFood = isFood,
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
local function isPartyEntry(e) return e.type == "partyspell" end

function Actions.ToggleTier(e)
  if InCombatLockdown() then return end
  e.tier = e.tier == 1 and 2 or 1
  ns.Refresh(false)
end

function Actions.Wheel(e, delta, step)
  if InCombatLockdown() or not (e.type == "buffitem" or e.type == "item") then return end
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

function ns.AddFromCursor()
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
  local dup = ns.Data.FindDuplicate(ns.db.self, info)
  if dup then return Say(string.format(ns.L.DUPLICATE, dup.name)) end
  local e = ns.Data.MakeEntry(ns.db, info, 1)
  table.insert(ns.db.self, e)
  Say(string.format(ns.L.ADDED, e.name))
  ns.Refresh(true)
end

-- Slipp på en sidemeny: sist i tier II på den siden. En spell på gruppesiden = gruppebuff (SPEC §8).
function Actions.DropOnSide(sideKey)
  if InCombatLockdown() then return end
  local kind, a, _, d = GetCursorInfo()
  local party = sideKey == pbSide()
  local info
  if kind == "spell" then
    info = Core.Resolve("spell", d or a)
  elseif kind == "item" and not party then
    info = Core.Resolve("item", a)
  else
    if kind then ClearCursor() Say(party and ns.L.EMPTY_PARTY or ns.L.NOT_ADDABLE) end
    return
  end
  ClearCursor()
  if not info then return Say(ns.L.NOT_KNOWN) end
  local list = party and ns.db.party or ns.db.self
  local dup = ns.Data.FindDuplicate(list, info)
  if dup then return Say(string.format(ns.L.DUPLICATE, dup.name)) end
  local e = party and ns.Data.MakePartyEntry(ns.db, info) or ns.Data.MakeEntry(ns.db, info, 2)
  table.insert(list, e)
  Say(string.format(ns.L.ADDED_SIDE, e.name))
  ns.Refresh(true)
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
    ns.Medallion.onZoneClick = function(z) -- menyen (nede) kommer i fase 6
      if (z == "left" or z == "right") and not InCombatLockdown() then
        ns.SideBar.SetOpen(z, not ns.SideBar.IsOpen(z))
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
                         "PLAYER_ENTERING_WORLD", "GET_ITEM_INFO_RECEIVED" }) do
      pcall(self.RegisterEvent, self, e)
    end
    C_Timer.NewTicker(0.25, function() Core.Draw() end) -- én felles klokke for nedtellingene
    ns.Refresh(true)
    return
  end
  if CAST[event] then
    local e, cast = ns.Track.OnEvent(event, arg1, ...)
    if e then
      if e.type == "partyspell" then
        ns.Scan.ConfirmParty(e, cast and cast.target and cast.target.name, cast and cast.group, members, ns.db.durations)
      else
        ns.Scan.Confirm(e, ns.db.durations)
      end
      ns.Refresh(true)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    local queue = afterCombat
    afterCombat = {}
    for _, fn in ipairs(queue) do pcall(fn) end
    ns.Refresh(true) -- les alt på nytt, legg ut knappene på nytt (SPEC §6.8)
  elseif event == "PLAYER_REGEN_DISABLED" then
    auraCache, partyAuraCache = nil, nil
    Core.Draw()
  else
    ns.Refresh(event == "UNIT_AURA" or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE")
  end
end)

------------------------------------------------------------------------
-- Kommandoer: /control og /ctl
------------------------------------------------------------------------

SLASH_CONTROL1 = "/control"
SLASH_CONTROL2 = "/ctl"
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
  elseif cmd == "angre" then
    Actions.Undo()
  elseif raw == "tøm" or raw == "Tøm" or cmd == "tom" then
    if InCombatLockdown() then return Say(ns.L.NOT_IN_COMBAT) end
    ns.db.self = {}
    ns.Refresh(true)
    Say(ns.L.LIST_CLEARED)
  elseif cmd == "nullstill" or cmd == "reset" then
    if InCombatLockdown() then return Say(ns.L.NOT_IN_COMBAT) end
    ns.db.ui.point = { "CENTER", "UIParent", "CENTER", 0, 200 }
    ns.db.ui.scale = 1.0
    ns.Medallion.ApplyPosition()
    ns.Medallion.frame:SetScale(1.0)
    Say(ns.L.RESET_DONE)
  else
    Say(ns.L.HELP)
  end
end
