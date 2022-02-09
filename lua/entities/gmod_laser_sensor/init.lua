AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_sensor.vmt")

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:InitSources()
  self.hitSize = 0     -- Amount of sources to have
  self.hitSources = {} -- Sources in notation `[ent] = true`
  self:InitArrays("Array", "Index", "Level", "Front")
  return self
end

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Origin", "VECTOR", "Sensor beam hit origin"  },
    {"Direct", "VECTOR", "Sensor extern hit normal"},
    {"Length", "NORMAL", "Sensor beam length brink"},
    {"Width" , "NORMAL", "Sensor beam width brink" },
    {"Damage", "NORMAL", "Sensor beam damage brink"},
    {"Force" , "NORMAL", "Sensor beam force brink" }
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Sensor enabled state"          },
    {"Width"   , "NORMAL", "Sensor beam width"             },
    {"Length"  , "NORMAL", "Sensor length width"           },
    {"Damage"  , "NORMAL", "Sensor damage width"           },
    {"Force"   , "NORMAL", "Sensor force amount"           },
    {"Origin"  , "VECTOR", "Sensor source beam origin"     },
    {"Direct"  , "VECTOR", "Sensor source beam direction"  },
    {"Entity"  , "ENTITY", "Sensor entity itself"          },
    {"Dominant", "ENTITY", "Sensor dominant entity"        },
    {"Count"   , "NORMAL", "Sensor sources count"          },
    {"Array"   , "ARRAY" , "Sensor sources array"          },
    {"Level"   , "ARRAY" , "Sensor power level array"      },
    {"Index"   , "ARRAY" , "Sensor first hit beam index"   },
    {"Front"   , "ARRAY" , "Sensor frontal hit array"      }
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
  self:InitSources()
  self:SetBeamForce(0)
  self:SetBeamWidth(0)
  self:SetBeamLength(0)
  self:SetBeamDamage(0)
  self:SetStopSound("")
  self:SetKillSound("")
  self:SetStartSound("")
  self:SetBeamMaterial("")
  self:SetDissolveType("")
  self:SetEndingEffect(0)
  self:SetReflectRatio(0)
  self:SetRefractRatio(0)
  self:SetForceCenter(0)
  self:SetInNonOverMater(0)
  self:SetBeamColorRGBA(255,255,255,255)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(6, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(6))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(6))
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetPlayer(ent, ply)
    ent:SetBeamTransform()
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

local normh , domsrc
local opower, npower, force  = 0, 0, 0
local width , length, damage = 0, 0, 0
local origin, direct = Vector(), Vector()

function ENT:ProcessBeam(entity, index, trace, beam)
  local norm = self:GetUnitDirection()
  local bdot, mdot = self:GetHitPower(norm, trace, beam)
  if(trace and trace.Hit and beam) then
    self:SetArrays(entity, index, mdot, (bdot and 1 or 0))
    if(bdot) then
      npower = LaserLib.GetPower(beam.NvWidth, beam.NvDamage)
      width  = width  + beam.NvWidth
      damage = damage + beam.NvDamage
      force  = force  + beam.NvForce
      if(not opower or npower >= opower) then
        normh  = true
        opower = npower
        domsrc = beam.BmSource
        length = beam.NvLength
        origin:Set(beam.VrOrigin)
        direct:Set(beam.VrDirect)
      end
    end
  end -- Sources are located in the table hash part
end

function ENT:UpdateSources()
  origin:SetUnpacked(0,0,0)
  direct:SetUnpacked(0,0,0)
  normh , domsrc = false, nil
  width , length, damage = 0, 0, 0
  npower, force , opower = 0, 0, nil

  self.hitSize = 0

  self:ProcessSources()

  if(self.hitSize > 0) then
    if(LaserLib.IsValid(domsrc)) then
      -- Read sensor configuration
      local mforce  = self:GetBeamForce()
      local mwidth  = self:GetBeamWidth()
      local morigin = self:GetUnitOrigin()
      local mdirect = self:GetUnitDirection()
      local mlength = self:GetBeamLength()
      local mdamage = self:GetBeamDamage()
      local zorigin, como = morigin:IsZero(), false
      local zdirect, comd = mdirect:IsZero(), false
      if(not zorigin) then -- Check if origin is present
        como = (morigin:Distance(origin) >= mlength)
      end -- No need to calculate square root when zero
      if(not zdirect) then comd = normh end
      -- Thrigger the wire inputs
      self:WireWrite("Width" , width)
      self:WireWrite("Length", length)
      self:WireWrite("Damage", damage)
      self:WireWrite("Force" , force)
      self:WireWrite("Origin", origin)
      self:WireWrite("Direct", direct)
      self:WireWrite("Dominant", domsrc)
      -- Check whenever sensor has to turn on
      if((zorigin or (not zorigin and como)) and
         (zdirect or (not zdirect and comd)) and
         (mforce  == 0 or (mforce  > 0 and force  >= mforce)) and
         (mwidth  == 0 or (mwidth  > 0 and width  >= mwidth)) and
         (mlength == 0 or (mlength > 0 and length >= mlength)) and
         (mdamage == 0 or (mdamage > 0 and damage >= mdamage))) then
        if(self:GetCheckDominant()) then -- Compare dominant
          -- Sensor configurations
          local mfcentr = self:GetForceCenter()
          local mreflec = self:GetReflectRatio()
          local mrefrac = self:GetRefractRatio()
          local mdistyp = self:GetDissolveType()
          local mendeff = self:GetEndingEffect()
          local mmatera = self:SetBeamMaterial()
          local movrmat = self:GetNonOverMater()
          local mcomcor, mcoe = self:GetCheckBeamColor()
          -- Dominant configurations ( booleans have true/false )
          local dfcentr = domsrc:GetForceCenter() and 2 or 1
          local dreflec = domsrc:GetReflectRatio() and 2 or 1
          local drefrac = domsrc:GetRefractRatio() and 2 or 1
          local ddistyp = domsrc:GetDissolveType()
          local dendeff = domsrc:GetEndingEffect() and 2 or 1
          local dmatera = domsrc:SetBeamMaterial()
          local dovrmat = domsrc:GetNonOverMater() and 2 or 1
          if(mcomcor) then -- Dominant beam color compare enabled
            local margin = LaserLib.GetData("CTOL")
            local mv, ma = self:GetBeamColor(), self:GetBeamAlpha()
            local dv, da = domsrc:GetBeamColor(), domsrc:GetBeamAlpha()
            mcoe = (mv:IsEqualTol(dv, margin) and (math.abs(ma - da) < margin))
          end
          -- Compare the internal congiguration and trigger sensor
          if((not mcomcor   or (mcomcor       and mcoe)) and
             (mmatera == "" or (mmatera ~= "" and mmatera == dmatera)) and
             (mdistyp == "" or (mdistyp ~= "" and mdistyp == ddistyp)) and
             (mfcentr == 0  or (mfcentr ~= 0  and mfcentr == dfcentr)) and
             (mreflec == 0  or (mreflec ~= 0  and mreflec == dreflec)) and
             (mrefrac == 0  or (mrefrac ~= 0  and mrefrac == drefrac)) and
             (mendeff == 0  or (mendeff ~= 0  and mendeff == dendeff)) and
             (movrmat == 0  or (movrmat ~= 0  and movrmat == dovrmat))
          ) then -- Dominant beam is like sensor beam
            self:SetOn(true)
          else -- Dominant beam is not like sensor beam
            self:SetOn(false)
          end
        else -- Dominant comparison is not enabled
          self:SetOn(true)
        end
      else -- Cannot match main beam components
        self:SetOn(false)
      end
    else
      self:SetOn(false)
      self:WireWrite("Width" , width)
      self:WireWrite("Length", length)
      self:WireWrite("Damage", damage)
      self:WireWrite("Force" , force)
      self:WireWrite("Origin", origin)
      self:WireWrite("Direct", direct)
      self:WireWrite("Dominant", domsrc)
    end
  else
    self:SetOn(false)
    self:WireWrite("Width" , width)
    self:WireWrite("Length", length)
    self:WireWrite("Damage", damage)
    self:WireWrite("Force" , force)
    self:WireWrite("Origin", origin)
    self:WireWrite("Direct", direct)
    self:WireWrite("Dominant", domsrc)
  end

  return self:UpdateArrays()
end

function ENT:Think()
  self:UpdateSources()

  if(self:GetOn()) then
    self:WireWrite("On", 1)
  else
    self:WireWrite("On", 0)
  end

  self:WireArrays()

  self:NextThink(CurTime())

  return true
end
