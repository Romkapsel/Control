-- Control: 40 px-knappen for én oppføring (SPEC §7.5). En sikker knapp (SecureActionButtonTemplate):
-- venstreklikk kaster spellen på deg selv eller bruker itemet. Attributter settes bare utenfor kamp.
-- Prosessen vises med form, ikke bare farge: tømming ovenfra (brukt tid), stor nedtelling (snart ute),
-- pulserende gullglød (kan trykkes), rolig ramme i ringens farge (gjør medaljongen farget, men lyser ikke),
-- og et bånd med lagertallet når en ting er tom.
local addonName, ns = ...
local Style = ns.Style
local C = Style.C

local EB = {}
ns.EntryButton = EB

local SIZE = 40
-- Spillets skrift (som overskriftene og spillets egne buffer), med skygge i stedet for tykk kant
-- (Daniel 5. okt: Arial med tykk kant så billig ut)
local GLOW = Style.hex("FFE98A")

local function useKeyDown()
  local ok, v = pcall(GetCVar, "ActionButtonUseKeyDown")
  return ok and v == "1"
end

local function font(fs, size, outline)
  if not fs:SetFont(Style.FONT_HEAD, size, outline and "OUTLINE" or "") then fs:SetFontObject(GameFontNormalSmall) end
  fs:SetShadowColor(0, 0, 0, 1)
  fs:SetShadowOffset(1, -1)
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

-- Felles vert for sikre skript på knappene i sidemenyene og menyen (Tray.RETARGET)
local header
function EB.Header()
  if not header then header = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate") end
  return header
end

local all = {}

-- Etter kamp: bind alle knappene på nytt. Det sikre skriptet kan ha flyttet en gruppeknapp videre i køen (unit,
-- ks-qi) for kast som ikke gikk gjennom; uten dette pekte den fortsatt på feil person etterpå.
function EB.ResetBindings()
  for _, b in ipairs(all) do b.sig = nil end
end

local function setIcon(b, e)
  local icon
  if e.spellId then icon = select(2, ns.Scan.SpellInfo(e.spellId)) end
  if e.itemId then icon = ns.Scan.ItemIcon(e.itemId) end
  if icon then b.icon:SetTexture(icon) else b.icon:SetColorTexture(0.2, 0.2, 0.2, 1) end
  b.noIcon = icon == nil -- ikke lastet ennå: prøves igjen ved neste tegning
end

function EB.Create(parent)
  local b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
  all[#all + 1] = b
  b:SetSize(SIZE, SIZE)
  b:RegisterForClicks(useKeyDown() and "AnyDown" or "AnyUp")
  b:SetAttribute("type2", "") -- høyreklikk skal aldri kaste (SPEC §12.1): det bytter tier
  b:SetAttribute("shift-type1", "") -- Shift + venstre gjør ingenting: Shift + dra flytter/fjerner uten å kaste
  b:RegisterForDrag("LeftButton")
  b:EnableMouseWheel(true)

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

  -- Bånd nederst med lagertallet når en ting er tom («0/10»)
  b.band = b:CreateTexture(nil, "OVERLAY", nil, 0)
  b.band:SetColorTexture(0, 0, 0, 0.72)
  b.band:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMLEFT")
  b.band:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT")
  b.band:SetHeight(13)
  b.bandText = b:CreateFontString(nil, "OVERLAY")
  font(b.bandText, 10)
  b.bandText:SetTextColor(C.text[1], C.text[2], C.text[3])
  b.bandText:SetPoint("CENTER", b.band, "CENTER", 0, 0)
  b.bandText:SetWordWrap(false)

  b.time = b:CreateFontString(nil, "OVERLAY")
  -- Svak mørk overgang nederst på ikonet, så tiden kan leses uten tykk kant
  b.timeShade = b:CreateTexture(nil, "ARTWORK", nil, 4)
  b.timeShade:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMLEFT")
  b.timeShade:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT")
  b.timeShade:SetHeight(16)
  b.timeShade:SetColorTexture(1, 1, 1, 1)
  if not (CreateColor and pcall(b.timeShade.SetGradient, b.timeShade, "VERTICAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0))) then
    b.timeShade:SetColorTexture(0, 0, 0, 0.5)
  end
  b.timeShade:Hide()
  font(b.time, 10)
  b.time:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
  b.time:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
  b.time:SetWordWrap(false)
  b.big = b:CreateFontString(nil, "OVERLAY")
  font(b.big, 15, true)
  b.big:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.big:SetWordWrap(false)
  -- MH/OH øverst til venstre på gift og olje: hvilken hånd knappen gjelder
  b.hand = b:CreateFontString(nil, "OVERLAY")
  font(b.hand, 9)
  b.hand:SetPoint("TOPLEFT", b, "TOPLEFT", 3, -3)
  b.hand:SetTextColor(C.text[1], C.text[2], C.text[3])
  b.stock = b:CreateFontString(nil, "OVERLAY")
  font(b.stock, 10)
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
  -- Ett mykt bilde (Daniel 5. okt: båndene av rektangler så pikselerte og trange ut): tynn lys kant rett
  -- innenfor knappens kant og et skinn som stopper før neste knapp. 64 × 64, sentrert på knappen.
  b.glow = CreateFrame("Frame", nil, b)
  b.glow:SetAllPoints(b)
  b.glowTex = Style.Image(b.glow, "glow_btn", 64, 64, "OVERLAY", 5)
  b.glowTex:SetVertexColor(GLOW[1], GLOW[2], GLOW[3])
  -- Diskret, fast ramme i ringens farge (oransje/rød) rundt det som gjør medaljongen farget, men ikke lyser
  -- (Daniel 5. okt: «må tyde for å finne hva som er oransje»). Samme myke bilde som gløden, svakere og uten puls.
  -- Skrus av og på med alpha (virker også i kamp).
  b.warn = Style.Image(b, "glow_btn", 64, 64, "OVERLAY", 4)
  b.warn:SetAlpha(0)
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
    if mouse == "LeftButton" and self.entry then
      -- Gruppebuff i kamp: det sikre skriptet kan ha flyttet knappen til neste i køen (unit). Bekreft på den.
      local cast = self.cast
      if cast and cast.target and not cast.group then
        local u = self:GetAttribute("unit")
        if u and u ~= cast.target.unit then
          local okN, nm = pcall(UnitName, u)
          if not okN or ns.Scan.isSecret(nm) then nm = nil end
          cast = { spell = cast.spell, group = false, target = { unit = u, name = nm } }
        end
      end
      ns.Track.Pressed(self.entry, cast)
    end
    self.flashAnim:Stop()
    self.flashAnim:Play()
  end)
  b:HookScript("PostClick", function(self, mouse)
    if mouse == "RightButton" and self.entry and not InCombatLockdown() and ns.Actions then
      ns.Actions.ToggleTier(self.entry)
    end
  end)
  b:SetScript("OnMouseWheel", function(self, delta)
    if self.entry and not InCombatLockdown() and ns.Actions then
      ns.Actions.Wheel(self.entry, delta, IsShiftKeyDown() and 5 or 1)
    end
  end)
  b:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and ns.SideBar then ns.SideBar.BeginDrag(self) end
  end)
  b:SetScript("OnDragStop", function(self)
    if ns.SideBar then ns.SideBar.EndDrag(self) end
  end)
  b:HookScript("OnEnter", function(self)
    if self.faded then return end -- usynlig (ferdig i kamp): ingen hover eller tooltip
    for _, t in ipairs(self.hoverEdge) do t:SetAlpha(0.75) end
    EB.ShowTooltip(self)
  end)
  b:HookScript("OnLeave", function(self)
    for _, t in ipairs(self.hoverEdge) do t:SetAlpha(0) end
    GameTooltip:Hide()
  end)
  return b
end

-- Hva knappen gjør når den klikkes. Bare utenfor kamp (beskyttet). Attributter settes bare når de endres.
-- Gruppebuff: st.cast = { spell, group, target = { name, unit } } fra Rules.partyCast.
-- Gruppebuff: hele køen av dem som mangler (ks-q1 …) settes også, så et klikk i kamp kan gå videre til neste.
function EB.Bind(b, e, st)
  local cast = st and st.cast
  local queue = {}
  if cast and cast.target and not cast.group then
    for _, m in ipairs(st.missingOn or {}) do queue[#queue + 1] = m.unit end
  end
  local sig = e.id .. "|" .. e.type .. "|" .. tostring(cast and cast.spell) .. "|" .. tostring(cast and cast.target and cast.target.unit)
    .. "|" .. table.concat(queue, ",")
  if b.entry == e and b.sig == sig then
    if b.noIcon then setIcon(b, e) end
    return
  end
  b.entry, b.sig, b.cast = e, sig, cast
  if #queue > 0 then
    for i, u in ipairs(queue) do b:SetAttribute("ks-q" .. i, u) end
    b:SetAttribute("ks-qn", #queue)
    b:SetAttribute("ks-qi", 1)
  else
    b:SetAttribute("ks-qn", nil)
  end
  if e.type == "partyspell" then
    if cast and cast.target then
      b:SetAttribute("type", "spell")
      b:SetAttribute("spell", cast.spell)
      b:SetAttribute("unit", cast.self and "player" or cast.target.unit) -- shouts: på deg selv
    else
      b:SetAttribute("type", nil) -- alle har den: ingenting å kaste
    end
    b:SetAttribute("item", nil)
  elseif e.type == "partyitem" then
    if cast and cast.target then
      b:SetAttribute("type", "item")
      b:SetAttribute("item", "item:" .. e.itemId)
      b:SetAttribute("unit", cast.target.unit) -- scrollen brukes på den som mangler
    else
      b:SetAttribute("type", nil)
    end
    b:SetAttribute("spell", nil)
  elseif e.type == "spell" then
    b:SetAttribute("type", "spell")
    b:SetAttribute("spell", e.name) -- etter navn: kaster høyeste rank (fase 0, V5)
    b:SetAttribute("unit", "player")
    b:SetAttribute("item", nil)
  elseif e.type == "buffitem" and e.weaponSlot then
    -- Gift/olje/slipestein: bruk tingen, og bruk så våpenet (som spillernes egen makro)
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", "/use item:" .. e.itemId .. "\n/use " .. e.weaponSlot)
    b:SetAttribute("item", nil)
    b:SetAttribute("spell", nil)
    b:SetAttribute("unit", nil)
  elseif e.type == "buffitem" then
    b:SetAttribute("type", "item")
    b:SetAttribute("item", "item:" .. e.itemId)
    b:SetAttribute("spell", nil)
    b:SetAttribute("unit", nil)
  else
    b:SetAttribute("type", nil) -- lagerting: vises bare
  end
  setIcon(b, e)
end

-- Hvordan knappen ser ut nå. Ikke beskyttet: virker også i kamp.
-- frozen = i kamp: en knapp som er ferdig (buffen er på), blir usynlig; den fjernes fra rekka etter kampen.
-- (Sikre knapper kan ikke skjules eller flyttes i kamp, så plassen står tom til kampen er over.)
function EB.Paint(b, e, st, L, frozen)
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
  local party = R.isParty(e)
  EB.Squares(b, party and st.members or nil)
  b.hand:SetText(e.weaponSlot == 16 and L.HAND_MAIN or e.weaponSlot == 17 and L.HAND_OFF or "")

  if party then
    glow = R.canPress(e, st) -- gløder når noen mangler (SPEC §7.5) og det er noe å gi dem
    if e.type == "partyitem" then
      local count = st.count or 0
      b.stock:SetText(R.stockText(count, 1))
      grey = count <= 0
      if grey then b.stock:SetTextColor(C.help[1], C.help[2], C.help[3]) else b.stock:SetTextColor(1, 1, 1) end
    end
  elseif e.type == "item" then
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
      b.time:SetText(R.formatTime(st.left, L, true) or "")
      if st.left and st.left ~= math.huge and st.duration and st.duration > 0 then
        drain = 1 - math.max(0, math.min(1, st.left / st.duration))
      end
    elseif status == "expiring" then
      b.big:SetText(R.formatTime(st.left, L, true) or "")
      drain = 0.97
    else
      -- Ikke på / gått ut: ingen tekst, gløden er signalet (Daniel, 4. okt)
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

  b.timeShade:SetShown((b.time:GetText() or "") ~= "")
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
  -- Medaljongen er farget av denne, men den lyser ikke: diskret ramme i samme farge som ringen
  local sev = R.severity(e, st)
  if not glow and sev > 0 then
    local c = sev == 2 and C.red or C.orange
    b.warn:SetVertexColor(c[1], c[2], c[3])
    b.warn:SetAlpha(0.55)
    b.warnSev = sev
  else
    b.warn:SetAlpha(0)
    b.warnSev = nil
  end
  b.faded = frozen and not R.canPress(e, st)
  local alpha = 1
  if b.faded then alpha = 0
  elseif party and InCombatLockdown() then alpha = 0.45 end -- vi ser ikke hvem som har den i kamp
  if b.dragDim then alpha = 0.35 end -- Shift + dra: knappen du drar, står dempet til du slipper
  b:SetAlpha(alpha)
  if GameTooltip:IsOwned(b) then EB.ShowTooltip(b) end
end

------------------------------------------------------------------------
-- Gruppebuff: én rute (5 px) per medlem som følges, i et 11 px-bånd nederst (SPEC §7.5).
-- Fylt lys = har, tom med gul kant = mangler, dempet = ukjent (ute av syne, offline, død).
------------------------------------------------------------------------

local LIGHT, GOLD, DIM = C.text, C.gold, Style.hex("5E5446")

function EB.Squares(b, members)
  b.squares = b.squares or {}
  local n = members and #members or 0
  if n == 0 then
    for _, sq in ipairs(b.squares) do sq.edge:Hide() sq.fill:Hide() end
    if b.partyBand then b.partyBand:Hide() end
    return
  end
  if not b.partyBand then
    b.partyBand = b:CreateTexture(nil, "OVERLAY", nil, 0)
    b.partyBand:SetColorTexture(0, 0, 0, 0.72)
    b.partyBand:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMLEFT")
    b.partyBand:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT")
    b.partyBand:SetHeight(11)
  end
  b.partyBand:Show()
  local total = n * 5 + (n - 1) * 2
  for i = 1, math.max(n, #b.squares) do
    local sq = b.squares[i]
    if not sq then
      sq = { edge = b:CreateTexture(nil, "OVERLAY", nil, 1), fill = b:CreateTexture(nil, "OVERLAY", nil, 2) }
      sq.edge:SetSize(5, 5)
      sq.fill:SetSize(3, 3)
      b.squares[i] = sq
    end
    local m = members[i]
    if m then
      local x = -total / 2 + (i - 1) * 7 + 2.5
      sq.edge:ClearAllPoints()
      sq.edge:SetPoint("CENTER", b.partyBand, "CENTER", x, 0)
      sq.fill:ClearAllPoints()
      sq.fill:SetPoint("CENTER", sq.edge, "CENTER")
      local edgeC, fillC, fillA = LIGHT, LIGHT, 1
      if m.has == false then edgeC, fillC, fillA = GOLD, C.black, 1
      elseif m.has == nil then edgeC, fillC, fillA = DIM, DIM, 1 end
      sq.edge:SetColorTexture(edgeC[1], edgeC[2], edgeC[3], 1)
      sq.fill:SetColorTexture(fillC[1], fillC[2], fillC[3], fillA)
      sq.edge:Show()
      sq.fill:Show()
    else
      sq.edge:Hide()
      sq.fill:Hide()
    end
  end
end

local function classColor(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then return c.r, c.g, c.b end
  return C.text[1], C.text[2], C.text[3]
end

local function partyTooltip(b, e, st, L)
  local members, missing = st.members or {}, st.missingOn or {}
  local known = 0
  for _, m in ipairs(members) do if m.has ~= nil then known = known + 1 end end
  GameTooltip:AddLine(#missing > 0 and string.format(L.TIP_PARTY_MISSING, #missing, #members) or L.TIP_PARTY_ALL, 1, 1, 1)
  for _, m in ipairs(members) do
    local r, g, bl = classColor(m.class)
    local word, wc = L.TIP_HAS, C.help
    if m.has == false then word, wc = L.TIP_LACKS, C.red
    elseif m.has == nil then word, wc = L.TIP_UNKNOWN, C.help end
    GameTooltip:AddDoubleLine(m.name, word, r, g, bl, wc[1], wc[2], wc[3])
  end
  local cast = b.cast
  if cast and cast.target then
    local action = cast.group and string.format(L.TIP_CAST_GROUP, cast.spell) or string.format(L.TIP_CAST_ON, cast.target.name)
    GameTooltip:AddLine(action, C.green[1], C.green[2], C.green[3])
  end -- ingen å kaste på: «Alle har den» står alt over
  local h = C.help
  GameTooltip:AddLine(e.onlyOn and L.TIP_ONLY_ON or L.TIP_PARTY_COMBAT, h[1], h[2], h[3])
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
  if ns.Rules.isParty(e) then
    partyTooltip(b, e, st, L)
    local h = C.help
    GameTooltip:AddLine(string.format(L.TIP_RCLICK, e.tier == 1 and L.TIER_1 or L.TIER_2), h[1], h[2], h[3])
    if b.inMenu then GameTooltip:AddLine(e.tier == 1 and L.TIER_1_HINT or L.TIER_2_HINT, h[1], h[2], h[3]) end
    if b.canDrag then GameTooltip:AddLine(L.TIP_DRAG, h[1], h[2], h[3]) end
    GameTooltip:Show()
    return
  elseif e.type == "item" then
    line = string.format(L.TIP_HAVE, st.count or 0, e.want or 1)
    -- Lagerting: «0 av 10» og fargen sier alt (Daniel 5. okt), ingen handlingslinje
  else
    if st.status == "expired" then line = L.TIP_EXPIRED
    elseif st.status == "missing" or not st.status then line = L.TIP_MISSING
    elseif st.status == "expiring" then line = string.format(L.TIP_EXPIRING, R.formatTime(st.left, L) or "")
    else line = st.left == math.huge and L.TIP_ON or string.format(L.TIP_LEFT, R.formatTime(st.left, L) or "") end
    if e.type == "buffitem" then
      line = line .. string.format(L.TIP_IN_BAG, st.count or 0, e.want or 1)
      if (st.count or 0) > 0 then
        action = e.weaponSlot and string.format(L.TIP_USE_WEAPON, e.weaponSlot == 17 and L.HAND_OFF_NAME or L.HAND_MAIN_NAME)
          or L.TIP_USE
      else
        action, actColor = L.TIP_NONE_IN_BAG, C.help
      end
    else
      action = L.TIP_CAST_SELF
    end
  end
  GameTooltip:AddLine(line, 1, 1, 1)
  if action ~= "" then GameTooltip:AddLine(action, actColor[1], actColor[2], actColor[3]) end
  local h = C.help
  if e.type == "buffitem" or e.type == "item" then GameTooltip:AddLine(L.TIP_WHEEL, h[1], h[2], h[3]) end
  GameTooltip:AddLine(string.format(L.TIP_RCLICK, e.tier == 1 and L.TIER_1 or L.TIER_2), h[1], h[2], h[3])
  if b.inMenu then GameTooltip:AddLine(e.tier == 1 and L.TIER_1_HINT or L.TIER_2_HINT, h[1], h[2], h[3]) end
  if b.canDrag then GameTooltip:AddLine(L.TIP_DRAG, h[1], h[2], h[3]) end
  GameTooltip:Show()
end
