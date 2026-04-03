--[[
 * Retrieves entity order settings for the given key
 * ent > Entity to register as primary laser source
]]
local function editableGetOrderID(ent, key)
  if(not key) then return end
  if(not IsValid(ent)) then return end
  local info = ent.meOrderInfo; if(not info) then return end
  local itab = info.T; if(itab[key]) then
    itab[key] = (itab[key] + 1) else itab[key] = 0 end
  info.N = (info.N + 1); return key, info.N, itab[key]
end

--[[
 * Extracts table value content from 2D set specified key
 * tab > Reference to a table of row tables (list.Get)
 * key > The key to be extracted (not mandatory)
]]
local function editableExtractCon(tab, key)
  if(not tab) then return tab end
  if(not key) then return tab end
  local set = {} -- Allocate
  for k, v in pairs(tab) do
    set[k] = v[key] -- Populate values
  end; return set -- Key-value pairs
end

-- https://wiki.facepunch.com/gmod/Silkicons
-- https://heyter.github.io/js-famfamfam-search/
local fmico = "icon16/%s.png"
local function editableGetIcon(icon)
  return fmico:format(tostring(icon or "accept"))
end

--[[
 * Extracts table icons from set specified key
 * tab > Reference to a table of row tables
 * key > The key to be extracted
 *   table  : convert all the values to icons
 *   direct : Translate 2:n to icon
 *   [key]  : Generate icons from row[key]
 * dir > Enable direct table mapping
]]
local function editableExtractIco(tab, key)
  if(not tab) then return end
  if(not key) then return end
  if(istable(key)) then
    for k, v in pairs(key) do
      key[k] = editableGetIcon(v)
    end; return key
  else
    if(key:sub(1, 1) == "#") then
      return editableGetIcon(key:sub(2, -1))
    else
      local set = {} -- Allocate
      for k, row in pairs(tab) do -- Populate values
        set[k] = editableGetIcon(row[key])
      end; return set -- Key-value pairs
    end -- Update icon with key table or string
  end
end

ENT.meOrderInfo = {N = 0, T = {}}

function ENT:EditableSetVector(name, catg)
  local typ, ord, id = editableGetOrderID(self, "Vector")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ
  }}); return self
end

function ENT:EditableSetVectorColor(name, catg)
  local typ, ord, id = editableGetOrderID(self, "Vector")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ.."Color"
    }}); return self
end

function ENT:EditableSetBool(name, catg)
  local typ, ord, id = editableGetOrderID(self, "Bool")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ
  }}); return self
end

function ENT:EditableSetFloat(name, catg, min, max)
  local typ, ord, id = editableGetOrderID(self, "Float")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ,
      min      = (tonumber(min) or -100),
      max      = (tonumber(max) or  100)
  }}); return self
end

function ENT:EditableSetFloatCombo(name, catg, vals, key, ico, sek)
  local vas = editableExtractCon(vals, key) -- Use provided
  local vco = editableExtractIco(vals, ico)
  local typ, ord, id = editableGetOrderID(self, "Float")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = "Combo",
      select   = sek,
      icons    = vco,
      values   = vas
  }}); return self
end

function ENT:EditableSetInt(name, catg, min, max)
  local typ, ord, id = editableGetOrderID(self, "Int")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ,
      min      = (tonumber(min) or -100),
      max      = (tonumber(max) or  100)
  }}); return self
end

function ENT:EditableSetIntCombo(name, catg, vals, key, ico, sek)
  local vas = editableExtractCon(vals, key) -- Use provided
  local vco = editableExtractIco(vals, ico)
  local typ, ord, id = editableGetOrderID(self, "Int")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = "Combo",
      select   = sek,
      icons    = vco,
      values   = vas
  }}); return self
end

function ENT:EditableSetStringGeneric(name, catg, enter)
  local typ, ord, id = editableGetOrderID(self, "String")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category     = catg,
      order        = ord,
      waitforenter = tobool(enter),
      type         = "Generic"
  }}); return self
end

function ENT:EditableSetStringCombo(name, catg, vals, key, ico, sek)
  local vas = editableExtractCon(vals, key) -- Use provided
  local vco = editableExtractIco(vals, ico)
  local typ, ord, id = editableGetOrderID(self, "String")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = "Combo",
      select   = sek,
      icons    = vco,
      values   = vas
  }}); return self
end
