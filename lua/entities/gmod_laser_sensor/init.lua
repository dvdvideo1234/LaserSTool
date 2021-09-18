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
    {"Direct"  , "VECTOR", "Sensor surface normal" }
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Sensor enabled state"  },
    {"Width"   , "NORMAL", "Sensor beam width"     },
    {"Length"  , "NORMAL", "Sensor length width"   },
    {"Damage"  , "NORMAL", "Sensor damage width"   },
    {"Force"   , "NORMAL", "Sensor force amount"   },
    {"DotMatch", "NORMAL", "Sensor beam direction match"   },
    {"DotBound", "NORMAL", "Sensor beam direction bound"   },
    {"Origin"  , "VECTOR", "Sensor source beam origin"     },
    {"Direct"  , "VECTOR", "Sensor source beam direction"  },
    {"RatioRL" , "NORMAL", "Sensor source reflection ratio"},
    {"RatioRF" , "NORMAL", "Sensor source refraction ratio"},
    {"NoVrmat" , "NORMAL", "Sensor source ovr matyerial"   },
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
  self:SetBeamForce(0)
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
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
  local bmrefl, bmrefr, novrmt = 0, 0, 0
  local normh , normm  = 0, 0
  local origin, direct = Vector(), Vector()
  local opower, npower, force  = 0, 0, 0
  local width , length, damage = 0, 0, 0
  local apower, doment = 0, nil -- Dominant source

  if(self.hitSize > 0) then
    for ent, hit in pairs(self.hitSources) do
      if(hit and LaserLib.IsValid(ent)) then
        local idh = self:GetHitSourceID(ent)
        if(idh) then local idx, siz = idh, ent:GetHitReports().Size
          while(idx <= siz) do -- First index always hits when present
            if(idh) then
              local trace, data = ent:GetHitReport(idh)
              local dotmg, flag = self:IsHitNormal(trace)
              if(trace and trace.Hit and data and flag) then
                npower = LaserLib.GetPower(data.NvWidth, data.NvDamage)
                width  = width  + data.NvWidth
                damage = damage + data.NvDamage
                force  = force  + data.NvForce
                if(npower > opower) then
                  length = data.NvLength
                  origin:Set(data.VrOrigin)
                  direct:Set(data.VrDirect)
                  bmrefl = (data.BrReflec and 1 or 0)
                  bmrefr = (data.BrRefrac and 1 or 0)
                  novrmt = (data.BmNoover and 1 or 0)
                  normh  = (flag and 1 or 0)
                  normm  = dotmg
                  doment, opower = ent, npower
                end
              end end; idx = idx + 1
            idh = self:GetHitSourceID(ent, idx)
          end
        end
      end
    end

    self:WireWrite("Width" , width)
    self:WireWrite("Length", length)
    self:WireWrite("Damage", damage)
    self:WireWrite("Force" , force)
    self:WireWrite("Origin", origin)
    self:WireWrite("Direct", direct)
    self:WireWrite("RatioRL", bmrefl)
    self:WireWrite("RatioRF", bmrefr)
    self:WireWrite("NoVrmat", novrmt)
    self:WireWrite("DotMatch", normh)
    self:WireWrite("DotBound", normm)
    self:WireWrite("Dominant", doment)
    -- Read sensor configuration
    local mforce  = self:GetBeamForce()
    local mwidth  = self:GetBeamWidth()
    local mdirect = self:GetDirection()
    local mlength = self:GetBeamLength()
    local mdamage = self:GetBeamDamage()
    -- Check whenever sensor has to turn on
    if(LaserLib.IsValid(doment) and
       (mforce  == 0 or (mforce  > 0 and force  >= mforce)) and
       (mwidth  == 0 or (mwidth  > 0 and width  >= mwidth)) and
       (mlength == 0 or (mlength > 0 and length >= mlength)) and
       (mdamage == 0 or (mdamage > 0 and damage >= mdamage)) and
       (mdirect:IsZero() or (normh > 0))) then
      self:SetOn(true)
    else
      self:SetOn(false)
    end
  else
    self:SetOn(false)
    self:WireWrite("Width" , width)
    self:WireWrite("Length", length)
    self:WireWrite("Damage", damage)
    self:WireWrite("Force" , force)
    self:WireWrite("Origin", origin)
    self:WireWrite("Direct", direct)
    self:WireWrite("RatioRL", bmrefl)
    self:WireWrite("RatioRF", bmrefr)
    self:WireWrite("NoVrmat", novrmt)
    self:WireWrite("DotMatch", normh)
    self:WireWrite("DotBound", normm)
    self:WireWrite("Dominant", doment)
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
