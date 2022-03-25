ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Splitter Multy"
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
  self:EditableSetVector("NormalLocal"   , "General") -- Used as forward
  self:EditableSetVector("UpwardLocal"   , "General")
  self:EditableSetBool  ("BeamDimmer"    , "General")
  self:EditableSetBool  ("BeamReplicate" , "General")
  self:EditableSetBool  ("BeamColorSplit", "Visuals")
  self:EditableSetBool  ("InPowerOn"     , "Internals")
  self:EditableSetInt   ("InBeamCount"   , "Internals", 0, LaserLib.GetData("MXSPLTBC"):GetInt())
  self:EditableSetFloat ("InBeamLeanX"   , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamLeanY"   , "Internals", 0, 1)
  LaserLib.OnFinish(self)
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local surface normal
  local upward = Vector(0,1,0)
  self:SetUpwardLocal(upward)
  self:SetNormalLocal(normal)
  return self
end

function ENT:UpdateVectors()
  local mdt = LaserLib.GetData("DOTM")
  local fwd = self:GetNormalLocal()
  local upw = self:GetUpwardLocal()
  if(math.abs(fwd:Dot(upw)) >= mdt) then
    local rgh = fwd:Cross(upw)
    upw:Set(rgh:Cross(fwd))
    upw:Normalize()
    self:SetUpwardLocal(upw)
  end; return self
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
  if(SERVER) then
    self.hitSources = {} -- Sources in notation `[ent] = true`
    self:InitArrays("Array")
  else
    if(not self.hitSources) then
      self.hitSources = {} -- Sources in notation `[ent] = true`
      self:InitArrays("Array")
    end
  end; return self
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

local hdx, count

function ENT:EveryBeam(entity, index, beam, trace)
  if(trace and trace.Hit and beam and self:IsHitNormal(trace)) then
    self:SetArrays(entity)
    local upwrd = Vector(self:GetUpwardLocal())
          upwrd:Rotate(self:GetAngles())
    local bsdir = Vector(trace.HitNormal)
    local bmorg = trace.HitPos; LaserLib.VecNegate(bsdir)
    local angle = bsdir:AngleEx(upwrd)
    local mrdotm = math.abs(beam.VrDirect:Dot(bsdir))
    local mrdotv = (self:GetBeamDimmer() and mrdotm or 1)
    if(count > 1) then
      local marbx = self:GetBeamLeanX()
      local marby = self:GetBeamLeanY()
      local mnang = LaserLib.GetData("AMAX")[2] / count
      for idx = 1, count do
        local newdr = marby * angle:Up(); newdr:Add(marbx * angle:Forward())
        if(CLIENT) then
          hdx = hdx + 1; self:DrawBeam(entity, bmorg, newdr, beam, mrdotv, hdx)
        else
          hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, bmorg, newdr, beam, mrdotv, hdx))
        end
        angle:RotateAroundAxis(bsdir, mnang)
      end
    else
      if(CLIENT) then
        hdx = hdx + 1; self:DrawBeam(entity, bmorg, bsdir, beam, mrdotv, hdx)
      else
        hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, bmorg, bsdir, beam, mrdotv, hdx))
      end
    end
  end -- Sources are located in the table hash part
end

function ENT:UpdateSources()
  self.hitSize = 0 -- Add sources in array
  hdx, count = 0, self:GetBeamCount()

  if(count > 0) then
    self:ProcessSources()
  end

  self:SetHitReportMax(hdx)

  return self:UpdateArrays()
end

function ENT:BeamColorSplit(idx, bmex)
  if(self:GetBeamColorSplit()) then
    local cnt = (idx % self:GetBeamCount() + 1)
    local r, g, b, a = bmex:GetColorRGBA()
    r, g, b = LaserLib.GetColorID(cnt, r, g, b)
    LaserLib.SetExColorRGBA(r, g, b, a)
  end; return self
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * bmex > Source trace beam class
 * vdot > Dot product with surface normal
 * idx  > Index to store the result
]]
function ENT:DoBeam(ent, org, dir, bmex, vdot, idx)
  LaserLib.SetExSources(ent, bmex:GetSource())
  LaserLib.SetExLength(bmex:GetLength())
  local length = bmex.NvLength
  local usrfle = bmex.BrReflec
  local usrfre = bmex.BrRefrac
  local noverm = bmex.BmNoover
  local count  = self:GetBeamCount()
  local todiv  = (self:GetBeamReplicate() and 1 or (count / vdot))
  local damage = (bmex.NvDamage / todiv)
  local force  = (bmex.NvForce  / todiv)
  local width  = LaserLib.GetWidth((bmex.NvWidth / todiv))
  local beam, trace = LaserLib.DoBeam(self:BeamColorSplit(idx, bmex),
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
