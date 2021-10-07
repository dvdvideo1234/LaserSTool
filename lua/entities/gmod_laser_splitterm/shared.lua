ENT.Type           = "anim"
ENT.Category       = "Laser"
ENT.PrintName      = "Splitter Multy"
ENT.Information    = ENT.Category.." "..ENT.PrintName
ENT.Base           = LaserLib.GetClass(1, 1)
if(WireLib) then
  ENT.WireDebugName = ENT.Information
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Spawnable      = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetVector("ElevatLocal"  , "General")
  self:EditableSetBool  ("BeamDimmer"   , "General")
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("InPowerOn"    , "Internals")
  self:EditableSetInt   ("InBeamCount"  , "Internals", 0, LaserLib.GetData("MXSPLTBC"):GetInt())
  self:EditableSetFloat ("InBeamLeanX"  , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamLeanY"  , "Internals", 0, 1)
  self:EditableRemoveOrderInfo()
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local surface normal
  local elevat = Vector(0,1,0)
  self:SetElevatLocal(elevat)
  self:SetNormalLocal(normal)
  return self
end

function ENT:SetBeamCount(num)
  local count = math.floor(math.Clamp(num, 0, 10))
  self:SetInBeamCount(count)
  return self
end

function ENT:GetBeamCount()
  return self:GetInBeamCount()
end

function ENT:SetBeamLeanX(num)
  local count = math.Clamp(num, 0, 1)
  self:SetInBeamLeanX(count)
  return self
end

function ENT:GetBeamLeanX()
  return self:GetInBeamLeanX()
end

function ENT:SetBeamLeanY(num)
  local count = math.Clamp(num, 0, 1)
  self:SetInBeamLeanY(count)
  return self
end

function ENT:GetBeamLeanY()
  return self:GetInBeamLeanY()
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
  local hdx, count = 0, self:GetBeamCount()
  if(count > 0) then
    self:DrawEffectBegin()
    self:ProcessSources(function(entity, index, trace, data)
      if(trace and trace.Hit and data and self:IsHitNormal(trace)) then
        if(self.hitArray[self.hitSize] ~= entity) then
          local hitSize = self.hitSize + 1
          self.hitArray[hitSize] = entity -- Store source
          self.hitSize = hitSize -- Point to next slot
        end
        local welev = Vector(self:GetElevatLocal())
              welev:Rotate(self:GetAngles())
        local bsdir = Vector(trace.HitNormal)
        local bmorg = trace.HitPos; LaserLib.VecNegate(bsdir)
        local angle = bsdir:AngleEx(welev)
        local mrdotm = math.abs(data.VrDirect:Dot(bsdir))
        local mrdotv = (self:GetBeamDimmer() and mrdotm or 1)
        if(count > 1) then
          local marbx = self:GetBeamLeanX()
          local marby = self:GetBeamLeanY()
          local fulla = LaserLib.GetData("AMAX")[2]
          local mnang = fulla / count
          for idx = 1, count do
            local newdr = marby * angle:Up()
                  newdr:Add(marbx * angle:Forward())
            if(CLIENT) then
              hdx = hdx + 1; self:DrawBeam(entity, bmorg, newdr, data, mrdotv, hdx)
            else
              hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, bmorg, newdr, data, mrdotv, hdx))
            end
            angle:RotateAroundAxis(bsdir, mnang)
          end
        else
          if(CLIENT) then
            hdx = hdx + 1; self:DrawBeam(entity, bmorg, bsdir, data, mrdotv, hdx)
          else
            hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, bmorg, bsdir, data, mrdotv, hdx))
          end
        end
      end -- Sources are located in the table hash part
    end)
    self:DrawEffectEnd()
  end; self:RemHitReports(hdx)
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
  local count  = self:GetBeamCount()
  local replic = self:GetBeamReplicate()
  local todiv  = (replic and 1 or (count / vdot))
  local damage = (sdat.NvDamage / todiv)
  local force  = (sdat.NvForce  / todiv)
  local width  = LaserLib.GetWidth((sdat.NvWidth / todiv))
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
