-- Q10: lista fra den gamle Klar-sjekk (KlarsjekkDB per karakter) flyttes over som MB tier II, én gang.
local fails, n = {}, 0
local function check(c, m) n = n + 1 if not c then table.insert(fails, m) end end

-- Slik lå lista på Sommer 4. okt (her med items testklienten kjenner)
KlarsjekkDB = { list = {
  { kind = "item", id = 13510, need = 2 },     -- flask: gir en buff → buffting
  { kind = "item", id = 14529, need = 10 },    -- bandasje: lagerting
  { kind = "buff", id = 1126, min = 0 },       -- spell
  { kind = "gear", id = 18834 },               -- utstyr: finnes ikke i Control, hoppes over
  { kind = "item", id = 999999, need = 1 },    -- ukjent for klienten: hoppes over
} }
T.counts[13510], T.counts[14529] = 3, 4
Fire("ADDON_LOADED", "Control")
Fire("PLAYER_LOGIN")
local list = ControlCharDB.self
check(#list == 3, "tre av fem flyttet over: " .. #list)
check(list[1].type == "buffitem" and list[1].tier == 2 and list[1].want == 2, "flask: buffting, tier II, vil ha 2")
check(list[2].type == "item" and list[2].want == 10 and list[2].short == "Bandage", "bandasje: lagerting, vil ha 10")
check(list[3].type == "spell" and list[3].name == "Mark of the Wild", "Mark of the Wild: spell")
check(ControlCharDB.importedKlarsjekk == true and Chat("3 ting fra den gamle Klar-sjekk"), "sagt fra én gang")
check(#NS.view.tray.self == 0, "tier II står ikke ute ved medaljongen")
NS.Data.ImportKlarsjekk(ControlCharDB, KlarsjekkDB, NS.Core.Resolve)
check(#ControlCharDB.self == 3, "importeres bare én gang")
return n, fails
