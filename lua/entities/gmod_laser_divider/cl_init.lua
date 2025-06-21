include("shared.lua")

function ENT:DrawBeam(src, org, dir, bmex)
  local beam = self:DoBeam(src, org, dir, bmex)
  if(not beam) then return end
  local sors = bmex:GetSource()
  self:DrawTrace(beam, sors)
  self:DrawEndingEffect(beam, sors)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:UpdateFlags()
    self:UpdateSources()
  end
end
