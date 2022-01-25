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
DATA.MFORCELM = CreateConVar("laseremitter_maxforclim", 25000, DATA.FGSRVCN, "Maximum force limit available to the welds", 0, 50000)
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
DATA.NUGE = 2               -- Nuge amount for origin vectors back-tracing
DATA.MINW = 0.05            -- Mininum width to be considered visible
DATA.DOTM = 0.01            -- Colinearity and dot prodic margin check
DATA.POWL = 0.001           -- Lowest bounds of laser power
DATA.ERAD = 1.12            -- Entity refract coefficient for back trace origins
DATA.TRWD = 0.27            -- Beam backtrace trace width when refracting
DATA.WLMR = 10000           -- World vectors to be correctly conveted to local
DATA.TRWU = 50000           -- The amount of units to trace for finding water surface
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
DATA.VTEMP = Vector()
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
  {"gmod_laser_divider"  , "divider"  , nil      }, -- Laser beam divider `DoBeam`
  {"gmod_laser_sensor"   , "sensor"   , nil      }, -- Laser beam sensor `ActionSource`
  {"gmod_laser_dimmer"   , "dimmer"   , nil      }, -- Laser beam divide `DoBeam`
  {"gmod_laser_splitterm", "splitterm", "splitrm"}, -- Laser beam splitter multy `ActionSource`
  {"gmod_laser_portal"   , "portal"   , nil      }, -- Laser beam portal  `DoBeam`
  {"gmod_laser_parallel" , "parallel" , "paralel"}  -- Laser beam parallel `DoBeam`
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
  ["BACKGND"] = Color(150, 150, 255, 180),
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
  [4] = "white"  , -- All general white paint
  [5] = "metal"  , -- All shiny metal reflect
  -- Used for prop updates and checks
  [DATA.KEYD]                            = "debug/env_cubemap_model",
  -- User for general class control
  -- [1] : Surface reflection index for the material specified
  -- [2] : Which index is the materil found at when it is searched in array part
  [""]                                   = false, -- Disable empty materials
  ["**empty**"]                          = false, -- Disable empty world materials
  ["**studio**"]                         = false, -- Disable empty prop materials
  ["cubemap"]                            = {0.999, "cubemap"},
  ["chrome"]                             = {0.955, "chrome" },
  ["shiny"]                              = {0.854, "shiny"  },
  ["white"]                              = {0.342, "white"  },
  ["metal"]                              = {0.045, "metal"  },
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
  -- Used for prop updates and checks
  [DATA.KEYD]                                   = "models/props_combine/health_charger_glass",
  -- User for general class control
  -- [1] : Medium refraction index for the material specified
  -- [2] : Medium refraction rating when the beam goes trough reduces its power
  -- [3] : Which index is the materil found at when it is searched in array part
  [""]                                          = false, -- Disable empty materials
  ["**empty**"]                                 = false, -- Disable empty world materials
  ["**studio**"]                                = false, -- Disable empty prop materials
  ["air"]                                       = {1.000, 1.000, "air"  }, -- Air refraction index
  ["glass"]                                     = {1.521, 0.999, "glass"}, -- Ordinary glass
  ["water"]                                     = {1.333, 0.955, "water"}, -- Water refraction index
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
  ["models/props_combine/citadel_cable"]        = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/citadel_cable_b"]      = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/pipes01"]              = {1.583, 0.761}, -- Dark glass other
  ["models/props_combine/pipes03"]              = {1.583, 0.761}, -- Dark glass other
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

DATA.WORLD = game.GetWorld()

if(CLIENT) then
  DATA.HOVM = Material("gui/ps_hover.png", "nocull")
  DATA.HOVB = GWEN.CreateTextureBorder(0, 0, 64, 64, 8, 8, 8, 8, DATA.HOVM)
  DATA.HOVP = function(pM, iW, iH) DATA.HOVB(0, 0, iW, iH, DATA.COLOR["WHITE"]) end
end

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

--[[
 * Performs CAP dedicated traces. Will return result
 * only when CAP hits its dedicated entities
 * origin > Trace origin as world position vector
 * direct > Trace direction as world aim vector
 * length > Trace length in source units
 * filter > Trace filter as standard config
 * https://github.com/RafaelDeJongh/cap/blob/master/lua/stargate/shared/tracelines.lua
]]
local function TraceCAP(origin, direct, length, filter)
  if(StarGate ~= nil) then
    DATA.TRACE.start:Set(origin)
    DATA.TRACE.endpos:Set(direct)
    DATA.TRACE.endpos:Normalize()
    if(not (length and length > 0)) then
      length = direct:Length()
    end -- Use proper length even if missing
    DATA.TRACE.endpos:Mul(length)
    local tr = StarGate.Trace:New(DATA.TRACE.start, DATA.TRACE.endpos, filter);
    if(StarGate.Trace.Entities[tr.Entity]) then return tr end
    -- If CAP specific entity is hit return and override the trace
  end; return nil -- Otherwise use the reglar trace for refraction control
end

--[[
 * Performs general traces according to the parameters passed
 * origin > Trace origin as world position vector
 * direct > Trace direction as world aim vector
 * length > Trace length in source units
 * filter > Trace filter as standard config
 * mask   > Trace mask as standard config
 * colgrp > Trace collision group as standard config
 * iworld > Trace ignore world as standard config
 * width  > When larger than zero will run a hull trace instead
 * result > Trace output destination table as standard config
]]
local function TraceBeam(origin, direct, length, filter, mask, colgrp, iworld, width, result)
  DATA.TRACE.start:Set(origin)
  DATA.TRACE.endpos:Set(direct)
  DATA.TRACE.endpos:Normalize()
  if(not (length and length > 0)) then
    length = direct:Length()
  end -- Use proper length even if missing
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
  if(not arg.IsValid) then return false end
  return arg:IsValid()
end

--[[
 * This setups the beam kill crediting
 * Updates the kill credit player for specific entity
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
 * This is used to time a given code sippet when debugging
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

-- Draw a position on the screen
function LaserLib.DrawPoint(pos, col, idx, msg)
  if(SERVER) then return end
  local crw = LaserLib.GetColor(col or "YELLOW")
  render.SetColorMaterial()
  render.DrawSphere(pos, 0.5, 25, 25, crw)
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
  if(SERVER) then return end
  local ven = pos + (dir * (tonumber(mag) or 1))
  local crw = LaserLib.GetColor(col or "YELLOW")
  render.SetColorMaterial()
  render.DrawSphere(pos, 0.5, 25, 25, crw)
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

--[[
 * Creates ordered sequence set for use with
 * The `Type` key is last and not mandaory
 * It is used for materials found with indexing match
 * https://wiki.facepunch.com/gmod/table.sort
]]
function LaserLib.GetSequence(set)
  local ser, inf, row = {Size = 0}
  if(set == DATA.REFLECT) then
    inf = {"Rate", "Type", Size = 2}
  elseif(set == DATA.REFRACT) then
    inf = {"Ridx", "Rate", "Type", Size = 3}
  else -- Otherwise raise error!
    error("Sequence different!")
  end -- Sequential table created
  for key, val in pairs(set) do
    if(type(val) == "table" and tostring(key):find("/")) then
      row = {Key = key, Draw = true}
      ser.Size = table.insert(ser, row)
      for iD = 1, inf.Size do row[inf[iD]] = val[iD] end
    end -- Store info and return table
  end
  ser.Info = inf; return ser
end

function LaserLib.GetSequenceInfo(row, info)
  local res = "" -- Temporary storage
  for iD = 1, info.Size do local dat = row[info[iD]]
    if(dat) then res = res.."|"..tostring(dat) end
  end; return "{"..res:sub(2, -1).."}"
end

function LaserLib.SetMaterialSize(pnMat, iRow)
  if(SERVER) then return end
  local scrW = surface.ScreenWidth()
  local scrH = surface.ScreenHeight()
  local nRat = LaserLib.GetData("GRAT")
  local nRaw, nRah = (scrW / nRat), (scrH / nRat)
  local iW = (((nRaw - 2*3 - 1) / iRow) / nRaw)
  local iH = (((nRah - 2*3 - 1) / iRow) / nRah)
  pnMat:SetItemWidth(iW)
  pnMat:SetItemHeight(iH)
end

function LaserLib.ClearMaterials(pnMat)
  if(SERVER) then return end
  -- Clear all entries from the list
  for key, val in pairs(pnMat.Controls) do
    val:Remove(); pnMat.Controls[key] = nil
  end -- Remove all rermaining image panels
  pnMat.List:CleanList()
  pnMat.SelectedMaterial = nil
  pnMat.OldSelectedPaintOver = nil
end

function LaserLib.SetMaterialPaintOver(pnMat, pnImg)
  if(SERVER) then return end
  -- Remove the current overlay
  if(pnMat.SelectedMaterial) then
    pnMat.SelectedMaterial.PaintOver = pnMat.OldSelectedPaintOver
  end
  -- Add the overlay to this button
  pnMat.OldSelectedPaintOver = pnImg.PaintOver
  pnImg.PaintOver = DATA.HOVP
  pnMat.SelectedMaterial = pnImg
end

function LaserLib.UpdateMaterials(pnFrame, pnMat, data)
  if(SERVER) then return end
  local sTool = LaserLib.GetTool()
  -- Clear Material selection content
  LaserLib.ClearMaterials(pnMat)
  -- Read the controls tabe and craete index
  local tCont, iC = pnMat.Controls, 0
  -- Update material panel with ordered values
  for iD = 1, data.Size do
    local tRow, pnImg = data[iD]
    if(tRow.Draw) then -- Drawing is enabled
      local sCon = LaserLib.GetSequenceInfo(tRow, data.Info)
      local sInf, sKey = sCon.." "..tRow.Key, tRow.Key
      pnMat:AddMaterial(sInf, sKey); iC = iC + 1; pnImg = tCont[iC]
      pnImg.DoClick = function(pnBut)
        LaserLib.SetMaterialPaintOver(pnMat, pnBut)
        LaserLib.ConCommand(nil, data.Sors, sKey)
        pnFrame:SetTitle(data.Name.." > "..sInf)
      end
      pnImg.DoRightClick = function(pnBut)
        local pnMenu = DermaMenu(false, pnFrame)
        if(not IsValid(pnMenu)) then return end
        pnMenu:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_cmat"),
          function() SetClipboardText(sKey) end):SetImage(LaserLib.GetIcon("page_copy"))
        pnMenu:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_cset"),
          function() SetClipboardText(sCon) end):SetImage(LaserLib.GetIcon("page_copy"))
        pnMenu:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_call"),
          function() SetClipboardText(sInf) end):SetImage(LaserLib.GetIcon("page_copy"))
        -- Attach sub-menu to the menu items
        local pSort, pOpts = pnMenu:AddSubMenu(language.GetPhrase("tool."..sTool..".openmaterial_sort"))
        if(not IsValid(pSort)) then return end
        if(not IsValid(pOpts)) then return end
        pOpts:SetImage(LaserLib.GetIcon("table_sort"))
        -- Sort data by the entry key
        if(tRow.Key) then
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find1").." (<)",
            function()
              table.SortByMember(data, "Key", true)
              LaserLib.UpdateMaterials(pnFrame, pnMat, data)
            end):SetImage(LaserLib.GetIcon("arrow_down"))
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find1").." (>)",
            function()
              table.SortByMember(data, "Key", false)
              LaserLib.UpdateMaterials(pnFrame, pnMat, data)
            end):SetImage(LaserLib.GetIcon("arrow_up"))
        end
        -- Sort data by the absorbtion rate
        if(tRow.Rate) then
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find2").." (<)",
            function()
              table.SortByMember(data, "Rate", true)
              LaserLib.UpdateMaterials(pnFrame, pnMat, data)
            end):SetImage(LaserLib.GetIcon("basket_remove"))
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find2").." (>)",
            function()
              table.SortByMember(data, "Rate", false)
              LaserLib.UpdateMaterials(pnFrame, pnMat, data)
            end):SetImage(LaserLib.GetIcon("basket_put"))
        end
        -- Sort data by the medium refraction index
        if(tRow.Ridx) then
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find3").." (<)",
            function()
              table.SortByMember(data, "Ridx", true)
              LaserLib.UpdateMaterials(pnFrame, pnMat, data)
            end):SetImage(LaserLib.GetIcon("ruby_get"))
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find3").." (>)",
            function()
              table.SortByMember(data, "Ridx", false)
              LaserLib.UpdateMaterials(pnFrame, pnMat, data)
            end):SetImage(LaserLib.GetIcon("ruby_put"))
        end
        pnMenu:Open()
      end
      -- When the variable value is the same as the key
      if(sKey == data.Conv:GetString()) then
        pnFrame:SetTitle(data.Name.." > "..sInf)
        LaserLib.SetMaterialPaintOver(pnMat, pnImg)
      end
    end
  end
end

function LaserLib.Call(time, func, ...)
  local tnew = SysTime()
  if((tnew - DATA.TOLD) > time)
    then func(...); DATA.TOLD = tnew end
end

--[[
 * Creates welds between laser and base
 * Applies and controls surface weld flag
 * weld  > Surface weld flag
 * laser > Laser entity to be welded
 * trace > Trace enity to be welded or world
]]
function LaserLib.Weld(laser, trace, weld, noco, flim)
  if(not LaserLib.IsValid(laser)) then return nil end
  local tren, bone = trace.Entity, trace.PhysicsBone
  local eval = (LaserLib.IsValid(tren) and not tren:IsWorld())
  local anch, encw, encn = (eval and tren or game.GetWorld())
  if(weld) then
    local lmax = DATA.MFORCELM:GetFloat()
    local flim = math.Clamp(tonumber(flim) or 0, 0, lmax)
    encw = constraint.Weld(laser, anch, 0, bone, flim)
    if(LaserLib.IsValid(encw)) then
      laser:DeleteOnRemove(encw) -- Remove the weld with the laser
      if(eval) then anch:DeleteOnRemove(encw) end
    end
  end
  if(noco and eval) then -- Otherwise falls trough the ground
    encn = constraint.NoCollide(laser, anch, 0, bone)
    if(LaserLib.IsValid(encn)) then
      laser:DeleteOnRemove(encn) -- Remove the NC with the laser
      anch:DeleteOnRemove(encn)
    end -- Skip no-collide when world is anchor
  end; return encw, encn -- Do not call this for the world
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
 * Calculates the refract interface border angle
 * between two mediuims. Returns angles in range
 * from (-pi/2) to (pi/2)
 * source > Source refraction index
 * destin > Destination refraction index
 * bdegr  > Return the result in degrees
]]
function LaserLib.GetRefractAngle(source, destin, bdegr)
  local mar = source / destin -- Calculate ratio
  if(math.abs(mar) > 1) then mar = 1 / mar end
  local arg = math.asin(mar) -- Calculate sine argument
  if(bdegr) then arg = math.deg(arg) end
  return arg -- The medium border angle
end

--[[
 * https://en.wikipedia.org/wiki/Refraction
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
  local inc = direct:GetNormalized() -- Read normalized copy os incident
  if(source == destin) then return inc, true end -- Continue out medium
  local nrm = Vector(normal) -- Always normalized. Call copy-constructor
  local vcr = inc:Cross(LaserLib.VecNegate(nrm)) -- Sine: |i||n|sin(i^n)
  local ang, sii = nrm:AngleEx(vcr), vcr:Length()
  local mar = (sii * source) / destin -- Apply Snell's law
  if(math.abs(mar) <= 1) then -- Valid angle available
    local sio, aup = math.asin(mar), ang:Up()
    ang:RotateAroundAxis(aup, -math.deg(sio))
    return ang:Forward(), true -- Make refraction
  else -- Reflect from medum interface boundary
    return LaserLib.GetReflected(direct, normal), false
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
  local key  = "laseremitter_material"
  ent:SetMaterial(data.MaterialOverride)
  duplicator.StoreEntityModifier(ent, key, data)
end

function LaserLib.SetProperties(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local phy = ent:GetPhysicsObject()
  if(not LaserLib.IsValid(phy)) then return end
  local data = {Material = tostring(mat or "")}
  local key  = "laseremitter_properties"
  construct.SetPhysProp(nil, ent, 0, phy, data)
  duplicator.StoreEntityModifier(ent, key, data)
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
 * Cashes the request issued for index material
 * mat > Direct material to check for. Missing uses `ent`
 * set > The dedicated parameeters setting to check
 * Returns: Material entry from the given set
]]
local function GetMaterialEntry(mat, set)
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
    if(mat:find(key, 1, true)) then -- Cache the material
      set[mat] = set[key] -- Cache rhe material found
      return set[mat], key -- Compare the entry
    end -- Read and compare the next entry
  end; set[mat] = false -- Undefined material
  return nil -- Return nothing when not found
end

--[[
 * Searches for a material in the definition set
 * When material is not passed returns the default
 * When material is passed indexes and returns it
]]
local function GetInteractIndex(iK, set)
  if(iK == DATA.KEYA) then return set end
  if(not iK) then return set[DATA.KEYD] end
  return set[iK] -- Index the row
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
    laser:SetCreator(user)
    laser:Setup(width       , length     , damage     , material    ,
                dissolveType, startSound , stopSound  , killSound   ,
                runToggle   , startOn    , pushForce  , endingEffect, trandata,
                reflectRate , refractRate, forceCenter, enOverMater , rayColor, false)

    local phys = laser:GetPhysicsObject()
    if(LaserLib.IsValid(phys)) then
      phys:EnableMotion(not frozen)
    end

    numpad.OnUp  (user, key, "Laser_Off", laser)
    numpad.OnDown(user, key, "Laser_On" , laser)

    -- Setup the laser kill crediting
    LaserLib.SetPlayer(laser, user)

    -- These do not change when laser is updated
    table.Merge(laser:GetTable(), {key = key, frozen = frozen})

    return laser
  end
elseif(CLIENT) then
  surface.CreateFont("LaserMedium",{
    font = "Arial", size = 28,
    weight = 600
  })
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
local function GetBeamPortal(base, exit, origin, direct, forigin, fdirect)
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

local mtBeam = {} -- Object metatable for class methods
      mtBeam.__type  = "BeamData" -- Store class type here
      mtBeam.__index = mtBeam -- If not found in self search here
      mtBeam.__vtemp = Vector() -- Temprary calculation vector object
      mtBeam.A = {DATA.REFRACT["air"  ], "air"  } -- General air info
      mtBeam.W = {DATA.REFRACT["water"], "water"} -- General water info
      mtBeam.F = function(ent) return (ent == DATA.WORLD) end
      mtBeam.__water = {
        P = Vector(), -- Water surface plane position
        N = Vector(), -- Water surface plane normal ( used also for trigger )
        D = Vector(), -- Water surface plane temporary direction vector
        M = 0, -- The value of the temporary dot product margin
        K = {["water"] = true} -- Fast water texture hash matching
      }
local function Beam(origin, direct, width, damage, length, force)
  local self = {}; setmetatable(self, mtBeam)
  self.TrMedium = {} -- Contains information for the mediums being traversed
  self.TvPoints = {Size = 0} -- Create empty vertices array for the client
  self.MxBounce = DATA.MBOUNCES:GetInt() -- All the bounces the loop made so far
  self.TrMedium.S = {mtBeam.A[1], mtBeam.A[2]} -- Source beam
  self.TrMedium.D = {mtBeam.A[1], mtBeam.A[2]}
  self.TrMedium.M = {mtBeam.A[1], mtBeam.A[2], Vector()}
  self.VrOrigin = Vector(origin) -- Copy origin not to modify it
  self.VrDirect = direct:GetNormalized() -- Copy deirection not to modify it
  self.BmLength = math.max(tonumber(length) or 0, 0) -- Initial start beam length
  self.NvDamage = math.max(tonumber(damage) or 0, 0) -- Initial current beam damage
  self.NvWidth  = math.max(tonumber(width ) or 0, 0) -- Initial current beam width
  self.NvForce  = math.max(tonumber(force ) or 0, 0) -- Initial current beam force
  self.StRfract = false -- Start tracing the beam inside a boundary
  self.IsTrace  = true -- Library is still tracing the beam
  self.TrFActor = false -- Trace filter was updated by actor and must be cleared
  self.DmRfract = 0 -- Diameter trace-back dimensions of the entity
  self.TrRfract = 0 -- Full length for traces not being bound by hit events
  self.BmTracew = 0 -- Make sure beam is zero width during the initial trace hit
  self.NvIWorld = false -- Ignore world flag to make it hit the other side
  self.IsRfract = false -- The beam is refracting inside and entity or world solid
  self.NvMask   = MASK_ALL -- Trace mask. When not provided negative one is used
  self.NvCGroup = COLLISION_GROUP_NONE -- Collision group. Missing then COLLISION_GROUP_NONE
  self.NvBounce = self.MxBounce -- Amount of bounces to control the infinite loop
  self.RaLength = self.BmLength -- Range of the length. Just like wire ranger
  self.NvLength = self.BmLength -- The actual beam lengths substracted after iterations
  return self
end

--[[
 * Checks when water base medium is not activated
]]
function mtBeam:IsAir()
  local wat = self.__water
  return wat.N:IsZero()
end

--[[
 * Clears the water surface normal
]]
function mtBeam:ClearWater()
  self.__water.N:Zero()
  return self -- Coding effective API
end

--[[
 * Issues a finish command to the traced laser beam
 * trace > Trace structure of the current iteration
]]
function mtBeam:Bounce()
  -- We are neither hitting something nor still tracing or hit dedicated entity
  self.NvBounce = self.NvBounce - 1 -- Refresh medium pass trough information
  return self -- Coding effective API
end

--[[
 * Cecks the condition for the beam loop to terminate
 * Returns boolean when the beam must continue
]]
function mtBeam:IsFinish()
  return (not self.IsTrace or
              self.NvBounce <= 0 or
              self.NvLength <= 0)
end

--[[
 * Cecks whenever the beam runs the first iteration
 * Returns boolean when the beam runs the first iteration
]]
function mtBeam:IsFirst()
  return (self.NvBounce == self.MxBounce)
end

--[[
 * Issues a finish command to the traced laser beam
 * trace > Trace structure of the current iteration
]]
function mtBeam:Finish(trace)
  self.IsTrace = false -- Make sure to exit not to do performance hit
  self.NvLength = self.NvLength - self.NvLength * trace.Fraction
  return self -- Coding effective API
end

--[[
 * Nudges and adjusts the temporary vector
 * using the direction and origin with a margin
 * Returns the adjusted temporary
 * margn > Marging to adjust the temporary with
]]
function mtBeam:GetNudge(margn)
  local vtm = self.__vtemp
  vtm:Set(self.VrDirect); vtm:Mul(margn)
  vtm:Add(self.VrOrigin); return vtm
end

--[[
 * Checks whenever the given position is located
 * above or below the water plane defined in `__water`
 * pos > World-space position to be checked
]]
function mtBeam:IsWater(pos)
  local wat = self.__water
  if(not pos) then return wat.F end
  wat.D:Set(pos); wat.D:Sub(wat.P)
  wat.M = wat.D:Dot(wat.N)
  wat.F = (wat.M < 0)
  return wat.F
end


--[[
 * Checks for memory refraction start-refract
 * from the last medum stored in memory and
 * ignores the beam start entity. Checks when
 * the given position is inside the beam source
]]
function mtBeam:IsMemory(index, pos)
  local sent = self.BmSource
  local vmin = sent:OBBMins()
  local vmax = sent:OBBMaxs()
  local vpos = sent:WorldToLocal(pos)
  local bent = vpos:WithinAABox(vmax, vmin)
  return ((index ~= self.TrMedium.M[1][1]) and not bent)
end

--[[
 * Changes the source medium. Source is the medium that
 * surrounds all objects and acts line their environment
 * origin > Beam exit position
 * direct > Beam exit direction
]]
function mtBeam:SetMediumSours(medium, key)
  if(key) then
    self.TrMedium.S[1] = medium -- Apply medium info
    self.TrMedium.S[2] = key    -- Apply medium key
  else
    self.TrMedium.S[1] = medium[1] -- Apply medium info
    self.TrMedium.S[2] = medium[2] -- Apply medium key
  end
  return self -- Coding effective API
end

--[[
 * Changes the source medium. Source is the medium that
 * surrounds all objects and acts line their environment
 * origin > Beam exit position
 * direct > Beam exit direction
]]
function mtBeam:SetMediumDestn(medium)
  if(key) then
    self.TrMedium.D[1] = medium -- Apply medium info
    self.TrMedium.D[2] = key    -- Apply medium key
  else
    self.TrMedium.D[1] = medium[1] -- Apply medium info
    self.TrMedium.D[2] = medium[2] -- Apply medium key
  end
  return self -- Coding effective API
end

--[[
 * Changes the source medium. Source is the medium that
 * surrounds all objects and acts line their environment
 * origin > Beam exit position
 * direct > Beam exit direction
]]
function mtBeam:SetMediumMemory(medium, key, normal)
  if(key) then
    self.TrMedium.M[1] = medium -- Apply medium info
    self.TrMedium.M[2] = key    -- Apply medium key
  else
    self.TrMedium.M[1] = medium[1] -- Apply medium info
    self.TrMedium.M[2] = medium[2] -- Apply medium key
  end
  if(normal) then
    self.TrMedium.M[3]:Set(normal)
  end
  return self -- Coding effective API
end

--[[
 * Intersects line (start, end) with a plane (position, normal)
 * This can be called then beam goes out of the water
 * To straight caluculate the intersection pont
 * this will ensure no overhead traces will be needed.
 * pos > Plane position as vector in 3D space
 * nor > Plane normal as world direction vector
 * org > Ray start origin position (trace.HitPos)
 * dir > Ray direction world vector (trace.Normal)
]]
function mtBeam:IntersectRayPlane(pos, nor, org, dir)
  local org = (org or self.VrOrigin)
  local dir = (dir or self.VrDirect)
  if(dir:Dot(nor) == 0) then return nil end
  local vop = Vector(pos); vop:Sub(org)
  local dst = vop:Dot(nor) / dir:Dot(nor)
  vop:Set(dir); vop:Mul(dst); vop:Add(org)
  return vop -- Water-air intersextion point
end

--[[
 * Clears configuration parameters for trace medium
 * origin > Beam exit position
 * direct > Beam exit direction
]]
function mtBeam:Redirect(origin, direct, reset)
  -- Appy origin and direction when beam exits the medium
  if(origin) then self.VrOrigin:Set(origin) end
  if(direct) then self.VrDirect:Set(direct) end
  -- Lower the refraction flag ( Not full internal reflection )
  if(reset) then
    self.BmTracew = 0 -- Use zero width beam traces
    self.NvIWorld = false -- Revert ignoring world
    self.IsRfract = false -- Has to stop refracting
    -- Restore the filter and hit world for tracing something else
    self.TeFilter = nil -- We prepare to hit something else anyway
    self.StRfract = false -- We are changing mediums and refraction is complete
  end; return self -- Coding effective API
end

--[[
 * Updates the hit texture if the trace contents
 * index > Texture index relative to DATA.REFRACT[ID]
 * trace > Trace structure of the current iteration
]]
function mtBeam:SetRefractContent(index, trace)
  local name = DATA.REFRACT[index]
  if(not name) then return self end
  trace.Fraction = 0
  trace.HitTexture = name
  self.TrMedium.S[2] = name
  self.TrMedium.S[1] = DATA.REFRACT[name]
  trace.HitPos:Set(self.VrOrigin)
  return self -- Coding effective API
end

--[[
 * Account for the trace width cube half diagonal
 * trace  > Trace result to be modified
 * length > Actual iteration beam length
]]
function mtBeam:SetTraceWidth(trace, length)
  if(trace and  -- Check if the trace is available
     trace.Hit and -- Trace must hit something
     self.IsRfract and -- Library must be refracting
     self.BmTracew and -- Beam width is available
     self.BmTracew > 0) then -- Beam width is present
    local vtm = self.__vtemp; vtm:Set(trace.HitNormal)
    vtm:Mul(-DATA.TRDG * self.BmTracew); trace.HitPos:Add(vtm)
  end -- At this point we know exacly how long will the trace be
  -- In this case the value of node regster length is calculated
  trace.LengthBS = length -- Acctual beam requested length
  trace.LengthFR = length * trace.Fraction -- Length fraction
  trace.LengthLS = length * trace.FractionLeftSolid -- Length fraction LS
  trace.LengthNR = self.IsRfract and (self.DmRfract - trace.LengthFR) or nil
  return trace
end

--[[
 * Beam traverses from medium [1] to medium [2]
 * origin > The node position to be registered
 * nbulen > Update the length according to the new node
 *          Positove number when provided else internal length
 *          Pass true boolean to update the node with distance
 * bedraw > Enable draw beam node on the CLIENT
 *          Use this for portals when skip gap is needed
]]
function mtBeam:RegisterNode(origin, nbulen, bedraw)
  local info = self.TvPoints -- Local reference to stack
  local node, width = Vector(origin), self.NvWidth
  local damage, force = self.NvDamage , self.NvForce
  local bedraw = (bedraw or bedraw == nil) and true or false
  local cnlen = math.max((tonumber(nbulen) or 0), 0)
  if(cnlen > 0) then -- Substract the path trough the medium
    self.NvLength = self.NvLength - cnlen -- Direct length
  else local size = info.Size -- Read the node stack size
    if(size > 0 and nbulen) then -- Length is not provided
      local prev, vtmp = info[size][1], self.__vtemp
      vtmp:Set(node); vtmp:Sub(prev) -- Relative to previous
      self.NvLength = self.NvLength - vtmp:Length()
    end -- Use the nodes and make sure previos exists
  end -- Register the new node to the stack
  info.Size = table.insert(info, {node, width, damage, force, bedraw})
  return self -- Coding effective API
end

--[[
 * Setups the beam power ratio when requested for the last
 * node on the stack. Applies power ratio and calculates
 * whenever the total beam is absorbed to be stopped
 * Returns node reference indexed internally and current power
 * rate   > The ratio to apply on the last node
]]
function mtBeam:SetPowerRatio(rate)
  local size = self.TvPoints.Size
  local node = self.TvPoints[size]
  if(rate) then -- There is sanity with adjusting the stuff
    self.NvDamage = rate * self.NvDamage
    self.NvForce  = rate * self.NvForce
    self.NvWidth  = LaserLib.GetWidth(rate * self.NvWidth)
    -- Update the parameters used for drawing the beam trace
    node[2] = self.NvWidth -- Adjusts visuals for width
    node[3] = self.NvDamage -- Adjusts visuals for damage
    node[4] = self.NvForce -- Adjusts visuals for force
  end -- Check out power rankings so the trace absorbed everything
  local power = LaserLib.GetPower(self.NvWidth, self.NvDamage)
  if(power < DATA.POWL) then self.IsTrace = false end -- Absorbs remaining light
  return node, power -- It is indexed anyway then return it to the caller
end

--[[
 * Checks whenever the last node location
 * belongs on the laser beam. Adjusts if not
]]
function mtBeam:IsNode()
  if(self.NvLength >= 0) then return true end
  local set = self.TvPoints -- Set of nodes
  local siz = set.Size -- Read stack size
  if(siz < 2) then return true end -- Exit
  local vtm = self.__vtemp -- Index temporary
  local nxt, prv = set[siz][1], set[siz-1][1]
  vtm:Set(nxt); vtm:Sub(prv); vtm:Normalize()
  vtm:Mul(self.NvLength); nxt:Add(vtm)
  self.NvLength = 0; return false
end

--[[
 * Prepares the laser beam data structure for entity refraction
 * origin  > New beam origin location vector
 * direct  > New beam ray direction vector
 * target  > New entity target being switched
 * refract > Refraction data entry
 * key     > Refraction data key
]]
function mtBeam:SetRefractEntity(origin, direct, target, refract, key)
  -- Register desination medium and raise calculate refraction flag
  if(refract and key) then
    self.TrMedium.D[1] = refract -- First element is always structure
    self.TrMedium.D[2] = tostring(key or "") -- Second element is always the index found
  else self:SetMediumDestn(refract) end -- Otherwise refract contains the whole thing
  -- Get the trace tready to check the other side and point and register the location
  self.DmRfract = (2 * target:BoundingRadius())
  self.VrDirect:Set(direct)
  self.VrOrigin:Set(direct)
  self.VrOrigin:Mul(self.DmRfract)
  self.VrOrigin:Add(origin)
  LaserLib.VecNegate(self.VrDirect)
  -- Must trace only this entity otherwise invalid
  self.TeFilter = function(ent) return (ent == target) end
  self.NvIWorld = true -- We are interested only in the refraction entity
  self.IsRfract = true -- Raise the bounce off refract flag
  self.BmTracew = DATA.TRWD -- Increase the beam width for back track
  self.TrRfract = (DATA.ERAD * self.DmRfract) -- Scale and again to make it hit
  return self -- Coding effective API
end

--[[
 * Samples the medium ahead in given direction
 * This aims to hit a solids of the map or entities
 * On success will return the refraction surface entry
 * origin > Refraction medium boundary origin
 * direct > Refraction medium boundary surface direct
 * trace  > Trace structure to store the result
]]
function mtBeam:GetSolidMedium(origin, direct, filter, trace)
  local tr = TraceBeam(origin, direct, DATA.NUGE,
    filter, MASK_SOLID, COLLISION_GROUP_NONE, false, 0, trace)
  if(not (tr or tr.Hit)) then return nil end -- Nothing traces
  if(tr.Fraction > 0) then return nil end -- Has prop air gap
  return GetMaterialEntry(GetMaterialID(tr, self), DATA.REFRACT)
end

--[[
 * Prepares the beam for the next general trace
 * This makes the hit-back entity from the other side
 * origin > Refraction medium boundary origin
 * direct > Refraction medium boundary surface direct
]]
function mtBeam:SetTraceNext(origin, direct)
  self.VrDirect:Set(direct)
  self.VrOrigin:Set(direct)
  self.VrOrigin:Mul(self.DmRfract)
  self.VrOrigin:Add(origin)
  LaserLib.VecNegate(self.VrDirect)
  return self -- Coding effective API
end

--[[
 * Requests a beam reflection
 * reflect > Reflection info structure
 * trace   > The current trace data
]]
function mtBeam:Reflect(reflect, trace)
  self.VrDirect:Set(LaserLib.GetReflected(self.VrDirect, trace.HitNormal))
  self.VrOrigin:Set(trace.HitPos)
  self.NvLength = self.NvLength - self.NvLength * trace.Fraction
  if(self.BrReflec) then self:SetPowerRatio(reflect[1]) end
  return self -- Coding effective API
end

--[[
 * Returns the trace entity valid flag and class
 * Updates the actor exit flag when found
 * target > The entity being the target
]]
function mtBeam:ActorTarget(target)
  -- If filter was a special actor and the clear flag is enabled
  -- Make sure to reset the filter if needed to enter actor again
  if(self.TrFActor) then -- Custom filter clear has been requested
    self.TeFilter = nil -- Reset the filter to hit something else
    self.TrFActor = false -- Lower the flag so it does not enter
  end -- Filter is present and we have request to clear the value
  -- Validate trace target and extract its class if available
  local ok, key = LaserLib.IsValid(target), nil -- Validate target
  if(ok) then key = target:GetClass() end; return ok, key
end

--[[
 * Performs library dedicated beam trace. Runs a
 * CAP trace. when fails runs a general trace
 * result > Trace output destination table as standard config
]]
function mtBeam:Trace(result)
  local length = (self.IsRfract and self.TrRfract or self.NvLength)
  if(not self.IsRfract) then -- CAP trace is not needed wen we are refracting
    local tr = TraceCAP(self.VrOrigin, self.VrDirect, length, self.TeFilter)
    if(tr) then return self:SetTraceWidth(tr, length) end -- Return CAP currently hit
  end -- When the trace is not specific CAP entity continue
  return self:SetTraceWidth(TraceBeam( -- Otherwise use the standard trace
    self.VrOrigin, self.VrDirect, length       , self.TeFilter,
    self.NvMask  , self.NvCGroup, self.NvIWorld, self.BmTracew, result), length)
end

--[[
 * Handles refraction of water to air
 * Redirects the beam from water to air at the boundary
 * point when water flag is triggered and hit position is
 * outside the water surface.
]]
function mtBeam:RefractWaterAir()
  -- When beam started inside the water and hit ouside the water
  local wat = self.__water -- Local reference indexing water
  local vtm = self.__vtemp; LaserLib.VecNegate(self.VrDirect)
  local vwa = self:IntersectRayPlane(wat.P, wat.N)
  -- Registering the node cannot be done with direct substraction
  LaserLib.VecNegate(self.VrDirect); self:RegisterNode(vwa, true)
  vtm:Set(wat.N); LaserLib.VecNegate(vtm)
  local vdir, bout = LaserLib.GetRefracted(self.VrDirect, vtm,
                       mtBeam.W[1][1], mtBeam.A[1][1])
  if(bout) then
    wat.N:Zero() -- Set water normal flag to zero
    self:SetMediumSours(mtBeam.A) -- Switch to air medium
    self:Redirect(vwa, vdir, true) -- Redirect and reset laser beam
  else -- Redirect the beam in case of going out reset medium
    self:Redirect(vwa, vdir) -- Redirect only reset laser beam
  end -- Apply power ratio when requested
  if(self.BrRefrac) then self:SetPowerRatio(mtBeam.W[1][2]) end
  return self -- Coding effective API
end

--[[
 * Configures and activates the water refraction surface
 * The beam may sart in the water or hit it and switch
 * reftype > Indication that this is found in the water
 * trace   > Trace result structure output being used
]]
function mtBeam:SetWater(reftype, trace)
  local wat = self.__water
  if(self.StRfract) then
    if(reftype and wat.K[reftype] and self:IsAir()) then
      local trace = TraceBeam(self.VrOrigin, DATA.VDRUP, DATA.TRWU,
        entity, MASK_ALL, COLLISION_GROUP_NONE, false, 0, trace)
      wat.N:Set(DATA.VDRUP); wat.P:Set(DATA.VDRUP)
      wat.P:Mul(DATA.TRWU * trace.FractionLeftSolid)
      wat.P:Add(self.VrOrigin)
    else -- Refract type is not water so reset the configuration
      wat.N:Zero() -- Clear the water normal vector
    end -- Water refraction configuration is done
  else -- Refract type not water then setup
    if(reftype and wat.K[reftype] and self:IsAir()) then
      wat.P:Set(trace.HitPos) -- Memorize the plane position
      wat.N:Set(trace.HitNormal) -- Memorize the plane normal
    else -- Refract type is not water so reset the configuration
      wat.N:Zero() -- Clear the water normal vector
    end -- Water refraction configuration is done
  end; return self -- Coding effective API
end

--[[
 * Setups the clags for world and water refraction
]]
function mtBeam:SetRefractWorld(trace, refract, key)
  if(refract and key) then
    self.TrMedium.D[1] = refract -- First element is always structure
    self.TrMedium.D[2] = tostring(key or "") -- Second element is always the index found
  else self:SetMediumDestn(refract) end -- Otherwise refract contains the whole thing
  -- Substact traced lenght from total length because we have hit something
  self.NvLength = self.NvLength - self.NvLength * trace.Fraction
  self.TrRfract = self.NvLength -- Remaining in refract mode
  -- Separate control for water and non-water
  if(self:IsAir()) then -- There is no water plane registered
    self.IsRfract = true -- Beam is inside another non water solid
    self.NvIWorld = false -- World transparen objects do not need world ignore
    self.NvMask = MASK_ALL -- Beam did not traverse into water
    self.BmTracew = DATA.TRWD -- Increase the beam width for back track
    -- Apply world-only filter for refraction exit the location
    self.TeFilter = mtBeam.F -- Fumction that filters hit world only
  else -- Filter solids so they can be hit inside water medium
    self.IsRfract = false -- Beam is inside water. Do not force refract
    self.NvIWorld = false -- Water refraction does not need world ignore
    self.NvMask = MASK_SOLID -- Aim to hit solid props within the water
    -- Clear the personal filter so we can hit models in the water
    -- We also must pass the primary iteration entity for custom beam offsets
    -- When beam starts inside the a laser prop with custom offsets must skip it
    self.TeFilter = (self:IsFirst() and self.BmSource or nil)
    self.TrMedium.S[1], self.TrMedium.D[1] = self.TrMedium.D[1], self.TrMedium.S[1]
    self.TrMedium.S[2], self.TrMedium.D[2] = self.TrMedium.D[2], self.TrMedium.S[2]
  end
end

--[[
 * Checks when another medium is present on exit
 * When present tranfers the beam to the new medium
 * origin > Origin position to be checked
 * normal > Normal vector of the refraction surface
 * target > Entity being the target
 * trace  > Trace structure to temporary store the result
]]
function mtBeam:IsRefractExit(origin, normal, target, trace)
  local refract = self:GetSolidMedium(origin, self.VrDirect, target, trace)
  if(not refract) then return false end
  -- Refract the hell out of this requested beam with enity destination
  local vdir, bout = LaserLib.GetRefracted(self.VrDirect,
                 normal, self.TrMedium.D[1][1], refract[1])
  if(bout) then
    self.IsRfract, self.StRfract = false, true
    self:Redirect(origin, nil, true) -- The beam did not traverse mediums
    self:SetMediumMemory(self.TrMedium.D, nil, normal)
    if(self.BrRefrac) then self:SetPowerRatio(refract[2]) end
  else -- Get the trace ready to check the other side and register the location
    self:SetTraceNext(origin, vdir) -- The beam did not traverse mediums
    if(self.BrRefrac) then self:SetPowerRatio(self.TrMedium.D[1][2]) end
  end; return true -- Apply power ratio when requested
end

--[[
 * Function handler for calculating SISO actor routines
 * These are specific handlers for specific classes
 * having single input beam and single output beam
 * trace > Reference to trace result structure
 * data  > Reference to trace beam data
]]
local gtActors = {
  ["event_horizon"] = function(trace, data)
    data:Finish(trace) -- Assume that beam stops traversing
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
    data:RegisterNode(data.VrOrigin, false, true)
    data.TeFilter, data.TrFActor = out, true
    data.IsTrace = true -- CAP networking is correct. Continue
  end,
  ["gmod_laser_portal"] = function(trace, data)
    data:Finish(trace) -- Assume that beam stops traversing
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
    nps, ndr = GetBeamPortal(ent, out, pos, dir,
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
    data:RegisterNode(data.VrOrigin, false, true)
    data.TeFilter, data.TrFActor = out, true
    data.IsTrace = true -- Output model is validated. Continue
  end,
  ["prop_portal"] = function(trace, data)
    data:Finish(trace) -- Assume that beam stops traversing
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
    data:RegisterNode(mav, false, false)
    local nps, ndr = GetBeamPortal(ent, out, pos, dir)
    data:RegisterNode(nps); nps:Add(vsm * ndr)
    data.VrOrigin:Set(nps); data.VrDirect:Set(ndr)
    data:RegisterNode(nps)
    data.TeFilter, data.TrFActor = out, true
    data.IsTrace = true -- Output portal is validated. Continue
  end,
  ["gmod_laser_dimmer"] = function(trace, data)
    data:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, trace, data, bmln)
    if(trace and trace.Hit and data and bdot) then
      data.IsTrace = true -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamReplicate() and 1 or mdot)
      local node = data:SetPowerRatio(vdot) -- May absorb
      data.VrOrigin:Set(trace.HitPos)
      data.TeFilter, data.TrFActor = ent, true -- Makes beam pass the dimmer
      node[1]:Set(trace.HitPos) -- We are not portal update position
      node[5] = true            -- We are not portal enable drawing
    end
  end,
  ["gmod_laser_parallel"] = function(trace, data)
    data:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, trace, data, bmln)
    if(trace and trace.Hit and data and bdot) then
      data.IsTrace = true -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamDimmer() and mdot or 1)
      local node = data:SetPowerRatio(vdot) -- May absorb
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
  -- Temporary values that are considered local and do not need to be accessed by hit reports
  local bIsValid  = false -- Stores whenever the trace is valid entity or not
  local sTrMaters = "" -- This stores the current extracted material as string
  local sTrClass  = nil -- This stores the calss of the current trace entity
  local trace, tr, target = {}, {} -- Configure and target and shared trace reference
  local data = Beam(origin, direct, width, damage, length, force) -- Beam data structure
  -- Reports dedicated values that are being used by other entities and processses
  data.TeFilter = entity -- Make sure the initial laser source is skipped
  data.BmSource = entity -- The beam source entity. Populated customly depending on the API
  data.BrReflec = usrfle -- Beam reflection ratio flag. Reduce beam power when reflecting
  data.BrRefrac = usrfre -- Beam refraction ratio flag. Reduce beam power when refracting
  data.BmNoover = noverm -- Beam no override material flag. Try to extract original material
  data.BmIdenty = index  -- Beam hit report index. Usually one if not provided

  if(data.NvLength <= 0) then return end
  if(data.VrDirect:LengthSqr() <= 0) then return end
  if(not LaserLib.IsValid(entity)) then return end

  data:RegisterNode(origin)

  repeat
    -- Run the trace using the defined conditianl parameters
    trace = data:Trace(trace); target = trace.Entity

    -- Initial start so the beam separate from the laser
    if(data.NvBounce == data.MxBounce) then
      data.TeFilter = nil

      if(trace.HitWorld and trace.StartSolid and data.NvMask == MASK_ALL) then
        -- Beam starts inside map solid and source must be changed
        if(bit.band(trace.Contents, CONTENTS_WATER) > 0) then
          data:SetRefractContent(3, trace)
        elseif(bit.band(trace.Contents, CONTENTS_WINDOW) > 0) then
          data:SetRefractContent(2, trace)
        end
      end
    else
      if(not data:IsAir() and not data.IsRfract) then
        if(not data:IsWater(trace.HitPos)) then
          data:RefractWaterAir() -- Water to air specifics
          -- Update the trace reference with the new data
          trace = data:Trace(trace); target = trace.Entity
        end
      end
    end
    -- Check current target for being a valid specific actor
    bIsValid, sTrClass = data:ActorTarget(target)
    -- Actor flag and specific filter are now reset when present
    if(trace.Fraction > 0) then -- Ignore registering zero length traces
      if(bIsValid) then -- Target is valis and it is a actor
        if(sTrClass and gtActors[sTrClass]) then
          data:RegisterNode(trace.HitPos, trace.LengthNR, false)
        else -- The trace entity target is not special actor case
          data:RegisterNode(trace.HitPos, trace.LengthNR)
        end
      else -- The trace has hit invalid entity or world
        if(trace.FractionLeftSolid > 0) then
          local mar = trace.LengthLS -- Use the feft-solid value
          local org = data:GetNudge(mar) -- Calculate nudge origin
          -- Register the node at the location the laser lefts the glass
          data:RegisterNode(org, mar)
        else
          data:RegisterNode(trace.HitPos, trace.LengthLS)
        end
        data.StRfract = trace.StartSolid -- Start in world entity
      end
    else -- Trace distance lenght is zero so enable refraction
      data.StRfract = true -- Do not alter the beam direction
    end -- Do not put a node when beam does not traverse
    -- When we are still tracing and hit something that is not specific unit
    if(data.IsTrace and trace.Hit and not LaserLib.IsUnit(target)) then
      -- Register a hit so reduce bounces count
      if(bIsValid) then
         if(data.IsRfract) then
          -- Well the beam is still tracing
          data.IsTrace = true -- Produce next ray
          -- Decide whenever to go out of the entity according to the hit location
          if(data:IsAir()) then
            data:SetMediumSours(mtBeam.A)
          else -- Water general flag is present
            if(data:IsWater(trace.HitPos)) then
              data:SetMediumSours(mtBeam.W)
            else -- Check if point is in or out of the water
              data:SetMediumSours(mtBeam.A)
            end -- Update the source accordingly
          end -- Nagate the normal so it must point inwards before refraction
          LaserLib.VecNegate(trace.HitNormal); LaserLib.VecNegate(data.VrDirect)
          -- Make sure to pick the correct refract exit medium for current node
          if(not data:IsRefractExit(trace.HitPos, trace.HitNormal, target, tr)) then
            -- Refract the hell out of this requested beam with enity destination
            local vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                           trace.HitNormal, data.TrMedium.D[1][1], data.TrMedium.S[1][1])
            if(bout) then -- When the beam gets out of the medium
              data:Redirect(trace.HitPos, vdir, true)
              if(not data:IsWater()) then -- Check for zero when water only
                if(not data:IsAir()) then data:ClearWater() end
              end -- Reset the normal. We are out of the water now
              data:SetMediumMemory(data.TrMedium.D, nil, trace.HitNormal)
            else -- Get the trace ready to check the other side and register the location
              data:SetTraceNext(trace.HitPos, vdir)
            end -- Apply power ratio when requested
            if(usrfre) then data:SetPowerRatio(data.TrMedium.D[1][2]) end
          end
        else -- Put special cases here
          if(sTrClass and gtActors[sTrClass]) then
            local suc, err = pcall(gtActors[sTrClass], trace, data)
            if(not suc) then data.IsTrace = false; error("Actor: "..err) end
          else
            sTrMaters = GetMaterialID(trace, data)
            data.IsTrace  = true -- Still tracing the beam
            local reflect = GetMaterialEntry(sTrMaters, DATA.REFLECT)
            if(reflect and not data.StRfract) then -- Just call reflection and get done with it..
              data:Reflect(reflect, trace) -- Call reflection method
            else
              local refract, key = GetMaterialEntry(sTrMaters, DATA.REFRACT)
              if(data.StRfract or (refract and key ~= data.TrMedium.S[2])) then -- Needs to be refracted
                -- When we have refraction entry and are still tracing the beam
                if(refract) then -- When refraction entry is available do the thing
                  -- Substact traced lenght from total length
                  data.NvLength = data.NvLength - data.NvLength * trace.Fraction
                  -- Calculated refraction ray. Reflect when not possible
                  local vdir, bout -- Refraction entity direction and reflection
                  -- Call refraction cases and prepare to trace-back
                  if(data.StRfract) then -- Bounces were decremented so move it up
                    if(data.NvBounce == data.MxBounce) then
                      vdir = Vector(direct) -- Primary node starts inside solid
                    else -- When two props are stuck save the middle boundary and traverse
                      -- When the traverse mediums is differerent and node is not inside a laser
                      if(data:IsMemory(refract[1], trace.HitPos)) then
                        vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                       data.TrMedium.M[3], data.TrMedium.M[1][1], refract[1])
                        -- Do not waste game ticks to refract the same refraction ratio
                      else -- When there is no medium traverse change
                        vdir = Vector(data.VrDirect) -- Keep the last beam direction
                      end -- Finish start-refraction for current iteration
                    end -- Marking the fraction being zero and refracting from the last entity
                    data.StRfract = false -- Make sure to disable the flag agian
                  else -- Otherwise do a normal water-entity-air refraction
                    vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                   trace.HitNormal, data.TrMedium.S[1][1], refract[1])
                  end
                  data:SetRefractEntity(trace.HitPos, vdir, target, refract, key)
                  -- Apply power ratio when requested
                  if(usrfre) then data:SetPowerRatio(refract[2]) end
                  -- We cannot be able to refract as the requested data is missing
                else data:Finish(trace) end
                -- We are neither reflecting nor refracting and have hit a wall
              else data:Finish(trace) end -- All triggers are processed
            end
          end
        end -- Comes from air then hits and refracts in water or starts in water
      elseif(trace.HitWorld) then
        if(data.IsRfract) then
          if(not trace.AllSolid) then
            -- Important thing is to consider what is the shape of the world entity
            -- We can eather memorize the normal vector which will fail for different shapes
            -- We can eather set the trace length insanely long will fail windows close to the gound
            -- Another trace is made here to account for these probles above
            -- Well the beam is still tracing
            data.IsTrace = true -- Produce next ray
            -- Make sure that outer trace will always hit
            local org, nrm = data:GetNudge(trace.LengthLS + DATA.NUGE)
            LaserLib.VecNegate(data.VrDirect)
            -- Margin multiplier for trace back to find correct surface normal
            -- This is the only way to get the proper surface normal vector
            local tr = TraceBeam(org, data.VrDirect, 2 * DATA.NUGE,
              mtBeam.F, MASK_ALL, COLLISION_GROUP_NONE, false, 0, tr)
            -- Store hit position and normal in beam temprary
            local nrm = Vector(tr.HitNormal); org:Set(tr.HitPos)
            -- Reverse direction of the normal to point inside transperent
            LaserLib.VecNegate(nrm); LaserLib.VecNegate(data.VrDirect)
            -- Do the refraction according to medium boundary
            if(not data:IsRefractExit(org, nrm, target, tr)) then
              local vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                   nrm, data.TrMedium.D[1][1], mtBeam.A[1][1])
              if(bout) then -- When the beam gets out of the medium
                data:Redirect(org, vdir, true)
                data:SetMediumSours(mtBeam.A)
                -- Memorizing will help when beam traverses from world to no-collided entity
                data:SetMediumMemory(data.TrMedium.D, nil, nrm)
              else -- Get the trace ready to check the other side and register the location
                data:Redirect(org, vdir)
              end
            end
          else -- The beam ends inside a solid transperent medium
            local org = data:GetNudge(data.NvLength)
            data:RegisterNode(org, data.NvLength)
            data:Finish(trace)
          end -- Apply power ratio when requested
          if(usrfre) then data:SetPowerRatio(data.TrMedium.D[1][2]) end
        else
          if(sTrClass and gtActors[sTrClass]) then
            local suc, err = pcall(gtActors[sTrClass], trace, data)
            if(not suc) then data.IsTrace = false; error("Actor: "..err) end
          else
            sTrMaters = GetMaterialID(trace, data)
            data.IsTrace  = true -- Still tracing the beam
            local reflect = GetMaterialEntry(sTrMaters, DATA.REFLECT)
            if(reflect and not data.StRfract) then
              data:Reflect(reflect, trace) -- Call reflection method
            else
              local refract, key = GetMaterialEntry(sTrMaters, DATA.REFRACT)
              if(data.StRfract or (refract and key ~= data.TrMedium.S[2])) then -- Needs to be refracted
                -- When we have refraction entry and are still tracing the beam
                if(refract) then -- When refraction entry is available do the thing
                  -- Calculated refraction ray. Reflect when not possible
                  if(data.StRfract) then -- Laser is within the map water submerged
                    data:SetWater(refract[3] or key, tr)
                    data:Redirect(trace.HitPos, direct) -- Keep the same direction and initial origin
                    data.StRfract = false -- Lower the flag so no preformance hit is present
                  else -- Beam comes from the air and hits the water. Store water plane and refract
                    -- Get the trace tready to check the other side and point and register the location
                    local vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                         trace.HitNormal, data.TrMedium.S[1][1], refract[1])
                    data:SetWater(refract[3] or key, trace)
                    data:Redirect(trace.HitPos, vdir)
                  end -- Need to make the traversed destination the new source
                  data:SetRefractWorld(trace, refract, key)
                  -- Apply power ratio when requested
                  if(usrfre) then data:SetPowerRatio(refract[2]) end
                  -- We cannot be able to refract as the requested data is missing
                else data:Finish(trace) end
                -- All triggers when reflecting and refracting are processed
              else data:Finish(trace) end -- Not traversing and have hit a wall
            end
          end -- We are neither hit a valid entity nor a map water
        end
      else data:Finish(trace) end; data:Bounce() -- Refresh medium pass trough information
    else data:Finish(trace) end -- Trace did not hit anything to be bounced off from
  until(data:IsFinish())

  -- Reset the normal for the next call
  data:ClearWater()

  -- The beam ends inside transperent medium
  if(not data:IsNode()) then return nil, data end

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
