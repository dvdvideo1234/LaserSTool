ENT.Type           = "anim"
ENT.PrintName      = "Laser"
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.PrintName
else
  ENT.Base          = "base_entity"
end
ENT.Editable       = true
ENT.Author         = "MadJawa"
ENT.Category       = ""
ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.Information    = ENT.PrintName

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupDataTables()
  self:EditableSetVector("OriginLocal"   , "General")
  self:EditableSetVector("DirectLocal"   , "General")
  self:EditableSetFloat ("AngleOffset"   , "General", -360, 360)
  self:EditableSetBool  ("StartToggle"   , "General")
  self:EditableSetBool  ("ForceCenter"   , "General")
  self:EditableSetBool  ("ReflectRatio"  , "Material")
  self:EditableSetBool  ("RefractRatio"  , "Material")
  self:EditableSetBool  ("InPowerOn"     , "Internals")
  self:EditableSetFloat ("InBeamWidth"   , "Internals", 0, 30)
  self:EditableSetFloat ("InBeamLength"  , "Internals", 0, 50000)
  self:EditableSetFloat ("InDamageAmount", "Internals", 0, 5000)
  self:EditableSetFloat ("InPushForce"   , "Internals", 0, 50000)
  self:EditableSetComboString("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetComboString("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
end

function ENT:SetBeamTransform()
  local angle  = self:GetAngleOffset()
  local direct = LaserLib.GetBeamDirection(self, angle)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  return self
end

function ENT:GetBeamOrigin(origin)
  return self:LocalToWorld(origin or self:GetOriginLocal())
end

function ENT:GetBeamDirection(direct)
  local dir = Vector(direct or self:GetDirectLocal())
        dir:Rotate(self:GetAngles())
  return dir
end

--[[ ----------------------
  Width
---------------------- ]]
function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  return self
end

function ENT:GetBeamWidth()
  if(SERVER) then
    local width = self:WireRead("Width", true)
    if(width ~= nil) then width = math.max(width, 0)
    else width = self:GetInBeamWidth() end
    self:SetNWFloat("GetInBeamWidth", width)
    self:WireWrite("Width", width)
    return width
  else
    local width = self:GetInBeamWidth()
    return self:GetNWFloat("GetInBeamWidth", width)
  end
end

--[[ ----------------------
   Length
---------------------- ]]
function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetInBeamLength(length)
  return self
end

function ENT:GetBeamLength()
  if(SERVER) then
    local length = self:WireRead("Length", true)
    if(length ~= nil) then length = math.abs(length)
    else length = self:GetInBeamLength() end
    self:SetNWFloat("GetInBeamLength", length)
    self:WireWrite("Length", length)
    return length
  else
    local length = self:GetInBeamLength()
    return self:GetNWFloat("GetInBeamLength", length)
  end
end

--[[ ----------------------
  Damage
---------------------- ]]
function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetInDamageAmount(damage)
  return self
end

function ENT:GetDamageAmount()
  if(SERVER) then
    local damage = self:WireRead("Damage", true)
    if(damage ~= nil) then damage = math.max(damage, 0)
    else damage = self:GetInDamageAmount() end
    self:SetNWFloat("GetInDamageAmount", damage)
    self:WireWrite("Damage", damage)
    return damage
  else
    local damage = self:GetInDamageAmount()
    return self:GetNWFloat("GetInDamageAmount", damage)
  end
end

--[[ ----------------------
  Material
---------------------- ]]
function ENT:SetBeamMaterial(mat)
  self:SetInBeamMaterial(mat)
  return self
end

function ENT:GetBeamMaterial(bool)
  local mat = self:GetInBeamMaterial()
  if(bool) then
    if(self.materCached) then
      if(self.materCached:GetName() ~= mat) then
        self.materCached = Material(mat)
      end
    else
      self.materCached = Material(mat)
    end
    return self.materCached
  else
    return mat
  end
end

--[[ ----------------------
          Sounds
---------------------- ]]
function ENT:SetStartSound(snd)
  local snd = tostring(snd or "")
  if(self.startSound ~= snd) then
    self.startSound = Sound(snd)
  else
    self.startSound = snd
  end; return self
end

function ENT:GetStartSound()
  return self.startSound
end

function ENT:SetStopSound(snd)
  local snd = tostring(snd or "")
  if(self.stopSound ~= snd) then
    self.stopSound = Sound(snd)
  else
    self.stopSound = snd
  end; return self
end

function ENT:GetStopSound()
  return self.stopSound
end

function ENT:SetKillSound(snd)
  local snd = tostring(snd or "")
  if(self.killSound ~= snd) then
    self.killSound = Sound(snd)
  else
    self.killSound = snd
  end; return self
end

function ENT:GetKillSound()
  return self.killSound
end

--[[ ----------------------
  On/Off
---------------------- ]]
function ENT:DoSound(state)
  if(self.OnState ~= state) then
    self.OnState = state -- Write the state
    if(state) then -- Activating laser
      self:EmitSound(self:GetStartSound())
    else -- User shuts the entity off
      self:EmitSound(self:GetStopSound())
    end -- Sound is calculated correctly
  end; return self
end

function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
  return self
end

function ENT:GetOn()
  if(SERVER) then
    local state = self:WireRead("On", true)
    if(state ~= nil) then state = (state ~= 0)
    else state = self:GetInPowerOn() end
    self:SetNWBool("GetInPowerOn", state)
    self:WireWrite("On", (state and 1 or 0))
    self:DoSound(state)
    return state
  else
    local state = self:GetInPowerOn()
    return self:GetNWBool("GetInPowerOn", state)
  end
end

--[[ ----------------------
      Prop pushing
---------------------- ]]
function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetInPushForce(force)
  return self
end

function ENT:GetPushForce()
  if(SERVER) then
    local force = self:WireRead("Force", true)
    if(force ~= nil) then force = math.max(force, 0)
    else force = self:GetInPushForce() end
    self:SetNWFloat("GetInPushForce", force)
    self:WireWrite("Force", force)
    return force
  else
    local force = self:GetInPushForce()
    return self:GetNWFloat("GetInPushForce", force)
  end
end

function ENT:Setup(width       , length     , damage     , material    ,
                   dissolveType, startSound , stopSound  , killSound   ,
                   toggle      , startOn    , pushForce  , endingEffect,
                   reflectRate , refractRate, forceCenter, enOnverMater, update)
  self:SetBeamWidth(width)
  self:SetBeamLength(length)
  self:SetDamageAmount(damage)
  self:SetPushForce(pushForce)
  -- These are not controlled by wire and are stored in the laser itself
  self:SetBeamColor(Vector(1,1,1))
  self:SetForceCenter(forceCenter)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetStartToggle(toggle)
  self:SetEndingEffect(endingEffect)
  self:SetReflectRatio(reflectRate)
  self:SetRefractRatio(refractRate)
  self:SetInNonOverMater(enOnverMater)
  self:SetBeamTransform()

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
    forceCenter  = forceCenter,
    enOnverMater = enOnverMater
  })

  if((not update) or
    (not toggle and update))
  then self:SetOn(startOn) end

  return self
end
