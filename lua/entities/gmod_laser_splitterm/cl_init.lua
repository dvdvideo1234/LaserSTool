include("shared.lua")

function ENT:DrawBeam(src, org, dir, bmex, vdot)
  local beam = self:DoBeam(src, org, dir, bmex, vdot)
  if(not beam) then return end
  local sors = bmex:GetSource()
  self:DrawTrace(beam, sors, beam.NvColor)
  self:DrawEndingEffect(beam, sors)
end

function ENT:Draw()
  self:UpdateViewRB()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:UpdateInit()
    self:UpdateSources()
  end
end
