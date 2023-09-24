ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Dimmer"
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
ENT.UnitID         = 7

LaserLib.RegisterUnit(ENT, "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass")

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

local gnDOTM = LaserLib.GetData("DOTM")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("LinearMapping", "General")
  LaserLib.Configure(self)
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
    return self:GetNWVector("GetNormalLocal", normal)
  end
end

function ENT:GetHitPower(normal, beam, trace, bmln)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dotv = math.abs(norm:Dot(beam.VrDirect))
  if(bmln) then dotv = 2 * math.asin(dotv) / math.pi end
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - gnDOTM)), dotv
end
