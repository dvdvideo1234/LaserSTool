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
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("InPowerOn"    , "Internals")
  self:EditableRemoveOrderInfo()
end

function ENT:RegisterSource(ent)
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

function ENT:UpdateSources()
  local hdx = 0; self.hitSize = 0 -- Add sources in array
  self:ProcessSources(function(entity, index, trace, data)
    if(trace and trace.Hit and data and self:IsHitNormal(trace)) then
      self:SetArrays(entity)
      local ref = LaserLib.GetReflected(data.VrDirect, trace.HitNormal)
      if(CLIENT) then
        hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, ref, data, hdx)
        hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, data.VrDirect, data, hdx)
      else
        hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, ref, data, hdx))
        hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, data.VrDirect, data, hdx))
      end
    end -- Sources are located in the table hash part
  end); self:RemHitReports(hdx)
  return self:UpdateArrays()
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * sdat > Source beam trace data
 * idx  > Index to store the result
]]
function ENT:DoBeam(ent, org, dir, sdat, idx)
  local length = sdat.NvLength
  local usrfle = sdat.BrReflec
  local usrfre = sdat.BrRefrac
  local noverm = sdat.BmNoover
  local todiv  = (self:GetBeamReplicate() and 1 or 2)
  local damage = sdat.NvDamage / todiv
  local force  = sdat.NvForce  / todiv
  local width  = LaserLib.GetWidth(sdat.NvWidth / todiv)
  local trace, data = LaserLib.DoBeam(self,
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
  return trace, ent:UpdateBeam(data, sdat)
end
