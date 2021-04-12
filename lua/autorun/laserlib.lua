LaserLib = nil
LaserLib = LaserLib or {};

function LaserLib.GetReflectedVector( incidentVector, surfaceNormal )

	return incidentVector - 2 * ( surfaceNormal:Dot( incidentVector ) * surfaceNormal );

end

if ( SERVER ) then

	AddCSLuaFile( "autorun/laserlib.lua" );
	
	function LaserLib.SpawnDissolver( ent, position, attacker, dissolveType )
		Dissolver = ents.Create( "env_entity_dissolver" );
		Dissolver.Target = "laserdissolve"..ent:EntIndex();
		Dissolver:SetKeyValue( "dissolvetype", dissolveType );
		Dissolver:SetKeyValue( "magnitude", 0 );
		Dissolver:SetPos( position );
		Dissolver:SetPhysicsAttacker( attacker );
		Dissolver:Spawn();
		
		return Dissolver;
	end
	
	function LaserLib.DoDamage( target, hitPos, normal, beamDir, damage, attacker, dissolveType, pushProps, killSound, laserEnt )
	
		laserEnt.NextLaserDamage = laserEnt.NextLaserDamage or CurTime();
	
		if ( pushProps and target:GetPhysicsObject():IsValid() ) then target:GetPhysicsObject():ApplyForceCenter( beamDir * 1600 ); end
		
		if ( CurTime() >= laserEnt.NextLaserDamage ) then
			if ( target:IsVehicle() and target:GetDriver():IsValid() ) then -- we must kill the driver!
				target = target:GetDriver();
				target:Kill(); -- takedamage doesn't seem to work on a player inside a vehicle
			end		
			
			if ( target:GetClass() == "shield" ) then
				target:Hit( laserEnt, hitPos, math.Clamp( damage / 2500 * 3, 0, 4), -1*normal );
				laserEnt.NextLaserDamage = CurTime() + 0.3;
				return; -- we stop here because we hit a shield
			end
			
			if ( target:Health() <= damage ) then
				if ( target:IsNPC() or target:IsPlayer() ) then
					local dissolverEnt = LaserLib.SpawnDissolver( laserEnt, target:GetPos(), attacker, dissolveType );
					
					if ( target:IsPlayer() ) then
						target:TakeDamage( damage, attacker, laserEnt ); -- we need to kill the player first to get his ragdoll
						if ( not target:GetRagdollEntity() or not target:GetRagdollEntity():IsValid() ) then return; end
						target:GetRagdollEntity():SetName( dissolverEnt.Target ); -- thanks to Nevec for the player ragdoll idea, allowing us to dissolve him the cleanest way
					else
						target:SetName( dissolverEnt.Target );
						if ( target:GetActiveWeapon():IsValid() ) then target:GetActiveWeapon():SetName( dissolverEnt.Target ); end
					end
					
					dissolverEnt:Fire( "Dissolve", dissolverEnt.Target, 0 );
					dissolverEnt:Fire( "Kill", "", 0.1 );
				end
				
				if ( killSound ~= nil and ( target:Health() ~= 0 or target:IsPlayer() ) ) then
					--WorldSound( Sound( killSound ), target:GetPos() );
					sound.Play( killSound, target:GetPos())
					target:EmitSound( Sound( killSound ) );
				end
			else
				laserEnt.NextLaserDamage = CurTime() + 0.3;
			end
			--attacker:AddFrags(0)
			target:TakeDamage( damage, attacker, laserEnt );
		end
	end

end