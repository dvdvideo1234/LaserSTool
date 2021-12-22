AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_sensor.vmt")

function ENT:RegisterSource(ent)
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
    {"Origin"  , "VECTOR", "Sensor source hit origin"},
    {"Direct"  , "VECTOR", "Sensor surface normal"   }
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Sensor enabled state"          },
    {"Width"   , "NORMAL", "Sensor beam width"             },
    {"Length"  , "NORMAL", "Sensor length width"           },
    {"Damage"  , "NORMAL", "Sensor damage width"           },
    {"Force"   , "NORMAL", "Sensor force amount"           },
    {"DotMatch", "NORMAL", "Sensor beam direction match"   },
    {"DotBound", "NORMAL", "Sensor beam direction bound"   },
    {"Origin"  , "VECTOR", "Sensor source beam origin"     },
    {"Direct"  , "VECTOR", "Sensor source beam direction"  },
    {"RatioRL" , "NORMAL", "Sensor source reflection ratio"},
    {"RatioRF" , "NORMAL", "Sensor source refraction ratio"},
    {"NoVrmat" , "NORMAL", "Sensor source ovr matyerial"   },
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
  self:SetEndingEffect(false)
  self:SetReflectRatio(false)
  self:SetRefractRatio(false)
  self:SetForceCenter(false)
  self:SetNonOverMater(false)
  self:SetBeamColorRGBA(255,255,255,255)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
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
    ent:SetBeamTransform()
    LaserLib.SetPlayer(ent, ply)
    return ent
  end; return nil
end

function ENT:UpdateSources()
  local normh , normm , domsrc = 0, 0
  local bmrefl, bmrefr, novrmt = 0, 0, 0
  local opower, npower, force  = 0, 0, 0
  local width , length, damage = 0, 0, 0
  local origin, direct = Vector(), Vector()

  self.hitSize = 0
  self:ProcessSources(function(entity, index, trace, data)
    local norm = self:GetUnitDirection()
    local bdot, mdot = self:GetHitPower(norm, trace, data)
    if(trace and trace.Hit and data) then
      self:SetArrays(entity, index, mdot, (bdot and 1 or 0))
      if(bdot) then
        npower = LaserLib.GetPower(data.NvWidth, data.NvDamage)
        width  = width  + data.NvWidth
        damage = damage + data.NvDamage
        force  = force  + data.NvForce
        if(npower > opower) then
          normh  = (bdot and 1 or 0)
          normm  = mdot
          opower = npower
          domsrc = data.BmSource
          length = data.NvLength
          origin:Set(data.VrOrigin)
          direct:Set(data.VrDirect)
          bmrefl = (data.BrReflec and 1 or 0)
          bmrefr = (data.BrRefrac and 1 or 0)
          novrmt = (data.BmNoover and 1 or 0)
        end
      end
    end -- Sources are located in the table hash part
  end);

  if(self.hitSize > 0) then
    if(LaserLib.IsValid(domsrc)) then
      -- Read sensor configuration
      local mforce  = self:GetBeamForce()
      local mwidth  = self:GetBeamWidth()
      local morigin = self:GetUnitOrigin()
      local mdirect = self:GetUnitDirection()
      local mlength = self:GetBeamLength()
      local mdamage = self:GetBeamDamage()
      local zorigin = morigin:IsZero()
      local zdirect = mdirect:IsZero()

      self:WireWrite("Width" , width)
      self:WireWrite("Length", length)
      self:WireWrite("Damage", damage)
      self:WireWrite("Force" , force)
      self:WireWrite("Origin", origin)
      self:WireWrite("Direct", direct)
      self:WireWrite("RatioRL", bmrefl)
      self:WireWrite("RatioRF", bmrefr)
      self:WireWrite("NoVrmat", novrmt)
      self:WireWrite("DotMatch", normh)
      self:WireWrite("DotBound", normm)
      self:WireWrite("Dominant", domsrc)
      -- Check whenever sensor has to turn on
      if((mforce  == 0 or (mforce  > 0 and force  >= mforce)) and
         (mwidth  == 0 or (mwidth  > 0 and width  >= mwidth)) and
         (mlength == 0 or (mlength > 0 and length >= mlength)) and
         (mdamage == 0 or (mdamage > 0 and damage >= mdamage))) then
        if(self:GetIsBeamDominant()) then -- Compare dominant data
          local mdistyp = self:GetDissolveType()
          local mmatera = self:GetInBeamMaterial()
          local ddistyp = domsrc:GetDissolveType()
          local dmatera = domsrc:GetInBeamMaterial()
          if((zorigin or (not zorigin and morigin:Distance(origin) >= mlength)) and
             (zdirect or (not zdirect and normh > 0)) and
             (mmatera == "" or (mmatera ~= "" and mmatera == dmatera)) and
             (mdistyp == "" or (mdistyp ~= "" and mdistyp == ddistyp))
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
      self:WireWrite("RatioRL", bmrefl)
      self:WireWrite("RatioRF", bmrefr)
      self:WireWrite("NoVrmat", novrmt)
      self:WireWrite("DotMatch", normh)
      self:WireWrite("DotBound", normm)
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
    self:WireWrite("RatioRL", bmrefl)
    self:WireWrite("RatioRF", bmrefr)
    self:WireWrite("NoVrmat", novrmt)
    self:WireWrite("DotMatch", normh)
    self:WireWrite("DotBound", normm)
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
