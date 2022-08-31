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
ENT.UnitID         = 4

LaserLib.RegisterUnit(ENT, "models/props_c17/pottery04a.mdl", "models/dog/eyeglass")

function ENT:SetupDataTables()
  self:EditableSetInt   ("InBeamCount"  , "Internals", 0, LaserLib.GetData("MXSPLTBC"):GetInt())
  self:EditableSetFloat ("InBeamLeanX"  , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamLeanY"  , "Internals", 0, 1)
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetVector("UpwardLocal"  , "General")
  LaserLib.SetPrimary(self)
  self:EditableSetBool("BeamColorSplit","Visuals")
  LaserLib.Configure(self)
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local beam birection
  local upward = Vector(0,1,0)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  self:SetUpwardLocal(upward)
  return self
end

function ENT:UpdateVectors()
  local mdt = LaserLib.GetData("DOTM")
  local fwd = self:GetDirectLocal()
  local upw = self:GetUpwardLocal()
  if(math.abs(fwd:Dot(upw)) >= mdt) then
    local rgh = fwd:Cross(upw)
    upw:Set(rgh:Cross(fwd))
    upw:Normalize()
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

function ENT:BeamColorSplit(idx)
  if(self:GetBeamColorSplit()) then
    local r, g, b, a = self:GetBeamColorRGBA()
    r, g, b = LaserLib.GetColorID(idx, r, g, b)
    LaserLib.SetExColorRGBA(r, g, b, a)
  end; return self
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

function ENT:DoBeam(org, dir, idx)
  local count  = self:GetBeamCount()
  local origin = self:GetBeamOrigin(org)
  local length = self:GetBeamLength()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local direct = self:GetBeamDirection(dir)
  local noverm = self:GetNonOverMater()
  local todiv  = (self:GetBeamReplicate() and 1 or count)
  local force  = self:GetBeamForce() / todiv
  local damage = self:GetBeamDamage() / todiv
  local width  = LaserLib.GetWidth(self:GetBeamWidth() / todiv)
  local beam, trace = LaserLib.DoBeam(self:BeamColorSplit(idx),
                                      origin,
                                      direct,
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
