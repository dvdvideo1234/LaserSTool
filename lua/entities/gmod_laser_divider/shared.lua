ENT.Type           = "anim"
ENT.PrintName      = "Laser Divider"
ENT.Base           = LaserLib.GetClass(1, 1)
if(WireLib) then
  ENT.WireDebugName = ENT.PrintName
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Category       = "Laser"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.Information    = ENT.PrintName

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
  if(CLIENT) then
    if(not self.hitSources) then
      self.hitArray   = {} -- Array to output for wiremod
      self.hitSources = {} -- Sources in notation `[ent] = true`
    end
  else
    if(self.hitSources) then
      table.Empty(self.hitSources)
      table.Empty(self.hitArray)
    else
      self.hitArray   = {} -- Array to output for wiremod
      self.hitSources = {} -- Sources in notation `[ent] = true`
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
  self.hitSize = 0 -- Add sources in array
  self:ProcessSources(function(entity, index, trace, data)
    if(trace and trace.Hit and data and self:IsHitNormal(trace)) then
      self.hitSize = self.hitSize + 1 -- Point to next slot
      self.hitArray[self.hitSize] = entity -- Store source
    end -- Sources are located in the table hash part
  end); return self:UpdateArrays("hitArray")
end

--[[
 * Divides the input sources beams and calculates the kit reports
]]
function ENT:ManageSources()
  if(self.hitSize and self.hitSize > 0) then local hdx = 0
    self:ProcessSources(function(entity, index, trace, data)
      if(trace and trace.Hit and data and self:IsHitNormal(trace)) then -- Do same stuff here
        local ref = LaserLib.GetReflected(data.VrDirect, trace.HitNormal)
        if(CLIENT) then
          hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, ref, data, hdx)
          hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, data.VrDirect, data, hdx)
        else
          hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, ref, data, hdx))
          hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, data.VrDirect, data, hdx))
        end
      end
    end) -- Check the rest of the beams and add power
  self:RemHitReports(hdx)
  end; return self
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
  if(LaserLib.IsUnit(ent, 2)) then
    data.BmSource = ent -- Initial stage store laser
  else -- Make sure we always know which laser is source
    data.BmSource = sdat.BmSource -- Inherit previous laser
  end -- Otherwise inherit the laser source from prev stage
  return trace, data
end
