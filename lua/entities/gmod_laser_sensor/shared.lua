ENT.Type           = "anim"
ENT.PrintName      = "Laser Sensor"
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
  self:EditableSetVector("OriginLocal" , "General")
  self:EditableSetVector("DirectLocal" , "General")
  self:EditableSetBool  ("ForceCenter" , "General")
  self:EditableSetBool  ("ReflectRatio", "Material")
  self:EditableSetBool  ("RefractRatio", "Material")
  self:EditableSetBool  ("InPowerOn"   , "Internals")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetComboString("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetComboString("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
  self:EditableRemoveOrderInfo()
end

function ENT:SetBeamTransform()
  local dir = Vector(0,0,1) -- Normal local direction
  self:SetDirectLocal(dir)
  return self
end

function ENT:GetSensDirection()
  if(SERVER) then
    local dir = self:WireRead("Direct", true)
    if(dir) then dir:Normalize() else
      dir = self:GetDirectLocal()
    end -- Make sure length is one unit
    self:SetNWVector("GetDirectLocal", dir)
    self:WireWrite("Direct", dir)
    return dir
  else
    local dir = self:GetDirectLocal()
    return self:GetNWFloat("GetDirectLocal", dir)
  end
end

function ENT:GetSensOrigin()
  if(SERVER) then
    local org = self:WireRead("Origin", true)
    if(not org) then org = self:GetOriginLocal() end
    self:SetNWVector("GetOriginLocal", org)
    self:WireWrite("Origin", org)
    return org
  else
    local org = self:GetOriginLocal()
    return self:GetNWFloat("GetOriginLocal", org)
  end
end

function ENT:IsHitNormal(trace)
  local dir = Vector(self:GetSensDirection())
        dir:Rotate(self:GetAngles())
  if(dir:IsZero()) then return 1, true end
  local dom = LaserLib.GetData("DOTM")
  local dot = dir:Dot(trace.HitNormal)
  return dot, (dot > (1 - dom))
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

function ENT:SetBeamDamage(num)
  local damage = math.max(num, 0)
  self:SetInBeamDamage(damage)
  return self
end

function ENT:GetBeamDamage()
  return self:GetInBeamDamage()
end

function ENT:SetBeamForce(num)
  local force = math.max(num, 0)
  self:SetInBeamForce(force)
  return self
end

function ENT:GetBeamForce()
  return self:GetInBeamForce()
end
