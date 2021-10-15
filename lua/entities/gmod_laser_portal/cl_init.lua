include("shared.lua")

function ENT:Initialize()
end

function ENT:Think()
end

local DRFONT = "Trebuchet24"
local BLACK  = LaserLib.GetColor("BLACK")
local BACKGR = LaserLib.GetColor("BACKGR")
local FOREGR = LaserLib.GetColor("FOREGR")

function ENT:DrawTransfer(ang, rot)
  local up, mrg = self:GetUp(), 6
  local mul = self:BoundingRadius()
  local pos = self:GetPos() + mul * up
  local txt = self:GetOverlayTransfer()
  local out = self:GetCorrectExit()

  if(rot) then
    ang:RotateAroundAxis(up, 180);
  end

  cam.Start3D2D(pos, ang, 0.16);
    surface.SetFont(DRFONT)
    local w, h = surface.GetTextSize(txt)
    draw.RoundedBox(8, -(w/2)-mrg, -(h/2)-mrg/1.5, w+2*mrg, h+2*mrg, BACKGR)
    if(out) then local mrg = mrg / 2
      draw.RoundedBox(8, -(w/2)-mrg, -(h/2)-mrg/2, w+2*mrg, h+2*mrg, FOREGR)
    end
    draw.SimpleText(txt,DRFONT,0,0,BLACK,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  cam.End3D2D();
end

function ENT:Draw()
  self:DrawModel()

  if(self:GetDrawTransfer()) then
    local fwd = self:GetNormalLocal()
    local ang = self:GetAngles()
    local pos = self:GetPos()
    fwd:Rotate(ang)
    ang:RotateAroundAxis(ang:Up(), 90);
    ang:RotateAroundAxis(ang:Forward(), 90);
    local dir = LocalPlayer():EyePos(); dir:Sub(pos)
    local rot = (fwd:Dot(dir) < 0)

    self:DrawTransfer(ang, rot)
  end
end
