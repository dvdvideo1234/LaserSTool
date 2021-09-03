ENT.Type           = "anim"
ENT.PrintName      = "Laser Crystal"
ENT.Base           = LaserLib.GetClass(1)
if(WireLib) then
  ENT.WireDebugName = ENT.PrintName
end
ENT.Author         = "MadJawa"
ENT.Category       = "Laser"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.Information    = ENT.PrintName

-- Override the beam transormation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local Direction
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  return self
end

function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
  self:WireWrite("On", (state and 1 or 0))
  return self
end

function ENT:GetOn()
  local state = self:GetInPowerOn()
  if(SERVER) then self:DoSound(state) end
  return state
end

function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetInBeamLength(length)
  self:WireWrite("Length", length)
  return self
end

function ENT:GetBeamLength()
  return self:GetInBeamLength()
end

function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  self:WireWrite("Width", width)
  return self
end

function ENT:GetBeamWidth()
  return self:GetInBeamWidth()
end

function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetInDamageAmount(damage)
  self:WireWrite("Damage", damage)
  return self
end

function ENT:GetDamageAmount()
  return self:GetInDamageAmount()
end

function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetInPushForce(force)
  self:WireWrite("Force", force)
  return self
end

function ENT:GetPushForce()
  return self:GetInPushForce()
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end
