LaserLib = LaserLib or {} -- Initialize the global variable of the library

local DATA = {}

-- Server controlled flags for console variables
DATA.FGSRVCN = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)

-- Library internal variables
DATA.BOUNCES = CreateConVar("laseremitter_maxbounces", "10", DATA.FGSRVCN, "Maximum surface bounces for the laser beam", 0, 1000)

DATA.TOOL = "laseremitter"

-- The default key in a collection point to take when not found
DATA.KEYD = "#"

DATA.CLS = {
  -- [1] Item true class [2] Spawn class from entities
  {"gmod_laser"},
  {"gmod_laser_crystal"  , "gmod_laser_crystal"},
  {"gmod_laser_reflector", "prop_physics"      }
}

DATA.MOD = {
  -- [1] Model used by the entities menu
  {""}, -- Laser model is changed via laser tool
  {"models/Combine_Helicopter/helicopter_bomb01.mdl"},
  {"models/madjawa/laser_reflector.mdl"}
}

DATA.MAT = {
  -- [1] Model used by the entities menu
  {""}, -- Laser material is changed with the model
  {"models/props_combine/health_charger_glass"},
  {"debug/env_cubemap_model"}
}

DATA.COLOR = {
  [DATA.KEYD] = "BLACK",
  ["BLACK"]   = Color( 0 ,  0 ,  0 , 255),
  ["WHITE"]   = Color(255, 255, 255, 255)
}

DATA.DISTYPE = {
  [DATA.KEYD]   = "coreffect",
  ["energy"]    = 0,
  ["heavyelec"] = 1,
  ["lightelec"] = 2,
  ["coreffect"] = 3
}

DATA.REFLECT = { -- Reflection data descriptor
  [1] = "cubemap", -- Cube maps textures
  [2] = "shiny"  , -- All shiny stuff reflect
  [3] = "chrome" , -- Chrome stuff reflect
  -- Used for prop updates and checks
  [DATA.KEYD]                          = "debug/env_cubemap_model",
  ["debug/env_cubemap_model"]          = 0.999,
  -- User for general class control
  ["shiny"]                            = 0.854,
  ["chrome"]                           = 0.955,
  ["cubemap"]                          = 0.999,
  -- Materials that are overriden and directly hash searched
  ["phoenix_storms/pack2/bluelight"]   = 0.681,
  ["phoenix_storms/window"]            = 0.854,
  ["sprops/trans/wheels/wheel_d_rim1"] = 0.943
}; DATA.REFLECT.__size = #DATA.REFLECT

DATA.REFRACT = { -- https://en.wikipedia.org/wiki/List_of_refractive_indices
  [1] = "air"  , -- Air enumerator index
  [2] = "glass", -- Glass enumerator index
  [3] = "water", -- Glass enumerator index
  -- Used for prop updates and chec
  [DATA.KEYD]                                   = "models/props_combine/health_charger_glass",
  ["models/props_combine/health_charger_glass"] = 1.552, -- Used for prop updates
  -- User for general class control
  ["air"]                                       = 1.000, -- Air refraction index
  ["glass"]                                     = 1.521, -- Ordinary glass
  ["water"]                                     = 1.333, -- Water refraction index
  -- Materials that are overriden and directly hash searched
  ["Models/effects/vol_light001"]               = 1.000, -- Transperent air
  ["models/props_combine/com_shield001a"]       = 1.573,
  ["models/props_combine/combine_door01_glass"] = 1.583, -- Bit darker glass
  ["models/airboat/airboat_blur02"]             = 1.647, -- Non pure glass 1
  ["models/dog/eyeglass"]                       = 1.612, -- Non pure glass 2
  ["models/effects/comball_glow2"]              = 1.536, -- Glass with some impurites
  ["models/props_combine/combine_fenceglow"]    = 1.638, -- Glass with decent impurites
  ["models/props_lab/xencrystal_sheet"]         = 1.555, -- Amber refraction index
  ["models/shadertest/predator"]                = 1.333, -- Water refraction index
  ["models/shadertest/shader3"]                 = 1.333, -- Water refraction index
  ["models/spawn_effect"]                       = 1.333, -- Water refraction index
  ["models/shadertest/shader4"]                 = 1.385  -- Water with some impurites
}; DATA.REFRACT.__size = #DATA.REFRACT

function LaserLib.GetTool()
  return DATA.TOOL
end

function LaserLib.GetClass(iK, iD)
  local tI = DATA.CLS[iK]
  return (tI and (tI[iD] or tI[1]) or nil)
end

function LaserLib.GetModel(iK, iD)
  local tI = DATA.MOD[iK]
  return (tI and (tI[iD] or tI[1]) or nil)
end

function LaserLib.GetMaterial(iK, iD)
  local tI = DATA.MAT[iK]
  return (tI and (tI[iD] or tI[1]) or nil)
end

function LaserLib.GetReflected(incident, normal)
  local reflect = Vector(normal)
        reflect:Mul(-2 * normal:Dot(incident))
        reflect:Add(incident)
  return reflect
end

function LaserLib.UpdateRB(base, vec, func)
  base.x = func(base.x, vec.x)
  base.y = func(base.y, vec.y)
  base.z = func(base.z, vec.z)
end

function LaserLib.GetBeamWidth(width)
  return math.Clamp(width, 0.1, 100)
end

-- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
function GetCollectionData(key, set)
  local idx = DATA.KEYD
  if(idx == key) then
    return set[set[idx]]
  else
    local out = set[key]
    if(not out) then
      out = set[set[idx]]
    end; return out
  end
end

function LaserLib.GetDissolveType(disstype)
  return GetCollectionData(disstype, DATA.DISTYPE)
end

function LaserLib.GetColor(color)
  return GetCollectionData(color, DATA.COLOR)
end

function LaserLib.SetMaterial(ply, ent, mat)
  if(not ply) then return end
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  if(not ply:IsValid()) then return end
  if(not ply:IsPlayer()) then return end
  local data = {MaterialOverride = tostring(mat or "")}
  ent:SetMaterial(data.MaterialOverride)
  duplicator.StoreEntityModifier(ent, "material", data)
end

--[[
Checks when the entity has reflective mirror texture
 * ent > Entity to retrieve the setting for
 * set > The dedicated parameeters setting to check
]]
function GetMaterialData(ent, set)
  if(not ent) then return nil end
  if(not ent:IsValid()) then return nil end
  local mat = ent:GetMaterial()
  if(mat == "") then -- No override
    mat = ent:GetMaterials()[1]
  end -- Read the first entry from table
  -- Protect hash indexing by nil
  if(not mat) then return nil end
  -- Check for overriding with default
  if(mat == DATA.KEYD) then return set[set[mat]] end
  -- Check for element overrides
  if(set[mat]) then return set[mat] end
  -- Check for emement category
  for idx = 1, set.__size do
    local key = set[idx]
    if(mat:find(key, 1, true)) then
      return set[key]
    end
  end; return nil
end

function LaserLib.GetReflect()
  return DATA.REFLECT[DATA.KEYD]
end

function LaserLib.GetRefract()
  return DATA.REFRACT[DATA.KEYD]
end

--[[
 * Calculates the local beam origin offset
 * according tho the base entity and direction provided
 * base   > Base entity to calculate the vector for
 * direct > Worls space direction vaector to match
 * Returns the local entity origin offcet vector
 * obcen  > The local entity origin vector
]]
function LaserLib.GetBeamOrigin(base, direct)
  if(not (base and base:IsValid())) then return Vector(0,0,0) end
        direct:Add(base:GetPos())
        direct:Set(base:WorldToLocal(direct))
  local obcen = base:OBBCenter()
  local obdir = base:OBBMaxs()
        obdir:Sub(base:OBBMins())
  local kmulv = math.abs(obdir:Dot(direct))
        direct:Mul(kmulv / 2)
        obcen:Add(direct)
  return obcen
end

--[[
 * Projects the OBB onto the ray defined by position and direction
 * base   > Base entity to calculate the vector for
 * direct > Worls space direction vaector to match
 * Returns the projected position as the beam position
 * obcen  > The local entity origin vector
]]
function LaserLib.GetBeamRay(base, direct)
  local pos = Vector(base:GetPos())
  local obb = base:LocalToWorld(base:OBBCenter())
        obb:Sub(pos)
  local ofs = obb:Dot(direct)
        obb:Set(direct)
        obb:Normalize()
        obb:Mul(ofs)
        pos:Add(obb)
  return pos
end

if(SERVER) then

  AddCSLuaFile("autorun/laserlib.lua")

  -- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
  function LaserLib.SpawnDissolver(base, position, attacker, disstype)
    local ent = ents.Create("env_entity_dissolver")
    if(not (ent and ent:IsValid())) then return nil end
    ent.Target = "laserdissolve"..base:EntIndex()
    ent:SetKeyValue("dissolvetype", disstype)
    ent:SetKeyValue("magnitude", 0)
    ent:SetPos(position)
    ent:SetPhysicsAttacker(attacker)
    ent:Spawn()
    return ent
  end

  function LaserLib.DoDamage(target   , hitPos  , normal      , beamDir  ,
                             damage   , attacker, dissolveType, pushForce,
                             killSound, laserEnt)
    laserEnt.NextDamage = laserEnt.NextDamage or CurTime()

    local ophys = target:GetPhysicsObject()
    if(pushForce and ophys and ophys:IsValid()) then
      ophys:ApplyForceOffset(beamDir * pushForce, hitPos)
    end

    if(CurTime() >= laserEnt.NextDamage) then
      if(target:IsVehicle()) then
        local odriver = target:GetDriver()
        -- Take damage doesn't work on player inside a vehicle.
        if(odriver and odriver:IsValid()) then
          target = odriver; target:Kill()
        end -- We must kill the driver!
      end

      if(target:GetClass() == "shield") then
        local odamage = math.Clamp(damage / 2500 * 3, 0, 4)
        target:Hit(laserEnt, hitPos, odamage, -1 * normal)
        laserEnt.NextDamage = CurTime() + 0.3
        return -- We stop here because we hit a shield!
      end

      if(target:Health() <= damage) then
        if(target:IsNPC() or target:IsPlayer()) then
          local odissolve = LaserLib.SpawnDissolver(laserEnt, target:GetPos(), attacker, dissolveType)

          if(target:IsPlayer()) then
            target:TakeDamage(damage, attacker, laserEnt)

            local tardoll = target:GetRagdollEntity()
            -- We need to kill the player first to get his ragdoll.
            if(not (tardoll and tardoll:IsValid())) then return end
            -- Thanks to Nevec for the player ragdoll idea, allowing us to dissolve him the cleanest way.
            tardoll:SetName(odissolve.Target)
          else
            target:SetName(odissolve.Target)

            local tarwep = target:GetActiveWeapon()
            if(tarwep and tarwep:IsValid()) then
              tarwep:SetName(odissolve.Target)
            end
          end

          odissolve:Fire("Dissolve", odissolve.Target, 0)
          odissolve:Fire("Kill", "", 0.1)
        end

        if(killSound ~= nil and (target:Health() > 0 or target:IsPlayer())) then
          sound.Play(killSound, target:GetPos())
          target:EmitSound(Sound(killSound))
        end
      else
        laserEnt.NextLaserDamage = CurTime() + 0.3
      end

      target:TakeDamage(damage, attacker, laserEnt)
    end
  end

  function LaserLib.New(user       , pos         , ang         , model      ,
                        angleOffset, key         , width       , length     ,
                        damage     , material    , dissolveType, startSound ,
                        stopSound  , killSound   , toggle      , startOn    ,
                        pushForce  , endingEffect, reflectRate , refractRate, frozen)

    local unit = LaserLib.GetTool()
    if(not (user and user:IsValid() and user:IsPlayer())) then return nil end
    if(not user:CheckLimit(unit.."s")) then return nil end

    local laser = ents.Create(LaserLib.GetClass(1, 1))
    if(not (laser and laser:IsValid())) then return nil end

    laser:SetPos(pos)
    laser:SetAngles(ang)
    laser:SetModel(Model(model))
    laser:SetAngleOffset(angleOffset)
    laser:Spawn()
    laser:SetCreator(user)
    laser:Setup(width       , length     , damage   , material    ,
                dissolveType, startSound , stopSound, killSound   ,
                toggle      , startOn    , pushForce, endingEffect,
                reflectRate , refractRate, false)

    local phys = laser:GetPhysicsObject()
    if(phys and phys:IsValid()) then
      phys:EnableMotion(not frozen)
    end

    user:AddCount(unit.."s", laser)
    numpad.OnUp(user, key, "Laser_Off", laser)
    numpad.OnDown(user, key, "Laser_On", laser)

    table.Merge(laser:GetTable(), {
      key         = key,
      angleOffset = angleOffset,
      frozen      = frozen
    })

    return laser
  end
end

--[[
Traces a laser beam from the entity provided
 * entity > Entity origin to trace the beam from
 * origin > Inititial ray origin position vector
 * direct > Inititial ray world direction vector
 * length > Total beam length to be traced
 * width  > The amout of themage the beam does
 * damage > The amout of themage the beam does
 * userfe > Use surface material reflecting efficiency
]]
function LaserLib.DoBeam(entity, origin, direct, length, width, damage, userfe)
  local data, trace = {}
  -- Configure data structure
  data.Tracing  = false
  data.TeFilter = entity
  data.TvPoints = {Size = 0}
  data.VrOrigin = Vector(origin)
  data.VrDirect = Vector(direct)
  data.BmLength = math.max(tonumber(length) or 0, 0)
  data.NvDamage = math.max(tonumber(damage) or 0, 0)
  data.NvWidth  = math.max(tonumber(width ) or 0, 0)
  data.TreIndex = {DATA.REFRACT["air"], DATA.REFRACT["air"]}
  data.MxBounce = DATA.BOUNCES:GetInt() -- All the bounces the loop made so far
  data.NvBounce, data.NvLength = data.MxBounce, data.BmLength

  if(data.NvLength <= 0) then return end
  if(not data.TeFilter) then return end
  if(not data.TeFilter:IsValid()) then return end
  if(data.VrDirect:LengthSqr() <= 0) then return end

  table.insert(data.TvPoints, {Vector(origin), data.NvWidth, data.NvDamage})
  data.TvPoints.Size = data.TvPoints.Size + 1

  repeat
    if(StarGate) then
      trace = StarGate.Trace:New(data.VrOrigin, data.VrDirect:GetNormalized() * data.NvLength, data.TeFilter)
    else -- TODO: Suppose pre-allocated trace data with output pointing to trace result is faster...
      trace = util.QuickTrace(data.VrOrigin, data.VrDirect:GetNormalized() * data.NvLength, data.TeFilter)
    end
    local reflect = GetMaterialData(trace.Entity, DATA.REFLECT)
    local refract = GetMaterialData(trace.Entity, DATA.REFRACT)

    table.insert(data.TvPoints, {trace.HitPos, data.NvWidth, data.NvDamage})
    data.TvPoints.Size = data.TvPoints.Size + 1

    if(trace.Entity and trace.Entity:IsValid()) then
      if(reflect) then
        data.Tracing = true
        data.VrOrigin:Set(trace.HitPos)
        data.VrDirect:Set(LaserLib.GetReflected(data.VrDirect, trace.HitNormal))
        data.NvLength = data.NvLength - data.NvLength * trace.Fraction
        data.NvBounce = data.NvBounce - 1
        if(userfe) then
          local info = data.TvPoints[data.TvPoints.Size]
          data.NvWidth  = LaserLib.GetBeamWidth(reflect * data.NvWidth)
          data.NvDamage = reflect * data.NvDamage
          info[2], info[3] = data.NvWidth, data.NvDamage
        end
      elseif(refract) then
        data.Tracing = false -- Temporaty prevent inifinite looks when refracting the beam
      else
        data.Tracing = false
      end
    else
      data.Tracing = false
    end

  until(not data.Tracing or data.NvBounce <= 0)

  if(SERVER) then
    if(trace.Entity and
       trace.Entity:IsValid() and
       trace.Entity:GetClass() == LaserLib.GetClass(2, 1)) then
      trace.Entity:InsertSource(entity, data)
    end
  end

  return trace, data
end

-- https://github.com/Facepunch/garrysmod/tree/master/garrysmod/resource/localization/en
function LaserLib.SetupMaterials()
  if(SERVER) then return end

  language.Add("cable.crystal_beam1", "Crystal Beam Cable" )
  language.Add("cable.cable1"       , "Cable Class 1"      )
  language.Add("cable.cable2"       , "Cable Class 2"      )

  table.Empty(list.GetForEdit("LaserEmitterMaterials"))
  list.Set("LaserEmitterMaterials", "#cable.cable1"          , "cable/cable"        )
  list.Set("LaserEmitterMaterials", "#cable.cable2"          , "cable/cable2"       )
  list.Set("LaserEmitterMaterials", "#ropematerial.rope"     , "cable/rope"         )
  list.Set("LaserEmitterMaterials", "#ropematerial.xbeam"    , "cable/xbeam"        )
  list.Set("LaserEmitterMaterials", "#ropematerial.redlaser" , "cable/redlaser"     )
  list.Set("LaserEmitterMaterials", "#ropematerial.blue_elec", "cable/blue_elec"    )
  list.Set("LaserEmitterMaterials", "#ropematerial.physbeam" , "cable/physbeam"     )
  list.Set("LaserEmitterMaterials", "#ropematerial.hydra"    , "cable/hydra"        )
  list.Set("LaserEmitterMaterials", "#cable.crystal_beam1"   , "cable/crystal_beam1")
  list.Set("LaserEmitterMaterials", "#trail.plasma"          , "trails/plasma"      )
  list.Set("LaserEmitterMaterials", "#trail.tube"            , "trails/tube"        )
  list.Set("LaserEmitterMaterials", "#trail.electric"        , "trails/electric"    )
  list.Set("LaserEmitterMaterials", "#trail.smoke"           , "trails/smoke"       )
  list.Set("LaserEmitterMaterials", "#trail.laser"           , "trails/laser"       )
  list.Set("LaserEmitterMaterials", "#trail.physbeam"        , "trails/physbeam"    )
  list.Set("LaserEmitterMaterials", "#trail.love"            , "trails/love"        )
  list.Set("LaserEmitterMaterials", "#trail.lol"             , "trails/lol"         )
  list.Set("LaserEmitterMaterials", "#effects.redlaser1"     , "effects/redlaser1"  )
end

function LaserLib.SetupModels()
  local data = {
    {"models/props_junk/flare.mdl"},
    {"models/props_junk/PopCan01a.mdl"},
    {"models/props_junk/TrafficCone001a.mdl"},
    -- With angle offset as a second table argument
    {"models/props_lab/tpplug.mdl", 90},
    {"models/props_combine/breenlight.mdl", 180},
    {"models/props_combine/headcrabcannister01a_skybox.mdl", 270}
  }

  if(WireLib) then -- Make these model available only if the player has Wire
    table.insert(data, {"models/jaanus/wiretool/wiretool_beamcaster.mdl"})
  end

  -- Automatic data population. Add models in the list above
  table.Empty(list.GetForEdit("LaserEmitterModels"))
  for idx = 1, #data do
    local rec = data[idx]
    local mod = tostring(rec[1] or "")
    local ang = (tonumber(rec[2]) or 0)
    table.Empty(rec)
    rec[DATA.TOOL.."_model"      ] = mod
    rec[DATA.TOOL.."_angleoffset"] = ang
    list.Set("LaserEmitterModels", mod, rec)
  end
end
