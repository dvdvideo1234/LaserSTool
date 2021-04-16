--[[
Hey you! You are reading my code!
I want to say that my code is far from perfect, and if you see that I'm doing something
in a really wrong/dumb way, please give me advices instead of saying "LOL U BAD CODER"
        Thanks
      - MadJawa
]]
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

resource.AddSingleFile("materials/vgui/entities/gmod_laser_reflector.vmt")
resource.AddSingleFile("materials/vgui/entities/gmod_laser_reflector.vtf")

resource.AddSingleFile("models/madjawa/laser_reflector.mdl")
resource.AddSingleFile("models/madjawa/laser_reflector.phy")
resource.AddSingleFile("models/madjawa/laser_reflector.vvd")
resource.AddSingleFile("models/madjawa/laser_reflector.sw.vtx")
resource.AddSingleFile("models/madjawa/laser_reflector.dx80.vtx")
resource.AddSingleFile("models/madjawa/laser_reflector.dx90.vtx")

include("shared.lua")

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  -- Sets the right angle at spawn. Thanks to aVoN!
  local yaw = (ply:GetAimVector():Angle().y + 180) % 360
  local pos = tr.HitPos + tr.HitNormal * 35
  local ent = ents.Create("prop_physics")
  ent:SetModel("models/madjawa/laser_reflector.mdl")
  ent:SetPos(pos)
  ent:Spawn()
  ent:Activate()
  ent:SetAngles(Angle(0, yaw, 0))
  return ent
end
