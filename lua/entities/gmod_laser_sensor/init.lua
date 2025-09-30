AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_sensor.vmt")

local gnCTOL  = LaserLib.GetData("CTOL")
local gcWHITE = LaserLib.GetColor("WHITE")

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:ResetInternals()
  self.crOrigin:SetUnpacked(0,0,0)
  self.crDirect:SetUnpacked(0,0,0)
  self.crWidth , self.crLength, self.crDamage = 0, 0, 0
  self.crNpower, self.crForce , self.crOpower = 0, 0, nil
  self.hitSize , self.crNormh , self.crDomsrc = 0, false, nil
  self.crColor.r, self.crColor.g = 0, 0
  self.crColor.b, self.crColor.a = 0, 0
  return self
end

function ENT:UpdateInternals()
  self.crOrigin = Vector()
  self.crDirect = Vector()
  self.crColor  = Color(0,0,0,0)
  self:ResetInternals()
  return self
end

function ENT:InitSources()
  self:UpdateInternals() -- Initialize sensor internals
  self.hitSources = {} -- Entity sources in notation `[ent] = true`
  self.pssSources = {
    Size = 0,  -- Contains the loop upper limit
    Time = 0,  -- Contains the current time for pass-trough
    Keys = {}, -- Contains the ordered by time keys
    Data = {}, -- contain the data set used to call every beam
    Copy = {   -- For pass-trough copy of current beam is needed
      Ony = {  -- Beam copy ONLY the specified fields
        ["NvWidth" ] = true, -- Copy beam width
        ["NvDamage"] = true, -- Copy beam damage
        ["NvForce" ] = true, -- Copy beam force
        ["NvLength"] = true, -- Copy beam length
        ["NvColor" ] = true, -- Copy beam color
        ["VrOrigin"] = true, -- Copy last trace origin
        ["VrDirect"] = true, -- Copy last trace direction
        ["BmTarget"] = true, -- Copy current trace data
        ["BoSource"] = true, -- Copy reference to external source
        ["BmSource"] = true  -- Copy reference to current source
      }, -- Copy only the needed fields. Nothing else
      Asn = {
        ["BoSource"] = true, -- Copy external source as pointer
        ["BmSource"] = true  -- Copy current source as pointer
      }, -- Direct assignment of beam source entity
      Cpn = {
        ["NvColor"]  = true, -- Copy current color
        ["BmTarget"] = true  -- Copy current trace data
      }
    } -- Configure how node data is being copied
  } -- Pass-trough internal configuration data
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
  self:SetInBeamSafety(0)
  self:SetInNonOverMater(0)
  self:SetCheckBeamColor(false)
  self:SetCheckDominant(false)
  self:SetPassBeamTrough(false)
  self:SetBeamColorRGBA(255,255,255,255)

  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local cas = LaserLib.GetClass(self.UnitID)
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(cas)
  if(LaserLib.IsValid(ent)) then
    LaserLib.SnapNormal(ent, tr, 90)
    ent:SetAngles(ang) -- Apply angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    LaserLib.SetVisuals(ply, ent, tr)
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetPlayer(ent, ply)
    ent:SetBeamTransform()
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

function ENT:EveryBeam(entity, index, beam)
  if(not beam) then return end
  local trace = beam:GetTarget()
  if(trace and trace.Hit) then
    local norm = self:GetUnitDirection()
    local bdot, mdot = self:GetHitPower(norm, beam, trace)
    self:SetArrays(entity, beam.BmIdenty, mdot, (bdot and 1 or 0))
    if(bdot) then
      self.crNpower = LaserLib.GetPower(beam.NvWidth, beam.NvDamage)
      self.crWidth  = self.crWidth  + beam.NvWidth
      self.crDamage = self.crDamage + beam.NvDamage
      self.crForce  = self.crForce  + beam.NvForce
      if(not self.crOpower or self.crNpower > self.crOpower) then
        local crCo = self.crColor
        self.crNormh  = true
        self.crOpower = self.crNpower
        self.crDomsrc = beam:GetSource()
        self.crLength = beam.NvLength
        self.crOrigin:Set(beam.VrOrigin)
        self.crDirect:Set(beam.VrDirect)
        crCo.r, crCo.g, crCo.b, crCo.a = beam:GetColorRGBA()
      end
    end
  end -- Sources are located in the table hash part
end

function ENT:UpdateOutputs(dom, bon)
  self:WireWrite("Width" , self.crWidth)
  self:WireWrite("Length", self.crLength)
  self:WireWrite("Damage", self.crDamage)
  self:WireWrite("Force" , self.crForce)
  self:WireWrite("Origin", self.crOrigin)
  self:WireWrite("Direct", self.crDirect)

  if(dom ~= nil) then
    self:WireWrite("Dominant", dom)
  else
    self:WireWrite("Dominant")
  end

  if(bon ~= nil) then
    self:SetOn(tobool(bon))
  else
    self:SetOn(false)
  end

  return self
end

function ENT:UpdateDominant(dom)
  local domsrc = (dom or self.crDomsrc)
  if(LaserLib.IsValid(domsrc)) then
    -- Read sensor configuration
    local mforce  = self:GetBeamForce()
    local mwidth  = self:GetBeamWidth()
    local morigin = self:GetUnitOrigin()
    local mdirect = self:GetUnitDirection()
    local mlength = self:GetBeamLength()
    local mdamage = self:GetBeamDamage()
    local mcomcor, mcoe = self:GetCheckBeamColor()
    local zorigin, como = morigin:IsZero(), false
    local zdirect, comd = mdirect:IsZero(), false
    if(not zorigin) then -- Check if origin is present
      como = (morigin:DistToSqr(self.crOrigin) >= mlength^2)
    end -- No need to calculate square root when zero
    if(not zdirect) then comd = self.crNormh end
     -- Dominant beam color compare enabled
    if(mcomcor) then
      local m = self:GetBeamColorRGBA(true)
      local d = self.crColor; self:SetColor(m)
      mcoe = ((math.abs(m.r - d.r) < gnCTOL) and (math.abs(m.g - d.g) < gnCTOL) and
              (math.abs(m.b - d.b) < gnCTOL) and (math.abs(m.a - d.a) < gnCTOL))
    else self:SetColor(gcWHITE) end
    -- Trigger the wire inputs
    self:UpdateOutputs(domsrc)
    -- Check whenever sensor has to turn on
    if((zorigin or (not zorigin and como)) and
       (zdirect or (not zdirect and comd)) and
       (not mcomcor or (mcomcor and mcoe)) and
       (mforce  == 0 or (mforce  > 0 and self.crForce  >= mforce)) and
       (mwidth  == 0 or (mwidth  > 0 and self.crWidth  >= mwidth)) and
       (mlength == 0 or (mlength > 0 and self.crLength >= mlength)) and
       (mdamage == 0 or (mdamage > 0 and self.crDamage >= mdamage))) then
      if(self:GetCheckDominant()) then -- Compare dominant
        -- Sensor configurations
        local mfcentr = self:GetForceCenter()
        local mreflec = self:GetReflectRatio()
        local mrefrac = self:GetRefractRatio()
        local mdistyp = self:GetDissolveType()
        local mendeff = self:GetEndingEffect()
        local mmatera = self:GetBeamMaterial()
        local mbmsafe = self:GetInBeamSafety()
        local mbmdisp = self:GetInBeamDisperse()
        local movrmat = self:GetInNonOverMater()
        -- Dominant configurations ( booleans have true/false )
        local dfcentr = domsrc:GetForceCenter()  and 2 or 1
        local dreflec = domsrc:GetReflectRatio() and 2 or 1
        local drefrac = domsrc:GetRefractRatio() and 2 or 1
        local ddistyp = domsrc:GetDissolveType()
        local dendeff = domsrc:GetEndingEffect() and 2 or 1
        local dmatera = domsrc:GetBeamMaterial()
        local dbmsafe = domsrc:GetBeamSafety()   and 2 or 1
        local dbmdisp = domsrc:GetBeamDisperse() and 2 or 1
        local dovrmat = domsrc:GetNonOverMater() and 2 or 1
        -- Compare the internal configuration and trigger sensor
        if((mmatera == "" or (mmatera ~= "" and mmatera == dmatera)) and
           (mdistyp == "" or (mdistyp ~= "" and mdistyp == ddistyp)) and
           (mfcentr == 0  or (mfcentr ~= 0  and mfcentr == dfcentr)) and
           (mreflec == 0  or (mreflec ~= 0  and mreflec == dreflec)) and
           (mrefrac == 0  or (mrefrac ~= 0  and mrefrac == drefrac)) and
           (mendeff == 0  or (mendeff ~= 0  and mendeff == dendeff)) and
           (mbmsafe == 0  or (mbmsafe ~= 0  and mbmsafe == dbmsafe)) and
           (mbmdisp == 0  or (mbmdisp ~= 0  and mbmdisp == dbmdisp)) and
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
    self:UpdateOutputs()
  end

  return self
end

function ENT:UpdateOn()
  if(self:GetOn()) then
    self:WireWrite("On", 1)
  else
    self:WireWrite("On", 0)
  end

  return self
end

function ENT:UpdateSources()
  self:ResetInternals()
  self:ProcessSources()

  if(self.hitSize > 0) then
    self:UpdateDominant()
  else
    self:UpdateOutputs()
  end

  return self:UpdateArrays()
end

function ENT:ClearPassTrough()
  local pss = self.pssSources
  table.Empty(pss.Keys)
  table.Empty(pss.Data)
  pss.Time = 0
  pss.Size = 0; return self
end

function ENT:Think()
  if(self:GetPassBeamTrough()) then
    local pss = self.pssSources
    if(LaserLib.IsTime(pss.Time)) then
      pss.Time = 0
      self:ResetInternals()
      self:UpdateDominant()
      self:UpdateOn()
      self:WireArrays()
      table.Empty(pss.Data)
    else -- Some beams still hit sensor
      self:ResetInternals()
      for idx = 1, pss.Size do
        local key = pss.Keys[idx]
        if(key) then local set = pss.Data[key]
          if(set) then self:EveryBeam(set.Src, idx, set.Pbm)
          else self:ClearPassTrough(); break end
        else -- If something gets messy reset the frame
          self:ClearPassTrough(); break
        end
      end
      self:UpdateDominant()
      self:UpdateOn()
      self:WireArrays()
    end
  else
    self:UpdateSources()
    self:UpdateOn()
    self:WireArrays()
  end

  self:NextThink(CurTime())

  return true
end
