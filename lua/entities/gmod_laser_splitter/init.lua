AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_splitter.vmt")

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end

function ENT:InitSources()
  if(self.hitSources) then
    table.Empty(self.hitSources)
  else
    self.hitSources = {} -- Sources in notation `[ent] = true`
  end
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
  self:SetBeamColor(Vector(1,1,1))

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
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
    ent:SetBeamTransform()
    ent:SetBeamCount(LaserLib.GetData("NSPLITER"):GetInt())
    ent:SetBeamLeanX(LaserLib.GetData("XSPLITER"):GetFloat())
    ent:SetBeamLeanY(LaserLib.GetData("YSPLITER"):GetFloat())
    return ent
  end; return nil
end

function ENT:UpdateSources()
  local opower, report, doment, domsrc
  self:ProcessSources(function(entity, index, trace, data)
    if(trace and trace.Hit and data) then
      local npower = LaserLib.GetPower(data.NvWidth,
                                       data.NvDamage)
      if(not opower or npower >= opower) then
        opower, report = npower, index
        doment, domsrc = entity, data.BmSource
      end
    end
  end)

  if(not LaserLib.IsValid(doment)) then return nil end
  if(not LaserLib.IsValid(domsrc)) then return nil end
  local count = self:GetBeamCount()
  if(count > 0) then
    local trace, data = doment:GetHitReport(report)
    if(data) then -- Dominant result hit
      self:SetBeamForce(data.NvForce)
      self:SetBeamWidth(data.NvWidth)
      self:SetBeamDamage(data.NvDamage)
      if(self:IsInfinite(doment)) then
        self:SetBeamLength(data.BmLength)
      else -- When not looping use the remaining
        self:SetBeamLength(data.NvLength)
      end -- Apply length based on looping
    else -- Dominant did not hit anything
      self:SetBeamForce(domsrc:GetBeamForce())
      self:SetBeamWidth(domsrc:GetBeamWidth())
      self:SetBeamDamage(domsrc:GetBeamDamage())
      self:SetBeamLength(domsrc:GetBeamLength())
    end -- The most powerful source (biggest damage/width)
  else
    self:SetBeamForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetBeamDamage(0)
  end

  self:SetDominant(domsrc)

  return domsrc
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
      local eleva = self:GetElevatLocal()
      local angle = direc:AngleEx(eleva)
      self:DrawEffects()
      for index = 1, mcount do
        local dir = marby * angle:Up()
              dir:Add(marbx * angle:Forward())
        self:DoDamage(self:DoBeam(nil, dir, index))
        angle:RotateAroundAxis(direc, delta)
      end
    else
      self:DoDamage(self:DoBeam(nil, direc))
    end
    self:RemHitReports(mcount)
  else
    self:RemHitReports()
    self:WireWrite("Width" , 0)
    self:WireWrite("Length", 0)
    self:WireWrite("Damage", 0)
    self:WireWrite("Force" , 0)
    self:WireWrite("Dominant")
  end

  self:NextThink(CurTime())

  return true
end
