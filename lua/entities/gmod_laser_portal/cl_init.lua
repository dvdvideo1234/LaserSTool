include("shared.lua")

function ENT:Initialize()
end

function ENT:Think()
end

local DRFONT = "Trebuchet24"
local BLACK  = LaserLib.GetColor("BLACK")
local BACKGR = LaserLib.GetColor("BACKGR")
local FOREGR = LaserLib.GetColor("FOREGR")

function ENT:DrawOverlay(rnd, wdt, hgh, mrg, col)
  local m = math.floor(mrg)
  local w, h = wdt + 2 * m, hgh + 2 * m
  local x, y = -(wdt / 2) - m, -(hgh / 2) - m
  draw.RoundedBox(rnd, x, y, w, h, col)
end

function ENT:DrawTransfer(ang)
  surface.SetFont(DRFONT)
  local obb = self:LocalToWorld(self:OBBCenter())
  local mul = self:BoundingRadius() * 0.9
  local pos = Vector(0,0,1); pos:Mul(mul); pos:Add(obb)
  local txt = self:GetOverlayTransfer()
  local fit, mrg = self:IsTrueExit(), 5
  local r, w, h = 8, surface.GetTextSize(txt)

  cam.Start3D2D(pos, ang, 0.16)
    self:DrawOverlay(r, w, h, mrg, BACKGR)
    if(fit) then self:DrawOverlay(r, w, h, mrg / 2, FOREGR) end
    draw.SimpleText(txt,DRFONT,0,-2,BLACK,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  cam.End3D2D()
end

function ENT:Draw()
  self:DrawModel()

  if(self:GetDrawTransfer()) then
    local ply = LocalPlayer()
    local ang = ply:EyeAngles()
    if(ply:InVehicle()) then
      ang = ply:GetVehicle():LocalToWorldAngles(ang)
    end
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 180)
    self:DrawTransfer(ang)
  end
end
