include("shared.lua")

function ENT:DrawBeam(src, org, dir, sdat, mdot, idx)
  local trace, data = self:DoBeam(src, org, dir, sdat, mdot, idx)
  if(data) then
    local color = sdat.BmSource:GetBeamColor()
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
    local mat = sdat.BmSource:GetBeamMaterial(true)
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
    self:DrawEndingEffect(trace, data, sdat.BmSource)
  end
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:DrawEffectBegin()
    self:UpdateSources()
    self:DrawEffectEnd()
  end
end
