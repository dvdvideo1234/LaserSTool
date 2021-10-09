include("shared.lua")

function ENT:DrawBeam(src, org, dir, sdat, idx)
  local trace, data = self:DoBeam(src, org, dir, sdat, idx)
  if(not data) then return end
  self:DrawTrace(data, sdat.BmSource)
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(trace, data, sdat.BmSource)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:DrawEffects()
    self:UpdateSources()
  end
end
