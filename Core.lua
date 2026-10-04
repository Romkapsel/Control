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
local prevTray, auraCache

function Core.Model()
  if Core.sample then return ns.Data.Sample(ns.Data.SAMPLES[Core.sample]) end
  local st = ns.Scan.State(ns.db, auraCache)
  return { self = ns.db.self, party = {}, st = st }
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
  if inCombat then
    ns.Tray.Paint(mbSide(), map, model.st, ns.L) -- frosset: bare tider, lager og glød
  else
    ns.Tray.Layout(mbSide(), trayEntries(view.tray.self, map), model.st, ns.L)
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
  local name, spell, isFood = ns.Scan.ItemInfo(id)
  if not name then return nil end
  return { kind = "item", itemId = id, itemName = name, itemSpell = spell, isFood = isFood,
           wellFed = wellFedName(), count = ns.Scan.ItemCount(id) }
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
    local n = ns.Data.ImportKlarsjekk(ns.db, KlarsjekkDB, Core.Resolve) -- den gamle lista, én gang (Q10)
    if n > 0 then Say(string.format(ns.L.IMPORTED, n)) end
    ns.Medallion.Create(ns.db, ns.L)
    ns.Medallion.onZoneClick = function() end -- sidemenyer og meny kommer i fase 4 og 6
    ns.Medallion.onDrop = ns.AddFromCursor
    ns.Tray.Create(ns.Medallion.frame, "left")
    ns.Tray.Create(ns.Medallion.frame, "right")
    pcall(self.RegisterUnitEvent, self, "UNIT_AURA", "player")
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
    local e = ns.Track.OnEvent(event, arg1, ...)
    if e then
      ns.Scan.Confirm(e, ns.db.durations)
      ns.Refresh(true)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    local queue = afterCombat
    afterCombat = {}
    for _, fn in ipairs(queue) do pcall(fn) end
    ns.Refresh(true) -- les alt på nytt, legg ut knappene på nytt (SPEC §6.8)
  elseif event == "PLAYER_REGEN_DISABLED" then
    auraCache = nil
    Core.Draw()
  else
    ns.Refresh(event == "UNIT_AURA" or event == "PLAYER_ENTERING_WORLD")
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
