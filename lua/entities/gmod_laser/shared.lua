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

function ENT:SetupDataTables()
  self:NetworkVar("Vector", 0, "OriginLocal"   , {KeyName = "originlocal"   , Edit = {category = "General"  , order = 1 , type = "Vector"}})
  self:NetworkVar("Vector", 1, "DirectLocal"   , {KeyName = "directlocal"   , Edit = {category = "General"  , order = 2 , type = "Vector"}})
  self:NetworkVar("Float" , 0, "AngleOffset"   , {KeyName = "angleoffset"   , Edit = {category = "General"  , order = 3 , type = "Float", min = -180, max = 180}})
  self:NetworkVar("Bool"  , 0, "StartToggle"   , {KeyName = "starttoggle"   , Edit = {category = "General"  , order = 4 , type = "Bool"}})
  self:NetworkVar("Bool"  , 1, "ForceCenter"   , {KeyName = "forcecenter"   , Edit = {category = "General"  , order = 5 , type = "Bool"}})
  self:NetworkVar("Bool"  , 2, "ReflectRatio"  , {KeyName = "reflectrate"   , Edit = {category = "Material" , order = 6 , type = "Bool"}})
  self:NetworkVar("Bool"  , 3, "RefractRatio"  , {KeyName = "refractrate"   , Edit = {category = "Material" , order = 7 , type = "Bool"}})
  self:NetworkVar("Bool"  , 4, "InPowerOn"     , {KeyName = "inpoweron"     , Edit = {category = "Internals", order = 8 , type = "Bool"}})
  self:NetworkVar("Float" , 1, "InBeamWidth"   , {KeyName = "inbeamwidth"   , Edit = {category = "Internals", order = 9 , type = "Float", min = 0, max = 30}})
  self:NetworkVar("Float" , 2, "InBeamLength"  , {KeyName = "inbeamlength"  , Edit = {category = "Internals", order = 10 , type = "Float", min = 0, max = 50000}})
  self:NetworkVar("Float" , 3, "InDamageAmount", {KeyName = "indamageamount", Edit = {category = "Internals", order = 11, type = "Float", min = 0, max = 5000}})
  self:NetworkVar("Float" , 4, "InPushForce"   , {KeyName = "inpushforce"   , Edit = {category = "Internals", order = 12 , type = "Float", min = 0, max = 50000}})
  self:NetworkVar("String", 0, "InBeamMaterial", {KeyName = "inbeammaterial", Edit = {category = "Internals", order = 13, type = "Combo", values = list.GetForEdit("LaserEmitterMaterials")}})
  self:NetworkVar("Bool"  , 5, "EndingEffect"  , {KeyName = "endingeffect"  , Edit = {category = "Visuals"  , order = 14, type = "Bool"}})
  self:NetworkVar("Vector", 2, "BeamColor"     , {KeyName = "beamcolor"     , Edit = {category = "Visuals"  , order = 15, type = "VectorColor"}})
  local val = {}; for k, v in pairs(list.GetForEdit("LaserDissolveTypes")) do val[k] = v.name end
  self:NetworkVar("String", 1, "DissolveType"  , {KeyName = "dissolvetype"  , Edit = {category = "Visuals"  , order = 16, type = "Combo", values = val}})
end

function ENT:SetBeamTransform()
  local angle  = self:GetAngleOffset()
  local direct = LaserLib.GetBeamDirection(self, angle)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  return self
end

function ENT:GetBeamOrigin()
  return self:LocalToWorld(self:GetOriginLocal())
end

function ENT:GetBeamDirection()
  local direct = Vector(self:GetDirectLocal())
        direct:Rotate(self:GetAngles())
  return direct
end

--[[ ----------------------
  Width
---------------------- ]]
function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  self:WireWrite("Width", width)
  return self
end

function ENT:GetBeamWidth()
  return self:GetInBeamWidth()
end

--[[ ----------------------
   Length
---------------------- ]]
function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetInBeamLength(length)
  self:WireWrite("Length", length)
  return self
end

function ENT:GetBeamLength()
  return self:GetInBeamLength()
end

--[[ ----------------------
  Damage
---------------------- ]]
function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetInDamageAmount(damage)
  self:WireWrite("Damage", damage)
  return self
end

function ENT:GetDamageAmount()
  return self:GetInDamageAmount()
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
function ENT:SetOn(bool)
  local state = tobool(bool)
  if(state ~= self:GetOn()) then
    if(state) then
      self:EmitSound(self:GetStartSound())
    else
      self:EmitSound(self:GetStopSound())
    end
  end

  self:SetInPowerOn(state)
  self:WireWrite("On", (state and 1 or 0))
  return self
end

function ENT:GetOn()
  return self:GetInPowerOn()
end

--[[ ----------------------
      Prop pushing
---------------------- ]]
function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetInPushForce(force)
  self:WireWrite("Force", force)
  return self
end

function ENT:GetPushForce()
  return self:GetInPushForce()
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
    forceCenter  = forceCenter
  })

  if((not update) or
    (not toggle and update))
  then self:SetOn(startOn) end

  return self
end
