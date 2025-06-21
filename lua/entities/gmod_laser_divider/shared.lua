ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Divider"
ENT.Information    = ENT.Category.." "..ENT.PrintName
ENT.Base           = LaserLib.GetClass(1)
if(WireLib) then
  ENT.WireDebugName = ENT.Information
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 5

LaserLib.RegisterUnit(ENT, "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass")

local gnDOTM = LaserLib.GetData("DOTM")

function ENT:UpdateInternals()
  self.hitSize = 0 -- Add sources in array
  self.crHdx = 0 -- Current bean index
  return self
end

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("InPowerOn"    , "Internals")
  LaserLib.Configure(self)
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

-- Override the beam transformation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local surface normal
  self:SetNormalLocal(normal)
  return self
end

function ENT:InitSources()
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
    return self:GetNWVector("GetNormalLocal", normal)
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
  return (math.abs(normal:Dot(trace.HitNormal)) > (1 - gnDOTM))
end

function ENT:EveryBeam(entity, index, beam)
  if(not beam) then return end
  local trace = beam:GetTarget()
  if(trace and trace.Hit and self:IsHitNormal(trace)) then
    self:SetArrays(entity)
    local ref = LaserLib.GetReflected(beam.VrDirect, trace.HitNormal)
    if(CLIENT) then
      self:DrawBeam(entity, trace.HitPos, ref, beam)
      self:DrawBeam(entity, trace.HitPos, beam.VrDirect, beam)
    else
      self:DoDamage(self:DoBeam(entity, trace.HitPos, ref, beam))
      self:DoDamage(self:DoBeam(entity, trace.HitPos, beam.VrDirect, beam))
    end
  end -- Sources are located in the table hash part
end

function ENT:UpdateSources()
  self:UpdateInternals() -- Add sources in array
  self:ProcessSources()
  self:SetHitReportMax(self.crHdx)

  return self:UpdateArrays()
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * bmex > Source trace beam class
]]
function ENT:DoBeam(ent, org, dir, bmex)
  self.crHdx = self.crHdx + 1
  local todiv = (self:GetBeamReplicate() and 1 or 2)
  local beam = LaserLib.Beam(org, dir, bmex.NvLength)
        beam:SetLength(bmex.NvLength)
        beam:SetSource(self, ent, bmex:GetSource())
        beam:SetWidth(LaserLib.GetWidth(bmex.NvWidth / todiv))
        beam:SetDamage(bmex.NvDamage / todiv)
        beam:SetForce(bmex.NvForce  / todiv)
        beam:SetFgDivert( bmex.BrReflec, bmex.BrRefrac)
        beam:SetFgTexture(bmex.BmNoover, false)
        beam:SetBounces()
  if(not beam:IsValid() and SERVER) then
    beam:Clear(); self:Remove(); return end
  return beam:Run(self.crHdx)
end
