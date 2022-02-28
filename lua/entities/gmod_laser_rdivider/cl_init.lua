include("shared.lua")

function ENT:Initialize()
  self:SetActor()
end

function ENT:DrawBeam(beam, trace)
  if(not beam) then return end
  local usent = beam:GetSource()
  local endrw = usent:GetEndingEffect()
  local corgb = usent:GetBeamColorRGBA(true)
  local imatr = usent:GetBeamMaterial(true)
  beam:Draw(usent, imatr) -- Draws the beam trace
  beam:DrawEffect(usent, trace, endrw) -- Handle drawing the effects
  return self
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
end
