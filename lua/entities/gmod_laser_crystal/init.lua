AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end

function ENT:InitSources()
  self.hitSize = 0       -- Amount of sources to have
  if(self.hitSources) then
    table.Empty(self.hitSources)
    table.Empty(self.hitArray)
  else
    self.hitSources = {} -- Sources in notation `[ent] = true`
    self.hitArray   = {} -- Array to output for wiremod
  end
  return self
end

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateOutputs(
    {"On"      , "NORMAL", "Concentrator working state"  },
    {"Hit"     , "NORMAL", "Indicates entity crystal hit"},
    {"Width"   , "NORMAL", "Concentrator beam width"     },
    {"Range"   , "NORMAL", "Concentrator beam range"     },
    {"Length"  , "NORMAL", "Concentrator length width"   },
    {"Damage"  , "NORMAL", "Concentrator damage width"   },
    {"Force"   , "NORMAL", "Concentrator force amount"   },
    {"Entity"  , "ENTITY", "Concentrator entity itself"  },
    {"Dominant", "ENTITY", "Concentrator dominant entity"},
    {"Target"  , "ENTITY", "Concentrator target entity"  },
    {"Count"   , "NORMAL", "Concentrated sources count"  },
    {"Array"   , "ARRAY" , "Concentrated sources array"  }
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then phys:Wake() end

  -- Detup default configuration
  self:InitSources()
  self:SetBeamForce(0)
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
  self:SetAngleOffset(0)
  self:SetBeamDamage(0)
  self:SetStopSound("")
  self:SetKillSound("")
  self:SetStartSound("")
  self:SetBeamMaterial("")
  self:SetDissolveType("")
  self:SetEndingEffect(false)
  self:SetReflectRatio(false)
  self:SetRefractRatio(false)
  self:SetForceCenter(false)
  self:SetNonOverMater(false)
  self:SetBeamColor(Vector(1,1,1))

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(2, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(2))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(2))
    ent:SetBeamTransform()
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    return ent
  end; return nil
end

function ENT:UpdateSources()
  local doment , domsrc
  local xlength, bpower = 0, false
  local xforce , xwidth, xdamage = 0, 0, 0
  local opower , npower, force   = 0, 0, 0
  local width  , length, damage  = 0, 0, 0

  self.hitSize = 0 -- Add sources in array
  self:ProcessSources(function(entity, index, trace, data)
    if(trace and trace.Hit and data) then
      if(self.hitArray[self.hitSize] ~= entity) then
        self.hitSize = self.hitSize + 1
        self.hitArray[self.hitSize] = entity
      end
      npower = LaserLib.GetPower(data.NvWidth,
                                 data.NvDamage)
      if(not self:IsInfinite(entity)) then
        width  = width  + data.NvWidth
        length = length + data.NvLength
        damage = damage + data.NvDamage
        force  = force  + data.NvForce
        bpower = (bpower or true)
      else
        if(doment ~= entity) then
          xforce  = data.NvForce
          xwidth  = data.NvWidth
          xdamage = data.NvDamage
          xlength = data.BmLength
        else
          xforce  = xforce  + data.NvForce
          xwidth  = xwidth  + data.NvWidth
          xdamage = xdamage + data.NvDamage
        end
      end
      if(npower > opower) then
        opower = npower
        domsrc = data.BmSource
        doment = entity
      end
    end
  end)

  if(self.hitSize > 0) then
    self:SetDominant(domsrc)

    if(bpower) then -- Sum settings
      self:SetBeamForce(force)
      self:SetBeamWidth(width)
      self:SetBeamLength(length)
      self:SetBeamDamage(damage)
    else -- Inside an active entity loop
      self:SetBeamForce(xforce)
      self:SetBeamWidth(xwidth)
      self:SetBeamDamage(xdamage)
      self:SetBeamLength(xlength)
    end
  else
    self:SetBeamForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetBeamDamage(0)
    self:RemHitReports()
  end

  return self:UpdateArrays("hitArray")
end

function ENT:Think()
  self:UpdateSources()

  local mwidth = self:GetBeamWidth()
  local mdamage = self:GetBeamDamage()

  if(self.hitSize > 0 and LaserLib.IsPower(mwidth, mdamage)) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  if(self:GetOn()) then
    local trace, data = self:DoBeam()

    if(data) then
      self:WireWrite("Range", data.RaLength)
    end

    if(trace) then
      self:WireWrite("Hit", (trace.Hit and 1 or 0))

      local trent = trace.Entity

      if(LaserLib.IsValid(trent)) then
        self:WireWrite("Target", trent)
      else
        self:WireWrite("Target")
      end
    end

    self:DoDamage(trace, data)
  else
    self:RemHitReports()
    self:WireWrite("Hit", 0)
    self:WireWrite("Range", 0)
    self:WireWrite("Target")
    self:WireWrite("Dominant")
  end

  self:WireWrite("Array", self.hitArray)
  self:WireWrite("Count", self.hitSize)
  self:NextThink(CurTime())

  return true
end
