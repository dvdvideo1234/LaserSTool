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

local gsNA = LaserLib.GetData("NOAV")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal" , "General") -- Used as forward
  self:EditableSetBool("MirrorExitPos" , "General") -- Mirror the exit ray location
  self:EditableSetBool("ReflectExitDir", "General") -- Reflect the exit ray direction
  self:EditableSetBool("DrawTransfer", "General") -- Draw transfer overlay entity
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

--[[
 * Converts the transit entity ID or entity itself
 * idx > Entiy ID to convert to transit
 * ent > Force entity outpout instead of string
]]
function ENT:GetTransitID(idx, ent)
  local idx = (tonumber(idx) or 0)
  if(ent) then
    return ((idx ~= 0) and Entity(idx) or nil)
  else
    return ((idx ~= 0) and tostring(idx) or gsNA)
  end
end

function ENT:GetCorrectExit()
  local idx = self:GetEntityExitID()
  local out = self:GetTransitID(idx, true)
  if(not LaserLib.IsValid(out)) then return end
  if(self:GetModel() ~= out:GetModel()) then return end
  if(out:IsWorld() or out:IsPlayer() or out:IsNPC()) then return end
  return out -- When successfull returns the valid transit entity
end

function ENT:GetOverlayTransfer()
  local bas = self:GetTransitID(self:EntIndex())
  local txt = self:GetTransitID(self:GetEntityExitID())
  return ("["..bas.."] > ["..txt.."]")
end
