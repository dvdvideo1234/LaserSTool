include("shared.lua")

function ENT:DrawBeam(org, dir, index)
  local trace, data = self:DoBeam(org, dir, index)
  if(data) then
    local color = self:GetBeamColor()
    local ushit = LocalPlayer():GetEyeTrace().HitPos
    local bbmin = self:LocalToWorld(self:OBBMins())
    local bbmax = self:LocalToWorld(self:OBBMaxs())
    local first = data.TvPoints[1][1]
    -- Extend render bounds with player hit position
    LaserLib.UpdateRB(bbmin, ushit, math.min)
    LaserLib.UpdateRB(bbmax, ushit, math.max)
    -- Extend render bounds with the first node
    LaserLib.UpdateRB(bbmin, first, math.min)
    LaserLib.UpdateRB(bbmax, first, math.max)
    -- Material must be cached and pdated with left click setup
    local mat = self:GetBeamMaterial(true)
    if(mat) then render.SetMaterial(mat) end
    -- Draw the beam sequentially bing faster
    for idx = 2, data.TvPoints.Size do
      local org = data.TvPoints[idx - 1]
      local new = data.TvPoints[idx - 0]
      local otx, ntx, wdt = org[1], new[1], org[2]

      -- Make sure the coordinates are conveted to world ones
      LaserLib.UpdateRB(bbmin, ntx, math.min)
      LaserLib.UpdateRB(bbmax, ntx, math.max)

      if(org[5] or new[5]) then
        -- Draw the actual beam texture
        local len = (ntx - otx):Length()
        local dtm = -(15 * CurTime())
        render.DrawBeam(otx,
                        ntx,
                        wdt,
                        dtm,
                        (dtm + len / 24),
                        color:ToColor())
      end
    end
    -- Adjust the render bounds with world-space coordinates
    self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster
    -- Handle drawing the effects when have to be drawwn
    self:DrawEndingEffect(trace, data)
  end
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
      local delta = 360 / mcount
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
      local direc = self:GetDirectLocal()
            direc:Mul(lndir); direc:Add(orign)
      render.DrawLine(orign, direc, color)
    end
    self:RemHitReports()
  end
end
