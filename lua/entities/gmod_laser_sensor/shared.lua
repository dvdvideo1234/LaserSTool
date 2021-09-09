ENT.Type           = "anim"
ENT.PrintName      = "Laser Sensor"
ENT.Base           = LaserLib.GetClass(1)
if(WireLib) then
  ENT.WireDebugName = ENT.PrintName
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Category       = "Laser"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.Information    = ENT.PrintName

function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
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
  return self
end

function ENT:GetBeamLength()
  return self:GetInBeamLength()
end

function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  return self
end

function ENT:GetBeamWidth()
  return self:GetInBeamWidth()
end

function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetInDamageAmount(damage)
  return self
end

function ENT:GetDamageAmount()
  return self:GetInDamageAmount()
end

function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetInPushForce(force)
  return self
end

function ENT:GetPushForce()
  return self:GetInPushForce()
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end
