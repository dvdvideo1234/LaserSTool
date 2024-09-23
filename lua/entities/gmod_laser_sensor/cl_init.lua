include("shared.lua")

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(true)
end
