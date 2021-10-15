ENT.Type           = "anim"
ENT.Category       = "Laser"
ENT.PrintName      = "Parallel"
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
  local amax = LaserLib.GetData("AMAX")
  self:EditableSetVector("NormalLocal", "General") -- Used as forward
  self:EditableSetBool  ("BeamDimmer" , "General")
  self:EditableSetBool  ("InPowerOn"  , "Internals")
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
      table.Empty(self.hitArray)
      table.Empty(self.hitSources)
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

function ENT:UpdateSources()
  local hdx = 0; self.hitSize = 0 -- Add sources in array
  self:ProcessSources(function(entity, index, trace, data)
    local bdot, mdot = self:GetHitPower(self:GetHitNormal(), trace, data)
    if(trace and trace.Hit and data and bdot) then
      if(self.hitArray[self.hitSize] ~= entity) then
        local hitSize = self.hitSize + 1
        self.hitArray[hitSize] = entity -- Store source
        self.hitSize = hitSize
      end
      local dir = Vector(trace.HitNormal)
      local vdot = (self:GetBeamDimmer() and mdot or 1)
      local pos = trace.HitPos; LaserLib.VecNegate(dir)
      if(CLIENT) then
        hdx = hdx + 1; self:DrawBeam(entity, pos, dir, data, vdot, hdx)
      else
        hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, pos, dir, data, vdot, hdx))
      end
    end -- Sources are located in the table hash part
  end); self:RemHitReports(hdx)

  return self:UpdateArrays("hitArray")
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * sdat > Source beam trace data
 * idx  > Index to store the result
]]
function ENT:DoBeam(ent, org, dir, sdat, vdot, idx)
  local length = sdat.NvLength
  local usrfle = sdat.BrReflec
  local usrfre = sdat.BrRefrac
  local noverm = sdat.BmNoover
  local damage = sdat.NvDamage * vdot
  local force  = sdat.NvForce  * vdot
  local width  = LaserLib.GetWidth(sdat.NvWidth * vdot)
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