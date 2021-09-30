ENT.Type           = "anim"
ENT.Category       = "Laser"
ENT.PrintName      = "Sensor"
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
  self:EditableSetStringCombo("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetStringCombo("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
  self:EditableRemoveOrderInfo()
end

function ENT:SetBeamTransform()
  local norm = Vector(0,0,1) -- Normal local direction
  self:SetDirectLocal(norm)  -- Used as hit-normal check
  return self
end

function ENT:GetUnitDirection()
  if(SERVER) then
    local norm = self:WireRead("Direct", true)
    if(norm) then norm:Normalize() else
      norm = self:GetDirectLocal()
    end -- Make sure length is one unit
    self:SetNWVector("GetDirectLocal", norm)
    self:WireWrite("Direct", norm)
    return norm
  else
    local norm = self:GetDirectLocal()
    return self:GetNWFloat("GetDirectLocal", norm)
  end
end

function ENT:GetUnitOrigin()
  if(SERVER) then
    local opos = self:WireRead("Origin", true)
    if(not opos) then opos = self:GetOriginLocal() end
    self:SetNWVector("GetOriginLocal", opos)
    self:WireWrite("Origin", opos)
    return opos
  else
    local opos = self:GetOriginLocal()
    return self:GetNWFloat("GetOriginLocal", opos)
  end
end

function ENT:GetHitNormal(trace)
  local norm = Vector(self:GetUnitDirection())
        norm:Rotate(self:GetAngles())
  if(norm:IsZero()) then return 1, true end
  local dom = LaserLib.GetData("DOTM")
  local dot = norm:Dot(trace.HitNormal)
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
