-- Control: knappene ved medaljongen (SPEC §6.4, §7.3). Én tray per side, bare tier I som kan trykkes.
-- Rammen starter i medaljongens midtpunkt (skjult bak sirkelen), 4 px under toppen; første knapp står 6 px utenfor
-- medaljongen, 6 px mellom knappene. Hvilke knapper som står ute, endres bare utenfor kamp (sikre knapper).
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local Tray = {}
ns.Tray = Tray

local BTN, GAP, MED = 40, 6, 64
local START = MED / 2   -- rammen starter i medaljongens midtpunkt
local AIR = 36          -- fra midten til første knapp minus 2: første knapp 6 px utenfor medaljongen
local SEAM = 3          -- rammen starter 3 px fra midten (som sidemenyene); lufta inne i rammen er 3 px mindre
local HEIGHT = 56 -- 4 kant + 4 luft + 40 knapp + 4 luft + 4 kant

local trays = {}

-- Luft på medaljongsiden: vokser med medaljongen (størrelse i menyen), så sirkelen ikke dekker knappene
local function air() return AIR - SEAM + ((ns.Medallion.Extra and ns.Medallion.Extra()) or 0) end

-- Bakgrunn og bronsekant som sidemenyen (SPEC §13.2)
local function chrome(f) Style.Frame(f) end -- lik kant hele veien rundt (UI/Style.lua)

local function popIn(b)
  if not b.popIn then
    b.popIn = b:CreateAnimationGroup()
    local s = b.popIn:CreateAnimation("Scale")
    if s.SetScaleFrom then s:SetScaleFrom(0.55, 0.55) s:SetScaleTo(1, 1) end
    s:SetDuration(0.28)
    s:SetSmoothing("OUT")
  end
  b.popIn:Play()
end

------------------------------------------------------------------------
-- Klikk i kamp (Daniel 4. okt): knappen forsvinner og rekka lukker seg med en gang.
-- Addon-kode kan ikke skjule eller flytte sikre knapper i kamp, men et sikkert skript (restricted Lua) kan,
-- når det startes av klikket selv. Skriptet ser ikke om kastet lyktes (buffene er hemmelige i kamp):
-- feiler det, står det fortsatt i tallet, og knappen kommer tilbake når kampen er over.
-- self = knappen, owner = rammen (SecureHandlerBaseTemplate). Ingen funksjoner defineres i skriptet.
------------------------------------------------------------------------

Tray.AFTER_CLICK = [[
  if button ~= "LeftButton" or SecureCmdOptionParse("[combat] k; u") ~= "k" then return end
  local qn = self:GetAttribute("ks-qn")
  if qn then
    local i = (self:GetAttribute("ks-qi") or 1) + 1
    if i <= qn then
      self:SetAttribute("ks-qi", i)
      self:SetAttribute("unit", self:GetAttribute("ks-q" .. i))
      return
    end
  end
  self:Hide()
  local slots, last = newtable(), 0
  local kids = newtable(owner:GetChildren())
  for i = 1, #kids do
    local k = kids[i]
    local order = k:GetAttribute("ks-order")
    if order and k:IsShown() then
      slots[order] = k
      if order > last then last = order end
    end
  end
  local side, air, n = owner:GetAttribute("ks-side"), owner:GetAttribute("ks-air"), 0
  for order = 1, last do
    local k = slots[order]
    if k then
      local x = 2 + air + n * 46
      k:ClearAllPoints()
      if side == "right" then
        k:SetPoint("TOPLEFT", owner, "TOPLEFT", x, -8)
      else
        k:SetPoint("TOPRIGHT", owner, "TOPRIGHT", -x, -8)
      end
      n = n + 1
    end
  end
  if n == 0 then
    owner:SetAttribute("ks-want", false)
    owner:Hide()
  else
    owner:SetWidth(2 + air + n * 46 + 2)
  end
]]

-- Gruppebuff i kamp (fase 7): neste klikk kaster på neste som manglet før kampen (ks-q1, ks-q2 …),
-- i stedet for på den samme igjen. Knappene ved medaljongen har dette i AFTER_CLICK (og skjules når køen er tom);
-- knappene i sidemenyene og menyen får bare dette.
Tray.RETARGET = [[
  if button ~= "LeftButton" or SecureCmdOptionParse("[combat] k; u") ~= "k" then return end
  local qn = self:GetAttribute("ks-qn")
  if not qn then return end
  local i = (self:GetAttribute("ks-qi") or 1) + 1
  if i > qn then return end
  self:SetAttribute("ks-qi", i)
  self:SetAttribute("unit", self:GetAttribute("ks-q" .. i))
]]

function Tray.Create(root, side)
  local f = CreateFrame("Frame", nil, root, "SecureHandlerBaseTemplate")
  f:SetAttribute("ks-side", side)
  f:SetAttribute("ks-air", AIR - SEAM)
  f:SetFrameLevel(math.max(0, root:GetFrameLevel() - 1))
  f:SetHeight(HEIGHT)
  if side == "right" then
    f:SetPoint("TOPLEFT", root, "TOPLEFT", START + SEAM, -4)
  else
    f:SetPoint("TOPRIGHT", root, "TOPRIGHT", -(START + SEAM), -4)
  end
  chrome(f)
  f:Hide()
  trays[side] = { frame = f, side = side, buttons = {}, ids = {}, air = AIR - SEAM }
  return trays[side]
end

local function button(t, i)
  local b = t.buttons[i]
  if not b then
    b = ns.EntryButton.Create(t.frame)
    SecureHandlerWrapScript(b, "OnClick", t.frame, "", Tray.AFTER_CLICK)
    t.buttons[i] = b
  end
  b:SetAttribute("ks-order", i)
  local x = 2 + t.air + (i - 1) * (BTN + GAP)
  b:ClearAllPoints()
  if t.side == "right" then
    b:SetPoint("TOPLEFT", t.frame, "TOPLEFT", x, -8)
  else
    b:SetPoint("TOPRIGHT", t.frame, "TOPRIGHT", -x, -8)
  end
  return b
end

-- Hvilke knapper som står ute. entries = oppføringene i rekkefølge (innerst først). Bare utenfor kamp.
-- covered = sidemenyen på denne siden er åpen: knappene legges ut, men rammen skjules (det sikre skriptet viser
-- den igjen hvis sidemenyen lukkes i kamp; ks-want sier om det er noe å vise).
function Tray.Layout(side, entries, st, L, covered)
  local t = trays[side]
  if not t or InCombatLockdown() then return false end
  -- Samme knapper som sist: bare nytt utseende (attributter settes ikke på nytt hvert kvarter sekund)
  -- (Et sikkert skript kan ha skjult knapper i kamp: da legges alt ut på nytt.)
  local same = #entries == #t.ids and (#entries == 0 or t.frame:IsShown() or covered) and t.covered == covered
  local a = air()
  if a ~= t.air then -- medaljongen har endret størrelse: legg alt ut på nytt
    t.air = a
    t.frame:SetAttribute("ks-air", a)
    same = false
  end
  for i, e in ipairs(entries) do
    if t.ids[i] ~= e.id or not t.buttons[i]:IsShown() then same = false break end
  end
  t.covered = covered
  t.frame:SetAttribute("ks-want", #entries > 0)
  if same then
    for i, e in ipairs(entries) do
      ns.EntryButton.Bind(t.buttons[i], e, st[e.id]) -- nytt mål for en gruppebuff setter nye attributter
      ns.EntryButton.Paint(t.buttons[i], e, st[e.id], L)
    end
    return true
  end
  local old = {}
  for _, id in ipairs(t.ids) do old[id] = true end
  t.ids = {}
  for i, e in ipairs(entries) do
    local b = button(t, i)
    ns.EntryButton.Bind(b, e, st[e.id])
    ns.EntryButton.Paint(b, e, st[e.id], L)
    b:Show()
    if not old[e.id] then popIn(b) end
    t.ids[i] = e.id
  end
  for i = #entries + 1, #t.buttons do t.buttons[i]:Hide() end
  local n = #entries
  if n > 0 then
    t.frame:SetWidth(2 + t.air + n * BTN + (n - 1) * GAP + 6 + 2)
    t.frame:SetShown(not covered)
  else
    t.frame:Hide()
  end
  return true
end

-- Oppdater utseendet på det som står ute (tider, lager, glød). Virker også i kamp.
function Tray.Paint(side, byId, st, L)
  local t = trays[side]
  if not t then return end
  for i, id in ipairs(t.ids) do
    local e = byId[id]
    if e then ns.EntryButton.Paint(t.buttons[i], e, st[id], L, true) end
  end
end

function Tray.Get(side) return trays[side] end
