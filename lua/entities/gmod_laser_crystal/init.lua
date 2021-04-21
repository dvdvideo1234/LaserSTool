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

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  local phys = self:GetPhysicsObject()
  if(phys:IsValid()) then phys:Wake() end

  self:SetupSources()
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
  self:SetDamageAmount(0)
  self:SetStartSound("ambient/energy/weld1.wav")
  self:SetStopSound("ambient/energy/weld2.wav")
  self:SetBeamMaterial("cable/physbeam")

  if(WireLib) then
    WireLib.CreateSpecialOutputs(self, {"Focusing", "Hit"})
  end
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  -- Sets the right angle at spawn. Thanks to aVoN!
  local pos = tr.HitPos + tr.HitNormal * 35
  local yaw = (ply:GetAimVector():Angle().y + 180) % 360
  local ent = ents.Create(LaserLib.GetClass(2, 2))
  ent:SetModel(LaserLib.GetModel(2, 1))
  ent:SetMaterial(LaserLib.GetMaterial(2, 1))
  ent:SetPos(pos)
  ent:SetAngles(Angle(0, yaw, 0))
  ent:Spawn()
  ent:Activate()
  ent:SetupBeamOrigin()
  return ent
end

function ENT:SetupSources()
  if(self.Sources) then
    table.Empty(self.Sources)
  else self.Sources = {} end
  self.Size, self.Hits = 0, 0
  return self
end

function ENT:IsSource(ent)
  if(not ent) then return false end
  if(not ent:IsValid()) then return false end
  if(ent == self) then return false end
  return (self.Sources[ent] ~= nil)
end

function ENT:ClearSources()
  for ent, data in pairs(self.Sources) do
    self.Sources[ent] = nil
  end; return self
end

function ENT:CountSources()
  self.Hits = 0
  for ent, data in pairs(self.Sources) do
    if(self:IsSource(ent)) then
      self.Hits = self.Hits + 1
    end
  end; return self.Hits
end

function ENT:InsertSource(ent, data)
  if(self:IsSource(ent)) then
    self.Sources[ent] = data
  else
    self.Size = self.Size + 1
    self.Sources[ent] = data
  end
  return self
end

function ENT:IsInfinite(ent)
  if(ent == self) then return true end
  local class = LaserLib.GetClass(2, 1)
  if(ent:GetClass() == class) then
    local flag = false -- Assume for no infinite loop
    for k, v in pairs(ent.Sources) do -- Check sources
      if(v) then -- Crystal has been hyt by other crystal
        if(k:GetClass() == class) then -- Check sources
          flag = k:IsInfinite(ent)
        else -- The source of the other one is not crystal
          flag = false
        end
        if(flag) then return true end
      end
    end
  else -- The entity is laser
    return false
  end
end

function ENT:UpdateDominant(ent)
  -- We set the same non-addable properties
  -- The most powerful laser (biggest damage/width)
  if(self:IsSource(ent)) then
    local user = (ent.ply or ent.player)
    self:SetPushProps(ent:GetPushProps())
    self:SetStopSound(ent:SetStopSound())
    self:SetKillSound(ent:GetKillSound())
    self:SetStartSound(ent:SetStartSound())
    self:SetBeamMaterial(ent:GetBeamMaterial())
    self:SetDissolveType(ent:GetDissolveType())
    self:SetEndingEffect(ent:GetEndingEffect())
    if(user and
       user:IsValid() and
       user:IsPlayer())
    then -- For prop protection addons
      self.ply    = user
      self.player = user
      self:SetCreator(user)
    end
  end
  return self
end

function ENT:UpdateBeam()
  local opower, npower = 0, 0
  local size  , dominant = self.Size
  local width , length, damage = 0, 0, 0

  if(size and size > 0) then
    for ent, data in pairs(self.Sources) do
      if(data and not self:IsInfinite(ent)) then
        width  = width  + data.NvWidth
        length = length + data.NvLength
        damage = damage + data.NvDamage
        npower = 3 * data.NvWidth + data.NvDamage

        if(npower > opower) then
          dominant, opower = ent, npower
        end
      end
    end
    width = LaserLib.GetBeamWidth(width)
    self:SetBeamWidth(width)
    self:SetBeamLength(length)
    self:SetDamageAmount(damage)
    self:UpdateDominant(dominant)
  end
end

function ENT:Think()
  local count = self:CountSources()

  if(count > 0) then
    self:UpdateBeam()
    self:SetOn(true)

    if(self:GetOn()) then

      local trace, data = self:DoBeam()

      if(WireLib) then
        if(trace.Entity and trace.Entity:IsValid()) then

          self:DoDamage(trace, data)

          WireLib.TriggerOutput(self, "Hit", 1)
        else
          WireLib.TriggerOutput(self, "Hit", 0)
        end
      end
    end

  else
    self:SetOn(false)
    self:SetupSources()
  end

  if(WireLib) then
    WireLib.TriggerOutput(self, "Focusing", count)
  end

  self:ClearSources()
  self:NextThink(CurTime())

  return true
end
