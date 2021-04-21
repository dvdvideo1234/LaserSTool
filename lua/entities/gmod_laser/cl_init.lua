include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

-- TODO : Beam is not rendered wehn hits the back of the player

function ENT:DrawEndingEffect(trace)
  self.NextEffect = self.NextEffect or CurTime()

  if(trace and not trace.HitSky and
     self:GetEndingEffect() and
     CurTime() >= self.NextEffect)
  then
    if(not self.DataEffect) then
      self.DataEffect = EffectData()
    end -- Allocate effect data class
    self.DataEffect:SetStart(trace.HitPos)
    self.DataEffect:SetOrigin(trace.HitPos)
    self.DataEffect:SetNormal(trace.HitNormal)
    self.DataEffect:SetScale(1)
    util.Effect("AR2Impact", self.DataEffect)
    self.NextEffect = CurTime() + 0.1
  end
end

function ENT:Draw()

  self:DrawModel()

  if(self:GetOn()) then
    local white  = LaserLib.GetColor("WHITE")
    local width  = self:GetBeamWidth()
    local length = self:GetBeamLength()
    local origin = self:GetBeamOrigin()
    local direct = self:GetBeamDirection()
    local userfe = self:GetReflectionRate()
    local trace, data = LaserLib.DoBeam(self,
                                        origin,
                                        direct,
                                        length,
                                        width,
                                        0, -- Damage is not used
                                        userfe)
    if(trace) then
      local prev  = origin
      local bbmin = self:LocalToWorld(self:OBBMins())
      local bbmax = self:LocalToWorld(self:OBBMaxs())

      -- Material must not be cached. Updated with left click setup
      render.SetMaterial(Material(self:GetBeamMaterial()))

      for idx = 1, data.TvPoints.Size do
        local val = data.TvPoints[idx]
        local vtx, wid = val[1], val[2]

        -- Make sure the coordinates are conveted to world ones
        LaserLib.UpdateRB(bbmin, vtx, math.min)
        LaserLib.UpdateRB(bbmax, vtx, math.max)

        -- Draw the actual beam texture
        if(prev ~= vtx) then
          local dtm = 13 * CurTime()
          local len = (vtx - prev):Length()
          render.DrawBeam(prev,
                          vtx,
                          wid,
                          dtm,
                          dtm - len / 9,
                          white)
        end; prev = vtx
      end

      -- Adjust the render bounds with local coordinates
      self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster

      self:DrawEndingEffect(trace)
    end
  end
end
