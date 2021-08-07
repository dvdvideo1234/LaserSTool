--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
 - MadJawa
]]

include("shared.lua")

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      local mcount = self:GetBeamCount()
      if(mcount > 1) then
        local delta = 360 / mcount
        local direc = self:GetDirectLocal()
        local eleva = self:GetElevatLocal()
        local marx = self:GetBeamLeanX()
        local mary = self:GetBeamLeanY()
        local angle = direc:AngleEx(eleva)
        self:DrawEffectBegin()
        for index = 1, mcount do
          local dir = mary * angle:Up()
                dir:Add(marx * angle:Forward())
          self:DrawBeam(nil, dir, length, width)
          angle:RotateAroundAxis(direc, delta)
        end
        self:DrawEffectEnd()
      else
        self:DrawEffectBegin()
        self:DrawBeam(nil, nil, length, width)
        self:DrawEffectEnd()
      end
    end
  else
    local mcount = self:GetBeamCount()
    if(mcount < 1) then return end
    render.SetColorMaterial()
    local delta = 360 / mcount
    local color = LaserLib.GetColor("YELLOW")
    local orign = self:GetBeamOrigin()
    local direc = self:GetDirectLocal()
    local eleva = self:GetElevatLocal()
    local marx = self:GetBeamLeanX()
    local mary = self:GetBeamLeanY()
    local angle = direc:AngleEx(eleva)
    self:DrawEffectBegin()
    for index = 1, mcount do
      local dir = mary * angle:Up()
            dir:Add(marx * angle:Forward())
            dir:Set(self:GetBeamDirection(dir))
            dir:Normalize(); dir:Mul(15)
            dir:Add(orign)
      render.DrawLine(orign, dir, color)
      angle:RotateAroundAxis(direc, delta)
    end
  end
end
