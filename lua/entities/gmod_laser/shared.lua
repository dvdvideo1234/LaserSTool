ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Emiter"
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
ENT.RenderGroup    = RENDERGROUP_OPAQUE

local EFFECTDT = LaserLib.GetData("EFFECTDT")
local DAMAGEDT = LaserLib.GetData("DAMAGEDT")

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/report_manager.lua")
include(LaserLib.GetTool().."/array_manager.lua")

function ENT:SetupDataTables()
  LaserLib.SetPrimary(self)
  LaserLib.ClearOrder(self)
end

function ENT:SetBeamTransform(tranData)
  if(tranData[2] and tranData[3]) then
    local diru = LaserLib.GetData("VDRUP")
    local zero = LaserLib.GetData("VZERO")
    local orgn = (tranData[2] or zero)
    local dirc = (tranData[3] or diru):GetNormalized()
    self:SetOriginLocal(orgn)
    self:SetDirectLocal(dirc)
  else
    local amx = LaserLib.GetData("AMAX")
    local val = (tonumber(tranData[1]) or 0)
    local ang = math.Clamp(val, amx[1], amx[2])
    local dir = LaserLib.GetBeamDirection(self, ang)
    local org = LaserLib.GetBeamOrigin(self, dir)
    self:SetOriginLocal(org)
    self:SetDirectLocal(dir)
  end; return self
end

function ENT:GetBeamOrigin(origin, nocnv)
  if(nocnv) then return Vector(origin) end
  return self:LocalToWorld(origin or self:GetOriginLocal())
end

function ENT:GetBeamDirection(direct, nocnv)
  if(nocnv) then return Vector(direct) end
  local dir = Vector(direct or self:GetDirectLocal())
        dir:Rotate(self:GetAngles())
  return dir
end

function ENT:GetHitPower(normal, beam, trace, bmln)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  local dotv = math.abs(norm:Dot(beam.VrDirect))
  if(bmln) then dotv = 2 * math.asin(dotv) / math.pi end
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - dotm)), dotv
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
function ENT:SetBeamDamage(num)
  local damage = math.max(num, 0)
  self:SetInBeamDamage(damage)
  return self
end

function ENT:GetBeamDamage()
  if(SERVER) then
    local damage = self:WireRead("Damage", true)
    if(damage ~= nil) then damage = math.max(damage, 0)
    else damage = self:GetInBeamDamage() end
    self:SetNWFloat("GetInBeamDamage", damage)
    self:WireWrite("Damage", damage)
    return damage
  else
    local damage = self:GetInBeamDamage()
    return self:GetNWFloat("GetInBeamDamage", damage)
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
  local mac = self.roMaterial
  local mat = self:GetInBeamMaterial()
  if(bool) then
    if(mac) then
      if(mac:GetName() ~= mat) then
        mac = Material(mat)
      end
    else mac = Material(mat) end
    self.roMaterial = mac; return mac
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
  Makes sounds
---------------------- ]]
function ENT:DoSound(state)
  if(self.onState ~= state) then
    self.onState = state -- Write the state
    local pos, enb = self:GetPos(), LaserLib.GetData("ENSOUNDS")
    local cls, mcs = self:GetClass(), LaserLib.GetClass(1, 1)
    if(cls == mcs or enb:GetBool()) then
      if(state) then -- Activating laser for given position
        self:EmitSound(self:GetStartSound())
      else -- User shuts the entity off
        self:EmitSound(self:GetStopSound())
      end -- Sound is calculated correctly
    end
  end; return self
end

--[[ ----------------------
  On/Off
---------------------- ]]
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
function ENT:SetBeamForce(num)
  local force = math.max(num, 0)
  self:SetInBeamForce(force)
  return self
end

function ENT:GetBeamForce()
  if(SERVER) then
    local force = self:WireRead("Force", true)
    if(force ~= nil) then force = math.max(force, 0)
    else force = self:GetInBeamForce() end
    self:SetNWFloat("GetInBeamForce", force)
    self:WireWrite("Force", force)
    return force
  else
    local force = self:GetInBeamForce()
    return self:GetNWFloat("GetInBeamForce", force)
  end
end

--[[ ----------------------
      Handling color setup and conversion
---------------------- ]]
function ENT:SetBeamColorRGBA(mr, mg, mb, ma)
  local m = LaserLib.GetData("CLMX")
  local v, a = Vector(), m
  if(istable(mr)) then
    v.x = ((mr[1] or mr["r"] or m) / m)
    v.y = ((mr[2] or mr["g"] or m) / m)
    v.z = ((mr[3] or mr["b"] or m) / m)
      a =  (mr[4] or mr["a"] or m)
  else
    v.x = ((mr or m) / m) -- [0-1]
    v.y = ((mg or m) / m) -- [0-1]
    v.z = ((mb or m) / m) -- [0-1]
      a =  (ma or m) -- [0-255]
  end
  self:SetBeamColor(v)
  self:SetBeamAlpha(a)
end

function ENT:GetBeamColorRGBA(bcol)
  local m = LaserLib.GetData("CLMX")
  local v = self:GetBeamColor()
  local a = self:GetBeamAlpha()
  local r, g, b = (v.x * m), (v.y * m), (v.z * m)
  if(bcol) then local c = self.roColor
    if(not c) then c = Color(0,0,0,0); self.roColor = c end
    c.r, c.g, c.b, c.a = r, g, b, a; return c
  else -- The user requests four numbers instead
    return r, g, b, a
  end
end

--[[
 * Effects draw handling decides whenever
 * the current tick has to draw the effects
 * Flag is automatically reset in every call
 * then becomes true when it meets requirements
]]
function ENT:UpdateFlags()
  local time = CurTime()

  self.isEffect = false -- Reset the frame effects
  if(not self.nxEffect or time > self.nxEffect) then
    local dt = EFFECTDT:GetFloat() -- Read configuration
    self.isEffect, self.nxEffect = true, time + dt
  end

  if(SERVER) then -- Damage exists only on the server
    self.isDamage = false -- Reset the frame damage
    if(not self.nxDamage or time > self.nxDamage) then
      local dt = DAMAGEDT:GetFloat() -- Read configuration
      self.isDamage, self.nxDamage = true, time + dt
    end
  end
end

--[[ ----------------------
  Beam uses the original mateial override
---------------------- ]]
function ENT:SetNonOverMater(bool)
  local over = tobool(bool)
  self:SetInNonOverMater(over)
  return self
end

function ENT:GetNonOverMater()
  return self:GetInNonOverMater()
end

function ENT:DoBeam(org, dir, idx)
  local force  = self:GetBeamForce()
  local width  = self:GetBeamWidth()
  local origin = self:GetBeamOrigin(org)
  local length = self:GetBeamLength()
  local damage = self:GetBeamDamage()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local direct = self:GetBeamDirection(dir)
  local noverm = self:GetNonOverMater()
  local beam, trace = LaserLib.DoBeam(self,
                                      origin,
                                      direct,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm,
                                      idx)
  return beam, trace
end

function ENT:Setup(width       , length     , damage     , material    ,
                   dissolveType, startSound , stopSound  , killSound   ,
                   runToggle   , startOn    , pushForce  , endingEffect, tranData,
                   reflectRate , refractRate, forceCenter, enOverMater , rayColor, update)
  self:SetBeamWidth(width)
  self:SetBeamLength(length)
  self:SetBeamDamage(damage)
  self:SetBeamForce(pushForce)
  -- These are not controlled by wire and are stored in the laser itself
  self:SetBeamColorRGBA(rayColor)
  self:SetForceCenter(forceCenter)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetEndingEffect(endingEffect)
  self:SetReflectRatio(reflectRate)
  self:SetRefractRatio(refractRate)
  self:SetNonOverMater(enOverMater)

  if(not update) then
    self:SetBeamTransform(tranData)
  end -- Update does not change transform

  if((not update) or
    (not runToggle and update))
  then self:SetOn(startOn) end

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
    runToggle    = runToggle,
    startOn      = startOn,
    pushForce    = pushForce,
    endingEffect = endingEffect,
    reflectRate  = reflectRate,
    refractRate  = refractRate,
    forceCenter  = forceCenter,
    enOverMater  = enOverMater,
    tranData     = tranData,
    rayColor     = {r, g, b, a}
  })

  return self
end

--[[
 * Checks for infinite loops when the source `ent`
 * is powered by other generators powered by `self`
 * self > The root of the tree propagated
 * ent  > The entity of the source checked
 * set  > Contains the already processed items
]]
function ENT:IsInfinite(ent, set)
  local set = (set or {}) -- Allocate passtrough entiti registration table
  if(LaserLib.IsValid(ent)) then -- Invalid entities cannot do infinite loops
    if(set[ent]) then return false end -- This has already been checked for infinite
    if(ent == self) then return true else set[ent] = true end -- Check and register
    if(LaserLib.IsBeam(ent) and ent.hitSources) then -- Can output neams and has sources
      for src, stat in pairs(ent.hitSources) do -- Other hits and we are in its sources
        if(LaserLib.IsValid(src)) then -- Crystal has been hit by other crystal
          if(src == self) then return true end -- Perforamance optimization
          if(LaserLib.IsBeam(src) and src.hitSources) then -- Class propagades the tree
            if(self:IsInfinite(src, set)) then return true end end
        end -- Cascadely propagate trough the crystal sources from `self`
      end; return false -- The entity does not persists in itself
    else return false end
  else return false end
end
