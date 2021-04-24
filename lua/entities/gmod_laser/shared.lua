ENT.Type           = "anim"
ENT.PrintName      = "Laser"
if(WireLib) then
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

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

function ENT:SetupBeamTransform()
  local angle  = self:GetAngleOffset()
  local direct = LaserLib.GetBeamDirection(self, angle)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetNWVector("Origin", origin)
  self:SetNWVector("Direct", direct); return self
end

function ENT:GetBeamOrigin()
  return self:LocalToWorld(self:GetNWVector("Origin"))
end

function ENT:GetBeamDirection()
  local direct = Vector(self:GetNWVector("Direct"))
        direct:Rotate(self:GetAngles())
  return direct
end

--[[ ----------------------
  Width
---------------------- ]]
function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetNWInt("Width", width)
  self:WireWrite("Width", width)
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
  self:WireWrite("Length", length)
end

function ENT:GetBeamLength()
  return self:GetNWInt("Length")
end

--[[ ----------------------
  Damage
---------------------- ]]
function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetNWInt("Damage", damage)
  self:WireWrite("Damage", damage)
end

function ENT:GetDamageAmount()
  return self:GetNWInt("Damage")
end

--[[ ----------------------
     Model Offset
---------------------- ]]
function ENT:SetAngleOffset(angle)
  self:SetNWInt("AngleOffset", angle)
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
      Dissolve type. Write string! Read number!
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
  self:SetNWBool("Toggle", tobool(bool))
end

function ENT:GetToggle()
  return self:GetNWBool("Toggle")
end

--[[ ----------------------
  On/Off
---------------------- ]]
function ENT:SetOn(bool)
  local state = tobool(bool)
  if(state ~= self:GetOn()) then
    if(state) then
      self:EmitSound(Sound(self:GetStartSound()))
    else
      self:EmitSound(Sound(self:GetStopSound()))
    end
  end

  self:SetNWBool("On", state)
  self:WireWrite("On", (state and 1 or 0))
end

function ENT:GetOn()
  return self:GetNWBool("On")
end

--[[ ----------------------
      Prop pushing
---------------------- ]]
function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetNWFloat("PushForce", force)
  self:WireWrite("Force", force)
end

function ENT:GetPushForce()
  return self:GetNWFloat("PushForce")
end

--[[ ----------------------
     Ending Effect
---------------------- ]]
function ENT:SetEndingEffect(bool)
  self:SetNWBool("EndingEffect", tobool(bool))
end

function ENT:GetEndingEffect()
  return self:GetNWBool("EndingEffect")
end

--[[ ----------------------
  Surface reflect efficiency
---------------------- ]]
function ENT:SetReflectionRate(bool)
  self:SetNWBool("ReflectRate", tobool(bool))
end

function ENT:GetReflectionRate()
  return self:GetNWBool("ReflectRate")
end

--[[ ----------------------
  Surface reflect efficiency
---------------------- ]]
function ENT:SetRefractionRate(bool)
  self:SetNWBool("RefractRate", tobool(bool))
end

function ENT:GetRefractionRate()
  return self:GetNWBool("RefractRate")
end

--[[ ----------------------
  Surface reflect efficiency
---------------------- ]]
function ENT:SetForceCenter(bool)
  self:SetNWBool("ForceCenter", tobool(bool))
end

function ENT:GetForceCenter()
  return self:GetNWBool("ForceCenter")
end

function ENT:Setup(width       , length     , damage     , material    ,
                   dissolveType, startSound , stopSound  , killSound   ,
                   toggle      , startOn    , pushForce  , endingEffect,
                   reflectRate , refractRate, forceCenter, update)
  self:SetBeamWidth(width)
  self.defaultWidth = width -- Used when wire is disconnected
  self:SetBeamLength(length)
  self.defaultLength = length -- Used when wire is disconnected
  self:SetDamageAmount(damage)
  self.defaultDamage = damage -- Used when wire is disconnected
  self:SetPushForce(pushForce)
  self.defaultForce = pushForce -- Used when wire is disconnected

  -- These are not controlled by wire and are stored in the laser itself
  self:SetForceCenter(forceCenter)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetToggle(toggle)
  self:SetEndingEffect(endingEffect)
  self:SetReflectionRate(reflectRate)
  self:SetRefractionRate(refractRate)
  self:SetupBeamTransform()

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
    pushForce    = pushForce,
    endingEffect = endingEffect,
    reflectRate  = reflectRate,
    refractRate  = refractRate,
    forceCenter  = forceCenter
  })

  if((not update) or
    (not toggle and update))
  then self:SetOn(startOn) end

  return self
end
