ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
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
  self:EditableSetVector("UpwardLocal" , "General") -- Used as forward
  self:EditableSetBool("MirrorExitPos" , "General") -- Mirror the exit ray location
  self:EditableSetBool("ReflectExitDir", "General") -- Reflect the exit ray direction
  self:EditableSetBool("DrawTransfer", "General") -- Draw transfer overlay entity
  self:EditableSetStringGeneric("EntityExitID", "General", true)
  self:EditableRemoveOrderInfo()
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  self:SetNormalLocal(Vector(1,0,0)) -- Local surface normal
  self:SetUpwardLocal(Vector(0,0,1)) -- Local surface normal
  return self
end

function ENT:UpdateVectors()
  local mdt = LaserLib.GetData("DOTM")
  local fwd = self:GetNormalLocal()
  local upw = self:GetUpwardLocal()
  if(math.abs(fwd:Dot(upw)) >= mdt) then
    local rgh = fwd:Cross(upw)
    upw:Set(rgh:Cross(fwd))
    upw:Normalize()
    self:SetUpwardLocal(upw)
  end; return self
end

function ENT:ToCustomUCS(vec)
  local ret = Vector()
  local ox = self:GetNormalLocal()
  local oz = self:GetUpwardLocal()
  local ucs = ox:AngleEx(oz)
  local x = vec:Dot(ox)
  local z = vec:Dot(oz)
  local y = vec:Dot(ucs:Right())
  ret:SetUnpacked(x, -y, z)
  return ret, ucs
end

function ENT:IsHitNormal(trace)
  local dotm = LaserLib.GetData("DOTM")
  local norm = Vector(self:GetNormalLocal())
  if(norm:LengthSqr() < dotm) then return true end
  norm:Rotate(self:GetAngles())
  return (math.abs(norm:Dot(trace.HitNormal)) > (1 - dotm))
end

--[[
 * Converts the transit entity ID or entity itself
 * idx > Entiy ID to convert to transit
 * ent > Force entity outpout instead of string
]]
function ENT:GetTransitID(idx, ent)
  local idx = (tonumber(idx) or 0) -- Convert the number
  if(ent) then return ((idx ~= 0) and Entity(idx) or nil)
  else return ((idx ~= 0) and tostring(idx) or gsNA) end
end

function ENT:IsTrueExit(out) local ent
  if(out) then ent = out else -- Retrieve only when needed
    ent = self:GetTransitID(self:GetEntityExitID(), true) end
  if(not LaserLib.IsValid(ent)) then return false end
  if(self:GetModel() ~= ent:GetModel()) then return false end
  if(ent:IsWorld() or ent:IsPlayer() or
     ent:IsNPC()   or ent:IsWidget()) then return false end
  return true -- The output entity has been validated
end

function ENT:GetActiveExit(eid) local idx
  if(eid) then idx = eid else
    idx = self:GetEntityExitID() end
  local out = self:GetTransitID(idx, true)
  return (self:IsTrueExit(out) and out or nil)
end

function ENT:GetOverlayTransfer()
  local bas = self:GetTransitID(self:EntIndex())
  local txt = self:GetTransitID(self:GetEntityExitID())
  return ("["..bas.."] > ["..txt.."]")
end
