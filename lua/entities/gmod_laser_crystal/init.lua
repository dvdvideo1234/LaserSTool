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
  -- Sets the right angle at spawn. Thanks to aVoN!
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
  self.hitSize = 0 -- Add sources in array
  for ent, stat in pairs(self.hitSources) do
    if(self:GetHitSourceID(ent)) then -- Check the thing
      self.hitSize = self.hitSize + 1 -- Point to next slot
      self.hitArray[self.hitSize] = ent -- Store source
    else -- When not a source. Delete the slot
      self.hitSources[ent] = nil -- Wipe out the entry
    end -- The sources order does not matter
  end; return self:UpdateArrays("hitArray")
end

function ENT:GetDominant(ent)
  if(not LaserLib.IsValid(ent)) then return self end
  -- We set the same non-addable properties
  -- The most powerful source (biggest damage/width)
  local dom = ent:GetHitDominant(self)
  if(not LaserLib.IsValid(dom)) then return self end
  self:SetStopSound(dom:GetStopSound())
  self:SetKillSound(dom:GetKillSound())
  self:SetBeamColor(dom:GetBeamColor())
  self:SetStartSound(dom:GetStartSound())
  self:SetBeamMaterial(dom:GetBeamMaterial())
  self:SetDissolveType(dom:GetDissolveType())
  self:SetEndingEffect(dom:GetEndingEffect())
  self:SetReflectRatio(dom:GetReflectRatio())
  self:SetRefractRatio(dom:GetRefractRatio())
  self:SetForceCenter(dom:GetForceCenter())
  self:SetNonOverMater(dom:GetNonOverMater())

  self:WireWrite("Dominant", dom)
  LaserLib.SetPlayer(self, (dom.ply or dom.player))

  return dom
end

function ENT:UpdateBeam()
  local opower, npower, force  = 0, 0, 0
  local width , length, damage = 0, 0, 0
  local bpower, doment = false -- Dominant source

  if(self.hitSize > 0) then
    self:ProcessSources(function(entity, index, trace, data)
      if(trace and trace.Hit and data) then
        npower = LaserLib.GetPower(data.NvWidth,
                                   data.NvDamage)
        if(not self:IsInfinite(entity)) then
          width  = width  + data.NvWidth
          length = length + data.NvLength
          damage = damage + data.NvDamage
          force  = force  + data.NvForce
          bpower = (bpower or true)
        end
        if(npower > opower) then
          doment, opower = entity, npower
        end
      end
    end)

    local dom = self:GetDominant(doment)
    if(bpower) then -- Sum settings
      self:SetBeamForce(force)
      self:SetBeamWidth(width)
      self:SetBeamLength(length)
      self:SetBeamDamage(damage)
    else -- Inside an active entity loop
      if(LaserLib.IsValid(dom)) then
        local force, width, damage = 0, 0, 0
        local stats = self:ProcessReports(doment,
          function(index, trace, data)
            if(trace and trace.Hit and data) then
              force  = force  + data.NvForce
              width  = width  + data.NvWidth
              damage = damage + data.NvDamage
            end
          end)
        if(stats) then
          self:SetBeamForce(force)
          self:SetBeamWidth(width)
          self:SetBeamDamage(damage)
        else
          self:SetBeamForce(dom:GetBeamForce())
          self:SetBeamWidth(dom:GetBeamWidth())
          self:SetBeamDamage(dom:GetBeamDamage())
        end
        self:SetBeamLength(dom:GetBeamLength())
      else
        self:SetBeamForce(0)
        self:SetBeamWidth(0)
        self:SetBeamLength(0)
        self:SetBeamDamage(0)
        self:RemHitReports()
      end -- Sources are infinite loops
    end
  else
    self:SetBeamForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetBeamDamage(0)
    self:RemHitReports()
  end

  return self
end

function ENT:Think()
  local mwidth = self:GetBeamWidth()
  local mdamage = self:GetBeamDamage()

  self:UpdateSources()

  if(self.hitSize > 0 and LaserLib.IsPower(mwidth, mdamage)) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  self:UpdateBeam()

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
