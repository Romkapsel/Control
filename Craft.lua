-- Control: «Lag selv» (Daniel 5. okt). Når et yrkesvindu er åpent, leses oppskriftene (hva de lager, hvor mange per
-- gang, og hva som trengs) og huskes per karakter i db.recipes. Tooltipen på en ting som er under ønsket antall,
-- viser da hva som trengs for å komme opp på grønt – ikke for 1 – og hva du har av hver ting.
-- To utgaver av spillets yrkes-API: classic (GetNumTradeSkills …) og den nye (C_TradeSkillUI). Den som finnes, brukes;
-- db.debug.craft sier hvilken det ble og hvor mange oppskrifter som ble lest.
local addonName, ns = ...

local Craft = {}
ns.Craft = Craft

local function idOf(link)
  if type(link) ~= "string" then return nil end
  return tonumber(link:match("item:(%d+)"))
end

-- Classic: bare radene som er synlige i vinduet (sammenfelte grupper hoppes over), så vi legger til, aldri sletter
local function readClassic(out)
  local okN, n = pcall(GetNumTradeSkills)
  if not okN or type(n) ~= "number" then return 0 end
  local read = 0
  for i = 1, n do
    local okI, name, kind = pcall(GetTradeSkillInfo, i)
    if okI and name and kind ~= "header" and kind ~= "subheader" then
      local okL, link = pcall(GetTradeSkillItemLink, i)
      local item = okL and idOf(link)
      if item then
        local okM, made = pcall(GetTradeSkillNumMade, i)
        local okR, nr = pcall(GetTradeSkillNumReagents, i)
        local r = {}
        for k = 1, (okR and type(nr) == "number") and nr or 0 do
          local okA, rname, _, count = pcall(GetTradeSkillReagentInfo, i, k)
          local okB, rlink = pcall(GetTradeSkillReagentItemLink, i, k)
          local rid = okB and idOf(rlink)
          if okA and rid and type(count) == "number" then r[#r + 1] = { id = rid, n = count, name = rname } end
        end
        if #r > 0 then
          out[item] = { made = (okM and type(made) == "number" and made > 0) and made or 1, r = r, name = name }
          read = read + 1
        end
      end
    end
  end
  return read
end

-- Ny API: alle lærte oppskrifter, med vanlige (basic) ingredienser
local function readModern(out)
  local T = C_TradeSkillUI
  local okA, ids = pcall(T.GetAllRecipeIDs)
  if not okA or type(ids) ~= "table" then return 0 end
  local read = 0
  for _, rid in ipairs(ids) do
    local okI, info = pcall(T.GetRecipeInfo, rid)
    if okI and type(info) == "table" and info.learned then
      local okS, s = pcall(T.GetRecipeSchematic, rid, false)
      if okS and type(s) == "table" and s.outputItemID then
        local r = {}
        for _, slot in ipairs(s.reagentSlotSchematics or {}) do
          local first = slot.reagents and slot.reagents[1]
          if first and first.itemID and (slot.reagentType == nil or slot.reagentType == 1) then
            r[#r + 1] = { id = first.itemID, n = slot.quantityRequired or 1 }
          end
        end
        if #r > 0 then
          out[s.outputItemID] = { made = (s.quantityMin and s.quantityMin > 0) and s.quantityMin or 1, r = r, name = info.name }
          read = read + 1
        end
      end
    end
  end
  return read
end

-- Les det yrkesvinduet viser nå (kalles når det åpnes og når lista endres)
function Craft.Read(db)
  db.recipes = db.recipes or {}
  local api, read = "ingen", 0
  if GetNumTradeSkills then
    api, read = "classic", readClassic(db.recipes)
  elseif C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
    api, read = "ny", readModern(db.recipes)
  end
  db.debug = db.debug or {}
  db.debug.craft = { at = date and date("%Y-%m-%d %H:%M:%S") or nil, api = api, read = read }
  return read
end

-- Hva trengs for å komme opp på grønt? nil hvis tingen ikke kan lages, eller ikke mangler.
-- { times = ganger, gets = så mange til, parts = { { id, name, need, have } }, ok = har alt }
function Craft.Plan(db, e, have)
  local rec = e.itemId and db.recipes and db.recipes[e.itemId]
  if not rec then return nil end
  local missing = (e.want or 1) - (have or 0)
  if missing <= 0 then return nil end
  local times = math.ceil(missing / (rec.made or 1))
  local parts, ok = {}, true
  for _, x in ipairs(rec.r) do
    local need = x.n * times
    local got = ns.Scan.ItemCount(x.id) or 0
    local name = (ns.Scan.ItemInfo(x.id)) or x.name or ("#" .. x.id)
    if got < need then ok = false end
    parts[#parts + 1] = { id = x.id, name = name, need = need, have = got }
  end
  return { times = times, gets = times * (rec.made or 1), parts = parts, ok = ok }
end
