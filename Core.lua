-- Control: navnerom, oppstart, hendelser, kø for etter kamp og kommandoer (SPEC §17).
local addonName, ns = ...

local Core = {}
ns.Core = Core

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

local function Say(msg) print("|cffffd100[Control]|r " .. msg) end
ns.Say = Say

------------------------------------------------------------------------
-- Tegning: tilstand → regler → UI (SPEC §17: én tegnerunde)
------------------------------------------------------------------------

-- Fram til fase 3 kommer tilstanden fra testdata (SPEC §18, fase 2).
Core.sample = 1

function Core.Model()
  return ns.Data.Sample(ns.Data.SAMPLES[Core.sample])
end

function ns.Refresh()
  if not ns.Medallion.frame then return end
  local view = ns.Rules.render(Core.Model(), ns.L, { inCombat = InCombatLockdown() })
  ns.view = view
  ns.Medallion.Update(view)
end

------------------------------------------------------------------------
-- Hendelser
------------------------------------------------------------------------

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= addonName then return end
    ControlCharDB = ns.Data.Init(ControlCharDB)
    ns.db = ControlCharDB
  elseif event == "PLAYER_LOGIN" then
    ns.Medallion.Create(ns.db, ns.L)
    ns.Medallion.onZoneClick = function() end -- sidemenyer og meny kommer i fase 4 og 6
    ns.Refresh()
  elseif event == "PLAYER_REGEN_ENABLED" then
    local queue = afterCombat
    afterCombat = {}
    for _, fn in ipairs(queue) do pcall(fn) end
    ns.Refresh()
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
    Core.sample = Core.sample % #ns.Data.SAMPLES + 1
    ns.Refresh()
    Say(string.format(ns.L.TEST_SAMPLE, ns.L["SAMPLE_" .. ns.Data.SAMPLES[Core.sample]:upper()]))
  elseif raw == "lås" or raw == "Lås" or cmd == "las" or cmd == "lock" then
    ns.Medallion.SetLocked(not ns.db.ui.locked)
    Say(ns.db.ui.locked and ns.L.LOCKED or ns.L.UNLOCKED)
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
