AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_splitter.vmt")

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:InitSources()
  self.hitSources = {} -- Sources in notation `[ent] = true`
  return self
end

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateOutputs(
    {"On"      , "NORMAL", "Splitter working state"  },
    {"Width"   , "NORMAL", "Splitter beam width"     },
    {"Length"  , "NORMAL", "Splitter length width"   },
    {"Damage"  , "NORMAL", "Splitter damage width"   },
    {"Force"   , "NORMAL", "Splitter force amount"   },
    {"Entity"  , "ENTITY", "Splitter entity itself"  },
    {"Dominant", "ENTITY", "Splitter dominant entity"}
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
  self:SetBeamLength(0)
  self:SetBeamDamage(0)
  self:SetStopSound("")
  self:SetKillSound("")
  self:SetStartSound("")
  self:SetBeamMaterial("")
  self:SetDissolveType("")
  self:SetBeamReplicate(false)
  self:SetEndingEffect(false)
  self:SetReflectRatio(false)
  self:SetRefractRatio(false)
  self:SetForceCenter(false)
  self:SetNonOverMater(false)
  self:SetBeamColorSplit(false)
  self:SetBeamColorRGBA(255,255,255,255)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(4, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(4))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(4))
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetPlayer(ent, ply)
    ent:SetBeamTransform()
    ent:SetBeamCount(LaserLib.GetData("NSPLITER"):GetInt())
    ent:SetBeamLeanX(LaserLib.GetData("XSPLITER"):GetFloat())
    ent:SetBeamLeanY(LaserLib.GetData("YSPLITER"):GetFloat())
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

local opower, doment, dobeam

function ENT:EveryBeacon(entity, index, trace, beam)
  if(trace and trace.Hit and beam) then
    local npower = LaserLib.GetPower(beam.NvWidth,
                                     beam.NvDamage)
    if(not opower or npower > opower) then
      opower, dobeam, doment = npower, beam, entity
    end
  end
end

function ENT:UpdateSources()
  opower, dobeam, doment = nil, nil, nil

  self:ProcessSources()

  local count = self:GetBeamCount()
  if(dobeam and count > 0) then -- Dominant result hit
    self:SetBeamForce(dobeam.NvForce)
    self:SetBeamWidth(dobeam.NvWidth)
    self:SetBeamDamage(dobeam.NvDamage)
    if(self:IsInfinite(doment)) then
      self:SetBeamLength(dobeam.BmLength)
    else -- When not looping use the remaining
      self:SetBeamLength(dobeam.NvLength)
    end -- Apply length based on looping
    -- Transfer visuals from the dominant
    self:SetDominant(dobeam)
    -- Send the dominant entity
    return dobeam.BmSource
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
    local direc = self:GetDirectLocal()
    if(mcount > 1) then
      local fulla = LaserLib.GetData("AMAX")[2]
      local delta = fulla / mcount
      local marbx = self:GetBeamLeanX()
      local marby = self:GetBeamLeanY()
      local upwrd = self:GetUpwardLocal()
      local angle = direc:AngleEx(upwrd)
      self:UpdateFlags()
      for index = 1, mcount do
        local dir = marby * angle:Up()
              dir:Add(marbx * angle:Forward())
        self:DoDamage(self:DoBeam(nil, dir, index))
        angle:RotateAroundAxis(direc, delta)
      end
    else
      self:DoDamage(self:DoBeam(nil, direc))
    end
    self:SetHitReportMax(mcount)
  else
    self:SetHitReportMax()
    self:WireWrite("Width" , 0)
    self:WireWrite("Length", 0)
    self:WireWrite("Damage", 0)
    self:WireWrite("Force" , 0)
    self:WireWrite("Dominant")
  end

  self:NextThink(CurTime())

  return true
end
