include("shared.lua")

local gtAMAX     = LaserLib.GetData("AMAX")
local cvLNDIRACT = LaserLib.GetData("LNDIRACT")
local gcYELLOW   = LaserLib.GetColor("YELLOW")

function ENT:DrawBeam(org, dir, idx)
  local beam = self:DoBeam(org, dir, idx)
  if(not beam) then return end
  self:DrawTrace(beam, nil, beam.NvColor)
  -- Handle drawing the effects when have to be drawn
  self:DrawEndingEffect(beam)
end

function ENT:Draw()
  self:UpdateViewRB()
  self:DrawModel()
  self:DrawShadow(false)
  local mcount = self:GetBeamCount()
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      if(mcount > 0) then
        local delta = gtAMAX[2] / mcount
        local forwd = self:GetDirectLocal()
        local upwrd = self:GetUpwardLocal()
        local angle = self:GetLeanAngle(forwd, upwrd)
        self:UpdateInit()
        for idx = 1, mcount do
          self:DrawBeam(nil, angle:Forward(), idx)
          if(mcount > 1) then angle:RotateAroundAxis(forwd, delta) end
        end
      end
      self:SetHitReportMax(mcount)
    end
  else
    local lndir = cvLNDIRACT:GetFloat()
    if(lndir > 0) then
      if(mcount > 1) then
        render.SetColorMaterial()
        local beang = self:GetAngles()
        local orign = self:GetBeamOrigin()
        local delta = gtAMAX[2] / mcount
        local forwd = self:GetDirectLocal()
        local upwrd = self:GetUpwardLocal()
        local angle = self:GetLeanAngle(forwd, upwrd)
        for idx = 1, mcount do
          local orend = angle:Forward(); orend:Mul(lndir)
          orend:Rotate(beang) orend:Add(orign)
          render.DrawLine(orign, orend, gcYELLOW)
          if(mcount > 1) then angle:RotateAroundAxis(forwd, delta) end
        end
      end
    end
    self:SetHitReportMax()
  end
end
