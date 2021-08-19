AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_divider.vmt")

function ENT:InitSources()
  if(self.hitSources) then
    table.Empty(self.hitSources)
    table.Empty(self.hitArray)
  else
    self.hitArray   = {} -- Array to output for wiremod
    self.hitSources = {} -- Sources in notation `[ent] = true`
  end
  self.hitSize = 0
  return self
end

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateOutputs(
    {"On"      , "NORMAL", "Divider working state"  },
    {"Count"   , "NORMAL", "Divider beam count"     },
    {"Entity"  , "ENTITY", "Divider crystal entity" },
    {"Array"   , "ARRAY" , "Divider sources array"  }
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
  -- Sets the right angle at spawn. Thanks to aVoN!
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(5))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(5))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(5))
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
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
      if(LaserLib.IsSource(trent)) then
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

  if(self.hitSize > 0) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  if(self:GetOn()) then
    self:DivideSources(true)
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