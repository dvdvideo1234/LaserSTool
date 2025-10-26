include("shared.lua")

local cvLNDIRACT = LaserLib.GetData("LNDIRACT")
local gcLINDCOLR = LaserLib.GetColor("YELLOW")

--[[
 * This is actually faster than stuffing all the beams
 * information for every laser in a dedicated table and
 * draw the table elements one by one at once.
 * beam   > Information parameters of the current beam
 * source > Entity that has laser related properties
]]
function ENT:DrawEndingEffect(beam, source)
  local okent = LaserLib.IsValid(source)
  local usent = (okent and source or self)
  local endrw = usent:GetEndingEffect()
  beam:DrawEffect(usent, endrw)
end

--[[
 * This traps the beam by following the trace
 * You can mark trace view points as visible
 * beam   > Beam information status structure
 * source > Entity that has laser related properties
 * color  > Force color to starts draw with
]]
function ENT:DrawTrace(beam, source)
  local okent = LaserLib.IsValid(source)
  local usent = (okent and source or self)
  local imatr = usent:GetBeamMaterial(true)
  beam:Draw(usent, imatr)
end

function ENT:DrawBeam()
  local beam = self:DoBeam()
  if(not beam) then return end
  self:DrawTrace(beam) -- Draws the beam trace
  -- Handle drawing the effects when have to be drawn
  self:DrawEndingEffect(beam)
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
  if(self:GetOn()) then
    local width = self:GetBeamWidth()
          width = LaserLib.GetWidth(width)
    local length = self:GetBeamLength()
    if(width > 0 and length > 0) then
      self:UpdateInit()
      self:DrawBeam()
    else
      self:SetHitReportMax()
    end
  else
    local lndir = cvLNDIRACT:GetFloat()
    if(lndir > 0) then
      local origin = self:GetBeamOrigin()
      local direct = self:GetBeamDirection()
            direct:Mul(lndir); direct:Add(origin)
      render.DrawLine(origin, direct, gcLINDCOLR)
    end; self:SetHitReportMax()
  end
end

--[[
 * The think method is not needed in general
 * but it is defined empty because otherwise
 * the draw method will not get called when
 * the player is not looking at the entity
]]
function ENT:Think()
end
