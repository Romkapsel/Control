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

-- Gjør alle tegnede deler i en ramme samme farge (symbolene skifter mellom gull og lys gull).
function Style.Tint(parts, color, alpha)
  for _, p in ipairs(parts) do p:SetColorTexture(color[1], color[2], color[3], alpha or 1) end
end
