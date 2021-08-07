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

resource.AddFile("materials/vgui/entities/gmod_laser_splitter.vmt")

function ENT:InitSources()
  if(self.hitSources) then
    table.Empty(self.hitSources)
  else
    self.hitSources = {} -- Sources in notation `[ent] = true`
  end
  return self
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
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
    {"Entity"  , "ENTITY", "Splitter crystal entity" },
    {"Dominant", "ENTITY", "Splitter dominant entity"}
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then phys:Wake() end

  -- Detup default configuration
  self:InitSources()
  self:SetPushForce(0)
  self:SetBeamWidth(0)
  self:SetBeamCount(0)
  self:SetBeamLeanX(0)
  self:SetBeamLeanY(0)
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
  local ent = ents.Create(LaserLib.GetClass(4))
  if(LaserLib.IsValid(ent)) then
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
    ent:SetBeamTransform()
    ent:SetBeamCount(LaserLib.GetData("NSPLITER"):GetInt())
    ent:SetBeamLeanX(LaserLib.GetData("XSPLITER"):GetFloat())
    ent:SetBeamLeanY(LaserLib.GetData("YSPLITER"):GetFloat())
    return ent
  end; return nil
end

function ENT:GetDominant()
  local opower, doment, report
  for ent, stat in pairs(self.hitSources) do
    if(LaserLib.IsValid(ent)) then
      local idx = self:GetHitSourceID(ent)
      if(idx) then -- Only one beam can be the input
        local trace, data = ent:GetHitReport(idx)
        if(data) then
          local npower = LaserLib.GetPower(data.NvWidth,
                                           data.NvDamage)
          if(not opower or npower >= opower) then
            opower = npower
            doment = ent
            report = idx
          end
        else self.hitSources[ent] = nil end
      else self.hitSources[ent] = nil end
    else self.hitSources[ent] = nil end
  end

  if(not LaserLib.IsValid(doment)) then return nil end
  local count = self:GetBeamCount()
  if(count > 0) then
    local trace, data = doment:GetHitReport(report)
    if(data) then -- Dominant result hit
      self:SetPushForce(data.NvForce / count)
      self:SetBeamWidth(data.NvWidth / count)
      self:SetBeamLength(doment:GetBeamLength())
      self:SetDamageAmount(data.NvDamage / count)
    else -- Dominant did not hit anything
      self:SetPushForce(doment:GetPushForce() / count)
      self:SetBeamWidth(doment:GetBeamWidth() / count)
      self:SetBeamLength(doment:GetBeamLength())
      self:SetDamageAmount(doment:GetDamageAmount() / count)
    end -- The most powerful source (biggest damage/width)
  else
    self:SetPushForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetDamageAmount(0)
  end
  self:SetStopSound(doment:GetStopSound())
  self:SetKillSound(doment:GetKillSound())
  self:SetBeamColor(doment:GetBeamColor())
  self:SetStartSound(doment:GetStartSound())
  self:SetBeamMaterial(doment:GetBeamMaterial())
  self:SetDissolveType(doment:GetDissolveType())
  self:SetEndingEffect(doment:GetEndingEffect())
  self:SetReflectRatio(doment:GetReflectRatio())
  self:SetRefractRatio(doment:GetRefractRatio())
  self:SetForceCenter(doment:GetForceCenter())
  self:SetNonOverMater(doment:GetNonOverMater())

  -- We set the same non-addable properties
  self:WireWrite("Dominant", doment)
  LaserLib.SetPlayer(self, (doment.ply or doment.player))

  return doment
end

function ENT:Think()
  self:UpdateVectors()
  local mcount = self:GetBeamCount()
  local mwidth = self:GetBeamWidth()
  local mdamage = self:GetDamageAmount()
  local mdoment = self:GetDominant()
  local mpower = LaserLib.GetPower(mwidth, mdamage)

  if(mcount > 0 and
     LaserLib.IsValid(mdoment) and
     math.floor(mpower) > 0) then
    self:SetOn(true)
  else
    self:SetOn(false)
  end

  if(self:GetOn()) then
    local direc = self:GetDirectLocal()
    if(mcount > 1) then
      local delta = 360 / mcount
      local marbx = self:GetBeamLeanX()
      local marby = self:GetBeamLeanY()
      local eleva = self:GetElevatLocal()
      local angle = direc:AngleEx(eleva)
      for index = 1, mcount do
        local dir = marby * angle:Up()
              dir:Add(marbx * angle:Forward())
        self:DoDamage(self:DoBeam(nil, dir, index))
        angle:RotateAroundAxis(direc, delta)
      end
    else
      self:DoDamage(self:DoBeam(nil, direc))
    end
  else
    self:RemHitReports()
    self:WireWrite("Dominant")
  end

  self:NextThink(CurTime())

  return true
end
