ENT.Type           = "anim"
ENT.Category       = "Laser"
ENT.PrintName      = "Portal"
ENT.Information    = ENT.Category.." "..ENT.PrintName
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.Information
else
  ENT.Base          = "base_entity"
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal" , "General") -- Used as forward
  self:EditableSetBool("MirrorExitPos" , "General") -- Mirror the exit ray location
  self:EditableSetBool("ReflectExitDir", "General") -- Reflect the exit ray direction
  self:EditableSetStringGeneric("EntityExitID", "General", true)
  self:EditableRemoveOrderInfo()
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(1,0,0) -- Local surface normal
  self:SetNormalLocal(normal)
  return self
end

function ENT:IsHitNormal(trace)
  local normal = Vector(self:GetHitNormal())
        normal:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  return (math.abs(normal:Dot(trace.HitNormal)) > (1 - dotm))
end
