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
local MEDAL = 80      -- bildene til medaljongen (Media/medal_*): 80 × 80 enheter rundt sirkelen på 64
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
-- Symbolene: hvite bilder (24 × 24 enheter) med glatte kanter, farget gull i spillet (Style.Tint).
------------------------------------------------------------------------

local SYM = 24

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

local function symbol(f, name, scale, sub)
  local size = SYM * (scale or 1)
  return add(f, Style.Image(f, name, size, size, "OVERLAY", sub or 2))
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

-- Ferdig bilde med glatte kanter (Daniel 5. okt: strekene ble pikselerte). Tegnet av tools/sword_render.py:
-- 128 × 128, ett sverd med spissen opp til venstre, i en boks på ±48 enheter rundt midten. Det andre sverdet er
-- samme bilde speilvendt. Stien bygges fra mappenavnet; tests/run.py sjekker at fila finnes (en ukjent sti
-- krasjer Forever-klienten).
local SWORD_TEX = Style.Media("sword")
M.SWORD_TEX = SWORD_TEX

local function sword(parent, ux, uy)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(96, 96)
  f:SetPoint("CENTER")
  f.ux, f.uy = ux, uy
  f.tex = f:CreateTexture(nil, "ARTWORK")
  f.tex:SetAllPoints()
  f.tex:SetTexture(SWORD_TEX)
  if ux > 0 then f.tex:SetTexCoord(1, 0, 0, 1) end -- speilvendt: spissen opp til høyre
  return f
end

buildSwords = function()
  swordFrame = CreateFrame("Frame", nil, root)
  swordFrame:SetSize(SIZE, SIZE)
  swordFrame:SetPoint("CENTER")
  swordFrame:SetFrameLevel(root:GetFrameLevel() + 1) -- under medaljongen, under sidemenyene
  -- Glimt rundt kanten når sverdene låses
  swordFlash = Style.Image(swordFrame, "medal_glow", MEDAL * 1.05, MEDAL * 1.05, "BACKGROUND", 0)
  Style.Tint({ swordFlash }, C.goldLight, 0)
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

  -- Lag utenfra og inn (SPEC §7.1), som ferdige bilder på 80 × 80 enheter (skygge og glød rundt sirkelen på 64):
  -- glød (farges som ringen), selve medaljongen (skygge, bronse, kjerne), lyset i bronsen ved mus over
  -- (legges på), og statusringen (farges rød/oransje/svart).
  parts.glow = Style.Image(face, "medal_glow", MEDAL, MEDAL, "BACKGROUND", -8)
  parts.glow:SetAlpha(0)
  parts.base = Style.Image(face, "medal_base", MEDAL, MEDAL, "BACKGROUND", -6)
  parts.rim = Style.Image(face, "medal_rim", MEDAL, MEDAL, "BACKGROUND", -5)
  parts.rim:SetBlendMode("ADD")
  parts.rim:SetVertexColor(C.bronzeLight[1], C.bronzeLight[2], C.bronzeLight[3])
  parts.rim:SetAlpha(0)
  parts.ring = Style.Image(face, "medal_ring", MEDAL, MEDAL, "BACKGROUND", -2)
  parts.ring:SetVertexColor(0, 0, 0)

  parts.count = face:CreateFontString(nil, "OVERLAY")
  if not parts.count:SetFont(Style.FONT_HEAD, 25, "OUTLINE") then parts.count:SetFontObject(GameFontNormalHuge) end
  parts.count:SetPoint("CENTER", face, "CENTER", 0, 0)
  parts.count:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

  -- Alt ok: tom kjerne, ingen hake (Daniel 5. okt: det som ikke lyser, er i orden)

  sym.up = symbolFrame(face, 0, SYM_OFFSET - 1) -- låsen er høyest: 1 enhet lenger inn, så bøylen ikke når ringen
  sym.up.open = symbolFrame(sym.up, 0, 0)
  symbol(sym.up.open, "sym_lock_open")
  sym.up.closed = symbolFrame(sym.up, 0, 0)
  symbol(sym.up.closed, "sym_lock_closed")
  sym.down = symbolFrame(face, 0, -SYM_OFFSET)
  symbol(sym.down, "sym_menu")
  sym.left = symbolFrame(face, -SYM_SIDE, 0)
  sym.left.one = symbolFrame(sym.left, 0, 0) symbol(sym.left.one, "sym_one")
  sym.left.two = symbolFrame(sym.left, 0, 0) symbol(sym.left.two, "sym_two")
  sym.right = symbolFrame(face, SYM_SIDE, 0)
  sym.right.one = symbolFrame(sym.right, 0, 0) symbol(sym.right.one, "sym_one")
  sym.right.two = symbolFrame(sym.right, 0, 0) symbol(sym.right.two, "sym_two")

  -- Lysbuen langs ringen (SPEC §7.1): myk bue på bronsekanten som peker mot sonen, sammen med lysprikken
  parts.arc = Style.Image(face, "medal_arc", MEDAL, MEDAL, "OVERLAY", 3)
  parts.arc:SetBlendMode("ADD")
  Style.Tint({ parts.arc }, C.goldLight, 0)
  -- Lysprikken på kanten: myk glorie og en liten prikk
  parts.dotHalo = Style.Image(face, "soft", 9, 9, "OVERLAY", 4)
  parts.dot = Style.Image(face, "disc", 4, 4, "OVERLAY", 5)
  Style.Tint({ parts.dotHalo, parts.dot }, C.goldLight, 0)
  -- Midten ved mus over: flyttekors på en mørk skive, eller en lås når den er låst
  parts.hubMove = symbolFrame(face, 0, 0)
  local hubDisc = Style.Image(parts.hubMove, "disc", 19, 19, "OVERLAY", 1)
  Style.Tint({ hubDisc }, C.core)
  Style.Tint({ symbol(parts.hubMove, "sym_move", 1, 3) }, C.goldLight)
  parts.hubLock = symbolFrame(face, 0, 0)
  symbol(parts.hubLock, "sym_lock_closed", 1.3)
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
  -- Bronsen lyser opp ved mus over: lyset legges oppå (ADD), sterkest oppe
  parts.rim:SetAlpha(0.22 * grow)

  local num = v("num", 1)
  -- Tallet kan slås av under Oppsett (Daniel 5. okt); da er det ringen som forteller at noe mangler
  parts.count:SetAlpha((view.allOk or db.ui.showCount == false) and 0 or num)
  if parts.count.SetTextScale then parts.count:SetTextScale(0.7 + 0.3 * num) end

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
  if parts.arc.SetRotation then parts.arc:SetRotation(ang) end
  parts.arc:SetAlpha(v("dot", 0) * 0.7)

  parts.hubMove:SetAlpha(v("hubMove", 0))
  parts.hubLock:SetAlpha(v("hubLock", 0))

  local r, g, bl = v("ringR", 0), v("ringG", 0), v("ringB", 0)
  parts.ring:SetVertexColor(r, g, bl)
  parts.glow:SetVertexColor(r, g, bl)
  parts.glow:SetAlpha(v("glowA", 0))
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

function M.SetScale(s)
  if inCombat() or type(s) ~= "number" or s <= 0 then return false end
  db.ui.scale = s
  applySize()
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

-- Bare selve medaljongen holdes på skjermen (Daniel 5. okt: «få lov til å dytte den helt ut» – knappene,
-- sidemenyene og menyen får falle utenfor kanten hvis man vil det). Større medaljong: sirkelen stikker extra ut.
function M.UpdateClamp()
  local extra = M.Extra()
  root:SetClampRectInsets(-extra, extra, extra, -extra)
  M.clamp = { left = extra, right = extra }
end

------------------------------------------------------------------------
-- Offentlig
------------------------------------------------------------------------

function M.Create(database, locale)
  db, L = database, locale
  build()
  M.ApplyPosition()
  applySize()
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
