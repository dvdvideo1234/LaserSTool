ENT.Type           = "anim"
ENT.PrintName      = "Laser"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.PrintName
else
  ENT.Base          = "base_entity"
end
ENT.WireDebugName  = "Laser"
ENT.Author         = "MadJawa"
ENT.Information    = ""
ENT.Category       = ""
ENT.Spawnable      = false
ENT.AdminSpawnable = false

local gnSVF = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)
local varMaxBounces = CreateConVar("laseremitter_maxbounces", "5", gnSVF, "Maximum surface bounces for the laser beam", 0, 1000)

function ENT:Setup(width, length, damage, material, dissolveType, startSound, stopSound, killSound, toggle, startOn, pushProps, endingEffect, update)
  self:SetBeamWidth(width)
  self.defaultWidth = width
  self:SetBeamLength(length)
  self.defaultLength = length
  self:SetDamageAmmount(damage)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetToggle(toggle)
  if((not toggle and update) or (not update)) then self:SetOn(startOn) end
  self:SetPushProps(pushProps)
  self:SetEndingEffect(endingEffect)

  if(update) then
    local ttable   = {
      width        = width,
      length       = length,
      damage       = damage,
      material     = material,
      dissolveType = dissolveType,
      startSound   = startSound,
      stopSound    = stopSound,
      killSound    = killSound,
      toggle       = toggle,
      startOn      = startOn,
      pushProps    = pushProps,
      endingEffect = endingEffect
    }
    table.Merge(self:GetTable(), ttable)
  end
end

-- FIXME : find a way to dynamically get the laser unit vector according the angle offset of bad oriented models
function ENT:GetBeamDirection()
  local angleOffset = self:GetAngleOffset()
  if(angleOffset == 90) then return self:GetForward()
  elseif(angleOffset == 180) then return (-1 * self:GetUp())
  elseif(angleOffset == 270) then return (-1 * self:GetForward())
  else return self:GetUp() end
end

--[[ ----------------------
  Width
---------------------- ]]
function ENT:SetBeamWidth( num )
  local width = math.Clamp(num, 1, 100)
  self:SetNWInt("Width", width)
  if(WireLib) then
    WireLib.TriggerOutput(self, "Width", width)
  end
end

function ENT:GetBeamWidth()
  return self:GetNWInt("Width")
end

--[[ ----------------------
   Length
---------------------- ]]
function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetNWInt("Length", length)
  if(WireLib) then
    WireLib.TriggerOutput(self, "Length", length)
  end
end

function ENT:GetBeamLength()
  return self:GetNWInt("Length")
end

--[[ ----------------------
  Damage
---------------------- ]]
function ENT:SetDamageAmmount(num)
  local damage = math.Round(num)
  self:SetNWInt("Damage", damage)
  if(WireLib) then
    WireLib.TriggerOutput(self, "Damage", damage)
  end
end

function ENT:GetDamageAmmount()
  return self:GetNWInt("Damage")
end

--[[ ----------------------
     Model Offset
---------------------- ]]
function ENT:SetAngleOffset( offset )
  self:SetNWInt("AngleOffset", offset)
end

function ENT:GetAngleOffset()
  return self:GetNWInt("AngleOffset")
end

--[[ ----------------------
  Material
---------------------- ]]
function ENT:SetBeamMaterial(material)
  self:SetNWString("Material", material)
end

function ENT:GetBeamMaterial()
  return self:GetNWString("Material")
end

--[[ ----------------------
      Dissolve type
---------------------- ]]
function ENT:SetDissolveType( dissolvetype )
  self:SetNWString("DissolveType", dissolvetype)
end

function ENT:GetDissolveType()
  local dissolvetype = self:GetNWString("DissolveType")

  if(dissolvetype == "energy") then return 0
  elseif(dissolvetype == "lightelec") then return 2
  elseif(dissolvetype == "heavyelec") then return 1
  else return 3 end
end

--[[ ----------------------
          Sounds
---------------------- ]]
-- FIXME : Well, not really something to fix, but it seems that I can't set networked strings with a length higher than 39 (not ideal for sounds)
function ENT:SetStartSound(sound)
  self.startSound = sound
end

function ENT:GetStartSound()
  return self.startSound
end

function ENT:SetStopSound(sound)
  self.stopSound = sound
end

function ENT:GetStopSound()
  return self.stopSound
end

function ENT:SetKillSound(sound)
  self.killSound = sound
end

function ENT:GetKillSound()
  return self.killSound
end

--[[ ----------------------
  Toggle
---------------------- ]]
function ENT:SetToggle(bool)
  self:SetNWBool("Toggle", bool)
end

function ENT:GetToggle()
  return self:GetNWBool("Toggle")
end

--[[ ----------------------
  On/Off
---------------------- ]]
function ENT:SetOn(bool)
  if(bool ~= self:GetOn()) then
    if(bool) then
      self:EmitSound(Sound(self:GetStartSound()))
    else
      self:EmitSound(Sound(self:GetStopSound()))
    end
  end

  self:SetNWBool("On", bool)

  if(WireLib) then
    WireLib.TriggerOutput(self, "On", (bool and 1 or 0))
  end
end

function ENT:GetOn()
  return self:GetNWBool("On")
end

--[[ ----------------------
      Prop pushing
---------------------- ]]
function ENT:SetPushProps(bool)
  self:SetNWBool("PushProps", bool)
end

function ENT:GetPushProps()
  return self:GetNWBool("PushProps")
end

--[[ ----------------------
     Ending Effect
---------------------- ]]
function ENT:SetEndingEffect(bool)
  self:SetNWBool("EndingEffect", bool)
end

function ENT:GetEndingEffect()
  return self:GetNWBool("EndingEffect")
end
