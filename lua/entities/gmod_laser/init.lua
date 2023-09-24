AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

resource.AddFile("models/props_junk/flare.mdl")
resource.AddFile("materials/effects/redlaser1.vmt")
resource.AddFile("materials/vgui/entities/gmod_laser.vmt")
resource.AddFile("materials/vgui/entities/gmod_laser_killicon.vmt")

resource.AddSingleFile("materials/effects/redlaser1_smoke.vtf")

local gtAMAX     = LaserLib.GetData("AMAX")
local cvMXBMWIDT = LaserLib.GetData("MXBMWIDT")
local cvMXBMLENG = LaserLib.GetData("MXBMLENG")
local cvMXBMDAMG = LaserLib.GetData("MXBMDAMG")
local cvMXBMFORC = LaserLib.GetData("MXBMFORC")

function ENT:PreEntityCopy()
  self:WirePreEntityCopy()
end

function ENT:PostEntityPaste(ply, ent, cre)
  self:WirePostEntityPaste(ply, ent, cre)
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
    {"Force" , "NORMAL", "Updates the beam force" },
    {"Safety", "NORMAL", "Updates the beam safety"}
  ):WireCreateOutputs(
    {"On"    , "NORMAL", "Laser entity status"    },
    {"Hit"   , "NORMAL", "Laser entity hit"       },
    {"Range" , "NORMAL", "Returns the beam range" },
    {"Length", "NORMAL", "Returns the beam length"},
    {"Width" , "NORMAL", "Returns the beam width" },
    {"Damage", "NORMAL", "Returns the beam damage"},
    {"Force" , "NORMAL", "Returns the beam force" },
    {"Safety", "NORMAL", "Returns the beam safety"},
    {"Target", "ENTITY", "Laser entity target"    },
    {"Entity", "ENTITY", "Laser entity itself"    }
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  self:WireWrite("Entity", self)
end

--[[
 * Spawns the laser via the etities tab under laser category
 * Returning with no entity is intentional becaues undo is duplicated
 * https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L828
]]
function ENT:SpawnFunction(user, trace)
  if(not trace.Hit) then return end
  if(not LaserLib.IsValid(user)) then return end
  local tool         = LaserLib.GetTool()
  local prefix       = LaserLib.GetTool().."_"
  local angspawn     = LaserLib.GetAngleSF(user)
  local key          = user:GetInfoNum(prefix.."key", 0)
  local model        = user:GetInfo(prefix.."model")
  local material     = user:GetInfo(prefix.."material")
  local stopsound    = user:GetInfo(prefix.."stopsound")
  local killsound    = user:GetInfo(prefix.."killsound")
  local startsound   = user:GetInfo(prefix.."startsound")
  local dissolvetype = user:GetInfo(prefix.."dissolvetype")
  local toggle       = (user:GetInfoNum(prefix.."toggle", 0) ~= 0)
  local frozen       = (user:GetInfoNum(prefix.."frozen", 0) ~= 0)
  local starton      = (user:GetInfoNum(prefix.."starton", 0) ~= 0)
  local surfweld     = (user:GetInfoNum(prefix.."surfweld", 0) ~= 0)
  local reflectrate  = (user:GetInfoNum(prefix.."reflectrate", 0) ~= 0)
  local refractrate  = (user:GetInfoNum(prefix.."refractrate", 0) ~= 0)
  local forcecenter  = (user:GetInfoNum(prefix.."forcecenter", 0) ~= 0)
  local endingeffect = (user:GetInfoNum(prefix.."endingeffect", 0) ~= 0)
  local enovermater  = (user:GetInfoNum(prefix.."enonvermater", 0) ~= 0)
  local ensafebeam   = (user:GetInfoNum(prefix.."ensafebeam", 0) ~= 0)
  local colorr       = math.Clamp(user:GetInfoNum(prefix.."colorr", 0), 0 , 255)
  local colorg       = math.Clamp(user:GetInfoNum(prefix.."colorg", 0), 0 , 255)
  local colorb       = math.Clamp(user:GetInfoNum(prefix.."colorb", 0), 0 , 255)
  local colora       = math.Clamp(user:GetInfoNum(prefix.."colora", 0), 0 , 255)
  local width        = math.Clamp(user:GetInfoNum(prefix.."width", 0), 0, cvMXBMWIDT:GetFloat())
  local length       = math.Clamp(user:GetInfoNum(prefix.."length", 0), 0, cvMXBMLENG:GetFloat())
  local damage       = math.Clamp(user:GetInfoNum(prefix.."damage", 0), 0, cvMXBMDAMG:GetFloat())
  local pushforce    = math.Clamp(user:GetInfoNum(prefix.."pushforce", 0), 0, cvMXBMFORC:GetFloat())
  local angle        = math.Clamp(user:GetInfoNum(prefix.."angle", 0), gtAMAX[1], gtAMAX[2])
  local org, dir     = user:GetInfo(prefix.."origin"), user:GetInfo(prefix.."direct")
  local trandata     = LaserLib.SetupTransform({angle, org, dir})
  local raycolor     = Color(colorr, colorg, colorb, colora)
  local laser        = LaserLib.NewLaser(user       , trace.HitPos, angspawn    , model       ,
                                         trandata   , key         , width       , length      ,
                                         damage     , material    , dissolvetype, startsound  ,
                                         stopsound  , killsound   , toggle      , starton     ,
                                         pushforce  , endingeffect, reflectrate , refractrate ,
                                         forcecenter, frozen      , enovermater , ensafebeam  , raycolor)
  if(LaserLib.IsValid(laser)) then

    LaserLib.ApplySpawn(laser, trace, trandata)

    user:AddCount(tool.."s", laser)
    user:AddCleanup(tool.."s", laser)

    return laser
  end
end

function ENT:DoDamage(beam, trace)
  if(trace and trace.Hit) then
    local trent = trace.Entity
    if(LaserLib.IsValid(trent)) then
      -- Check whenever target is beam source
      if(not LaserLib.IsUnit(trent)) then
        local sors = beam:GetSource()
        local user = (self.ply or self.player)
        local dtyp = sors:GetDissolveType()

        LaserLib.DoDamage(trent,
                          self,
                          (user or sors:GetCreator()),
                          trace.HitPos,
                          trace.Normal,
                          beam.VrDirect,
                          beam.NvDamage,
                          beam.NvForce,
                          LaserLib.GetDissolveID(dtyp),
                          sors:GetKillSound(),
                          sors:GetForceCenter(),
                          sors:GetBeamSafety())
      end
    end
  end

  return self
end

function ENT:Think()
  if(self:GetOn()) then
    self:UpdateFlags()
    local beam, trace = self:DoBeam()

    if(beam) then
      self:WireWrite("Range", beam.RaLength)
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

    self:DoDamage(beam, trace)
  else
    self:WireWrite("Hit", 0)
    self:WireWrite("Range", 0)
    self:WireWrite("Target")
  end

  self:NextThink(CurTime())

  return true
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
