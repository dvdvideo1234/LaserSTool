AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")

function ENT:InitSources()
  if(self.hitSources) then
    table.Empty(self.hitSources)
    table.Empty(self.hitArray)
  else
    self.hitSources = {} -- Sources in notation `[ent] = true`
    self.hitArray   = {} -- Array to output for wiremod
  end
  self.hitSize = 0       -- Amount of sources to have
  return self
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
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
    {"Focusing", "NORMAL", "How many sources are focused"},
    {"Entity"  , "ENTITY", "Concentrator crystal entity" },
    {"Dominant", "ENTITY", "Concentrator dominant entity"},
    {"Target"  , "ENTITY", "Concentrator target entity"  },
    {"Array"   , "ARRAY" , "Concentrated sources array"  }
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then phys:Wake() end

  -- Detup default configuration
  self:InitSources()
  self:SetPushForce(0)
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
  self:SetAngleOffset(0)
  self:SetDamageAmount(0)
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
  local ent = ents.Create(LaserLib.GetClass(2))
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
    ent:PhysWake()
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
  end
  local cnt = (self.hitSize + 1) -- Remove the residuals
  while(self.hitArray[cnt]) do -- Table end check
    self.hitArray[cnt] = nil -- Wipe cirrent item
    cnt = (cnt + 1) -- Wipe the rest until empty
  end; return self -- Sources are located in the table hash part
end

function ENT:UpdateDominant(ent, pow)
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

  if(not pow) then
    local idx = self:GetHitSourceID(ent)
    if(idx) then
      local force, width, damage = 0, 0, 0
      for cnt = 1, ent:GetHitReports().Size do
        local trace, data = ent:GetHitReport(cnt)
        if(trace and trace.Hit and data) then
          force = force + data.NvForce
          width = width + data.NvWidth
          damage = damage + data.NvDamage
        end
      end
      self:SetPushForce(force)
      self:SetBeamWidth(width)
      self:SetDamageAmount(damage)
    else
      self:SetPushForce(dom:GetPushForce())
      self:SetBeamWidth(dom:GetBeamWidth())
      self:SetDamageAmount(dom:GetDamageAmount())
    end
    self:SetBeamLength(dom:GetBeamLength())
  end

  self:WireWrite("Dominant", dom)
  LaserLib.SetPlayer(self, (dom.ply or dom.player))

  return self
end

function ENT:UpdateBeam()
  local opower, npower, force  = 0, 0, 0
  local width , length, damage = 0, 0, 0
  local apower, doment = 0 -- Dominant source

  if(self.hitSize > 0) then
    for cnt = 1, self.hitSize do
      local ent = self.hitArray[cnt]
      if(LaserLib.IsValid(ent)) then
        local idx = self:GetHitSourceID(ent)
        if(idx) then
          for cnt = 1, ent:GetHitReports().Size do
            local hit = self:GetHitSourceID(ent, cnt)
            if(hit) then
              local trace, data = ent:GetHitReport(hit)
              if(trace and trace.Hit and data) then
                npower = LaserLib.GetPower(data.NvWidth,
                                           data.NvDamage)
                if(not self:IsInfinite(ent)) then
                  width  = width  + data.NvWidth
                  length = length + data.NvLength
                  damage = damage + data.NvDamage
                  force  = force  + data.NvForce
                  apower = apower + npower
                end
                if(npower > opower) then
                  doment, opower = ent, npower
                end
              end
            end
          end
        end
      end
      -- Use accumulated power flag
      local bpower = (apower > 0)
      -- This must always produce a dominant
      if(bpower) then -- Sum settings
        self:SetPushForce(force)
        self:SetBeamWidth(width)
        self:SetBeamLength(length)
        self:SetDamageAmount(damage)
      end -- Sources are infinite loops

      self:UpdateDominant(doment, bpower)
    end
  else
    self:SetPushForce(force)
    self:SetBeamWidth(width)
    self:SetBeamLength(length)
    self:SetDamageAmount(damage)
    self:RemHitReports()
  end

  return self
end

function ENT:Think()
  local mwidth = self:GetBeamWidth()
  local mdamage = self:GetDamageAmount()
  local mpower = LaserLib.GetPower(mwidth, mdamage)

  self:UpdateSources()

  if(self.hitSize > 0 and math.floor(mpower) > 0) then
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
    self:WireWrite("Target")
    self:WireWrite("Dominant")
  end

  self:WireWrite("Array", self.hitArray)
  self:WireWrite("Focusing", self.hitSize)
  self:NextThink(CurTime())

  return true
end
