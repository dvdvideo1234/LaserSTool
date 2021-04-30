include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

--[[
* This is actually faster than stuffing all the beams
* information for every laser in a dedicated table and
* draw the table elemeents one by one at once.
]]

function ENT:DrawEndingEffect(trace, data)
  self.nextEffect = self.nextEffect or CurTime()

  if(trace and not trace.HitSky and
     self:GetEndingEffect() and
     CurTime() >= self.nextEffect)
  then
    if(not self.beamEffectData) then
      self.beamEffectData = EffectData()
    end -- Allocate effect data class
    if(trace.Hit) then
      local ent = trace.Entity
      local eff = self.beamEffectData
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
    self.nextEffect = CurTime() + 0.1
  end
end

function ENT:Draw()
  self:DrawModel()
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      local force  = self:GetPushForce()
      local origin = self:GetBeamOrigin()
      local damage = self:GetDamageAmount()
      local direct = self:GetBeamDirection()
      local usrfle = self:GetReflectRatio()
      local usrfre = self:GetRefractRatio()
      local trace, data = LaserLib.DoBeam(self,
                                          origin,
                                          direct,
                                          length,
                                          width,
                                          damage,
                                          force,
                                          usrfle,
                                          usrfre)
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
          local otx, ntx, nwd = org[1], new[1], new[2]

          -- Make sure the coordinates are conveted to world ones
          LaserLib.UpdateRB(bbmin, ntx, math.min)
          LaserLib.UpdateRB(bbmax, ntx, math.max)

          -- Draw the actual beam texture
          local dtm = 13 * CurTime()
          local len = (ntx - otx):Length()
          render.DrawBeam(otx,
                          ntx,
                          nwd,
                          dtm,
                          dtm - len / 9,
                          color:ToColor())
        end
        -- Adjust the render bounds with world-space coordinates
        self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster
        -- Handle drawing the effects when have to be drawwn
        self:DrawEndingEffect(trace, data)
      end
    end
  end
end
