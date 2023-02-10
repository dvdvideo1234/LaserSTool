ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Splitter Multy"
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
ENT.UnitID         = 8

LaserLib.RegisterUnit(ENT, "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass")

local gtAMAX     = LaserLib.GetData("AMAX")
local gnDOTM     = LaserLib.GetData("DOTM")
local cvMXSPLTBC = LaserLib.GetData("MXSPLTBC")

function ENT:UpdateInternals()
  self.hitSize = 0 -- Add sources in array
  self.crHdx = 0 -- Current bean index
  self.crCount = self:GetBeamCount()
  return self
end

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"   , "General") -- Used as forward
  self:EditableSetVector("UpwardLocal"   , "General")
  self:EditableSetBool  ("BeamDimmer"    , "General")
  self:EditableSetBool  ("BeamReplicate" , "General")
  self:EditableSetBool  ("BeamColorSplit", "Visuals")
  self:EditableSetBool  ("InPowerOn"     , "Internals")
  self:EditableSetInt   ("InBeamCount"   , "Internals", 0, cvMXSPLTBC:GetInt())
  self:EditableSetFloat ("InBeamLeanX"   , "Internals", -1, 1)
  self:EditableSetFloat ("InBeamLeanY"   , "Internals", -1, 1)
  LaserLib.Configure(self)
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
  local fwd = self:GetNormalLocal()
  local upw = self:GetUpwardLocal()
  if(math.abs(fwd:Dot(upw)) >= gnDOTM) then
    local rgh = fwd:Cross(upw)
    upw:Set(rgh:Cross(fwd))
    upw:Normalize()
    self:SetUpwardLocal(upw)
  end; return self
end

function ENT:SetBeamCount(num)
  local cnt = math.floor(math.max(num, 0))
  self:SetInBeamCount(cnt)
  return self
end

function ENT:GetBeamCount()
  return self:GetInBeamCount()
end

function ENT:SetBeamLeanX(num)
  local x = math.Clamp(num, 0, 1)
  self:SetInBeamLeanX(x)
  return self
end

function ENT:GetBeamLeanX()
  return self:GetInBeamLeanX()
end

function ENT:SetBeamLeanY(num)
  local y = math.Clamp(num, 0, 1)
  self:SetInBeamLeanY(y)
  return self
end

function ENT:GetBeamLeanY()
  return self:GetInBeamLeanY()
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
  end; return self
end

function ENT:GetHitNormal()
  return LaserLib.GetUnitProperty(self, "GetNormalLocal", "Normal"):GetNormalized()
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

function ENT:EveryBeam(entity, index, beam, trace)
  if(trace and trace.Hit and beam and self:IsHitNormal(trace)) then
    self:SetArrays(entity)
    local marbx = self:GetBeamLeanX()
    local marby = self:GetBeamLeanY()
    local upwrd = Vector(self:GetUpwardLocal())
          upwrd:Rotate(self:GetAngles())
    local bsdir = Vector(trace.HitNormal)
    local bmorg = trace.HitPos; bsdir:Negate()
    local mrdotm = math.abs(beam.VrDirect:Dot(bsdir))
    local mrdotv = (self:GetBeamDimmer() and mrdotm or 1)
    local angle, count = bsdir:AngleEx(upwrd), self.crCount
    local angup, angfw = angle:Up(), angle:Forward()
    angup:Mul(marby); angfw:Mul(marbx); angfw:Add(angup)
    angle:Set(angfw:AngleEx(upwrd))
    if(count > 1) then
      local mnang = gtAMAX[2] / count
      for idx = 1, count do
        local newdr = angle:Forward()
        if(CLIENT) then
          self:DrawBeam(entity, bmorg, newdr, beam, mrdotv)
        else
          self:DoDamage(self:DoBeam(entity, bmorg, newdr, beam, mrdotv))
        end
        angle:RotateAroundAxis(bsdir, mnang)
      end
    else
      local newdr = angle:Forward()
      if(CLIENT) then
        self:DrawBeam(entity, bmorg, newdr, beam, mrdotv)
      else
        self:DoDamage(self:DoBeam(entity, bmorg, newdr, beam, mrdotv))
      end
    end
  end -- Sources are located in the table hash part
end

function ENT:UpdateSources()
  self:UpdateInternals()

  if(self.crCount > 0) then
    self:ProcessSources()
  end

  self:SetHitReportMax(self.crHdx)

  return self:UpdateArrays()
end

function ENT:BeamColorSplit(idx, bmex)
  if(self:GetBeamColorSplit()) then
    local cnt = (idx % self.crCount + 1)
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
]]
function ENT:DoBeam(ent, org, dir, bmex, vdot)
  self.crHdx = self.crHdx + 1
  LaserLib.SetExSources(ent, bmex:GetSource())
  LaserLib.SetExLength(bmex:GetLength())
  local length = bmex.NvLength
  local usrfle = bmex.BrReflec
  local usrfre = bmex.BrRefrac
  local noverm = bmex.BmNoover
  local todiv  = (self:GetBeamReplicate() and 1 or (self.crCount / vdot))
  local damage = (bmex.NvDamage / todiv)
  local force  = (bmex.NvForce  / todiv)
  local width  = LaserLib.GetWidth((bmex.NvWidth / todiv))
  local beam, trace = LaserLib.DoBeam(self:BeamColorSplit(self.crHdx, bmex),
                                      org,
                                      dir,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm,
                                      self.crHdx)
  return beam, trace
end
