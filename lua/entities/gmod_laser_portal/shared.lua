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
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 9

LaserLib.RegisterUnit(ENT, "models/props_c17/frame002a.mdl", "models/props_combine/com_shield001a")

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

local gsNOAV = LaserLib.GetData("NOAV")
local gnDOTM = LaserLib.GetData("DOTM")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal" , "General") -- Used as forward
  self:EditableSetVector("UpwardLocal" , "General") -- Used as forward
  self:EditableSetBool("MirrorExitPos" , "General") -- Mirror the exit ray location
  self:EditableSetBool("ReflectExitDir", "General") -- Reflect the exit ray direction
  self:EditableSetBool("DrawTransfer", "General") -- Draw transfer overlay entity
  self:EditableSetStringGeneric("EntityExitID", "General", true)
  LaserLib.Configure(self)
end

-- Override the beam transformation
function ENT:SetBeamTransform()
  self:SetNormalLocal(Vector(1,0,0)) -- Local surface normal
  self:SetUpwardLocal(Vector(0,0,1)) -- Local surface normal
  return self
end

function ENT:UpdateVectors()
  local fwd = self:GetNormalLocal()
  local upw = self:GetUpwardLocal()
  if(not LaserLib.IsOrtho(fwd, upw)) then
    LaserLib.SetOrtho(fwd, upw, true)
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
  local norm = Vector(self:GetNormalLocal())
  if(norm:LengthSqr() < gnDOTM) then return true end
  norm:Rotate(self:GetAngles())
  return (math.abs(norm:Dot(trace.HitNormal)) > (1 - gnDOTM))
end

--[[
 * Converts the transit entity ID or entity itself
 * idx > Entity ID to convert to transit
 * ent > Force entity output instead of string
]]
function ENT:GetTransitID(idx, ent)
  local idx = (tonumber(idx) or 0) -- Convert the number
  if(ent) then return ((idx ~= 0) and Entity(idx) or nil)
  else return ((idx ~= 0) and tostring(idx) or gsNOAV) end
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
