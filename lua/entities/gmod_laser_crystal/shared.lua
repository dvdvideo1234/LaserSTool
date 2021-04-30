--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]

ENT.Type           = "anim"
ENT.PrintName      = "Laser Crystal"
ENT.Base           = LaserLib.GetClass(1, 1)
if(WireLib) then
  ENT.WireDebugName = ENT.PrintName
end
ENT.Author         = "MadJawa"
ENT.Category       = "Other"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.Information    = ENT.PrintName

-- Override the beam transormation
function ENT:SetBeamTransform()
  local direct = Vector(0,0,1) -- Local Direction
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  return self
end
