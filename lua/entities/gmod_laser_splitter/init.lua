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
        for cnt = 1, ent:GetHitReports().Size do
          local trace, data = ent:GetHitReport(cnt)
          if(trace and trace.Hit and data) then
            local npower = LaserLib.GetPower(data.NvWidth,
                                             data.NvDamage)
            if(not opower or npower >= opower) then
              opower = npower
              doment = ent
              report = cnt
            end
          end
        end
      else self.hitSources[ent] = nil end
    else self.hitSources[ent] = nil end
  end

  if(not LaserLib.IsValid(doment)) then return nil end
  local dom = doment:GetHitDominant(self)
  if(not LaserLib.IsValid(dom)) then return nil end
  local count = self:GetBeamCount()
  if(count > 0) then
    local trace, data = doment:GetHitReport(report)
    if(data) then -- Dominant result hit
      self:SetPushForce(data.NvForce)
      self:SetBeamWidth(data.NvWidth)
      self:SetDamageAmount(data.NvDamage)
      if(self:IsInfinite(doment)) then
        self:SetBeamLength(data.BmLength)
      else -- When not looping use the remaining
        self:SetBeamLength(data.NvLength)
      end -- Apply length based on looping
    else -- Dominant did not hit anything
      self:SetPushForce(dom:GetPushForce())
      self:SetBeamWidth(dom:GetBeamWidth())
      self:SetDamageAmount(dom:GetDamageAmount())
      self:SetBeamLength(dom:GetBeamLength())
    end -- The most powerful source (biggest damage/width)
  else
    self:SetPushForce(0)
    self:SetBeamWidth(0)
    self:SetBeamLength(0)
    self:SetDamageAmount(0)
  end
  self:SetStopSound(dom:GetStopSound())
  self:SetKillSound(dom:GetKillSound())
  self:SetBeamColor(dom:GetBeamColor())
  self:SetStartSound(dom:GetStartSound())
  self:SetBeamMaterial(dom:GetBeamMaterial())
  self:SetDissolveType(dom:GetDissolveType())
  self:SetEndingEffect(dom:GetEndingEffect())
  self:SetReflectRatio(dom:GetReflectRatio())
  self:SetRefractRatio(dom:GetRefractRatio())
  self:SetForceCenter(dom:GetForceCenter())
  self:SetNonOverMater(dom:GetNonOverMater())

  -- We set the same non-addable properties
  self:WireWrite("Dominant", dom)
  LaserLib.SetPlayer(self, (dom.ply or dom.player))

  return dom
end

function ENT:Think()
  self:UpdateVectors()
  local mcount = self:GetBeamCount()
  local mwidth = self:GetBeamWidth()
  local mdamage = self:GetDamageAmount()
  local mdoment = self:GetDominant()
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
