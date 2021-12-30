AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")

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

local doment , domsrc
local xlength, bpower
local xforce , xwidth, xdamage
local opower , npower, force
local width  , length, damage

function ENT:ActionSource(entity, index, trace, data)
  if(trace and trace.Hit and data) then
    self:SetArrays(entity)
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
    if(not opower or npower >= opower) then
      opower = npower
      domsrc = data.BmSource
      doment = entity
    end
  end
end

function ENT:UpdateSources()
  self.hitSize = 0 -- Add sources in array
  doment , domsrc = nil, nil
  xlength, bpower = 0, false
  xforce , xwidth, xdamage = 0, 0, 0
  width  , length, damage  = 0, 0, 0
  npower , force , opower  = 0, 0, nil

  self:ProcessSources()

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

  self:WireArrays()

  self:NextThink(CurTime())

  return true
end
