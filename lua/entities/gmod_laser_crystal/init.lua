AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")

local CLMX = LaserLib.GetData("CLMX")

function ENT:UpdateInternals(init)
  if(init) then
    self.hitSize = 0
    self.crXlength, self.crBpower = nil, nil
    self.crXforce , self.crXwidth, self.crXdamage = nil, nil, nil
    self.crOpower , self.crNpower, self.crForce   = nil, nil, nil
    self.crWidth  , self.crLength, self.crDamage  = nil, nil, nil
    self.crDoment , self.crDobeam, self.crNcolor  = nil, nil, nil
    self.crDomcor = Color(0,0,0,0)
    self.crXomcor = Color(0,0,0,0)
  else
    self.hitSize = 0 -- Add sources in array
    self.crXlength, self.crBpower = 0, false
    self.crXforce , self.crXwidth, self.crXdamage = 0  , 0  , 0
    self.crOpower , self.crNpower, self.crForce   = nil, 0  , 0
    self.crWidth  , self.crLength, self.crDamage  = 0  , 0  , 0
    self.crDoment , self.crDobeam, self.crNcolor  = nil, nil, nil
    self.crDomcor.r, self.crDomcor.g = 0, 0
    self.crDomcor.b, self.crDomcor.a = 0, 0
    self.crXomcor.r, self.crXomcor.g = 0, 0
    self.crXomcor.b, self.crXomcor.a = 0, 0
  end
  return self
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:InitSources()
  self:UpdateInternals(true) -- Amount of sources to have
  self.hitSources = {} -- Sources in notation `[ent] = true`
  self:InitArrays("Array")
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
    {"Safety"  , "NORMAL", "Concentrator beam safety"    },
    {"Entity"  , "ENTITY", "Concentrator entity itself"  },
    {"Dominant", "ENTITY", "Concentrator dominant entity"},
    {"Target"  , "ENTITY", "Concentrator target entity"  },
    {"Count"   , "NORMAL", "Concentrated sources count"  },
    {"Array"   , "ARRAY" , "Concentrated sources array"  }
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
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
  self:SetBeamSafety(false)
  self:SetForceCenter(false)
  self:SetEndingEffect(false)
  self:SetReflectRatio(false)
  self:SetRefractRatio(false)
  self:SetNonOverMater(false)
  self:SetBeamColorMerge(false)
  self:SetBeamColorRGBA(255,255,255,255)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local gen = LaserLib.GetTool()
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
    LaserLib.SetReplace(ply, 2, ent, tr.Entity)
    ent:SetBeamTransform()
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetPlayer(ent, ply)
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

function ENT:EveryBeam(entity, index, beam, trace)
  if(trace and trace.Hit and beam) then
    self:SetArrays(entity)
    local mrg = self:GetBeamColorMerge()
    if(mrg) then self.crNcolor = beam:GetColorRGBA(true) end
    self.crNpower = LaserLib.GetPower(beam.NvWidth,
                               beam.NvDamage)
    if(not self:IsInfinite(entity)) then
      self.crBpower = (self.crBpower or true)
      self.crForce = self.crForce + beam.NvForce
      self.crWidth = self.crWidth + beam.NvWidth
      self.crLength = self.crLength + beam.NvLength
      self.crDamage = self.crDamage + beam.NvDamage
      if(mrg) then
        self.crDomcor.r = self.crDomcor.r + self.crNcolor.r
        self.crDomcor.g = self.crDomcor.g + self.crNcolor.g
        self.crDomcor.b = self.crDomcor.b + self.crNcolor.b
        self.crDomcor.a = math.max(self.crDomcor.a, self.crNcolor.a)
      end
    else
      if(self.crDoment ~= entity) then
        self.crXforce = beam.NvForce
        self.crXwidth = beam.NvWidth
        self.crXdamage = beam.NvDamage
        self.crXlength = beam:GetLength()
        if(mrg) then
          self.crXomcor.r = self.crNcolor.r
          self.crXomcor.g = self.crNcolor.g
          self.crXomcor.b = self.crNcolor.b
          self.crXomcor.a = math.max(self.crXomcor.a, self.crNcolor.a)
        end
      else
        self.crXforce = self.crXforce + beam.NvForce
        self.crXwidth = self.crXwidth + beam.NvWidth
        self.crXdamage = self.crXdamage + beam.NvDamage
        if(mrg) then
          self.crXomcor.r = self.crXomcor.r + self.crNcolor.r
          self.crXomcor.g = self.crXomcor.g + self.crNcolor.g
          self.crXomcor.b = self.crXomcor.b + self.crNcolor.b
          self.crXomcor.a = math.max(self.crXomcor.a, self.crNcolor.a)
        end
      end
    end
    if(not self.crOpower or self.crNpower > self.crOpower) then
      self.crOpower = self.crNpower
      self.crDoment = entity
      self.crDobeam = beam
    end
  end
end

function ENT:DominantColor(beam, cov)
  local mar = math.max(cov.r, cov.g, cov.b)
  if(mar > 0) then
    if(mar > CLMX) then
      cov.r = (cov.r / mar) * CLMX
      cov.g = (cov.g / mar) * CLMX
      cov.b = (cov.b / mar) * CLMX
    end
    self:SetDominant(beam, cov)
  else
    self:SetDominant(beam)
  end
end

function ENT:UpdateSources()
  self:UpdateInternals()
  self:ProcessSources()

  if(self.hitSize > 0) then
    if(self:GetBeamColorMerge()) then
      if(self.crBpower) then -- No infinite
        self:DominantColor(self.crDobeam, self.crDomcor)
      else -- Utilize the loop color
        self:DominantColor(self.crDobeam, self.crXomcor)
      end -- Use regular dominant
    else self:SetDominant(self.crDobeam) end

    if(self.crBpower) then -- Sum settings
      self:SetBeamForce(self.crForce)
      self:SetBeamWidth(self.crWidth)
      self:SetBeamLength(self.crLength)
      self:SetBeamDamage(self.crDamage)
    else -- Inside an active entity loop
      self:SetBeamForce(self.crXforce)
      self:SetBeamWidth(self.crXwidth)
      self:SetBeamDamage(self.crXdamage)
      self:SetBeamLength(self.crXlength)
    end
  else
    self:SetBeamForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetBeamDamage(0)
    self:SetHitReportMax()
  end

  return self:UpdateArrays()
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
    self:UpdateFlags()
    local beam, trace = self:DoBeam()

    if(beam) then
      self:WireWrite("Range", beam.RaLength)
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

    self:DoDamage(beam, trace)
  else
    self:SetHitReportMax()
    self:WireWrite("Hit", 0)
    self:WireWrite("Range", 0)
    self:WireWrite("Target")
    self:WireWrite("Dominant")
  end

  self:WireArrays()

  self:NextThink(CurTime())

  return true
end
