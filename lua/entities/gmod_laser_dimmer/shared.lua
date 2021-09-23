ENT.Type           = "anim"
ENT.PrintName      = "Laser Dimmer"
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
  local normal = Vector(0,0,1) -- Local surface direction
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
      table.Empty(self.hitFront)
      table.Empty(self.hitLevel)
      table.Empty(self.hitArray)
      table.Empty(self.hitIndex)
      table.Empty(self.hitSources)
    else
      self.hitFront   = {} -- Array for surface hit normal
      self.hitLevel   = {} -- Array for product coefficients
      self.hitArray   = {} -- Array to output for wiremod
      self.hitIndex   = {} -- Array of the first index hit
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

function ENT:GetHitPower(trace, data)
  local normal = Vector(self:GetHitNormal())
        normal:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  local dotv = math.abs(normal:Dot(data.VrDirect))
  local dott = math.abs(normal:Dot(trace.HitNormal))
  return dotv, (dott > (1 - dotm))
end

function ENT:UpdateSources()
  local hdx = 0; self.hitSize = 0 -- Add sources in array
  self:ProcessSources(function(entity, index, trace, data)
    local mdot, bdot = self:GetHitPower(trace, data)
    if(trace and trace.Hit and data and bdot) then
      if(self.hitArray[self.hitSize] ~= entity) then
        local hitSize = self.hitSize + 1
        self.hitArray[hitSize] = entity -- Store source
        if(SERVER) then
          self.hitIndex[hitSize] = index -- Store index
          self.hitLevel[hitSize] = mdot -- Store source
          self.hitFront[hitSize] = (bdot and 1 or 0)
        end
        self.hitSize = hitSize
      end
      if(CLIENT) then
        hdx = hdx + 1; self:DrawBeam(entity, trace.HitPos, data.VrDirect, data, mdot, hdx)
      else
        hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, trace.HitPos, data.VrDirect, data, mdot, hdx))
      end
    end -- Sources are located in the table hash part
  end); self:RemHitReports(hdx)

  return self:UpdateArrays("hitArray", "hitLevel", "hitFront", "hitIndex")
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * sdat > Source beam trace data
 * idx  > Index to store the result
]]
function ENT:DoBeam(ent, org, dir, sdat, mdot, idx)
  local length = sdat.NvLength
  local usrfle = sdat.BrReflec
  local usrfre = sdat.BrRefrac
  local noverm = sdat.BmNoover
  local damage = sdat.NvDamage * mdot
  local force  = sdat.NvForce  * mdot
  local width  = LaserLib.GetWidth(sdat.NvWidth * mdot)
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
