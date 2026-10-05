-- Control: sidemenyene (SPEC §7.4). Folder ut fra medaljongen når du klikker venstre eller høyre sone.
-- Rad 1: tier I, fure, tier II, tomme ruter (minst 5 plasser, alltid minst én; den første er slippmål med «+»).
-- Rad 2: statuslinja (§6.6). Samme forankring som knappene ved medaljongen, og dekker dem på den siden.
-- Knappene er sikre (klikk kaster); rammen åpnes, lukkes og bygges om bare utenfor kamp.
-- Dra: Shift + dra flytter eller fjerner (vanlig klikk kaster på «ned», så et vanlig dra ville kastet/brukt).
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local SB = {}
ns.SideBar = SB

local BTN, GAP, MED = 40, 6, 64
local START, AIR = MED / 2, 36
-- Rad 1 som knappene ved medaljongen: 4 px kant + 4 px luft + 40 px knapp + 4 px luft (knappene står likt)
local ROW1, GROOVE, ROW2 = 52, 2, 30
local HEIGHT = ROW1 + GROOVE + ROW2 + 4 -- 4 px kant nederst (svart, bronse, svart)
local TIER_GAP = 12 -- fura mellom tier I og II: 2 px streker + marg

local bars = {}

local function chrome(f) Style.Frame(f) end -- lik kant hele veien rundt (UI/Style.lua)

-- Fure: 1 px svart + 1 px bronse (vannrett under rad 1, loddrett mellom tier I og II)
local function groove(f, horizontal)
  local a = f:CreateTexture(nil, "ARTWORK", nil, 1)
  local b = f:CreateTexture(nil, "ARTWORK", nil, 1)
  a:SetColorTexture(0, 0, 0, 1)
  local c = Style.hex("4A3920")
  b:SetColorTexture(c[1], c[2], c[3], 1)
  if horizontal then a:SetHeight(1) b:SetHeight(1) else a:SetWidth(1) b:SetWidth(1) end
  return a, b
end

------------------------------------------------------------------------
-- Tomme ruter
------------------------------------------------------------------------

local function emptySlot(bar, i)
  local s = bar.slots[i]
  if s then return s end
  s = CreateFrame("Button", nil, bar.frame)
  s:SetSize(BTN, BTN)
  local edge = Style.Rect(s, "BACKGROUND", 0, BTN, BTN, C.black, 1)
  local inner = Style.Rect(s, "BACKGROUND", 1, BTN - 2, BTN - 2, Style.hex("0B0907"), 1)
  s.plus = s:CreateFontString(nil, "OVERLAY")
  if not s.plus:SetFont(Style.FONT_HEAD, 20, "") then s.plus:SetFontObject(GameFontNormalLarge) end
  local pc = Style.hex("5E5446")
  s.plus:SetTextColor(pc[1], pc[2], pc[3])
  s.plus:SetPoint("CENTER")
  s.plus:SetText("+")
  -- Kryssede sverd i siste tomme rute i kamp (frosset)
  local sw = Style.hex("8A7A5A")
  s.swords = {
    Style.Line(s, "OVERLAY", 1, -9, -9, 9, 9, 2, sw, 1),
    Style.Line(s, "OVERLAY", 1, -9, 9, 9, -9, 2, sw, 1),
  }
  s:SetScript("OnReceiveDrag", function() SB.DropOn(bar.side) end)
  s:SetScript("OnMouseUp", function() if GetCursorInfo() then SB.DropOn(bar.side) end end)
  s:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.hint or "", 1, 1, 1)
    GameTooltip:Show()
  end)
  s:SetScript("OnLeave", function() GameTooltip:Hide() end)
  bar.slots[i] = s
  return s
end

local function swordsAlpha(s, a)
  for _, l in ipairs(s.swords) do l:SetAlpha(a) end
end

------------------------------------------------------------------------
-- Bygging
------------------------------------------------------------------------

function SB.Create(root, side)
  local f = CreateFrame("Frame", nil, root)
  f:SetFrameLevel(root:GetFrameLevel() + 2)
  f:SetHeight(HEIGHT)
  if side == "right" then
    f:SetPoint("TOPLEFT", root, "TOPLEFT", START, -4)
  else
    f:SetPoint("TOPRIGHT", root, "TOPRIGHT", -START, -4)
  end
  chrome(f)
  f:EnableMouse(true)
  f:SetScript("OnReceiveDrag", function() SB.DropOn(side) end)
  f:SetScript("OnMouseUp", function() if GetCursorInfo() then SB.DropOn(side) end end)

  local bar = { frame = f, side = side, buttons = {}, slots = {}, ids = {} }
  bar.hA, bar.hB = groove(f, true)
  local y = -ROW1
  bar.hA:SetPoint("TOPLEFT", f, "TOPLEFT", side == "right" and (2 + AIR - 6) or 8, y)
  bar.hA:SetPoint("TOPRIGHT", f, "TOPRIGHT", side == "right" and -8 or -(2 + AIR - 6), y)
  bar.hB:SetPoint("TOPLEFT", bar.hA, "BOTTOMLEFT")
  bar.hB:SetPoint("TOPRIGHT", bar.hA, "BOTTOMRIGHT")
  bar.vA, bar.vB = groove(f, false)
  bar.vA:SetHeight(BTN)
  bar.vB:SetHeight(BTN)

  bar.status = f:CreateFontString(nil, "OVERLAY")
  if not bar.status:SetFont(Style.FONT_HEAD, 12, "") then bar.status:SetFontObject(GameFontNormal) end
  bar.status:SetShadowColor(0, 0, 0, 1)
  bar.status:SetShadowOffset(1, -1)
  bar.status:SetWordWrap(false)
  bar.status:SetJustifyH(side == "right" and "LEFT" or "RIGHT")
  bar.status:SetHeight(ROW2)
  if side == "right" then
    bar.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2 + AIR + 2, 4)
    bar.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 4)
  else
    bar.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(2 + AIR + 2), 4)
    bar.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 4)
  end

  f.fadeIn = f:CreateAnimationGroup()
  local a = f.fadeIn:CreateAnimation("Alpha")
  a:SetFromAlpha(0)
  a:SetToAlpha(1)
  a:SetDuration(0.2)
  f:Hide()
  bars[side] = bar
  return bar
end

-- x for plass nr. «slot» (0-basert), med fure før tier II
local function slotX(slot, n1, hasGroove)
  local x = 2 + AIR + slot * (BTN + GAP)
  if hasGroove and slot >= n1 then x = x + TIER_GAP end
  return x
end

local function place(bar, frame, x)
  frame:ClearAllPoints()
  if bar.side == "right" then
    frame:SetPoint("TOPLEFT", bar.frame, "TOPLEFT", x, -8)
  else
    frame:SetPoint("TOPRIGHT", bar.frame, "TOPRIGHT", -x, -8)
  end
end

-- Rich text for statuslinja: gull etikett, navn i buff-fargen, lagertall i lager-fargen
local SEVC = { [0] = C.text, [1] = C.orange, [2] = C.red }
local function hexOf(c) return string.format("%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255) end
local function colored(text, c) return "|cff" .. hexOf(c) .. text .. "|r" end

function SB.StatusText(status, isParty, L)
  local out = colored(status.label, C.gold) .. L.LABEL_GAP
  if status.ok then return out .. colored(isParty and L.PARTY_ALL_OK or L.ALL_OK, C.green) end
  local parts = {}
  for _, p in ipairs(status.parts) do
    if isParty then
      parts[#parts + 1] = colored(p.name .. ": ", C.help) .. colored(p.members, C.text)
    else
      local t = colored(p.name, SEVC[p.nameSev] or C.text)
      if p.stock then t = t .. " " .. colored(p.stock, SEVC[p.stockSev] or C.text) end
      parts[#parts + 1] = t
    end
  end
  if status.more and status.more > 0 then parts[#parts + 1] = colored("+" .. status.more, C.help) end
  return out .. table.concat(parts, colored(L.SEP, C.help))
end

-- Bygg sidemenyen fra Rules.render (side = view.side.self/party, status = view.status.self/party). Bare utenfor kamp.
function SB.Layout(sideKey, entries, st, view, isParty, L)
  local bar = bars[sideKey]
  if not bar or InCombatLockdown() then return false end
  local sideView = isParty and view.side.party or view.side.self
  local byId = {}
  for _, e in ipairs(entries) do byId[e.id] = e end
  local order = {}
  for _, id in ipairs(sideView.tier1) do order[#order + 1] = byId[id] end
  for _, id in ipairs(sideView.tier2) do order[#order + 1] = byId[id] end
  local n1, groove = #sideView.tier1, sideView.groove
  bar.ids = {}
  for i, e in ipairs(order) do
    local b = bar.buttons[i]
    if not b then
      b = ns.EntryButton.Create(bar.frame)
      b.canDrag = true
      bar.buttons[i] = b
    end
    b.side, b.index, b.isParty = sideKey, i, isParty
    place(bar, b, slotX(i - 1, n1, groove))
    ns.EntryButton.Bind(b, e, st[e.id]) -- setter attributter bare når noe er endret
    ns.EntryButton.Paint(b, e, st[e.id], L)
    b:Show()
    bar.ids[i] = e.id
  end
  for i = #order + 1, #bar.buttons do bar.buttons[i]:Hide() end
  for k = 1, sideView.slots do
    local s = emptySlot(bar, k)
    place(bar, s, slotX(#order + k - 1, n1, groove))
    s.plus:SetShown(k == 1)
    s.hint = (k == 1) and (isParty and L.EMPTY_PARTY or L.EMPTY_SELF) or L.FREE_SLOT
    swordsAlpha(s, 0)
    s:Show()
  end
  for k = sideView.slots + 1, #bar.slots do bar.slots[k]:Hide() end
  bar.vA:SetShown(groove)
  bar.vB:SetShown(groove)
  if groove then
    local x = slotX(n1, n1, false) + 2
    place(bar, bar.vA, x)
    place(bar, bar.vB, x + 1)
  end
  bar.frame:SetWidth(sideView.width)
  -- Tom side: ingen statuslinje (den får ikke plass, og «+»-ruta sier hva du kan gjøre)
  bar.status:SetText(#bar.ids == 0 and "" or SB.StatusText(isParty and view.status.party or view.status.self, isParty, L))
  return true
end

-- Utseende i kamp: tider, lager, glød, statuslinje; sverd i siste tomme rute
function SB.Paint(sideKey, entries, st, view, isParty, L)
  local bar = bars[sideKey]
  if not bar then return end
  local byId = {}
  for _, e in ipairs(entries) do byId[e.id] = e end
  for i, id in ipairs(bar.ids) do
    local e = byId[id]
    if e then ns.EntryButton.Paint(bar.buttons[i], e, st[id], L) end
  end
  -- Tom side: ingen statuslinje (den får ikke plass, og «+»-ruta sier hva du kan gjøre)
  bar.status:SetText(#bar.ids == 0 and "" or SB.StatusText(isParty and view.status.party or view.status.self, isParty, L))
  local inCombat = InCombatLockdown()
  local last
  for _, s in ipairs(bar.slots) do if s:IsShown() then last = s end end
  for _, s in ipairs(bar.slots) do swordsAlpha(s, (inCombat and s == last) and 1 or 0) end
end

function SB.IsOpen(sideKey) return bars[sideKey] and bars[sideKey].frame:IsShown() end

function SB.SetOpen(sideKey, open)
  local bar = bars[sideKey]
  if not bar or InCombatLockdown() then return false end
  if open then
    bar.frame:Show()
    bar.frame.fadeIn:Play()
  else
    bar.frame:Hide()
  end
  return true
end

function SB.Get(sideKey) return bars[sideKey] end

------------------------------------------------------------------------
-- Dra: Shift + dra en knapp. Slipp utenfor sidemenyen = fjern; på en annen knapp = flytt dit.
------------------------------------------------------------------------

local ghost, dragging

local function ensureGhost()
  if ghost then return ghost end
  ghost = CreateFrame("Frame", nil, UIParent)
  ghost:SetSize(30, 30)
  ghost:SetFrameStrata("TOOLTIP")
  ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
  ghost.icon:SetAllPoints()
  ghost.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  ghost.text = ghost:CreateFontString(nil, "OVERLAY")
  if not ghost.text:SetFont(Style.FONT_HEAD, 12, "OUTLINE") then ghost.text:SetFontObject(GameFontNormal) end
  ghost.text:SetPoint("LEFT", ghost, "RIGHT", 6, 0)
  ghost.text:SetTextColor(C.red[1], C.red[2], C.red[3])
  ghost:Hide()
  return ghost
end

local function hoveredButton(bar)
  for i, b in ipairs(bar.buttons) do
    if b:IsShown() and b:IsMouseOver() then return i end
  end
end

function SB.BeginDrag(b)
  if InCombatLockdown() or not b.canDrag or not b.entry then return end
  local g = ensureGhost()
  dragging = { button = b, bar = bars[b.side] }
  g.icon:SetTexture(b.icon:GetTexture())
  b:SetAlpha(0.35)
  g:SetScript("OnUpdate", function(self)
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    local inside = dragging and dragging.bar.frame:IsMouseOver()
    self.text:SetText(inside and "" or ns.L.DRAG_REMOVE)
    self.icon:SetDesaturated(not inside)
  end)
  g:Show()
end

function SB.EndDrag(b)
  if not dragging or dragging.button ~= b then return end
  local bar = dragging.bar
  dragging = nil
  b:SetAlpha(1)
  if ghost then ghost:Hide() ghost:SetScript("OnUpdate", nil) end
  if InCombatLockdown() then return end
  if not bar.frame:IsMouseOver() then
    if SB.onRemove then SB.onRemove(b.entry, b.isParty) end
  else
    local to = hoveredButton(bar)
    if to and to ~= b.index and SB.onMove then
      SB.onMove(b.entry, bars[b.side].ids[to], b.isParty)
    end
  end
end

function SB.DropOn(sideKey)
  if SB.onDrop then SB.onDrop(sideKey) end
end
