include("shared.lua")

local gcBaseWhite = LaserLib.GetColor("WHITE")
local varMaxBounces = GetConVar("laseremitter_maxbounces")

ENT.RenderGroup = RENDERGROUP_BOTH

-- FIXME : find a better way to render the laser (Scripted Effect?)
function ENT:Draw()

 self:DrawModel()

  if(self:GetOn()) then
    local trace, data = LaserLib.DoBeam(self,
                                        self:GetPos(),
                                        self:GetBeamDirection(),
                                        self:GetBeamLength(),
                                        varMaxBounces:GetInt())
    if(trace) then
      local prev  = self:GetPos()
      local width = self:GetBeamWidth()
      local bbmin = self:LocalToWorld(self:OBBMins())
      local bbmax = self:LocalToWorld(self:OBBMaxs())

      -- Material must not be caches so that can be updated with left click setup
      render.SetMaterial(Material(self:GetBeamMaterial()))

      for key, val in pairs(data.TvPoints) do
        if(prev ~= val) then
          local dt = 13 * CurTime()
          render.DrawBeam(prev,
                          val,
                          width,
                          dt,
                          dt - (val - prev):Length() / 9,
                          gcBaseWhite)
        end; prev = val

        -- Make sure the coordinates are conveted to local ones
        if(val.x < bbmin.x) then bbmin.x = val.x end
        if(val.y < bbmin.y) then bbmin.y = val.y end
        if(val.z < bbmin.z) then bbmin.z = val.z end
        if(val.x > bbmax.x) then bbmax.x = val.x end
        if(val.y > bbmax.y) then bbmax.y = val.y end
        if(val.z > bbmax.z) then bbmax.z = val.z end
      end

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

      -- Adjust the render bounds with local coordinates
      self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster
    end
  end
end
