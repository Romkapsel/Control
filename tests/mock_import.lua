-- Ting som ligger på lista med feil type, rettes ved innlogging (en potion som ble lagt inn som buffting før 4. okt).
-- (Importen fra den gamle Klar-sjekk er droppet, Daniel 4. okt.)
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end

ControlCharDB = { self = {
  { id = "e9", type = "buffitem", itemId = 13446, name = "Major Healing Potion", tier = 1, want = 3,
    castName = "Healing Potion", auraNames = { "Healing Potion" }, short = "Healing" },
  { id = "e10", type = "item", itemId = 13510, name = "Flask of the Titans", tier = 2, want = 1, short = "Flask" },
}, nextId = 10 }
KlarsjekkDB = { list = { { kind = "item", id = 14529, need = 10 } } } -- den gamle lista skal ikke røres
T.counts[13446], T.counts[13510] = 2, 1
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local all = ControlCharDB.self
check(all[1].type == "item" and all[1].auraNames == nil and all[1].want == 3, "potionen som var buffting, er rettet til lagerting")
check(all[2].type == "buffitem" and all[2].castName == "Flask of the Titans" and all[2].auraNames[1] == "Flask of the Titans",
  "flasken som var lagerting, er rettet til buffting")
check(#all == 2 and not ControlCharDB.importedKlarsjekk, "ingen import fra den gamle Klar-sjekk")
return n, fails
