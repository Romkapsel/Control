-- Control: menyen (SPEC §7.6). Åpnes med nedre sone, bare utenfor kamp (den har sikre knapper).
-- Fire deler, ovenfra: Mine buffs, Party buffs, Byvakt, Retning. Hver del har en kategorilinje (klikk = fell sammen),
-- unntatt Retning. Knappene oppfører seg som overalt ellers: klikk, høyreklikk = tier, hjul = antall, Shift + dra.
-- Står medaljongen i nedre halvdel av skjermen, åpner menyen oppover.
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local Menu = {}
ns.Menu = Menu

local PAD, HEAD = 10, 24
-- Bredden følger sidemenyene (Daniel 5. okt): like bred som to sidemenyer med 2 knapper og 1 «+» hver, med fugen
-- imellom – da linjer kantene opp. Fra midten: 3 px fuge + 37 px luft og kant + 3 × 46 px (+ der medaljongen er større).
local W = 356
function Menu.Width()
  local extra = (ns.Medallion and ns.Medallion.Extra and ns.Medallion.Extra()) or 0
  return 2 * (3 + 37 + 3 * 46 + extra)
end
local BTN, GAP = 40, 6
local TIERCOL = 22
local LINE = 18
local G = 10 -- lik luft mellom alt i menyen (Daniel 5. okt): elementer, rader, streker og kategorilinjer
local TEXTH = 14 -- høyden på en tekstlinje (12 px skrift)
local BX = PAD + TIERCOL + 8 -- første knapp i en rad, etter tier-tallet og fura
local PER_LINE = 6 -- regnes ut i Layout

local db, L, root
local frame
local pools = {}
local dimForCombat -- defineres lenger ned (før Menu.Paint), brukes også i Layout
local y = 0

-- Kallbakker fra Core (handlingene ligger der)
Menu.onChange = nil   -- noe er endret: tegn på nytt
Menu.onDrop = nil     -- (party, tier): slipp fra musepekeren
Menu.onFollow = nil   -- (entry, name, names): slå av/på hvem en gruppebuff følges på
Menu.onAddCity = nil  -- (zone)
Menu.onRemoveCity = nil -- (zone)
Menu.onSwap = nil
Menu.onScale = nil
Menu.onToggleCount = nil -- tallet i midten av medaljongen av/på    -- (skala 0,70–1,50): settes når du slipper slideren

------------------------------------------------------------------------
-- Byggeklosser
------------------------------------------------------------------------

local function newText(parent, size, color)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  if not fs:SetFont(Style.FONT_HEAD, size, "") then fs:SetFontObject(GameFontNormal) end
  fs:SetShadowColor(0, 0, 0, 1)
  fs:SetShadowOffset(1, -1)
  fs:SetWordWrap(false)
  if color then fs:SetTextColor(color[1], color[2], color[3]) end
  return fs
end

local function textWidth(fs)
  local ok, w = pcall(fs.GetStringWidth, fs)
  if not ok or type(w) ~= "number" or w <= 0 then w = #(fs:GetText() or "") * 6 end
  return math.ceil(w)
end

local function setColor(fs, c)
  fs:SetTextColor(c[1], c[2], c[3])
  fs.color = c
end

local function place(f, x, top)
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -top)
end

-- Gjenbruk: hver tegning tar fra starten av hver pool; det som ikke ble brukt, skjules til slutt
local function take(kind, make)
  local p = pools[kind]
  if not p then p = { n = 0, items = {} } pools[kind] = p end
  p.n = p.n + 1
  local it = p.items[p.n]
  if not it then it = make() p.items[p.n] = it end
  it:Show()
  return it
end

local function tooltip(owner, text, sub)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:SetText(text or "", 1, 1, 1)
  if sub then GameTooltip:AddLine(sub, C.help[1], C.help[2], C.help[3]) end
  GameTooltip:Show()
end

local function makeHeader()
  local h = CreateFrame("Button", nil, frame)
  h:SetHeight(HEAD)
  local bg = Style.hex("241C14")
  h.bg = h:CreateTexture(nil, "BACKGROUND")
  h.bg:SetAllPoints()
  h.bg:SetColorTexture(bg[1], bg[2], bg[3], 1)
  h.line = h:CreateTexture(nil, "ARTWORK")
  local lc = Style.hex("4A3920")
  h.line:SetColorTexture(lc[1], lc[2], lc[3], 1)
  h.line:SetHeight(Style.OnePixel(h))
  h.line:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT")
  h.line:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT")
  h.title = newText(h, 13, C.gold)
  h.title:SetPoint("LEFT", h, "LEFT", 8, 0)
  h.pm = newText(h, 14, C.goldDim or C.help)
  h.pm:SetPoint("RIGHT", h, "RIGHT", -8, 0)
  h.right = newText(h, 11, C.help)
  h.right:SetPoint("RIGHT", h, "RIGHT", -24, 0)
  h:SetScript("OnClick", function(self)
    if not self.key or InCombatLockdown() then return end
    db.ui.menuSections[self.key] = not db.ui.menuSections[self.key]
    if Menu.onChange then Menu.onChange() end
  end)
  return h
end

local function makeSlot()
  local s = CreateFrame("Button", nil, frame)
  s:SetSize(BTN, BTN)
  Style.Rect(s, "BACKGROUND", 0, BTN, BTN, C.black, 1)
  Style.Rect(s, "BACKGROUND", 1, BTN - 2, BTN - 2, Style.hex("0B0907"), 1)
  s.plus = newText(s, 20, Style.hex("5E5446"))
  s.plus:SetPoint("CENTER")
  s.plus:SetText("+")
  local function drop(self) if self.drop and Menu.onDrop then Menu.onDrop(self.drop.party, self.drop.tier) end end
  s:SetScript("OnReceiveDrag", drop)
  s:SetScript("OnMouseUp", function(self) if GetCursorInfo() then drop(self) end end)
  s:SetScript("OnEnter", function(self) tooltip(self, self.hint, self.sub) end)
  s:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return s
end

local function makeLink()
  local b = CreateFrame("Button", nil, frame)
  b:SetHeight(LINE)
  b.fs = newText(b, 12)
  b.fs:SetPoint("LEFT", b, "LEFT", 0, 0)
  b:SetScript("OnClick", function(self) if self.onClick and not InCombatLockdown() then self.onClick() end end)
  b:SetScript("OnEnter", function(self) if self.tip then tooltip(self, self.tip) end end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

local function makeAction()
  local b = CreateFrame("Button", nil, frame)
  b:SetHeight(22)
  b.edge = b:CreateTexture(nil, "BACKGROUND", nil, 0)
  b.edge:SetAllPoints()
  local e = Style.hex("8A6A36")
  b.edge:SetColorTexture(e[1], e[2], e[3], 1)
  b.fill = b:CreateTexture(nil, "BACKGROUND", nil, 1)
  b.fill:SetPoint("TOPLEFT", 1, -1)
  b.fill:SetPoint("BOTTOMRIGHT", -1, 1)
  local f = Style.hex("1C1610")
  b.fill:SetColorTexture(f[1], f[2], f[3], 1)
  b.fs = newText(b, 12)
  b.fs:SetPoint("CENTER")
  b:SetScript("OnClick", function(self)
    if self.enabled and self.onClick and (self.allowCombat or not InCombatLockdown()) then self.onClick() end
  end)
  b:SetScript("OnEnter", function(self)
    if InCombatLockdown() and not self.allowCombat then return tooltip(self, L.NOT_IN_COMBAT) end
    if self.tip then tooltip(self, self.tip) end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

local function text(str, color, size)
  local fs = take("text" .. (size or 12), function() return newText(frame, size or 12) end)
  fs:SetWidth(0)
  fs:SetText(str)
  setColor(fs, color or C.text)
  return fs
end

local function link(str, color, tip, onClick)
  local b = take("link", makeLink)
  b.fs:SetText(str)
  setColor(b.fs, color)
  b.text, b.color, b.tip, b.onClick = str, color, tip, onClick
  b:SetWidth(textWidth(b.fs))
  return b
end

local function action(str, enabled, tip, onClick, width)
  local b = take("action", makeAction)
  b.fs:SetText(str)
  setColor(b.fs, enabled and C.gold or C.help)
  b.enabled, b.text, b.tip, b.onClick, b.allowCombat = enabled, str, tip, onClick, nil
  b:SetWidth(width or (textWidth(b.fs) + 20))
  b:SetAlpha(enabled and 1 or 0.5)
  return b
end

------------------------------------------------------------------------
-- Delene
------------------------------------------------------------------------

local function header(key, title, right)
  local h = take("head", makeHeader)
  h:SetWidth(W - 8)
  place(h, 4, y)
  h.key = key
  h.title:SetText(title)
  h.right:SetText(right or "")
  local isOpen = key == nil or db.ui.menuSections[key] ~= false
  h.pm:SetText(key and (isOpen and "-" or "+") or "") -- vanlig bindestrek: Friz Quadrata har ikke U+2212
  Menu.heads[#Menu.heads + 1] = h
  y = y + HEAD + G
  return isOpen
end

-- Tynn strek mellom ting inne i en bolk (f.eks. Bytt side og Størrelse): sentrert, lik luft over og under.
-- Bolkene skilles av kategorilinja, ikke av streker (Daniel 5. okt).
local function separator()
  local t = take("sep", function()
    local s = frame:CreateTexture(nil, "ARTWORK")
    local c = Style.hex("4A3920")
    s:SetColorTexture(c[1], c[2], c[3], 1)
    s:SetHeight(1)
    return s
  end)
  t:SetWidth(W - 80)
  Style.HairlineAt(t, "TOPLEFT", frame, "TOPLEFT", 40, -y)
  y = y + 1 + G -- like mye luft over (fra elementet over) som under
end

local function sideWord(isParty)
  local partyRight = db.ui.partySide == "right"
  local right = (isParty and partyRight) or (not isParty and not partyRight)
  return right and L.SIDE_RIGHT or L.SIDE_LEFT
end

-- Rad I og rad II: tier-tallet, knappene (brytes etter PER_LINE) og en «+»-rute sist
local function rows(list, isParty, st)
  local host = Menu.host
  for tier = 1, 2 do
    local items = {}
    for _, e in ipairs(list) do if e.tier == tier then items[#items + 1] = e end end
    local total = #items + 1
    local lines = math.ceil(total / PER_LINE)
    local h = lines * (BTN + GAP) - GAP
    local label = text(tier == 1 and L.TIER_1 or L.TIER_2, C.gold, 14)
    label:ClearAllPoints()
    label:SetPoint("CENTER", frame, "TOPLEFT", PAD + TIERCOL / 2, -(y + BTN / 2))
    for i = 1, total do
      local col, line = (i - 1) % PER_LINE, math.floor((i - 1) / PER_LINE)
      local x, top = BX + col * (BTN + GAP), y + line * (BTN + GAP)
      if i <= #items then
        local e = items[i]
        local b = take("btn", function()
          local nb = ns.EntryButton.Create(frame)
          SecureHandlerWrapScript(nb, "OnClick", ns.EntryButton.Header(), ns.Tray.PRE, ns.Tray.RETARGET) -- gruppebuff i kamp
          nb.canDrag, nb.inMenu, nb.dragHost = true, true, host
          return nb
        end)
        place(b, x, top)
        b.isParty = isParty
        host.buttons[#host.buttons + 1] = b
        b.index = #host.buttons
        host.ids[b.index] = e.id
        ns.EntryButton.Bind(b, e, st[e.id])
        ns.EntryButton.Paint(b, e, st[e.id], L)
      else
        local s = take("slot", makeSlot)
        place(s, x, top)
        s.drop = { party = isParty, tier = tier }
        s.hint = isParty and L.EMPTY_PARTY or L.EMPTY_SELF
        s.sub = tier == 1 and L.TIER_1_HINT or L.TIER_2_HINT
        host.slots[#host.slots + 1] = s
      end
    end
    y = y + h + G
  end
end

local function classColor(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then return { c.r, c.g, c.b } end
  return C.text
end

local function iconOf(e)
  if e.spellId then return select(2, ns.Scan.SpellInfo(e.spellId)) end
  if e.itemId then return ns.Scan.ItemIcon(e.itemId) end
end

-- Hvem hver gruppebuff følges på (Q7): klikk et navn for å slå det av/på. Grå = følges ikke.
local function picker(list, members)
  if #list == 0 then return end
  if #members == 0 then
    local t = text(L.NO_PARTY, C.help)
    place(t, PAD, y)
    y = y + TEXTH + G
    return
  end
  local names, classes = {}, {}
  for _, m in ipairs(members) do
    if m.name then names[#names + 1] = m.name classes[m.name] = m.class end
  end
  for _, e in ipairs(list) do
    local ic = take("icon", function()
      local t = frame:CreateTexture(nil, "ARTWORK")
      t:SetSize(16, 16)
      t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      return t
    end)
    place(ic, PAD, y + 1)
    local icon = iconOf(e)
    if icon then ic:SetTexture(icon) else ic:SetColorTexture(0.2, 0.2, 0.2, 1) end
    local all = {}
    for _, n in ipairs(names) do all[#all + 1] = n end
    for n in pairs(e.onlyOn or {}) do if not classes[n] then all[#all + 1] = n end end -- valgt, men ikke i party nå
    local x = PAD + 24
    for _, n in ipairs(all) do
      local on = e.onlyOn == nil or e.onlyOn[n] == true
      local short = e.short or e.name
      local l = link(n, on and classColor(classes[n]) or Style.hex("5E5446"),
        string.format(on and L.FOLLOW_STOP or L.FOLLOW_START, n, short),
        function() if Menu.onFollow then Menu.onFollow(e, n, names) end end)
      local w = l:GetWidth() or 40
      if x + w > W - PAD and x > PAD + 24 then x = PAD + 24 y = y + LINE end
      place(l, x, y)
      l.entry, l.followed = e, on
      x = x + w + 12
    end
    y = y + LINE
  end
  y = y + G - (LINE - TEXTH)
end

local function safeZone()
  local ok, z = pcall(GetRealZoneText)
  if not ok or ns.Scan.isSecret(z) or type(z) ~= "string" or z == "" then return nil end
  return z
end
Menu.Zone = safeZone

-- Lista over steder som voktes: foldes ut med «Voktes (n)». Dra et sted ut av lista for å fjerne det.
local citiesOpen = false
local ghost, draggingCity

local function ensureGhost()
  if ghost then return ghost end
  ghost = CreateFrame("Frame", nil, UIParent)
  ghost:SetSize(10, 10)
  ghost:SetFrameStrata("TOOLTIP")
  ghost.fs = newText(ghost, 12)
  ghost.fs:SetPoint("LEFT", ghost, "RIGHT", 4, 0)
  ghost:Hide()
  return ghost
end

local function makeCityRow()
  local r = CreateFrame("Button", nil, frame)
  r:SetFrameLevel(frame:GetFrameLevel() + 3) -- over boksen, så det er radene som tar musa
  r:SetHeight(LINE)
  r.fs = newText(r, 12, C.text)
  r.fs:SetPoint("LEFT", r, "LEFT", 6, 0)
  r.hl = r:CreateTexture(nil, "BACKGROUND")
  r.hl:SetAllPoints()
  r.hl:SetColorTexture(1, 0.93, 0.67, 0)
  r:RegisterForDrag("LeftButton")
  r:SetScript("OnEnter", function(self)
    self.hl:SetColorTexture(1, 0.93, 0.67, 0.08)
    tooltip(self, self.city, L.CITY_ROW_TIP)
  end)
  r:SetScript("OnLeave", function(self) self.hl:SetColorTexture(1, 0.93, 0.67, 0) GameTooltip:Hide() end)
  r:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    draggingCity = self
    self:SetAlpha(0.35)
    local g = ensureGhost()
    g:SetScript("OnUpdate", function(gf)
      local x, yy = GetCursorPosition()
      local s = UIParent:GetEffectiveScale() or 1
      gf:ClearAllPoints()
      gf:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, yy / s)
      local inside = Menu.cityBox and Menu.cityBox:IsMouseOver()
      gf.fs:SetText(inside and self.city or (self.city .. "  " .. L.DRAG_REMOVE))
      setColor(gf.fs, inside and C.text or C.red)
    end)
    g:Show()
  end)
  r:SetScript("OnDragStop", function(self)
    if draggingCity ~= self then return end
    draggingCity = nil
    self:SetAlpha(1)
    if ghost then ghost:Hide() ghost:SetScript("OnUpdate", nil) end
    if InCombatLockdown() then return end
    if not (Menu.cityBox and Menu.cityBox:IsMouseOver()) and Menu.onRemoveCity then Menu.onRemoveCity(self.city) end
  end)
  return r
end

local function makeBox()
  local b = CreateFrame("Frame", nil, frame)
  b:SetFrameLevel(frame:GetFrameLevel() + 1)
  local e = Style.hex("4A3920")
  b.edge = b:CreateTexture(nil, "BACKGROUND", nil, 0)
  b.edge:SetAllPoints()
  b.edge:SetColorTexture(e[1], e[2], e[3], 1)
  b.fill = b:CreateTexture(nil, "BACKGROUND", nil, 1)
  b.fill:SetPoint("TOPLEFT", 1, -1)
  b.fill:SetPoint("BOTTOMRIGHT", -1, 1)
  local f = Style.hex("0B0907")
  b.fill:SetColorTexture(f[1], f[2], f[3], 1)
  b:EnableMouse(true)
  return b
end

-- De lange knappene (Voktes, Bytt side) er like brede: teksten «Bytt side på gruppene» + luft, midtstilt
local function wideWidth()
  local probe = text(L.DIR_SWAP, C.text)
  local w = textWidth(probe) + 28
  probe:Hide()
  return w
end

local function cityWatch()
  local cities = db.cityWatch.cities
  local zone = safeZone()
  local watched = false
  for _, c in ipairs(cities) do if c == zone then watched = true end end
  local a = action(L.CITY_ADD, zone ~= nil and not watched, watched and L.CITY_ALREADY or nil,
    function() if Menu.onAddCity then Menu.onAddCity(zone) end end)
  local aw = a:GetWidth() or 80
  place(a, W - PAD - aw, y)
  Menu.cityButton = a
  local here = text(string.format(L.CITY_HERE, zone or "?"), C.help)
  here:SetWidth(W - 2 * PAD - aw - 10) -- lange sonenavn kuttes med «…» i stedet for å gå inn i knappen
  here:SetJustifyH("LEFT")
  place(here, PAD, y + 4)
  y = y + 22 + G
  local ww = wideWidth()
  local list = action(string.format(L.CITY_LIST, #cities), true, nil, function()
    citiesOpen = not citiesOpen
    if Menu.onChange then Menu.onChange() end
  end, ww)
  place(list, math.floor((W - ww) / 2), y)
  list.edge:SetAlpha(citiesOpen and 1 or 0.6)
  Menu.cityListButton = list
  y = y + 22 + G
  Menu.cityBox = nil
  if citiesOpen then
    local box = take("box", makeBox)
    local rowsN = math.max(1, #cities)
    local bw = ww -- samme bredde som knappen over
    local bx = math.floor((W - bw) / 2)
    box:SetSize(bw, rowsN * LINE + 6)
    place(box, bx, y)
    Menu.cityBox = box
    if #cities == 0 then
      local t = text(L.CITY_NONE, C.help)
      place(t, bx + 6, y + 3)
    end
    for i, c in ipairs(cities) do
      local r = take("cityrow", makeCityRow)
      r.city = c
      r.fs:SetText(c)
      r:SetWidth(bw - 2)
      place(r, bx + 1, y + 3 + (i - 1) * LINE)
    end
    y = y + rowsN * LINE + 6 + G
  end
end
Menu.CitiesOpen = function() return citiesOpen end

-- Størrelse: slider 70–150 %. Viser tallet mens du drar; endrer størrelsen når du slipper
-- (ellers vokser menyen bort fra musepekeren mens du drar).
local function makeSlider()
  local s = CreateFrame("Slider", nil, frame)
  s:SetOrientation("HORIZONTAL")
  s:EnableMouse(true)
  s:SetSize(150, 16)
  s:SetMinMaxValues(math.floor(ns.Data.SCALE_MIN * 100 + 0.5), math.floor(ns.Data.SCALE_MAX * 100 + 0.5))
  s:SetValueStep(math.floor(ns.Data.SCALE_STEP * 100 + 0.5))
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:EnableMouseWheel(true)
  local tc = Style.hex("4A3920")
  s.track = s:CreateTexture(nil, "BACKGROUND")
  s.track:SetColorTexture(tc[1], tc[2], tc[3], 1)
  s.track:SetPoint("LEFT", s, "LEFT", 0, 0)
  s.track:SetPoint("RIGHT", s, "RIGHT", 0, 0)
  s.track:SetHeight(4)
  s.thumb = s:CreateTexture(nil, "OVERLAY")
  s.thumb:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
  s.thumb:SetSize(10, 16)
  s:SetThumbTexture(s.thumb)
  s.label = newText(frame, 12, C.text)
  local function commit(self)
    local v = self:GetValue()
    if type(v) == "number" and Menu.onScale and math.abs(v / 100 - (db.ui.scale or 1)) > 0.001 then Menu.onScale(v / 100) end
  end
  s:SetScript("OnValueChanged", function(self, v)
    self.label:SetText(string.format(L.SCALE_VALUE, math.floor((v or 100) + 0.5)))
    if not self.dragging and not self.setting then commit(self) end -- hjul og klikk på sporet: med en gang
  end)
  s:SetScript("OnMouseDown", function(self) self.dragging = true end)
  s:SetScript("OnMouseUp", function(self) self.dragging = false commit(self) end)
  s:SetScript("OnMouseWheel", function(self, delta)
    if InCombatLockdown() then return end
    self:SetValue((self:GetValue() or 100) + (delta > 0 and 5 or -5))
  end)
  s:SetScript("OnEnter", function(self) tooltip(self, L.SCALE_TIP, InCombatLockdown() and L.NOT_IN_COMBAT or nil) end)
  s:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return s
end

-- Størrelse: tekst, glider og prosent som én midtstilt gruppe (Daniel 5. okt: så strukket ut)
local SLIDER_W, VALUE_W = 150, 40
local function scaleRow()
  local t = text(L.SCALE, C.text)
  local tw = textWidth(t)
  local x0 = math.floor((W - (tw + 14 + SLIDER_W + 10 + VALUE_W)) / 2)
  place(t, x0, y + 1)
  if not Menu.slider then Menu.slider = makeSlider() end
  local s = Menu.slider
  s:Show()
  s.label:Show()
  place(s, x0 + tw + 14, y)
  -- Menyen tegnes fire ganger i sekundet. Mens du drar, skal slideren stå der musa er, ikke hoppe tilbake
  -- til lagret verdi (det var hakkingen, Daniel 5. okt).
  if not s.dragging then
    s.setting = true -- å sette verdien fra lagringen er ikke en endring
    s:SetValue(math.floor((db.ui.scale or 1) * 100 + 0.5))
    s.setting = false
  end
  s.label:ClearAllPoints()
  s.label:SetPoint("TOPLEFT", frame, "TOPLEFT", x0 + tw + 14 + SLIDER_W + 10, -(y + 1))
  y = y + 16 + G
end

-- Tall i midten: av/på (Daniel 5. okt). Tekst til venstre, liten knapp til høyre, som «Legg til» under Byvakt.
local function countRow()
  local on = db.ui.showCount ~= false
  local t = text(L.COUNT_LABEL, C.text)
  local tw = textWidth(t)
  local x0 = math.floor((W - (tw + 14 + 52)) / 2) -- tekst og knapp som én midtstilt gruppe
  place(t, x0, y + 4)
  Menu.countText = t
  local a
  a = action(on and L.ON or L.OFF, true, nil, function()
    if Menu.onToggleCount then Menu.onToggleCount() end
    local now = db.ui.showCount ~= false and L.ON or L.OFF
    a.fs:SetText(now)
    a.text = now
  end, 52)
  a.allowCombat = true -- endrer bare tallet i medaljongen
  place(a, x0 + tw + 14, y)
  Menu.countButton = a
  y = y + 22 + G
end

-- Bytt side: én lang knapp, midtstilt (Daniel 5. okt). Hvilken side som er hvor, står i kategorilinjene over.
local function direction()
  local ww = wideWidth()
  local a = action(L.DIR_SWAP, true, nil, function() if Menu.onSwap then Menu.onSwap() end end, ww)
  place(a, math.floor((W - ww) / 2), y)
  Menu.swapButton = a
  y = y + 22 + G
end

------------------------------------------------------------------------
-- Plassering: under medaljongen, eller over når den står i nedre halvdel av skjermen
------------------------------------------------------------------------

function Menu.OpensUp()
  local _, cy = root:GetCenter()
  if type(cy) ~= "number" then return false end
  local rs = root:GetEffectiveScale() or 1
  local us = UIParent:GetEffectiveScale() or 1
  local h = UIParent:GetHeight()
  if type(h) ~= "number" or h <= 0 then h = 768 end
  return cy * rs / us < h / 2
end

-- Rammen (root) er 64 px; en større medaljong stikker extra px ut over og under den.
-- 6 px luft til medaljongen eller sidemenyene – samme fuge som mellom sidemenyene (Daniel 5. okt).
local AIRGAP = 6
local function anchor(sideOpen)
  frame:ClearAllPoints()
  local extra = ns.Medallion.Extra and ns.Medallion.Extra() or 0
  local up = Menu.OpensUp()
  if up then
    frame:SetPoint("BOTTOM", root, "TOP", 0, AIRGAP + extra)
  else
    local top = 64 + AIRGAP + extra
    -- Under sidemenyene (4 px ned + 88 px høye): et hakk tettere, så luften ser lik ut som fugen mellom dem
    if sideOpen then top = math.max(top, 4 + 88 + 4) end
    frame:SetPoint("TOP", root, "TOP", 0, -top)
  end
  -- Pila peker mot medaljongen: opp når menyen henger under, ned når den står over
  if Menu.closeUp and Menu.closeDown then
    Menu.closeUp:SetShown(not up)
    Menu.closeDown:SetShown(up)
  end
end

Menu.CLOSE = [[
  local m = self:GetFrameRef("menu")
  if m then m:Hide() end
]]

------------------------------------------------------------------------
-- Offentlig
------------------------------------------------------------------------

function Menu.Create(parent, database, locale)
  root, db, L = parent, database, locale
  -- Eksplisitt beskyttet ramme: det sikre skriptet på medaljongen og lukke-pila kan vise/skjule den i kamp
  frame = CreateFrame("Frame", nil, parent, "SecureHandlerBaseTemplate")
  frame:SetFrameLevel(parent:GetFrameLevel() + 2)
  frame:SetWidth(W)
  frame:SetHeight(100)
  Style.Frame(frame)
  frame:EnableMouse(true)
  frame.unfold = frame:CreateAnimationGroup()
  local sc = frame.unfold:CreateAnimation("Scale")
  if sc.SetScaleFrom then sc:SetScaleFrom(1, 0.25) sc:SetScaleTo(1, 1) end
  sc:SetDuration(0.3)
  sc:SetSmoothing("OUT")
  frame.unfoldScale = sc
  local a = frame.unfold:CreateAnimation("Alpha")
  a:SetFromAlpha(0)
  a:SetToAlpha(1)
  a:SetDuration(0.2)
  -- Lukke-piler nederst til høyre (én av dem vises, etter hvilken vei menyen åpner)
  local function after() if Menu.onChange then Menu.onChange() end end
  Menu.closeUp = Style.CloseArrow(frame, "up", Menu.CLOSE, L.CLOSE, after)
  Menu.closeDown = Style.CloseArrow(frame, "down", Menu.CLOSE, L.CLOSE, after)
  for _, b in ipairs({ Menu.closeUp, Menu.closeDown }) do
    b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    SecureHandlerSetFrameRef(b, "menu", frame)
  end
  Menu.closeDown:Hide()
  frame:Hide()
  Menu.frame = frame
  Menu.host = { frame = frame, buttons = {}, ids = {}, slots = {} }
  Menu.heads = {}
  return frame
end

function Menu.IsOpen() return frame ~= nil and frame:IsShown() end

function Menu.SetOpen(v)
  if InCombatLockdown() or not frame then return end
  if v then
    frame:Show()
    -- Glir ut fra medaljongen: ned når den henger under, opp når den står over (SPEC §7.6, 0,3 s)
    frame.unfoldScale:SetOrigin(Menu.OpensUp() and "BOTTOM" or "TOP", 0, 0)
    frame.unfold:Play()
  else
    frame:Hide()
  end
end

-- Bygg menyen (bare utenfor kamp). model = Core.Model(), members = Scan.Party()
-- Bygges også når den er lukket: i kamp kan den bare åpnes (av det sikre skriptet), ikke bygges.
function Menu.Layout(model, members, sideOpen)
  if not frame or InCombatLockdown() then return false end
  W = Menu.Width()
  PER_LINE = math.floor((W - PAD - BX + GAP) / (BTN + GAP))
  frame:SetWidth(W)
  for _, p in pairs(pools) do p.n = 0 end
  local host = Menu.host
  host.buttons, host.ids, host.slots = {}, {}, {}
  Menu.heads = {}
  y = 8
  if header("self", L.LABEL_MY_BUFFS, sideWord(false)) then rows(model.self, false, model.st) end
  if header("party", L.LABEL_PARTY_BUFFS, sideWord(true)) then
    rows(model.party, true, model.st)
    picker(model.party, members or {})
  end
  if header("city", L.MENU_CITY) then cityWatch() end
  header(nil, L.MENU_DIR)
  direction()
  separator()
  countRow()
  separator()
  scaleRow()
  if db.debug and db.debug.rangeButton then
    -- Avstandstest (slås på med /control avstand): ett bilde per trykk, også i kamp
    separator()
    local ww = W - 2 * PAD - 80
    local a = action(L.RANGE_BUTTON, true, L.RANGE_TIP, function() if ns.RangeProbe then ns.RangeProbe() end end, ww)
    a.allowCombat = true
    place(a, math.floor((W - ww) / 2), y)
    Menu.rangeButton = a
    y = y + 22 + G
  else
    Menu.rangeButton = nil
  end
  for _, p in pairs(pools) do
    for i = p.n + 1, #p.items do p.items[i]:Hide() end
  end
  frame:SetHeight(y + 4)
  anchor(sideOpen)
  if Menu.combatDimmed then dimForCombat(false) end
  return true
end

-- I kamp: bare utseendet på knappene (tider, lager, glød)
-- Det som ikke virker i kamp (Bytt side, Størrelse, Byvakt, navnene, å folde delene), blir grått så lenge kampen
-- varer (Daniel 5. okt: «man kan ikke endre på menyen under combat» – det så bare ut som om ingenting skjedde).
-- Tall i midten og Avstandstest virker. Utenfor kamp setter Layout alt tilbake.
dimForCombat = function(combat)
  local dim = combat and 0.4 or 1
  for kind, p in pairs(pools) do
    for i = 1, p.n do
      local it = p.items[i]
      if kind == "action" then
        if combat and not it.allowCombat then it:SetAlpha(0.4) elseif not combat then it:SetAlpha(it.enabled and 1 or 0.5) end
      elseif kind == "link" or kind == "cityrow" then
        it:SetAlpha(dim)
      elseif kind == "head" then
        it.pm:SetAlpha(dim)
      end
    end
  end
  local s = Menu.slider
  if s then
    s:SetAlpha(dim)
    s.label:SetAlpha(dim)
    s:EnableMouse(not combat)
  end
  Menu.combatDimmed = combat
end

function Menu.Paint(model)
  if not frame or not frame:IsShown() then return end
  local combat = InCombatLockdown() and true or false
  if combat ~= (Menu.combatDimmed or false) then dimForCombat(combat) end
  local byId = {}
  for _, e in ipairs(model.self) do byId[e.id] = e end
  for _, e in ipairs(model.party) do byId[e.id] = e end
  for i, b in ipairs(Menu.host.buttons) do
    local e = byId[Menu.host.ids[i]]
    if e then ns.EntryButton.Paint(b, e, model.st[e.id], L) end
  end
end
