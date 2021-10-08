AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_divider.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal"  , "VECTOR", "Dimmer surface normal"}
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Dimmer working state"       },
    {"Normal"  , "VECTOR", "Dimmer surface normal"      },
    {"Entity"  , "ENTITY", "Dimmer entity itself"       },
    {"Count"   , "NORMAL", "Dimmer beam count"          },
    {"Array"   , "ARRAY" , "Dimmer sources array"       },
    {"Level"   , "ARRAY" , "Dimmer power level array"   },
    {"Index"   , "ARRAY" , "Dimmer first hit beam index"},
    {"Front"   , "ARRAY" , "Dimmer frontal hit array"   }
  )

  self:InitSources()
  self:SetBeamReplicate(false)
  self:SetStopSound("")
  self:SetStartSound("")

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(7, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(7))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(7))
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
  self:DrawEffectBegin()
  self:UpdateSources()
  self:DrawEffectEnd()

  if(self.hitSize > 0) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  if(self:GetOn()) then
    self:WireWrite("Count", self.hitSize)
    self:WireWrite("Array", self.hitArray)
    self:WireWrite("Front", self.hitFront)
    self:WireWrite("Index", self.hitIndex)
    self:WireWrite("Level", self.hitLevel)
  else
    self:RemHitReports()
    self:WireWrite("Count", 0)
    self:WireWrite("Array")
    self:WireWrite("Front")
    self:WireWrite("Index")
    self:WireWrite("Level")
  end

  self:NextThink(CurTime())
  return true
end
