include("shared.lua")

local gcBaseWhite = Color(255, 255, 255, 255)
local gsReflector = "models/madjawa/laser_reflector.mdl"
local varMaxBounces = GetConVar("laseremitter_maxbounces")

language.Add("gmod_laser", "Laser")
killicon.Add("gmod_laser", "materials/vgui/entities/gmod_laser_killicon", gcBaseWhite)

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

    local width = self:GetBeamWidth()
    local prev  = self:GetPos()
    local bbmin = self:OBBMins()
    local bbmax = self:OBBMaxs()

    -- Material must not be caches so that can be updated with left click setup
    render.SetMaterial(Material(self:GetBeamMaterial()))

    for k, v in pairs(data.TvPoints) do
      local conv = self:WorldToLocal(v)

      if(prev ~= v) then
        local dt = 13 * CurTime()
        render.DrawBeam(prev,
                        v,
                        width,
                        dt,
                        dt - (v - prev):Length() / 9,
                        gcBaseWhite)
      end; prev = v
      
      -- Make sure the coordinates are conveted to local ones
      if(conv.x < bbmin.x) then bbmin.x = conv.x end
      if(conv.y < bbmin.y) then bbmin.y = conv.y end
      if(conv.z < bbmin.z) then bbmin.z = conv.z end
      if(conv.x > bbmax.x) then bbmax.x = conv.x end
      if(conv.y > bbmax.y) then bbmax.y = conv.y end
      if(conv.z > bbmax.z) then bbmax.z = conv.z end
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
    self:SetRenderBounds(bbmin, bbmax)
  end
end
