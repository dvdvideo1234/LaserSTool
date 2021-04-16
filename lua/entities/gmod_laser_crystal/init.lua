--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddSingleFile("materials/vgui/entities/gmod_laser_crystal.vmt")
resource.AddSingleFile("materials/vgui/entities/gmod_laser_crystal.vtf")

local varMaxBounces = GetConVar("laseremitter_maxbounces")

function ENT:SpawnFunction(ply, tr)
 	if(not tr.Hit) then return end
  -- Sets the right angle at spawn. Thanks to aVoN!
 	local pos = tr.HitPos + tr.HitNormal * 35
  local yaw = (ply:GetAimVector():Angle().y + 180) % 360
 	local ent = ents.Create("gmod_laser_crystal")
	ent:SetModel("models/Combine_Helicopter/helicopter_bomb01.mdl")
	ent:SetMaterial("models/props_lab/xencrystal_sheet")
	ent:SetPos(pos)
	ent:SetAngles(Angle(0, yaw, 0))
 	ent:Spawn()
 	ent:Activate()
	return ent
end

function ENT:Initialize()

	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	local phys = self.Entity:GetPhysicsObject()
	if(phys:IsValid()) then phys:Wake() end

	self.Targets = {}
	self.Hits    = {}

	self:SetBeamLength(0)
	self:SetBeamWidth(0, true)
	self:SetDamageAmmount(0)
	self:SetBeamMaterial("cable/physbeam")

	if(WireLib) then
		WireLib.CreateSpecialOutputs(self.Entity, {"Focusing", "Hit"})
	end
end

function ENT:Think()

	local isUpdate

	for k, v in pairs(self.Hits) do
		local lastTarget
		if v then lastTarget = v.Targets[#v.Targets]
		else lastTarget = nil end

		if(not lastTarget or lastTarget ~= self) then
			table.remove(self.Hits, k)
			isUpdate = true
		elseif(v and v.IsModified) then
			isUpdate = true
			v.IsModified = false
		end
	end

	if(isUpdate) then
    self:UpdateLaserProperties()
  end

	if(#self.Hits > 0) then
    self:SetOn(true)
  else
    self:SetOn(false)
    self.Hits = {}
  end

	if(WireLib) then
    WireLib.TriggerOutput(self.Entity, "Focusing", #self.Hits)
  end

	if(self:GetOn()) then
		local trace = LaserLib.DoBeam(self.Entity,
                                  self:GetBeamStart(),
                                  self:GetBeamDirection(),
                                  self:GetBeamLength(),
                                  varMaxBounces:GetInt())

		if(WireLib) then
			if(trace.Entity and trace.Entity:IsValid()) then
				WireLib.TriggerOutput(self.Entity, "Hit", 1)
			else
				WireLib.TriggerOutput(self.Entity, "Hit", 0)
			end
		end
	end

	self.Entity:NextThink(CurTime())

	return true
end

function ENT:UpdateLaserProperties()
	local width   , length, damage       = 0, 0, 0
  local oldpower, power , mostPowerful = 0, 0, 1

	if(#self.Hits > 0) then
		for k, v in pairs(self.Hits) do
			local laserWidth = v:GetBeamWidth()
      local laserDmg   = v:GetDamageAmmount()
			length = length + v:GetBeamLength()
			width  = width  + laserWidth
			damage = damage + laserDmg

			power = 3 * laserWidth + laserDmg
			if(power > oldpower) then
				mostPowerful = k
				oldpower = power
			end
		end

		self:SetBeamWidth(math.Clamp(width, 1, 100))
		self:SetBeamLength(length)
		self:SetDamageAmmount(damage)

		-- We set the same non-addable properties as the most powerful laser (biggest damage/width)
		self:SetBeamMaterial(self.Hits[mostPowerful]:GetBeamMaterial())
		self:SetDissolveType(self.Hits[mostPowerful]:GetDissolveType())
		self:SetEndingEffect(self.Hits[mostPowerful]:GetEndingEffect())
		self:SetPushProps(self.Hits[mostPowerful]:GetPushProps())
		self:SetKillSound(self.Hits[mostPowerful]:GetKillSound())
		self.ply = self.Hits[mostPowerful].ply

		self.IsModified = true
	end
end

function ENT:UpdateBounceCount(ent)
	if(not table.HasValue(self.Hits, ent) and
     not (ent:GetClass() == "gmod_laser_crystal" and self:IsInfiniteLaserLoop(ent)))
  then
		table.insert(self.Hits, ent)
		if(not ent.IsModified) then
      self:UpdateLaserProperties()
    end -- When modified is true, it will update the laser on the next think
	end
end

function ENT:IsInfiniteLaserLoop(ent)
	if(ent == self) then return true end

	local crystals = {ent}

	repeat
		newCrystals = {}
		for k, v in pairs(crystals) do
			for j, w in pairs(v.Hits) do
				if(w:GetClass() == "gmod_laser_crystal") then
          -- This crystal is being hit by ours : infinite loop
					if(w == self or table.HasValue(w.Hits, self)) then return true
					else table.insert(newCrystals, w) -- If not, we add it to the table
					end
				end
			end
		end
		crystals = table.Copy(newCrystals)
	until(#crystals == 0)

	return false
end
