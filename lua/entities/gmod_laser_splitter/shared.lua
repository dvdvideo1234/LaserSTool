ENT.Type           = "anim"
ENT.PrintName      = "Laser Splitter"
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
  self:EditableSetVector("OriginLocal"  , "General")
  self:EditableSetVector("DirectLocal"  , "General")
  self:EditableSetVector("ElevatLocal"  , "General")
  self:EditableSetBool  ("ForceCenter"  , "General")
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("ReflectRatio" , "Material")
  self:EditableSetBool  ("RefractRatio" , "Material")
  self:EditableSetBool  ("InPowerOn"    , "Internals")
  self:EditableSetInt   ("InBeamCount"  , "Internals", 0, LaserLib.GetData("MXSPLTBC"):GetInt())
  self:EditableSetFloat ("InBeamLeanX"  , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamLeanY"  , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamWidth"  , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength" , "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InBeamDamage" , "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InBeamForce"  , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetComboString("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetComboString("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
  self:EditableRemoveOrderInfo()
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local beam birection
  local elevat = Vector(0,1,0)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  self:SetElevatLocal(elevat)
  return self
end

function ENT:UpdateVectors()
  local mdt = LaserLib.GetData("DOTM")
  local dir = self:GetDirectLocal()
  local elv = self:GetElevatLocal()
  if(math.abs(dir:Dot(elv)) >= mdt) then
    local piv = dir:Cross(elv)
    elv:Set(piv:Cross(dir))
    elv:Normalize()
    dir:Normalize()
    self:SetElevatLocal(elv)
    self:SetDirectLocal(dir)
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
  local trace, data = LaserLib.DoBeam(self,
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
  return trace, data
end
