ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Splitter Single"
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
ENT.WaveAR         = {}
ENT.UnitID         = 4

LaserLib.RegisterUnit(ENT, "models/props_c17/pottery04a.mdl", "models/dog/eyeglass")

local gtWVIS     = LaserLib.GetData("WVIS")
local gnDOTM     = LaserLib.GetData("DOTM")
local cvWDHUECNT = LaserLib.GetData("WDHUECNT")
local cvMXSPLTBC = LaserLib.GetData("MXSPLTBC")

function ENT:SetupDataTables()
  self:EditableSetInt   ("InBeamCount"  , "Internals", 0, cvMXSPLTBC:GetInt())
  self:EditableSetFloat ("InBeamLeanX"  , "Internals", -1, 1)
  self:EditableSetFloat ("InBeamLeanY"  , "Internals", -1, 1)
  self:EditableSetFloat ("InBeamLeanZ"  , "Internals", -1, 1)
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetVector("UpwardLocal"  , "General")
  self:EditableSetBool ("BeamColorSplit", "Visuals")
  LaserLib.SetPrimary(self)
  LaserLib.Configure(self)
end

-- Override the beam transformation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local beam direction
  local upward = Vector(0,1,0)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  self:SetUpwardLocal(upward)
  return self
end

function ENT:UpdateVectors()
  local fwd = self:GetDirectLocal()
  local upw = self:GetUpwardLocal()
  if(not LaserLib.IsOrtho(fwd, upw)) then
    LaserLib.SetOrtho(fwd, upw, true)
    self:SetUpwardLocal(upw)
  end; return self
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

function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetInBeamLength(length)
  self:WireWrite("Length", length)
  return self
end

function ENT:GetBeamLength()
  return self:GetInBeamLength()
end

function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  self:WireWrite("Width", width)
  return self
end

function ENT:GetBeamWidth()
  return self:GetInBeamWidth()
end

function ENT:SetBeamDamage(num)
  local damage = math.max(num, 0)
  self:SetInBeamDamage(damage)
  self:WireWrite("Damage", damage)
  return self
end

function ENT:GetBeamDamage()
  return self:GetInBeamDamage()
end

function ENT:SetBeamForce(num)
  local force = math.max(num, 0)
  self:SetInBeamForce(force)
  self:WireWrite("Force", force)
  return self
end

function ENT:GetBeamForce()
  return self:GetInBeamForce()
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

--[[
 * Safety. Makes the beam acts like in the
 * portal series towards all players
]]
function ENT:SetBeamSafety(bool)
  local safe = tobool(bool)
  self:SetInBeamSafety(safe)
  self:WireWrite("Safety", (safe and 1 or 0))
  return self
end

function ENT:GetBeamSafety()
  return self:GetInBeamSafety()
end

--[[
 * Ignite. Makes the beam ignite props
 * portal series towards all players
]]
function ENT:SetBeamIgnite(bool)
  local igne = tobool(bool)
  self:SetInBeamIgnite(igne)
  self:WireWrite("Ignite", (igne and 1 or 0))
  return self
end

function ENT:GetBeamIgnite()
  return self:GetInBeamIgnite()
end


--[[
 * Disperse. Makes the beam disperse
]]
function ENT:GetBeamDisperse()
  return self:GetInBeamDisperse()
end

function ENT:SetBeamDisperse(bool)
  local disp = tobool(bool)
  self:SetInBeamDisperse(disp)
  self:WireWrite("Disperse", (disp and 1 or 0))
  return self
end

function ENT:GetLeanAngle(forwd, upwrd)
  return LaserLib.GetLeanAngle(forwd, upwrd,
                               self:GetBeamLeanX(),
                               self:GetBeamLeanY(),
                               self:GetBeamLeanZ())
end

function ENT:SetColorWave(beam, iC, iD)
  if(not beam) then return end
  local iC = math.floor(tonumber(iC) or 0)
  if(iC <= 0) then return end
  local iD = math.floor(tonumber(iD) or 0)
  if(iD <= 0) then return end
  local cB, tW = beam:GetColorBase()
  if(not cB) then return end
  if(iD > 1) then tW = self.WaveAR else
    tW = LaserLib.GetWaveArray(cB, self.WaveAR, iC) end
  if(not tW) then return end
  local sr, sg, sb, sa = beam:GetColorRGBA()
  local recw = tW[iD] -- Current component indexing
  local rCo, rPw = recw.C, tW.PC
  sa = ((recw.P > 0) and sa or 0)
  sr, sg, sb = (rCo.r * rPw), (rCo.g * rPw), (rCo.b * rPw)
  beam:SetWavelength(recw.W)    -- Component wavelength
  beam:SetColorRGBA(sr, sg, sb, sa) -- Apply beam color
end

function ENT:DoBeam(org, dir, idx)
  local count  = self:GetBeamCount()
  local origin = self:GetBeamOrigin(org)
  local length = self:GetBeamLength()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local direct = self:GetBeamDirection(dir)
  local noverm = self:GetNonOverMater()
  local disper = (self:GetBeamDisperse() and cvWDHUECNT:GetInt() > 0)
  local todiv  = (self:GetBeamReplicate() and 1 or count)
  local beam   = LaserLib.Beam(origin, direct, length)
        beam:SetSource(self, self)
        beam:SetWidth(LaserLib.GetWidth(self:GetBeamWidth() / todiv))
        beam:SetDamage(self:GetBeamDamage() / todiv)
        beam:SetForce(self:GetBeamForce() / todiv)
        beam:SetFgDivert(usrfle, usrfre)
        beam:SetFgTexture(noverm, disper)
        beam:SetBounces()
  if(self:GetBeamColorSplit() and idx) then
    self:SetColorWave(beam, count, idx)
  end
  if(not beam:IsValid() and SERVER) then
    beam:Clear(); self:Remove(); return end
  return beam:Run()
end
