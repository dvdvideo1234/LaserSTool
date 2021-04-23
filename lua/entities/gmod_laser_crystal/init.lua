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

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateOutputs(
    {"On"      , "NORMAL", "Concentrator working state"  },
    {"Width"   , "NORMAL", "Concentrator beam width"     },
    {"Length"  , "NORMAL", "Concentrator length width"   },
    {"Damage"  , "NORMAL", "Concentrator damage width"   },
    {"Force"   , "NORMAL", "Concentrator force amount"   },
    {"Focusing", "NORMAL", "How many sources are focused"},
    {"Hit"     , "NORMAL", "Indicates entity crystal hit"},
    {"Entity"  , "ENTITY", "Concentrator crystal entity" },
    {"Dominant", "ENTITY", "Concentrator dominant entity"},
    {"Target"  , "ENTITY", "Concentrator target entity"  },
    {"Array"   , "ARRAY" , "Concentrated sources array"  }
  )

  local phys = self:GetPhysicsObject()
  if(phys:IsValid()) then phys:Wake() end

  -- Detup default configuration
  self:SetupSources()
  self:SetPushForce(0)
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
  self:SetDamageAmount(0)
  self:SetStartSound("")
  self:SetStopSound("")
  self:SetKillSound("")
  self:SetBeamMaterial("")
  self:SetDissolveType("")
  self:SetEndingEffect(false)
  self:SetReflectionRate(false)
  self:SetRefractionRate(false)
  self:SetForceCenter(false)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  -- Sets the right angle at spawn. Thanks to aVoN!
  local pos = tr.HitPos + tr.HitNormal * 35
  local yaw = (ply:GetAimVector():Angle().y + 180) % 360
  local ent = ents.Create(LaserLib.GetClass(2, 2))
  ent:SetModel(LaserLib.GetModel(2, 1))
  ent:SetMaterial(LaserLib.GetMaterial(2, 1))
  ent:SetPos(pos)
  ent:SetAngles(Angle(0, yaw, 0))
  ent:Spawn()
  ent:Activate()
  ent:SetupBeamTransform()
  return ent
end

function ENT:SetupSources()
  if(self.Sources) then
    table.Empty(self.Sources)
    table.Empty(self.Array)
  else
    self.Sources = {} -- Sources in notation `[ent] = data`
    self.Array   = {} -- Array to output for wiremod
  end
  self.Size = 0     -- Amount of sources to have
  return self
end

function ENT:InsertSource(ent, data)
  self.Sources[ent] = data; return self
end

function ENT:RemoveSource(ent, data)
  self.Sources[ent] = nil; return self
end

function ENT:IsInfinite(ent)
  if(ent == self) then return true end
  local class = LaserLib.GetClass(2, 1)
  if(ent:GetClass() == class) then
    local flag = false -- Assume for no infinite loop
    for k, v in pairs(ent.Sources) do -- Check sources
      if(v) then -- Crystal has been hyt by other crystal
        if(k:GetClass() == class) then -- Check sources
          flag = k:IsInfinite(ent)
        else -- The source of the other one is not crystal
          flag = false
        end
        if(flag) then return true end
      end
    end
  else -- The entity is laser
    return false
  end
end

function ENT:IsSource(ent)
  if(not ent) then return false end
  if(not ent:IsValid()) then return false end
  if(ent == self) then return false end
  local data = self.Sources[ent] -- Read source item
  if(not data) then return false end
  local trace = data.TeTarget -- Check source trace
  if(not trace) then return false end
  if(not trace.Hit) then return false end
  local ehit = trace.Entity -- Check source entity
  if(not ehit) then return false end
  if(not ehit:IsValid()) then return false end
  return (ehit == self) -- With traces hitting this
end

function ENT:ClearSources()
  table.Empty(self.Array)
  self.Size = 0; return self
end

function ENT:CountSources()
  self.Size = 0 -- Add sources in array
  for ent, data in pairs(self.Sources) do
    local src = self:IsSource(ent)
    LaserLib.Print(1, print, ent, data, src)
    if(src) then
      self.Size = self.Size + 1
      self.Array[self.Size] = ent
    else -- When not a source. Clear the slot
      self.Sources[ent] = nil -- Wipe out the entry
    end -- The sources order does not matter
  end -- Sources are located in the table hash part
  self:WireWrite("Array", self.Array)
end

function ENT:UpdateDominant(ent)
  if(not ent) then return self end
  if(not ent:IsValid()) then return self end
  -- We set the same non-addable properties
  -- The most powerful laser (biggest damage/width)
  local user = (ent.ply or ent.player)
  self:SetPushForce(ent:GetPushForce())
  self:SetStopSound(ent:SetStopSound())
  self:SetKillSound(ent:GetKillSound())
  self:SetStartSound(ent:SetStartSound())
  self:SetBeamMaterial(ent:GetBeamMaterial())
  self:SetDissolveType(ent:GetDissolveType())
  self:SetEndingEffect(ent:GetEndingEffect())
  self:SetReflectionRate(ent:GetReflectionRate())
  self:SetRefractionRate(ent:GetRefractionRate())
  self:SetForceCenter(ent:GetForceCenter())

  self:WireWrite("Dominant", ent)

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
  local dominant -- Stores the dominant source

  if(self.Size > 0) then
    for ent, data in pairs(self.Sources) do
      if(data and not self:IsInfinite(ent)) then
        width  = width  + data.NvWidth
        length = length + data.NvLength
        damage = damage + data.NvDamage
        force  = force  + data.NvForce
        npower = 3 * data.NvWidth + data.NvDamage

        if(npower > opower) then
          dominant, opower = ent, npower
        end
      end
    end
    self:UpdateDominant(dominant)
  end

  self:SetPushForce(force)
  self:SetBeamWidth(width)
  self:SetBeamLength(length)
  self:SetDamageAmount(damage)
end

function ENT:Think()
  self:CountSources()

  if(self.Size > 0) then
    self:UpdateBeam()
    self:SetOn(true)

    if(self:GetOn()) then
      self:DoDamage(self:DoBeam())
    end
  else
    self:SetOn(false)
  end

  self:WireWrite("Focusing", self.Size)

  self:ClearSources()
  self:NextThink(CurTime())

  return true
end
