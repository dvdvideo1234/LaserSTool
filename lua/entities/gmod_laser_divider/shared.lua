ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Divider"
ENT.Information    = ENT.Category.." "..ENT.PrintName
ENT.Base           = LaserLib.GetClass(1, 1)
if(WireLib) then
  ENT.WireDebugName = ENT.Information
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("InPowerOn"    , "Internals")
  LaserLib.ClearOrder(self)
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local surface normal
  self:SetNormalLocal(normal)
  return self
end

function ENT:InitSources()
  self.hitSize = 0
  if(SERVER) then
    self.hitSources = {} -- Sources in notation `[ent] = true`
    self:InitArrays("Array")
  else
    if(not self.hitSources) then
      self.hitSources = {} -- Sources in notation `[ent] = true`
      self:InitArrays("Array")
    end
  end
  return self
end

function ENT:GetHitNormal()
  if(SERVER) then
    local normal = self:WireRead("Normal", true)
    if(normal) then normal:Normalize() else
      normal = self:GetNormalLocal()
    end -- Make sure length is one unit
    self:SetNWVector("GetNormalLocal", normal)
    self:WireWrite("Normal", normal)
    return normal
  else
    local normal = self:GetNormalLocal()
    return self:GetNWFloat("GetNormalLocal", normal)
  end
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

function ENT:IsHitNormal(trace)
  local normal = Vector(self:GetHitNormal())
        normal:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  return (math.abs(normal:Dot(trace.HitNormal)) > (1 - dotm))
end

local hdx = 0

function ENT:EveryBeacon(entity, index, beam, trace)
  if(trace and trace.Hit and beam and self:IsHitNormal(trace)) then
    self:SetArrays(entity)
    local ref = LaserLib.GetReflected(beam.VrDirect, trace.HitNormal)
    if(CLIENT) then
      hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, ref, beam, hdx)
      hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, beam.VrDirect, beam, hdx)
    else
      hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, ref, beam, hdx))
      hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, beam.VrDirect, beam, hdx))
    end
  end -- Sources are located in the table hash part
end

function ENT:UpdateSources()
  hdx = 0; self.hitSize = 0 -- Add sources in array

  self:ProcessSources()
  self:SetHitReportMax(hdx)

  return self:UpdateArrays()
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * bmex > Source trace beam class
 * idx  > Index to store the result
]]
function ENT:DoBeam(ent, org, dir, bmex, idx)
  LaserLib.SetExSources(ent, bmex:GetSource())
  LaserLib.SetExLength(bmex.BmLength)
  local length = bmex.NvLength
  local usrfle = bmex.BrReflec
  local usrfre = bmex.BrRefrac
  local noverm = bmex.BmNoover
  local todiv  = (self:GetBeamReplicate() and 1 or 2)
  local damage = bmex.NvDamage / todiv
  local force  = bmex.NvForce  / todiv
  local width  = LaserLib.GetWidth(bmex.NvWidth / todiv)
  local beam, trace = LaserLib.DoBeam(self,
                                      org,
                                      dir,
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
