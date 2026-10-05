-- Control: medaljongen (SPEC §7.1, §7.2, §7.8). 64 px, tall og statusring, fire soner og et grep i midten.
-- Ingen sikre rammer her: tall, ring og hover virker alltid, også i kamp. Flytting er likevel av i kamp,
-- fordi knappene ved siden av (fase 3) er sikre og henger på samme ramme.
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local M = {}
ns.Medallion = M

local SIZE = 64
local HUB_R = 11      -- midten (22 px)
local OUTER_R = 33    -- utenfor ringen teller ikke
local SYM_OFFSET = 17 -- lås og meny ut mot kanten av kjernen
local SYM_SIDE = 15   -- hodene litt innenfor: de er bredere enn de er høye
local DOT_R = 29      -- lysprikken på bronsekanten, utenfor symbolene
local ZONE_ANGLE = { up = 90, right = 0, down = -90, left = 180 }

------------------------------------------------------------------------
-- Sone fra vinkel og avstand (SPEC §7.2). dx, dy fra midten, y oppover.
------------------------------------------------------------------------

function M.ZoneAt(dx, dy)
  local d2 = dx * dx + dy * dy
  if d2 < HUB_R * HUB_R then return "hub" end
  if d2 > OUTER_R * OUTER_R then return nil end
  if math.abs(dx) > math.abs(dy) then return dx > 0 and "right" or "left" end
  return dy > 0 and "up" or "down"
end

------------------------------------------------------------------------
-- Animasjon: én OnUpdate, bare mens noe beveger seg
------------------------------------------------------------------------

local root, face, hit
local animFrame, trackFrame -- frie rammer (ikke forankret til noe sikkert): OnUpdate kan slås av og på også i kamp
local swordFrame, swords, swordFlash
local buildSwords
local anim = {}   -- key → { cur, from, to, t, dur }
local applyAll

local function ease(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2 end

local function step(_, elapsed)
  local busy = false
  for _, a in pairs(anim) do
    if a.t < 1 then
      a.t = math.min(1, a.t + elapsed / a.dur)
      a.cur = a.from + (a.to - a.from) * ease(a.t)
      if a.t < 1 then busy = true end
    end
  end
  applyAll()
  if not busy then animFrame:SetScript("OnUpdate", nil) end
end

local function animate(key, to, dur, instant)
  local a = anim[key]
  if not a then
    a = { cur = to, from = to, to = to, t = 1, dur = dur }
    anim[key] = a
  end
  if key == "angle" and not instant then -- korteste vei rundt ringen
    while to - a.cur > 180 do to = to - 360 end
    while a.cur - to > 180 do to = to + 360 end
  end
  if a.to == to and a.t >= 1 then return end
  if instant then
    a.cur, a.from, a.to, a.t = to, to, to, 1
  else
    a.from, a.to, a.t, a.dur = a.cur, to, 0, dur
    animFrame:SetScript("OnUpdate", step)
  end
end

local function v(key, default)
  local a = anim[key]
  if a then return a.cur end
  return default
end

------------------------------------------------------------------------
-- Symbolene (tegnet med streker og flater, ingen teksturer)
------------------------------------------------------------------------

local function symbolFrame(parent, x, y)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(18, 18)
  f.baseX, f.baseY = x, y
  f:SetPoint("CENTER", parent, "CENTER", x, y)
  f.parts = {}
  return f
end

local function add(f, p)
  f.parts[#f.parts + 1] = p
  return p
end

-- Strekene i symbolene: spillet glatter ikke kantene på streker, så en tykkelse mellom to piksler blir ujevn
-- (synlig når medaljongen er større, Daniel 5. okt). Vi husker grunntykkelsen og runder den til hele
-- skjermpiksler for størrelsen som gjelder (M.Resnap).
local lines = {}
local function line(parent, layer, sub, x1, y1, x2, y2, t, c, a)
  local l = Style.Line(parent, layer, sub, x1, y1, x2, y2, t, c, a)
  lines[#lines + 1] = { l = l, t = t }
  return l
end

-- Symbolene er tynne konturer som i designet (SPEC §7.1), ikke fylte flater.
local STROKE = 1.3

local function joint(f, x, y, t, c, sub)
  add(f, Style.Disc(f, "OVERLAY", sub or 2, t, c, 1, x, y))
end

local function polyline(f, pts, t, c)
  for i = 2, #pts do
    add(f, line(f, "OVERLAY", 2, pts[i - 1][1], pts[i - 1][2], pts[i][1], pts[i][2], t, c))
    if i < #pts then joint(f, pts[i][1], pts[i][2], t, c) end -- knekkpunkt: rundt, ikke hakk
  end
end

local function drawLock(f, s, open)
  local c, t = C.goldDim, STROKE * s
  local w, h, by = 4.5 * s, 3.5 * s, -2.2 * s -- kroppen: halv bredde, halv høyde, midtpunkt
  polyline(f, { { -w, by - h }, { w, by - h }, { w, by + h }, { -w, by + h }, { -w, by - h } }, t, c)
  local lift = open and 1.6 * s or 0
  local sx, top, r = 2.8 * s, 5.6 * s + lift, 1.3 * s
  local right = open and { sx, top - 2.6 * s } or { sx, by + h }
  polyline(f, { { -sx, by + h }, { -sx, top - r }, { -sx + r, top }, { sx - r, top }, { sx, top - r }, right }, t, c)
  add(f, Style.Disc(f, "OVERLAY", 2, 1.8 * s, c, 1, 0, by)) -- nøkkelhull
end

local function drawMenu(f)
  for _, y in ipairs({ 3.5, 0, -3.5 }) do
    add(f, line(f, "OVERLAY", 2, -4.5, y, 4.5, y, STROKE, C.goldDim))
  end
end

-- Hode som ring og skuldre som bue. Det indre av hodet har kjernens farge og farges ikke ved mus over.
-- Kompakt (ca. 8 × 11 px), så symbolet holder seg inne i kjernen også når det vokser 25 %.
local function drawPerson(f, x, s)
  local c, t = C.goldDim, STROKE
  add(f, Style.Disc(f, "OVERLAY", 2, 5.4 * s, c, 1, x, 2.6 * s))
  Style.Disc(f, "OVERLAY", 3, 5.4 * s - 2 * t, C.core, 1, x, 2.6 * s)
  local pts = {}
  for i = 0, 6 do
    local a = math.pi * i / 6
    pts[#pts + 1] = { x + 4 * s * math.cos(a), -5.2 * s + 3.6 * s * math.sin(a) }
  end
  polyline(f, pts, t, c)
end

local function drawOne(f) drawPerson(f, 0, 1) end
local function drawTwo(f) drawPerson(f, 2.4, 0.78) drawPerson(f, -2.2, 0.78) end

local function drawCheck(f)
  add(f, line(f, "OVERLAY", 3, -7, 1, -2, -5, 3, C.goldDim))
  add(f, line(f, "OVERLAY", 3, -2, -5, 8, 6, 3, C.goldDim))
  joint(f, -2, -5, 3, C.goldDim, 3) -- bunnen av haken: rund
end

local function drawMove(f)
  local c = C.goldLight
  add(f, Style.Disc(f, "OVERLAY", 1, 22, c, 0.45))
  add(f, Style.Disc(f, "OVERLAY", 2, 19, C.core, 1))
  add(f, line(f, "OVERLAY", 3, -7, 0, 7, 0, 1.6, c))
  add(f, line(f, "OVERLAY", 3, 0, -7, 0, 7, 1.6, c))
  for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do -- pilspisser
    local tx, ty = 7 * d[1], 7 * d[2]
    local px, py = -d[2] * 2.5, d[1] * 2.5
    add(f, line(f, "OVERLAY", 3, tx, ty, tx - 2.5 * d[1] + px, ty - 2.5 * d[2] + py, 1.4, c))
    add(f, line(f, "OVERLAY", 3, tx, ty, tx - 2.5 * d[1] - px, ty - 2.5 * d[2] - py, 1.4, c))
  end
end

------------------------------------------------------------------------
-- Bygging
------------------------------------------------------------------------

local db, L
local parts = {}
local sym = {}
local hover
local view = { count = 0, ring = 0, allOk = true, empty = true }

local function partyLeft() return db.ui.partySide ~= "right" end

------------------------------------------------------------------------
-- I kamp (sikkert skript): klikk på en sone åpner/lukker sidemenyen eller menyen. self = klikkflaten.
-- Sonen regnes ut fra musa (GetMousePosition: 0–1 over flaten) i medaljongens egne enheter (64 px).
-- Sidemenyen dekker knappene ved medaljongen på sin side; de kommer tilbake når den lukkes (ks-want).
-- Restricted Lua: ingen funksjoner, ingen math-bibliotek.
------------------------------------------------------------------------

M.TOGGLE = [[
  if button ~= "LeftButton" or SecureCmdOptionParse("[combat] k; u") ~= "k" then return end
  if not self.GetMousePosition then return end -- finnes ikke i denne klienten: gjør ingenting heller enn å feile
  local x, y = self:GetMousePosition()
  if not x or not y then return end
  local dx, dy = (x - 0.5) * 64, (y - 0.5) * 64
  local d2 = dx * dx + dy * dy
  if d2 < 121 or d2 > 1089 then return end
  local ax, ay = dx, dy
  if ax < 0 then ax = -ax end
  if ay < 0 then ay = -ay end
  local zone
  if ax > ay then
    if dx > 0 then zone = "right" else zone = "left" end
  elseif dy < 0 then
    zone = "down"
  else
    return
  end
  if zone == "down" then
    local m = self:GetFrameRef("menu")
    if m then
      if m:IsShown() then m:Hide() else m:Show() end
    end
    return
  end
  local sb, tr = self:GetFrameRef("sb" .. zone), self:GetFrameRef("tr" .. zone)
  if not sb then return end
  if sb:IsShown() then
    sb:Hide()
    if tr and tr:GetAttribute("ks-want") then tr:Show() end
  else
    sb:Show()
    if tr then tr:Hide() end
  end
]]

------------------------------------------------------------------------
-- Kampsymbol (Daniel 5. okt): to sverd skyter ned og låses i kryss bak medaljongen, «sword and board».
-- Tegnet med streker og flater (ingen teksturer), med svart omriss. Bak medaljongen: egen ramme under ansiktet.
------------------------------------------------------------------------

local STEEL, STEEL_LIGHT, LEATHER = Style.hex("B8BFCB"), Style.hex("EEF1F6"), Style.hex("5C3A21")

local function sword(parent, ux, uy)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(SIZE, SIZE)
  f:SetPoint("CENTER")
  f.ux, f.uy = ux, uy
  local px, py = -uy, ux
  local function P(a, b) return a * ux + b * px, a * uy + b * py end -- a langs bladet, b på tvers
  local function seg(a1, b1, a2, b2, t, c, sub, alpha)
    local x1, y1 = P(a1, b1)
    local x2, y2 = P(a2, b2)
    return line(f, "ARTWORK", sub, x1, y1, x2, y2, t, c, alpha)
  end
  local hx, hy = P(-45, 0)
  -- Myk kant: spillet glatter ikke skrå streker (trappetrinn). En bredere, svak skygge under omrisset
  -- demper trinnene (Daniel 5. okt: «litt pixelerte»).
  local SOFT = 0.3
  seg(-30, 0, 51, 0, 9, C.black, -1, SOFT)
  seg(48, 0, 57, 0, 6, C.black, -1, SOFT)
  seg(-31, -10.5, -31, 10.5, 7, C.black, -1, SOFT)
  seg(-31, 0, -43, 0, 7, C.black, -1, SOFT)
  Style.Disc(f, "ARTWORK", -1, 10, C.black, SOFT, hx, hy)
  -- omriss
  seg(-30, 0, 51, 0, 7, C.black, 0)
  seg(48, 0, 56, 0, 4, C.black, 0)
  seg(-31, -9.5, -31, 9.5, 5, C.black, 0)
  seg(-31, 0, -42, 0, 5, C.black, 0)
  Style.Disc(f, "ARTWORK", 0, 8, C.black, 1, hx, hy)
  -- blad med lys rygg og spiss (litt kraftigere)
  seg(-30, 0, 50, 0, 5, STEEL, 1)
  seg(-28, 0, 47, 0, 1, STEEL_LIGHT, 2)
  seg(48, 0, 55, 0, 2, STEEL, 1)
  -- parerstang, grep, knapp
  seg(-31, -8.5, -31, 8.5, 3, C.gold, 1)
  seg(-32, 0, -41, 0, 3, LEATHER, 1)
  Style.Disc(f, "ARTWORK", 1, 6, C.gold, 1, hx, hy)
  return f
end

buildSwords = function()
  swordFrame = CreateFrame("Frame", nil, root)
  swordFrame:SetSize(SIZE, SIZE)
  swordFrame:SetPoint("CENTER")
  swordFrame:SetFrameLevel(root:GetFrameLevel() + 1) -- under medaljongen, under sidemenyene
  -- Glimt rundt kanten når sverdene låses
  swordFlash = Style.Disc(swordFrame, "BACKGROUND", 0, 72, C.goldLight, 0)
  local r = math.sqrt(0.5)
  swords = { sword(swordFrame, -r, r), sword(swordFrame, r, r) } -- spissene opp til venstre og høyre
  swordFrame:SetAlpha(0)
  swordFrame:Hide()
end

local function swordOffset(off)
  for _, s in ipairs(swords) do
    s:ClearAllPoints()
    s:SetPoint("CENTER", swordFrame, "CENTER", s.ux * off, s.uy * off)
  end
end

-- on = kampen starter (inn) eller er over (ut). instant: uten animasjon (f.eks. /reload midt i kamp).
function M.SetCombat(on, instant)
  if not swordFrame then return end
  M.combatShown = on
  local t0 = GetTime()
  if instant then
    swordFrame:SetScript("OnUpdate", nil)
    swordOffset(0)
    swordFlash:SetAlpha(0)
    swordFrame:SetAlpha(on and 1 or 0)
    swordFrame:SetShown(on)
    return
  end
  swordFrame:Show()
  swordFrame:SetScript("OnUpdate", function(self)
    local t = GetTime() - t0
    if on then
      -- skyter ned langs bladet (akselererer), smeller 3 px for langt, setter seg
      local off, a
      if t < 0.16 then
        local k = t / 0.16
        off, a = 40 - 43 * k * k, math.min(1, k * 2)
      elseif t < 0.26 then
        local k = (t - 0.16) / 0.10
        off, a = -3 + 3 * (1 - (1 - k) * (1 - k)), 1
      else
        off, a = 0, 1
      end
      swordOffset(off)
      self:SetAlpha(a)
      swordFlash:SetAlpha(t >= 0.16 and math.max(0, 0.7 * (1 - (t - 0.16) / 0.35)) or 0)
      if t >= 0.55 then self:SetScript("OnUpdate", nil) end
    else
      local k = math.min(1, t / 0.28)
      swordOffset(30 * k * k)
      self:SetAlpha(1 - k)
      swordFlash:SetAlpha(0)
      if k >= 1 then
        self:SetScript("OnUpdate", nil)
        self:Hide()
      end
    end
  end)
end

local function build()
  animFrame = CreateFrame("Frame")
  trackFrame = CreateFrame("Frame")
  root = CreateFrame("Frame", nil, UIParent)
  root:SetSize(SIZE, SIZE)
  root:SetMovable(true)
  root:SetClampedToScreen(true)
  -- Over action bars og questlista (Daniel 5. okt: de skinte gjennom menyen). Alt annet arver laget herfra.
  root:SetFrameStrata("HIGH")

  face = CreateFrame("Frame", nil, root)
  face:SetSize(SIZE, SIZE)
  face:SetPoint("CENTER")
  face:SetFrameLevel(root:GetFrameLevel() + 10) -- over knappene ved siden av, som starter under medaljongen

  -- Lag utenfra og inn (SPEC §7.1)
  -- Gløden: tre lag som blir svakere utover (en myk overgang uten tekstur)
  parts.glow = {
    { tex = Style.Disc(face, "BACKGROUND", -8, 76, C.red, 0), k = 0.10 },
    { tex = Style.Disc(face, "BACKGROUND", -8, 72, C.red, 0), k = 0.16 },
    { tex = Style.Disc(face, "BACKGROUND", -8, 68, C.red, 0), k = 0.24 },
  }
  parts.shadow = Style.Disc(face, "BACKGROUND", -7, 68, C.black, 0.55, 0, -2)
  parts.outer = Style.Disc(face, "BACKGROUND", -6, 64, C.black, 1)
  parts.bronze = Style.Disc(face, "BACKGROUND", -5, 62, { 1, 1, 1 }, 1)
  Style.Gradient(parts.bronze, C.bronzeDark, C.bronzeLight, C.bronzeMid)
  parts.bronzeEdge = Style.Disc(face, "BACKGROUND", -4, 56, C.bronzeLight, 0.30)
  parts.inner = Style.Disc(face, "BACKGROUND", -3, 54, C.black, 1)
  parts.ring = Style.Disc(face, "BACKGROUND", -2, 52, C.black, 1)
  parts.coreLo = Style.Disc(face, "BACKGROUND", -1, 48, C.coreLo, 1)
  parts.core = Style.Disc(face, "BACKGROUND", 0, 44, C.core, 1)
  parts.coreHi = Style.Disc(face, "BACKGROUND", 1, 30, C.coreHi, 0.55, 0, 4)

  parts.count = face:CreateFontString(nil, "OVERLAY")
  if not parts.count:SetFont(Style.FONT_HEAD, 25, "OUTLINE") then parts.count:SetFontObject(GameFontNormalHuge) end
  parts.count:SetPoint("CENTER", face, "CENTER", 0, 0)
  parts.count:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

  parts.check = symbolFrame(face, 0, 0)
  drawCheck(parts.check)

  sym.up = symbolFrame(face, 0, SYM_OFFSET)
  sym.up.open = symbolFrame(sym.up, 0, 0)
  drawLock(sym.up.open, 1, true)
  sym.up.closed = symbolFrame(sym.up, 0, 0)
  drawLock(sym.up.closed, 1, false)
  sym.down = symbolFrame(face, 0, -SYM_OFFSET)
  drawMenu(sym.down)
  sym.left = symbolFrame(face, -SYM_SIDE, 0)
  sym.left.one = symbolFrame(sym.left, 0, 0) drawOne(sym.left.one)
  sym.left.two = symbolFrame(sym.left, 0, 0) drawTwo(sym.left.two)
  sym.right = symbolFrame(face, SYM_SIDE, 0)
  sym.right.one = symbolFrame(sym.right, 0, 0) drawOne(sym.right.one)
  sym.right.two = symbolFrame(sym.right, 0, 0) drawTwo(sym.right.two)

  parts.dotHalo = Style.Disc(face, "OVERLAY", 4, 9, C.goldLight, 0)
  parts.dot = Style.Disc(face, "OVERLAY", 5, 4, C.goldLight, 0)
  parts.hubMove = symbolFrame(face, 0, 0)
  drawMove(parts.hubMove)
  parts.hubLock = symbolFrame(face, 0, 0)
  drawLock(parts.hubLock, 1.3, false)
  Style.Tint(parts.hubLock.parts, C.goldLight)

  -- Klikkflaten er en sikker knapp (Daniel 5. okt): i kamp åpner og lukker et sikkert skript sidemenyene og
  -- menyen (vanlig kode får ikke vise/skjule rammer med sikre knapper i kamp). Utenfor kamp gjør Lua det som før.
  hit = CreateFrame("Button", nil, root, "SecureHandlerClickTemplate")
  hit:SetAllPoints(root)
  hit:EnableMouse(true)
  hit:RegisterForClicks("LeftButtonUp")
  hit:SetAttribute("_onclick", M.TOGGLE)
  hit:SetFrameLevel(root:GetFrameLevel() + 20)

  buildSwords()
end

------------------------------------------------------------------------
-- Tegning fra tilstanden
------------------------------------------------------------------------

local function allSymParts(f)
  local out = {}
  local function collect(x)
    for _, p in ipairs(x.parts or {}) do out[#out + 1] = p end
    for _, k in ipairs({ "open", "closed", "one", "two" }) do if x[k] then collect(x[k]) end end
  end
  collect(f)
  return out
end

function applyAll()
  local grow = v("grow", 0)
  face:SetScale(M.Size() * (1 + 0.06 * grow))
  -- Bronsen lyser opp (115 %) ved mus over. Gradienten lages på nytt med lysere farger: SetVertexColor ville
  -- overskrevet den, fordi en gradient er hjørnefarger.
  local b = 0.87 + 0.13 * grow
  if b ~= parts.bronze.bright then
    parts.bronze.bright = b
    local function mul(c) return { math.min(1, c[1] * b), math.min(1, c[2] * b), math.min(1, c[3] * b) } end
    Style.Gradient(parts.bronze, mul(C.bronzeDark), mul(C.bronzeLight), mul(C.bronzeMid))
  end

  local num = v("num", 1)
  local showCheck = view.allOk
  parts.count:SetAlpha(showCheck and 0 or num)
  if parts.count.SetTextScale then parts.count:SetTextScale(0.7 + 0.3 * num) end
  parts.check:SetAlpha(showCheck and 0.6 * num or 0)

  for _, z in ipairs({ "up", "right", "down", "left" }) do
    local f, a, s = sym[z], v("symA_" .. z, 0), v("symS_" .. z, 1)
    f:SetAlpha(a)
    f:SetScale(s)
    f:ClearAllPoints()
    f:SetPoint("CENTER", face, "CENTER", f.baseX / s, f.baseY / s) -- skaleringen flytter ikke midtpunktet
  end

  local ang = math.rad(v("angle", 90))
  local dx, dy = DOT_R * math.cos(ang), DOT_R * math.sin(ang)
  for _, d in ipairs({ parts.dot, parts.dotHalo }) do
    d:ClearAllPoints()
    d:SetPoint("CENTER", face, "CENTER", dx, dy)
  end
  parts.dot:SetAlpha(v("dot", 0))
  parts.dotHalo:SetAlpha(v("dot", 0) * 0.35)

  parts.hubMove:SetAlpha(v("hubMove", 0))
  parts.hubLock:SetAlpha(v("hubLock", 0))

  local r, g, bl = v("ringR", 0), v("ringG", 0), v("ringB", 0)
  parts.ring:SetColorTexture(r, g, bl, 1)
  local ga = v("glowA", 0)
  for _, layer in ipairs(parts.glow) do layer.tex:SetColorTexture(r, g, bl, ga * layer.k) end
end

local function refreshHover()
  local locked = db.ui.locked
  local ring4 = hover and hover ~= "hub"
  animate("grow", hover and 1 or 0, 0.15)
  animate("num", hover and 0 or 1, 0.15)
  for _, z in ipairs({ "up", "right", "down", "left" }) do
    local active = hover == z
    animate("symA_" .. z, ring4 and (active and 1 or 0.45) or 0, 0.15)
    animate("symS_" .. z, active and 1.25 or 1, 0.15)
    Style.Tint(allSymParts(sym[z]), active and C.goldLight or C.goldDim)
  end
  if ring4 then animate("angle", ZONE_ANGLE[hover], 0.25) end
  animate("dot", ring4 and 1 or 0, 0.15)
  animate("hubMove", (hover == "hub" and not locked) and 1 or 0, 0.15)
  animate("hubLock", (hover == "hub" and locked) and 1 or 0, 0.15)
end

local function refreshSymbols()
  local locked = db.ui.locked
  sym.up.open:SetShown(not locked)
  sym.up.closed:SetShown(locked)
  local pl = partyLeft()
  sym.left.two:SetShown(pl)
  sym.left.one:SetShown(not pl)
  sym.right.two:SetShown(not pl)
  sym.right.one:SetShown(pl)
end

------------------------------------------------------------------------
-- Tooltip for sonene og midten (SPEC §14)
------------------------------------------------------------------------

local function zoneText(z)
  if z == "up" then return db.ui.locked and L.ZONE_UNLOCK or L.ZONE_LOCK end
  if z == "down" then
    local open = M.isMenuOpen and M.isMenuOpen()
    return open and L.ZONE_MENU_CLOSE or L.ZONE_MENU_OPEN
  end
  if z == "hub" then
    if db.ui.locked then return L.HUB_LOCKED end
    return L.HUB_MOVE, InCombatLockdown() and L.NOT_IN_COMBAT or nil -- spillet sperrer flytting i kamp
  end
  local isParty = (z == "left") == partyLeft()
  local open = M.isSideOpen and M.isSideOpen(z)
  local text
  if isParty then text = open and L.ZONE_CLOSE_PARTY or L.ZONE_OPEN_PARTY
  else text = open and L.ZONE_CLOSE_SELF or L.ZONE_OPEN_SELF end
  return text
end

local function showTip()
  if not hover then return GameTooltip:Hide() end
  local text, sub = zoneText(hover)
  GameTooltip:SetOwner(root, "ANCHOR_BOTTOM")
  GameTooltip:SetText(text, 1, 1, 1)
  if sub then GameTooltip:AddLine(sub, C.help[1], C.help[2], C.help[3]) end
  GameTooltip:Show()
end

------------------------------------------------------------------------
-- Mus: sone, klikk, flytting
------------------------------------------------------------------------

local function inCombat() return InCombatLockdown() end

local function cursorZone()
  local s = root:GetEffectiveScale()
  local x, y = GetCursorPosition()
  local cx, cy = root:GetCenter()
  if not cx then return nil end
  local fs = face:GetScale() -- størrelse og hover-vekst: sonene følger sirkelen
  return M.ZoneAt((x / s - cx) / fs, (y / s - cy) / fs)
end

local function setHover(z)
  if z == hover then return end
  hover = z
  refreshHover()
  showTip()
end

function M.TrackMouse()
  setHover(cursorZone())
end

local moving = false

function M.SavePosition()
  local point, rel, relPoint, x, y = root:GetPoint()
  db.ui.point = { point, (rel and rel.GetName and rel:GetName()) or "UIParent", relPoint, x, y }
end

function M.ApplyPosition()
  local p = db.ui.point
  root:ClearAllPoints()
  root:SetPoint(p[1] or "CENTER", UIParent, p[3] or p[1] or "CENTER", p[4] or 0, p[5] or 200)
end

-- Størrelse (slider i menyen, Daniel 5. okt): bare selve medaljongen vokser. Knappene, sidemenyene og menyen
-- beholder størrelsen og flytter seg utover med M.Extra(), så sirkelen ikke dekker dem.
-- Rammen (root) er alltid 64 px; det er den alt annet er forankret i, og midten står derfor stille.
local function applySize()
  local s = db.ui.scale or 1
  hit:ClearAllPoints()
  hit:SetPoint("CENTER", root, "CENTER")
  hit:SetSize(SIZE * s, SIZE * s)
  if swordFrame then swordFrame:SetScale(s) end
end

function M.Size() return (db and db.ui.scale) or 1 end

-- Hvor mye lenger ut kanten av sirkelen står enn ved 100 % (px)
function M.Extra() return math.floor(SIZE / 2 * (M.Size() - 1) + 0.5) end

function M.Lines() return lines end -- for testene

function M.Resnap()
  if not root then return end
  local k = M.Size()
  local px = Style.OnePixel(root) -- UI-enheter per skjermpiksel
  if not px or px <= 0 then px = 1 end
  for _, it in ipairs(lines) do
    local n = math.max(1, math.floor(it.t * k / px + 0.5))
    it.l:SetThickness(n * px / k)
  end
end

function M.SetScale(s)
  if inCombat() or type(s) ~= "number" or s <= 0 then return false end
  db.ui.scale = s
  applySize()
  M.Resnap()
  applyAll()
  return true
end

function M.SetLocked(locked)
  db.ui.locked = locked and true or false
  refreshSymbols()
  refreshHover()
  if hover then showTip() end
end

local function onMouseDown(_, button)
  if button ~= "LeftButton" then return end
  if hover == "hub" and not db.ui.locked and not inCombat() then
    moving = true
    root:StartMoving()
  end
end

local function onMouseUp(_, button)
  if GetCursorInfo() and M.onDrop then -- noe holdes på musepekeren: slipp det her
    M.onDrop()
    return
  end
  if moving then
    moving = false
    root:StopMovingOrSizing()
    M.SavePosition()
    return
  end
  if button ~= "LeftButton" then return end
  if hover == "up" then
    M.SetLocked(not db.ui.locked)
    if M.onLockChanged then M.onLockChanged(db.ui.locked) end
  elseif hover and M.onZoneClick then
    M.onZoneClick(hover)
    showTip()
  end
end

------------------------------------------------------------------------
-- Klemming: med begge sidemenyene og menyen fullt utfoldet (SPEC §7.8)
------------------------------------------------------------------------

function M.UpdateClamp(sideWidths)
  local wSelf = (sideWidths and sideWidths.self) or 100
  local wParty = (sideWidths and sideWidths.party) or 100
  local wL, wR = partyLeft() and wParty or wSelf, partyLeft() and wSelf or wParty
  -- Sidemenyene starter i midtpunktet (32 px inn); menyen stikker 138 px ut på hver side (340 px, sentrert)
  local extra = M.Extra()
  local left = math.max(138, SIZE / 2 + wL + extra - SIZE)
  local right = math.max(138, SIZE / 2 + wR + extra - SIZE)
  root:SetClampRectInsets(-left, right, extra, -28 - extra)
  M.clamp = { left = left, right = right }
end

------------------------------------------------------------------------
-- Offentlig
------------------------------------------------------------------------

function M.Create(database, locale)
  db, L = database, locale
  build()
  M.ApplyPosition()
  applySize()
  M.Resnap()
  hit:SetScript("OnEnter", function() setHover(cursorZone()) trackFrame:SetScript("OnUpdate", M.TrackMouse) end)
  hit:SetScript("OnLeave", function() trackFrame:SetScript("OnUpdate", nil) setHover(nil) GameTooltip:Hide() end)
  hit:HookScript("PostClick", function()
    if InCombatLockdown() then
      if M.onSecureToggle then M.onSecureToggle() end
      if hover then showTip() end
    end
  end)
  hit:SetScript("OnMouseDown", onMouseDown)
  hit:SetScript("OnMouseUp", onMouseUp)
  hit:SetScript("OnReceiveDrag", function() if M.onDrop then M.onDrop() end end)
  for _, k in ipairs({ "ringR", "ringG", "ringB", "glowA" }) do animate(k, 0, 0.3, true) end
  refreshSymbols()
  refreshHover()
  applyAll()
  M.frame = root
  return root
end

-- view fra Rules.render
function M.Update(newView)
  view = newView
  local txt = newView.allOk and "" or tostring(newView.count)
  parts.count:SetText(txt)
  -- Optisk midt (Daniel 5. okt): «1» i Friz Quadrata har flagg til venstre og bred fot, så streken – det øyet
  -- leser som tallet – står ca. 2 px til høyre for midten. Flytt den inn. (I medaljongens egne enheter: følger størrelsen.)
  local dx = 0
  if txt == "1" then dx = -1.5 elseif txt:sub(1, 1) == "1" then dx = -1 end
  if dx ~= parts.count.dx then
    parts.count.dx = dx
    parts.count:ClearAllPoints()
    parts.count:SetPoint("CENTER", face, "CENTER", dx, 0)
  end
  local c = Style.RING[newView.ring] or Style.RING[0]
  animate("ringR", c[1], 0.3)
  animate("ringG", c[2], 0.3)
  animate("ringB", c[3], 0.3)
  animate("glowA", Style.GLOW_ALPHA[newView.ring] or 0, 0.3)
  refreshSymbols()
  -- Skjermgrensen endres bare utenfor kamp: medaljongen har sikre knapper under seg (fase 3)
  if newView.side and not InCombatLockdown() then
    M.UpdateClamp({ self = newView.side.self.width, party = newView.side.party.width })
  end
  applyAll()
  if hover then showTip() end
end

-- Rammene det sikre skriptet åpner og lukker (sbleft/sbright, trleft/trright, menu). Bare utenfor kamp.
function M.SetRefs(refs)
  if inCombat() then return end
  for k, f in pairs(refs) do SecureHandlerSetFrameRef(hit, k, f) end
end

-- For testene
function M.State()
  return { hover = hover, locked = db.ui.locked, count = parts.count:GetText(), moving = moving,
           anim = anim, parts = parts, sym = sym, root = root, face = face, hit = hit,
           swordFrame = swordFrame, swords = swords, swordFlash = swordFlash, trackFrame = trackFrame, animFrame = animFrame }
end
