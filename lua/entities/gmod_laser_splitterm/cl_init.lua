include("shared.lua")

function ENT:DrawBeam(src, org, dir, sdat, vdot, idx)
  local trace, beam = self:DoBeam(src, org, dir, sdat, vdot, idx)
  if(not beam) then return end
  self:DrawTrace(beam, sdat.BmSource, beam.BmColor)
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(trace, beam, sdat.BmSource)
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
