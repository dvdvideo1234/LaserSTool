AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_unit.vmt")

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local prefix       = LaserLib.GetData("TOOL").."_"
  local angspawn     = LaserLib.GetAngleSF(ply)
  local amax         = LaserLib.GetData("AMAX")
  local colorr       = math.Clamp(ply:GetInfoNum(prefix.."colorr", 0), 0 , 255)
  local colorg       = math.Clamp(ply:GetInfoNum(prefix.."colorg", 0), 0 , 255)
  local colorb       = math.Clamp(ply:GetInfoNum(prefix.."colorb", 0), 0 , 255)
  local colora       = math.Clamp(ply:GetInfoNum(prefix.."colora", 0), 0 , 255)
  local width        = math.Clamp(ply:GetInfoNum(prefix.."width", 0), 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  local length       = math.Clamp(ply:GetInfoNum(prefix.."length", 0), 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  local damage       = math.Clamp(ply:GetInfoNum(prefix.."damage", 0), 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  local pushforce    = math.Clamp(ply:GetInfoNum(prefix.."pushforce", 0), 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  local angle        = math.Clamp(ply:GetInfoNum(prefix.."angle", 0), amax[1], amax[2])
  local org, dir     = ply:GetInfo(prefix.."origin"), ply:GetInfo(prefix.."direct")
  local trandata     = LaserLib.SetupTransform({angle, org, dir})
  local raycolor     = Color(colorr, colorg, colorb, colora)
  local key          = ply:GetInfoNum(prefix.."key", 0)
  local model        = ply:GetInfo(prefix.."model")
  local material     = ply:GetInfo(prefix.."material")
  local stopsound    = ply:GetInfo(prefix.."stopsound")
  local killsound    = ply:GetInfo(prefix.."killsound")
  local startsound   = ply:GetInfo(prefix.."startsound")
  local dissolvetype = ply:GetInfo(prefix.."dissolvetype")
  local toggle       = (ply:GetInfoNum(prefix.."toggle", 0) ~= 0)
  local frozen       = (ply:GetInfoNum(prefix.."frozen", 0) ~= 0)
  local starton      = (ply:GetInfoNum(prefix.."starton", 0) ~= 0)
  local reflectrate  = (ply:GetInfoNum(prefix.."reflectrate", 0) ~= 0)
  local refractrate  = (ply:GetInfoNum(prefix.."refractrate", 0) ~= 0)
  local endingeffect = (ply:GetInfoNum(prefix.."endingeffect", 0) ~= 0)
  local forcecenter  = (ply:GetInfoNum(prefix.."forcecenter", 0) ~= 0)
  local enovermater  = (ply:GetInfoNum(prefix.."enonvermater", 0) ~= 0)
  local laser        = LaserLib.New(ply        , tr.HitPos   , angspawn    , model       ,
                                    trandata   , key         , width       , length      ,
                                    damage     , material    , dissolvetype, startsound  ,
                                    stopsound  , killsound   , toggle      , starton     ,
                                    pushforce  , endingeffect, reflectrate , refractrate ,
                                    forcecenter, frozen      , enovermater , raycolor)
  if(LaserLib.IsValid(laser)) then
    LaserLib.SetProperties(laser, "metal")
    LaserLib.ApplySpawn(laser, tr, trandata)
    return laser
  end; return nil
end
