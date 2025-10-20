AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_splitter.vmt")

local gtAMAX     = LaserLib.GetData("AMAX")
local cvNSPLITER = LaserLib.GetData("NSPLITER")
local cvXSPLITER = LaserLib.GetData("XSPLITER")
local cvYSPLITER = LaserLib.GetData("YSPLITER")
local cvZSPLITER = LaserLib.GetData("ZSPLITER")

function ENT:UpdateInternals()
  self.crOpower = nil
  self.crDoment = nil
  self.crDobeam = nil
  return self
end

function ENT:RegisterSource(ent)
  if(not self.meSources) then return self end
  self.meSources[ent] = true; return self
end

function ENT:InitSources()
  self.meSources = {} -- Sources in notation `[ent] = true`
  return self
end

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateOutputs(
    {"On"        , "NORMAL", "Splitter working state"  },
    {"Width"     , "NORMAL", "Splitter beam width"     },
    {"Length"    , "NORMAL", "Splitter length width"   },
    {"Damage"    , "NORMAL", "Splitter damage width"   },
    {"Force"     , "NORMAL", "Splitter force amount"   },
    {"Safety"    , "NORMAL", "Splitter beam safety"    },
    {"Disperse"  , "NORMAL", "Splitter beam disperse"  },
    {"Entity"    , "ENTITY", "Splitter entity itself"  },
    {"Dominant"  , "ENTITY", "Splitter dominant entity"}
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
  self:InitSources()
  self:SetBeamForce(0)
  self:SetBeamWidth(0)
  self:SetBeamCount(0)
  self:SetBeamLeanX(0)
  self:SetBeamLeanY(0)
  self:SetBeamLeanZ(0)
  self:SetBeamLength(0)
  self:SetBeamDamage(0)
  self:SetStopSound("")
  self:SetKillSound("")
  self:SetStartSound("")
  self:SetBeamMaterial("")
  self:SetDissolveType("")
  self:SetBeamSafety(false)
  self:SetForceCenter(false)
  self:SetBeamDisperse(false)
  self:SetEndingEffect(false)
  self:SetReflectRatio(false)
  self:SetRefractRatio(false)
  self:SetNonOverMater(false)
  self:SetBeamReplicate(false)
  self:SetBeamColorSplit(false)
  self:SetBeamColorRGBA(255,255,255,255)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local cas = LaserLib.GetClass(self.UnitID)
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(cas)
  if(LaserLib.IsValid(ent)) then
    LaserLib.SnapNormal(ent, tr, 90)
    ent:SetAngles(ang) -- Apply angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    LaserLib.SetVisuals(ply, ent, tr)
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetPlayer(ent, ply)
    ent:SetBeamTransform()
    ent:SetBeamCount(cvNSPLITER:GetInt())
    ent:SetBeamLeanX(cvXSPLITER:GetFloat())
    ent:SetBeamLeanY(cvYSPLITER:GetFloat())
    ent:SetBeamLeanZ(cvZSPLITER:GetFloat())
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

function ENT:EveryBeam(entity, index, beam)
  if(not beam) then return end
  local trace = beam:GetTarget()
  if(trace and trace.Hit) then
    local npower = LaserLib.GetPower(beam.NvWidth,
                                     beam.NvDamage)
    if(not self.crOpower or npower > self.crOpower) then
      self.crOpower, self.crDobeam, self.crDoment = npower, beam, entity
    end
  end
end

function ENT:UpdateSources()
  self:UpdateInternals()
  self:ProcessSources()

  local count = self:GetBeamCount()
  if(self.crDobeam and count > 0) then -- Dominant result hit
    self:SetBeamForce(self.crDobeam.NvForce)
    self:SetBeamWidth(self.crDobeam.NvWidth)
    self:SetBeamDamage(self.crDobeam.NvDamage)
    if(self:IsInfinite(self.crDoment)) then
      self:SetBeamLength(self.crDobeam.BmLength)
    else -- When not looping use the remaining
      self:SetBeamLength(self.crDobeam.NvLength)
    end -- Apply length based on looping
    -- Transfer visuals from the dominant
    self:SetDominant(self.crDobeam)
    -- Send the dominant entity
    return self.crDobeam:GetSource()
  else
    self:SetBeamForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetBeamDamage(0)
  end
end

function ENT:Think()
  self:UpdateVectors()
  local mcount = self:GetBeamCount()
  local mwidth = self:GetBeamWidth()
  local mdamage = self:GetBeamDamage()
  local mdoment = self:UpdateSources()

  if(mcount > 0 and
     LaserLib.IsValid(mdoment) and
     LaserLib.IsPower(mwidth, mdamage)) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  if(self:GetOn()) then
    local delta = gtAMAX[2] / mcount
    local forwd = self:GetDirectLocal()
    local upwrd = self:GetUpwardLocal()
    local angle = self:GetLeanAngle(forwd, upwrd)
    self:UpdateInit()
    for idx = 1, mcount do
      self:DoDamage(self:DoBeam(nil, angle:Forward(), idx))
      if(mcount > 1) then angle:RotateAroundAxis(forwd, delta) end
    end
    self:SetHitReportMax(true)
  else
    self:WireWrite("Width" , 0)
    self:WireWrite("Length", 0)
    self:WireWrite("Damage", 0)
    self:WireWrite("Force" , 0)
    self:WireWrite("Dominant")
    self:SetHitReportMax()
  end

  self:NextThink(CurTime())

  return true
end
