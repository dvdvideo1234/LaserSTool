include("shared.lua")

function ENT:DrawBeam(src, org, dir, bmex, vdot)
  local beam, trace = self:DoBeam(src, org, dir, bmex, vdot)
  if(not beam) then return end
  local sors = bmex:GetSource()
  self:DrawTrace(beam, sors, beam.BmColor)
  self:DrawEndingEffect(beam, trace, sors)
end

function ENT:Draw()
  self:UpdateViewRB()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:UpdateFlags()
    self:UpdateSources()
  end
end
