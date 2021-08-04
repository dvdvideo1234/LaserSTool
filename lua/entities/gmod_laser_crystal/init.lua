--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")

function ENT:InitSources()
  if(self.Sources) then
    table.Empty(self.Sources)
    table.Empty(self.Array)
  else
    self.Sources = {} -- Sources in notation `[ent] = true`
    self.Array   = {} -- Array to output for wiremod
  end
  self.Size = 0       -- Amount of sources to have
  return self
end

function ENT:RegisterSource(ent)
  self.Sources[ent] = true; return self
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
  if(phys:IsValid()) then phys:Wake() end

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
  self:SetBeamColor(Vector(1,1,1))

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  -- Sets the right angle at spawn. Thanks to aVoN!
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(2))
  if(ent and ent:IsValid()) then
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
    ent:Activate()
    ent:PhysWake()
    return ent
  end; return nil
end

--[[
 * Checks for infinite loops when the source `ent`
 * is powered by other crystals powered by self
 * self > The root of the tree propagated
 * ent  > The entity of the source checked
]]
function ENT:IsInfinite(ent)
  if(ent == self) then return true end
  if(LaserLib.IsSource(ent) and ent.Sources) then
    for src, stat in pairs(ent.Sources) do
      if(src == self) then return true end -- Other hits and we are in its sources
      if(src and src:IsValid()) then -- Crystal has been hit by other crystal
        if(LaserLib.IsSource(src) and src.Sources) then -- Check calss to propagade the tree
          if(self:IsInfinite(src)) then return true end end
      end -- Cascadely propagate trough the crystal sources from `self`
    end; return false
  else -- The entity is laser
    return false
  end
end

function ENT:UpdateSources()
  self.Size = 0 -- Add sources in array
  for ent, stat in pairs(self.Sources) do
    if(self:GetHitSourceID(ent)) then -- Check the thing
      self.Size = self.Size + 1 -- Point to next slot
      self.Array[self.Size] = ent -- Store source
    else -- When not a source. Delete the slot
      self.Sources[ent] = nil -- Wipe out the entry
    end -- The sources order does not matter
  end
  local cnt = (self.Size + 1) -- Remove the residuals
  while(self.Array[cnt]) do -- Table end check
    self.Array[cnt] = nil -- Wipe cirrent item
    cnt = (cnt + 1) -- Wipe the rest until empty
  end; return self -- Sources are located in the table hash part
end

function ENT:UpdateDominant(ent, pow)
  if(not ent) then return self end
  if(not ent:IsValid()) then return self end
  -- We set the same non-addable properties
  -- The most powerful source (biggest damage/width)
  self:SetStopSound(ent:GetStopSound())
  self:SetKillSound(ent:GetKillSound())
  self:SetBeamColor(ent:GetBeamColor())
  self:SetStartSound(ent:GetStartSound())
  self:SetBeamMaterial(ent:GetBeamMaterial())
  self:SetDissolveType(ent:GetDissolveType())
  self:SetEndingEffect(ent:GetEndingEffect())
  self:SetReflectRatio(ent:GetReflectRatio())
  self:SetRefractRatio(ent:GetRefractRatio())
  self:SetForceCenter(ent:GetForceCenter())

  if(not pow) then
    local index = self:GetHitSourceID(ent)
    if(index) then
      local force, width, damage = 0, 0, 0
      local trace, data = ent:GetHitReport(index)
      if(data) then
        force = force + data.NvForce
        width = width + data.NvWidth
        damage = damage + data.NvDamage
      end -- There is atleast one beam that hits us
      for idx = (index + 1), ent:GetHitReports().Size do
        local hit = self:GetHitSourceID(ent, idx)
        if(hit) then
          local trace, data = ent:GetHitReport(idx)
          if(data) then
            force = force + data.NvForce
            width = width + data.NvWidth
            damage = damage + data.NvDamage
          end -- Check the rest of the beams and add power
        end
      end
      self:SetPushForce(force)
      self:SetBeamWidth(width)
      self:SetDamageAmount(damage)
    else
      self:SetPushForce(ent:GetPushForce())
      self:SetBeamWidth(ent:GetBeamWidth())
      self:SetDamageAmount(ent:GetDamageAmount())
    end
    self:SetBeamLength(ent:GetBeamLength())
  end

  self:WireWrite("Dominant", ent)

  local user = (ent.ply or ent.player)
  if(user and
     user:IsValid() and
     user:IsPlayer())
  then -- TODO: Is this OK with prop protection addons?
    self.ply    = user
    self.player = user
    self:SetCreator(user)
  end

  return self
end

function ENT:UpdateBeam()
  local opower, npower, force  = 0, 0, 0
  local width , length, damage = 0, 0, 0
  local apower, doment = 0 -- Dominant source

  if(self.Size > 0) then
    for cnt = 1, self.Size do
      local ent = self.Array[cnt]
      if(ent and ent:IsValid()) then
        for idx = 1, ent:GetHitReports().Size do
          local hit = self:GetHitSourceID(ent, idx)
          if(hit) then
            local trace, data = ent:GetHitReport(hit)
            if(data and trace.Hit) then
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

  if(self.Size > 0 and math.floor(mpower) > 0) then
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

      if(trent and trent:IsValid()) then
        self:WireWrite("Target", trent)
      else
        self:WireWrite("Target")
      end
    end

    self:DoDamage(trace, data)
  else
    self:WireWrite("Hit", 0)
    self:WireWrite("Target")
    self:WireWrite("Dominant")
  end

  self:WireWrite("Array", self.Array)
  self:WireWrite("Focusing", self.Size)
  self:NextThink(CurTime())

  return true
end
