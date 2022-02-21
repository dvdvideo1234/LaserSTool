include("shared.lua")

function ENT:DrawBeam(src, org, dir, bmex, idx)
  local beam, trace = self:DoBeam(src, org, dir, bmex, idx)
  if(not beam) then return end
  local sors = bmex:GetSource()
  self:DrawTrace(beam, sors)
  self:DrawEndingEffect(beam, trace, sors)
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
