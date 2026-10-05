-- Rettelser etter kodegjennomgangen (5. okt): hver test gjenskaper en feil som fantes, og sjekker at den er borte.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

T.party = { party1 = "Brakk", party2 = "Mira" }
T.pa = { party1 = {}, party2 = {} }
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
local M = ns.Medallion
local st = M.State()
local A = ns.Alert
local function sounds() return A.sounds or 0 end
local function zone(z) T.zone = z Fire("ZONE_CHANGED_NEW_AREA") end

-- Party-køen: et kast i kamp som ikke gikk gjennom, flyttet knappen videre – og det ble stående etter kampen
T.cursor = { "spell", 3, "spell", 1126 }
ns.Actions.DropOn(true, 1)
local tb = ns.Tray.Get("left").buttons[1]
eq(tb:GetAttribute("unit"), "party1", "før kampen: Brakk")
T.combat, T.secret = true, true
Fire("PLAYER_REGEN_DISABLED")
SecureClick(tb, "LeftButton") -- kastet går ikke gjennom (ingen SUCCEEDED)
eq(tb:GetAttribute("unit"), "party2", "i kamp: videre til Mira")
T.combat, T.secret = false, false
Fire("PLAYER_REGEN_ENABLED")
check(tb:GetAttribute("unit") == "party1" and tb:GetAttribute("ks-qi") == 1, "etter kampen: tilbake til Brakk, køen fra start")

-- Flight master: lukke samtalen uten å fly skal ikke bruke opp varselet
T.counts[14529] = 0
T.cursor = { "item", 14529, "[Runecloth Bandage]" }
st.hit.scripts.OnReceiveDrag(st.hit)
zone("Stormwind City")
local s0 = sounds()
T.gossip = { { name = "I need a ride.", icon = 132057 } }
Fire("GOSSIP_SHOW")
eq(sounds(), s0 + 1, "snakker med flight master: varsel")
Fire("GOSSIP_CLOSED") -- går fra uten å fly
T.gossip = nil
zone("Elwynn Forest")
eq(sounds(), s0 + 2, "går ut porten etterpå: varsel igjen")
-- ... men flyr du, kommer det ikke to ganger
zone("Stormwind City")
T.gossip = { { name = "I need a ride.", icon = 132057 } }
Fire("GOSSIP_SHOW")
Fire("GOSSIP_CLOSED")
Fire("TAXIMAP_OPENED") -- kartet åpnes rett etter samtalen
T.onTaxi = true
Fire("TAXIMAP_CLOSED")
zone("Westfall")
eq(sounds(), s0 + 3, "flyr ut: bare ett varsel")
T.onTaxi, T.gossip = false, nil

-- Ved porten: kartet henger litt etter sonenavnet – avreisen skal ikke gå tapt
zone("Stormwind City")
local s1 = sounds()
T.maps = { [1453] = { name = "Stormwind City", mapType = 3 }, [1429] = { name = "Elwynn Forest", mapType = 3 } }
T.mapId = 1453
zone("Elwynn Forest")
eq(sounds(), s1, "kartet sier fortsatt Stormwind: ikke ennå")
T.mapId = 1429
Tick()
eq(sounds(), s1 + 1, "kartet er enig: varselet kommer")
-- Hearthstone rett fra et vertshus i byen
zone("Stormwind City")
T.mapId = 1453
zone("The Gilded Rose")
eq(sounds(), s1 + 1, "inn på vertshuset: ingen varsel")
T.mapId = 1429
T.zone = "Goldshire"
Tick()
eq(sounds(), s1 + 2, "hearthstone fra vertshuset: varsel")
T.maps, T.mapId = nil, nil

-- Ikke slippe på medaljongen i kamp
local before = #ControlCharDB.self
T.combat = true
T.cursor = { "spell", 3, "spell", 5232 }
st.hit.scripts.OnReceiveDrag(st.hit)
eq(#ControlCharDB.self, before, "i kamp: ingenting legges til")
T.combat, T.cursor = false, nil

-- Glidebryteren: kamp midt i et dra skal ikke la medaljongen henge i forhåndsvisningen
ns.Menu.SetOpen(true)
ns.Refresh(false)
local sl = ns.Menu.slider
sl.scripts.OnMouseDown(sl)
sl:SetValue(150)
eq(st.face.scale, 1.5, "drar: forhåndsvisning")
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
check(not sl.dragging and st.face.scale == 1, "kamp midt i: slutt å dra, tilbake til lagret størrelse")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")

-- Et navn bare én gang i lista over hvem som følges, også når klassen er ukjent
T.partyClass = { party1 = nil, party2 = "MAGE" }
local g = ControlCharDB.party[1]
g.onlyOn = { Brakk = true }
ns.Refresh(false)
local count = 0
for _, c in ipairs(ns.Menu.frame.children or {}) do if c.shown and c.text == "Brakk" then count = count + 1 end end
eq(count, 1, "Brakk står én gang")

-- Shift + dra: knappen du drar, beholder den dempede fargen også når menyen tegnes på nytt
local mb = ns.SideBar.Get("right")
ns.SideBar.SetOpen("right", true)
ns.Refresh(false)
local b = mb.buttons[1]
T.shift = true
b.scripts.OnDragStart(b)
ns.Refresh(false)
eq(b.alpha, 0.35, "drar: dempet")
mb.frame.mouse = true
b.scripts.OnDragStop(b)
mb.frame.mouse = false
T.shift = false
ns.Refresh(false)
eq(b.alpha, 1, "sluppet: vanlig igjen")

return n, fails
