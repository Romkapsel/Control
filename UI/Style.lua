-- Control: farger, skrift og byggeklosser for tegning (SPEC §13).
-- Det runde og skrå (medaljongen, symbolene, pilene, sverdene) er ferdige bilder i Media/ med glatte kanter
-- (fase 9, Daniel: «mye fremstår pixelet»), tegnet av tools/render_media.py og tools/sword_render.py.
-- Rammer og knapper er rette fargeflater. En ukjent teksturbane krasjer beta-klienten (ASSERT fileDataID,
-- 1. okt 2026): spillets egne filer brukes ikke, og tests/run.py sjekker at hvert bilde vi ber om, finnes.
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

-- Våre egne bilder: Interface/AddOns/<mappa>/Media/<navn>(.tga)
function Style.Media(name)
  return "Interface\\AddOns\\" .. addonName .. "\\Media\\" .. name
end

-- Et bilde fra Media/, w × h, sentrert (x, y) i parent. Hvite bilder farges med Style.Tint.
function Style.Image(parent, name, w, h, layer, sub, x, y)
  local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
  t:SetTexture(Style.Media(name))
  t:SetSize(w, h)
  t:SetPoint("CENTER", parent, "CENTER", x or 0, y or 0)
  t.isImage = true
  return t
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

-- En strek på nøyaktig én skjermpiksel, på hel piksel (Daniel 5. okt: én skillestrek så tykkere ut enn de andre –
-- 1 enhet ble 1 eller 2 piksler alt etter hvor den havnet). PixelUtil er Blizzards egen avrunding.
function Style.HairlineAt(t, point, rel, relPoint, x, y)
  t:SetHeight(Style.OnePixel(rel))
  t:ClearAllPoints()
  if PixelUtil and PixelUtil.SetPoint then
    PixelUtil.SetPoint(t, point, rel, relPoint, x, y)
  else
    t:SetPoint(point, rel, relPoint, x, y)
  end
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
  -- Pila er et bilde (glatte kanter): chevron_h peker til venstre, chevron_v opp; de andre er speilvendt
  local horizontal = dir == "left" or dir == "right"
  local t = Style.Image(b, horizontal and "chevron_h" or "chevron_v", 12, 12, "OVERLAY", 1)
  if dir == "right" then t:SetTexCoord(1, 0, 0, 1) elseif dir == "down" then t:SetTexCoord(0, 1, 1, 0) end
  b.parts = { t }
  Style.Tint(b.parts, Style.C.goldDim)
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
-- Farge på flater og (hvite) bilder. Et bilde farges med SetVertexColor – SetColorTexture ville byttet det ut.
function Style.Tint(parts, color, alpha)
  for _, p in ipairs(parts) do
    if p.isImage then
      p:SetVertexColor(color[1], color[2], color[3])
      if alpha then p:SetAlpha(alpha) end
    else
      p:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    end
  end
end
