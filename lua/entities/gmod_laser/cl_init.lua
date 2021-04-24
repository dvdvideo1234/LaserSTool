include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

--[[
* This is actually faster than stuffing all the beams
* information for every laser in a dedicated table and
* draw the table elemeents one by one at once.
]]

function ENT:DrawEndingEffect(trace)
  self.nextEffect = self.nextEffect or CurTime()

  if(trace and not trace.HitSky and
     self:GetEndingEffect() and
     CurTime() >= self.nextEffect)
  then
    if(not self.beamEffect) then
      self.beamEffect = EffectData()
    end -- Allocate effect data class
    self.beamEffect:SetStart(trace.HitPos)
    self.beamEffect:SetOrigin(trace.HitPos)
    self.beamEffect:SetNormal(trace.HitNormal)
    self.beamEffect:SetScale(1)
    util.Effect("AR2Impact", self.beamEffect)
    self.nextEffect = CurTime() + 0.1
  end
end

function ENT:Draw()
  self:DrawModel()
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.ClampWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      local origin = self:GetBeamOrigin()
      local direct = self:GetBeamDirection()
      local usrfle = self:GetReflectionRate()
      local usrfre = self:GetRefractionRate()
      local trace, data = LaserLib.DoBeam(self,
                                          origin,
                                          direct,
                                          length,
                                          width,
                                          0, -- Damage is not used
                                          0, -- Force is not used
                                          usrfle,
                                          usrfre)
      if(trace) then
        local vprev = origin
        local white = LaserLib.GetColor("WHITE")
        local ushit = LocalPlayer():GetEyeTrace().HitPos
        local bbmin = self:LocalToWorld(self:OBBMins())
        local bbmax = self:LocalToWorld(self:OBBMaxs())

        -- Material must be cached and pdated with left click setup
        local mat = self:GetBeamMaterial(true)
        if(mat) then render.SetMaterial(mat) end

        for idx = 1, data.TvPoints.Size do
          local val = data.TvPoints[idx]
          local vtx, wid = val[1], val[2]

          -- Make sure the coordinates are conveted to world ones
          LaserLib.UpdateRB(bbmin, vtx, math.min)
          LaserLib.UpdateRB(bbmax, vtx, math.max)

          -- Draw the actual beam texture
          if(vprev ~= vtx) then
            local dtm = 13 * CurTime()
            local len = (vtx - vprev):Length()
            render.DrawBeam(vprev,
                            vtx,
                            wid,
                            dtm,
                            dtm - len / 9,
                            white)
          end; vprev = vtx
        end

        LaserLib.UpdateRB(bbmin, ushit, math.min)
        LaserLib.UpdateRB(bbmax, ushit, math.max)

        -- Adjust the render bounds with world-space coordinates
        self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster

        self:DrawEndingEffect(trace)
      end
    end
  end
end
