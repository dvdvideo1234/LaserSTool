--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  -- Sets the right angle at spawn. Thanks to aVoN!
  local yaw = (ply:GetAimVector():Angle().y + 180) % 360
  local pos = tr.HitPos + tr.HitNormal * 35
  local ent = ents.Create(LaserLib.GetClass(3, 2))
  ent:SetModel(LaserLib.GetModel(3, 1))
  ent:SetMaterial(LaserLib.GetMaterial(3, 1))
  ent:SetPos(pos)
  ent:Spawn()
  ent:Activate()
  ent:SetAngles(Angle(0, yaw, 0))
  return ent
end
