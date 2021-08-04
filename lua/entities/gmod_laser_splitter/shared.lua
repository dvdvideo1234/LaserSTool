--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]

ENT.Type           = "anim"
ENT.PrintName      = "Laser Splitter"
ENT.Base           = LaserLib.GetClass(1)
if(WireLib) then
  ENT.WireDebugName = ENT.PrintName
end
ENT.Editable       = true
ENT.Author         = "MadJawa"
ENT.Category       = "Laser"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.Information    = ENT.PrintName

function ENT:SetupDataTables()
  self:EditableSetVector("OriginLocal"   , "General")
  self:EditableSetVector("DirectLocal"   , "General")
  self:EditableSetVector("ElevatLocal"   , "General")
  self:EditableSetFloat ("AngleOffset"   , "General", -360, 360)
  self:EditableSetBool  ("StartToggle"   , "General")
  self:EditableSetBool  ("ForceCenter"   , "General")
  self:EditableSetBool  ("ReflectRatio"  , "Material")
  self:EditableSetBool  ("RefractRatio"  , "Material")
  self:EditableSetBool  ("InPowerOn"     , "Internals")
  self:EditableSetInt   ("InBeamCount"   , "Internals", 0, 10)
  self:EditableSetFloat ("InBeamLeanX"   , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamLeanY"   , "Internals", 0, 1)
  self:EditableSetFloat ("InBeamWidth"   , "Internals", 0, 30)
  self:EditableSetFloat ("InBeamLength"  , "Internals", 0, 50000)
  self:EditableSetFloat ("InDamageAmount", "Internals", 0, 5000)
  self:EditableSetFloat ("InPushForce"   , "Internals", 0, 50000)
  self:EditableSetComboString("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetComboString("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local beam birection
  local elevat = Vector(1,0,0)
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

function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetInDamageAmount(damage)
  self:WireWrite("Damage", damage)
  return self
end

function ENT:GetDamageAmount()
  return self:GetInDamageAmount()
end

function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetInPushForce(force)
  self:WireWrite("Force", force)
  return self
end

function ENT:GetPushForce()
  return self:GetInPushForce()
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
