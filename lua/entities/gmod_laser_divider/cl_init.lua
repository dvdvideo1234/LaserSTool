include("shared.lua")

function ENT:DrawBeam(src, org, dir, bmsr)
  local beam = self:DoBeam(src, org, dir, bmsr)
  if(not beam) then return end
  local sors = bmsr:GetSource()
  self:DrawTrace(beam, sors)
  self:DrawEndingEffect(beam, sors)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:UpdateInit()
    self:UpdateSources()
  end
end
