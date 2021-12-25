ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
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
ENT.RenderGroup    = RENDERGROUP_BOTH

function ENT:SetupDataTables()
  local material = list.Get("LaserEmitterMaterials")
  local dissolve = list.Get("LaserDissolveTypes")
  material["Empty"] = ""; dissolve["Empty"] = {name = "", icon = "delete"}
  self:EditableSetBool("CheckDominant", "General")
  self:EditableSetVector("OriginLocal" , "General")
  self:EditableSetVector("DirectLocal" , "General")
  self:EditableSetIntCombo("ForceCenter" , "General", list.GetForEdit("LaserEmitterComboBools"))
  self:EditableSetIntCombo("ReflectRatio", "Material", list.GetForEdit("LaserEmitterComboBools"))
  self:EditableSetIntCombo("RefractRatio", "Material", list.GetForEdit("LaserEmitterComboBools"))
  self:EditableSetBool  ("InPowerOn"   , "Internals")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetStringCombo("InBeamMaterial", "Internals", material)
  self:EditableSetIntCombo("InNonOverMater", "Internals", list.GetForEdit("LaserEmitterComboBools"))
  self:EditableSetIntCombo("EndingEffect"  , "Visuals", list.GetForEdit("LaserEmitterComboBools"))
  self:EditableSetBool("CheckBeamColor", "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetFloat("BeamAlpha", "Visuals", 0, LaserLib.GetData("CLMX"))
  self:EditableSetStringCombo("DissolveType", "Visuals", dissolve, "name")
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
