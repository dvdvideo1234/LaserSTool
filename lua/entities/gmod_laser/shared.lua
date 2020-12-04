
ENT.Type 			= "anim";
ENT.Base			= "base_anim";
ENT.PrintName		= "Laser";
ENT.WireDebugName	= "Laser"
ENT.Author			= "MadJawa";
ENT.Information		= "";
ENT.Category		= "";

ENT.Spawnable		= false;
ENT.AdminSpawnable	= false;

LASER_MAXBOUNCES	= 4; -- FIXME: make a convar for this


function ENT:Setup( width, length, damage, material, dissolveType, startSound, stopSound, killSound, toggle, startOn, pushProps, endingEffect, update )
	
	self.Entity:SetBeamWidth( width );
	self.defaultWidth = width;
	self.Entity:SetBeamLength( length );
	self.defaultLength = length;
	self.Entity:SetDamageAmmount( damage );
	self.Entity:SetBeamMaterial( material );
	self.Entity:SetDissolveType( dissolveType );
	self.Entity:SetStartSound( startSound );
	self.Entity:SetStopSound( stopSound );
	self.Entity:SetKillSound( killSound );
	self.Entity:SetToggle( toggle );
	if ( ( not toggle and update ) or ( not update ) ) then self.Entity:SetOn( startOn ); end
	self.Entity:SetPushProps( pushProps );
	self.Entity:SetEndingEffect( endingEffect );
	
	if ( update ) then
		local ttable = {
			width = width,
			length = length,
			damage = damage,
			material = material,
			dissolveType = dissolveType,
			startSound = startSound,
			stopSound = stopSound,
			killSound = killSound,
			toggle = toggle,
			startOn = startOn,
			pushProps = pushProps,
			endingEffect = endingEffect
		}
		table.Merge(self.Entity:GetTable(), ttable );
	end
	
end

// FIXME : find a way to dynamically get the laser unit vector according the angle offset of bad oriented models
function ENT:GetBeamDirection()

	local angleOffset = self:GetAngleOffset();
	if ( angleOffset==90 ) then return self.Entity:GetForward();
	elseif ( angleOffset==180 ) then return -1*self.Entity:GetUp();
	elseif ( angleOffset==270 ) then return -1*self.Entity:GetForward();
	else return self.Entity:GetUp(); end

end



/* ----------------------
	Width
---------------------- */
function ENT:SetBeamWidth( num )
	local width = math.Clamp( num, 1, 100 );
	self.Entity:SetNWInt( "Width", width );
	if WireAddon then Wire_TriggerOutput( self.Entity, "Width", width ); end
end

function ENT:GetBeamWidth()
	return self.Entity:GetNWInt( "Width" );
end


/* ----------------------
	 Length
---------------------- */
function ENT:SetBeamLength( num )
	local length = math.abs( num );
	self.Entity:SetNWInt( "Length", length );
	if WireAddon then Wire_TriggerOutput( self.Entity, "Length", length ); end
end

function ENT:GetBeamLength()
	return self.Entity:GetNWInt( "Length" );
end


/* ----------------------
	Damage
---------------------- */
function ENT:SetDamageAmmount( num )
	local damage = math.Round( num );
	self.Entity:SetNWInt( "Damage", damage );
	if WireAddon then Wire_TriggerOutput( self.Entity, "Damage", damage ); end
end

function ENT:GetDamageAmmount()
	return self.Entity:GetNWInt( "Damage" );
end


/* ----------------------
     Model Offset
---------------------- */
function ENT:SetAngleOffset( offset )
	self.Entity:SetNWInt( "AngleOffset", offset );
end

function ENT:GetAngleOffset()
	return self.Entity:GetNWInt( "AngleOffset" );
end


/* ----------------------
	Material
---------------------- */
function ENT:SetBeamMaterial ( material )
	self.Entity:SetNWString( "Material", material );
end

function ENT:GetBeamMaterial()
	return self.Entity:GetNWString( "Material" );
end


/* ----------------------
      Dissolve type
---------------------- */
function ENT:SetDissolveType( dissolvetype )
	self.Entity:SetNWString( "DissolveType", dissolvetype );
end

function ENT:GetDissolveType()
	local dissolvetype = self.Entity:GetNWString( "DissolveType" );
	
	if ( dissolvetype == "energy" ) then return 0;
	elseif ( dissolvetype == "lightelec" ) then return 2;
	elseif ( dissolvetype == "heavyelec" ) then return 1;
	else return 3; end
end


/* ----------------------
          Sounds
---------------------- */
-- FIXME : Well, not really something to fix, but it seems that I can't set networked strings with a length higher than 39 (not ideal for sounds)
function ENT:SetStartSound( sound )
	self.startSound = sound;
end

function ENT:GetStartSound()
	return self.startSound;
end

function ENT:SetStopSound( sound )
	self.stopSound = sound;
end

function ENT:GetStopSound()
	return self.stopSound;
end

function ENT:SetKillSound( sound )
	self.killSound = sound;
end

function ENT:GetKillSound()
	return self.killSound;
end


/* ----------------------
	Toggle
---------------------- */
function ENT:SetToggle( bool )
	self.Entity:SetNWBool( "Toggle", bool );
end

function ENT:GetToggle()
	return self.Entity:GetNWBool( "Toggle" );
end


/* ----------------------
	On/Off
---------------------- */
function ENT:SetOn( bool )
	if ( bool ~= self.Entity:GetOn() ) then
		if ( bool == true ) then
			self.Entity:EmitSound( Sound( self.Entity:GetStartSound() ) );
		else
			self.Entity:EmitSound( Sound( self.Entity:GetStopSound() ) );
		end
	end
	
	self.Entity:SetNWBool( "On", bool );
	
	if WireAddon then
		local wireBool = 0;
		if ( bool == true ) then wireBool = 1; end
		Wire_TriggerOutput( self.Entity, "On", wireBool );
	end
end

function ENT:GetOn()
	return self.Entity:GetNWBool( "On" );
end


/* ----------------------
      Prop pushing
---------------------- */
function ENT:SetPushProps( bool )
	self.Entity:SetNWBool( "PushProps", bool );
end

function ENT:GetPushProps()
	return self.Entity:GetNWBool( "PushProps" );
end


/* ----------------------
     Ending Effect
---------------------- */
function ENT:SetEndingEffect ( bool )
	self.Entity:SetNWBool( "EndingEffect", bool );
end

function ENT:GetEndingEffect()
	return self.Entity:GetNWBool( "EndingEffect" );
end