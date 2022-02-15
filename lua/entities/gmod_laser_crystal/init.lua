AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")

local CLMX = LaserLib.GetData("CLMX")

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:InitSources()
  self.hitSize = 0     -- Amount of sources to have
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
  self:SetEndingEffect(false)
  self:SetReflectRatio(false)
  self:SetRefractRatio(false)
  self:SetForceCenter(false)
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
    LaserLib.SetProperties(ent, "metal")
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
    LaserLib.SetPlayer(ent, ply)
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

local xlength, bpower
local xforce , xwidth, xdamage
local opower , npower, force
local width  , length, damage
local doment , dobeam, ncolor
local domcor = Color(0,0,0,0)
local xomcor = Color(0,0,0,0)

function ENT:EveryBeacon(entity, index, trace, beam)
  if(trace and trace.Hit and beam) then
    self:SetArrays(entity)
    local mrg = self:GetBeamColorMerge()
    if(mrg) then ncolor = beam:GetColorRGBA(true) end
    npower = LaserLib.GetPower(beam.NvWidth,
                               beam.NvDamage)
    if(not self:IsInfinite(entity)) then
      bpower = (bpower or true)
      force = force + beam.NvForce
      width = width + beam.NvWidth
      length = length + beam.NvLength
      damage = damage + beam.NvDamage
      if(mrg) then
        domcor.r = domcor.r + ncolor.r
        domcor.g = domcor.g + ncolor.g
        domcor.b = domcor.b + ncolor.b
        domcor.a = math.max(domcor.a, ncolor.a)
      end
    else
      if(doment ~= entity) then
        xforce = beam.NvForce
        xwidth = beam.NvWidth
        xdamage = beam.NvDamage
        xlength = (beam.BoLength or beam.BmLength)
        if(mrg) then
          xomcor.r = ncolor.r
          xomcor.g = ncolor.g
          xomcor.b = ncolor.b
          xomcor.a = math.max(xomcor.a, ncolor.a)
        end
      else
        xforce = xforce + beam.NvForce
        xwidth = xwidth + beam.NvWidth
        xdamage = xdamage + beam.NvDamage
        if(mrg) then
          xomcor.r = xomcor.r + ncolor.r
          xomcor.g = xomcor.g + ncolor.g
          xomcor.b = xomcor.b + ncolor.b
          xomcor.a = math.max(xomcor.a, ncolor.a)
        end
      end
    end
    if(not opower or npower > opower) then
      opower = npower
      doment = entity
      dobeam = beam
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
  self.hitSize = 0 -- Add sources in array
  domcor.r, domcor.g = 0, 0
  domcor.b, domcor.a = 0, 0
  xomcor.r, xomcor.g = 0, 0
  xomcor.b, xomcor.a = 0, 0
  doment , dobeam = nil, nil
  xlength, bpower, ncolor  = 0, false
  xforce , xwidth, xdamage = 0, 0, 0
  width  , length, damage  = 0, 0, 0
  npower , force , opower  = 0, 0, nil

  self:ProcessSources()

  if(self.hitSize > 0) then
    if(self:GetBeamColorMerge()) then
      if(bpower) then -- No infinite
        self:DominantColor(dobeam, domcor)
      else -- Utilize the loop color
        self:DominantColor(dobeam, xomcor)
      end -- Use regular dominant
    else self:SetDominant(dobeam) end

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
    local trace, beam = self:DoBeam()

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

    self:DoDamage(trace, beam)
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
