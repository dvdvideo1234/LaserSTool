LaserLib = LaserLib or {} -- Initialize the global variable of the library

local DATA = {}

-- Server controlled flags for console variables
DATA.FGSRVCN = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)

-- Library internal variables
DATA.BOUNCES = CreateConVar("laseremitter_maxbounces", "10", DATA.FGSRVCN, "Maximum surface bounces for the laser beam", 0, 1000)

DATA.TOOL = "laseremitter"
DATA.ICON = "icon16/%s.png"
DATA.NOAV = "N/A"
DATA.TOLD = SysTime()

-- Store zero angle and vector
DATA.AZERO = Angle()
DATA.VZERO = Vector()

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
  [DATA.KEYD]   = "core",
  ["energy"]    = 0,
  ["heavyelec"] = 1,
  ["lightelec"] = 2,
  ["core"]      = 3
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
}; DATA.REFLECT.Size = #DATA.REFLECT

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
}; DATA.REFRACT.Size = #DATA.REFRACT

function LaserLib.Print(time, func, ...)
  local tnew = SysTime()
  if((tnew - DATA.TOLD) > time)
    then func(...); DATA.TOLD = tnew end
end

function LaserLib.GetIcon(icon)
  return DATA.ICON:format(tostring(icon or ""))
end

function LaserLib.GetTool()
  return DATA.TOOL
end

function LaserLib.GetZeroVector()
  return DATA.VZERO
end

function LaserLib.GetZeroAngle()
  return DATA.AZERO
end

function LaserLib.GetZeroTransform()
  return LaserLib.GetZeroVector(),
         LaserLib.GetZeroAngle()
end

function LaserLib.VecNegate(vec)
  vec.x = -vec.x
  vec.y = -vec.y
  vec.z = -vec.z
  return vec
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

-- when zero return zero. Otherwise clamp
function LaserLib.ClampWidth(width)
  local out = math.max(width, 0.1)
  return ((width > 0) and out or 0)
end

-- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
function GetCollectionData(key, set)
  local idx = DATA.KEYD
  local def = set[set[idx]]
  if(not key) then return def end
  if(key == idx) then return def end
  local out = set[key] -- Try to index
  if(not out) then return def end
  return out -- Return indexed OK
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
  for idx = 1, set.Size do
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
 * direct > Local direction vector according to `base`
 * Returns the local entity origin offcet vector
 * obcen  > The local entity origin vector
]]
function LaserLib.GetBeamOrigin(base, direct)
  if(not (base and base:IsValid())) then return Vector(DATA.VZERO) end
  local vbeam = Vector(direct)
  local obcen = base:OBBCenter()
  local obdir = base:OBBMaxs()
        obdir:Sub(base:OBBMins())
  local kmulv = math.abs(obdir:Dot(vbeam))
        vbeam:Mul(kmulv / 2)
        obcen:Add(vbeam)
  return obcen
end

--[[
 * Calculates the beam direction according to the
 * angle provided as a regular number. Rotates around Y
 * base  > Base entity to calculate the direction for
 * angle > Amount to rotate the entity angle in degrees
]]
function LaserLib.GetBeamDirection(base, angle)
  if(not (base and base:IsValid())) then return Angle(DATA.AZERO) end
  local aent = base:GetAngles()
  local rang, arot = aent:Right(), (tonumber(angle) or 0)
        aent:RotateAroundAxis(rang, arot)
  local pent = base:GetPos(); pent:Add(aent:Forward())
  return base:WorldToLocal(pent)
end

--[[
 * Projects the OBB onto the ray defined by position and direction
 * base  > Base entity to calculate the snapping for
 * hitp  > The position of the surface to snap the laser on
 * norm  > World normal direction vector defining the snap plane
 * angle > The model offset beam angling parameterization
]]
function LaserLib.SnapUpSurface(base, hitp, norm, angle)
  local ang = norm:Angle()
        ang:RotateAroundAxis(ang:Right(), -angle)
  local dir = LaserLib.GetBeamDirection(base, angle)
  local org = LaserLib.GetBeamOrigin(base, dir)
  local obb = base:OBBCenter()
        org:Sub(obb)
        LaserLib.VecNegate(org)
        org:Add(obb)
  local pos = base:LocalToWorld(org)
        org:Set(base:WorldToLocal(pos))
        pos:Set(norm)
        pos:Mul(math.abs(org:Dot(dir)))
        pos:Add(hitp)
  base:SetPos(pos)
  base:SetAngles(ang)
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
        laserEnt.NextDamage = CurTime() + 0.3
      end

      target:TakeDamage(damage, attacker, laserEnt)
    end
  end

  function LaserLib.New(user       , pos         , ang         , model      ,
                        angleOffset, key         , width       , length     ,
                        damage     , material    , dissolveType, startSound ,
                        stopSound  , killSound   , toggle      , startOn    ,
                        pushForce  , endingEffect, reflectRate , refractRate,
                        forceCenter, frozen)

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
                reflectRate , refractRate, forceCenter, false)

    local phys = laser:GetPhysicsObject()
    if(phys and phys:IsValid()) then
      phys:EnableMotion(not frozen)
    end

    user:AddCount(unit.."s", laser)
    numpad.OnUp(user, key, "Laser_Off", laser)
    numpad.OnDown(user, key, "Laser_On", laser)

    table.Merge(laser:GetTable(), {
      ply         = user,
      player      = user,
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
 * width  > Beam starting width from the origin
 * damage > The amout of damage the beam does
 * force  > The amout of force the beam does
 * usrfle > Use surface material reflecting efficiency
 * usrfre > Use surface material refracting efficiency
]]
function LaserLib.DoBeam(entity, origin, direct, length, width, damage, force, usrfle, usrfre)
  local data, trace = {}
  -- Configure data structure
  data.IsTrace  = false
  data.TeFilter = entity
  data.TvPoints = {Size = 0}
  data.VrOrigin = Vector(origin)
  data.VrDirect = Vector(direct)
  data.BmLength = math.max(tonumber(length) or 0, 0)
  data.NvDamage = math.max(tonumber(damage) or 0, 0)
  data.NvWidth  = math.max(tonumber(width ) or 0, 0)
  data.NvForce  = math.max(tonumber(force ) or 0, 0)
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
        data.IsTrace = true
        data.VrOrigin:Set(trace.HitPos)
        data.VrDirect:Set(LaserLib.GetReflected(data.VrDirect, trace.HitNormal))
        data.NvLength = data.NvLength - data.NvLength * trace.Fraction
        data.NvBounce = data.NvBounce - 1
        if(usrfle) then
          data.NvWidth  = LaserLib.GetBeamWidth(reflect * data.NvWidth)
          data.NvDamage = reflect * data.NvDamage
          data.NvForce  = reflect * data.NvForce
          -- Update the parameters used for drawing the beam trace
          local info = data.TvPoints[data.TvPoints.Size]
          info[2], info[3] = data.NvWidth, data.NvDamage
        end
      elseif(refract) then
        data.IsTrace = false -- Temporaty prevent inifinite looks when refracting the beam
        if(usrfre) then
          -- New stuff for refraction
        end
      else
        data.IsTrace = false
      end
    else
      data.IsTrace = false
    end

  until(not data.IsTrace or data.NvBounce <= 0)

  data.TeTarget = trace -- Update trace entity target to be accessible by crystals

  if(SERVER) then
    if(trace.Entity and
       trace.Entity:IsValid() and
       trace.Entity:GetClass() == LaserLib.GetClass(2, 1)) then
      trace.Entity:InsertSource(entity, data)
    end
  end

  return trace, data
end

function LaserLib.GetTerm(str, def)
  local txt = tostring(str or "")
        txt = ((txt == "") and tostring(def or "") or txt)
  return ((txt == "") and DATA.NOAV or txt)
end

function LaserLib.ComboBoxString(panel, convar, nameset)
  local unit = LaserLib.GetTool()
  local data = GetConVar(unit.."_"..convar):GetString()
  local base = language.GetPhrase("tool."..unit.."."..convar.."_con")
  local hint = language.GetPhrase("tool."..unit.."."..convar)
  local item, name = panel:ComboBox(base, unit.."_"..convar)
  item:SetTooltip(hint); name:SetTooltip(hint)
  item:SetSortItems(true); item:Dock(TOP); item:SetTall(22)
  for key, val in pairs(list.GetForEdit(nameset)) do
    local icon = LaserLib.GetIcon(val.icon)
    item:AddChoice(key, val.name, (data == val.name), icon)
  end
  item.DoRightClick = function(pnSelf)
    local sN = DATA.NOAV
    local vV = pnSelf:GetValue()
    local iD = pnSelf:GetSelectedID()
    local vT = pnSelf:GetOptionText(iD)
    SetClipboardText(LaserLib.GetTerm(vT, vV))
  end
  name.DoRightClick = function(pnSelf)
    SetClipboardText(pnSelf:GetText())
  end
  return item, name
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
  if(SERVER) then return end

  local data = {
    {"models/props_junk/flare.mdl",90},
    {"models/props_lab/jar01a.mdl",90},
    {"models/props_lab/jar01b.mdl",90},
    {"models/props_junk/popcan01a.mdl",90},
    {"models/props_c17/pottery01a.mdl",90},
    {"models/props_c17/pottery02a.mdl",90},
    {"models/props_c17/pottery04a.mdl",90},
    {"models/props_c17/pottery05a.mdl",90},
    {"models/props_junk/trafficcone001a.mdl",90},
    -- With angle offset as a second table argument
    {"models/props_lab/tpplug.mdl"},
    {"models/props_combine/breenlight.mdl",-90},
    {"models/props_combine/headcrabcannister01a_skybox.mdl",180}
  }

  if(IsMounted("portal")) then -- Portal is mounted
    table.insert(data, {"models/props_bts/rocket.mdl"})
    table.insert(data, {"models/props/cake/cake.mdl",90})
    table.insert(data, {"models/Weapons/w_portalgun.mdl",180})
    table.insert(data, {"models/props/pc_case02/pc_case02.mdl",90})
  end

  if(IsMounted("hl2")) then -- Portal is mounted
    table.insert(data, {"models/items/ar2_grenade.mdl"})
    table.insert(data, {"models/items/combine_rifle_ammo01.mdl",90})
    table.insert(data, {"models/items/combine_rifle_cartridge01.mdl",90})
    table.insert(data, {"models/items/combine_rifle_cartridge01.mdl",90})
  end

  if(IsMounted("dod")) then
    table.insert(data, {"models/weapons/w_smoke_ger.mdl",-90})
  end

  if(IsMounted("cstrike")) then
    table.insert(data, {"models/props/de_nuke/emergency_lighta.mdl",90})
  end

  if(WireLib) then -- Make these model available only if the player has Wire
    table.insert(data, {"models/led2.mdl", 90})
    table.insert(data, {"models/venompapa/wirecdlock.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_siren.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_range.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_beamcaster.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_grabber_forcer.mdl", 90})
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

-- http://www.famfamfam.com/lab/icons/silk/preview.php
function LaserLib.SetupDissolveTypes()
  if(SERVER) then return end

  language.Add("dissolvetype.energy"       , "AR2 style")
  language.Add("dissolvetype.heavyelectric", "Heavy electrical")
  language.Add("dissolvetype.lightelectric", "Light electrical")
  language.Add("dissolvetype.core"         , "Core Effect")

  table.Empty(list.GetForEdit("LaserDissolveTypes"))
  list.Set("LaserDissolveTypes", "#dissolvetype.energy"       , {name = "energy"   , icon = "lightning"})
  list.Set("LaserDissolveTypes", "#dissolvetype.heavyElectric", {name = "heavyelec", icon = "joystick" })
  list.Set("LaserDissolveTypes", "#dissolvetype.lightElectric", {name = "lightelec", icon = "package"  })
  list.Set("LaserDissolveTypes", "#dissolvetype.core"         , {name = "core"     , icon = "ruby"     })
end

function LaserLib.SetupSoundEffects()
  if(SERVER) then return end

  language.Add("sound.none"              , "None")
  language.Add("sound.alyxemp"           , "Alyx EMP")
  language.Add("sound.weld1"             , "Weld 1")
  language.Add("sound.weld2"             , "Weld 2")
  language.Add("sound.electricexplosion1", "Electric Explosion 1")
  language.Add("sound.electricexplosion2", "Electric Explosion 2")
  language.Add("sound.electricexplosion3", "Electric Explosion 3")
  language.Add("sound.electricexplosion4", "Electric Explosion 4")
  language.Add("sound.electricexplosion5", "Electric Explosion 5")
  language.Add("sound.disintegrate1"     , "Disintegrate 1")
  language.Add("sound.disintegrate2"     , "Disintegrate 2")
  language.Add("sound.disintegrate3"     , "Disintegrate 3")
  language.Add("sound.disintegrate4"     , "Disintegrate 4")
  language.Add("sound.zapper"            , "Zapper")

  table.Empty(list.GetForEdit("LaserSounds"))
  list.Set("LaserSounds", "#sound.none"              , "")
  list.Set("LaserSounds", "#sound.alyxemp"           , "AlyxEMP.Charge")
  list.Set("LaserSounds", "#sound.weld1"             , "ambient/energy/weld1.wav")
  list.Set("LaserSounds", "#sound.weld2"             , "ambient/energy/weld2.wav")
  list.Set("LaserSounds", "#sound.electricexplosion1", "ambient/levels/labs/electric_explosion1.wav")
  list.Set("LaserSounds", "#sound.electricexplosion2", "ambient/levels/labs/electric_explosion2.wav")
  list.Set("LaserSounds", "#sound.electricexplosion3", "ambient/levels/labs/electric_explosion3.wav")
  list.Set("LaserSounds", "#sound.electricexplosion4", "ambient/levels/labs/electric_explosion4.wav")
  list.Set("LaserSounds", "#sound.electricexplosion5", "ambient/levels/labs/electric_explosion5.wav")
  list.Set("LaserSounds", "#sound.disintegrate1"     , "ambient/levels/citadel/weapon_disintegrate1.wav")
  list.Set("LaserSounds", "#sound.disintegrate2"     , "ambient/levels/citadel/weapon_disintegrate2.wav")
  list.Set("LaserSounds", "#sound.disintegrate3"     , "ambient/levels/citadel/weapon_disintegrate3.wav")
  list.Set("LaserSounds", "#sound.disintegrate4"     , "ambient/levels/citadel/weapon_disintegrate4.wav")
  list.Set("LaserSounds", "#sound.zapper"            , "ambient/levels/citadel/zapper_warmup1.wav")

  table.Empty(list.GetForEdit("LaserStartSounds"))
  table.Empty(list.GetForEdit("LaserStopSounds"))
  table.Empty(list.GetForEdit("LaserKillSounds"))
  for key, val in pairs(list.Get("LaserSounds")) do
    list.Set("LaserStartSounds", key, {name = val, icon = "sound_add"   })
    list.Set("LaserStopSounds" , key, {name = val, icon = "sound_delete"})
    list.Set("LaserKillSounds" , key, {name = val, icon = "sound_mute"  })
  end

  table.Empty(list.GetForEdit("LaserSounds"))
end
