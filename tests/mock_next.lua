-- Én tast for «neste buff» (Daniel 5. okt): ControlNextBuff trykker den første knappen ved medaljongen; i kamp går
-- den videre til neste når en knapp er trykket og forsvinner.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local nb = ns.Tray.nextBtn
check(nb and nb.name == "ControlNextBuff" and nb.template == "SecureActionButtonTemplate", "knappen tasten trykker, har navn")
eq(nb:GetAttribute("type"), "click", "den sender trykket videre")
eq(BINDING_NAME_CLICK == nil and _G["BINDING_NAME_CLICK ControlNextBuff:LeftButton"], "Neste buff", "navnet i tasteoppsettet")
local trR, trL = ns.Tray.Get("right"), ns.Tray.Get("left")
check(trR.frame.refs.next == nb and trR.frame.refs.other == trL.frame, "trayene kjenner tasten og hverandre")
eq(nb:GetAttribute("clickbutton"), nil, "ingenting mangler: tasten gjør ingenting")

-- MotW og flask mangler (tier I): tasten trykker den første
local hit = ns.Medallion.State().hit
T.cursor = { "spell", 3, "spell", 5232 }
hit.scripts.OnReceiveDrag(hit)
T.counts[13510] = 3
T.cursor = { "item", 13510, "[Flask of the Titans]" }
hit.scripts.OnReceiveDrag(hit)
local b1, b2 = trR.buttons[1], trR.buttons[2]
check(b1.shown and b2.shown, "to knapper ute")
eq(nb:GetAttribute("clickbutton"), b1, "tasten trykker MotW")

-- I kamp: trykk MotW, så går tasten videre til flasken, og så til ingenting
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
SecureClick(b1, "LeftButton")
check(not b1.shown and nb:GetAttribute("clickbutton") == b2, "i kamp: MotW borte, tasten går til flasken")
SecureClick(b2, "LeftButton")
eq(nb:GetAttribute("clickbutton"), nil, "begge trykket: tasten gjør ingenting")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
eq(nb:GetAttribute("clickbutton"), trR.buttons[1], "etter kampen: tilbake til den første som står ute")

return n, fails
