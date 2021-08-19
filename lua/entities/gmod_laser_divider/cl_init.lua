include("shared.lua")

function ENT:DrawEndingEffect(src, trace, data, sdat)
  if(trace and not trace.HitSky and
    sdat.BmSource:GetEndingEffect() and self.drawEffect)
  then
    if(not self.beamEffect) then
      self.beamEffect = EffectData()
    end -- Allocate effect data class
    if(trace.Hit) then
      local ent = trace.Entity
      local eff = self.beamEffect
      if(not LaserLib.IsSource(ent)) then
        eff:SetStart(trace.HitPos)
        eff:SetOrigin(trace.HitPos)
        eff:SetNormal(trace.HitNormal)
        eff:SetScale(1)
        util.Effect("AR2Impact", eff)
        -- Draw particle effects
        if(data.NvDamage > 0) then
          if(not (ent:IsPlayer() or ent:IsNPC())) then
            local dir = LaserLib.GetReflected(data.VrDirect,
                                              trace.HitNormal)
            eff:SetNormal(dir)
            if(data.NvDamage > 3500) then
              util.Effect("ManhackSparks", eff)
            else
              util.Effect("MetalSpark", eff)
            end
          else
            util.Effect("BloodImpact", eff)
          end
        end
      end
    end
  end
end

function ENT:DrawBeam(src, org, dir, sdat, idx)
  local trace, data = self:DoBeam(src, org, dir, sdat, idx)
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
    self:DrawEndingEffect(src, trace, data, sdat)
  end
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  self:InitSources()
  if(self:GetOn()) then
    self:DrawEffectBegin()
    self:UpdateSources()
    self:DivideSources()
    self:DrawEffectEnd()
  end
end