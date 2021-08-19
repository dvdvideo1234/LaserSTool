include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

--[[
* This is actually faster than stuffing all the beams
* information for every laser in a dedicated table and
* draw the table elements one by one at once.
]]

function ENT:DrawEndingEffect(trace, data)
  if(trace and not trace.HitSky and
    self:GetEndingEffect() and self.drawEffect)
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

function ENT:DrawBeam(org, dir, length, width)
  local force  = self:GetPushForce()
  local origin = self:GetBeamOrigin(org)
  local damage = self:GetDamageAmount()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local direct = self:GetBeamDirection(dir)
  local noverm = self:GetNonOverMater()
  local trace, data = LaserLib.DoBeam(self,
                                      origin,
                                      direct,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm)
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
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      self:DrawEffectBegin()
      self:DrawBeam(nil, nil, length, width)
      self:DrawEffectEnd()
    end
  else
    local color = LaserLib.GetColor("YELLOW")
    local lndir = LaserLib.GetData("LNDIRACT"):GetFloat()
    local origin = self:GetBeamOrigin()
    local direct = self:GetBeamDirection()
          direct:Mul(lndir); direct:Add(origin)
    render.DrawLine(origin, direct, color)
  end
end
