ENT.Type           = "anim"
ENT.PrintName      = "Laser Divider"
ENT.Base           = LaserLib.GetClass(1)
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
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local normal direction
  self:SetNormalLocal(normal)
  return self
end

function ENT:InitSources()
  if(CLIENT) then
    if(not self.hitSources) then
      self.hitSize    = 0
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

function ENT:GetBeamNormal()
  if(SERVER) then
    local norm = self:WireRead("Normal", true)
    if(norm) then norm:Normalize() else
      norm = self:GetNormalLocal()
    end -- Make sure length is one unit
    self:SetNWVector("GetNormalLocal", norm)
    self:WireWrite("Normal", norm)
    return norm
  else
    local norm = self:GetNormalLocal()
    return self:GetNWFloat("GetNormalLocal", norm)
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
  local norm = Vector(self:GetBeamNormal())
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  return (math.abs(norm:Dot(trace.HitNormal)) > (1 - dotm))
end

function ENT:UpdateSources()
  self.hitSize = 0 -- Add sources in array
  for ent, stat in pairs(self.hitSources) do
    local idx = self:GetHitSourceID(ent)
    if(idx) then
      local trace, data = ent:GetHitReport(idx)
      if(trace and self:IsHitNormal(trace)) then
        self.hitSize = self.hitSize + 1 -- Point to next slot
        self.hitArray[self.hitSize] = ent -- Store source
      else self.hitSources[ent] = nil end
    else self.hitSources[ent] = nil end -- The sources order does not matter
  end
  local cnt = (self.hitSize + 1) -- Remove the residuals
  while(self.hitArray[cnt]) do -- Table end check
    self.hitArray[cnt] = nil -- Wipe cirrent item
    cnt = (cnt + 1) -- Wipe the rest until empty
  end; return self -- Sources are located in the table hash part
end

function ENT:GetHitDominant(ent)
  if(self.hitSize and self.hitSize > 0) then
    local opower, doment = 0, nil
    for idx = 1, self:GetHitReports().Size do
      local trace, data = self:GetHitReport(idx)
      if(trace and trace.Hit and trace.Entity == ent and data) then
        local npower = LaserLib.GetPower(data.NvWidth, data.NvDamage)
        if(npower >= opower) then opower, doment = npower, data.BmSource end
      end
    end
    if(LaserLib.IsUnit(doment, 2)) then
      return doment
    else return nil end
  end; return nil
end

--[[
 * Divides the input sources beams and calculates the kit reports
]]
function ENT:DivideSources()
  if(self.hitSize and self.hitSize > 0) then
    local hdx, tr, dt = 0
    for cnt = 1, self.hitSize do
      local src = self.hitArray[cnt]
      for idx = 1, src:GetHitReports().Size do
        local hit = self:GetHitSourceID(src, idx)
        if(hit) then
          local trace, data = src:GetHitReport(idx)
          if(trace and trace.Hit and data and self:IsHitNormal(trace)) then -- Do same stuff here
            local ref = LaserLib.GetReflected(data.VrDirect, trace.HitNormal)
            if(CLIENT) then
              hdx = hdx + 1; self:DrawBeam(src, trace.HitPos, ref, data, hdx)
              hdx = hdx + 1; self:DrawBeam(src, trace.HitPos, data.VrDirect, data, hdx)
            else
              hdx = hdx + 1; self:DoDamage(self:DoBeam(src, trace.HitPos, ref, data, hdx))
              hdx = hdx + 1; self:DoDamage(self:DoBeam(src, trace.HitPos, data.VrDirect, data, hdx))
            end
          end -- Check the rest of the beams and add power
        end -- Whenever or not our source hits the divider
      end -- Make sure we wipe all reports that are irrelevant anymore
    end; self:RemHitReports(hdx)
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
