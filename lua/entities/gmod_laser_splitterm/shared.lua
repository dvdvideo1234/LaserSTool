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
  self:EditableSetFloat ("InBeamLeanZ"   , "Internals", -1, 1)
  LaserLib.Configure(self)
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

-- Override the beam transformation
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
  if(not LaserLib.IsOrtho(fwd, upw)) then
    LaserLib.SetOrtho(fwd, upw, true)
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
  local x = math.Clamp(num, -1, 1)
  self:SetInBeamLeanX(x)
  return self
end

function ENT:GetBeamLeanX()
  return self:GetInBeamLeanX()
end

function ENT:SetBeamLeanY(num)
  local y = math.Clamp(num, -1, 1)
  self:SetInBeamLeanY(y)
  return self
end

function ENT:GetBeamLeanY()
  return self:GetInBeamLeanY()
end

function ENT:SetBeamLeanZ(num)
  local z = math.Clamp(num, -1, 1)
  self:SetInBeamLeanZ(z)
  return self
end

function ENT:GetBeamLeanZ()
  return self:GetInBeamLeanZ()
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

function ENT:GetLeanAngle(forwd, upwrd)
  return LaserLib.GetLeanAngle(forwd, upwrd,
                               self:GetBeamLeanX(),
                               self:GetBeamLeanY(),
                               self:GetBeamLeanZ())
end

function ENT:EveryBeam(entity, index, beam, trace)
  if(trace and trace.Hit and beam and self:IsHitNormal(trace)) then
    local count = self.crCount; self:SetArrays(entity)
    if(count > 0) then
      local mnang = gtAMAX[2] / count
      local bsdir = Vector(trace.HitNormal)
      local bmorg = trace.HitPos; bsdir:Negate()
      local mdotm = math.abs(beam.VrDirect:Dot(bsdir))
      local mdotv = (self:GetBeamDimmer() and mdotm or 1)
      local upwrd = self:GetUpwardLocal(); upwrd:Rotate(self:GetAngles())
      local angle = self:GetLeanAngle(bsdir, upwrd)
      for idx = 1, count do
        if(CLIENT) then
          self:DrawBeam(entity, bmorg, angle:Forward(), beam, mdotv)
        else
          self:DoDamage(self:DoBeam(entity, bmorg, angle:Forward(), beam, mdotv))
        end
        if(count > 1) then angle:RotateAroundAxis(bsdir, mnang) end
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
