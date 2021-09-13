AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_sensor.vmt")

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end

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

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal"  , "VECTOR", "Sensor surface normal" }
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Sensor enabled state"  },
    {"Normal"  , "VECTOR", "Sensor surface normal" },
    {"Width"   , "NORMAL", "Sensor beam width"     },
    {"Length"  , "NORMAL", "Sensor length width"   },
    {"Damage"  , "NORMAL", "Sensor damage width"   },
    {"Force"   , "NORMAL", "Sensor force amount"   },
    {"Entity"  , "ENTITY", "Sensor entity itself"  },
    {"Dominant", "ENTITY", "Sensor dominant entity"},
    {"Count"   , "NORMAL", "Sensor sources count"  },
    {"Array"   , "ARRAY" , "Sensor sources array"  }
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then phys:Wake() end

  -- Detup default configuration
  self:InitSources()
  self:SetPushForce(0)
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
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
  local ent = ents.Create(LaserLib.GetClass(6))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(6))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(6))
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    ent:SetBeamTransform()
    LaserLib.SetPlayer(ent, ply)
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
  end
  if(self.hitSize > 0) then
    self:WireWrite("Count", self.hitSize)
    self:WireWrite("Array", self.hitArray)
  else
    self:WireWrite("Count", 0)
    self:WireWrite("Array")
  end
  return self -- Sources are located in the table hash part
end

function ENT:UpdateDominant()
  local opower, npower, force  = 0, 0, 0
  local width , length, damage = 0, 0, 0
  local apower, doment = 0 -- Dominant source

  if(self.hitSize > 0) then
    for cnt = 1, self.hitSize do
      local ent = self.hitArray[cnt]
      if(LaserLib.IsValid(ent)) then
        local idx = self:GetHitSourceID(ent)
        if(idx) then
          for cdx = 1, ent:GetHitReports().Size do
            local hit = self:GetHitSourceID(ent, cdx)
            if(hit) then
              local trace, data = ent:GetHitReport(hit)
              if(trace and trace.Hit and data and self:IsHitNormal(trace)) then
                npower = LaserLib.GetPower(data.NvWidth,
                                           data.NvDamage)
                width  = width  + data.NvWidth
                damage = damage + data.NvDamage
                force  = force  + data.NvForce
                if(npower > opower) then
                  length = data.NvLength
                  doment, opower = ent, npower
                end
              end
            end
          end
        end
      end
    end
    self:WireWrite("Width" , width)
    self:WireWrite("Length", length)
    self:WireWrite("Damage", damage)
    self:WireWrite("Force" , force)
    self:WireWrite("Dominant", doment)
    -- Read sensor configuration
    local mforce  = self:GetPushForce()
    local mwidth  = self:GetBeamWidth()
    local mlength = self:GetBeamLength()
    local mdamage = self:GetDamageAmount()
    -- Check whenever sensor has to turn on
    if(LaserLib.IsValid(doment) and
       (mforce  == 0 or (mforce  > 0 and force  >= mforce)) and
       (mwidth  == 0 or (mwidth  > 0 and width  >= mwidth)) and
       (mlength == 0 or (mlength > 0 and length >= mlength)) and
       (mdamage == 0 or (mdamage > 0 and damage >= mdamage))) then
      self:SetOn(true)
    else
      self:SetOn(false)
    end
  else
    self:SetOn(false)
    self:WireWrite("Width" , 0)
    self:WireWrite("Length", 0)
    self:WireWrite("Damage", 0)
    self:WireWrite("Force" , 0)
    self:WireWrite("Dominant")
  end

  return self
end

function ENT:Think()
  self:UpdateSources()
  self:UpdateDominant()

  if(self:GetOn()) then
    self:WireWrite("On", 1)
  else
    self:WireWrite("On", 0)
  end

  self:NextThink(CurTime())

  return true
end
