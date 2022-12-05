include("shared.lua")

local AMAX     = LaserLib.GetData("AMAX")
local LNDIRACT = LaserLib.GetData("LNDIRACT")

function ENT:DrawBeam(org, dir, idx)
  local beam, trace = self:DoBeam(org, dir, idx)
  if(not beam) then return end
  self:DrawTrace(beam, nil, beam.BmColor)
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(beam, trace)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  local mcount = self:GetBeamCount()
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      if(mcount > 1) then
        local delta = AMAX[2] / mcount
        local direc = self:GetDirectLocal()
        local upwrd = self:GetUpwardLocal()
        local marx = self:GetBeamLeanX()
        local mary = self:GetBeamLeanY()
        local angle = direc:AngleEx(upwrd)
        self:UpdateFlags()
        for idx = 1, mcount do
          local dir = mary * angle:Up()
                dir:Add(marx * angle:Forward())
          self:DrawBeam(nil, dir, idx)
          angle:RotateAroundAxis(direc, delta)
        end
      elseif(mcount == 1) then
        self:UpdateFlags()
        self:DrawBeam()
      end
      self:SetHitReportMax(mcount)
    end
  else
    if(mcount > 1) then
      local lndir = LNDIRACT:GetFloat()
      if(lndir > 0) then
        render.SetColorMaterial()
        local delta = AMAX[2] / mcount
        local color = LaserLib.GetColor("YELLOW")
        local orign = self:GetBeamOrigin()
        local direc = self:GetDirectLocal()
        local upwrd = self:GetUpwardLocal()
        local marx = self:GetBeamLeanX()
        local mary = self:GetBeamLeanY()
        local angle = direc:AngleEx(upwrd)
        for idx = 1, mcount do
          local dir = mary * angle:Up()
                dir:Add(marx * angle:Forward())
                dir:Set(self:GetBeamDirection(dir))
                dir:Normalize(); dir:Mul(lndir)
                dir:Add(orign)
          render.DrawLine(orign, dir, color)
          angle:RotateAroundAxis(direc, delta)
        end
      elseif(mcount == 1) then
        local color = LaserLib.GetColor("YELLOW")
        local orign = self:GetBeamOrigin()
        local direc = self:GetBeamDirection()
              direc:Mul(lndir); direc:Add(orign)
        render.DrawLine(orign, direc, color)
      end
    end
    self:SetHitReportMax()
  end
end
