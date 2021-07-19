AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

resource.AddFile("models/props_junk/flare.mdl")
resource.AddFile("materials/effects/redlaser1.vmt")
resource.AddFile("materials/vgui/entities/gmod_laser_killicon.vmt")

resource.AddSingleFile("materials/effects/redlaser1_smoke.vtf")

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
    {"On"    , "NORMAL", "Laser entity status"    },
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
        if(trent:GetClass() == LaserLib.GetClass(2)) then
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
      self:WireWrite("Target")
    end
  else
    self:WireWrite("Hit", 0)
    self:WireWrite("Target")
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
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local noverm = self:GetInNonOverMater()
  local trace, data = LaserLib.DoBeam(self,
                                      origin,
                                      direct,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm)
  return trace, data
end

function ENT:Think()
  if(self:GetOn()) then
    self:DoDamage(self:DoBeam())
  else
    self:WireWrite("Hit", 0)
    self:WireWrite("Target")
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
  if(ent:WireIsConnected("On")) then return end
  ent:SetOn(not ent:GetOn())
end

local function Off(ply, ent)
  if(not ent) then return end
  if(ent == NULL) then return end
  if(not ent:IsValid()) then return end
  if(ent:WireIsConnected("On")) then return end
  if(ent:GetStartToggle()) then return end
  ent:SetOn(not ent:GetOn())
end

numpad.Register("Laser_On" , On )
numpad.Register("Laser_Off", Off)
