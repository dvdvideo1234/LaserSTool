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
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  self:WireWrite("Entity", self)
end

function ENT:DoDamage(trace, data)
  -- TODO : Make the owner of the mirror get the kill instead of the owner of the laser
  if(trace) then
    local trent = trace.Entity
    if(LaserLib.IsValid(trent)) then
      -- Check whenever target is beam source
      if(LaserLib.IsUnit(trent)) then
        -- Register the source to the ones who has it
        if(trent.RegisterSource) then
          trent:RegisterSource(self)
        end -- Define the method to register sources
      else
        local user = (self.ply or self.player)
        local dtyp = self:GetDissolveType()
        LaserLib.DoDamage(trent,
                          trace.HitPos,
                          trace.Normal,
                          data.VrDirect,
                          data.NvDamage,
                          data.NvForce,
                          (user or self:GetCreator()),
                          LaserLib.GetDissolveID(dtyp),
                          self:GetKillSound(),
                          self:GetForceCenter(),
                          self)
      end
    end
  end

  return self
end

--[[
 * Extract the parameters needed to create a beam
 * Takes the values tom the argument and updated source
 * ent > Dominant entity reference being extracted
]]
function ENT:SetDominant(ent)
  if(not LaserLib.IsUnit(ent, 2)) then return self end
  -- We set the same non-addable properties
  -- The most powerful source (biggest damage/width)
  self:SetStopSound(ent:GetStopSound())
  self:SetKillSound(ent:GetKillSound())
  self:SetBeamColorRGBA(ent:GetBeamColorRGBA())
  self:SetStartSound(ent:GetStartSound())
  self:SetBeamMaterial(ent:GetBeamMaterial())
  self:SetDissolveType(ent:GetDissolveType())
  self:SetEndingEffect(ent:GetEndingEffect())
  self:SetReflectRatio(ent:GetReflectRatio())
  self:SetRefractRatio(ent:GetRefractRatio())
  self:SetForceCenter(ent:GetForceCenter())
  self:SetNonOverMater(ent:GetNonOverMater())

  self:WireWrite("Dominant", ent)
  LaserLib.SetPlayer(self, (ent.ply or ent.player))

  return self
end

function ENT:Think()
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

local function On(ply, ent)
  if(not LaserLib.IsValid(ent)) then return end
  if(ent:WireIsConnected("On")) then return end
  ent:SetOn(not ent:GetOn())
end

local function Off(ply, ent)
  if(not LaserLib.IsValid(ent)) then return end
  if(ent:WireIsConnected("On")) then return end
  if(ent:GetTable().runToggle) then return end
  ent:SetOn(not ent:GetOn())
end

numpad.Register("Laser_On" , On )
numpad.Register("Laser_Off", Off)
