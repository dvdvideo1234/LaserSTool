--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]

ENT.Type           = "anim"
ENT.PrintName      = "Laser Crystal"
ENT.Base           = LaserLib.GetClass(1)
if(WireLib) then
  ENT.WireDebugName = ENT.PrintName
end
ENT.Author         = "MadJawa"
ENT.Category       = "Other"
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

function ENT:GetOn()
  if(SERVER) then
    local state = self:GetInPowerOn()
    self:SetNWBool("GetInPowerOn", state)
    self:WireWrite("On", (state and 1 or 0))
    return state
  else
    return self:GetNWBool("GetInPowerOn")
  end
end

function ENT:GetBeamLength()
  if(SERVER) then
    local length = self:GetInBeamLength()
    self:SetNWFloat("GetInBeamLength", length)
    self:WireWrite("Length", length)
    return length
  else
    return self:GetNWFloat("GetInBeamLength")
  end
end

function ENT:GetBeamWidth()
  if(SERVER) then
    local width = self:GetInBeamWidth()
    self:SetNWFloat("GetInBeamWidth", width)
    self:WireWrite("Width", width)
    return width
  else
    return self:GetNWFloat("GetInBeamWidth")
  end
end

function ENT:GetDamageAmount()
  if(SERVER) then
    local damage = self:GetInDamageAmount()
    self:SetNWFloat("GetInDamageAmount", damage)
    self:WireWrite("Damage", damage)
    return damage
  else
    return self:GetNWFloat("GetInDamageAmount")
  end
end

function ENT:GetPushForce()
  if(SERVER) then
    local force = self:GetInPushForce()
    self:SetNWBool("GetInPushForce", force)
    self:WireWrite("Force", force)
    return force
  else
    return self:GetNWBool("GetInPushForce")
  end
end
