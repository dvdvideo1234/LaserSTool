ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Crystal"
ENT.Information    = ENT.Category.." "..ENT.PrintName
ENT.Base           = LaserLib.GetClass(1)
if(WireLib) then
  ENT.WireDebugName = ENT.Information
end
ENT.Author         = "DVD"
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 2

LaserLib.RegisterUnit(ENT, "models/props_c17/pottery02a.mdl", "models/dog/eyeglass")

function ENT:SetupDataTables()
  LaserLib.SetPrimary(self)
  self:EditableSetBool("BeamColorMerge","Visuals")
  LaserLib.Configure(self)
end

-- Override the beam transformation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local Direction
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  return self
end

function ENT:GetOn()
  local state = self:GetInPowerOn()
  if(SERVER) then self:DoSound(state) end
  return state
end

function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
  self:WireWrite("On", (state and 1 or 0))
  return self
end

--[[
 * Length. Produced beam length
]]
function ENT:GetBeamLength()
  return self:GetInBeamLength()
end

function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetInBeamLength(length)
  self:WireWrite("Length", length)
  return self
end

--[[
 * Width. Produced beam width
]]
function ENT:GetBeamWidth()
  return self:GetInBeamWidth()
end

function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  self:WireWrite("Width", width)
  return self
end

--[[
 * Damage. Produced beam damage
]]
function ENT:GetBeamDamage()
  return self:GetInBeamDamage()
end

function ENT:SetBeamDamage(num)
  local damage = math.max(num, 0)
  self:SetInBeamDamage(damage)
  self:WireWrite("Damage", damage)
  return self
end

--[[
 * Force. Produced beam force
]]
function ENT:GetBeamForce()
  return self:GetInBeamForce()
end

function ENT:SetBeamForce(num)
  local force = math.max(num, 0)
  self:SetInBeamForce(force)
  self:WireWrite("Force", force)
  return self
end

--[[
 * Safety. Makes the beam acts like in the
 * portal series towards all players
]]
function ENT:GetBeamSafety()
  return self:GetInBeamSafety()
end

function ENT:SetBeamSafety(bool)
  local safe = tobool(bool)
  self:SetInBeamSafety(safe)
  self:WireWrite("Safety", (safe and 1 or 0))
  return self
end

