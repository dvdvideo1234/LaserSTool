include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

--[[
 * This is actually faster than stuffing all the beams
 * information for every laser in a dedicated table and
 * draw the table elements one by one at once.
 * trace  > Trace data recieved from the beam
 * data   > Information parameters of the current beam
 * source > Entity that has laser related properties
]]
function ENT:DrawEndingEffect(trace, data, source)
  local okent = LaserLib.IsValid(source)
  local usent = (okent and source or self)
  local endrw = usent:GetEndingEffect()
  data:DrawEffect(usent, trace, endrw)
end

--[[
 * This traps the beam by following the trace
 * You can mark trace view points as visible
 * data   > Beam  information status structure
 * source > Entity that has laser related properties
]]
function ENT:DrawTrace(data, source)
  local okent = LaserLib.IsValid(source)
  local usent = (okent and source or self)
  local corgb = usent:GetBeamColorRGBA(true)
  local imatr = usent:GetBeamMaterial(true)
  data:Draw(usent, imatr, corgb)
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
