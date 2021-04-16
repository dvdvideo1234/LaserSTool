LaserLib = nil
LaserLib = LaserLib or {}

function LaserLib.GetReflectedVector(incident, normal)
  local reflect = Vector(normal)
        reflect:Mul(-2 * normal:Dot(incident))
        reflect:Add(incident)
  return reflect
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
            target:SetName( dissolverEnt.Target )
            if(target:GetActiveWeapon():IsValid()) then
              target:GetActiveWeapon():SetName( dissolverEnt.Target )
            end
          end

          dissolverEnt:Fire("Dissolve", dissolverEnt.Target, 0)
          dissolverEnt:Fire("Kill", "", 0.1)
        end

        if(killSound ~= nil and (target:Health() ~= 0 or target:IsPlayer())) then
          --WorldSound( Sound( killSound ), target:GetPos() )
          sound.Play(killSound, target:GetPos())
          target:EmitSound(Sound(killSound))
        end
      else
        laserEnt.NextLaserDamage = CurTime() + 0.3
      end
      --attacker:AddFrags(0)
      target:TakeDamage(damage, attacker, laserEnt)
    end
  end

end

--[[ Traces a laser beam from the entity provided
 * entity > Entity origin to trace the beam from
 * origin > Inititial ray origin position vector
 * direct > Inititial ray world direction vector
 * length > Total beam length to be traced
 * bounce > Maximum amount of reflector bounces
]]
local gsReflector = "models/madjawa/laser_reflector.mdl"
function LaserLib.DoBeam(entity, origin, direct, length, bounce)
  local data, trace = {}
  -- Configure data structure
  data.IsMirror = false
  data.TeFilter = entity
  data.VrOrigin = Vector(origin)
  data.VrDirect = Vector(direct)
  data.TvPoints = {data.Origin}
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

    if(trace.Entity and
       trace.Entity:IsValid() and
       trace.Entity:GetModel() == gsReflector)
    then
      data.IsMirror = true
      data.VrOrigin:Set(trace.HitPos)
      data.VrDirect:Set(LaserLib.GetReflectedVector(data.VrDirect, trace.HitNormal))
      data.BmLength = data.BmLength - data.BmLength * trace.Fraction
      data.TeFilter = trace.Entity
      data.CrBounce = data.CrBounce + 1
    else
      data.IsMirror = false
    end
  until(not data.IsMirror or data.CrBounce > data.MxBounce)

  return trace, data
end
