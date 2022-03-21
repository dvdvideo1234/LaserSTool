ENT.meOrderInfo = {N = 0, T = {}}



function ENT:EditableSetVector(name, catg)
  local typ, ord, id = LaserLib.GetOrderID(self, "Vector")
  local a = self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ
    }}); return self
end

function ENT:EditableSetVectorColor(name, catg)
  local typ, ord, id = LaserLib.GetOrderID(self, "Vector")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ.."Color"
    }}); return self
end

function ENT:EditableSetBool(name, catg)
  local typ, ord, id = LaserLib.GetOrderID(self, "Bool")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ
    }}); return self
end

function ENT:EditableSetFloat(name, catg, min, max)
  local typ, ord, id = LaserLib.GetOrderID(self, "Float")
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

function ENT:EditableSetFloatCombo(name, catg, vals, key)
  local set = vals -- Use provided values unless a table
  local typ, ord, id = LaserLib.GetOrderID(self, "Float")
  if(key) then set = {} -- Allocate
    for k, v in pairs(vals) do
      set[k] = v[key] -- Populate values
    end -- Produce proper key-value pairs
  end -- When list value is a table
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = "Combo",
      values   = set
    }}); return self
end

function ENT:EditableSetInt(name, catg, min, max)
  local typ, ord, id = LaserLib.GetOrderID(self, "Int")
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

function ENT:EditableSetIntCombo(name, catg, vals, key)
  local set = vals -- Use provided values unless a table
  local typ, ord, id = LaserLib.GetOrderID(self, "Int")
  if(key) then set = {} -- Allocate
    for k, v in pairs(vals) do
      set[k] = v[key] -- Populate values
    end -- Produce proper key-value pairs
  end -- When list value is a table
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = "Combo",
      values   = set
    }}); return self
end

function ENT:EditableSetStringGeneric(name, catg, enter)
  local typ, ord, id = LaserLib.GetOrderID(self, "String")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category     = catg,
      order        = ord,
      waitforenter = tobool(enter),
      type         = "Generic"
    }}); return self
end

function ENT:EditableSetStringCombo(name, catg, vals, key)
  local set = vals -- Use provided values unless a table
  local typ, ord, id = LaserLib.GetOrderID(self, "String")
  if(key) then set = {} -- Allocate
    for k, v in pairs(vals) do
      set[k] = v[key] -- Populate values
    end -- Produce proper key-value pairs
  end -- When list value is a table
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = "Combo",
      values   = set
    }}); return self
end
