AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

resource.AddFile("models/props_junk/flare.mdl")
resource.AddFile("materials/effects/redlaser1.vmt")
resource.AddFile("materials/vgui/entities/gmod_laser.vmt")
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

--[[
 * Spawns the laser via the etities tab under laser category
 * Returning with no entity is intentional becaues undo is duplicated
 * https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/commands.lua#L803
]]
function ENT:SpawnFunction(user, trace)
  if(not trace.Hit) then return end
  if(not user and user:IsValid()) then return end
  local tool         = LaserLib.GetTool()
  local angspawn     = LaserLib.GetAngleSF(user)
  local prefix, amax = tool.."_", LaserLib.GetData("AMAX")
  local colorr       = math.Clamp(user:GetInfoNum(prefix.."colorr", 0), 0 , 255)
  local colorg       = math.Clamp(user:GetInfoNum(prefix.."colorg", 0), 0 , 255)
  local colorb       = math.Clamp(user:GetInfoNum(prefix.."colorb", 0), 0 , 255)
  local colora       = math.Clamp(user:GetInfoNum(prefix.."colora", 0), 0 , 255)
  local width        = math.Clamp(user:GetInfoNum(prefix.."width", 0), 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  local length       = math.Clamp(user:GetInfoNum(prefix.."length", 0), 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  local damage       = math.Clamp(user:GetInfoNum(prefix.."damage", 0), 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  local pushforce    = math.Clamp(user:GetInfoNum(prefix.."pushforce", 0), 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  local angle        = math.Clamp(user:GetInfoNum(prefix.."angle", 0), amax[1], amax[2])
  local org, dir     = user:GetInfo(prefix.."origin"), user:GetInfo(prefix.."direct")
  local trandata     = LaserLib.SetupTransform({angle, org, dir})
  local raycolor     = Color(colorr, colorg, colorb, colora)
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
  local laser        = LaserLib.New(user       , trace.HitPos, angspawn    , model       ,
                                    trandata   , key         , width       , length      ,
                                    damage     , material    , dissolvetype, startsound  ,
                                    stopsound  , killsound   , toggle      , starton     ,
                                    pushforce  , endingeffect, reflectrate , refractrate ,
                                    forcecenter, frozen      , enovermater , raycolor)
  if(LaserLib.IsValid(laser)) then
    LaserLib.SetProperties(laser, "metal")
    LaserLib.ApplySpawn(laser, trace, trandata)

    local weld = LaserLib.Weld(surfweld, laser, trace)

    undo.Create("Laser emitter ["..laser:EntIndex().."]")
      undo.AddEntity(laser)
      if(weld) then undo.AddEntity(weld) end
      undo.SetPlayer(user)
    undo.Finish()

    gamemode.Call("PlayerSpawnedSENT", user, laser)

    user:AddCleanup(tool.."s", laser)
    user:AddCount(tool.."s", laser)
    user:AddCount("sents"  , laser)
  end
end

function ENT:DoDamage(trace, data)
  if(trace and trace.Hit) then
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
        local dtyp = data.BmSource:GetDissolveType()
        LaserLib.DoDamage(trent,
                          trace.HitPos,
                          trace.Normal,
                          data.VrDirect,
                          data.NvDamage,
                          data.NvForce,
                          (user or data.BmSource:GetCreator()),
                          LaserLib.GetDissolveID(dtyp),
                          data.BmSource:GetKillSound(),
                          data.BmSource:GetForceCenter(),
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
  self:SetStartSound(ent:GetStartSound())
  self:SetForceCenter(ent:GetForceCenter())
  self:SetBeamMaterial(ent:GetBeamMaterial())
  self:SetDissolveType(ent:GetDissolveType())
  self:SetEndingEffect(ent:GetEndingEffect())
  self:SetReflectRatio(ent:GetReflectRatio())
  self:SetRefractRatio(ent:GetRefractRatio())
  self:SetNonOverMater(ent:GetNonOverMater())
  self:SetBeamColorRGBA(ent:GetBeamColorRGBA())

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
    self:WireWrite("Range", 0)
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
