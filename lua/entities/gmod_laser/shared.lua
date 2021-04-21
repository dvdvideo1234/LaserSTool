ENT.Type           = "anim"
ENT.PrintName      = "Laser"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.PrintName
else
  ENT.Base          = "base_entity"
end
ENT.Author         = "MadJawa"
ENT.Category       = ""
ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.Information    = ENT.PrintName

function ENT:GetBeamDirection()
  local aos = self:GetAngleOffset()
  if    (aos ==  90) then return self:GetForward()
  elseif(aos == 180) then return (-1 * self:GetUp())
  elseif(aos == 270) then return (-1 * self:GetForward())
  else return self:GetUp() end
end

function ENT:SetupBeamOrigin()
  local direct = self:GetBeamDirection()
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetNWVector("Origin", origin); return self
end

function ENT:Setup(width       , length    , damage   , material    ,
                   dissolveType, startSound, stopSound, killSound   ,
                   toggle      , startOn   , pushProps, endingEffect,
                   reflectRate)
  self:SetBeamWidth(width)
  self.defaultWidth = width
  self:SetBeamLength(length)
  self.defaultLength = length
  self:SetDamageAmount(damage)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetToggle(toggle)
  self:SetPushProps(pushProps)
  self:SetEndingEffect(endingEffect)
  self:SetReflectionRate(reflectRate)
  self:SetupBeamOrigin()

  table.Merge(self:GetTable(), {
    width        = width,
    model        = model,
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
    endingEffect = endingEffect,
    reflectRate  = reflectRate
  })

  if((not update) or
    (not toggle and update))
  then self:SetOn(startOn) end

  return self
end

function ENT:GetBeamOrigin()
  return self:LocalToWorld(self:GetNWVector("Origin"))
end

--[[ ----------------------
  Width
---------------------- ]]
function ENT:SetBeamWidth(num)
  local width = LaserLib.GetBeamWidth(num)
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
function ENT:SetDamageAmount(num)
  local damage = math.abs(num)
  self:SetNWInt("Damage", damage)
  if(WireLib) then
    WireLib.TriggerOutput(self, "Damage", damage)
  end
end

function ENT:GetDamageAmount()
  return self:GetNWInt("Damage")
end

--[[ ----------------------
     Model Offset
---------------------- ]]
function ENT:SetAngleOffset(offset)
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
function ENT:SetDissolveType(dissolvetype)
  self:SetNWString("DissolveType", dissolvetype)
end

function ENT:GetDissolveType()
  return LaserLib.GetDissolveType(self:GetNWString("DissolveType"))
end

--[[ ----------------------
          Sounds
---------------------- ]]
function ENT:SetStartSound(snd)
  self.startSound = tostring(snd or "")
end

function ENT:GetStartSound()
  return self.startSound
end

function ENT:SetStopSound(snd)
  self.stopSound = tostring(snd or "")
end

function ENT:GetStopSound()
  return self.stopSound
end

function ENT:SetKillSound(snd)
  self.killSound = tostring(snd or "")
end

function ENT:GetKillSound()
  return self.killSound
end

--[[ ----------------------
  Toggle
---------------------- ]]
function ENT:SetToggle(bool)
  local togg = tobool(bool)
  self:SetNWBool("Toggle", togg)
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
function ENT:SetPushProps(num)
  self:SetNWFloat("PushProps", num)
end

function ENT:GetPushProps()
  return self:GetNWFloat("PushProps")
end

--[[ ----------------------
     Ending Effect
---------------------- ]]
function ENT:SetEndingEffect(bool)
  local eeff = tobool(bool)
  self:SetNWBool("EndingEffect", eeff)
end

function ENT:GetEndingEffect()
  return self:GetNWBool("EndingEffect")
end

--[[ ----------------------
  Surface reflect efficiency
---------------------- ]]
function ENT:SetReflectionRate(bool)
  local reff = tobool(bool)
  self:SetNWBool("ReflectRate", reff)
end

function ENT:GetReflectionRate()
  return self:GetNWBool("ReflectRate")
end
