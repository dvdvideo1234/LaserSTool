ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Parallel"
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
  local amax = LaserLib.GetData("AMAX")
  self:EditableSetVector("NormalLocal", "General") -- Used as forward
  self:EditableSetBool  ("BeamDimmer" , "General")
  self:EditableSetBool  ("LinearMapping", "General")
  self:EditableSetBool  ("InPowerOn"  , "Internals")
  self:EditableRemoveOrderInfo()
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local surface direction
  self:SetNormalLocal(normal)
  return self
end

function ENT:GetHitNormal()
  if(SERVER) then
    local normal = self:WireRead("Normal", true)
    if(normal) then normal:Normalize() else
      normal = self:GetNormalLocal()
    end -- Make sure length is one unit
    self:SetNWVector("GetNormalLocal", normal)
    self:WireWrite("Normal", normal)
    return normal
  else
    local normal = self:GetNormalLocal()
    return self:GetNWFloat("GetNormalLocal", normal)
  end
end

function ENT:GetHitPower(normal, trace, data, bmln)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  local dotv = math.abs(norm:Dot(data.VrDirect))
  if(bmln) then dotv = 2 * math.asin(dotv) / math.pi end
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - dotm)), dotv
end

