ENT.meOrderInfo = {N = 0, T = {}}

function ENT:EditableSetVector(name, catg)
  local typ, ord, id = LaserLib.GetOrderID(self, "Vector")
  self:NetworkVar(typ, id, name, {
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

function ENT:EditableSetFloatCombo(name, catg, vals, key, ico, sek)
  local vas = LaserLib.ExtractVas(vals, key) -- Use provided
  local vco = LaserLib.ExtractIco(vals, ico)
  local typ, ord, id = LaserLib.GetOrderID(self, "Float")
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

function ENT:EditableSetIntCombo(name, catg, vals, key, ico, sek)
  local vas = LaserLib.ExtractVas(vals, key) -- Use provided
  local vco = LaserLib.ExtractIco(vals, ico)
  local typ, ord, id = LaserLib.GetOrderID(self, "Int")
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

function ENT:EditableSetStringCombo(name, catg, vals, key, ico, sek)
  local vas = LaserLib.ExtractVas(vals, key) -- Use provided
  local vco = LaserLib.ExtractIco(vals, ico)
  local typ, ord, id = LaserLib.GetOrderID(self, "String")
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
