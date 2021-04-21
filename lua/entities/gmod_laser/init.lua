AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:ApplyDupeInfo(ply, ent, info, entid)
  if(WireLib) then
    WireLib.ApplyDupeInfo(ply, ent, info, entid)
  end
end

function ENT:PreEntityCopy()
  if(WireLib) then
    duplicator.StoreEntityModifier(self, "WireDupeInfo", WireLib.BuildDupeInfo(self))
  end
end

local function EntityLookup(created)
  return function(id, default)
    if(id == nil) then return default
    elseif(id == 0) then return game.GetWorld() end
    local ent = created[id] or (isnumber(id) and ents.GetByIndex(id))
    if(IsValid(ent)) then return ent else return default end
  end
end

function ENT:PostEntityPaste(ply, ent, created)
  if(ent.EntityMods and ent.EntityMods.WireDupeInfo) then
    if(WireLib) then
      WireLib.ApplyDupeInfo(ply, ent, ent.EntityMods.WireDupeInfo, EntityLookup(created))
    end
  end
end

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)

  local phys = self:GetPhysicsObject()
  if(phys:IsValid()) then phys:Wake() end

  if(WireLib)then
    WireLib.CreateSpecialInputs(self, {"On", "Length", "Width", "Damage"})
    WireLib.CreateSpecialOutputs(self, {"On", "Length", "Width", "Damage"})
  end
end

function ENT:DoDamage(trace, data)
  -- TODO : Make the owner of the mirror get the kill instead of the owner of the laser
  if(self:GetDamageAmount() > 0 and trace) then
    local trent = trace.Entity
    if(trent and trent:IsValid() and
       trent:GetClass() ~= LaserLib.GetClass(1, 1) and
       trent:GetClass() ~= LaserLib.GetClass(2, 1) and
       trent:GetModel() ~= LaserLib.GetModel(3, 1))
    then
      LaserLib.DoDamage(trent,
                        trace.HitPos,
                        trace.Normal,
                        data.VrDirect,
                        data.NvDamage,
                        self.ply,
                        self:GetDissolveType(),
                        self:GetPushProps(),
                        self:GetKillSound(),
                        self)
    end
  end

  return self
end

function ENT:DoBeam()
  local origin = self:GetBeamOrigin()
  local length = self:GetBeamLength()
  local damage = self:GetDamageAmount()
  local direct = self:GetBeamDirection()
  local userfe = self:GetReflectionRate()
  local trace, data = LaserLib.DoBeam(self,
                                      origin,
                                      direct,
                                      length,
                                      0, -- Width is not used
                                      damage,
                                      userfe)
  return trace, data
end

function ENT:Think()
  if(self:GetOn()) then
    local trace, data = self:DoBeam()
    self:DoDamage(trace, data)
  end

  self:NextThink(CurTime())
  return true
end

function ENT:OnRemove()
  if(WireLib) then WireLib.Remove(self) end
end

function ENT:OnRestore()
  if(WireLib) then WireLib.Restored(self) end
end

function ENT:TriggerInput(iname, value)
  if(iname == "On") then
    self:SetOn(tobool(value))
  elseif(iname == "Length") then
    if(value == 0) then value = self.defaultLength end
    self:SetBeamLength(value)
  elseif(iname == "Width") then
    if(value == 0) then value = self.defaultWidth end
    self:SetBeamWidth(value)
  elseif(iname == "Damage") then
    self:SetDamageAmount(value)
  elseif(iname == "Force") then
    -- TODO: Force for pushing props
  end
end

local function On(ply, ent)
  if(not ent) then return end
  if(ent == NULL) then return end
  if(not ent:IsValid()) then return end
  ent:SetOn(not ent:GetOn())
end

local function Off(ply, ent)
  if(not ent) then return end
  if(ent == NULL) then return end
  if(not ent:IsValid()) then return end
  if(ent:GetToggle()) then return end
  ent:SetOn(not ent:GetOn())
end

numpad.Register("Laser_On" , On )
numpad.Register("Laser_Off", Off)
