LaserLib = LaserLib or {} -- Initialize the global variable of the library

local DATA = {}

-- Server controlled flags for console variables
DATA.FGSRVCN = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)
-- Independently controlled flags for console variables
DATA.FGINDCN = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

-- Library internal variables for limits and realtime tweaks
DATA.MXSPLTBC = CreateConVar("laseremitter_maxspltbc", 16, DATA.FGSRVCN, "Maximum splitter output laser beams count", 0, 32)
DATA.MXBMWIDT = CreateConVar("laseremitter_maxbmwidt", 30, DATA.FGSRVCN, "Maximum beam width for all laser beams", 0, 100)
DATA.MXBMDAMG = CreateConVar("laseremitter_maxbmdamg", 5000, DATA.FGSRVCN, "Maximum beam damage for all laser beams", 0, 10000)
DATA.MXBMFORC = CreateConVar("laseremitter_maxbmforc", 25000, DATA.FGSRVCN, "Maximum beam force for all laser beams", 0, 50000)
DATA.MXBMLENG = CreateConVar("laseremitter_maxbmleng", 25000, DATA.FGSRVCN, "Maximum beam length for all laser beams", 0, 50000)
DATA.MBOUNCES = CreateConVar("laseremitter_maxbounces", 10, DATA.FGSRVCN, "Maximum surface bounces for the laser beam", 0, 1000)
DATA.MCRYSTAL = CreateConVar("laseremitter_mcrystal", "models/props_c17/pottery02a.mdl", DATA.FGSRVCN, "Controls the crystal model")
DATA.MREFLECT = CreateConVar("laseremitter_mreflect", "models/madjawa/laser_reflector.mdl", DATA.FGSRVCN, "Controls the reflector model")
DATA.MSPLITER = CreateConVar("laseremitter_mspliter", "models/props_c17/pottery04a.mdl", DATA.FGSRVCN, "Controls the splitter model")
DATA.MDIVIDER = CreateConVar("laseremitter_mdivider", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the divider model")
DATA.MSENSOR  = CreateConVar("laseremitter_msensor" , "models/props_c17/pottery01a.mdl", DATA.FGSRVCN, "Controls the sensor model")
DATA.MDIMMER  = CreateConVar("laseremitter_mdimmer" , "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the dimmer model")
DATA.MPORTAL  = CreateConVar("laseremitter_mportal" , "models/props_c17/Frame002a.mdl", DATA.FGSRVCN, "Controls the portal model")
DATA.MSPLITRM = CreateConVar("laseremitter_msplitrm", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the splitter multy model")
DATA.MPARALEL = CreateConVar("laseremitter_mparalel", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the paralleller multy model")
DATA.NSPLITER = CreateConVar("laseremitter_nspliter", 2, DATA.FGSRVCN, "Controls the default splitter outputs count", 0, 16)
DATA.XSPLITER = CreateConVar("laseremitter_xspliter", 1, DATA.FGSRVCN, "Controls the default splitter X direction", 0, 1)
DATA.YSPLITER = CreateConVar("laseremitter_yspliter", 1, DATA.FGSRVCN, "Controls the default splitter Y direction", 0, 1)
DATA.EFFECTDT = CreateConVar("laseremitter_effectdt", 0.15, DATA.FGINDCN, "Controls the time between effect drawing", 0, 5)
DATA.ENSOUNDS = CreateConVar("laseremitter_ensounds", 1, DATA.FGSRVCN, "Trigger this to enable or disable redirector sounds")
DATA.LNDIRACT = CreateConVar("laseremitter_lndiract", 20, DATA.FGINDCN, "How long will the direction of output beams be rendered", 0, 50)
DATA.DAMAGEDT = CreateConVar("laseremitter_damagedt", 0.1, DATA.FGSRVCN, "The time frame to pass between the beam damage cycles", 0, 10)
DATA.DRWBMSPD = CreateConVar("laseremitter_drwbmspd", 8, DATA.FGINDCN, "The speed used to render the beam in the main routine", 0, 16)

DATA.GRAT = 1.61803398875   -- Golden ratio used for panels
DATA.TOOL = "laseremitter"  -- Tool name for internal use
DATA.ICON = "icon16/%s.png" -- Format to convert icons
DATA.NOAV = "N/A"           -- Not available as string
DATA.CATG = "Laser"         -- Category name in the entities tab
DATA.TOLD = SysTime()       -- Reduce debug function calls
DATA.RNDB = 3               -- Decimals beam round for visibility check
DATA.KWID = 5               -- Width coefficient used to calculate power
DATA.CLMX = 255             -- Maximum value for valid coloring
DATA.CTOL = 0.01            -- Color vectors and alpha comparison tolerance
DATA.NUGE = 0.1             -- Nuge amount for vectors to continue tracing
DATA.MINW = 0.05            -- Mininum width to be considered visible
DATA.DOTM = 0.01            -- Colinearity and dot prodic margin check
DATA.POWL = 0.001           -- Lowest bounds of laser power
DATA.ERAD = 1.12            -- Entity refract coefficient for back trace origins
DATA.TRWD = 0.33            -- Beam backtrace trace width when refracting
DATA.WLMR = 10000           -- World vectors to be correctly conveted to local
DATA.NTIF = {}              -- User notification configuration type
DATA.FMVA = "%f,%f,%f"      -- Utilized to print vector in proper manner
DATA.AMAX = {-360, 360}     -- Genral angular limis for having min/max
DATA.TIME = {Size = 1, Done = false, Suma = 0} -- Used for testing perposes
DATA.TRDG = (DATA.TRWD * math.sqrt(3)) / 2 -- Trace hitnormal displatement
DATA.NTIF[1] = "GAMEMODE:AddNotify(\"%s\", NOTIFY_%s, 6)"
DATA.NTIF[2] = "surface.PlaySound(\"ambient/water/drip%d.wav\")"

-- Store zero angle and vector
DATA.AZERO = Angle()
DATA.VZERO = Vector()
DATA.VDFWD = Vector(1, 0, 0)
DATA.VDRGH = Vector(0,-1, 0) -- Positive direction is to the left
DATA.VDRUP = Vector(0, 0, 1)
DATA.TCUST = {
  "Forward", "Right", "Up",
  H = {ID = 0, M = 0, V = 0},
  L = {ID = 0, M = 0, V = 0}
}

-- The default key in a collection point to take when not found
DATA.KEYD = "#"
-- The all key in a collection point to return the all in set
DATA.KEYA = "*"

DATA.CLS = {
  -- Classes existing in the hash part have their own beam handling
  -- Class hashes and flags that are checked by `IsUnit` function
  -- Class hashes are enabled for creating hit reports via `SetHitReport`
  -- [1] Can the entity be considered and actual beam source
  -- [2] Does the entity have the inherited editable laser properties
  ["gmod_laser"          ] = {true , true },
  ["gmod_laser_crystal"  ] = {true , true },
  ["gmod_laser_splitter" ] = {true , true },
  ["gmod_laser_divider"  ] = {true , false},
  ["gmod_laser_sensor"   ] = {false, false},
  ["gmod_laser_splitterm"] = {true , false},
  -- [1] Actual class passed to ents.Create
  -- [2] Extension for folder name indices
  -- [3] Extension for variable name indices
  {"gmod_laser"          , nil        , nil      }, -- Laser entity calss `PriarySource`
  {"gmod_laser_crystal"  , "crystal"  , nil      }, -- Laser crystal class `ActionSource`
  {"prop_physics"        , "reflector", "reflect"}, -- Laser reflectors class `DoBeam`
  {"gmod_laser_splitter" , "splitter" , "spliter"}, -- Laser beam splitter `ActionSource`
  {"gmod_laser_divider"  , "divider"  , nil      }, -- Laser beam divider `ActionSource`
  {"gmod_laser_sensor"   , "sensor"   , nil      }, -- Laser beam sensor `ActionSource`
  {"gmod_laser_dimmer"   , "dimmer"   , nil      }, -- Laser beam divide `ActionSource`
  {"gmod_laser_splitterm", "splitterm", "splitrm"}, -- Laser beam splitter multy `ActionSource`
  {"gmod_laser_portal"   , "portal"   , nil      }, -- Laser beam portal  `DoBeam`
  {"gmod_laser_parallel" , "parallel" , "paralel"}  -- Laser beam parallel `ActionSource`
}

DATA.MOD = { -- Model used by the entities menu
  "", -- Laser model is changed via laser tool. Variable is not needed.
  DATA.MCRYSTAL:GetString(), -- Portal cube: models/props/reflection_cube.mdl
  DATA.MREFLECT:GetString(),
  DATA.MSPLITER:GetString(),
  DATA.MDIVIDER:GetString(),
  DATA.MSENSOR:GetString() , -- Portal catcher: models/props/laser_catcher_center.mdl
  DATA.MDIMMER:GetString() ,
  DATA.MSPLITRM:GetString(),
  DATA.MPORTAL:GetString() , -- Portal: Well... Portals being entities
  DATA.MPARALEL:GetString()
}

DATA.MAT = {
  "", -- Laser material is changed with the model
  "models/dog/eyeglass"    ,
  "debug/env_cubemap_model",
  "models/dog/eyeglass"    ,
  "models/dog/eyeglass"    ,
  "models/props_combine/citadel_cable",
  "models/dog/eyeglass"    ,
  "models/dog/eyeglass"    ,
  "models/props_combine/com_shield001a",
  "models/dog/eyeglass"
}

DATA.COLOR = {
  [DATA.KEYD] = "BLACK",
  ["BLACK"]   = Color( 0 ,  0 ,  0 , 255),
  ["RED"]     = Color(255,  0 ,  0 , 255),
  ["GREEN"]   = Color( 0 , 255,  0 , 255),
  ["BLUE"]    = Color( 0 ,  0 , 255, 255),
  ["YELLOW"]  = Color(255, 255,  0 , 255),
  ["MAGENTA"] = Color(255,  0 , 255, 255),
  ["CYAN"]    = Color( 0 , 255, 255, 255),
  ["WHITE"]   = Color(255, 255, 255, 255),
  ["BACKGR"]  = Color(150, 150, 255, 190),
  ["FOREGR"]  = Color(150, 255, 150, 240)
}

DATA.DISTYPE = {
  [DATA.KEYD]   = "core",
  ["energy"]    = 0,
  ["heavyelec"] = 1,
  ["lightelec"] = 2,
  ["core"]      = 3
}

DATA.REFLECT = { -- Reflection data descriptor
  [1] = "cubemap", -- Cube maps textures
  [2] = "chrome" , -- Chrome stuff reflect
  [3] = "shiny"  , -- All shiny stuff reflect
  [4] = "metal"  , -- All shiny metal reflect
  [5] = "white"  , -- All general white paint
  -- Used for prop updates and checks
  [DATA.KEYD]                            = "debug/env_cubemap_model",
  -- User for general class control
  [""]                                   = false, -- Disable empty materials
  ["shiny"]                              = {0.854},
  ["metal"]                              = {0.045},
  ["white"]                              = {0.342},
  ["chrome"]                             = {0.955},
  ["cubemap"]                            = {0.999},
  -- Materials that are overriden and directly hash searched
  ["models/shiny"]                       = {0.873},
  ["wtp/chrome_1"]                       = {0.955},
  ["wtp/chrome_2"]                       = {0.955},
  ["wtp/chrome_3"]                       = {0.955},
  ["wtp/chrome_4"]                       = {0.955},
  ["wtp/chrome_5"]                       = {0.955},
  ["wtp/chrome_6"]                       = {0.955},
  ["wtp/chrome_7"]                       = {0.955},
  ["phoenix_storms/window"]              = {0.897},
  ["bobsters_trains/chrome"]             = {0.955},
  ["debug/env_cubemap_model"]            = {1.000}, -- There is no perfect mirror
  ["models/materials/chchrome"]          = {0.864},
  ["phoenix_storms/grey_chrome"]         = {0.757},
  ["phoenix_storms/fender_white"]        = {0.625},
  ["sprops/textures/sprops_chrome"]      = {0.757},
  ["sprops/textures/sprops_chrome2"]     = {0.657},
  ["phoenix_storms/pack2/bluelight"]     = {0.734},
  ["sprops/trans/wheels/wheel_d_rim1"]   = {0.943},
  ["bobsters_trains/chrome_dirty_black"] = {0.537}
}; DATA.REFLECT.Size = #DATA.REFLECT

DATA.REFRACT = { -- https://en.wikipedia.org/wiki/List_of_refractive_indices
  [1] = "air"  , -- Air enumerator index
  [2] = "glass", -- Glass enumerator index
  [3] = "water", -- Water enumerator index
  -- Used for prop updates and chec
  [DATA.KEYD]                                   = "models/props_combine/health_charger_glass",
  -- User for general class control
  -- [1] : Medium refraction index for the material specified
  -- [2] : Medium refraction rating when the beam goes trough reduces its power
  [""]                                          = false, -- Disable empty materials
  ["air"]                                       = {1.000, 1.000}, -- Air refraction index
  ["glass"]                                     = {1.521, 0.999}, -- Ordinary glass
  ["water"]                                     = {1.333, 0.955}, -- Water refraction index
  -- Materials that are overriden and directly hash searched
  ["models/spawn_effect"]                       = {1.153, 0.954}, -- Closer to air (pixelated)
  ["models/dog/eyeglass"]                       = {1.612, 0.955}, -- Non pure glass 2
  ["phoenix_storms/glass"]                      = {1.521, 0.999}, -- Ordinary glass
  ["models/shadertest/shader3"]                 = {1.333, 0.832}, -- Water refraction index
  ["models/shadertest/shader4"]                 = {1.385, 0.922}, -- Water with some impurites
  ["models/shadertest/predator"]                = {1.333, 0.721}, -- Water refraction index
  ["phoenix_storms/pack2/glass"]                = {1.521, 0.999}, -- Ordinary glass
  ["models/effects/vol_light001"]               = {1.000, 1.000}, -- Transperent air
  ["models/props_c17/fisheyelens"]              = {1.521, 0.999}, -- Ordinary glass
  ["models/effects/comball_glow2"]              = {1.536, 0.924}, -- Glass with some impurites
  ["models/airboat/airboat_blur02"]             = {1.647, 0.955}, -- Non pure glass 1
  ["models/props_lab/xencrystal_sheet"]         = {1.555, 0.784}, -- Amber refraction index
  ["models/props_combine/com_shield001a"]       = {1.573, 0.653}, -- Dycamically changing slass
  ["models/props_combine/combine_fenceglow"]    = {1.638, 0.924}, -- Glass with decent impurites
  ["models/props_c17/frostedglass_01a_dx60"]    = {1.521, 0.853}, -- White glass
  ["models/props_combine/health_charger_glass"] = {1.552, 1.000}, -- Resembles glass
  ["models/props_combine/combine_door01_glass"] = {1.583, 0.341}, -- Bit darker glass
  ["models/props_combine/pipes03"]              = {1.583, 0.761}, -- Bit darker glass
  ["models/props_combine/citadel_cable"]        = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/citadel_cable_b"]      = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/pipes01"]              = {1.583, 0.911}, -- Dark glass other
  ["models/props_combine/pipes03"]              = {1.583, 0.911}, -- Dark glass other
  ["models/props_combine/stasisshield_sheet"]   = {1.511, 0.427}  -- Blue temper glass
}; DATA.REFRACT.Size = #DATA.REFRACT

DATA.MATYPE = {
  [MAT_SNOW       ] = "white",
  [MAT_GRATE      ] = "metal",
  [MAT_CLIP       ] = "metal",
  [MAT_METAL      ] = "metal",
  [MAT_VENT       ] = "metal",
  [MAT_GLASS      ] = "glass",
  [MAT_WARPSHIELD ] = "glass"
}

DATA.TRACE = {
  start          = Vector(),
  endpos         = Vector(),
  filter         = nil,
  mask           = MASK_SOLID,
  collisiongroup = COLLISION_GROUP_NONE,
  ignoreworld    = false,
  mins           = Vector(),
  maxs           = Vector(),
  output         = nil
}

-- Callbacks for console variables
for idx = 2, #DATA.CLS do
  local vset = DATA.CLS[idx]
  local vidx = (vset[3] or vset[2])
  local varo = DATA["M"..vidx:upper()]
  local varn = varo:GetName()

  cvars.RemoveChangeCallback(varn, varn)
  cvars.AddChangeCallback(varn,
    function(name, o, n)
      local m = tostring(n):Trim()
      if(m:sub(1,1) == DATA.KEYD) then
        DATA.MOD[idx] = varo:GetDefault()
        varo:SetString(DATA.MOD[idx])
      else DATA.MOD[idx] = m end
    end,
  varn)
end

function LaserLib.TraceCAP(origin, direct, length, filter)
  if(StarGate ~= nil) then
    DATA.TRACE.start:Set(origin)
    DATA.TRACE.endpos:Set(direct)
    DATA.TRACE.endpos:Normalize()
    DATA.TRACE.endpos:Mul(length) -- If CAP specific entity is hit return trace
    local tr = StarGate.Trace:New(DATA.TRACE.start, DATA.TRACE.endpos, filter);
    if(StarGate.Trace.Entities[tr.Entity]) then return tr end
  end; return nil -- Otherwise use the reglar trace for refraction control
end

-- CAP: https://github.com/RafaelDeJongh/cap/blob/master/lua/stargate/shared/tracelines.lua
function LaserLib.Trace(origin, direct, length, filter, mask, colgrp, iworld, width, result)
  local tr = LaserLib.TraceCAP(origin, direct, length, filter)
  if(tr) then return tr end -- Return when CAP stuff is currently being hit
  DATA.TRACE.start:Set(origin)
  DATA.TRACE.endpos:Set(direct)
  DATA.TRACE.endpos:Normalize()
  DATA.TRACE.endpos:Mul(length)
  DATA.TRACE.endpos:Add(origin)
  DATA.TRACE.filter = filter
  if(width ~= nil and width > 0) then
    local m = width / 2
    DATA.TRACE.funct = util.TraceHull
    DATA.TRACE.mins:SetUnpacked(-m, -m, -m)
    DATA.TRACE.maxs:SetUnpacked( m,  m,  m)
  else
    DATA.TRACE.funct = util.TraceLine
  end
  if(mask ~= nil) then
    DATA.TRACE.mask = mask
  else -- Default trace mask
    DATA.TRACE.mask = MASK_SOLID
  end
  if(iworld ~= nil) then
    DATA.TRACE.ignoreworld = iworld
  else -- Default world ignore
    DATA.TRACE.ignoreworld = false
  end
  if(colgrp ~= nil) then
    DATA.TRACE.collisiongroup = colgrp
  else -- Default collision group
    DATA.TRACE.collisiongroup = COLLISION_GROUP_NONE
  end
  if(result ~= nil) then
    DATA.TRACE.output = result
    DATA.TRACE.funct(DATA.TRACE)
    DATA.TRACE.output = nil
    return result
  else
    DATA.TRACE.output = nil
    return DATA.TRACE.funct(DATA.TRACE)
  end
end

function LaserLib.GetSign(arg)
  return arg / math.abs(arg)
end

--[[
 * This is used to time a given code sippet
 * Call it without arguments to reset the state
 * Dinamically sums N-calls and reurns the average
 * num > Number of samples to be registered
 * tim > Time difference to be registered
]]
function LaserLib.Time(num, tim)
  local arr = DATA.TIME
  if(num and tim) then
    local siz = arr.Size
    if(siz <= num) then
      arr.Suma = arr.Suma - (arr[siz] or 0)
      arr[siz] = tim
      arr.Suma = arr.Suma + tim
      arr.Size = siz + 1
    else
      arr.Suma = arr.Suma - arr[1]
      arr[1] = tim
      arr.Suma = arr.Suma + tim
      arr.Size = 1
      arr.Done = true
    end
    local top = arr.Done and num or siz
    return (arr.Suma / top), top
  else
    arr.Size = 1
    arr.Suma = 0
    arr.Done = false
  end
end

function LaserLib.Clear(arr, idx)
  if(not arr) then return end
  local idx = math.floor(tonumber(idx) or 1)
  if(idx <= 0) then return end
  while(arr[idx]) do idx, arr[idx] = (idx + 1) end
end

-- Validates entity or physics object
function LaserLib.IsValid(arg)
  if(arg == nil) then return false end
  if(arg == NULL) then return false end
  return arg:IsValid()
end

--[[
 * This setups the beam kill krediting
 * Updates the kill kredit player for specific entity
 * To obtain the creator player use `ent:GetCreator()`
 * https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/entity.lua#L69
]]
function LaserLib.SetPlayer(ent, user)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsValid(user)) then return end
  ent.ply, ent.player = user, user -- Used for PPs and wire
  ent:SetVar("Player", user) -- Used in sandbox on spawn
end

-- https://wiki.facepunch.com/gmod/Enums/NOTIFY
function LaserLib.Notify(user, text, mtyp)
  if(LaserLib.IsValid(user)) then
    if(SERVER) then local ran = math.random(1, 4)
      user:SendLua(DATA.NTIF[1]:format(text, mtyp))
      user:SendLua(DATA.NTIF[2]:format(ran))
    end
  end
end

function LaserLib.ConCommand(user, name, value)
  local key = DATA.TOOL.."_"..name
  if(LaserLib.IsValid(user)) then
    user:ConCommand(key.." \""..tostring(value or "").."\"\n")
  else RunConsoleCommand(key, tostring(value or "")) end
end

function LaserLib.Call(time, func, ...)
  local tnew = SysTime()
  if((tnew - DATA.TOLD) > time)
    then func(...); DATA.TOLD = tnew end
end

-- Draw a position on the screen
function LaserLib.DrawPoint(pos, col, idx, msg)
  if(not CLIENT) then return end
  local crw = LaserLib.GetColor(col or "YELLOW")
  render.SetColorMaterial()
  render.DrawSphere(pos, 1, 25, 25, crw)
  if(idx or msg) then
    local txt, mrg, fnt = "", 6, "Trebuchet24"
    if(idx) then txt = txt..tostring(idx)
      if(msg) then txt = txt..": " end end
    if(msg) then txt = txt..tostring(msg) end
    local ang = dir:AngleEx(DATA.VDRUP)
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    cam.Start3D2D(pos, ang, 0.16)
      surface.SetFont(fnt)
      local w, h = surface.GetTextSize(txt)
      draw.RoundedBox(8, -(w/2)-mrg, -(h/2)-mrg/1.5, w+2*mrg, h+2*mrg, DATA.COLOR.BACKGR)
      draw.SimpleText(txt,fnt,0,0,DATA.COLOR.BLACK,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
  end
end

-- Draw a position on the screen
function LaserLib.DrawVector(pos, dir, mag, col, idx, msg)
  if(not CLIENT) then return end
  local ven = pos + (dir * (tonumber(mag) or 1))
  local crw = LaserLib.GetColor(col or "YELLOW")
  render.SetColorMaterial()
  render.DrawSphere(pos, 1, 25, 25, crw)
  render.DrawLine(pos, ven, crw, false)
  if(idx or msg) then
    local txt, mrg, fnt = "", 6, "Trebuchet24"
    if(idx) then txt = txt..tostring(idx)
      if(msg) then txt = txt..": " end end
    if(msg) then txt = txt..tostring(msg) end
    local ang = dir:AngleEx(DATA.VDRUP)
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    cam.Start3D2D(pos, ang, 0.16)
      surface.SetFont(fnt)
      local w, h = surface.GetTextSize(txt)
      draw.RoundedBox(8, -(w/2)-mrg, -(h/2)-mrg/1.5, w+2*mrg, h+2*mrg, DATA.COLOR.BACKGR)
      draw.SimpleText(txt,fnt,0,0,DATA.COLOR.BLACK,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
  end
end

function LaserLib.GetIcon(icon)
  return DATA.ICON:format(tostring(icon or ""))
end

function LaserLib.GetData(key)
  if(not key) then return end
  return DATA[key]
end

function LaserLib.GetTool()
  return DATA.TOOL
end

function LaserLib.GetZeroVector()
  return DATA.VZERO
end

function LaserLib.GetZeroAngle()
  return DATA.AZERO
end

function LaserLib.GetRatio()
  return DATA.GRAT
end

function LaserLib.GetZeroTransform()
  return DATA.VZERO, DATA.AZERO
end

function LaserLib.VecNegate(vec)
  vec.x = -vec.x
  vec.y = -vec.y
  vec.z = -vec.z
  return vec
end

function LaserLib.ToString(tav)
  local a = tonumber(tav[1] or tav.x or tav.p) or 0
  local b = tonumber(tav[2] or tav.y or tav.y) or 0
  local c = tonumber(tav[3] or tav.z or tav.r) or 0
  return DATA.FMVA:format(a, b, c)
end

function LaserLib.ByString(str)
  local str = tostring(str or ""):Trim()
  local tav = (","):Explode(str)
  local a = (tonumber(tav[1]) or 0)
  local b = (tonumber(tav[2]) or 0)
  local c = (tonumber(tav[3]) or 0)
  return a, b, c
end

function LaserLib.SetupTransform(tran)
  local amax = LaserLib.GetData("AMAX")
  tran[1] = math.Clamp(tonumber(tran[1]) or 0, amax[1], amax[2])
  if(not tran[2] or tran[2] == "") then tran[2] = nil -- Origin
  else tran[2] = Vector(LaserLib.ByString(tran[2])) end
  if(not tran[3] or tran[3] == "") then tran[3] = nil -- Direction
  else tran[3] = Vector(LaserLib.ByString(tran[3])) end
  return tran -- Return the converted transform
end

--[[
 * Applies the final posutional and angular offsets to the laser spawned
 * Adjusts the custom model angle and calculates the touch position
 * base  > The laser entity to preform the operation for
 * trace > The trace that player is aiming for
 * tran  > Transform data array information
]]
function LaserLib.ApplySpawn(base, trace, tran)
  if(tran[2] and tran[3]) then
    LaserLib.SnapCustom(base, trace.HitPos, trace.HitNormal, tran[2], tran[3])
  else
    LaserLib.SnapNormal(base, trace.HitPos, trace.HitNormal, tran[1])
  end
end

--[[
 * Reads class name from the list
 * idx (int) > When provided checks settings
]]
function LaserLib.GetClass(iR, iC)
  local nR = math.floor(tonumber(iR) or 0)
  local tS = DATA.CLS[nR] -- Pick elemrnt
  if(not tS) then return nil end -- No info
  local nC = math.floor(tonumber(iC) or 0)
  return tS[nC] -- Return whatever found
end

--[[
 * Defines when the enty is laser library unit
 * idx (int) > When provided checks for flags
]]
function LaserLib.IsUnit(ent, idx)
  if(not LaserLib.IsValid(ent)) then return false end
  local set = DATA.CLS[ent:GetClass()]
  if(not set) then return false end
  if(not idx) then return true end
  return set[idx]
end

function LaserLib.GetModel(iK)
  local sM = DATA.MOD[tonumber(iK)]
  return (sM and sM or nil)
end

function LaserLib.GetMaterial(iK)
  local sT = DATA.MAT[tonumber(iK)]
  return (sT and sT or nil)
end

--[[
 * Creates welds between laser and base
 * Applies and controls surface weld flag
 * weld  > Surface weld flag
 * laser > Laser entity to be welded
 * trace > Trace enity to be welded or world
]]
function LaserLib.Weld(weld, laser, trace)
  if(not weld) then return nil end
  if(not LaserLib.IsValid(laser)) then return nil end
  local tren, bone = trace.Entity, trace.PhysicsBone
  local eval = (LaserLib.IsValid(tren) and not tren:IsWorld())
  local anch = eval and tren or game.GetWorld()
  local encw = constraint.Weld(laser, anch, bone, 0, 0)
  if(LaserLib.IsValid(encw)) then
    laser:DeleteOnRemove(encw) -- Remove the weld with the laser
    if(eval) then -- Remove weld with the anchor entity
      anch:DeleteOnRemove(encw) -- Apply on valid entity
    end; return encw -- Return the weld for undo list
  end; return nil -- Do not call this for the world
end

--[[
 * Returns the yaw angle for the spawn function
 * ply > Player to calculate the angle for
   [1] > The calculated yaw result angle
]]
function LaserLib.GetAngleSF(ply)
  local han, tan = (DATA.AMAX[2] / 2), DATA.AMAX[2]
  local yaw = (ply:GetAimVector():Angle().y + han) % tan
  local ang = Angle(0, yaw, 0); ang:Normalize(); return ang
end

--[[
 * Reflects a beam from a surface with material override
 * direct > The incident direction vector
 * normal > Surface normal vector trace.HitNormal ( normalized )
 * Return the refracted ray and beam status
  [1] > The refracted ray direction vector
]]
function LaserLib.GetReflected(direct, normal)
  local ref = Vector(normal) -- Always normalized
  local inc = direct:GetNormalized()
  local mul = (-2 * inc:Dot(ref))
  ref:Mul(mul); ref:Add(inc); return ref
end

--[[
 * Refracts a beam across two mediums by returning the refracted vector
 * direct > The incident direction vector
 * normal > Surface normal vector trace.HitNormal ( normalized )
 * source > Refraction index of the source medium
 * destin > Refraction index of the destination medium
 * Return the refracted ray and beam status
  [1] > The refracted ray direction vector
  [2] > Will the beam go out of the medium
]]
function LaserLib.GetRefracted(direct, normal, source, destin)
  local nrm = Vector(normal) -- Always normalized
  local inc = direct:GetNormalized()
  local vcr = inc:Cross(LaserLib.VecNegate(nrm))
  local ang, sii = nrm:AngleEx(vcr), vcr:Length()
  local sio = math.asin(sii / (destin / source))
  if(sio ~= sio) then -- Argument sine is undefined so reflect (NaN)
    return LaserLib.GetReflected(direct, nrm), false
  else -- Arg sine is defined so refract. Exit medium
    ang:RotateAroundAxis(ang:Up(), -math.deg(sio))
    return ang:Forward(), true
  end
end

--[[
 * Updates render bounds vector by calling min/max
 * base > Vector to be updated
 * vec  > Vector the base must be updated with
 * func > The cinction to be called. Either max or min
]]
function LaserLib.UpdateRB(base, vec, func)
  base.x = func(base.x, vec.x)
  base.y = func(base.y, vec.y)
  base.z = func(base.z, vec.z)
end

--[[
 * Makes the width visible when different than zero
 * width > The value to apply beam transformation
]]
function LaserLib.GetWidth(width)
  if(SERVER) then return width end
  local out = math.max(width, DATA.MINW)
  return ((width > 0) and out or 0)
end

--[[
 * Calculates the laser trigger power
 * width  > Laser beam width
 * damage > Laser beam damage
]]
function LaserLib.GetPower(width, damage)
  return (DATA.KWID * width + damage)
end

--[[
 * Returns true whenever the width is still visible
 * width  > Value to chack beam visiblility
 * damage > Complete the power damage formula
]]
function LaserLib.IsPower(width, damage)
  local margn = (DATA.KWID * DATA.MINW)
  local power = LaserLib.GetPower(width, damage)
  return (math.Round(power, DATA.RNDB) > margn)
end

-- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
function GetCollectionData(key, set)
  local idx = DATA.KEYD
  local def = set[set[idx]]
  if(not key) then return def end
  if(key == idx) then return def end
  local out = set[key] -- Try to index
  if(not out) then return def end
  return out -- Return indexed OK
end

function LaserLib.GetDissolveID(disstype)
  return GetCollectionData(disstype, DATA.DISTYPE)
end

function LaserLib.GetColor(color)
  return GetCollectionData(color, DATA.COLOR)
end

function LaserLib.SetMaterial(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local data = {MaterialOverride = tostring(mat or "")}
  ent:SetMaterial(data.MaterialOverride)
  duplicator.StoreEntityModifier(ent, "laseremitter_material", data)
end

function LaserLib.SetProperties(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local phy = ent:GetPhysicsObject()
  if(not LaserLib.IsValid(phy)) then return end
  local data = {Material = tostring(mat or "")}
  construct.SetPhysProp(nil, ent, 0, phy, data)
  duplicator.StoreEntityModifier(ent, "laseremitter_properties", data)
end

--[[
 * https://wiki.facepunch.com/gmod/Enums/MAT
 * https://wiki.facepunch.com/gmod/Entity:GetMaterialType
 * Retrieves material override for a trace or use the default
 * Toggles material original selecton when not available
 * When flag is disabled uses the material type for checking
 * The value must be available for client and server sides
 * trace > Reference to trace result structure
 * data  > Reference to current beam data parameters
 * Returns: Material extracted from the entity on server and client
]]
local function GetMaterialID(trace, data)
  if(not trace) then return nil end
  if(not trace.Hit) then return nil end
  if(trace.HitWorld) then
    local mat = trace.HitTexture -- Use trace material type
    if(mat:sub(1,1) == "*" and mat:sub(-1,-1) == "*") then
      mat = DATA.MATYPE[trace.MatType] -- Material lookup
    end -- **studio**, **displacement**, **empty**
    return mat
  else
    local ent = trace.Entity
    if(not LaserLib.IsValid(ent)) then return nil end
    local mat = ent:GetMaterial() -- Entity may not have override
    if(mat == "") then -- Empty then use the material type
      if(data.BmNoover) then -- No override is available use original
        mat = ent:GetMaterials()[1] -- Just grab the first material
      else -- Gmod can not simply decide which material is hit
        mat = trace.HitTexture -- Use trace material type
        if(mat:sub(1,1) == "*" and mat:sub(-1,-1) == "*") then
          mat = DATA.MATYPE[trace.MatType] -- Material lookup
        end -- **studio**, **displacement**, **empty**
      end -- Physobj has a single surfacetype related to model
    end
    return mat
  end
end


--[[
 * Checks when the entity has interactive material
 * mat > Direct material to check for. Missing uses `ent`
 * set > The dedicated parameeters setting to check
 * Returns: data, key
]]
local function IndexMaterial(mat, set)
  if(not mat) then return nil end
  if(not set) then return nil end
  local mat = tostring(mat)-- Pointer to the local surface material
  -- Read the first entry from table
  local key, val = mat, set[mat]
  -- Check for overriding with default
  if(mat == DATA.KEYD) then return set[val], val end
  -- Check for element overrides
  if(val) then return val, key end
  -- Check for emement category
  for idx = 1, set.Size do key = set[idx]
    if(mat:find(key, 1, true)) then
      set[mat] = set[key]  -- Cache the material
      return set[key], key -- Compare the entry
    end -- Read and compare the next entry
  end; set[mat] = false -- Undefined material
  return nil -- Return nothing when not found
end

local function GetInteractIndex(iK, data)
  if(iK == DATA.KEYA) then return data end
  return (data[iK] or data[DATA.KEYD])
end

function LaserLib.DataReflect(iK)
  return GetInteractIndex(iK, DATA.REFLECT)
end

function LaserLib.DataRefract(iK)
  return GetInteractIndex(iK, DATA.REFRACT)
end

--[[
 * Calculates the local beam origin offset
 * according to the base entity and direction provided
 * base   > Base entity to calculate the vector for
 * direct > Local direction vector according to `base`
 * Returns the local entity origin offcet vector
 * obcen  > Beam origin as a local offset vector
 * kmulv  > Width relative to the given local direction
]]
function LaserLib.GetBeamOrigin(base, direct)
  if(not LaserLib.IsValid(base)) then return Vector(DATA.VZERO) end
  local vbeam, obcen = Vector(direct), base:OBBCenter()
  local obdir = base:OBBMaxs(); obdir:Sub(base:OBBMins())
  local kmulv = math.abs(obdir:Dot(vbeam))
        vbeam:Mul(kmulv / 2); obcen:Add(vbeam)
  return obcen, kmulv
end

--[[
 * Calculates the beam direction according to the
 * angle provided as a regular number. Rotates around Y
 * base  > Base entity to calculate the direction for
 * angle > Amount to rotate the entity angle in degrees
]]
function LaserLib.GetBeamDirection(base, angle)
  if(not LaserLib.IsValid(base)) then return Angle(DATA.AZERO) end
  local aent = base:GetAngles()
  local rang, arot = aent:Right(), (tonumber(angle) or 0)
        aent:RotateAroundAxis(rang, arot)
  local pent = base:GetPos(); pent:Add(aent:Forward())
  local dent = base:WorldToLocal(pent)
        dent:Normalize(); return dent
end

--[[
 * Projects the OBB onto the ray defined by position and direction
 * base  > Base entity to calculate the snapping for
 * hitp  > The position of the surface to snap the laser on
 * norm  > World normal direction vector defining the snap plane
 * angle > The model offset beam angling parameterization
]]
function LaserLib.SnapNormal(base, hitp, norm, angle)
  local ang = norm:Angle()
        ang:RotateAroundAxis(ang:Right(), -angle)
  local dir = LaserLib.GetBeamDirection(base, angle)
        LaserLib.VecNegate(dir)
  local org = LaserLib.GetBeamOrigin(base, dir)
        LaserLib.VecNegate(org)
  dir:Rotate(ang); org:Rotate(ang); org:Add(hitp)
  base:SetPos(org); base:SetAngles(ang)
end

function LaserLib.GetCustomAngle(base, direct)
  local tab = base:GetTable(); if(tab.anCustom) then
    return tab.anCustom else tab.anCustom = Angle() end
  local az, mt = DATA.AZERO, DATA.TCUST
  local th, tl = mt.H, mt.L; th.ID, tl.ID = 0, 0 -- Wipe ID
  for idx = 1, #mt do -- Pick up min/max projection lengths
    local vec = az[mt[idx]](az) -- Read primal direction vector
    local vmr = direct:Dot(vec)
    local mar = math.abs(vmr) -- Calculate margin
    if(th.ID == 0 or mar >= th.M) then
      th.ID, th.M = idx, mar
      th.V = ((mar ~= 0) and vmr or 1)
      tl.V = LaserLib.GetSign(tl.V)
    end
    if(tl.ID == 0 or mar <= tl.M) then
      tl.ID, tl.M = idx, mar
      tl.V = ((mar ~= 0) and vmr or 1)
      tl.V = LaserLib.GetSign(tl.V)
    end
  end -- Forward is max projection up is min projection
  local f = az[mt[th.ID]](az); f:Mul(th.V) -- Primary forward (orthogonal)
  local u = az[mt[tl.ID]](az); u:Mul(tl.V) -- Primary up (orthogonal)
  tab.anCustom:Set(f:AngleEx(u)) -- Transfer data and applt angle pitch
  tab.anCustom:RotateAroundAxis(f:Cross(u), -90) -- Cache angle
  return tab.anCustom
end

function LaserLib.SnapCustom(base, hitp, norm, origin, direct)
  local dir = Vector(direct); LaserLib.VecNegate(dir)
  local ang, tra = Angle(), norm:Angle()
  local pos = LaserLib.GetBeamOrigin(base, dir)
  ang:Set(LaserLib.GetCustomAngle(base, direct))
  tra:RotateAroundAxis(tra:Right(), -90)
  ang:Set(base:AlignAngles(base:LocalToWorldAngles(ang), tra))
  pos:Rotate(ang); LaserLib.VecNegate(pos); pos:Add(hitp)
  base:SetPos(pos); base:SetAngles(ang)
end

if(SERVER) then

  AddCSLuaFile("autorun/laserlib.lua")

  DATA.DMGI = DamageInfo() -- Create a server-side damage information class

  -- https://wiki.facepunch.com/gmod/Global.DamageInfo
  function LaserLib.TakeDamage(victim, damage, attacker, laser)
    DATA.DMGI:SetDamage(damage)
    DATA.DMGI:SetAttacker(attacker)
    DATA.DMGI:SetInflictor(laser)
    DATA.DMGI:SetDamageType(DMG_ENERGYBEAM)
    victim:TakeDamageInfo(DATA.DMGI)
  end

  -- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
  function LaserLib.GetTorch(base, position, attacker, disstype)
    local ent = ents.Create("env_entity_dissolver")
    if(not LaserLib.IsValid(ent)) then return nil end
    ent.Target = "laserdissolve"..base:EntIndex()
    ent:SetKeyValue("dissolvetype", disstype)
    ent:SetKeyValue("magnitude", 0)
    ent:SetPos(position)
    ent:SetPhysicsAttacker(attacker)
    ent:Spawn()
    return ent
  end

  function LaserLib.DoDamage(target, origin , normal  , direct  ,
                             damage, force  , attacker, dissolve,
                             noise , fcenter, laser)
    local phys = target:GetPhysicsObject()
    if(force and LaserLib.IsValid(phys)) then
      if(fcenter) then -- Force relative to mass center
        phys:ApplyForceCenter(direct * force)
      else -- Keep force separate from damage inflicting
        phys:ApplyForceOffset(direct * force, origin)
      end -- This is the way laser can be used as forcer
    end

    if(laser.isDamage) then
      if(target:IsVehicle()) then
        local driver = target:GetDriver()
        -- Take damage doesn't work on player inside a vehicle.
        if(LaserLib.IsValid(driver)) then
          target = driver; target:Kill()
        end -- We must kill the driver!
      end

      if(target:GetClass() == "shield") then
        local damage = math.Clamp(damage / 2500 * 3, 0, 4)
        target:Hit(laser, origin, damage, -1 * normal)
        return -- We stop here because we hit a shield!
      end

      if(target:Health() <= damage) then
        if(target:IsNPC() or target:IsPlayer()) then
          local torch = LaserLib.GetTorch(laser, target:GetPos(), attacker, dissolve)
          if(LaserLib.IsValid(torch)) then
            if(target:IsPlayer()) then
              LaserLib.TakeDamage(target, damage, attacker, laser)

              local doll = target:GetRagdollEntity()
              -- We need to kill the player first to get his ragdoll.
              if(not LaserLib.IsValid(doll)) then return end
              -- Thanks to Nevec for the player ragdoll idea, allowing us to dissolve him the cleanest way.
              doll:SetName(torch.Target)
            else
              target:SetName(torch.Target)

              local swep = target:GetActiveWeapon()
              if(LaserLib.IsValid(swep)) then
                swep:SetName(torch.Target)
              end
            end

            torch:Fire("Dissolve", torch.Target, 0)
            torch:Fire("Kill", "", 0.1)
          end
        end

        if(noise ~= nil and (target:Health() > 0 or target:IsPlayer())) then
          sound.Play(noise, target:GetPos())
          target:EmitSound(Sound(noise))
        end
      end

      LaserLib.TakeDamage(target, damage, attacker, laser)
    end
  end

  function LaserLib.New(user       , pos         , ang         , model      ,
                        trandata   , key         , width       , length     ,
                        damage     , material    , dissolveType, startSound ,
                        stopSound  , killSound   , runToggle   , startOn    ,
                        pushForce  , endingEffect, reflectRate , refractRate,
                        forceCenter, frozen      , enOverMater , rayColor )

    local unit = LaserLib.GetTool()
    if(not (LaserLib.IsValid(user) and user:IsPlayer())) then return nil end
    if(not user:CheckLimit(unit.."s")) then return nil end

    local laser = ents.Create(LaserLib.GetClass(1, 1))
    if(not (LaserLib.IsValid(laser))) then return nil end

    laser:SetCollisionGroup(COLLISION_GROUP_NONE)
    laser:SetSolid(SOLID_VPHYSICS)
    laser:SetMoveType(MOVETYPE_VPHYSICS)
    laser:SetNotSolid(false)
    laser:SetPos(pos)
    laser:SetAngles(ang)
    laser:SetModel(Model(model))
    laser:Spawn()
    laser:SetCreator(user); laser:SetVar("Player", user)
    laser:Setup(width       , length     , damage     , material    ,
                dissolveType, startSound , stopSound  , killSound   ,
                runToggle   , startOn    , pushForce  , endingEffect, trandata,
                reflectRate , refractRate, forceCenter, enOverMater , rayColor, false)

    local phys = laser:GetPhysicsObject()
    if(LaserLib.IsValid(phys)) then
      phys:EnableMotion(not frozen)
    end

    user:AddCount(unit.."s", laser)
    numpad.OnUp  (user, key, "Laser_Off", laser)
    numpad.OnDown(user, key, "Laser_On" , laser)

    -- These do not change when laser is updated
    table.Merge(laser:GetTable(), {
      ply         = laser:GetCreator(),
      player      = laser:GetCreator(),
      key         = key,
      frozen      = frozen
    })

    return laser
  end
end

--[[
 * Setups the beam power ratio when requested
 * data   > Internal beam manipulation data
 * rate   > The ratio to apply on the last node
]]
function LaserLib.SetPowerRatio(data, rate)
  data.NvDamage = rate * data.NvDamage
  data.NvForce  = rate * data.NvForce
  data.NvWidth  = LaserLib.GetWidth(rate * data.NvWidth)
  -- Update the parameters used for drawing the beam trace
  local node = data.TvPoints[data.TvPoints.Size]
  node[2], node[3], node[4] = data.NvWidth, data.NvDamage, data.NvForce
  -- Check out power rankings so the trace absorbed everything
  local power = LaserLib.GetPower(data.NvWidth, data.NvDamage)
  if(power < DATA.POWL) then data.IsTrace = false end -- Absorbs remaining light
  return node, power -- It is indexed anyway then return it to the caller
end

--[[
 * Beam traverses from medium [1] to medium [2]
 * data   > The structure to update the nodes for
 * origin > The node position to be registered
 * bulen  > Update the length according to the new node
]]
function LaserLib.RegisterNode(data, origin, bulen, bdraw)
  local info = data.TvPoints -- Local reference to stack
  local node, width = Vector(origin), data.NvWidth
  local damage, force = data.NvDamage , data.NvForce
  local bdraw = (bdraw or bdraw == nil) and true or false
  if(bulen) then -- Substract the path trough the medium
    local prev = info[info.Size][1]
    data.NvLength = data.NvLength - (node - prev):Length()
  end -- Register the new node to the stack
  info.Size = table.insert(info, {node, width, damage, force, bdraw})
end

--[[
 * Caculates the beam posidion and direction when entity is a portal
 * This assumes that the neam enters th +X and exits at +X
 * This will lead to correct beam representation across portal Y axis
 * base    > Base entity actime as a portal entrance
 * base    > Exit entity actime as a portal beam output location
 * origin  > Hit location vector placed on the furst entity surface
 * direct  > Direction that the beam goes inside the first entity
 * forigin > Origin custom modifier function. Negates X, Y by default
 * fdirect > Direction custom modifier function. Negates X, Y by default
 * Returns the output beam ray position and direction
]]
function LaserLib.GetBeamPortal(base, exit, origin, direct, forigin, fdirect)
  if(not LaserLib.IsValid(base)) then return origin, direct end
  if(not LaserLib.IsValid(exit)) then return origin, direct end
  local pos, dir = Vector(origin), Vector(direct)
  pos:Set(base:WorldToLocal(pos)); dir:Mul(DATA.WLMR)
  if(forigin) then local ok, err = pcall(forigin, pos)
    if(not ok) then error("Origin error: "..err) end
  else pos.x, pos.y = -pos.x, -pos.y end
  pos:Set(exit:LocalToWorld(pos))
  dir:Add(base:GetPos())
  dir:Set(base:WorldToLocal(dir))
  if(fdirect) then local ok, err = pcall(fdirect, dir)
    if(not ok) then error("Direction error: "..err) end
  else dir.x, dir.y = -dir.x, -dir.y end
  dir:Rotate(exit:GetAngles()); dir:Div(DATA.WLMR)
  return pos, dir
end

DATA.ACTOR = {
   --[[
    * Function handler for calculating portal routines
    * entity > The actual beam source
    * trace  > Reference to trace result structure
    * trace  > Reference to trace beam data
   ]]
  ["event_horizon"] = function(trace, data)
    data.IsTrace = false -- Assue that beam stops traversing
    data.NvLength = data.NvLength - data.NvLength * trace.Fraction
    local ent, src = trace.Entity, data.BmSource
    local pob, dir = trace.HitPos, data.VrDirect
    local eff, out = src.isEffect, ent.Target
    if(out == ent) then return end -- We need to go somewhere
    if(not LaserLib.IsValid(out)) then return end
    -- Leave networking to CAP. Invalid target. Stop
    local pot, dit = ent:GetTeleportedVector(pob, dir)
    if(SERVER and ent:IsOpen() and eff) then -- Library effect flag
      ent:EnterEffect(pob, data.NvWidth) -- Enter effect
      out:EnterEffect(pot, data.NvWidth) -- Exit effect
    end -- Stargate ( CAP ) requires little nudge in the origin vector
    data.VrOrigin:Set(pot); data.VrDirect:Set(dit)
    -- Otherwise the trace will get stick and will hit again
    LaserLib.RegisterNode(data, data.VrOrigin, nil, true)
    data.TeFilter, data.TrFActor = out, true
    data.IsTrace = true -- CAP networking is correct. Continue
  end,
  ["gmod_laser_portal"] = function(trace, data)
    data.IsTrace = false -- Assue that beam stops traversing
    data.NvLength = data.NvLength - data.NvLength * trace.Fraction
    local ent, src = trace.Entity, data.BmSource
    if(not ent:IsHitNormal(trace)) then return end
    local idx = (tonumber(ent:GetEntityExitID()) or 0)
    if(idx <= 0) then return end -- No output ID chosen
    local out = ent:GetActiveExit(idx) -- Validate output entity
    if(not out) then return end -- No output ID. Missing ent
    local nrm = ent:GetNormalLocal() -- Read current normal
    local bnr = (nrm:LengthSqr() > 0) -- When the model is flat
    local mir = ent:GetMirrorExitPos()
    local pos, dir = trace.HitPos, data.VrDirect
    nps, ndr = LaserLib.GetBeamPortal(ent, out, pos, dir,
      function(ppos)
        if(mir and bnr) then
          local v, a = ent:ToCustomUCS(ppos)
          v.y = -v.y; ppos:Set(v); ppos:Rotate(a)
        else
          local v, a = ent:ToCustomUCS(ppos)
          ppos:Set(v); ppos:Rotate(a)
        end
      end,
      function(pdir)
        if(ent:GetReflectExitDir()) then
          local trn = Vector(trace.HitNormal)
          trn:Mul(DATA.WLMR); trn:Add(ent:GetPos())
          trn:Set(ent:WorldToLocal(trn)); trn:Div(DATA.WLMR)
          pdir:Set(LaserLib.GetReflected(pdir, trn))
        else
          local v, a = ent:ToCustomUCS(pdir)
          v.x = -v.x; v.y = -v.y
          pdir:Set(v); pdir:Rotate(a)
        end
      end)
    data.VrOrigin:Set(nps); data.VrDirect:Set(ndr)
    LaserLib.RegisterNode(data, data.VrOrigin, nil, true)
    data.TeFilter, data.TrFActor = out, true
    data.IsTrace = true -- Output model is validated. Continue
  end,
  ["prop_portal"] = function(trace, data)
    data.IsTrace = false -- Assue that beam stops traversing
    data.NvLength = data.NvLength - data.NvLength * trace.Fraction
    local ent, src, out = trace.Entity, data.BmSource
    if(not ent:IsLinked()) then return end -- No linked pair
    if(SERVER) then out = ent:FindOpenPair() -- Retrieve open pair
    else out = Entity(ent:GetNWInt("laseremitter_portal", 0)) end
    -- Assume that output portal will have the same surface offset
    if(not LaserLib.IsValid(out)) then return end -- No linked pair
    ent:SetNWInt("laseremitter_portal", out:EntIndex())
    local inf = data.TvPoints; inf[inf.Size][5] = true
    local dir, nrm, pos = data.VrDirect, trace.HitNormal, trace.HitPos
    local eps, ean, mav = ent:GetPos(), ent:GetAngles(), Vector(dir)
    local fwd, wvc = ent:GetForward(), Vector(pos); wvc:Sub(eps)
    local mar = math.abs(wvc:Dot(fwd)) -- Project entrance vector
    local vsm = mar / math.cos(math.asin(fwd:Cross(dir):Length()))
    vsm = 2 * vsm; mav:Set(dir); mav:Mul(vsm); mav:Add(trace.HitPos)
    LaserLib.RegisterNode(data, mav, nil, false)
    local nps, ndr = LaserLib.GetBeamPortal(ent, out, pos, dir)
    LaserLib.RegisterNode(data, nps); nps:Add(vsm * ndr)
    data.VrOrigin:Set(nps); data.VrDirect:Set(ndr)
    LaserLib.RegisterNode(data, nps)
    data.TeFilter, data.TrFActor = out, true
    data.IsTrace = true -- Output portal is validated. Continue
  end,
  ["gmod_laser_dimmer"] = function(trace, data)
    data.IsTrace = false -- Assume that beam stops traversing
    data.NvLength = data.NvLength - data.NvLength * trace.Fraction
    local ent , node = trace.Entity, data.TvPoints[data.TvPoints.Size]
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, trace, data, bmln)
    if(trace and trace.Hit and data and bdot) then
      data.IsTrace = true -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamReplicate() and 1 or mdot)
      local node = LaserLib.SetPowerRatio(data, vdot) -- May absorb
      data.VrOrigin:Set(trace.HitPos)
      data.TeFilter, data.TrFActor = ent, true -- Makes beam pass the dimmer
      node[1]:Set(trace.HitPos) -- We are not portal update position
      node[5] = true            -- We are not portal enable drawing
    end
  end,
  ["gmod_laser_parallel"] = function(trace, data)
    data.IsTrace = false -- Assume that beam stops traversing
    data.NvLength = data.NvLength - data.NvLength * trace.Fraction
    local ent , node = trace.Entity, data.TvPoints[data.TvPoints.Size]
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, trace, data, bmln)
    if(trace and trace.Hit and data and bdot) then
      data.IsTrace = true -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamDimmer() and mdot or 1)
      local node = LaserLib.SetPowerRatio(data, vdot) -- May absorb
      data.VrOrigin:Set(trace.HitPos)
      data.VrDirect:Set(trace.HitNormal); LaserLib.VecNegate(data.VrDirect)
      data.TeFilter, data.TrFActor = ent, true -- Makes beam pass the parallel
      node[1]:Set(trace.HitPos) -- We are not portal update node
      node[5] = true            -- We are not portal enable drawing
    end
  end
}

--[[
 * Traces a laser beam from the entity provided
 * entity > Entity origin of the beam ( laser )
 * origin > Inititial ray world position vector
 * direct > Inititial ray world direction vector
 * length > Total beam length to be traced
 * width  > Beam starting width from the origin
 * damage > The amout of damage the beam does
 * force  > The amout of force the beam does
 * usrfle > Use surface material reflecting efficiency
 * usrfre > Use surface material refracting efficiency
 * noverm > Enable interactions with no material override
]]
function LaserLib.DoBeam(entity, origin, direct, length, width, damage, force, usrfle, usrfre, noverm, index)
  local data, trace, target = {} -- Configure data structure and target reference
  data.TrMaters = "" -- This stores the current extracted material as string
  data.NvMask   = MASK_ALL -- Trace mask. When not provided negative one is used
  data.NvCGroup = COLLISION_GROUP_NONE -- Collision group. Missing then COLLISION_GROUP_NONE
  data.IsTrace  = false -- Library is still tracing the beam
  data.NvIWorld = false -- Ignore world flag to make it hit the other side
  data.IsRfract = {false, false} -- Refracting flag for entity [1] and world [2]
  data.StRfract = false -- Start tracing the beam inside a boundary
  data.TrFActor = false -- Trace filter was updated by actor and must be cleared
  data.TeFilter = entity -- Make sure the initial laser source is skipped
  data.TvPoints = {Size = 0} -- Create empty vertices array
  data.VrOrigin = Vector(origin) -- Copy origin not to modify it
  data.VrDirect = direct:GetNormalized() -- Copy deirection not to modify it
  data.BmLength = math.max(tonumber(length) or 0, 0)
  data.NvDamage = math.max(tonumber(damage) or 0, 0)
  data.NvWidth  = math.max(tonumber(width ) or 0, 0)
  data.NvForce  = math.max(tonumber(force ) or 0, 0)
  data.TrMedium = {S = {DATA.REFRACT["air"], "air"}}
  data.BmTracew = 0 -- Make sure beam is zero width during the initial trace hit
  data.MxBounce = DATA.MBOUNCES:GetInt() -- All the bounces the loop made so far
  data.NvBounce = data.MxBounce -- Amount of bounces to control the infinite loop
  data.RaLength = data.BmLength -- Range of the length. Just like wire ranger
  data.TrRfract = data.BmLength -- Full length for traces not being bound by hit events
  data.DmRfract = data.BmLength -- Diameter trace-back dimensions of the entity
  data.NvLength = data.BmLength -- The actual beam lengths substracted after iterations
  data.BmSource = entity -- The beam source entity. Populated customly depending on the API
  data.BrReflec = usrfle -- Beam reflection ratio flag. Reduce beam power when reflecting
  data.BrRefrac = usrfre -- Beam refraction ratio flag. Reduce beam power when refracting
  data.BmNoover = noverm -- Beam no override material flag. Try to extract original material
  data.BmIdenty = index  -- Beam hit report index. Usually one if not provided

  if(data.NvLength <= 0) then return end
  if(data.VrDirect:LengthSqr() <= 0) then return end
  if(not LaserLib.IsValid(entity)) then return end

  LaserLib.RegisterNode(data, origin)

  repeat
    --[[
      TODO: Fix world water to air refraction
      When beam goes up has to be checked when comes out of the water
      if(DATA.VDRUP:Dot(data.VrDirect) and ??)
    ]]

    local isRfract = (data.IsRfract[1] or data.IsRfract[2])

    -- LaserLib.DrawVector(data.VrOrigin, data.VrDirect,
    --   (isRfract and data.TrRfract or data.NvLength), "GREEN", data.NvBounce)

    trace = LaserLib.Trace(data.VrOrigin,
                           data.VrDirect,
                           (isRfract and data.TrRfract or data.NvLength),
                           data.TeFilter,
                           data.NvMask,
                           data.NvCGroup,
                           data.NvIWorld,
                           data.BmTracew); target = trace.Entity

    if(isRfract and trace and trace.Hit and data.BmTracew and data.BmTracew > 0) then
      local mul = (-DATA.TRDG * data.BmTracew); trace.HitPos:Add(mul * trace.HitNormal)
    end -- Make sure we account for the trace width cube half diagonal

    -- Initial start so the beam separate from the entity
    if(data.NvBounce == data.MxBounce) then
      data.TeFilter = nil
      -- Beam starts inside map water
      if(trace.StartSolid) then
        trace.HitPos:Set(data.VrOrigin)
        trace.Fraction = 0
        trace.FractionLeftSolid = 0
        trace.HitTexture = "water"
        data.TrMedium = {S = {DATA.REFRACT["water"], "water"}}
      end
    end

    -- If filter was a special actor and the clear flag is enabled
    -- Make sure to reset the filter if needed to enter actor again
    if(data.TrFActor) then -- Custom filter clear has been requested
      data.TeFilter = nil -- Reset the filter to hit something else
      data.TrFActor = false -- Lower the flag so it does not enter
    end -- Filter is present and we have request to clear the value

    -- LaserLib.DrawVector(trace.HitPos, trace.HitNormal, 10, nil, data.NvBounce)

    local valid, class = LaserLib.IsValid(target) -- Validate target
    if(valid) then class = target:GetClass() end
    if(trace.Fraction > 0) then -- Ignore registering zero length traces
      if(valid) then -- Target is valis and it is a actor
        if(class and DATA.ACTOR[class]) then
          LaserLib.RegisterNode(data, trace.HitPos, isRfract, false)
        else -- The trace entity target is not special actor case
          LaserLib.RegisterNode(data, trace.HitPos, isRfract)
        end
      else -- The trace has hit invalid entity
        LaserLib.RegisterNode(data, trace.HitPos, isRfract)
      end
    else -- Trace distance lenght is zero so enable refraction
      if(data.NvBounce == data.MxBounce) then data.StRfract = true end
    end -- Do not put a node when beam starts in a solid
    -- When we hit something that is not specific unit
    if(trace.Hit and not LaserLib.IsUnit(target)) then
      -- Refresh medium pass trough information
      data.NvBounce = data.NvBounce - 1
      -- Register a hit so reduce bounces count
      if(valid) then
        if(data.IsRfract[1]) then
          -- Well the beam is still tracing
          data.IsTrace = true -- Produce next ray
          -- Make sure that outer trace will always hit
          LaserLib.VecNegate(data.VrDirect)
          LaserLib.VecNegate(trace.HitNormal)
          if(data.TrMedium.D[1]) then
            local vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                                     trace.HitNormal,
                                                     data.TrMedium.D[1][1],
                                                     data.TrMedium.S[1][1])
            if(vdir) then
              if(bout) then -- When the beam gets out of the medium
                -- Lower refraction flag ( Not full internal reflection )
                data.IsRfract[1] = false
                -- Restore the filter and hit world for tracing something else
                data.TeFilter = target -- We prepare to hit something else anyway
                data.BmTracew = 0 -- Use zero width beam traces
                data.NvIWorld = false -- Revert ignoring world
                -- Appy origin and direction when beam exits the medium
                data.VrDirect:Set(vdir)
                data.VrOrigin:Set(trace.HitPos)
              else -- Get the trace ready to check the other side and register the location
                data.VrDirect:Set(vdir)
                data.VrOrigin:Set(vdir)
                data.VrOrigin:Mul(data.DmRfract)
                data.VrOrigin:Add(trace.HitPos)
                LaserLib.VecNegate(data.VrDirect)
              end
            end
            if(usrfre) then
              LaserLib.SetPowerRatio(data, data.TrMedium.D[1][2])
            end
          end
        else -- Put special cases here
          if(class and DATA.ACTOR[class]) then
            local suc, err = pcall(DATA.ACTOR[class], trace, data)
            if(not suc) then data.IsTrace = false; error("Actor error: "..err) end
          else
            data.TrMaters = GetMaterialID(trace, data)
            data.IsTrace  = true -- Still tracing the beam
            local reflect = IndexMaterial(data.TrMaters, DATA.REFLECT)
            if(reflect) then -- Just call reflection and get done with it..
              data.VrDirect:Set(LaserLib.GetReflected(data.VrDirect, trace.HitNormal))
              data.VrOrigin:Set(trace.HitPos)
              data.NvLength = data.NvLength - data.NvLength * trace.Fraction
              if(usrfle) then
                LaserLib.SetPowerRatio(data, reflect[1])
              end
            else
              local refract, key = IndexMaterial(data.TrMaters, DATA.REFRACT)
              if(data.StRfract or (refract and key ~= data.TrMedium.S[2])) then -- Needs to be refracted
                -- Register desination medium and raise calculate refraction flag
                data.TrMedium.D = {refract, key}
                -- Substact traced lenght from total length
                data.NvLength = data.NvLength - data.NvLength * trace.Fraction
                -- Calculated refraction ray. Reflect when not possible
                local vdir, bout = target -- Refraction entity
                if(data.StRfract) then
                  vdir = Vector(direct); data.StRfract = false
                else
                  if(data.TrMedium.D[1]) then
                    vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                                       trace.HitNormal,
                                                       data.TrMedium.S[1][1],
                                                       data.TrMedium.D[1][1])
                  end
                end
                 -- Get the trace tready to check the other side and point and register the location
                data.DmRfract = (2 * target:BoundingRadius())
                data.VrDirect:Set(vdir)
                data.VrOrigin:Set(vdir)
                data.VrOrigin:Mul(data.DmRfract)
                data.VrOrigin:Add(trace.HitPos)
                LaserLib.VecNegate(data.VrDirect)
                -- LaserLib.DrawVector(data.VrOrigin, data.VrDirect, 10, "RED")
                -- Must trace only this entity otherwise invalid
                data.TeFilter = function(ent) return (ent == target) end
                data.NvIWorld = true -- Ignore world too for precision  ws
                data.IsRfract[1] = true -- Raise the bounce off refract flag
                data.BmTracew = DATA.TRWD -- Increase the beam width for back track
                data.TrRfract = (DATA.ERAD * data.DmRfract) -- Scale again to make it hit
                if(usrfre and data.TrMedium.D[1]) then
                  LaserLib.SetPowerRatio(data, data.TrMedium.D[1][2])
                end
              else -- We are neither reflecting nor refracting and have hit a wall
                data.IsTrace = false -- Make sure to exit not to do performance hit
                data.NvLength = data.NvLength - data.NvLength * trace.Fraction
              end -- All triggers when reflecting and refracting are processed
            end
          end
        end
      elseif(trace.HitWorld or data.IsRfract[2]) then
        if(data.IsRfract[2]) then
          data.IsRfract[2] = false
          local vdir, bout
          -- Well the beam is still tracing
          data.IsTrace = true -- Produce next ray
          -- Make sure that outer trace will always hit
          LaserLib.VecNegate(data.VrDirect)
          LaserLib.VecNegate(trace.HitNormal)
          if(data.TrMedium.D[1]) then
            vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                               trace.HitNormal,
                                               data.TrMedium.D[1][1],
                                               data.TrMedium.S[1][1])
            if(vdir) then
              data.VrDirect:Set(vdir)
              data.VrOrigin:Set(vdir)
              data.VrOrigin:Add(trace.HitPos)
              LaserLib.VecNegate(data.VrDirect)
            end
            if(usrfre) then
              LaserLib.SetPowerRatio(data, data.TrMedium.D[1][2])
            end
          end
        else
          if(class and DATA.ACTOR[class]) then
            local suc, err = pcall(DATA.ACTOR[class], trace, data)
            if(not suc) then data.IsTrace = false; error("Actor error: "..err) end
          else
            data.TrMaters = GetMaterialID(trace, data)
            data.IsTrace  = true -- Still tracing the beam
            local reflect = IndexMaterial(data.TrMaters, DATA.REFLECT)
            if(reflect) then -- Just call reflection and get done with it..
              data.VrDirect:Set(LaserLib.GetReflected(data.VrDirect, trace.HitNormal))
              data.VrOrigin:Set(trace.HitPos)
              data.NvLength = data.NvLength - data.NvLength * trace.Fraction
              if(usrfle) then
                LaserLib.SetPowerRatio(data, reflect[1])
              end
            else
              local refract, key = IndexMaterial(data.TrMaters, DATA.REFRACT)
              if(data.StRfract or (refract and key ~= data.TrMedium.S[2])) then -- Needs to be refracted
                -- Register desination medium and raise calculate refraction flag
                data.TrMedium.D = {refract, key}
                -- Substact traced lenght from total length
                data.NvLength = data.NvLength - data.NvLength * trace.Fraction
                data.TrRfract = data.NvLength
                -- Calculated refraction ray. Reflect when not possible
                if(data.StRfract) then
                  data.StRfract = false
                  data.VrDirect:Set(direct)
                  data.VrOrigin:Set(trace.HitPos)
                  data.NvMask = MASK_SOLID
                  data.TeFilter = nil
                  data.TrMedium.S = data.TrMedium.D
                else
                  if(data.TrMedium.D[1]) then -- From air to water
                    local vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                                             trace.HitNormal,
                                                             data.TrMedium.S[1][1],
                                                             data.TrMedium.D[1][1])
                    if(vdir) then -- Get the trace tready to check the other side and point and register the location
                      data.VrDirect:Set(vdir)
                      data.VrOrigin:Set(trace.HitPos)
                      data.TeFilter = nil -- Delete the filter so we can hit models in the water
                      data.NvMask   = MASK_SOLID -- Swap air and water for internal reflaection
                      data.TrMedium.S, data.TrMedium.D = data.TrMedium.D, data.TrMedium.S
                    end
                    if(usrfre) then
                      LaserLib.SetPowerRatio(data, data.TrMedium.S[1][2])
                    end
                  end
                end
              else -- We are neither reflecting nor refracting and have hit a wall
                data.IsTrace = false -- Make sure to exit not to do performance hit
                data.NvLength = data.NvLength - data.NvLength * trace.Fraction
              end -- All triggers when reflecting and refracting are processed
            end
          end
        end
      else
        data.IsTrace = false
        data.NvLength = data.NvLength - data.NvLength * trace.Fraction
      end
    else
      data.IsTrace = false
      data.NvLength = data.NvLength - data.NvLength * trace.Fraction
    end
  until(not data.IsTrace or data.NvBounce <= 0 or data.NvLength <= 0)

  if(data.NvLength < 0) then
    local top = data.TvPoints.Size
    local prv = data.TvPoints[top - 1][1]
    local nxt = data.TvPoints[top - 0][1]
    local dir = (nxt - prv); dir:Normalize()
    dir:Mul(data.NvLength); nxt:Add(dir)
    data.NvLength = 0; return nil, data
  end -- The beam ends inside transperent medium

  if(trace.Hit and data.RaLength > data.NvLength) then
    data.RaLength = data.RaLength - data.NvLength
  end

  if(LaserLib.IsUnit(entity)) then
    if(entity.SetHitReport) then
      -- Update the current beam source hit report
      -- This is done to know what we just hit
      entity:SetHitReport(trace, data, index)
    end -- Reduce indexing by using last target
    if(LaserLib.IsValid(target) and target.RegisterSource) then
      target:RegisterSource(entity) -- Register source entity
    end
  end

  return trace, data
end

function LaserLib.GetTerm(str, def)
  local str = tostring(str or "")
  local def = tostring(def or "")
        str = ((str == "") and def or str)
  return ((str == "") and DATA.NOAV or str)
end

function LaserLib.ComboBoxString(panel, convar, nameset)
  local unit = LaserLib.GetTool()
  local data = GetConVar(unit.."_"..convar):GetString()
  local base = language.GetPhrase("tool."..unit.."."..convar.."_con")
  local hint = language.GetPhrase("tool."..unit.."."..convar)
  local item, name = panel:ComboBox(base, unit.."_"..convar)
  item:SetTooltip(hint); name:SetTooltip(hint)
  item:SetSortItems(true); item:Dock(TOP); item:SetTall(22)
  for key, val in pairs(list.GetForEdit(nameset)) do
    local icon = LaserLib.GetIcon(val.icon)
    item:AddChoice(key, val.name, (data == val.name), icon)
  end
  item.DoRightClick = function(pnSelf)
    local sN = DATA.NOAV
    local vV = pnSelf:GetValue()
    local iD = pnSelf:GetSelectedID()
    local vT = pnSelf:GetOptionText(iD)
    SetClipboardText(LaserLib.GetTerm(vT, vV))
  end
  name.DoRightClick = function(pnSelf)
    SetClipboardText(pnSelf:GetValue())
  end
  return item, name
end

-- https://github.com/Facepunch/garrysmod/tree/master/garrysmod/resource/localization/en
function LaserLib.SetupComboBools()
  if(SERVER) then return end

  table.Empty(list.GetForEdit("LaserEmitterComboBools"))
  list.Set("LaserEmitterComboBools", "Empty", 0)
  list.Set("LaserEmitterComboBools", "False", 1)
  list.Set("LaserEmitterComboBools", "True" , 2)
end

function LaserLib.SetupMaterials()
  if(SERVER) then return end

  language.Add("laser.cable.crystal_beam1"   , "Crystal Beam Cable")
  language.Add("laser.cable.cable1"          , "Cable Class 1"     )
  language.Add("laser.cable.cable2"          , "Cable Class 2"     )
  language.Add("laser.effects.emptool"       , "Alyx EMP"          )
  language.Add("laser.splodearc.sheet"       , "Splodearc Sheet"   )
  language.Add("laser.warp.sheet"            , "Warp Sheet"        )
  language.Add("laser.ropematerial.redlaser" , "Rope Red Laser"    )
  language.Add("laser.ropematerial.blue_elec", "Rope Blue Electric")
  language.Add("laser.effects.redlaser1"     , "Red Laser Effect"  )

  table.Empty(list.GetForEdit("LaserEmitterMaterials"))
  list.Set("LaserEmitterMaterials", "#laser.cable.cable1"          , "cable/cable"                   )
  list.Set("LaserEmitterMaterials", "#laser.cable.cable2"          , "cable/cable2"                  )
  list.Set("LaserEmitterMaterials", "#laser.splodearc.sheet"       , "models/effects/splodearc_sheet")
  list.Set("LaserEmitterMaterials", "#laser.warp.sheet"            , "models/props_lab/warp_sheet"   )
  list.Set("LaserEmitterMaterials", "#ropematerial.xbeam"          , "cable/xbeam"                   )
  list.Set("LaserEmitterMaterials", "#laser.ropematerial.redlaser" , "cable/redlaser"                )
  list.Set("LaserEmitterMaterials", "#laser.ropematerial.blue_elec", "cable/blue_elec"               )
  list.Set("LaserEmitterMaterials", "#ropematerial.physbeam"       , "cable/physbeam"                )
  list.Set("LaserEmitterMaterials", "#ropematerial.hydra"          , "cable/hydra"                   )
  list.Set("LaserEmitterMaterials", "#laser.cable.crystal_beam1"   , "cable/crystal_beam1"           )
  list.Set("LaserEmitterMaterials", "#trail.plasma"                , "trails/plasma"                 )
  list.Set("LaserEmitterMaterials", "#trail.electric"              , "trails/electric"               )
  list.Set("LaserEmitterMaterials", "#trail.smoke"                 , "trails/smoke"                  )
  list.Set("LaserEmitterMaterials", "#trail.laser"                 , "trails/laser"                  )
  list.Set("LaserEmitterMaterials", "#laser.effects.emptool"       , "models/alyx/emptool_glow"      )
  list.Set("LaserEmitterMaterials", "#trail.love"                  , "trails/love"                   )
  list.Set("LaserEmitterMaterials", "#trail.lol"                   , "trails/lol"                    )
  list.Set("LaserEmitterMaterials", "#laser.effects.redlaser1"     , "effects/redlaser1"             )
end

function LaserLib.SetupModels()
  if(SERVER) then return end

  local data = {
    {"models/props_lab/tpplug.mdl"},
    {"models/hunter/plates/plate.mdl"},
    {"models/props_junk/flare.mdl",90},
    {"models/props_lab/jar01a.mdl",90},
    {"models/props_lab/jar01b.mdl",90},
    {"models/props_junk/popcan01a.mdl",90},
    {"models/props_c17/pottery01a.mdl",90},
    {"models/props_c17/pottery02a.mdl",90},
    {"models/props_c17/pottery03a.mdl",90},
    {"models/props_c17/pottery04a.mdl",90},
    {"models/props_c17/pottery05a.mdl",90},
    {"models/jaanus/thruster_flat.mdl",90},
    {"models/props_combine/breenlight.mdl",-90},
    {"models/props_junk/trafficcone001a.mdl",90},
    {"models/hunter/blocks/cube025x025x025.mdl"},
    {"models/props_phx2/garbage_metalcan001a.mdl",-90},
    {"models/props_combine/headcrabcannister01a_skybox.mdl",180}
  }

  if(IsMounted("portal")) then -- Portal
    table.insert(data, {"models/props_bts/rocket.mdl"})
    table.insert(data, {"models/props/cake/cake.mdl",90})
    table.insert(data, {"models/props/water_bottle/water_bottle.mdl",90})
    table.insert(data, {"models/props/turret_01.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(data, {"models/props_bts/projector.mdl",0,"1,-10,5","0,-1,0"})
    table.insert(data, {"models/props/laser_emitter.mdl",0,"29,0,-14","1,0,0"})
    table.insert(data, {"models/props/laser_emitter_center.mdl",0,"29,0,0","1,0,0"})
    table.insert(data, {"models/weapons/w_portalgun.mdl",0,"-20,-0.7,-0.3","-1,0,0"})
    table.insert(data, {"models/props_bts/glados_ball_reference.mdl",0,"0,15,0","0,1,0"})
    table.insert(data, {"models/props/pc_case02/pc_case02.mdl",0,"-0.2,2.4,-9.2","1,0,0"})
  end

  if(IsMounted("portal2")) then -- Portal 2
    table.insert(data, {"models/br_debris/deb_s8_cube.mdl"})
    table.insert(data, {"models/npcs/turret/turret.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(data, {"models/npcs/turret/turret_skeleton.mdl",0,"12,0,36.75","1,0,0"})
  end

  if(IsMounted("hl2")) then -- HL2
    table.insert(data, {"models/items/ar2_grenade.mdl"})
    table.insert(data, {"models/props_lab/huladoll.mdl",90})
    table.insert(data, {"models/weapons/w_missile_closed.mdl"})
    table.insert(data, {"models/weapons/w_missile_launch.mdl"})
    table.insert(data, {"models/props_c17/canister01a.mdl",90})
    table.insert(data, {"models/props_combine/weaponstripper.mdl"})
    table.insert(data, {"models/items/combine_rifle_ammo01.mdl",90})
    table.insert(data, {"models/props_borealis/bluebarrel001.mdl",90})
    table.insert(data, {"models/props_c17/canister_propane01a.mdl",90})
    table.insert(data, {"models/props_borealis/door_wheel001a.mdl",180})
    table.insert(data, {"models/items/combine_rifle_cartridge01.mdl",-90})
    table.insert(data, {"models/props_trainstation/trashcan_indoor001b.mdl",-90})
    table.insert(data, {"models/props_lab/reciever01b.mdl",0,"-7.12,-6.56,0.35","-1,0,0"})
    table.insert(data, {"models/props_c17/trappropeller_lever.mdl",0,"0,-6,-0.15","0,-1,0"})
  end

  if(IsMounted("dod")) then -- DoD
    table.insert(data, {"models/weapons/w_smoke_ger.mdl",-90})
  end

  if(IsMounted("ep2")) then -- HL2 EP2
    table.insert(data, {"models/props_junk/gnome.mdl",0,"-3,0.94,6","-1,0,0"})
  end

  if(IsMounted("cstrike")) then -- Counter-Strike Source
    table.insert(data, {"models/props/de_nuke/emergency_lighta.mdl",90})
  end

  if(IsMounted("left4dead")) then -- Left 4 Dead
    table.insert(data, {"models/props_unique/airport/line_post.mdl",90})
    table.insert(data, {"models/props_street/firehydrant.mdl",0,"-0.081,0.052,39.31","0,0,1"})
  end

  if(IsMounted("tf")) then -- Team Fortress 2
    table.insert(data, {"models/props_hydro/road_bumper01.mdl",90})
  end

  if(WireLib) then -- Make these model available only if the player has Wire
    table.insert(data, {"models/led2.mdl", 90})
    table.insert(data, {"models/venompapa/wirecdlock.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_siren.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_range.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_beamcaster.mdl", 90})
    table.insert(data, {"models/jaanus/wiretool/wiretool_grabber_forcer.mdl", 90})
  end

  -- Automatic data population. Add models in the list above
  table.Empty(list.GetForEdit("LaserEmitterModels"))
  for idx = 1, #data do
    local rec = data[idx]
    local mod = tostring(rec[1] or "")
    local ang = (tonumber(rec[2]) or 0)
    local org = tostring(rec[3] or "")
    local dir = tostring(rec[4] or "")
    table.Empty(rec)
    rec[DATA.TOOL.."_model" ] = mod
    rec[DATA.TOOL.."_angle" ] = ang
    rec[DATA.TOOL.."_origin"] = org
    rec[DATA.TOOL.."_direct"] = dir
    list.Set("LaserEmitterModels", mod, rec)
  end
end

-- http://www.famfamfam.com/lab/icons/silk/preview.php
function LaserLib.SetupDissolveTypes()
  if(SERVER) then return end

  language.Add("dissolvetype.energy"       , "AR2 style")
  language.Add("dissolvetype.heavyelectric", "Heavy electrical")
  language.Add("dissolvetype.lightelectric", "Light electrical")
  language.Add("dissolvetype.core"         , "Core Effect")

  table.Empty(list.GetForEdit("LaserDissolveTypes"))
  list.Set("LaserDissolveTypes", "#dissolvetype.energy"       , {name = "energy"   , icon = "lightning"})
  list.Set("LaserDissolveTypes", "#dissolvetype.heavyElectric", {name = "heavyelec", icon = "joystick" })
  list.Set("LaserDissolveTypes", "#dissolvetype.lightElectric", {name = "lightelec", icon = "package"  })
  list.Set("LaserDissolveTypes", "#dissolvetype.core"         , {name = "core"     , icon = "ruby"     })
end

function LaserLib.SetupSoundEffects()
  if(SERVER) then return end

  language.Add("sound.none"              , "None")
  language.Add("sound.alyxemp"           , "Alyx EMP")
  language.Add("sound.weld1"             , "Weld 1")
  language.Add("sound.weld2"             , "Weld 2")
  language.Add("sound.electricexplosion1", "Electric Explosion 1")
  language.Add("sound.electricexplosion2", "Electric Explosion 2")
  language.Add("sound.electricexplosion3", "Electric Explosion 3")
  language.Add("sound.electricexplosion4", "Electric Explosion 4")
  language.Add("sound.electricexplosion5", "Electric Explosion 5")
  language.Add("sound.disintegrate1"     , "Disintegrate 1")
  language.Add("sound.disintegrate2"     , "Disintegrate 2")
  language.Add("sound.disintegrate3"     , "Disintegrate 3")
  language.Add("sound.disintegrate4"     , "Disintegrate 4")
  language.Add("sound.zapper"            , "Zapper")

  table.Empty(list.GetForEdit("LaserSounds"))
  list.Set("LaserSounds", "#sound.none"              , "")
  list.Set("LaserSounds", "#sound.alyxemp"           , "AlyxEMP.Charge")
  list.Set("LaserSounds", "#sound.weld1"             , "ambient/energy/weld1.wav")
  list.Set("LaserSounds", "#sound.weld2"             , "ambient/energy/weld2.wav")
  list.Set("LaserSounds", "#sound.electricexplosion1", "ambient/levels/labs/electric_explosion1.wav")
  list.Set("LaserSounds", "#sound.electricexplosion2", "ambient/levels/labs/electric_explosion2.wav")
  list.Set("LaserSounds", "#sound.electricexplosion3", "ambient/levels/labs/electric_explosion3.wav")
  list.Set("LaserSounds", "#sound.electricexplosion4", "ambient/levels/labs/electric_explosion4.wav")
  list.Set("LaserSounds", "#sound.electricexplosion5", "ambient/levels/labs/electric_explosion5.wav")
  list.Set("LaserSounds", "#sound.disintegrate1"     , "ambient/levels/citadel/weapon_disintegrate1.wav")
  list.Set("LaserSounds", "#sound.disintegrate2"     , "ambient/levels/citadel/weapon_disintegrate2.wav")
  list.Set("LaserSounds", "#sound.disintegrate3"     , "ambient/levels/citadel/weapon_disintegrate3.wav")
  list.Set("LaserSounds", "#sound.disintegrate4"     , "ambient/levels/citadel/weapon_disintegrate4.wav")
  list.Set("LaserSounds", "#sound.zapper"            , "ambient/levels/citadel/zapper_warmup1.wav")

  table.Empty(list.GetForEdit("LaserStartSounds"))
  table.Empty(list.GetForEdit("LaserStopSounds"))
  table.Empty(list.GetForEdit("LaserKillSounds"))
  for key, val in pairs(list.Get("LaserSounds")) do
    list.Set("LaserStartSounds", key, {name = val, icon = "sound_add"   })
    list.Set("LaserStopSounds" , key, {name = val, icon = "sound_delete"})
    list.Set("LaserKillSounds" , key, {name = val, icon = "sound_mute"  })
  end

  table.Empty(list.GetForEdit("LaserSounds"))
end
