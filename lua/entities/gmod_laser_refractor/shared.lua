ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Refractor"
ENT.Information    = ENT.Category.." "..ENT.PrintName
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.Information
else
  ENT.Base          = "base_entity"
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 12

LaserLib.RegisterUnit(ENT, "models/madjawa/laser_reflector.mdl", "models/props_combine/health_charger_glass")

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupDataTables()
  self:EditableSetBool ("ZeroIndexMode" , "General")
  self:EditableSetBool ("ZeroRatioMode" , "General")
  self:EditableSetBool ("HitSurfaceMode", "General")
  self:EditableSetFloat("InRefractIndex", "General", -25, 25)
  self:EditableSetFloat("InRefractRatio", "General",   0,  1)
  LaserLib.Configure(self)
end

function ENT:GetRefractIndex()
  if(SERVER) then
    local index = self:WireRead("Index", true)
    if(not index) then index = self:GetInRefractIndex() end
    self:SetNWFloat("GetInRefractIndex", index)
    self:WireWrite("Index", index)
    return index
  else
    local index = self:GetInRefractIndex()
    return self:GetNWFloat("GetInRefractIndex", index)
  end
end

function ENT:SetRefractIndex(index)
  local index = math.Clamp(tonumber(index) or 0, -25, 25)
  self:SetInRefractIndex(index)
  self:WireWrite("Index", index)
  return self
end

function ENT:GetRefractRatio()
  if(SERVER) then
    local ratio = self:WireRead("Ratio", true)
    if(not ratio) then ratio = self:GetInRefractRatio() end
    self:SetNWFloat("GetInRefractRatio", ratio)
    self:WireWrite("Ratio", ratio)
    return ratio
  else
    local ratio = self:GetInRefractRatio()
    return self:GetNWFloat("GetInRefractRatio", ratio)
  end
end

function ENT:SetRefractRatio(ratio)
  local ratio = math.Clamp(tonumber(ratio) or 0, 0, 1)
  self:SetInRefractRatio(ratio)
  self:WireWrite("Ratio", ratio)
  return self
end

function ENT:GetRefractInfo(refract)
  local cpy = table.Copy(refract)
  local idx = self:GetRefractIndex()
  local rat = self:GetRefractRatio()
  -- Pick refractive index. Make zero available
  if(self:GetZeroIndexMode()) then cpy[1] = idx
  else cpy[1] = ((idx ~= 0) and idx or refract[1]) end
  -- Pick refractive ratio. Make zero available
  if(self:GetZeroRatioMode()) then cpy[2] = rat
  else cpy[2] = ((rat  > 0) and rat or refract[2]) end
  return cpy -- Return modified row copy
end
