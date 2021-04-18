include("shared.lua")

local gcBaseWhite = LaserLib.GetColor("WHITE")
local varMaxBounces = GetConVar("laseremitter_maxbounces")

ENT.RenderGroup = RENDERGROUP_BOTH

-- FIXME : Beam is not rendered whn hits the back of the player

function ENT:Draw()

 self:DrawModel()

  if(self:GetOn()) then
    local direct = self:GetBeamDirection()
    local origin = self:LocalToWorld(self:OBBCenter())
    local trace, data = LaserLib.DoBeam(self,
                                        origin,
                                        direct,
                                        self:GetBeamLength(),
                                        varMaxBounces:GetInt())
    if(trace) then
      local prev  = origin
      local width = self:GetBeamWidth()
      local bbmin = self:LocalToWorld(self:OBBMins())
      local bbmax = self:LocalToWorld(self:OBBMaxs())

      -- Material must not be cached so it can be updated with left click setup
      render.SetMaterial(Material(self:GetBeamMaterial()))

      for key, val in pairs(data.TvPoints) do

        -- Make sure the coordinates are conveted to world ones
        LaserLib.UpdateRB(bbmin, val, math.min)
        LaserLib.UpdateRB(bbmax, val, math.max)

        -- Draw the actual beam texture
        if(prev ~= val) then
          local dt = 13 * CurTime()
          render.DrawBeam(prev,
                          val,
                          width,
                          dt,
                          dt - (val - prev):Length() / 9,
                          gcBaseWhite)
        end; prev = val
      end

      -- Adjust the render bounds with local coordinates
      self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster

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
  end
end
