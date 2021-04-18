LaserLib = {} -- Initialize the global variable of the library

local DATA = {}

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
  ["BLACK"] = Color( 0 ,  0 ,  0 , 255),
  ["WHITE"] = Color(255, 255, 255, 255)
}

DATA.TOOL = "laseremitter"

DATA.REFLECT = {
  [1] = "cubemap", -- Cube maps textures
  [1] = "shiny"  , -- All shiny stuff reflect
  [2] = "chrome" , -- Chrome stuff reflect
  -- Used for prop updates and checks
  ["#"]                                = "debug/env_cubemap_model",
  ["debug/env_cubemap_model"]          = true,
  -- User for general class control
  ["shiny"]                            = true,
  ["chrome"]                           = true,
  ["cubemap"]                          = true,
  -- Materials that are overriden and directly hash searched
  ["phoenix_storms/pack2/bluelight"]   = true,
  ["phoenix_storms/window"]            = true,
  ["sprops/trans/wheels/wheel_d_rim1"] = true
}; DATA.REFLECT.__size = #DATA.REFLECT

DATA.REFRACT = { -- https://en.wikipedia.org/wiki/List_of_refractive_indices
  [1] = "air"  , -- Air enumerator index
  [2] = "glass", -- Glass enumerator index
  [3] = "water", -- Glass enumerator index
  -- Used for prop updates and chec
  ["#"]                                         = "models/props_combine/health_charger_glass",
  ["models/props_combine/health_charger_glass"] = 1.55, -- Used for prop updates
  -- User for general class control
  ["air"]                                       = 1.00, -- Air refraction index
  ["glass"]                                     = 1.52, -- Ordinary glass
  ["water"]                                     = 1.33, -- Water refraction index
  -- Materials that are overriden and directly hash searched
  ["Models/effects/vol_light001"]               = 1.00, -- Transperent air
  ["models/props_combine/com_shield001a"]       = 1.57,
  ["models/props_combine/combine_door01_glass"] = 1.58, -- Bit darker glass
  ["models/airboat/airboat_blur02"]             = 1.64, -- Non pure glass 1
  ["models/dog/eyeglass"]                       = 1.61, -- Non pure glass 2
  ["models/effects/comball_glow2"]              = 1.53, -- Glass with some impurites
  ["models/props_combine/combine_fenceglow"]    = 1.63, -- Glass with decent impurites
  ["models/props_lab/xencrystal_sheet"]         = 1.55, -- Amber refraction index
  ["models/shadertest/predator"]                = 1.33, -- Water refraction index
  ["models/shadertest/shader3"]                 = 1.33, -- Water refraction index
  ["models/spawn_effect"]                       = 1.33, -- Water refraction index
  ["models/shadertest/shader4"]                 = 1.38  -- Water with some impurites
}; DATA.REFRACT.__size = #DATA.REFRACT

function LaserLib.GetTool()
  return DATA.TOOL
end

function LaserLib.GetColor(iK)
  return DATA.COLOR[iK]
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

if(SERVER) then

  AddCSLuaFile("autorun/laserlib.lua")

  function LaserLib.SpawnDissolver(ent, position, attacker, disstype)
    local dissolver = ents.Create("env_entity_dissolver")
    if(not (dissolver and dissolver:IsValid())) then return nil end
    dissolver.Target = "laserdissolve"..ent:EntIndex()
    dissolver:SetKeyValue("dissolvetype", disstype)
    dissolver:SetKeyValue("magnitude", 0)
    dissolver:SetPos(position)
    dissolver:SetPhysicsAttacker(attacker)
    dissolver:Spawn()
    return dissolver
  end

  function LaserLib.DoDamage(target, hitPos, normal, beamDir, damage, attacker, dissolveType, pushProps, killSound, laserEnt)

    laserEnt.NextLaserDamage = laserEnt.NextLaserDamage or CurTime()

    if(pushProps and target:GetPhysicsObject():IsValid()) then
      target:GetPhysicsObject():ApplyForceCenter(beamDir * 1600)
    end -- TODO: Laser must be able to adjust the push prop force

    if(CurTime() >= laserEnt.NextLaserDamage) then
      if(target:IsVehicle() and target:GetDriver():IsValid()) then
        target = target:GetDriver() -- We must kill the driver!
        target:Kill() -- Take damage doesn't seem to work on a player inside a vehicle
      end

      if(target:GetClass() == "shield") then
        target:Hit(laserEnt, hitPos, math.Clamp(damage / 2500 * 3, 0, 4), -1 * normal)
        laserEnt.NextLaserDamage = CurTime() + 0.3
        return -- We stop here because we hit a shield
      end

      if(target:Health() <= damage) then
        if(target:IsNPC() or target:IsPlayer()) then
          local dissolverEnt = LaserLib.SpawnDissolver(laserEnt, target:GetPos(), attacker, dissolveType)

          if(target:IsPlayer()) then
            target:TakeDamage(damage, attacker, laserEnt)
            -- We need to kill the player first to get his ragdoll
            if(not target:GetRagdollEntity() or not target:GetRagdollEntity():IsValid()) then return end
            -- Thanks to Nevec for the player ragdoll idea, allowing us to dissolve him the cleanest way
            target:GetRagdollEntity():SetName(dissolverEnt.Target)
          else
            target:SetName(dissolverEnt.Target)
            if(target:GetActiveWeapon():IsValid()) then
              target:GetActiveWeapon():SetName(dissolverEnt.Target)
            end
          end

          dissolverEnt:Fire("Dissolve", dissolverEnt.Target, 0)
          dissolverEnt:Fire("Kill", "", 0.1)
        end

        if(killSound ~= nil and (target:Health() ~= 0 or target:IsPlayer())) then
          sound.Play(killSound, target:GetPos())
          target:EmitSound(Sound(killSound))
        end
      else
        laserEnt.NextLaserDamage = CurTime() + 0.3
      end
      target:TakeDamage(damage, attacker, laserEnt)
    end
  end

  local gsUnit = LaserLib.GetTool()
  local gsLaseremCls = LaserLib.GetClass(1, 1)
  function LaserLib.New(ply, pos, ang, model, angleOffset, key, width, length, damage, material, dissolveType, startSound, stopSound, killSound, toggle, startOn, pushProps, endingEffect, Vel, aVel, frozen)
    if(not (ply and ply:IsValid() and ply:IsPlayer())) then return nil end
    if(not ply:CheckLimit(gsUnit.."s")) then return nil end

    local laser = ents.Create(gsLaseremCls)
    if(not (laser and laser:IsValid())) then return nil end

    laser:SetPos(pos)
    laser:SetAngles(ang)
    laser:SetModel(Model(model))
    laser:SetAngleOffset(angleOffset)
    laser:Spawn()
    laser:Setup(width, length, damage, material, dissolveType, startSound, stopSound, killSound, toggle, startOn, pushProps, endingEffect, false)

    ply:AddCount(gsUnit.."s", laser)
    numpad.OnDown(ply, key, "Laser_On", laser)
    numpad.OnUp(ply, key, "Laser_Off", laser)

    local ttable   = {
      ply          = ply,
      key          = key,
      width        = width,
      length       = length,
      damage       = damage,
      material     = material,
      dissolveType = dissolveType,
      startSound   = startSound,
      stopSound    = stopSound,
      killSound    = killSound,
      toggle       = toggle,
      startOn      = startOn,
      pushProps    = pushProps,
      endingEffect = endingEffect,
      angleOffset  = angleOffset
    }

    table.Merge(laser:GetTable(), ttable)

    return laser
  end

end

--[[
Checks when the entity has reflective mirror texture
 * ent > Entity to retrieve the setting for
 * set > The dedicated parameeters setting to check
]]
function LaserLib.GetSetting(ent, set)
  if(not ent) then return nil end
  if(not ent:IsValid()) then return nil end
  local mat = ent:GetMaterial()
  if(mat == "") then
    mat = ent:GetMaterials()[1]
  end
  -- Protect hesh indexing by nil
  if(not mat) then return nil end
  -- Check for element overrides
  if(set[mat]) then return set[mat] end
  -- Check for emement category
  for i = 1, set.__size do
    local key = set[i]
    if(mat:find(key, 1, true)) then
      return set[key]
    end
  end; return nil
end

function LaserLib.GetReflect()
  return DATA.REFLECT["#"]
end

function LaserLib.GetRefract()
  return DATA.REFRACT["#"]
end

--[[
Projects the OBB onto the ray defined by position and direction
Returns the projected position as the beam position
 * ent > The laser entity
 * dir > The beam direction
]]
function LaserLib.GetBeamPos(ent, dir)
  local pos = Vector(ent:GetPos())
  local obb = ent:LocalToWorld(ent:OBBCenter())
        obb:Sub(pos)
  local ofs = obb:Dot(dir)
        obb:Set(dir)
        obb:Normalize()
        obb:Mul(ofs)
        pos:Add(obb)
  return pos
end

--[[
Traces a laser beam from the entity provided
 * entity > Entity origin to trace the beam from
 * origin > Inititial ray origin position vector
 * direct > Inititial ray world direction vector
 * length > Total beam length to be traced
 * bounce > Maximum amount of reflector bounces
]]
function LaserLib.DoBeam(entity, origin, direct, length, bounce)
  local data, trace = {}
  -- Configure data structure
  data.Tracing  = false
  data.TeFilter = entity
  data.VrOrigin = Vector(origin)
  data.VrDirect = Vector(direct)
  data.TvPoints = {}; table.insert(data.TvPoints, Vector(origin))
  data.TreIndex = {DATA.REFRACT["air"], DATA.REFRACT["air"]}
  data.MxBounce = math.floor(math.max(tonumber(bounce) or 0, 0))
  data.CrBounce = 0 -- All the bounces the loop made so far
  data.BmLength = math.max(tonumber(length) or 0, 0)

  if(data.BmLength <= 0) then return end
  if(not data.TeFilter) then return end
  if(not data.TeFilter:IsValid()) then return end
  if(data.VrDirect:LengthSqr() <= 0) then return end

  repeat
    if(StarGate) then
      trace = StarGate.Trace:New(data.VrOrigin, data.VrDirect:GetNormalized() * data.BmLength, data.TeFilter)
    else
      trace = util.QuickTrace(data.VrOrigin, data.VrDirect:GetNormalized() * data.BmLength, data.TeFilter)
    end

    table.insert(data.TvPoints, trace.HitPos)

    if(trace.Entity and trace.Entity:IsValid()) then
      if(LaserLib.GetSetting(trace.Entity, DATA.REFLECT)) then
        data.Tracing = true
        data.VrOrigin:Set(trace.HitPos)
        data.VrDirect:Set(LaserLib.GetReflected(data.VrDirect, trace.HitNormal))
        data.BmLength = data.BmLength - data.BmLength * trace.Fraction
        data.CrBounce = data.CrBounce + 1
      elseif(LaserLib.GetSetting(trace.Entity, DATA.REFRACT)) then
        data.Tracing = false -- Temporaty prevent inifinite looks when refracting the beam
      else
        data.Tracing = false
      end
    else
      data.Tracing = false
    end

  until(not data.Tracing or data.CrBounce > data.MxBounce)

  return trace, data
end
