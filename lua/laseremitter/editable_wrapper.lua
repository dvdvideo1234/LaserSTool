ENT.EditableOrderInfo = {N = 0, T = {}}

function ENT:EditableGetOrderID(key)
  local info = self.EditableOrderInfo
  if(not info.T[key]) then info.T[key] = 0
  else info.T[key] = info.T[key] + 1 end
  info.N = info.N + 1 -- Increment order
  return key, info.N, info.T[key]
end

function ENT:EditableRemoveOrderInfo()
  self.EditableOrderInfo = nil
  return self
end

function ENT:EditableSetVector(name, catg)
  local typ, ord, id = self:EditableGetOrderID("Vector")
  local a = self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ
    }}); return self
end

function ENT:EditableSetVectorColor(name, catg)
  local typ, ord, id = self:EditableGetOrderID("Vector")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ.."Color"
    }}); return self
end

function ENT:EditableSetBool(name, catg)
  local typ, ord, id = self:EditableGetOrderID("Bool")
  self:NetworkVar(typ, id, name, {
    KeyName = name:lower(),
    Edit = {
      category = catg,
      order    = ord,
      type     = typ
    }}); return self
end

function ENT:EditableSetFloat(name, catg, min, max)
  local typ, ord, id = self:EditableGetOrderID("Float")
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
  local typ, ord, id = self:EditableGetOrderID("Float")
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
  local typ, ord, id = self:EditableGetOrderID("Int")
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
  local typ, ord, id = self:EditableGetOrderID("Int")
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
  local typ, ord, id = self:EditableGetOrderID("String")
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
  local typ, ord, id = self:EditableGetOrderID("String")
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
