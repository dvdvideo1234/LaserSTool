include("shared.lua")

function ENT:DrawBeam(org, dir, index)
  local trace, data = self:DoBeam(org, dir, index)
  if(not data) then return end
  self:DrawTrace(data)
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(trace, data)
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
        local fulla = LaserLib.GetData("AMAX")[2]
        local delta = fulla / mcount
        local direc = self:GetDirectLocal()
        local eleva = self:GetElevatLocal()
        local marx = self:GetBeamLeanX()
        local mary = self:GetBeamLeanY()
        local angle = direc:AngleEx(eleva)
        self:DrawEffectBegin()
        for index = 1, mcount do
          local dir = mary * angle:Up()
                dir:Add(marx * angle:Forward())
          self:DrawBeam(nil, dir, index)
          angle:RotateAroundAxis(direc, delta)
        end
        self:DrawEffectEnd()
      elseif(mcount == 1) then
        self:DrawEffectBegin()
        self:DrawBeam()
        self:DrawEffectEnd()
      end
      self:RemHitReports(mcount)
    end
  else
    if(mcount > 1) then
      render.SetColorMaterial()
      local fulla = LaserLib.GetData("AMAX")[2]
      local delta = fulla / mcount
      local lndir = LaserLib.GetData("LNDIRACT"):GetFloat()
      local color = LaserLib.GetColor("YELLOW")
      local orign = self:GetBeamOrigin()
      local direc = self:GetDirectLocal()
      local eleva = self:GetElevatLocal()
      local marx = self:GetBeamLeanX()
      local mary = self:GetBeamLeanY()
      local angle = direc:AngleEx(eleva)
      for index = 1, mcount do
        local dir = mary * angle:Up()
              dir:Add(marx * angle:Forward())
              dir:Set(self:GetBeamDirection(dir))
              dir:Normalize(); dir:Mul(lndir)
              dir:Add(orign)
        render.DrawLine(orign, dir, color)
        angle:RotateAroundAxis(direc, delta)
      end
    elseif(mcount == 1) then
      local lndir = LaserLib.GetData("LNDIRACT"):GetFloat()
      local color = LaserLib.GetColor("YELLOW")
      local orign = self:GetBeamOrigin()
      local direc = self:GetBeamDirection()
            direc:Mul(lndir); direc:Add(orign)
      render.DrawLine(orign, direc, color)
    end
    self:RemHitReports()
  end
end
