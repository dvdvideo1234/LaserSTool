include("shared.lua")

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(true)
end
