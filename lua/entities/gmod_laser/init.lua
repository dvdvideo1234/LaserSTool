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
    {"Range" , "NORMAL", "Returns the beam range" },
    {"Length", "NORMAL", "Returns the beam length"},
    {"Width" , "NORMAL", "Returns the beam width" },
    {"Damage", "NORMAL", "Returns the beam damage"},
    {"Force" , "NORMAL", "Returns the beam force" },
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
    if(trent and trent:IsValid()) then
      -- Check whenever target is beam source
      if(LaserLib.IsSource(trent)) then
        -- Register the source to the ones who has it
        if(trent.RegisterSource) then
          trent.RegisterSource(trent, self)
        end -- Define the method to register sources
      else
        local dsvtype = self:GetDissolveType()
        LaserLib.DoDamage(trent,
                          trace.HitPos,
                          trace.Normal,
                          data.VrDirect,
                          data.NvDamage,
                          data.NvForce,
                          self:GetCreator(),
                          LaserLib.GetDissolveID(dsvtype),
                          self:GetKillSound(),
                          self:GetForceCenter(),
                          self)
      end
    end
  end

  return self
end

function ENT:DoBeam(org, dir, idx)
  self:DrawEffectBegin()
  local force  = self:GetPushForce()
  local width  = self:GetBeamWidth()
  local origin = self:GetBeamOrigin(org)
  local length = self:GetBeamLength()
  local damage = self:GetDamageAmount()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local direct = self:GetBeamDirection(dir)
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
                                      noverm,
                                      idx)
  self:DrawEffectEnd()
  return trace, data
end

function ENT:Think()
  if(self:GetOn()) then
    local trace, data = self:DoBeam()

    if(data) then
      self:WireWrite("Range", data.RaLength)
    end

    if(trace) then
      self:WireWrite("Hit", (trace.Hit and 1 or 0))

      local trent = trace.Entity

      if(trent and trent:IsValid()) then
        self:WireWrite("Target", trent)
      else
        self:WireWrite("Target")
      end
    end

    self:DoDamage(trace, data)
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

--[[
 * Removes hit reports from the list
 * bovr > When remove overhead only is true removes
          all items having larger index than the list
          size, otherwise removes all items from the list
]]

function ENT:RemHitReports(bovr)
  if(self.Reports) then
    local rep, idx = self.Reports
    if(not bovr) then
     idx, rep.Size = 1, 0
    else idx = rep.Size + 1 end
    -- Wipe selected items
    while(rep[idx]) do
      rep[idx] = nil
      idx = idx + 1
    end
  end; return self
end

--[[
 Returns the entity hit report information table
]]
function ENT:GetHitReports()
  return self.Reports
end

--[[
 Checks whenever the entity beam report hits us (self)
 * self > The crystal to be checked
 * ent  > Source entity to be checked
 * idx  > Forced index to check. Not mandatory
]]
function ENT:GetHitSourceID(ent, idx)
  if(not ent) then return nil end -- Skip unavaliable
  if(not ent:IsValid()) then return nil end -- Skip invalid
  if(ent == self) then return nil end -- Loop source
  if(not self.Sources[ent]) then return nil end
  if(not LaserLib.IsSource(ent)) then return nil end
  if(not ent:GetOn()) then return nil end
  local rep = ent.Reports
  if(not rep) then return nil end
  if(idx) then
    local trace, data = ent:GetHitReport(idx)
    if(trace and trace.Hit and self == trace.Entity) then return idx end
  else
    for cnt = 1, rep.Size do
      local trace, data = ent:GetHitReport(cnt)
      if(trace and trace.Hit and self == trace.Entity) then return cnt end
    end
  end; return nil
end

function ENT:SetHitReport(trace, data, index)
  if(not self.Reports) then self.Reports = {Size = 0} end
  local rep = self.Reports
  if(not rep) then return self end
  local idx = LaserLib.GetReportID(index)
  if(idx >= self.Reports.Size) then self.Reports.Size = idx end
  local rep = self.Reports[idx]
  if(not rep) then
    self.Reports[idx] = {}
    rep = self.Reports[idx]
  end
  rep["DT"] = data
  rep["TR"] = trace
  return self
end

function ENT:GetHitReport(index)
  if(not self.Reports) then return end
  local idx = LaserLib.GetReportID(index)
  local rep = self.Reports[idx]
  if(not rep) then return end
  return rep["TR"], rep["DT"]
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
