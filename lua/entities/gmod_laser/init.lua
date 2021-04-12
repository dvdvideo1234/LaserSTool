
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );

include( "shared.lua" );

resource.AddFile( "materials/vgui/entities/gmod_laser_killicon.vtf" );
resource.AddFile( "materials/vgui/entities/gmod_laser_killicon.vmt" );

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	WireLib.ApplyDupeInfo(ply, ent, info, GetEntByID)
end

function ENT:PreEntityCopy()
	duplicator.StoreEntityModifier(self, "WireDupeInfo", WireLib.BuildDupeInfo(self))
end

local function EntityLookup(CreatedEntities)
	return function(id, default)
		if id == nil then return default
		elseif id == 0 then return game.GetWorld() end
		local ent = CreatedEntities[id] or (isnumber(id) and ents.GetByIndex(id))
		if IsValid(ent) then return ent else return default end
	end
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, EntityLookup(CreatedEntities))
	end
end

function ENT:Initialize()

	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetSolid( SOLID_VPHYSICS );
	
	local phys = self:GetPhysicsObject();
	if ( phys:IsValid() ) then
		phys:Wake();
	end
	
	if WireAddon then
		self.Inputs = Wire_CreateInputs( self, { "On", "Length", "Width", "Damage" } )
		self.Outputs = Wire_CreateOutputs( self, { "On", "Length", "Width", "Damage" } )
	end
	
end


function ENT:Think()

	if ( self:GetOn() ) then
		local trace = {};
		
		local beamStart = self:GetPos();
		local beamDir = self:GetBeamDirection();
		local beamLength = self:GetBeamLength();
		local beamFilter = self;
		
		local bounces = 0;
		
		repeat
			if ( StarGate ~= nil ) then
				trace = StarGate.Trace:New( beamStart, beamDir:GetNormalized() * beamLength, beamFilter );
			else
				trace = util.QuickTrace( beamStart, beamDir:GetNormalized() * beamLength, beamFilter )
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
			
			LaserLib.DoDamage(	trace.Entity, trace.HitPos, trace.Normal, beamDir, self:GetDamageAmmount(), self.ply,self:GetDissolveType(), self:GetPushProps(), self:GetKillSound(), self );
			
		end
	end
	
	self:NextThink( CurTime() );
	return true;

end



function ENT:OnRemove()
	if WireAddon then Wire_Remove( self ); end
end

function ENT:OnRestore()
	if WireAddon then Wire_Restored( self ); end
end



function ENT:TriggerInput( iname, value )

	if ( iname == "On" ) then
		self:SetOn( tobool( value ) );
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