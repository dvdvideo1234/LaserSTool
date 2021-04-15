include("shared.lua")

language.Add("gmod_laser", "Laser")

killicon.Add("gmod_laser", "vgui/entities/gmod_laser_killicon", Color( 255, 255, 255, 255 ))

ENT.RenderGroup = RENDERGROUP_BOTH

local gsReflector = "models/madjawa/laser_reflector.mdl"
local varMaxBounces = GetConVar("laseremitter_maxbounces")

-- FIXME : find a better way to render the laser (Scripted Effect?)
function ENT:Draw()

  self:DrawModel()

  if(self:GetOn()) then
    local trace, isMirror = {}, false
    local beamStart = self:GetPos()
    local beamDir = self:GetBeamDirection()
    local beamLength = self:GetBeamLength()
    local beamFilter, bounces = self, 0
    local beamPoints = {beamStart}
    local maxbounces = varMaxBounces:GetInt()

    while(bounces < maxbounces) do
      if(StarGate) then
        trace = StarGate.Trace:New(beamStart, beamDir:GetNormalized() * beamLength, beamFilter)
      else
        trace = util.QuickTrace(beamStart, beamDir:GetNormalized() * beamLength, beamFilter)
      end

      table.insert(beamPoints, trace.HitPos)

      if(trace.Entity and
         trace.Entity:IsValid() and
         trace.Entity:GetModel() == gsReflector)
      then
        isMirror = true
        beamStart = trace.HitPos
        beamDir = LaserLib.GetReflectedVector(beamDir, trace.HitNormal)
        beamLength = beamLength - beamLength * trace.Fraction
        beamFilter = trace.Entity
        bounces = bounces + 1
      else
        isMirror = false
      end

      if(not isMirror) then break end
    end

    local beamWidth = self:GetBeamWidth()
    local prevPoint = self:GetPos()
    local bbmin = self:OBBMins()
    local bbmax = self:OBBMaxs()

    -- Material must not be caches so that can be updated with left click setup
    render.SetMaterial(Material(self:GetBeamMaterial()))

    for k, v in pairs(beamPoints) do
      if(prevPoint ~= v) then
        render.DrawBeam(prevPoint,
                        v,
                        beamWidth,
                        13 * CurTime(),
                        13 * CurTime() - (v - prevPoint):Length() / 9,
                        Color( 255, 255, 255, 255 ))
      end

      prevPoint = v

      if (v.x < bbmin.x) then bbmin.x = v.x end
      if (v.y < bbmin.y) then bbmin.y = v.y end
      if (v.z < bbmin.z) then bbmin.z = v.z end
      if (v.x > bbmax.x) then bbmax.x = v.x end
      if (v.y > bbmax.y) then bbmax.y = v.y end
      if (v.z > bbmax.z) then bbmax.z = v.z end
    end

    self.NextEffect = self.NextEffect or CurTime()
    if(not trace.HitSky and
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

    self:SetRenderBoundsWS( bbmin, bbmax )
  end

end
