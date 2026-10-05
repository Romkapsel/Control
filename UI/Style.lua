-- Control: farger, skrift og byggeklosser for tegning (SPEC §13).
-- Medaljongen tegnes med fargeflater, gradienter og streker. Den eneste teksturen er den runde masken, og den
-- sjekkes før bruk: en ukjent teksturbane krasjer beta-klienten (ASSERT fileDataID, 1. okt 2026).
local addonName, ns = ...

local Style = {}
ns.Style = Style

local function hex(h, a)
  return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255, a or 1 }
end
Style.hex = hex

Style.C = {
  red = hex("FF2020"),
  orange = hex("FF8C1A"),
  green = hex("40BF40"),
  gold = hex("FFD100"),
  goldLight = hex("FFF3B0"),
  goldDim = hex("C9A24A"),
  text = hex("ECE6D8"),
  help = hex("A0A0A0"),
  black = hex("000000"),
  bronzeLight = hex("F0CF86"),
  bronzeMid = hex("B58A40"),
  bronzeDark = hex("6A4A1C"),
  coreHi = hex("3B2F22"),
  core = hex("17110C"),
  coreLo = hex("0B0806"),
}

-- Ringfarge per alvorlighet (SPEC §6.5): 2 rød, 1 oransje, 0 svart (ingen lys).
Style.RING = { [0] = Style.C.black, [1] = Style.C.orange, [2] = Style.C.red }
Style.GLOW_ALPHA = { [0] = 0, [1] = 0.65, [2] = 0.70 }

Style.FONT_HEAD = "Fonts\\FRIZQT__.TTF"

------------------------------------------------------------------------
-- Rund maske: atlas hvis klienten har det, ellers fil hvis den finnes, ellers firkanter (virker, men kantete)
------------------------------------------------------------------------

local MASK_ATLAS = "CircleMaskScalable"
local MASK_FILE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

function Style.FileExists(path)
  if not GetFileIDFromPath then return false end
  local ok, id = pcall(GetFileIDFromPath, path)
  return ok and id ~= nil
end

function Style.AtlasExists(name)
  if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
  local ok, info = pcall(C_Texture.GetAtlasInfo, name)
  return ok and info ~= nil
end

local maskMode
function Style.MaskMode()
  if maskMode == nil then
    if Style.AtlasExists(MASK_ATLAS) then maskMode = "atlas"
    elseif Style.FileExists(MASK_FILE) then maskMode = "file"
    else maskMode = false end
  end
  return maskMode
end

function Style.Round(tex, parent)
  local mode = Style.MaskMode()
  if not mode or not parent.CreateMaskTexture then return end
  local m = parent:CreateMaskTexture()
  if mode == "atlas" then
    m:SetAtlas(MASK_ATLAS, false)
  else
    m:SetTexture(MASK_FILE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  end
  m:SetAllPoints(tex)
  tex:AddMaskTexture(m)
end

-- En rund fargeflate med midten i (x, y) fra forelderens midte.
function Style.Disc(parent, layer, sub, size, color, alpha, x, y)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetSize(size, size)
  t:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
  t:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
  Style.Round(t, parent)
  return t
end

-- Loddrett gradient (bunn → topp). Klienter uten SetGradient(ColorMixin) får midtfargen.
function Style.Gradient(t, bottom, top, mid)
  local ok = CreateColor and pcall(t.SetGradient, t, "VERTICAL",
    CreateColor(bottom[1], bottom[2], bottom[3], 1), CreateColor(top[1], top[2], top[3], 1))
  if not ok and mid then t:SetColorTexture(mid[1], mid[2], mid[3], 1) end
end

function Style.Rect(parent, layer, sub, w, h, color, alpha, x, y)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetSize(w, h)
  t:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
  t:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
  return t
end

function Style.Line(parent, layer, sub, x1, y1, x2, y2, thickness, color, alpha)
  local l = parent:CreateLine(nil, layer, nil, sub)
  l:SetThickness(thickness)
  l:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
  l:SetStartPoint("CENTER", parent, x1, y1)
  l:SetEndPoint("CENTER", parent, x2, y2)
  return l
end

-- Rammen rundt knappene ved medaljongen og sidemenyene (SPEC §13.2): 1 px svart, 2 px bronse og 1 px svart,
-- lik hele veien rundt (Daniel 4. okt: bunnen og siden skal se ut som toppen), og mørk brun bakgrunn innenfor.
-- Kanten måles i skjermpiksler, ikke UI-enheter: med UI-skala ble en 1-enhets strek noen ganger 2 piksler
-- (toppen så tykkere ut). PixelUtil er Blizzards egen omregning; uten den brukes 1 enhet.
Style.FRAME_EDGE = 4
function Style.OnePixel(f)
  if PixelUtil and PixelUtil.GetPixelToUIUnitFactor then
    local ok, s = pcall(f.GetEffectiveScale, f)
    if ok and s and s > 0 then return PixelUtil.GetPixelToUIUnitFactor() / s end
  end
  return 1
end

-- Liten lukke-pil i hjørnet (Daniel 5. okt): en sikker knapp, så den virker også i kamp. dir = retningen pila
-- peker (mot medaljongen): "left", "right", "up", "down". snippet = det sikre skriptet (_onclick).
-- onAfter() kalles etter klikket (Lua: tegn på nytt).
function Style.CloseArrow(parent, dir, snippet, tip, onAfter)
  local b = CreateFrame("Button", nil, parent, "SecureHandlerClickTemplate")
  b:SetSize(18, 18)
  b:RegisterForClicks("LeftButtonUp")
  b:SetAttribute("_onclick", snippet)
  b:SetFrameLevel(parent:GetFrameLevel() + 5)
  local pts = ({
    left = { { 2, -4 }, { -2, 0 }, { 2, 4 } },
    right = { { -2, -4 }, { 2, 0 }, { -2, 4 } },
    up = { { -4, -2 }, { 0, 2 }, { 4, -2 } },
    down = { { -4, 2 }, { 0, -2 }, { 4, 2 } },
  })[dir]
  b.parts = {
    Style.Line(b, "OVERLAY", 1, pts[1][1], pts[1][2], pts[2][1], pts[2][2], 2, Style.C.goldDim),
    Style.Line(b, "OVERLAY", 1, pts[2][1], pts[2][2], pts[3][1], pts[3][2], 2, Style.C.goldDim),
    Style.Disc(b, "OVERLAY", 2, 2, Style.C.goldDim, 1, pts[2][1], pts[2][2]), -- rund spiss
  }
  b:SetScript("OnEnter", function(self)
    Style.Tint(self.parts, Style.C.goldLight)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(tip or "", 1, 1, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function(self) Style.Tint(self.parts, Style.C.goldDim) GameTooltip:Hide() end)
  b:HookScript("PostClick", function() GameTooltip:Hide() if onAfter then onAfter() end end)
  return b
end

function Style.Frame(f)
  local p = Style.OnePixel(f)
  local bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
  bg:SetPoint("TOPLEFT", 4 * p, -4 * p)
  bg:SetPoint("BOTTOMRIGHT", -4 * p, 4 * p)
  bg:SetColorTexture(1, 1, 1, 1) -- helt tett: ingenting skal skinne gjennom
  Style.Gradient(bg, hex("130E0A"), hex("201812"), hex("1A140F"))
  local function ring(inset, thick, color, sub)
    inset, thick = inset * p, thick * p
    local function edge(p1, x1, y1, p2, x2, y2, w, h)
      local t = f:CreateTexture(nil, "BORDER", nil, sub)
      t:SetColorTexture(color[1], color[2], color[3], 1)
      t:SetPoint(p1, f, p1, x1, y1)
      t:SetPoint(p2, f, p2, x2, y2)
      if w then t:SetWidth(w) end
      if h then t:SetHeight(h) end
    end
    edge("TOPLEFT", inset, -inset, "TOPRIGHT", -inset, -inset, nil, thick)
    edge("BOTTOMLEFT", inset, inset, "BOTTOMRIGHT", -inset, inset, nil, thick)
    edge("TOPLEFT", inset, -inset, "BOTTOMLEFT", inset, inset, thick, nil)
    edge("TOPRIGHT", -inset, -inset, "BOTTOMRIGHT", -inset, inset, thick, nil)
  end
  ring(0, 1, Style.C.black, 0)
  ring(1, 2, hex("8A6A36"), 1)
  ring(3, 1, Style.C.black, 2)
end

-- Gjør alle tegnede deler i en ramme samme farge (symbolene skifter mellom gull og lys gull).
function Style.Tint(parts, color, alpha)
  for _, p in ipairs(parts) do p:SetColorTexture(color[1], color[2], color[3], alpha or 1) end
end
