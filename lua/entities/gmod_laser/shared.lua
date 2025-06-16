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
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 1

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

local gnCLMX     = LaserLib.GetData("CLMX")
local gnDOTM     = LaserLib.GetData("DOTM")
local gtAMAX     = LaserLib.GetData("AMAX")
local gvVDRUP    = LaserLib.GetData("VDRUP")
local gvVZERO    = LaserLib.GetData("VZERO")
local cvEFFECTDT = LaserLib.GetData("EFFECTDT")
local cvDAMAGEDT = LaserLib.GetData("DAMAGEDT")
local cvENSOUNDS = LaserLib.GetData("ENSOUNDS")

function ENT:SetupDataTables()
  LaserLib.SetPrimary(self)
  LaserLib.Configure(self)
end

function ENT:SetBeamTransform(tranData)
  if(tranData[2] and tranData[3]) then
    local orgn = (tranData[2] or gvVZERO)
    local dirc = (tranData[3] or gvVDRUP):GetNormalized()
    self:SetOriginLocal(orgn)
    self:SetDirectLocal(dirc)
  else
    local val = (tonumber(tranData[1]) or 0)
    local ang = math.Clamp(val, gtAMAX[1], gtAMAX[2])
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
  local dotv = math.abs(norm:Dot(beam.VrDirect))
  if(bmln) then dotv = 2 * math.asin(dotv) / math.pi end
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - gnDOTM)), dotv
end

--[[
 * Width. How wide does the beam appear when drawn
 * This is different than the trace width itself
 * This is often use for back-trace width when refracting
]]
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

--[[
 * Length. The total laser beam length to be traced
]]
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

--[[
 * Damage. How much damage does the laser do per tick
]]
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

--[[
 * Safety. Makes the beam acts like in the
 * portal series towards all players
]]
function ENT:SetBeamSafety(bool)
  local safe = tobool(bool)
  self:SetInBeamSafety(safe)
  return self
end

function ENT:GetBeamSafety()
  if(SERVER) then
    local safe = self:WireRead("Safety", true)
    if(safe ~= nil) then safe = tobool(safe)
    else safe = self:GetInBeamSafety() end
    self:SetNWBool("GetInBeamSafety", safe)
    self:WireWrite("Safety", (safe and 1 or 0))
    return safe
  else
    local safe = self:GetInBeamSafety()
    return self:GetNWBool("GetInBeamSafety", safe)
  end
end

--[[
 * Material. The actual material used drawing the beam
 * When `true` is passed will return a material object
]]
function ENT:SetBeamMaterial(mat)
  self:SetInBeamMaterial(mat)
  return self
end

function ENT:GetBeamMaterial(bool)
  local mat = self:GetInBeamMaterial()
  if(bool) then -- Material object requested
    local mac = self.roMaterial
    if(mac) then -- Material object. Compare materials
      if(mac:GetName() ~= mat) then -- Different mats
        mac = Material(mat) -- Update reference
        self.roMaterial = mac -- Store material
      end -- Material object is cached and updated
    else -- Missing. Populate cached material
      mac = Material(mat) -- Update reference
      self.roMaterial = mac -- Store material
    end; return mac -- Return mat object
  else -- Material object is not issued. Return the string
    return mat
  end
end

--[[
 * Sounds. Control the sounds the beam makes in various conditions
]]
function ENT:SetStartSound(snd)
  local snd = tostring(snd or "")
  if(self.startSound ~= snd) then
    self.startSound = Sound(snd)
  else
    self.startSound = snd
  end; return self
end

function ENT:GetStartSound()
  return (self.startSound or "")
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
  return (self.stopSound or "")
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
  return (self.killSound or "")
end

--[[
 * Makes laser to produce the actual sounds
]]
function ENT:DoSound(state)
  if(self.onState ~= state) then
    self.onState = state -- Write the state
    local pos, cls = self:GetPos(), self:GetClass()
    if(cls == LaserLib.GetClass(1) or cvENSOUNDS:GetBool()) then
      if(state) then -- Activating laser for given position
        self:EmitSound(self:GetStartSound())
      else -- User shuts the entity off
        self:EmitSound(self:GetStopSound())
      end -- Sound is calculated correctly
    end
  end; return self
end

--[[
 * On/Off. Toggle switch. Every unit must have one
]]
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

--[[
 * Force. Used for prop pushing when positive.
]]
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

--[[
 * Handling color setup and conversion
]]
function ENT:SetBeamColorRGBA(mr, mg, mb, ma)
  local r, g, b, a = LaserLib.GetColorRGBA(mr, mg, mb, ma)
  local v = Vector(r / gnCLMX, g / gnCLMX, b / gnCLMX)
  self:SetBeamColor(v) -- [0-1]
  self:SetBeamAlpha(a) -- [0-255]
end

function ENT:GetBeamColorRGBA(bcol)
  local v, a = self:GetBeamColor(), self:GetBeamAlpha()
  local r, g, b = (v.x * gnCLMX), (v.y * gnCLMX), (v.z * gnCLMX)
  if(bcol) then local c = self.roColor
    if(not c) then c = Color(0,0,0,0); self.roColor = c end
    c.r, c.g, c.b, c.a = r, g, b, a; return c
  else -- The user requests four numbers instead
    return r, g, b, a
  end
end

--[[
 * Beam uses the original material override
]]
function ENT:SetNonOverMater(bool)
  local over = tobool(bool)
  self:SetInNonOverMater(over)
  return self
end

function ENT:GetNonOverMater()
  return self:GetInNonOverMater()
end

function ENT:DoBeam(org, dir, idx)
  local origin = self:GetBeamOrigin(org)
  local direct = self:GetBeamDirection(dir)
  local length = self:GetBeamLength()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local noverm = self:GetNonOverMater()
  local beam   = LaserLib.Beam(origin, direct, length)
        beam:SetSource(self, self)
        beam:SetWidth(self:GetBeamWidth())
        beam:SetDamage(self:GetBeamDamage())
        beam:SetForce(self:GetBeamForce())
        beam:SetFgDivert(usrfle, usrfre)
        beam:SetFgTexture(noverm, false)
  if(not beam:IsValid()) then
    beam:Clear(); self:Remove(); return end
  local trace = beam:Run(idx)
  return beam, trace
end

function ENT:Setup(width      , length      , damage    , material   , dissolveType,
                   startSound , stopSound   , killSound , runToggle  , startOn     ,
                   pushForce  , endingEffect, tranData  , reflectRate, refractRate ,
                   forceCenter, enOverMater , enSafeBeam, rayColor   , update)
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
  self:SetBeamSafety(enSafeBeam)

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
    enSafeBeam   = enSafeBeam,
    tranData     = tranData,
    rayColor     = {r, g, b, a}
  })

  return self
end
