-- Gift, våpenoljer og slipesteiner (Daniel 5. okt: «den må med»): knappen legger dem på våpenet, teller ned fra
-- det spillet sier om våpenet, og har en egen knapp for annen hånd når du har et våpen der.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

-- Instant Poison: bruk-effekt, tooltipen nevner våpenet
T.itemNames[6947] = "Instant Poison"
T.itemSpells[6947] = { "Instant Poison", 8679 }
T.itemClass[6947] = { 0, 0 }
T.tooltips[6947] = { "Instant Poison", "Use: Coats a weapon with poison that lasts for 30 minutes." }
T.spellNames[8679] = "Instant Poison"
T.counts[6947] = 12
T.itemClass[1001] = { 2, 0 } -- dolk i annen hånd
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local st = ns.Medallion.State()
local tray = ns.Tray.Get("right")

-- Slipp giften på medaljongen: hovedhånda
T.cursor = { "item", 6947, "[Instant Poison]" }
st.hit.scripts.OnReceiveDrag(st.hit)
local mh = ControlCharDB.self[1]
check(mh and mh.type == "buffitem" and mh.weaponSlot == 16 and mh.castName == "Instant Poison", "gift: buffting på hovedhånda")
check(#mh.auraNames == 0, "leses fra våpenet, ikke fra auraene")
local b = tray.buttons[1]
check(b and b.shown and b.glowing, "ingen gift på våpenet: står ute og lyser")
check(b:GetAttribute("type") == "macro" and b:GetAttribute("macrotext") == "/use item:6947\n/use 16", "knappen: bruk giften, så hovedhånda")
eq(b.hand.text, "MH", "MH i hjørnet")
b.scripts.hookOnEnter(b)
local hasLine = false
for _, l in ipairs(T.tooltip.lines) do if l == "Klikk: på hovedhånda" then hasLine = true end end
check(hasLine, "tooltip: Klikk: på hovedhånda")

-- Uten våpen i annen hånd: samme gift en gang til er et duplikat
T.cursor = { "item", 6947, "[Instant Poison]" }
st.hit.scripts.OnReceiveDrag(st.hit)
check(#ControlCharDB.self == 1 and Chat("er allerede med"), "uten våpen i annen hånd: ikke to ganger")
-- Med en dolk i annen hånd: egen knapp for den
T.equip = { [17] = 1001 }
T.cursor = { "item", 6947, "[Instant Poison]" }
ns.Actions.DropOn(false, 1)
local oh = ControlCharDB.self[2]
check(oh and oh.weaponSlot == 17, "dolk i annen hånd: egen knapp for annen hånd")

-- Klikk: kastet bekreftes, og så sier spillet at hovedhånda har gift i 30 min
b.scripts.hookPreClick(b, "LeftButton")
Fire("UNIT_SPELLCAST_SENT", "player", "", "w1", 8679)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "w1", 8679)
check(ns.Track.Pending() == nil, "bruken er bekreftet")
T.wench = { mh = 1800 * 1000 }
ns.Refresh(true)
local s = ns.model.st[mh.id]
check(s.status == "on" and math.abs(s.left - 1800) < 1, "hovedhånda: på, 30 min igjen")
eq(ns.model.st[oh.id].status, "missing", "annen hånd: mangler fortsatt")
eq(ControlCharDB.durations["weapon:Instant Poison"], 1800, "varigheten huskes")

-- Snart ute: under 40 s
T.wench = { mh = 30 * 1000, oh = 1800 * 1000 }
ns.Refresh(true)
eq(ns.model.st[mh.id].status, "expiring", "30 s igjen: snart ute")

-- I kamp (hemmelig): teller ned fra det vi visste
T.wench = { mh = 1000 * 1000, oh = 1800 * 1000 }
ns.Refresh(true)
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
T.now = T.now + 100
Tick()
s = ns.model.st[mh.id]
check(s.status == "on" and math.abs(s.left - 900) < 1, "i kamp: teller ned fra det vi visste (900 s)")
T.combat, T.secret = false, false
Fire("PLAYER_REGEN_ENABLED")

-- Byvakt: tom for gift i tier I = rødt
T.counts[6947] = 0
ns.Refresh(false)
local d = ns.Rules.departure(ns.db.self, ns.model.st, ns.L, {})
check(d.sev == 2, "tom for gift: rødt i byvakta")

-- Debug: våpenet tas med i målingen
SlashCmdList.CONTROL("debug")
local run = ControlCharDB.debug.runs[#ControlCharDB.debug.runs]
check(run.vitals.weapon and run.vitals.weapon.hasMH == true, "debug: våpenet er med i målingen")

return n, fails
