-- Fase 8: byvakt og varsel (SPEC §10, §11). Akseptkriteriet: gå ut av Stormwind med 0 bandasjer:
-- rød tekst + lyd én gang. Pluss: flykart, ikke to ganger for samme avreise, oransje, grønn, kamp, uttoning.
local ns = NS
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end
local function eq(a, b, m) check(a == b, m .. ": fikk " .. tostring(a) .. ", ventet " .. tostring(b)) end

Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
local A = ns.Alert
local function zone(z) T.zone = z Fire("ZONE_CHANGED_NEW_AREA") end
local function sounds() return A.sounds or 0 end
eq(ns.CityWatch.Current(), "Stormwind City", "innlogget i Stormwind")
check(not (A.frame and A.frame.shown), "ingen varsel ved innlogging")

-- 0 bandasjer, tier I
T.counts[14529] = 0
T.cursor = { "item", 14529, "[Runecloth Bandage]" }
local hit = ns.Medallion.State().hit
hit.scripts.OnReceiveDrag(hit)
local band = ControlCharDB.self[1]
check(band and band.type == "item" and band.tier == 1, "bandasjer: lagerting, tier I")

-- Ut porten
zone("Elwynn Forest")
check(A.frame and A.frame.shown, "ut av Stormwind: varsel")
eq(A.title.text, "Du forlater Stormwind City", "hvor du drar fra")
check(A.main.text:find("Bandage", 1, true) and A.main.text:find("0/1", 1, true), "hva som mangler")
eq(A.sev, 2, "tomt: rødt")
eq(sounds(), 1, "én lyd")
eq(A.frame.mouseEnabled, false, "varselet tar ikke musa")
check(A.frame.width >= 240, "ramma har minst 240 px bredde")

-- Ikke to ganger for samme avreise; ikke fra et sted som ikke voktes
zone("Westfall")
eq(sounds(), 1, "Elwynn → Westfall: ingen nytt varsel")
zone("Elwynn Forest")
eq(sounds(), 1, "fortsatt ute: ingen nytt varsel")

-- Tilbake og ut igjen: nytt varsel
zone("Stormwind City")
zone("Elwynn Forest")
eq(sounds(), 2, "ny avreise: nytt varsel")

-- Flykartet: varsel før du flyr, ikke igjen når du forlater sonen
zone("Stormwind City")
Fire("TAXIMAP_OPENED")
eq(sounds(), 3, "flykart i Stormwind: varsel")
zone("Westfall")
eq(sounds(), 3, "flyr ut: ikke en gang til")
Fire("TAXIMAP_OPENED")
eq(sounds(), 3, "flykart et sted som ikke voktes: ingenting")

-- Flight master: varsel når samtalen åpnes, før «I need a ride» – og ikke igjen når kartet kommer
zone("Stormwind City")
T.gossip = { { name = "Can I buy something?", icon = 132060 } }
Fire("GOSSIP_SHOW")
eq(sounds(), 3, "vanlig samtale: ingen varsel")
T.gossip = { { name = "I need a ride.", icon = 132057, gossipOptionID = 1 } }
Fire("GOSSIP_SHOW")
eq(sounds(), 4, "flight master: varsel når samtalen åpnes")
check(ControlCharDB.debug.gossip.taxi and ControlCharDB.debug.gossip.options[1].icon == 132057, "samtalen lagres i debug")
Fire("TAXIMAP_OPENED")
eq(sounds(), 4, "kartet etterpå: ikke en gang til")
zone("Westfall")
eq(sounds(), 4, "flyr ut: ikke en gang til")
T.gossip = { { name = "Show me where I can fly." } }
zone("Stormwind City")
Fire("GOSSIP_SHOW")
eq(sounds(), 5, "kjennes også igjen på teksten alene")
zone("Westfall")
T.gossip = nil

-- Sonenavnet kan være tomt rett etter lasteskjermen (V8)
T.zone = ""
Fire("PLAYER_ENTERING_WORLD")
eq(ns.CityWatch.Current(), "Westfall", "tomt sonenavn ignoreres")

-- Oransje: under ønsket, ingen lyd
band.want = 5
T.counts[14529] = 2
zone("Ironforge")
zone("Dun Morogh")
eq(A.sev, 1, "under ønsket: oransje")
eq(A.title.text, "Du forlater Ironforge", "fra Ironforge")
eq(sounds(), 5, "oransje: ingen lyd")

-- Alt med: kort grønt, tones ut
T.counts[14529] = 5
zone("Ironforge")
zone("Dun Morogh")
check(A.sev == 0 and A.main.text:find("Alt med", 1, true), "alt med: grønt")
eq(sounds(), 5, "grønt: ingen lyd")
T.now = T.now + 2.5
A.frame.scripts.OnUpdate(A.frame)
check(A.frame.shown and A.frame.alpha < 1, "tones ut etter 2 s")
T.now = T.now + 2
A.frame.scripts.OnUpdate(A.frame)
check(not A.frame.shown, "borte")

-- I kamp: ingen nye tekster; varselet kommer når kampen er over
T.counts[14529] = 0
zone("Ironforge")
T.combat = true
Fire("PLAYER_REGEN_DISABLED")
zone("Dun Morogh")
check(not A.frame.shown, "i kamp: ikke vist ennå")
T.combat = false
Fire("PLAYER_REGEN_ENABLED")
check(A.frame.shown and A.sev == 2 and sounds() == 6, "etter kampen: varselet kommer")

-- Steder som ikke lenger voktes, varsles ikke
zone("Darnassus")
table.remove(ControlCharDB.cityWatch.cities, 3)
zone("Teldrassil")
eq(sounds(), 6, "Darnassus fjernet fra vakta: ingen varsel")

-- /control varsel: se varselet når som helst
SlashCmdList.CONTROL("varsel")
check(A.frame.shown and A.title.text == "Du forlater Teldrassil", "/control varsel viser varselet")

return n, fails
