include("shared.lua")

local gcBG = LaserLib.GetColor("BACKGR")
local gsNA = LaserLib.GetData("NOAV")

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:GetExitTextID(idx)
  local idx = (tonumber(idx) or 0)
  return ((idx ~= 0) and tostring(idx) or gsNA)
end

function ENT:Draw()
  self:DrawModel()
  local ply = LocalPlayer()
  local ent = ply:GetEyeTrace().Entity
  if(self == ent) then
    local cen = self:LocalToWorld(self:OBBCenter())
    local dst = self:BoundingRadius() / 2
    local bas = self:GetExitTextID(self:EntIndex())
    local txt = self:GetExitTextID(self:GetEntityExitID())
    local pos = Vector(0,0,dst); pos:Add(cen)
    local nam = ("["..bas.."] > ["..txt.."]")
    AddWorldTip(self:EntIndex(), nam, 0.5, pos)
  end
end


