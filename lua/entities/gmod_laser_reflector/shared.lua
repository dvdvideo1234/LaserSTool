ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Reflector"
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
ENT.UnitID         = 3

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupDataTables()
  self:EditableSetFloat("InReflectRatio" , "General", 0, 1)
  LaserLib.SetClass(self,
    "models/madjawa/laser_reflector.mdl",
    "debug/env_cubemap_model")
  LaserLib.Configure(self)
end

function ENT:GetReflectRatio()
  if(SERVER) then
    local ratio = self:WireRead("Ratio", true)
    if(not ratio) then ratio = self:GetInReflectRatio() end
    self:SetNWFloat("GetInReflectRatio", ratio)
    self:WireWrite("Ratio", ratio)
    return ratio
  else
    local ratio = self:GetInReflectRatio()
    return self:GetNWFloat("GetInReflectRatio", ratio)
  end
end

function ENT:SetReflectRatio(ratio)
  local ratio = math.Clamp(tonumber(ratio) or 0, 0, 1)
  self:SetInReflectRatio(ratio)
  self:WireWrite("Ratio", ratio)
  return self
end
