AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_portal.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal"  , "VECTOR", "Portal surface normal"}
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Portal working state" },
    {"Normal"  , "VECTOR", "Portal surface normal"},
    {"Count"   , "NORMAL", "Portal beam count"    },
    {"Entity"  , "ENTITY", "Portal entity itself" },
    {"Array"   , "ARRAY" , "Portal sources array" }
  )

  self:InitSources()
  self:SetStopSound("")
  self:SetStartSound("")

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then phys:Wake() end

  -- Detup default configuration
  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(9, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(9))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(9))
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:SetBeamTransform()
    return ent
  end; return nil
end

function ENT:DoDamage(trace, data)
  -- TODO : Make the owner of the mirror get the kill instead of the owner of the laser
  if(trace) then
    local trent = trace.Entity
    if(LaserLib.IsValid(trent)) then
      -- Check whenever target is beam source
      if(LaserLib.IsUnit(trent)) then
        -- Register the source to the ones who has it
        if(trent.RegisterSource) then
          trent:RegisterSource(self)
        end -- Define the method to register sources
      else
        local user = (self.ply or self.player)
        local dtyp = data.BmSource:GetDissolveType()
        LaserLib.DoDamage(trent,
                          trace.HitPos,
                          trace.Normal,
                          data.VrDirect,
                          data.NvDamage,
                          data.NvForce,
                          (user or data.BmSource:GetCreator()),
                          LaserLib.GetDissolveID(dtyp),
                          data.BmSource:GetKillSound(),
                          data.BmSource:GetForceCenter(),
                          self)
      end
    end
  end

  return self
end

function ENT:Think()
  self:UpdateSources()

  print(self, self.hitSize, self:GetEntityID())

  if(self.hitSize > 0) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  if(self:GetOn()) then
    self:WireWrite("Array", self.hitArray)
    self:WireWrite("Count", self.hitSize)
  else
    self:RemHitReports()
    self:WireWrite("Array")
    self:WireWrite("Count", 0)
  end

  self:NextThink(CurTime())
  return true
end
