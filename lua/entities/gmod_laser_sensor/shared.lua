ENT.Type           = "anim"
ENT.PrintName      = "Laser Sensor"
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
  self:EditableSetVector("NormalLocal"   , "General")
  self:EditableSetBool  ("ForceCenter"   , "General")
  self:EditableSetBool  ("ReflectRatio"  , "Material")
  self:EditableSetBool  ("RefractRatio"  , "Material")
  self:EditableSetBool  ("InPowerOn"     , "Internals")
  self:EditableSetFloat ("InBeamWidth"   , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength"  , "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InDamageAmount", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InPushForce"   , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetComboString("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetComboString("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
end

function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local normal direction
  self:SetNormalLocal(normal)
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

function ENT:IsHitNormal(trace)
  local norm = Vector(self:GetBeamNormal())
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  return (norm:Dot(trace.HitNormal) > (1 - dotm))
end

function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
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
  return self
end

function ENT:GetBeamLength()
  return self:GetInBeamLength()
end

function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  return self
end

function ENT:GetBeamWidth()
  return self:GetInBeamWidth()
end

function ENT:SetDamageAmount(num)
  local damage = math.max(num, 0)
  self:SetInDamageAmount(damage)
  return self
end

function ENT:GetDamageAmount()
  return self:GetInDamageAmount()
end

function ENT:SetPushForce(num)
  local force = math.max(num, 0)
  self:SetInPushForce(force)
  return self
end

function ENT:GetPushForce()
  return self:GetInPushForce()
end
