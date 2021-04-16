AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

resource.AddSingleFile("materials/effects/redlaser1.vmt")
resource.AddSingleFile("materials/effects/redlaser1.vtf")
resource.AddSingleFile("materials/effects/redlaser1_smoke.vtf")

resource.AddSingleFile("models/props_junk/flare.mdl")
resource.AddSingleFile("models/props_junk/flare.phy")
resource.AddSingleFile("models/props_junk/flare.vvd")
resource.AddSingleFile("models/props_junk/flare.sw.vtx")
resource.AddSingleFile("models/props_junk/flare.dx80.vtx")
resource.AddSingleFile("models/props_junk/flare.dx90.vtx")

local gsReflector = "models/madjawa/laser_reflector.mdl"
local varMaxBounces = GetConVar("laseremitter_maxbounces")

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
  if(WireLib) then
    WireLib.ApplyDupeInfo(ply, ent, info, GetEntByID)
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
  if(phys:IsValid()) then
    phys:Wake()
  end

  if(WireLib)then
    WireLib.CreateSpecialInputs(self, {"On", "Length", "Width", "Damage"})
    WireLib.CreateSpecialOutputs(self, {"On", "Length", "Width", "Damage"})
  end
end

function ENT:Think()
  if(self:GetOn()) then
    local trace, data = LaserLib.DoBeam(self,
                                        self:GetPos(),
                                        self:GetBeamDirection(),
                                        self:GetBeamLength(),
                                        varMaxBounces:GetInt())

    -- FIXME : Eake the owner of the mirror get the kill instead of the owner of the laser
    if(self:GetDamageAmmount() > 0 and trace and
       trace.Entity and trace.Entity:IsValid() and
       trace.Entity:GetClass() ~= "gmod_laser" and
       trace.Entity:GetModel() ~= gsReflector)
    then
      LaserLib.DoDamage(trace.Entity,
                        trace.HitPos,
                        trace.Normal,
                        data.VrDirect,
                        self:GetDamageAmmount(),
                        self.ply,
                        self:GetDissolveType(),
                        self:GetPushProps(),
                        self:GetKillSound(),
                        self)
    end
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
    self:SetDamageAmmount(value)
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
