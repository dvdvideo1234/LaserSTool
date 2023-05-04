include("shared.lua")

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  -- local p1 = self:GetNWVector("tr-pos1")
  -- local n1 = self:GetNWVector("tr-nrm1")
  -- LaserLib.DrawVector(p1, n1, 10, "RED")
  local p2 = self:GetNWVector("tr-pos2")
  local n2 = self:GetNWVector("tr-nrm2")
  LaserLib.DrawVector(p2, n2, 10, "GREEN")
end
