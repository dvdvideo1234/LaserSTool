--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]

ENT.Type           = "anim"
ENT.PrintName      = "Laser Crystal"
ENT.Base           = "gmod_laser"
ENT.Author         = "MadJawa"
ENT.Information    = ENT.PrintName
ENT.Category       = "Other"
ENT.Spawnable      = true
ENT.AdminSpawnable = true

function ENT:GetBeamDirection()
  -- Crystal always cast the beam in the same direction
	return self.Entity:GetUp()
end

function ENT:GetBeamStart()
  -- FIXME: make it not start in the middle of the prop
	return Vector(0, 0, 0)
end
