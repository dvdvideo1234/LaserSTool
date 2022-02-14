include("shared.lua")

function ENT:DrawBeam(src, org, dir, bmex, idx)
  local trace, beam = self:DoBeam(src, org, dir, bmex, idx)
  if(not beam) then return end
  self:DrawTrace(beam, bmex.BmSource)
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(trace, beam, bmex.BmSource)
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
