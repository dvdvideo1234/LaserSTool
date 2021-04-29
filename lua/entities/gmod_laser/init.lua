AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:PreEntityCopy()
  self:WirePreEntityCopy()
end

function ENT:PostEntityPaste(ply, ent, created)
  self:WirePostEntityPaste(ply, ent, created)
end

function ENT:ApplyDupeInfo(ply, ent, info, fentid)
  self:WireApplyDupeInfo(ply, ent, info, fentid)
end

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)

  self:WireCreateInputs(
    {"On"    , "NORMAL", "Turns the laser on/off" },
    {"Length", "NORMAL", "Updates the beam length"},
    {"Width" , "NORMAL", "Updates the beam width" },
    {"Damage", "NORMAL", "Updates the beam damage"},
    {"Force" , "NORMAL", "Updates the beam force" }
  ):WireCreateOutputs(
    {"On"    , "NORMAL", "Laser entiy status"     },
    {"Hit"   , "NORMAL", "Laser entity hit"       },
    {"Length", "NORMAL", "Updates the beam length"},
    {"Width" , "NORMAL", "Updates the beam width" },
    {"Damage", "NORMAL", "Updates the beam damage"},
    {"Force" , "NORMAL", "Updates the beam force" },
    {"Target", "ENTITY", "Laser entity target"    },
    {"Entity", "ENTITY", "Laser entity itself"    }
  )

  local phys = self:GetPhysicsObject()
  if(phys:IsValid()) then phys:Wake() end

  self:WireWrite("Entity", self)
end

function ENT:DoDamage(trace, data)
  -- TODO : Make the owner of the mirror get the kill instead of the owner of the laser
  if(trace) then
    local trent = trace.Entity

    if(trace.Hit) then
      self:WireWrite("Hit", 1)
    else
      self:WireWrite("Hit", 0)
    end

    if(trent and trent:IsValid()) then
      self:WireWrite("Target", trent)

      if(LaserLib.IsSource(trent)) then
        -- Register the source to the concentator
        if(trent:GetClass() == LaserLib.GetClass(2, 1)) then
          trent:SetSource(self)
        end
        -- When the trace is not a source we try to kill it
      else
        local dissolveType = self:GetDissolveType()
        LaserLib.DoDamage(trent,
                          trace.HitPos,
                          trace.Normal,
                          data.VrDirect,
                          data.NvDamage,
                          data.NvForce,
                          self:GetCreator(),
                          LaserLib.GetDissolveID(dissolveType),
                          self:GetKillSound(),
                          self:GetForceCenter(),
                          self)
      end
    else
      self:WireWrite("Hit", 0)
      self:WireWrite("Target")
    end
  end

  return self
end

function ENT:DoBeam()
  local force  = self:GetPushForce()
  local width  = self:GetBeamWidth()
  local origin = self:GetBeamOrigin()
  local length = self:GetBeamLength()
  local damage = self:GetDamageAmount()
  local direct = self:GetBeamDirection()
  local usrfle = self:GetReflectionRate()
  local usrfre = self:GetRefractionRate()
  local trace, data = LaserLib.DoBeam(self,
                                      origin,
                                      direct,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre)
  return trace, data
end

function ENT:Think()
  if(self:GetOn()) then
    self:DoDamage(self:DoBeam())
  end

  self:NextThink(CurTime())
  return true
end

function ENT:OnRemove()
  self:WireRemove()
end

function ENT:OnRestore()
  self:WireRestored()
end

function ENT:TriggerInput(iname, value)
  if(iname == "On") then
    self:SetOn(value)
  elseif(iname == "Length") then
    self:SetBeamLength(self:WireRead("Length", true) or self.defaultLength)
  elseif(iname == "Width") then
    self:SetBeamWidth(self:WireRead("Width", true) or self.defaultWidth)
  elseif(iname == "Damage") then
    self:SetDamageAmount(self:WireRead("Damage", true) or self.defaultDamage)
  elseif(iname == "Force") then
    self:SetPushForce(self:WireRead("Force", true) or self.defaultForce)
  end
end

function ENT:SetHitReport(trace, data)
  if(not self.hitReport) then self.hitReport = {} end
  self.hitReport["DT"] = data
  self.hitReport["TR"] = trace
  return self
end

function ENT:GetHitReport()
  if(not self.hitReport) then return end
  local data  = self.hitReport["DT"]
  local trace = self.hitReport["TR"]
  return trace, data
end

local function On(ply, ent)
  if(not ent) then return end
  if(ent == NULL) then return end
  if(not ent:IsValid()) then return end
  ent:SetOn(not ent:GetOn())
end

local function Off(ply, ent)
  if(not ent) then return end
  if(ent == NULL) then return end
  if(not ent:IsValid()) then return end
  if(ent:GetToggle()) then return end
  ent:SetOn(not ent:GetOn())
end

numpad.Register("Laser_On" , On )
numpad.Register("Laser_Off", Off)
