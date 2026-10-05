-- Control: snart ute (SPEC §11 nivå 2, Daniel 5. okt). Når en buff du hadde har 40 s igjen, står et lite ikon
-- med nedtelling over figuren din, midt på skjermen. Ingen lyd, ingen mus. Forsvinner når du fornyer
-- (eller når buffen er gått ut – da viser medaljongen den som manglende).
-- Ikke sikre rammer: kan vises og skjules også i kamp, der nedtellingen fortsetter fra det vi visste.
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local X = {}
ns.Expiry = X

local SIZE, GAP, MAX = 36, 8, 4
local NUM_FONT = "Fonts\\ARIALN.TTF"
local f
local icons = {}

local function build()
  f = CreateFrame("Frame", nil, UIParent)
  f:SetSize(1, 1)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 90)
  f:SetFrameStrata("HIGH")
  f:EnableMouse(false)
  X.frame = f
end

local function icon(i)
  local it = icons[i]
  if it then return it end
  it = CreateFrame("Frame", nil, f)
  it:SetSize(SIZE, SIZE)
  it:EnableMouse(false)
  it.edge = Style.Rect(it, "BACKGROUND", 0, SIZE + 4, SIZE + 4, C.orange, 1)
  it.inner = Style.Rect(it, "BACKGROUND", 1, SIZE + 2, SIZE + 2, C.black, 1)
  it.icon = it:CreateTexture(nil, "ARTWORK")
  it.icon:SetAllPoints()
  it.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  it.shade = it:CreateTexture(nil, "ARTWORK", nil, 1)
  it.shade:SetAllPoints()
  it.shade:SetColorTexture(0, 0, 0, 0.35)
  it.time = it:CreateFontString(nil, "OVERLAY")
  if not it.time:SetFont(NUM_FONT, 16, "OUTLINE") then it.time:SetFontObject(NumberFontNormal) end
  it.time:SetPoint("CENTER", it, "CENTER", 0, 0)
  it.time:SetTextColor(1, 1, 1)
  icons[i] = it
  return it
end

local function iconOf(e)
  if e.itemId then return ns.Scan.ItemIcon(e.itemId) end
  if e.spellId then return select(2, ns.Scan.SpellInfo(e.spellId)) end
end

-- list = Rules.expiring(...)
function X.Update(list, L)
  if not f then build() end
  local n = math.min(#list, MAX)
  local total = n * SIZE + math.max(0, n - 1) * GAP
  for i = 1, n do
    local it, e = icon(i), list[i].e
    local tex = iconOf(e)
    if tex then it.icon:SetTexture(tex) else it.icon:SetColorTexture(0.2, 0.2, 0.2, 1) end
    it.time:SetText(ns.Rules.formatTime(list[i].left, L) or "")
    it.entry = e
    it:ClearAllPoints()
    it:SetPoint("CENTER", f, "CENTER", -total / 2 + (i - 1) * (SIZE + GAP) + SIZE / 2, 0)
    it:Show()
  end
  for i = n + 1, #icons do icons[i]:Hide() end
  X.shown = n
end

function X.Icons() return icons end
