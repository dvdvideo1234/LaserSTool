ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Sensor"
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
ENT.UnitID         = 6

LaserLib.RegisterUnit(ENT, "models/props_lab/jar01a.mdl", "zup/ramps/ramp_metal")

function ENT:SetupDataTables()
  self.DoBeam = nil -- Receive beams only
  self:EditableSetBool("CheckBeamColor", "Visuals")
  self:EditableSetBool("CheckDominant" , "General")
  self:EditableSetBool("PassBeamTrough", "General")
  LaserLib.SetPrimary(self, true)
  LaserLib.Configure(self)
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
    return self:GetNWVector("GetDirectLocal", norm)
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
    return self:GetNWVector("GetOriginLocal", opos)
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
