
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );

include( "shared.lua" );

resource.AddFile( "materials/vgui/entities/gmod_laser_killicon.vtf" );
resource.AddFile( "materials/vgui/entities/gmod_laser_killicon.vmt" );


function ENT:Initialize()

	self.Entity:PhysicsInit( SOLID_VPHYSICS );
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS );
	self.Entity:SetSolid( SOLID_VPHYSICS );
	
	local phys = self.Entity:GetPhysicsObject();
	if ( phys:IsValid() ) then
		phys:Wake();
	end
	
	if WireAddon then
		self.Inputs = Wire_CreateInputs( self.Entity, { "On", "Length", "Width", "Damage" } )
		self.Outputs = Wire_CreateOutputs( self.Entity, { "On", "Length", "Width", "Damage" } )
	end
	
end


function ENT:Think()

	if ( self:GetOn() ) then
		local trace = {};
		
		local beamStart = self.Entity:GetPos();
		local beamDir = self:GetBeamDirection();
		local beamLength = self:GetBeamLength();
		local beamFilter = self.Entity;
		
		local bounces = 0;
		
		repeat
			if ( StarGate ~= nil ) then
				trace = StarGate.Trace:New( beamStart, beamDir:GetNormalized() * beamLength, beamFilter );
			else
				trace = util.QuickTrace( beamStart, (beamDir:GetNormalized() * beamLength), beamFilter )
			end
			
			if ( trace.Entity and trace.Entity:IsValid() and trace.Entity:GetModel() == "models/madjawa/laser_reflector.mdl" ) then
				isMirror = true;
				beamStart = trace.HitPos;
				beamDir = LaserLib.GetReflectedVector( beamDir, trace.HitNormal )
				beamLength = beamLength - beamLength * trace.Fraction;
				beamFilter = trace.Entity;
				bounces = bounces + 1;
				-- FIXME : make the owner of the mirror get the kill instead of the owner of the laser
			else
				isMirror = false;
			end		
		until ( isMirror == false or bounces > LASER_MAXBOUNCES )

		if(	self:GetDamageAmmount() > 0 and trace.Entity and trace.Entity:IsValid() and
			trace.Entity:GetClass() ~= "gmod_laser" and trace.Entity:GetModel() ~= "models/madjawa/laser_reflector.mdl" ) then
			
			LaserLib.DoDamage(	trace.Entity, trace.HitPos, trace.Normal, beamDir, self:GetDamageAmmount(), self.ply,self:GetDissolveType(), self:GetPushProps(), self:GetKillSound(), self.Entity );
			
		end
	end
	
	self.Entity:NextThink( CurTime() );
	return true;

end



function ENT:OnRemove()
	if WireAddon then Wire_Remove( self.Entity ); end
end

function ENT:OnRestore()
	if WireAddon then Wire_Restored( self.Entity ); end
end



function ENT:TriggerInput( iname, value )

	if ( iname == "On" ) then
		self:SetOn( util.tobool( value ) );
	elseif ( iname == "Length" ) then
		if ( value == 0 ) then value = self.defaultLength; end
		self:SetBeamLength( value );
	elseif ( iname == "Width" ) then
		if ( value == 0 ) then value = self.defaultWidth; end
		self:SetBeamWidth( value );
	elseif ( iname == "Damage" ) then
		self:SetDamageAmmount( value );
	end

end



local function On( ply, ent )

	if ( not ent or ent == NULL ) then return; end
	ent:SetOn( !ent:GetOn() );

end

local function Off( ply, ent )

	if ( not ent or ent == NULL or ent:GetToggle() ) then return; end
	ent:SetOn( !ent:GetOn() );

end

numpad.Register( "Laser_On", On ) 
numpad.Register( "Laser_Off", Off ) 