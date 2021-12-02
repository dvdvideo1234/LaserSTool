include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

local MXBMDAMG = LaserLib.GetData("MXBMDAMG")
local DRWBMSPD = LaserLib.GetData("DRWBMSPD")

--[[
 * This is actually faster than stuffing all the beams
 * information for every laser in a dedicated table and
 * draw the table elements one by one at once.
 * trace  > Trace data recieved from the beam
 * data   > Information parameters of the current beam
 * source > Entity that has laser related properties
]]
function ENT:DrawEndingEffect(trace, data, source)
  local sent = (source or self)
  if(trace and not trace.HitSky and
    sent:GetEndingEffect() and self.isEffect)
  then
    if(not self.beamEffect) then
      self.beamEffect = EffectData()
    end -- Allocate effect data class
    if(trace.Hit) then
      local ent = trace.Entity
      local eff = self.beamEffect
      if(not LaserLib.IsUnit(ent)) then
        eff:SetStart(trace.HitPos)
        eff:SetOrigin(trace.HitPos)
        eff:SetNormal(trace.HitNormal)
        util.Effect("AR2Impact", eff)
        -- Draw particle effects
        if(data.NvDamage > 0) then
          if(not (ent:IsPlayer() or ent:IsNPC())) then
            local mul = (data.NvDamage / MXBMDAMG:GetFloat())
            local dir = LaserLib.GetReflected(data.VrDirect,
                                              trace.HitNormal)
            eff:SetNormal(dir)
            eff:SetScale(0.5)
            eff:SetRadius(10 * mul)
            eff:SetMagnitude(3 * mul)
            util.Effect("Sparks", eff)
          else
            util.Effect("BloodImpact", eff)
          end
        end
      end
    end
  end
end

--[[
 * This traps the beam by following the trace
 * You can mark trace view points as visible
 * data   > Beam  information status structure
 * source > Entity that has laser related properties
]]
function ENT:DrawTrace(data, source)
  local sent = (source or self)
  local rgba = sent:GetBeamColorRGBA(true)
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
  local mat = sent:GetBeamMaterial(true)
  if(mat) then render.SetMaterial(mat) end
  local spd = DRWBMSPD:GetFloat()

  -- Draw the beam sequentially bing faster
  for idx = 2, data.TvPoints.Size do
    local org = data.TvPoints[idx - 1]
    local new = data.TvPoints[idx - 0]
    local otx, ntx, wdt = org[1], new[1], org[2]

    -- Make sure the coordinates are conveted to world ones
    LaserLib.UpdateRB(bbmin, ntx, math.min)
    LaserLib.UpdateRB(bbmax, ntx, math.max)

    if(org[5]) then
      local dtm, len = (spd * CurTime()), ntx:Distance(otx)
      render.DrawBeam(otx, ntx, wdt, dtm + len / 8, dtm, rgba)
    end -- Draw the actual beam texture
  end
  -- Adjust the render bounds with world-space coordinates
  self:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster
end

function ENT:DrawBeam()
  local trace, data = self:DoBeam()
  if(not data) then return end
  self:DrawTrace(data) -- Draws the beam trace
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(trace, data)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      self:UpdateFlags()
      self:DrawBeam()
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
