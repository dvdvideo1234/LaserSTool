include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

--[[
 * This is actually faster than stuffing all the beams
 * information for every laser in a dedicated table and
 * draw the table elements one by one at once.
 * trace  > Trace result recieved from the beam
 * beam   > Information parameters of the current beam
 * source > Entity that has laser related properties
]]
function ENT:DrawEndingEffect(beam, trace, source)
  local okent = LaserLib.IsValid(source)
  local usent = (okent and source or self)
  local endrw = usent:GetEndingEffect()
  beam:DrawEffect(usent, trace, endrw)
end

--[[
 * This traps the beam by following the trace
 * You can mark trace view points as visible
 * beam   > Beam information status structure
 * source > Entity that has laser related properties
 * color  > Force color to starts draw with
]]
function ENT:DrawTrace(beam, source, color)
  local okent = LaserLib.IsValid(source)
  local usent = (okent and source or self)
  local corgb = usent:GetBeamColorRGBA(true)
  local imatr = usent:GetBeamMaterial(true)
  beam:Draw(usent, imatr, color or corgb)
end

function ENT:DrawBeam()
  local beam, trace = self:DoBeam()
  if(not beam) then return end
  self:DrawTrace(beam) -- Draws the beam trace
  -- Handle drawing the effects when have to be drawwn
  self:DrawEndingEffect(beam, trace)
end

function ENT:DrawBeamOn()
  local width = self:GetBeamWidth()
        width = LaserLib.GetWidth(width)
  local length = self:GetBeamLength()
  if(width > 0 and length > 0) then
    self:UpdateFlags()
    self:DrawBeam()
  end
end

function ENT:DrawBeamOff()
  local color = LaserLib.GetColor("YELLOW")
  local lndir = LaserLib.GetData("LNDIRACT"):GetFloat()
  local origin = self:GetBeamOrigin()
  local direct = self:GetBeamDirection()
        direct:Mul(lndir); direct:Add(origin)
  render.DrawLine(origin, direct, color)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)

  if(self:GetOn()) then
    self:DrawBeamOn()
  else
    self:DrawBeamOff()
  end
end
