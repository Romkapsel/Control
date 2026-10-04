-- Control: 40 px-knappen for én oppføring (SPEC §7.5). En sikker knapp (SecureActionButtonTemplate):
-- venstreklikk kaster spellen på deg selv eller bruker itemet. Attributter settes bare utenfor kamp.
-- Prosessen vises med form, ikke bare farge: tømming ovenfra (brukt tid), stor nedtelling (snart ute),
-- bånd med «ikke på»/«gått ut» og pulserende gullglød (kan trykkes).
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local EB = {}
ns.EntryButton = EB

local SIZE = 40
local NUM_FONT = "Fonts\\ARIALN.TTF"
local GLOW = Style.hex("FFE98A")

local function useKeyDown()
  local ok, v = pcall(GetCVar, "ActionButtonUseKeyDown")
  return ok and v == "1"
end

local function font(fs, size)
  if not fs:SetFont(NUM_FONT, size, "OUTLINE") then fs:SetFontObject(NumberFontNormal) end
end

local function edgeRects(parent, layer, sub, inset, thick, color, alpha)
  local out = {}
  local function r(p1, p2, w, h)
    local t = parent:CreateTexture(nil, layer, nil, sub)
    t:SetColorTexture(color[1], color[2], color[3], alpha)
    t:SetPoint(p1[1], parent, p1[1], p1[2], p1[3])
    t:SetPoint(p2[1], parent, p2[1], p2[2], p2[3])
    if w then t:SetWidth(w) end
    if h then t:SetHeight(h) end
    out[#out + 1] = t
  end
  r({ "TOPLEFT", -inset, inset }, { "TOPRIGHT", inset, inset }, nil, thick)
  r({ "BOTTOMLEFT", -inset, -inset }, { "BOTTOMRIGHT", inset, -inset }, nil, thick)
  r({ "TOPLEFT", -inset, inset }, { "BOTTOMLEFT", -inset, -inset }, thick, nil)
  r({ "TOPRIGHT", inset, inset }, { "BOTTOMRIGHT", inset, -inset }, thick, nil)
  return out
end

function EB.Create(parent)
  local b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
  b:SetSize(SIZE, SIZE)
  b:RegisterForClicks(useKeyDown() and "AnyDown" or "AnyUp")
  b:SetAttribute("type2", "") -- høyreklikk skal aldri kaste (SPEC §12.1)

  b.bg = Style.Rect(b, "BACKGROUND", 0, SIZE, SIZE, C.black, 1)
  b.icon = b:CreateTexture(nil, "ARTWORK", nil, 0)
  b.icon:SetPoint("TOPLEFT", 1, -1)
  b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  -- Tømming ovenfra: mørk flate med lys underkant
  b.drain = b:CreateTexture(nil, "ARTWORK", nil, 2)
  b.drain:SetColorTexture(8 / 255, 6 / 255, 4 / 255, 0.66)
  b.drain:SetPoint("TOPLEFT", b.icon, "TOPLEFT")
  b.drain:SetPoint("TOPRIGHT", b.icon, "TOPRIGHT")
  b.drain:SetHeight(1)
  b.drainEdge = b:CreateTexture(nil, "ARTWORK", nil, 3)
  b.drainEdge:SetColorTexture(1, 0.93, 0.67, 0.35)
  b.drainEdge:SetPoint("TOPLEFT", b.drain, "BOTTOMLEFT")
  b.drainEdge:SetPoint("TOPRIGHT", b.drain, "BOTTOMRIGHT")
  b.drainEdge:SetHeight(1)

  -- Bånd nederst («ikke på», «gått ut», «0/10»)
  b.band = b:CreateTexture(nil, "OVERLAY", nil, 0)
  b.band:SetColorTexture(0, 0, 0, 0.72)
  b.band:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMLEFT")
  b.band:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT")
  b.band:SetHeight(13)
  b.bandText = b:CreateFontString(nil, "OVERLAY")
  font(b.bandText, 10)
  b.bandText:SetPoint("CENTER", b.band, "CENTER", 0, 0)
  b.bandText:SetWordWrap(false)

  b.time = b:CreateFontString(nil, "OVERLAY")
  font(b.time, 12)
  b.time:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
  b.time:SetWordWrap(false)
  b.big = b:CreateFontString(nil, "OVERLAY")
  font(b.big, 16)
  b.big:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.big:SetWordWrap(false)
  b.stock = b:CreateFontString(nil, "OVERLAY")
  font(b.stock, 12)
  b.stock:SetPoint("TOPRIGHT", b, "TOPRIGHT", -2, -2)

  -- Mus over: tynn lys innerkant. Trykket: gyllent glimt.
  b.hoverEdge = edgeRects(b, "OVERLAY", 3, -1, 1, { 1, 236 / 255, 170 / 255 }, 0)
  b.flash = Style.Rect(b, "OVERLAY", 4, SIZE - 2, SIZE - 2, GLOW, 0)
  b.flash:SetBlendMode("ADD")
  b.flashAnim = b.flash:CreateAnimationGroup()
  local fa = b.flashAnim:CreateAnimation("Alpha")
  fa:SetFromAlpha(0.8)
  fa:SetToAlpha(0)
  fa:SetDuration(0.17)

  -- Glød: pulserende gull, 2,4 s syklus (innerkant + to ytre lag)
  b.glow = CreateFrame("Frame", nil, b)
  b.glow:SetAllPoints(b)
  edgeRects(b.glow, "OVERLAY", 5, 0, 2, GLOW, 1)
  edgeRects(b.glow, "BACKGROUND", -1, 3, 3, GLOW, 0.35)
  edgeRects(b.glow, "BACKGROUND", -2, 7, 4, GLOW, 0.15)
  b.glowAnim = b.glow:CreateAnimationGroup()
  b.glowAnim:SetLooping("BOUNCE")
  local ga = b.glowAnim:CreateAnimation("Alpha")
  ga:SetFromAlpha(0.3)
  ga:SetToAlpha(1)
  ga:SetDuration(1.2)
  ga:SetSmoothing("IN_OUT")
  -- Gløden skrus av og på med gjennomsiktighet, aldri Show/Hide: rammen henger under en sikker knapp,
  -- og vis/skjul kan være sperret i kamp.
  b.glow:SetAlpha(0)

  b:HookScript("PreClick", function(self, mouse)
    if mouse == "LeftButton" and self.entry then ns.Track.Pressed(self.entry) end
    self.flashAnim:Stop()
    self.flashAnim:Play()
  end)
  b:HookScript("OnEnter", function(self)
    for _, t in ipairs(self.hoverEdge) do t:SetAlpha(0.75) end
    EB.ShowTooltip(self)
  end)
  b:HookScript("OnLeave", function(self)
    for _, t in ipairs(self.hoverEdge) do t:SetAlpha(0) end
    GameTooltip:Hide()
  end)
  return b
end

-- Hva knappen gjør når den klikkes. Bare utenfor kamp (beskyttet).
function EB.Bind(b, e)
  b.entry = e
  if e.type == "spell" then
    b:SetAttribute("type", "spell")
    b:SetAttribute("spell", e.name) -- etter navn: kaster høyeste rank (fase 0, V5)
    b:SetAttribute("unit", "player")
    b:SetAttribute("item", nil)
  elseif e.type == "buffitem" then
    b:SetAttribute("type", "item")
    b:SetAttribute("item", "item:" .. e.itemId)
    b:SetAttribute("spell", nil)
    b:SetAttribute("unit", nil)
  else
    b:SetAttribute("type", nil) -- lagerting: vises bare
  end
  local icon
  if e.spellId then icon = select(2, ns.Scan.SpellInfo(e.spellId)) end
  if e.itemId then icon = ns.Scan.ItemIcon(e.itemId) end
  if icon then b.icon:SetTexture(icon) else b.icon:SetColorTexture(0.2, 0.2, 0.2, 1) end
end

-- Hvordan knappen ser ut nå. Ikke beskyttet: virker også i kamp.
function EB.Paint(b, e, st, L)
  st = st or {}
  b.entry, b.st = e, st
  local R = ns.Rules
  local status = st.status
  b.time:SetText("")
  b.big:SetText("")
  b.stock:SetText("")
  b.band:Hide()
  b.bandText:SetText("")
  local drain, grey, glow = 0, false, false

  if e.type == "item" then
    local count, want = st.count or 0, e.want or 1
    if count <= 0 then
      b.band:Show()
      b.bandText:SetText(R.stockText(count, want))
      grey = true
    else
      b.time:SetText(R.stockText(count, want))
    end
    drain = 1 - math.min(1, count / want)
  else
    if status == "on" then
      b.time:SetText(R.formatTime(st.left, L) or "")
      if st.left and st.left ~= math.huge and st.duration and st.duration > 0 then
        drain = 1 - math.max(0, math.min(1, st.left / st.duration))
      end
    elseif status == "expiring" then
      b.big:SetText(R.formatTime(st.left, L) or "")
      drain = 0.97
    else
      b.band:Show()
      b.bandText:SetText(status == "expired" and L.BTN_EXPIRED or L.BTN_MISSING)
      glow = R.canPress(e, st)
    end
    if e.type == "buffitem" then
      local count, want = st.count or 0, e.want or 1
      b.stock:SetText(R.stockText(count, want))
      if count <= 0 then
        grey = true
        b.stock:SetTextColor(C.help[1], C.help[2], C.help[3])
      else
        b.stock:SetTextColor(1, 1, 1)
      end
    end
  end

  b.drain:SetHeight(math.max(1, (SIZE - 2) * drain))
  b.drain:SetShown(drain > 0)
  b.drainEdge:SetShown(drain > 0 and drain < 1)
  b.icon:SetDesaturated(grey)
  b.icon:SetVertexColor(grey and 0.6 or 1, grey and 0.6 or 1, grey and 0.6 or 1)
  if glow and not b.glowing then
    b.glow:SetAlpha(1)
    b.glowAnim:Play()
  elseif not glow and b.glowing then
    b.glowAnim:Stop()
    b.glow:SetAlpha(0)
  end
  b.glowing = glow
  if GameTooltip:IsOwned(b) then EB.ShowTooltip(b) end
end

------------------------------------------------------------------------
-- Tooltip (SPEC §7.7)
------------------------------------------------------------------------

function EB.ShowTooltip(b)
  local e, st, L = b.entry, b.st or {}, ns.L
  if not e then return end
  local R = ns.Rules
  GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
  GameTooltip:SetText(e.type == "buffitem" and (e.auraNames and e.auraNames[1] or e.name) or e.name, 1, 1, 1)
  local line, action, actColor = "", "", C.green
  if e.type == "item" then
    line = string.format(L.TIP_HAVE, st.count or 0, e.want or 1)
    local s = R.stockSeverity(e, st)
    action = s == 2 and L.TIP_STOCK_EMPTY or s == 1 and L.TIP_STOCK_LOW or L.TIP_STOCK_OK
    actColor = C.help
  else
    if st.status == "expired" then line = L.TIP_EXPIRED
    elseif st.status == "missing" or not st.status then line = L.TIP_MISSING
    elseif st.status == "expiring" then line = string.format(L.TIP_EXPIRING, R.formatTime(st.left, L) or "")
    else line = st.left == math.huge and L.TIP_ON or string.format(L.TIP_LEFT, R.formatTime(st.left, L) or "") end
    if e.type == "buffitem" then
      line = line .. string.format(L.TIP_IN_BAG, st.count or 0, e.want or 1)
      if (st.count or 0) > 0 then
        action = string.format(L.TIP_USE, e.name or "")
      else
        action, actColor = L.TIP_NONE_IN_BAG, C.help
      end
    else
      action = L.TIP_CAST_SELF
    end
  end
  GameTooltip:AddLine(line, 1, 1, 1)
  GameTooltip:AddLine(action, actColor[1], actColor[2], actColor[3])
  GameTooltip:Show()
end
