-- Control: varsel midt på skjermen (SPEC §11, nivå 3 – øyeblikk du ikke kan angre, som byvakt).
-- Én linje: rød + én lyd når noe er tomt (eller mangler i tier I), oransje uten lyd når noe er under ønsket,
-- kort grønn «Alt med» som tones ut. Over linja, i grått og mindre: hvor du drar fra.
-- Ingen mus: varselet stjeler aldri et klikk. Står i samme bronseramme som menyen, så det ikke drukner i alt
-- rundt (Daniel 5. okt); fargen ligger i teksten. Ramma følger teksten i bredden.
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local Alert = {}
ns.Alert = Alert

local HOLD = { [0] = 2, [1] = 6, [2] = 8 } -- sekunder før det tones ut
local FADE = 1.2
local SEVC = { [0] = C.green, [1] = C.orange, [2] = C.red }

local f, title, main
local shownAt, hold

local function hexOf(c) return string.format("%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255) end
local function colored(text, c) return "|cff" .. hexOf(c) .. text .. "|r" end

local PADX, MINW, HEIGHT = 28, 240, 76

local function width(fs)
  local ok, w = pcall(fs.GetStringWidth, fs)
  if not ok or type(w) ~= "number" or w <= 0 then w = #(fs:GetText() or "") * 7 end
  return w
end

local function build()
  f = CreateFrame("Frame", nil, UIParent)
  f:SetSize(MINW, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
  f:SetFrameStrata("HIGH")
  f:EnableMouse(false)
  Style.Frame(f)
  title = f:CreateFontString(nil, "OVERLAY")
  if not title:SetFont(Style.FONT_HEAD, 13, "") then title:SetFontObject(GameFontNormal) end
  title:SetPoint("TOP", f, "TOP", 0, -16)
  title:SetTextColor(C.help[1], C.help[2], C.help[3])
  title:SetShadowColor(0, 0, 0, 1)
  title:SetShadowOffset(1, -1)
  main = f:CreateFontString(nil, "OVERLAY")
  if not main:SetFont(Style.FONT_HEAD, 22, "OUTLINE") then main:SetFontObject(GameFontNormalHuge) end
  main:SetPoint("TOP", title, "BOTTOM", 0, -8)
  main:SetWordWrap(false)
  f:SetScript("OnUpdate", function(self)
    local t = GetTime() - shownAt
    if t < hold then self:SetAlpha(1) return end
    local a = 1 - (t - hold) / FADE
    if a <= 0 then self:Hide() return end
    self:SetAlpha(a)
  end)
  f:Hide()
  Alert.frame, Alert.title, Alert.main = f, title, main
end

-- «Watch it!» med grov dvergestemme (Daniel 5. okt): sound/creature/dwarfmalegrimnpc/dwarfmalegrimnpcpissed01.ogg,
-- fil-ID fra spillets filliste og bekreftet ved å transkribere selve lydfila. Kan den ikke spilles: vanlig varsellyd.
Alert.VOICE = 547866
local function playSound()
  local ok, willPlay = pcall(PlaySoundFile, Alert.VOICE, "Master")
  if ok and willPlay then return end
  pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master")
end

-- where = «Du forlater Stormwind City», d = Rules.departure(...)
function Alert.Show(where, d, quiet)
  if not f then build() end
  title:SetText(where or "")
  local text
  if d.sev == 0 then
    text = colored(d.text, C.green)
  else
    local parts = {}
    for _, p in ipairs(d.parts or {}) do
      local t = colored(p.name, SEVC[p.nameSev] or C.text)
      if p.stock then t = t .. " " .. colored(p.stock, SEVC[p.stockSev] or C.text) end
      parts[#parts + 1] = t
    end
    if (d.more or 0) > 0 then parts[#parts + 1] = colored("+" .. d.more, C.help) end
    text = table.concat(parts, colored(ns.L.SEP, C.help))
  end
  main:SetText(text)
  f:SetWidth(math.max(MINW, math.ceil(math.max(width(title), width(main))) + 2 * PADX))
  Alert.sev = d.sev
  shownAt, hold = GetTime(), HOLD[d.sev] or 4
  f:SetAlpha(1)
  f:Show()
  if d.sev == 2 and not quiet then -- bytte sett: ingen «Watch it!», du står ikke ved porten
    playSound()
    Alert.sounds = (Alert.sounds or 0) + 1
  end
end

------------------------------------------------------------------------
-- Stort varsel midt på skjermen (Daniel 7. okt – kompisen: «det må være in your face»). Når en «Må ha»-buff har
-- 10 sekunder igjen (en shout, en flask …), lyser ikonet opp stort midt på skjermen med navnet og sekundene som
-- teller ned, og en lyd én gang. Borte når buffen er fornyet eller har gått ut. Av/på under Oppsett (av som standard).
-- Ingen mus: stjeler aldri et klikk. I kamp teller den fra det Control vet (buffene er hemmelige der).
------------------------------------------------------------------------

Alert.BIG_AT = 10
local BIG = 72
local big
local soundFor -- id-en det er spilt lyd for i denne runden

local function buildBig()
  big = CreateFrame("Frame", nil, UIParent)
  big:SetSize(BIG + 40, BIG + 40)
  big:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  big:SetFrameStrata("HIGH")
  big:EnableMouse(false)
  big.glow = Style.Image(big, "glow_btn", BIG * 2, BIG * 2, "BACKGROUND", 0)
  big.glow:SetVertexColor(C.gold[1], C.gold[2], C.gold[3])
  big.edge = Style.Rect(big, "BORDER", 0, BIG + 4, BIG + 4, C.gold, 1)
  big.icon = big:CreateTexture(nil, "ARTWORK")
  big.icon:SetSize(BIG, BIG)
  big.icon:SetPoint("CENTER")
  big.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- Tallet i en egen ramme, så det kan sprette (vokse og falle på plass) hvert sekund
  big.timeFrame = CreateFrame("Frame", nil, big)
  big.timeFrame:SetSize(BIG, BIG)
  big.timeFrame:SetPoint("CENTER", big.icon, "CENTER", 0, 0)
  big.timeFrame:SetFrameLevel(big:GetFrameLevel() + 2)
  big.time = big.timeFrame:CreateFontString(nil, "OVERLAY")
  if not big.time:SetFont(Style.FONT_HEAD, 40, "OUTLINE") then big.time:SetFontObject(GameFontNormalHuge) end
  big.time:SetPoint("CENTER", big.timeFrame, "CENTER", 0, 0)
  big.time:SetTextColor(1, 1, 1)
  big.name = big:CreateFontString(nil, "OVERLAY")
  if not big.name:SetFont(Style.FONT_HEAD, 18, "OUTLINE") then big.name:SetFontObject(GameFontNormalLarge) end
  big.name:SetPoint("TOP", big.icon, "BOTTOM", 0, -10)
  big.name:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
  -- Pulserer: gløden puster, og ikonet vokser litt i takt
  big:SetScript("OnUpdate", function(self)
    local now = GetTime() or 0
    local p = 0.5 + 0.5 * math.sin(now * 6)
    self.glow:SetAlpha(0.35 + 0.65 * p)
    self.icon:SetSize(BIG * (1 + 0.06 * p), BIG * (1 + 0.06 * p))
    local k = math.min(1, (now - (self.popAt or 0)) / 0.3) -- nytt sekund: tallet starter stort og faller på plass
    self.timeFrame:SetScale(1 + 0.7 * (1 - k) * (1 - k))
  end)
  big:Hide()
  Alert.big = big
end

-- e = oppføringen (nil = ingen), left = sekunder igjen, icon = ikonet, gone = buffen forsvant før tiden («Borte!»)
function Alert.Big(e, left, icon, gone)
  if not e then
    if big then big:Hide() end
    soundFor = nil
    return
  end
  if not big then buildBig() end
  if icon then big.icon:SetTexture(icon) else big.icon:SetColorTexture(0.2, 0.2, 0.2, 1) end
  big.icon:SetDesaturated(gone and true or false)
  local c = gone and C.red or C.gold
  big.glow:SetVertexColor(c[1], c[2], c[3])
  big.edge:SetColorTexture(c[1], c[2], c[3], 1)
  local txt = gone and "!" or tostring(math.max(1, math.ceil(left or 0)))
  if txt ~= big.time:GetText() then
    big.time:SetText(txt)
    big.popAt = GetTime() or 0
  end
  big.time:SetTextColor(gone and C.red[1] or 1, gone and C.red[2] or 1, gone and C.red[3] or 1)
  big.name:SetText(gone and string.format(ns.L.BIG_GONE, e.name or e.short or "") or (e.name or e.short or ""))
  big.entry, big.gone = e, gone and true or false
  big:Show()
  local key = e.id .. (gone and ":borte" or "")
  if soundFor ~= key then
    soundFor = key
    pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master")
    Alert.bigSounds = (Alert.bigSounds or 0) + 1
  end
end
