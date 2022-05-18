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
DATA.MAXRAYAS = CreateConVar("laseremitter_maxrayast", 100, DATA.FGINDCN, "Maximum distance to compare projection to units center", 0, 250)
DATA.MCRYSTAL = CreateConVar("laseremitter_mcrystal", "models/props_c17/pottery02a.mdl", DATA.FGSRVCN, "Controls the crystal model")
DATA.MREFLECT = CreateConVar("laseremitter_mreflect", "models/madjawa/laser_reflector.mdl", DATA.FGSRVCN, "Controls the reflector model")
DATA.MREFRACT = CreateConVar("laseremitter_mrefract", "models/madjawa/laser_reflector.mdl", DATA.FGSRVCN, "Controls the refractor model")
DATA.MSPLITER = CreateConVar("laseremitter_mspliter", "models/props_c17/pottery04a.mdl", DATA.FGSRVCN, "Controls the splitter model")
DATA.MDIVIDER = CreateConVar("laseremitter_mdivider", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the divider model")
DATA.MSENSOR  = CreateConVar("laseremitter_msensor" , "models/props_c17/pottery01a.mdl", DATA.FGSRVCN, "Controls the sensor model")
DATA.MDIMMER  = CreateConVar("laseremitter_mdimmer" , "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the dimmer model")
DATA.MPORTAL  = CreateConVar("laseremitter_mportal" , "models/props_c17/Frame002a.mdl", DATA.FGSRVCN, "Controls the portal model")
DATA.MSPLITRM = CreateConVar("laseremitter_msplitrm", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the splitter multy model")
DATA.MPARALEL = CreateConVar("laseremitter_mparalel", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Controls the paralleller multy model")
DATA.MFILTER  = CreateConVar("laseremitter_mfilter" , "models/props_c17/Frame002a.mdl", DATA.FGSRVCN, "Controls the filter model")
DATA.NSPLITER = CreateConVar("laseremitter_nspliter", 2, DATA.FGSRVCN, "Controls the default splitter outputs count", 0, 16)
DATA.XSPLITER = CreateConVar("laseremitter_xspliter", 1, DATA.FGSRVCN, "Controls the default splitter X direction", 0, 1)
DATA.YSPLITER = CreateConVar("laseremitter_yspliter", 1, DATA.FGSRVCN, "Controls the default splitter Y direction", 0, 1)
DATA.EFFECTDT = CreateConVar("laseremitter_effectdt", 0.15, DATA.FGINDCN, "Controls the time between effect drawing", 0, 5)
DATA.ENSOUNDS = CreateConVar("laseremitter_ensounds", 1, DATA.FGSRVCN, "Trigger this to enable or disable redirector sounds")
DATA.LNDIRACT = CreateConVar("laseremitter_lndiract", 20, DATA.FGINDCN, "How long will the direction of output beams be rendered", 0, 50)
DATA.DAMAGEDT = CreateConVar("laseremitter_damagedt", 0.1, DATA.FGSRVCN, "The time frame to pass between the beam damage cycles", 0, 10)
DATA.DRWBMSPD = CreateConVar("laseremitter_drwbmspd", 8, DATA.FGINDCN, "The speed used to render the beam in the main routine", 0, 16)
DATA.VESFBEAM = CreateConVar("laseremitter_vesfbeam", 150, DATA.FGSRVCN, "Controls the beam safety velocity for player pushed aside", 0, 500)
DATA.NRASSIST = CreateConVar("laseremitter_nrassist", 1000, DATA.FGSRVCN, "Controls the area that is searched when drawing assist", 0, 10000)

DATA.GRAT = 1.61803398875    -- Golden ratio used for panels
DATA.TOOL = "laseremitter"   -- Tool name for internal use
DATA.ICON = "icon16/%s.png"  -- Format to convert icons
DATA.NOAV = "N/A"            -- Not available as string
DATA.CATG = "Laser"          -- Category name in the entities tab
DATA.TOLD = SysTime()        -- Reduce debug function calls
DATA.RNDB = 3                -- Decimals beam round for visibility check
DATA.KWID = 5                -- Width coefficient used to calculate power
DATA.CLMX = 255              -- Maximum value for valid coloring
DATA.CTOL = 0.01             -- Color vectors and alpha comparison tolerance
DATA.NUGE = 2                -- Nudge amount for origin vectors back-tracing
DATA.MINW = 0.05             -- Minimum width to be considered visible
DATA.DOTM = 0.01             -- Collinearity and dot product margin check
DATA.POWL = 0.001            -- Lowest bounds of laser power
DATA.ERAD = 1.12             -- Entity refract coefficient for back trace origins
DATA.TRWD = 0.27             -- Beam back trace width when refracting
DATA.WLMR = 10000            -- World vectors to be correctly converted to local
DATA.TRWU = 50000            -- The distance to trace for finding water surface
DATA.FMVA = "%f,%f,%f"       -- Utilized to print vector in proper manner
DATA.FNUH = "%.2f"           -- Formats number to be printed on a HUD
DATA.AMAX = {-360, 360}      -- General angular limits for having min/max
DATA.BBONC = 0               -- External forced beam max bounces. Resets on every beam
DATA.BLENG = 0               -- External forced beam length used in the current request
DATA.BESRC = nil             -- External forced entity source for the beam update
DATA.BCOLR = nil             -- External forced beam color used in the current request
DATA.KEYD = "#"              -- The default key in a collection point to take when not found
DATA.KEYA = "*"              -- The all key in a collection point to return the all in set
DATA.AZERO = Angle()         -- Zero angle used across all sources
DATA.VZERO = Vector()        -- Zero vector used across all sources
DATA.VTEMP = Vector()        -- Global library temporary storage vector
DATA.VDFWD = Vector(1, 0, 0) -- Global forward vector used across all sources
DATA.VDRGH = Vector(0,-1, 0) -- Global right vector used across all sources. Positive is at the left
DATA.VDRUP = Vector(0, 0, 1) -- Global up vector used across all sources
DATA.WORLD = game.GetWorld() -- Store reference to the world to skip the call in realtime
DATA.KPHYP = DATA.TOOL.."_physprop" -- Key used to registed physical properties
DATA.TRDG = (DATA.TRWD * math.sqrt(3)) / 2 -- Trace hit normal displacement

local gtTCUST = {
  "Forward", "Right", "Up",
  H = {ID = 0, M = 0, V = 0},
  L = {ID = 0, M = 0, V = 0}
}

-- Translates color from index/key to key/index
local gtCOLID = {
  ["r"] = 1, -- Red
  ["g"] = 2, -- Green
  ["b"] = 3, -- Blue
  ["a"] = 4, -- Alpha
  "r", "g", "b", "a"
}

local gtCLASS = {
  -- Classes existing in the hash part are laser-enabled entities `LaserLib.Configure(self)`
  -- Classes are stored in notation `[ent:GetClass()] = true` and used in `LaserLib.IsUnit(ent)`
  ["gmod_laser"           ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_crystal"   ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_dimmer"    ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_divider"   ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_filter"    ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_parallel"  ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_portal"    ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_rdivider"  ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_reflector" ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_sensor"    ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_splitter"  ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_splitterm" ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_refractor" ] = true, -- This is present for hot reload. You must register yours separately
  -- [1] Actual class passed to `ents.Create` and used to actually create the proper scripted entity
  -- [2] Extension for folder name indices. Stores which folder are entity specific files located
  -- [3] Extension for variable name indices. Populate this when model control variable is different
  {"gmod_laser"          , nil        , nil      }, -- Laser entity class `PriarySource`
  {"gmod_laser_crystal"  , "crystal"  , nil      }, -- Laser crystal class `EveryBeam`
  {"gmod_laser_reflector", "reflector", "reflect"}, -- Laser reflectors class `DoBeam`
  {"gmod_laser_splitter" , "splitter" , "spliter"}, -- Laser beam splitter `EveryBeam`
  {"gmod_laser_divider"  , "divider"  , nil      }, -- Laser beam divider `DoBeam`
  {"gmod_laser_sensor"   , "sensor"   , nil      }, -- Laser beam sensor `EveryBeam`
  {"gmod_laser_dimmer"   , "dimmer"   , nil      }, -- Laser beam divide `DoBeam`
  {"gmod_laser_splitterm", "splitterm", "splitrm"}, -- Laser beam splitter multy `EveryBeam`
  {"gmod_laser_portal"   , "portal"   , nil      }, -- Laser beam portal  `DoBeam`
  {"gmod_laser_parallel" , "parallel" , "paralel"}, -- Laser beam parallel `DoBeam`
  {"gmod_laser_filter"   , "filter"   , nil      }, -- Laser beam filter `DoBeam`
  {"gmod_laser_refractor", "refractor", "refract"}  -- Laser beam refractor `DoBeam`
}

local gtMODEL = { -- Model used by the entities menu
  "", -- Laser model is changed via laser tool. Variable is not needed.
  DATA.MCRYSTAL:GetString(), -- Portal cube: models/props/reflection_cube.mdl
  DATA.MREFLECT:GetString(),
  DATA.MSPLITER:GetString(),
  DATA.MDIVIDER:GetString(),
  DATA.MSENSOR:GetString() , -- Portal catcher: models/props/laser_catcher_center.mdl
  DATA.MDIMMER:GetString() ,
  DATA.MSPLITRM:GetString(),
  DATA.MPORTAL:GetString() , -- Portal: Well... Portals being entities
  DATA.MPARALEL:GetString(),
  DATA.MFILTER:GetString() ,
  DATA.MREFRACT:GetString()
}

local gtMATERIAL = {
  "", -- Laser material is changed with the model
  "models/dog/eyeglass"                ,
  "debug/env_cubemap_model"            ,
  "models/dog/eyeglass"                ,
  "models/dog/eyeglass"                ,
  "models/props_combine/citadel_cable" ,
  "models/dog/eyeglass"                ,
  "models/dog/eyeglass"                ,
  "models/props_combine/com_shield001a",
  "models/dog/eyeglass"                ,
  "models/props_combine/citadel_cable" ,
  "models/dog/eyeglass"
}

local gtCOLOR = {
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

local gtDISTYPE = {
  [DATA.KEYD]   = "core",
  ["energy"]    = 0,
  ["heavyelec"] = 1,
  ["lightelec"] = 2,
  ["core"]      = 3
}

local gtREFLECT = { -- Reflection descriptor
  [1] = "cubemap", -- Cube maps textures
  [2] = "reflect", -- Has reflect in the name
  [3] = "mirror" , -- Regular mirror surface
  [4] = "chrome" , -- Chrome stuff reflect
  [5] = "shiny"  , -- All shiny reflective stuff
  [6] = "white"  , -- All general white paint
  [7] = "metal"  , -- All shiny metal reflect
  -- Used for prop updates and checks
  [DATA.KEYD]                            = "debug/env_cubemap_model",
  -- User for general class control
  -- [1] : Surface reflection index for the material specified
  -- [2] : Which index is the material found at when it is searched in array part
  [""]                                   = false, -- Disable empty materials
  ["**empty**"]                          = false, -- Disable empty world materials
  ["**studio**"]                         = false, -- Disable empty prop materials
  ["cubemap"]                            = {0.999, "cubemap"},
  ["reflect"]                            = {0.999, "reflect"},
  ["mirror"]                             = {0.999, "mirror"},
  ["chrome"]                             = {0.955, "chrome" },
  ["shiny"]                              = {0.854, "shiny"  },
  ["white"]                              = {0.342, "white"  },
  ["metal"]                              = {0.045, "metal"  },
  -- Materials that are overridden and directly hash searched
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
  ["gm_construct/color_room"]            = {0.342}, -- White room in gm_construct
  ["debug/env_cubemap_model"]            = {1.000}, -- There is no perfect mirror
  ["models/materials/chchrome"]          = {0.864},
  ["phoenix_storms/grey_chrome"]         = {0.757},
  ["phoenix_storms/fender_white"]        = {0.625},
  ["sprops/textures/sprops_chrome"]      = {0.757},
  ["sprops/textures/sprops_chrome2"]     = {0.657},
  ["phoenix_storms/pack2/bluelight"]     = {0.734},
  ["sprops/trans/wheels/wheel_d_rim1"]   = {0.943},
  ["bobsters_trains/chrome_dirty_black"] = {0.537}
}; gtREFLECT.Size = #gtREFLECT

local gtREFRACT = { -- https://en.wikipedia.org/wiki/List_of_refractive_indices
  [1] = "air"  , -- Air enumerator index
  [2] = "glass", -- Glass enumerator index
  [3] = "water", -- Water enumerator index
  -- Used for prop updates and checks
  [DATA.KEYD]                                   = "models/props_combine/health_charger_glass",
  -- User for general class control
  -- [1] : Medium refraction index for the material specified
  -- [2] : Medium refraction rating when the beam goes through reduces its power
  -- [3] : Which index is the material found at when it is searched in array part
  [""]                                          = false, -- Disable empty materials
  ["**empty**"]                                 = false, -- Disable empty world materials
  ["**studio**"]                                = false, -- Disable empty prop materials
  ["air"]                                       = {1.000, 1.000, "air"  }, -- Air refraction index
  ["glass"]                                     = {1.521, 0.999, "glass"}, -- Ordinary glass
  ["water"]                                     = {1.333, 0.955, "water"}, -- Water refraction index
  -- Materials that are overridden and directly hash searched
  ["models/spawn_effect"]                       = {1.153, 0.954}, -- Closer to air (pixelated)
  ["models/dog/eyeglass"]                       = {1.612, 0.955}, -- Non pure glass 2
  ["phoenix_storms/glass"]                      = {1.521, 0.999}, -- Ordinary glass
  ["models/shadertest/shader3"]                 = {1.333, 0.832}, -- Water refraction index
  ["models/shadertest/shader4"]                 = {1.385, 0.922}, -- Water with some impurities
  ["models/shadertest/predator"]                = {1.333, 0.721}, -- Water refraction index
  ["phoenix_storms/pack2/glass"]                = {1.521, 0.999}, -- Ordinary glass
  ["models/effects/vol_light001"]               = {1.000, 1.000}, -- Transparent no perfect air
  ["models/props_c17/fisheyelens"]              = {1.521, 0.999}, -- Ordinary glass
  ["models/effects/comball_glow2"]              = {1.536, 0.924}, -- Glass with some impurities
  ["models/airboat/airboat_blur02"]             = {1.647, 0.955}, -- Non pure glass 1
  ["models/props_lab/xencrystal_sheet"]         = {1.555, 0.784}, -- Amber refraction index
  ["models/props_combine/com_shield001a"]       = {1.573, 0.653}, -- Dynamically changing glass
  ["models/props_combine/combine_fenceglow"]    = {1.638, 0.924}, -- Glass with decent impurities
  ["models/props_c17/frostedglass_01a_dx60"]    = {1.521, 0.853}, -- White glass
  ["models/props_combine/health_charger_glass"] = {1.552, 1.000}, -- Resembles no perfect glass
  ["models/props_combine/combine_door01_glass"] = {1.583, 0.341}, -- Bit darker glass
  ["models/props_combine/citadel_cable"]        = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/citadel_cable_b"]      = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/pipes01"]              = {1.583, 0.761}, -- Dark glass other
  ["models/props_combine/pipes03"]              = {1.583, 0.761}, -- Dark glass other
  ["models/props_combine/stasisshield_sheet"]   = {1.511, 0.427}  -- Blue temper glass
}; gtREFRACT.Size = #gtREFRACT

local gtMATYPE = {
  [MAT_SNOW       ] = "white",
  [MAT_GRATE      ] = "metal",
  [MAT_CLIP       ] = "metal",
  [MAT_METAL      ] = "metal",
  [MAT_VENT       ] = "metal",
  [MAT_GLASS      ] = "glass",
  [MAT_WARPSHIELD ] = "glass"
}

local gtTRACE = {
  ["noDetour"]   = true, -- Mee's Seamless-Portals. Backwards compatibility
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

if(CLIENT) then
  DATA.KILL = "vgui/entities/gmod_laser_killicon"
  DATA.HOVM = Material("gui/ps_hover.png", "nocull")
  DATA.HOVB = GWEN.CreateTextureBorder(0, 0, 64, 64, 8, 8, 8, 8, DATA.HOVM)
  DATA.HOVP = function(pM, iW, iH) DATA.HOVB(0, 0, iW, iH, gtCOLOR["WHITE"]) end
  gtREFLECT.Sort = {Size = 0, Info = {"Rate", "Type", Size = 2}, Mpos = 0}
  gtREFRACT.Sort = {Size = 0, Info = {"Ridx", "Rate", "Type", Size = 3}, Mpos = 0}
  surface.CreateFont("LaserHUD", {font = "Arial", size = 22, weight = 600})
  killicon.Add(gtCLASS[1][1], DATA.KILL, gtCOLOR["WHITE"])
else
  DATA.NTIF = {} -- User notification configuration type
  DATA.NTIF[1] = "GAMEMODE:AddNotify(\"%s\", NOTIFY_%s, 6)"
  DATA.NTIF[2] = "surface.PlaySound(\"ambient/water/drip%d.wav\")"
end

-- Callbacks for console variables
for idx = 2, #gtCLASS do
  local vset = gtCLASS[idx]
  local vidx = (vset[3] or vset[2])
  local varo = DATA["M"..vidx:upper()]
  local varn = varo:GetName()

  cvars.RemoveChangeCallback(varn, varn)
  cvars.AddChangeCallback(varn,
    function(name, o, n)
      local m = tostring(n):Trim()
      if(m:sub(1,1) == DATA.KEYD) then
        gtMODEL[idx] = varo:GetDefault()
        varo:SetString(gtMODEL[idx])
      else gtMODEL[idx] = m end
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
    gtTRACE.start:Set(origin)
    gtTRACE.endpos:Set(direct)
    gtTRACE.endpos:Normalize()
    if(not (length and length > 0)) then
      length = direct:Length()
    end -- Use proper length even if missing
    gtTRACE.endpos:Mul(length)
    local tr = StarGate.Trace:New(gtTRACE.start, gtTRACE.endpos, filter)
    if(StarGate.Trace.Entities[tr.Entity]) then return tr end
    -- If CAP specific entity is hit return and override the trace
  end; return nil -- Otherwise use the regular trace for refraction control
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
  gtTRACE.start:Set(origin)
  gtTRACE.endpos:Set(direct)
  gtTRACE.endpos:Normalize()
  if(not (length and length > 0)) then
    length = direct:Length()
  end -- Use proper length even if missing
  gtTRACE.endpos:Mul(length)
  gtTRACE.endpos:Add(origin)
  gtTRACE.filter = filter
  if(width ~= nil and width > 0) then
    local m = width / 2
    gtTRACE.funct = util.TraceHull
    gtTRACE.mins:SetUnpacked(-m, -m, -m)
    gtTRACE.maxs:SetUnpacked( m,  m,  m)
  else
    if(SeamlessPortals) then -- Mee's Seamless-Portals
      gtTRACE.funct = SeamlessPortals.TraceLine
    else -- Seamless portals are not installed
      gtTRACE.funct = util.TraceLine
    end -- Use the original no detour trace line
  end
  if(mask ~= nil) then
    gtTRACE.mask = mask
  else -- Default trace mask
    gtTRACE.mask = MASK_SOLID
  end
  if(iworld ~= nil) then
    gtTRACE.ignoreworld = iworld
  else -- Default world ignore
    gtTRACE.ignoreworld = false
  end
  if(colgrp ~= nil) then
    gtTRACE.collisiongroup = colgrp
  else -- Default collision group
    gtTRACE.collisiongroup = COLLISION_GROUP_NONE
  end
  if(result ~= nil) then
    gtTRACE.output = result
    gtTRACE.funct(gtTRACE)
    gtTRACE.output = nil
    return result
  else
    gtTRACE.output = nil
    return gtTRACE.funct(gtTRACE)
  end
end

function LaserLib.GetSign(arg)
  return arg / math.abs(arg)
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

--[[
 * Clears an array table from specified index
 * arr > Array to be cleared
 * idx > Start clear index (not mandatory)
]]
function LaserLib.Clear(arr, idx)
  if(not arr) then return end
  local idx = math.floor(tonumber(idx) or 1)
  if(idx <= 0) then return end
  while(arr[idx]) do idx, arr[idx] = (idx + 1) end
end

--[[
 * Extracts table values from 2D set specified key
 * tab > Reference to a table of row tables
 * key > The key to be extracted (not mandatory)
]]
function LaserLib.Extract(tab, key)
  if(not tab) then return tab end
  if(not key) then return tab end
  local set = {} -- Allocate
  for k, v in pairs(tab) do
    set[k] = v[key] -- Populate values
  end; return set -- Key-value pairs
end

--[[
 * Validates entity or physics object
 * arg > Entity or physics object
]]
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
  local key = LaserLib.GetTool().."_"..name
  if(LaserLib.IsValid(user)) then
    user:ConCommand(key.." \""..tostring(value or "").."\"\n")
  else RunConsoleCommand(key, tostring(value or "")) end
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
 * Applies the final positional and angular offsets to the laser spawned
 * Adjusts the custom model angle and calculates the touch position
 * base  > The laser entity to perform the operation for
 * trace > The trace that player is aiming for
 * tran  > Transform information setup array
]]
function LaserLib.ApplySpawn(base, trace, tran)
  if(tran[2] and tran[3]) then
    LaserLib.SnapCustom(base, trace.HitPos, trace.HitNormal, tran[2], tran[3])
  else
    LaserLib.SnapNormal(base, trace.HitPos, trace.HitNormal, tran[1])
  end
end

--[[
 * Reads entity class name from the list
 * idx (int) > When provided checks settings
]]
function LaserLib.GetClass(iR, iC)
  local nR = math.floor(tonumber(iR) or 0)
  local tS = gtCLASS[nR] -- Pick element
  if(not tS) then return nil end -- No info
  local nC = math.floor(tonumber(iC) or 0)
  return tS[nC] -- Return whatever found
end

--[[
 * Check when the entity is laser library unit
]]
function LaserLib.IsUnit(ent)
  if(LaserLib.IsValid(ent)) then
    return gtCLASS[ent:GetClass()]
  else return false end
end

--[[
 * Defines when the entity can produce output beam
]]
function LaserLib.IsBeam(ent)
  if(LaserLib.IsValid(ent)) then
    return (ent.DoBeam != nil)
  else return false end
end

--[[
 * Defines when the entity has primary laser settings
]]
function LaserLib.IsPrimary(ent)
  if(LaserLib.IsValid(ent)) then
    return (ent.GetDissolveType ~= nil)
  end; return false
end

--[[
 * Defines when the entity is actual beam source
]]
function LaserLib.IsSource(ent)
  if(LaserLib.IsValid(ent)) then
    return (ent.DoBeam != nil and ent.GetDissolveType ~= nil)
  else return false end
end

--[[
 * Allocates entity data tables and adds entity to `LaserLib.IsPrimary`
 * ent > Entity to initialize as primary laser source. Usually dominants
 * nov > Enable initializing empty value. Used for sensors and configuration
]]
function LaserLib.SetPrimary(ent, nov)
  if(not LaserLib.IsValid(ent)) then return end
  local dissolve = list.Get("LaserDissolveTypes")
  local material = list.Get("LaserEmitterMaterials")
  local comxbool = list.GetForEdit("LaserEmitterComboBools")
  ent:EditableSetVector("OriginLocal" , "General")
  ent:EditableSetVector("DirectLocal" , "General")
  if(nov) then
    material["Empty"] = ""
    dissolve["Empty"] = {name = "", icon = "delete"}
    ent:EditableSetIntCombo("ForceCenter" , "General" , comxbool)
    ent:EditableSetIntCombo("ReflectRatio", "Material", comxbool)
    ent:EditableSetIntCombo("RefractRatio", "Material", comxbool)
  else
    ent:EditableSetBool("ForceCenter" , "General")
    ent:EditableSetBool("ReflectRatio", "Material")
    ent:EditableSetBool("RefractRatio", "Material")
  end
  ent:EditableSetBool ("InPowerOn"   , "Internals")
  ent:EditableSetFloat("InBeamWidth" , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  ent:EditableSetFloat("InBeamLength", "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  ent:EditableSetFloat("InBeamDamage", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  ent:EditableSetFloat("InBeamForce" , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  ent:EditableSetStringCombo("InBeamMaterial", "Internals", material)
  if(nov) then
    ent:EditableSetIntCombo("InNonOverMater", "Internals", comxbool)
    ent:EditableSetIntCombo("InBeamSafety"  , "Internals", comxbool)
    ent:EditableSetIntCombo("EndingEffect"  , "Visuals"  , comxbool)
  else
    ent:EditableSetBool("InNonOverMater", "Internals")
    ent:EditableSetBool("InBeamSafety"  , "Internals")
    ent:EditableSetBool("EndingEffect"  , "Visuals")
  end
  ent:EditableSetVectorColor("BeamColor", "Visuals")
  ent:EditableSetFloat("BeamAlpha", "Visuals", 0, LaserLib.GetData("CLMX"))
  ent:EditableSetStringCombo("DissolveType", "Visuals", dissolve, "name")
end

--[[
 * Clears entity internal order info for the editable wrapper
 * Registers the entity to the units list on CLIENT/SERVER
 * unit > Entity to register as primary laser source unit
]]
function LaserLib.Configure(unit)
  if(not LaserLib.IsValid(unit)) then return end
  local uas, cas = unit:GetClass(), LaserLib.GetClass(1, 1)
  -- Delete temporary order infor and register unit
  unit.meOrderInfo = nil; gtCLASS[uas] = true
  -- Instance specific configuration
  if(SERVER) then -- Do server configuration finalizer
    if(unit.WireRemove) then function unit:OnRemove() self:WireRemove() end end
    if(unit.WireRestored) then function unit:OnRestore() self:WireRestored() end end
  else -- Do client configuration finalizer
    language.Add(uas, unit.Information)
    if(uas ~= cas) then -- Setup the same kill icon
      killicon.AddAlias(uas, cas)
    end
  end
  ------ GENERAL FRAME MANAGER ------
  if(SERVER) then
    if(LaserLib.IsSource(unit)) then
      --[[
       * Extract the parameters needed to create a beam
       * Takes the values from the argument and updated source
       * beam  > Dominant laser beam reference being extracted
       * color > Beam color for override. Not mandatory
      ]]
      function unit:SetDominant(beam, color)
        local src = beam:GetSource()
        -- We set the same non-addable properties
        if(not LaserLib.IsSource(src)) then return self end
        -- The most powerful source (biggest damage/width)
        self:SetStopSound(src:GetStopSound())
        self:SetKillSound(src:GetKillSound())
        self:SetStartSound(src:GetStartSound())
        self:SetBeamSafety(src:GetBeamSafety())
        self:SetForceCenter(src:GetForceCenter())
        self:SetBeamMaterial(src:GetBeamMaterial())
        self:SetDissolveType(src:GetDissolveType())
        self:SetEndingEffect(src:GetEndingEffect())
        self:SetReflectRatio(src:GetReflectRatio())
        self:SetRefractRatio(src:GetRefractRatio())
        self:SetNonOverMater(src:GetNonOverMater())
        self:SetBeamColorRGBA(color or beam:GetColorRGBA(true))
        -- Write down the dominant
        self:WireWrite("Dominant", src)
        -- Update the player for kill krediting
        LaserLib.SetPlayer(self, (src.ply or src.player))
        -- Use coding effective API
        return self
      end
    end
  end
  --[[
   * Effects draw handling decides whenever
   * the current tick has to draw the effects
   * Flag is automatically reset in every call
   * then becomes true when it meets requirements
  ]]
  function unit:UpdateFlags() local time = CurTime()
    self.isEffect = false -- Reset the frame effects
    if(not self.nxEffect or time > self.nxEffect) then
      local dt = DATA.EFFECTDT:GetFloat() -- Read configuration
      self.isEffect, self.nxEffect = true, time + dt
    end
    if(SERVER) then -- Damage exists only on the server
      self.isDamage = false -- Reset the frame damage
      if(not self.nxDamage or time > self.nxDamage) then
        local dt = DATA.DAMAGEDT:GetFloat() -- Read configuration
        self.isDamage, self.nxDamage = true, time + dt
      end
    end
  end
  --[[
   * Checks for infinite loops when the source `ent`
   * is powered by other generators powered by `self`
   * self > The root of the tree propagated
   * ent  > The entity of the source checked
   * set  > Contains the already processed items
  ]]
  function unit:IsInfinite(ent, set)
    local set = (set or {}) -- Allocate passtrough entiti registration table
    if(LaserLib.IsValid(ent)) then -- Invalid entities cannot do infinite loops
      if(set[ent]) then return false end -- This has already been checked for infinite
      if(ent == self) then return true else set[ent] = true end -- Check and register
      if(LaserLib.IsBeam(ent) and ent.hitSources) then -- Can output neams and has sources
        for src, stat in pairs(ent.hitSources) do -- Other hits and we are in its sources
          if(LaserLib.IsValid(src)) then -- Crystal has been hit by other crystal
            if(src == self) then return true end -- Perforamance optimization
            if(LaserLib.IsBeam(src) and src.hitSources) then -- Class propagades the tree
              if(self:IsInfinite(src, set)) then return true end end
          end -- Cascadely propagate trough the crystal sources from `self`
        end; return false -- The entity does not persists in itself
      else return false end
    else return false end
  end
  ------ HIT REPORTS MANAGER ------
  --[[
   * Returns hit report stack size
  ]]
  function unit:GetHitReportMax()
    local rep = self.hitReports
    if(not rep) then return 0 end
    return rep.Size or 0
  end

  --[[
   * Removes hit reports from the list according to new size
   * rovr > When remove overhead is provided deletes
            all entries with larger index
   * Data is stored in notation: self.hitReports[ID]
  ]]
  function unit:SetHitReportMax(rovr)
    if(self.hitReports) then
      local rep, idx = self.hitReports
      if(rovr) then -- Overhead mode
        local rovr = tonumber(rovr) or 0
        idx, rep.Size = (rovr + 1), rovr
      else idx, rep.Size = 1, 0 end
      -- Wipe selected items
      while(rep[idx]) do
        rep[idx] = nil
        idx = idx + 1
      end
    end; return self
  end

  --[[
   * Checks whenever the entity `ent` beam report hits us `self`
   * self > Target entity to be checked
   * ent  > Reporter entity to be checked
   * idx  > Forced index to check for hit report. Not mandatory
   * bri  > Search from idx as start hit report index. Not mandatory
   * Data is stored in notation: self.hitReports[ID]
  ]]
  function unit:GetHitSourceID(ent, idx, bri)
    if(not LaserLib.IsUnit(ent)) then return nil end -- Invalid
    if(ent == self) then return nil end -- Cannot be source to itself
    if(not self.hitSources[ent]) then return nil end -- Not source
    if(not ent:GetOn()) then return nil end -- Unit is not powered on
    local rep = ent.hitReports -- Retrieve and localize hit reports
    if(not rep) then return nil end -- No hit reports. Exit at once
    if(idx and not bri) then -- Retrieve the report requested by ID
      local beam, trace = ent:GetHitReport(idx) -- Retrieve beam report
      if(trace and trace.Hit and self == trace.Entity) then return idx end
    else local anc = (bri and idx or 1) -- Check all the entity reports for possible hits
      for cnt = anc, rep.Size do local beam, trace = ent:GetHitReport(cnt)
        if(trace and trace.Hit and self == trace.Entity) then return cnt end
      end -- The hit report list is scanned and no reports are found hitting us `self`
    end; return nil -- Tell requestor we did not find anything that hits us `self`
  end

  --[[
   * Registers a trace hit report under the specified index
   * trace > Trace result structure to register
   * beam  > Beam structure to register
  ]]
  function unit:SetHitReport(beam, trace)
    if(not self.hitReports) then self.hitReports = {Size = 0} end
    local rep, idx = self.hitReports, beam.BmIdenty
    if(idx >= rep.Size) then rep.Size = idx end
    if(not rep[idx]) then rep[idx] = {} end; rep = rep[idx]
    rep["BM"] = beam; rep["TR"] = trace; return self
  end

  --[[
   * Retrieves hit report trace and beam under specified index
   * index > Hit report index to read ( defaults to 1 )
  ]]
  function unit:GetHitReport(index)
    if(not index) then return end
    if(not self.hitReports) then return end
    local rep = self.hitReports[index]
    if(not rep) then return end
    return rep["BM"], rep["TR"]
  end

  --[[
   * Processes the sources table for a given entity
   * using a custom local scope function routine.
   * Runs a dedicated routine to define how the
   * source `ent` affects our `self` behavior.
   * self > Entity base item that is being issued
   * ent  > Entity hit reports getting checked
   * proc > Scope function per-beam handler. Arguments:
   *      > entity > Hit report active source
   *      > index  > Hit report active index
   *      > trace  > Hit report active trace
   *      > beam   > Hit report active beam
   * each > Scope function per-source handler. Arguments:
   *      > entity > Hit report active source
   *      > index  > Hit report active index
   * apre > Action taken for pre-processing
   *      > entity > Source entity
   * post > Action taken for post-processing
   *      > entity > Source entity
   * Returns flag indicating presence of hit reports
  ]]
  function unit:ProcessReports(ent, proc, each, apre, post)
    if(not LaserLib.IsValid(ent)) then return false end
    if(apre) then local suc, err = pcall(apre, self, ent)
      if(not suc) then self:Remove(); error(err); return false end
    end -- When whe have dedicated methor to apply on each source
    local idx = self:GetHitSourceID(ent)
    if(idx) then local siz = ent.hitReports.Size
      if(each) then local suc, err = pcall(each, self, ent, idx)
        if(not suc) then self:Remove(); error(err); return false end
      end -- When whe have dedicated method to apply on each source
      if(proc) then -- Trigger the beam processing routine
        while(idx and idx <= siz) do -- First index always hits when present
          local beam, trace = ent:GetHitReport(idx) -- When the report hits us
          local suc, err = pcall(proc, self, ent, idx, beam, trace) -- Call process
          if(not suc) then self:Remove(); error(err); return false end
          idx = self:GetHitSourceID(ent, idx + 1, true) -- Prepare for the next report
        end -- When whe have dedicated method to apply on each source
      end -- Trigger the post-processing routine
      if(post) then local suc, err = pcall(post, self, ent)
        if(not suc) then self:Remove(); error(err); return false end
      end; return true -- At least one report is processed for the current entity
    end; return false -- The entity hit reports do not hit us `self`
  end

  --[[
   * Processes the sources table for all entities
   * using a custom local scope function routine.
   * Runs the dedicated routines to define how the
   * sources `ent` affect our `self` behavior.
   * Automatically removes the non related reports
   * self > Entity base item that is being issued
   * proc > Scope function to process. Arguments:
   *      > entity > Hit report active entity
   *      > index  > Hit report active index
   *      > trace  > Hit report active trace
   *      > beam   > Hit report active beam
   * Process how `ent` hit reports affects us `self`. Remove when no hits
  ]]
  function unit:ProcessSources(proc, each, apre, post)
    local proc, each = (proc or self.EveryBeam ), (each or self.EverySource)
    local apre, post = (apre or self.PreProcess), (post or self.PostProcess)
    if(not self.hitSources) then return false end
    for ent, hit in pairs(self.hitSources) do -- For all rgistered source entities
      if(hit and LaserLib.IsValid(ent)) then -- Process only valid hits from the list
        if(not self:ProcessReports(ent, proc, each, apre, post)) then -- Procesed sources
          self.hitSources[ent] = nil -- Remove the netity from the list
        end -- Check when there is any hit report that is processed correctly
      else self.hitSources[ent] = nil end -- Delete the entity when force skipped
    end; return true -- There are hit reports and all are processed correctly
  end
  ------ INTERNAL ARRAY MANGER ------
  --[[
   * Initializes array definitions and createsa a list
   * that is derived from the string arguments.
   * This will create arays in notation `self.hit%NAME`
   * Pass `false` as name to skip the wire output
  ]]
  function unit:InitArrays(...)
    local arg = {...}
    local num = #arg
    if(num <= 0) then return self end
    self.hitSetup = {Size = num}
    for idx = 1, num do local nam = arg[idx]
      self.hitSetup[idx] = {Name = nam, Data = {}}
    end; return self
  end
  --[[
   * Clears the output arrays according to the hit size
   * Removes the residual elements from wire ouputs
   * Desidned to be called at the end of sources process
  ]]
  function unit:UpdateArrays()
    local set = self.hitSetup
    if(not set) then return self end
    local idx = (tonumber(self.hitSize) or 0) + 1
    for cnt = 1, set.Size do local arr = set[cnt]
      if(arr and arr.Data) then LaserLib.Clear(arr.Data, idx) end
    end; set.Save = nil -- Clear the last top enntity
    return self -- Use coding effective API
  end
  --[[
   * Registers the argument values in the setup arrays
   * The argument order must be the same as initialization
   * The first array must always hold valid source entities
  ]]
  function unit:SetArrays(...)
    local set = self.hitSetup
    if(not set) then return self end
    local arg, idx = {...}, self.hitSize
    if(set.Save == arg[1]) then return self end
    if(not set.Save) then set.Save = arg[1] end
    idx = (tonumber(idx) or 0) + 1
    for cnt = 1, set.Size do
      set[cnt].Data[idx] = arg[cnt]
    end; self.hitSize = idx
    return self
  end
  --[[
   * Triggers all the dedicated arrays in one call
  ]]
  function unit:WireArrays()
    if(CLIENT) then return self end
    local set = self.hitSetup
    if(not set) then return self end
    local idx = (tonumber(self.hitSize) or 0)
    self:WireWrite("Count", idx)
    for cnt = 1, set.Size do -- Copy values to arrays
      local nam = set[cnt].Name
      local arr = (idx > 0 and set[cnt].Data or nil)
      if(nam) then self:WireWrite(nam, arr) end
    end; return self
  end
end

--[[
 * Retrieves entity order settings for the given key
 * ent > Entity to register as primary laser source
]]
function LaserLib.GetOrderID(ent, key)
  if(not key) then return end
  if(not LaserLib.IsValid(ent)) then return end
  local info = ent.meOrderInfo; if(not info) then return end
  local itab = info.T; if(itab[key]) then
    itab[key] = (itab[key] + 1) else itab[key] = 0 end
  info.N = (info.N + 1); return key, info.N, itab[key]
end

function LaserLib.GetModel(iK)
  local sM = gtMODEL[tonumber(iK) or 0]
  return (sM and sM or nil)
end

function LaserLib.GetMaterial(iK)
  local sT = gtMATERIAL[tonumber(iK) or 0]
  return (sT and sT or nil)
end

function LaserLib.ProjectRay(pos, org, dir)
  local vrs = Vector(pos); vrs:Sub(org)
  local mar = vrs:Dot(dir); vrs:Set(dir)
        vrs:Mul(mar); vrs:Add(org)
  local amr = pos:DistToSqr(vrs)
  return vrs, mar, amr
end

function LaserLib.GetTransformUnit(ent)
  if(not LaserLib.IsValid(ent)) then return end
  local org = (ent.GetOriginLocal and ent:GetOriginLocal() or ent:OBBCenter())
  local dir = (ent.GetDirectLocal and ent:GetDirectLocal() or nil)
  if(not dir) then  dir = (ent.GetNormalLocal and ent:GetNormalLocal() or nil) end
  if(not (org and dir)) then return end
  local pos, ang = ent:GetPos(), ent:GetAngles()
  local vor = Vector(org); vor:Rotate(ang); vor:Add(pos);
  local vdr = Vector(dir); vdr:Rotate(ang)
  return vor, vdr
end

--[[
 * Draws OBB projected iteraction for a single ray
 * vbb > Bounding box center being drawn
 * org > Origin ray start position vector
 * dir > Direction ray beam aiming vector (normalized)
 * nar > Treshhold to compare the dostance OBB to projection
 * rev > Reverse the drawing colors when available
]]
function LaserLib.DrawAssistOBB(vbb, org, dir, nar, rev)
  if(SERVER) then return end -- Server can go out now
  if(not (org and dir)) then return end
  local csr = LaserLib.GetColor("YELLOW")
  local ctr = LaserLib.GetColor("GREEN")
  local vrs, mar, amr = LaserLib.ProjectRay(vbb, org, dir)
  if(rev and mar < 0) then return end
  local so, sv = vbb:ToScreen(), vrs:ToScreen()
  if(so.visible) then
    if(rev) then surface.DrawCircle(so.x, so.y, 3, ctr)
    else surface.DrawCircle(so.x, so.y, 3, ctr) end
  end
  if(amr < nar and so.visible and sv.visible) then
    if(rev) then
      surface.DrawCircle(sv.x, sv.y, 5, csr)
      surface.SetDrawColor(ctr)
    else
      surface.DrawCircle(sv.x, sv.y, 5, csr)
      surface.SetDrawColor(csr)
    end
    surface.DrawLine(so.x, so.y, sv.x, sv.y)
    surface.SetFont("Trebuchet18")
    surface.SetTextPos(sv.x, sv.y)
    if(rev) then surface.SetTextColor(csr)
    else surface.SetTextColor(ctr) end
    surface.DrawText(("%.2f"):format(math.sqrt(amr)))
  end
end

function LaserLib.DrawAssistReports(vbb, erp, nar, rev)
  if(SERVER) then return end -- Server can go out now
  if(not LaserLib.IsValid(erp)) then return end
  for idx = 1, erp.hitReports.Size do
    local beam = erp:GetHitReport(idx)
    if(beam) then local tvp = beam.TvPoints
      for idp = 2, tvp.Size do
        local org, nxt = tvp[idp - 1], tvp[idp - 0]
        local dir = (nxt[1] - org[1]); dir:Normalize()
        LaserLib.DrawAssistOBB(vbb, org[1], dir, nar, rev)
      end
    end
  end
end

function LaserLib.DrawAssist(org, dir, ray, tre, ply)
  if(SERVER) then return end -- Server can go out now
  if(ray <= 0) then return end -- Ray assist disabled
  local vndr = DATA.VTEMP -- Cube size
  local mray = DATA.MAXRAYAS:GetFloat()
  local nasr = DATA.NRASSIST:GetFloat()
  vndr.x, vndr.y, vndr.z = nasr, nasr, nasr
  local vmax = Vector(org); vmax:Add(vndr)
  local vmin = Vector(org); vmin:Sub(vndr)
  local ncst = math.Clamp(ray, 0, mray)^2
  local teun = ents.FindInBox(vmin, vmax)
  for idx = 1, #teun do local ent = teun[idx]
    if(LaserLib.IsValid(ent) and
      LaserLib.IsUnit(ent) and tre ~= ent)
    then -- Move targets to the trace entity beam
      local vbb = ent:LocalToWorld(ent:OBBCenter())
      local rep = (tre and tre.hitReports or nil)
      if(rep and rep.Size and rep.Size > 0) then
        LaserLib.DrawAssistReports(vbb, tre, ncst)
      else
        LaserLib.DrawAssistOBB(vbb, org, dir, ncst)
      end
    end
  end
  if(tre and ply) then
    local vbb = tre:LocalToWorld(tre:OBBCenter())
    local org, dir = ply:EyePos(), ply:GetAimVector()
    for idx = 1, #teun do
      local ent = teun[idx]
      local ecs = ent:GetClass()
      if(tre ~= ent and not ecs ~= "gmod_laser" and
         LaserLib.IsValid(ent) and ecs:find("gmod_laser", 1, true))
      then -- Move trace entity to the targets beam
        local rep = (ent and ent.hitReports or nil)
        if(rep and rep.Size and rep.Size > 0) then
          LaserLib.DrawAssistReports(vbb, ent, ncst, true)
        else
          local org, dir = LaserLib.GetTransformUnit(ent)
          LaserLib.DrawAssistOBB(vbb, org, dir, ncst, true)
        end
      end
    end
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
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Up(), 180)
    local cbk = LaserLib.GetColor("BLACK")
    local cbg = LaserLib.GetColor("BACKGR")
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    cam.Start3D2D(pos, ang, 0.16)
      surface.SetFont(fnt)
      local w, h = surface.GetTextSize(txt)
      draw.RoundedBox(8, -(w/2)-mrg, -(h/2)-mrg/1.5, w+2*mrg, h+2*mrg, cbg)
      draw.SimpleText(txt,fnt,0,0,cbk,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
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
    local cbk = LaserLib.GetColor("BLACK")
    local cbg = LaserLib.GetColor("BACKGR")
    ang:RotateAroundAxis(ang:Up(), 90)
    ang:RotateAroundAxis(ang:Forward(), 90)
    cam.Start3D2D(pos, ang, 0.16)
      surface.SetFont(fnt)
      local w, h = surface.GetTextSize(txt)
      draw.RoundedBox(8, -(w/2)-mrg, -(h/2)-mrg/1.5, w+2*mrg, h+2*mrg, cbg)
      draw.SimpleText(txt,fnt,0,0,cbk,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
  end
end

--[[
 * Creates ordered sequence set for use with
 * The `Type` key is last and not mandatory
 * It is used for materials found with indexing match
 * https://wiki.facepunch.com/gmod/table.sort
]]
function LaserLib.GetSequenceData(set)
  if(SERVER) then return end
  local ser = set.Sort
  if(not ser) then return end
  local inf = ser.Info
  if(not inf) then return end
  for key, val in pairs(set) do -- Check database
    if(not ser[key]) then -- Entry is not present
      if(type(val) == "table" and tostring(key):find("/")) then
        row = {Key = key, Draw = true}; ser[key] = true
        ser.Size = table.insert(ser, row) -- Insert
        for iD = 1, inf.Size do row[inf[iD]] = val[iD] end
      end -- Store info and return sequential table
    end -- Entry is added to the sequential list
  end; return ser
end

--[[
 * Extracts information for a given sorted row
 * Returns the information as a string
]]
function LaserLib.GetSequenceInfo(row, info)
  local res = "" -- Temporary storage
  for iD = 1, info.Size do local dat = row[info[iD]]
    if(dat) then res = res.."|"..tostring(dat) end
  end; return "{"..res:sub(2, -1).."}"
end

--[[
 * Automatically adjusts the material size
 * Materials button will always be square
]]
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

--[[
 * Clears the material selector from any content
 * This is used for sorting and filtering
]]
function LaserLib.ClearMaterials(pnMat)
  if(SERVER) then return end
  -- Clear all entries from the list
  for key, val in pairs(pnMat.Controls) do
    val:Remove(); pnMat.Controls[key] = nil
  end -- Remove all remaining image panels
  pnMat.List:CleanList()
  pnMat.SelectedMaterial = nil
  pnMat.OldSelectedPaintOver = nil
end

--[[
 * Changes the selected material paint over function
 * When other one is clicked reverts the last change
]]
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

--[[
 * Triggers save request for the material select
 * scroll bar and reads it on the next panel open
 * Animates the slider to the last remembered position
]]
function LaserLib.SetMaterialScroll(pnMat, sort)
  if(SERVER) then return end
  local pnBar = pnMat.List.VBar
  if(pnBar) then
    function pnBar:OnMouseReleased()
      self.Dragging = false
      self.DraggingCanvas = nil
      self:MouseCapture(false)
      self.btnGrip.Depressed = false
      sort.Mpos = self:GetScroll()
    end
    pnBar:AnimateTo(sort.Mpos, 0.05)
  end
end

--[[
 * Preforms material selection panel update for the requested entries
 * Clears the content and remembers the last panel view state
 * Called recursively when sorting or filtering is requested
]]
function LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
  if(SERVER) then return end
  local sTool = LaserLib.GetTool()
  -- Update material selection content
  LaserLib.ClearMaterials(pnMat)
  -- Read the controls table and create index
  local tCont, iC = pnMat.Controls, 0
  -- Update material panel with ordered values
  for iD = 1, sort.Size do
    local tRow, pnImg = sort[iD]
    if(tRow.Draw) then -- Drawing is enabled
      local sCon = LaserLib.GetSequenceInfo(tRow, sort.Info)
      local sInf, sKey = sCon.." "..tRow.Key, tRow.Key
      pnMat:AddMaterial(sInf, sKey); iC = iC + 1; pnImg = tCont[iC]
      function pnImg:DoClick()
        LaserLib.SetMaterialPaintOver(pnMat, self)
        LaserLib.ConCommand(nil, sort.Sors, sKey)
        pnFrame:SetTitle(sort.Name.." > "..sInf)
      end
      function pnImg:DoRightClick()
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
        -- Sort the data by the entry key
        if(tRow.Key) then
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find1").." (<)",
            function()
              table.SortByMember(sort, "Key", true)
              LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
            end):SetImage(LaserLib.GetIcon("arrow_down"))
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find1").." (>)",
            function()
              table.SortByMember(sort, "Key", false)
              LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
            end):SetImage(LaserLib.GetIcon("arrow_up"))
        end
        -- Sort the data by the absorption rate
        if(tRow.Rate) then
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find2").." (<)",
            function()
              table.SortByMember(sort, "Rate", true)
              LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
            end):SetImage(LaserLib.GetIcon("basket_remove"))
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find2").." (>)",
            function()
              table.SortByMember(sort, "Rate", false)
              LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
            end):SetImage(LaserLib.GetIcon("basket_put"))
        end
        -- Sorted members by the medium refraction index
        if(tRow.Ridx) then
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find3").." (<)",
            function()
              table.SortByMember(sort, "Ridx", true)
              LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
            end):SetImage(LaserLib.GetIcon("ruby_get"))
          pSort:AddOption(language.GetPhrase("tool."..sTool..".openmaterial_find3").." (>)",
            function()
              table.SortByMember(sort, "Ridx", false)
              LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
            end):SetImage(LaserLib.GetIcon("ruby_put"))
        end
        pnMenu:Open()
      end
      -- When the variable value is the same as the key
      if(sKey == sort.Conv:GetString()) then
        pnFrame:SetTitle(sort.Name.." > "..sInf)
        LaserLib.SetMaterialPaintOver(pnMat, pnImg)
      end
    end
  end
  -- Update material panel scroll bar
  LaserLib.SetMaterialScroll(pnMat, sort)
end

--[[
 * Used to debug and set random stuff  in an interval
 * Good for preventing spam of printing traces for example
]]
function LaserLib.Call(time, func, ...)
  local tnew = SysTime()
  if((tnew - DATA.TOLD) > time) then
    DATA.TOLD = tnew -- Update time
    local suc, err = pcall(func, ...)
    if(not suc) then error(err) end
  end
end

function LaserLib.PrintOn()
  DATA.PRDY = true
end

function LaserLib.PrintOff()
  DATA.PRDY = false
end

function LaserLib.Print(...)
  if(not DATA.PRDY) then return end
  print(...)
end

function LaserLib.PrintTable(...)
  if(not DATA.PRDY) then return end
  PrintTable(...)
end

--[[
 * Creates welds between laser and base
 * Applies and controls surface weld flag
 * weld  > Surface weld flag
 * laser > Laser entity to be welded
 * trace > Trace entity to be welded or world
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
  if(noco and eval) then -- Otherwise falls through the ground
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
 * Returns the calculated yaw result angle
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
 * between two mediums. Returns angles in range
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
  [2] > Will the beam traverse to the next medium
  [3] > Mediums have the same refractive index
]]
function LaserLib.GetRefracted(direct, normal, source, destin)
  local inc = direct:GetNormalized() -- Read normalized copy or incident
  if(source == destin) then return inc, true, true end -- Continue out medium
  local nrm = Vector(normal) -- Always normalized. Call copy-constructor
  local vcr = inc:Cross(LaserLib.VecNegate(nrm)) -- Sine: |i||n|sin(i^n)
  local ang, sii = nrm:AngleEx(vcr), vcr:Length()
  local mar = (sii * source) / destin -- Apply Snell's law
  if(math.abs(mar) <= 1) then -- Valid angle available
    local sio, aup = math.asin(mar), ang:Up()
    ang:RotateAroundAxis(aup, -math.deg(sio))
    return ang:Forward(), true, false -- Make refraction
  else -- Reflect from medium interface boundary
    return LaserLib.GetReflected(direct, normal), false, false
  end
end

--[[
 * Updates render bounds vector by calling min/max
 * base > Vector to be updated and manipulated
 * vec  > Vector the base must be updated with
 * func > The function to be called. Either max or min
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
 * width  > Value to check beam visibility
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

function LaserLib.GetDissolveID(idx)
  return GetCollectionData(idx, gtDISTYPE)
end

function LaserLib.GetColor(idx)
  return GetCollectionData(idx, gtCOLOR)
end

--[[
 * Translates indices to color keys for RGB
 * Generally used to split colors into separate beams
 * idx > Index of the beam being split to components
 * mr  > Red component of the picked color channel
         Can also be a color object then `mb` is missed
 * mg  > Green component of the picked color channel
         Can also be a flag for new color if mr is object
 * mb  > Blue component of the picked color channel
]]
function LaserLib.GetColorID(idx, mr, mg, mb)
  if(not (idx and idx > 0)) then return end
  local idc = ((idx - 1) % 3) + 1 -- Index component
  local key = gtCOLID[idc] -- Key color component
  if(istable(mr)) then local cov = mr[key]
    if(mg) then local c = Color(0,0,0,mr.a); c[key] = cov; return c
    else mr.r, mr.g, mr.b = 0, 0, 0; mr[key] = cov; return mr end
  else
    local r = ((key == "r") and mr or 0) -- Split red   [1]
    local g = ((key == "g") and mg or 0) -- Split green [2]
    local b = ((key == "b") and mb or 0) -- Split blue  [3]
    return r, g, b -- Return the picked component
  end
end

function LaserLib.SetMaterial(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local tab = {MaterialOverride = tostring(mat or "")}
  local key = "laseremitter_material"
  ent:SetMaterial(tab.MaterialOverride)
  duplicator.StoreEntityModifier(ent, key, tab)
end

function LaserLib.SetProperties(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local phy = ent:GetPhysicsObject()
  if(not LaserLib.IsValid(phy)) then return end
  local tab = {Material = tostring(mat or "")}
  construct.SetPhysProp(nil, ent, 0, phy, tab)
  duplicator.StoreEntityModifier(ent, DATA.KPHYP, tab)
end

--[[
 * Checks when the entity has interactive material
 * Cashes the request issued for index material
 * mat > Direct material to check for. Missing uses `ent`
 * set > The dedicated parameters setting to check
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
  -- Check for element category
  for idx = 1, set.Size do key = set[idx]
    if(mat:find(key, 1, true)) then -- Cache the material
      set[mat] = set[key] -- Cache the material found
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
  return GetInteractIndex(iK, gtREFLECT)
end

function LaserLib.DataRefract(iK)
  return GetInteractIndex(iK, gtREFRACT)
end

--[[
 * Calculates the local beam origin offset
 * according to the base entity and direction provided
 * base   > Base entity to calculate the vector for
 * direct > Local direction vector according to `base`
 * Returns the local entity origin offset vector
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

--[[
 * Generates a custom local angle for lasers
 * Defines value bases on a dominant direction
 * base   > Entity to calculate for
 * direct > Local direction for beam align
]]
function LaserLib.GetCustomAngle(base, direct)
  local tab = base:GetTable(); if(tab.anCustom) then
    return tab.anCustom else tab.anCustom = Angle() end
  local az, mt = DATA.AZERO, gtTCUST
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
  tab.anCustom:Set(f:AngleEx(u)) -- Transfer and apply angle pitch
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
  AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
  AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")

  DATA.DMGI = DamageInfo() -- Create a server-side damage information class
  DATA.BURN = "player/general/flesh_burn.wav" -- Burn sound for player safety

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

  function LaserLib.DoDissolve(torch)
    if(not LaserLib.IsValid(torch)) then return end
    torch:Fire("Dissolve", torch.Target, 0)
    torch:Fire("Kill", "", 0.1)
  end

  function LaserLib.DoSound(target, noise)
    if(not LaserLib.IsValid(target)) then return end
    if(noise ~= nil and (target:Health() > 0 or target:IsPlayer())) then
      sound.Play(noise, target:GetPos())
      target:EmitSound(Sound(noise))
    end
  end

  function LaserLib.DoBurn(target, origin, direct, safety)
    if(not safety) then return end -- Beam safety skipped
    if(not LaserLib.IsValid(target)) then return end
    local smu = DATA.VESFBEAM:GetFloat()
    if(smu <= 0) then return end -- General setting
    local idx = target:StartLoopingSound(Sound(DATA.BURN))
    local obb = target:LocalToWorld(target:OBBCenter())
    local pbb = LaserLib.ProjectRay(obb, origin, direct)
          obb:Sub(pbb); obb:Normalize(); obb:Mul(smu)
          obb.z = 0; target:SetVelocity(obb)
    timer.Simple(0.5, function() target:StopLoopingSound(idx) end)
  end

  function LaserLib.DoDamage(target  , laser , attacker, origin ,
                             normal  , direct, damage  , force  ,
                             dissolve, noise , fcenter , safety)
    local phys = target:GetPhysicsObject()
    if(not LaserLib.IsUnit(target)) then
      if(force and force > 0 and LaserLib.IsValid(phys)) then
        if(fcenter) then -- Force relative to mass center
          phys:ApplyForceCenter(direct * force)
        else -- Keep force separate from damage inflicting
          phys:ApplyForceOffset(direct * force, origin)
        end -- This is the way laser can be used as forcer
      end -- Do not apply force on laser units
      if(target:IsPlayer()) then -- Portal beam safety
        LaserLib.DoBurn(target, origin, direct, safety)
      end -- Target is not unit. Check emiter safety
    end

    if(laser.isDamage) then
      if(target:IsVehicle()) then
        local driver = target:GetDriver()
        if(LaserLib.IsValid(driver) and driver:IsPlayer()) then
          if(driver:Health() <= damage) then -- We must kill the driver!
            local torch = LaserLib.GetTorch(laser, driver:GetPos(), attacker, dissolve)
            if(not LaserLib.IsValid(torch)) then driver:Kill(); return end
            LaserLib.TakeDamage(target, damage, attacker, laser) -- Do damage to generate the ragdoll
            local doll = driver:GetRagdollEntity() -- We need to kill the player first to get his ragdoll
            if(not LaserLib.IsValid(doll)) then return end
            doll:SetName(torch.Target) -- Thanks to Nevec for the player ragdoll idea
            LaserLib.DoDissolve(torch) -- Allowing us to dissolve him the cleanest way
            LaserLib.DoSound(driver, noise)
          end
        end
      end

      if(target:GetClass() == "shield") then
        local damage = math.Clamp(damage / 2500 * 3, 0, 4)
        target:Hit(laser, origin, damage, -1 * normal)
        return -- We stop here because we hit a shield!
      end

      if(target:Health() <= damage) then
        if(target:IsNPC() or target:IsPlayer()) then
          local torch = LaserLib.GetTorch(laser, target:GetPos(), attacker, dissolve)
          if(not LaserLib.IsValid(torch)) then target:Kill(); return end
          if(target:IsPlayer()) then
            LaserLib.TakeDamage(target, damage, attacker, laser) -- Do damage to generate the ragdoll
            local doll = target:GetRagdollEntity() -- We need to kill the player first to get his ragdoll
            if(not LaserLib.IsValid(doll)) then target:Kill(); return end -- Nevec for the player ragdoll idea
            doll:SetName(torch.Target) -- Allowing us to dissolve him the cleanest way
          else
            target:SetName(torch.Target)
            local swep = target:GetActiveWeapon()
            if(LaserLib.IsValid(swep)) then
              swep:SetName(torch.Target)
            else target:Kill(); return end
          end
          LaserLib.DoDissolve(torch) -- Dissolver only for player and NPC
        end
        LaserLib.DoSound(target, noise) -- Play sound for breakable props
      end

      LaserLib.TakeDamage(target, damage, attacker, laser)
    end
  end

  function LaserLib.New(user       , pos         , ang         , model      ,
                        trandata   , key         , width       , length     ,
                        damage     , material    , dissolveType, startSound ,
                        stopSound  , killSound   , runToggle   , startOn    ,
                        pushForce  , endingEffect, reflectRate , refractRate,
                        forceCenter, frozen      , enOverMater , enSafeBeam , rayColor )

    local unit = LaserLib.GetTool()
    if(not LaserLib.IsValid(user)) then return end
    if(not user:IsPlayer()) then return end
    if(not user:CheckLimit(unit.."s")) then return end

    local laser = ents.Create(LaserLib.GetClass(1, 1))
    if(not (LaserLib.IsValid(laser))) then return end

    laser:SetCollisionGroup(COLLISION_GROUP_NONE)
    laser:SetSolid(SOLID_VPHYSICS)
    laser:SetMoveType(MOVETYPE_VPHYSICS)
    laser:SetNotSolid(false)
    laser:SetPos(pos)
    laser:SetAngles(ang)
    laser:SetModel(Model(model))
    laser:Spawn()
    laser:SetCreator(user)
    laser:Setup(width      , length      , damage    , material   , dissolveType,
                startSound , stopSound   , killSound , runToggle  , startOn     ,
                pushForce  , endingEffect, trandata  , reflectRate, refractRate ,
                forceCenter, enOverMater , enSafeBeam, rayColor   , false)

    local phys = laser:GetPhysicsObject()
    if(LaserLib.IsValid(phys)) then
      phys:EnableMotion(not frozen)
    end

    numpad.OnUp  (user, key, "Laser_Off", laser)
    numpad.OnDown(user, key, "Laser_On" , laser)

    -- Setup the laser kill crediting
    LaserLib.SetPlayer(laser, user)

    -- Apply proper laser emiter material
    LaserLib.SetProperties(laser, "metal")

    -- These do not change when laser is updated
    table.Merge(laser:GetTable(), {key = key, frozen = frozen})

    return laser
  end

end

--[[
 * Calculates the beam position and direction when entity is a portal
 * This assumes that the beam enters the +X and exits at +X
 * This will lead to correct beam representation across portal Y axis
 * base    > Base entity acting as a portal entrance
 * exit    > Exit entity acting as a portal beam output location
 * origin  > Hit location vector placed on the first entity surface
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
    if(not ok) then error("Direct error: "..err) end
  else dir.x, dir.y = -dir.x, -dir.y end
  dir:Rotate(exit:GetAngles()); dir:Div(DATA.WLMR)
  return pos, dir
end

--[[
 * Projects beam direction onto portal forward and retrieves
 * portal beam margin visuals to be displayed correctly in
 * render target surface. Returns incorrect results when
 * portal position is not located on the render target surface
 * entity > The portal entity to calculate margin for
 * origin > Hit location vector placed on the furst entity surface
 * direct > Direction that the beam goes inside the first entity
 * normal > Surface normal vector. Usually portal:GetForward()
 * Returns the output beam ray margin transition
]]
--[[
    local pos, dir = trace.HitPos, beam.VrDirect
    local eps, mav = ent:GetPos(), Vector(dir)
    local fwd, wvc = ent:GetForward(), Vector(pos); wvc:Sub(eps)
    local mar = math.abs(wvc:Dot(fwd)) -- Project entrance vector
    local vsm = mar / math.cos(math.asin(fwd:Cross(dir):Length()))
    vsm = 2 * vsm; mav:Set(dir); mav:Mul(vsm); mav:Add(pos)
]]
local function GetMarginPortal(entity, origin, direct, normal)
  local normal = (normal or entity:GetForward())
  local pos, mav = entity:GetPos(), Vector(direct)
  local wvc = Vector(origin); wvc:Sub(pos)
  local mar = math.abs(wvc:Dot(normal)) -- Project entrance vector
  local vsm = mar / math.cos(math.asin(normal:Cross(direct):Length()))
  vsm = 2 * vsm; mav:Mul(vsm); mav:Add(origin)
  return mav, vsm
end

--[[
 * Makes the laser trace loop use pre-defined bounces cout
 * When this is not given the loop will use MBOUNCES
 * bounce > The amount of bounces the loop will have
]]
function LaserLib.SetExBounces(bounce)
  DATA.BBONC = 0 -- Initial value
  if(bounce and bounce > 0) then
    DATA.BBONC = math.floor(bounce)
  end
end

--[[
 * Makes the laser trace loop use pre-defined length
 * This is done so the next unit will know the
 * actual length when SIMO entities are used
 * length > The actual external length for SIMO
]]
function LaserLib.SetExLength(length)
  DATA.BLENG = 0
  if(length and length > 0) then
    DATA.BLENG = length
  end
end

--[[
 * Updates the beam source according to the current entity
 * entity > Reference to the current entity
 * former > Reference to the source from last split
]]
function LaserLib.SetExSources(...)
  DATA.BESRC = nil -- Initial value
  for idx, ent in pairs({...}) do
    if(LaserLib.IsPrimary(ent)) then
      DATA.BESRC = ent; break
    end -- Source is found
  end -- No source is found
end

--[[
 * Updates the beam source according to the current entity
 * entity > Reference to the current entity
 * former > Reference to the source from last split
]]
function LaserLib.SetExColorRGBA(mr, mg, mb, ma)
  DATA.BCOLR = nil -- Initial value
  if(mr or mg or mb or ma) then
    local m = DATA.CLMX -- Localize max
    local c = Color(0,0,0,0); DATA.BCOLR = c
    if(istable(mr)) then -- Color object
      c.r = math.Clamp(mr[1] or mr["r"], 0, m)
      c.g = math.Clamp(mr[2] or mr["g"], 0, m)
      c.b = math.Clamp(mr[3] or mr["b"], 0, m)
      c.a = math.Clamp(mr[4] or mr["a"], 0, m)
    else -- Must utilize numbers
      c.r =  math.Clamp(mr or 0, 0, m)
      c.g =  math.Clamp(mg or 0, 0, m)
      c.b =  math.Clamp(mb or 0, 0, m)
      c.a =  math.Clamp(ma or 0, 0, m)
    end -- We have input parameter
  end -- We do not have input parameter
end

--[[
 * This implements beam OOP with all its specifics
]]
local mtBeam = {} -- Object metatable for class methods
      mtBeam.__type  = "BeamData" -- Store class type here
      mtBeam.__index = mtBeam -- If not found in self search here
      mtBeam.__vtorg = Vector() -- Temporary calculation origin vector
      mtBeam.__vtdir = Vector() -- Temporary calculation direct vector
      mtBeam.A = {gtREFRACT["air"  ], "air"  } -- General air info
      mtBeam.W = {gtREFRACT["water"], "water"} -- General water info
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
  self.BmLength = math.max(tonumber(length) or 0, 0) -- Initial start beam length
  if(self.BmLength == 0) then return end -- Length is not available exit now
  self.VrDirect = Vector(direct) -- Copy direction and normalize when present
  if(self.VrDirect:LengthSqr() > 0) then self.VrDirect:Normalize() else return end
  self.VrOrigin = Vector(origin) -- Create local copy for origin not to modify it
  self.TrMedium = {} -- Contains information for the mediums being traversed
  self.TvPoints = {Size = 0} -- Create empty vertices array for the client
  -- This will apply the external configuration during the beam creation
  if(DATA.BBONC > 0) then self.MxBounce = DATA.BBONC; DATA.BBONC = 0 -- External count
  else self.MxBounce = DATA.MBOUNCES:GetInt() end -- Internal count from the convar
  if(DATA.BCOLR) then self.BmColor = DATA.BCOLR; DATA.BCOLR = nil end -- Beam start color
  if(DATA.BESRC) then self.BoSource = DATA.BESRC; DATA.BESRC = nil end -- Original source
  if(DATA.BLENG > 0) then self.BoLength = DATA.BLENG; DATA.BLENG = 0 end -- Original length
  self.TrMedium.S = {mtBeam.A[1], mtBeam.A[2]} -- Source beam medium
  self.TrMedium.D = {mtBeam.A[1], mtBeam.A[2]} -- Destination beam medium
  self.TrMedium.M = {mtBeam.A[1], mtBeam.A[2], Vector()} -- Medium memory
  self.NvDamage = math.max(tonumber(damage) or 0, 0) -- Initial current beam damage
  self.NvWidth  = math.max(tonumber(width ) or 0, 0) -- Initial current beam width
  self.NvForce  = math.max(tonumber(force ) or 0, 0) -- Initial current beam force
  self.DmRfract = 0 -- Diameter trace-back dimensions of the entity
  self.TrRfract = 0 -- Full length for traces not being bound by hit events
  self.BmTracew = 0 -- Make sure beam is zero width during the initial trace hit
  self.IsTrace  = true -- Library is still tracing the beam and calculating nodes
  self.StRfract = false -- Start tracing the beam inside a medium boundary
  self.TrFActor = false -- Trace filter was updated by actor and must be cleared
  self.NvIWorld = false -- Ignore world flag to make it hit the other side
  self.IsRfract = false -- The beam is refracting inside and entity or world solid
  self.NvMask   = MASK_ALL -- Trace mask. When not provided negative one is used
  self.NvCGroup = COLLISION_GROUP_NONE -- Collision group. Missing then COLLISION_GROUP_NONE
  self.NvBounce = self.MxBounce -- Amount of bounces to control the infinite loop
  self.RaLength = self.BmLength -- Range of the length. Just like wire ranger
  self.NvLength = self.BmLength -- The actual beam lengths subtracted after iterations
  return self
end

--[[
 * Returns the desired nore information
 * index > Node index to be used. Defaults to node size
]]
function mtBeam:GetNode(index)
  local tno = self.TvPoints
  if(index) then
    return tno[index]
  else
    return tno[tno.Size]
  end
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
]]
function mtBeam:Bounce()
  -- We are neither hitting something nor still tracing or hit dedicated entity
  self.NvBounce = self.NvBounce - 1 -- Refresh medium pass trough information
  return self -- Coding effective API
end

--[[
 * Checks the condition for the beam loop to terminate
 * Returns boolean when the beam must continue
]]
function mtBeam:IsFinish()
  return (not self.IsTrace or
              self.NvBounce <= 0 or
              self.NvLength <= 0)
end

--[[
 * Checks whenever the beam runs the first iteration
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
 * margn > Margin to adjust the temporary with
]]
function mtBeam:GetNudge(margn)
  local vtm = self.__vtorg
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
 * from the last medium stored in memory and
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
 * To straight calculate the intersection point
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
  return vop -- Water-air intersection point
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
 * index > Texture index relative to `gtREFRACT[ID]`
 * trace > Trace structure of the current iteration
]]
function mtBeam:SetRefractContent(index, trace)
  local name = gtREFRACT[index]
  if(not name) then return self end
  trace.Fraction = 0
  trace.HitTexture = name
  self.TrMedium.S[2] = name
  self.TrMedium.S[1] = gtREFRACT[name]
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
    local vtm = self.__vtorg; vtm:Set(trace.HitNormal)
    vtm:Mul(-DATA.TRDG * self.BmTracew); trace.HitPos:Add(vtm)
  end -- At this point we know exactly how long will the trace be
  -- In this case the value of node register length is calculated
  trace.LengthBS = length -- Actual beam requested length
  trace.LengthFR = length * trace.Fraction -- Length fraction
  trace.LengthLS = length * trace.FractionLeftSolid -- Length fraction LS
  trace.LengthNR = self.IsRfract and (self.DmRfract - trace.LengthFR) or nil
  return trace
end

--[[
 * Beam traverses from medium [1] to medium [2]
 * origin > The node position to be registered
 * nbulen > Update the length according to the new node
 *          Positive number when provided else internal length
 *          Pass true boolean to update the node with distance
 * bedraw > Enable draw beam node on the CLIENT
 *          Use this for portals when skip gap is needed
 *   info > Trace data points row for a given node ID
 *    [1] > Node location in 3D space position (vector)
 *    [2] > Node beam current width automatic (number)
 *    [3] > Node beam current damage automatic (number)
 *    [4] > Node beam current force automatic (number)
 *    [5] > Whenever to draw or not beam line (boolean)
 *    [6] > Color updated by various filters (color)
]]
function mtBeam:RegisterNode(origin, nbulen, bedraw)
  local info = self.TvPoints -- Local reference to stack
  local node, width = Vector(origin), self.NvWidth
  local damage, force = self.NvDamage , self.NvForce
  local bedraw = (bedraw or bedraw == nil) and true or false
  local cnlen = math.max((tonumber(nbulen) or 0), 0)
  if(cnlen > 0) then -- Subtract the path trough the medium
    self.NvLength = self.NvLength - cnlen -- Direct length
  else local size = info.Size -- Read the node stack size
    if(size > 0 and nbulen) then -- Length is not provided
      local prev, vtmp = info[size][1], self.__vtorg
      vtmp:Set(node); vtmp:Sub(prev) -- Relative to previous
      self.NvLength = self.NvLength - vtmp:Length()
    end -- Use the nodes and make sure previous exists
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
  local info = self.TvPoints -- Localize stack
  local size = info.Size     -- Read stack size
  local node = info[size]    -- Index top element
  if(rate and size > 0) then -- There is sanity with adjusting
    self.NvDamage = rate * self.NvDamage
    self.NvForce  = rate * self.NvForce
    self.NvWidth  = rate * self.NvWidth
    -- Update the parameters used for drawing the beam trace
    node[2] = self.NvWidth -- Adjusts visuals for width
    node[3] = self.NvDamage -- Adjusts visuals for damage
    node[4] = self.NvForce -- Adjusts visuals for force
  end -- Check out power rating so the trace absorbed everything
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
  local vtm = self.__vtorg -- Index temporary
  local nxt, prv = set[siz][1], set[siz-1][1]
  vtm:Set(nxt); vtm:Sub(prv); vtm:Normalize()
  vtm:Mul(self.NvLength); nxt:Add(vtm)
  self.NvLength = 0; return false
end

--[[
 * Prepares the laser beam structure for entity refraction
 * origin  > New beam origin location vector
 * direct  > New beam ray direction vector
 * target  > New entity target being switched
 * refract > Refraction descriptor entry
 * key     > Refraction descriptor key
]]
function mtBeam:SetRefractEntity(origin, direct, target, refract, key)
  -- Register desination medium and raise calculate refraction flag
  if(refract and key) then
    self.TrMedium.D[1] = refract -- First element is always structure
    self.TrMedium.D[2] = tostring(key or "") -- Second element is always the index found
  else self:SetMediumDestn(refract) end -- Otherwise refract contains the whole thing
  -- Get the trace ready to check the other side and point and register the location
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
 * https://wiki.facepunch.com/gmod/Enums/MAT
 * https://wiki.facepunch.com/gmod/Entity:GetMaterialType
 * Retrieves material override for a trace or use the default
 * Toggles material original selection when not available
 * When flag is disabled uses the material type for checking
 * The value must be available for client and server sides
 * trace > Reference to trace result structure
 * Returns: Material extracted from the entity on server and client
]]
function mtBeam:GetMaterialID(trace)
  if(not trace) then return nil end
  if(not trace.Hit) then return nil end
  if(trace.HitWorld) then
    local mat = trace.HitTexture -- Use trace material type
    if(mat:sub(1,1) == "*" and mat:sub(-1,-1) == "*") then
      mat = gtMATYPE[trace.MatType] -- Material lookup
    end -- **studio**, **displacement**, **empty**
    return mat
  else
    local ent = trace.Entity
    if(not LaserLib.IsValid(ent)) then return nil end
    local mat = ent:GetMaterial() -- Entity may not have override
    if(mat == "") then -- Empty then use the material type
      if(self.BmNoover) then -- No override is available use original
        mat = ent:GetMaterials()[1] -- Just grab the first material
      else -- Gmod cannot simply decide which material is hit
        mat = trace.HitTexture -- Use trace material type
        if(mat:sub(1,1) == "*" and mat:sub(-1,-1) == "*") then
          mat = gtMATYPE[trace.MatType] -- Material lookup
        end -- **studio**, **displacement**, **empty**
      end -- Physics object has a single surface type related to model
    end
    return mat
  end
end

--[[
 * Samples the medium ahead in given direction
 * This aims to hit a solids of the map or entities
 * On success will return the refraction surface entry
 * Must update custom special case `gmod_laser_refractor`
 * origin > Refraction medium boundary origin
 * direct > Refraction medium boundary surface direct
 * trace  > Trace structure to store the result
]]
function mtBeam:GetSolidMedium(origin, direct, filter, trace)
  local tr = TraceBeam(origin, direct, DATA.NUGE,
    filter, MASK_SOLID, COLLISION_GROUP_NONE, false, 0, trace)
  if(not (tr or tr.Hit)) then return nil end -- Nothing traces
  if(tr.Fraction > 0) then return nil end -- Has prop air gap
  local ent, mat = tr.Entity, self:GetMaterialID(tr)
  if(LaserLib.IsValid(ent)) then
    if(ent:GetClass() == "gmod_laser_refractor") then
      local refract, key = GetMaterialEntry(mat, gtREFRACT)
      return ent:GetRefractInfo(refract), key -- Return the initial key
    else
      return GetMaterialEntry(mat, gtREFRACT)
    end
  else
    return GetMaterialEntry(mat, gtREFRACT)
  end
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
 * ratio > Reflection ratio value
 * trace > The current trace result
]]
function mtBeam:Reflect(ratio, trace)
  self.VrDirect:Set(LaserLib.GetReflected(self.VrDirect, trace.HitNormal))
  self.VrOrigin:Set(trace.HitPos)
  self.NvLength = self.NvLength - self.NvLength * trace.Fraction
  if(self.BrReflec) then self:SetPowerRatio(ratio) end
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
  -- When beam started inside the water and hit outside the water
  local wat = self.__water -- Local reference indexing water
  local vtm = self.__vtorg; LaserLib.VecNegate(self.VrDirect)
  local vwa = self:IntersectRayPlane(wat.P, wat.N)
  -- Registering the node cannot be done with direct subtraction
  LaserLib.VecNegate(self.VrDirect); self:RegisterNode(vwa, true)
  vtm:Set(wat.N); LaserLib.VecNegate(vtm)
  local vdir, bnex = LaserLib.GetRefracted(self.VrDirect, vtm,
                       mtBeam.W[1][1], mtBeam.A[1][1])
  if(bnex) then
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
 * The beam may start in the water or hit it and switch
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
 * Setups the class for world and water refraction
]]
function mtBeam:SetRefractWorld(trace, refract, key)
  if(refract and key) then
    self.TrMedium.D[1] = refract -- First element is always structure
    self.TrMedium.D[2] = tostring(key or "") -- Second element is always the index found
  else self:SetMediumDestn(refract) end -- Otherwise refract contains the whole thing
  -- Subtract traced length from total length because we have hit something
  self.NvLength = self.NvLength - self.NvLength * trace.Fraction
  self.TrRfract = self.NvLength -- Remaining in refract mode
  -- Separate control for water and non-water
  if(self:IsAir()) then -- There is no water plane registered
    self.IsRfract = true -- Beam is inside another non water solid
    self.NvIWorld = false -- World transparent objects do not need world ignore
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
 * When present transfers the beam to the new medium
 * origin > Origin position to be checked ( not mandatory )
 * direct > Ray direction vector override ( not mandatory )
 * normal > Normal vector of the refraction surface
 * target > Entity being the current beam target
 * trace  > Trace structure to temporary store the result
]]
function mtBeam:IsTraverse(origin, direct, normal, target, trace)
  local org = mtBeam.__vtorg; org:Set(origin or self.VrOrigin)
  local dir = mtBeam.__vtdir; dir:Set(direct or self.VrDirect)
  local refract = self:GetSolidMedium(org, dir, target, trace)
  if(not refract) then return false end
  -- Refract the hell out of this requested beam with enity destination
  local vdir, bnex, bsam = LaserLib.GetRefracted(dir,
                 normal, self.TrMedium.D[1][1], refract[1])
  if(bnex) then
    self.IsRfract, self.StRfract = false, true -- Force start-refract
    self:Redirect(org, nil, true) -- The beam did not traverse mediums
    self:SetMediumMemory(self.TrMedium.D, nil, normal)
    if(self.BrRefrac) then self:SetPowerRatio(refract[2]) end
  else -- Get the trace ready to check the other side and register the location
    self:SetTraceNext(org, vdir) -- The beam did not traverse mediums
    if(self.BrRefrac) then self:SetPowerRatio(self.TrMedium.D[1][2]) end
  end; return true -- Apply power ratio when requested
end

--[[
 * This does some logic on the start entity
 * Preforms some logic to calculate the filter
 * entity > Entity we intend the start the beam from
]]
function mtBeam:SourceFilter(entity)
  if(not LaserLib.IsValid(entity)) then return self end
  -- Populated custom depending on the API
  if(entity.RecuseBeamID and self.BmRecstg == 1) then -- Recursive
    entity.RecuseBeamID = 0 -- Reset entity hit report index
  end -- We need to reset the top index hit reports count
  -- Make sure the initial laser source is skipped
  if(entity:IsPlayer()) then local eGun = entity:GetActiveWeapon()
    if(LaserLib.IsUnit(eGun)) then self.BmSource, self.TeFilter = eGun, {entity, eGun} end
  elseif(entity:IsWeapon()) then local ePly = entity:GetOwner()
    if(LaserLib.IsUnit(entity)) then self.BmSource, self.TeFilter = entity, {entity, ePly} end
  else -- Switch the filter according to the weapon the player is holding
    self.BmSource, self.TeFilter = entity, entity
  end; return self
end

--[[
 * Returns the beam current active source entity
]]
function mtBeam:GetSource()
  return (self.BoSource or self.BmSource)
end

--[[
 * Returns the beam current active length
]]
function mtBeam:GetLength()
  return (self.BoLength or self.BmLength)
end

--[[
 * Reads draw color from the beam object when needed
]]
function mtBeam:GetColorRGBA(bcol)
  local com = (self.NvColor or self.BmColor)
  if(not com) then local src = self:GetSource()
    com = (com or src:GetBeamColorRGBA(true))
  end -- No forced colors are present use source
  if(bcol) then return com end -- Return object
  return com.r, com.g, com.b, com.a -- Numbers
end

--[[
 * Cashes the currently used beam color when needed
]]
function mtBeam:SetColorRGBA(mr, mg, mb, ma)
  local c, m = self.NvColor, LaserLib.GetData("CLMX")
  if(not c) then c = Color(0,0,0,0); self.NvColor = c end
  if(istable(mr)) then
    c.r = math.Clamp(mr[1] or mr["r"], 0, m)
    c.g = math.Clamp(mr[2] or mr["g"], 0, m)
    c.b = math.Clamp(mr[3] or mr["b"], 0, m)
    c.a = math.Clamp(mr[4] or mr["a"], 0, m)
  else
    c.r =  math.Clamp(mr or 0, 0, m)
    c.g =  math.Clamp(mg or 0, 0, m)
    c.b =  math.Clamp(mb or 0, 0, m)
    c.a =  math.Clamp(ma or 0, 0, m)
  end; return self
end

--[[
 * This does post-update and registers beam sources
 * Preforms some logick to calculate the filter
 * trace > Trace result after the last iteration
]]
function mtBeam:UpdateSource(trace)
  local entity, target = self.BmSource, trace.Entity
  -- Calculates the range as beam distance traveled
  if(trace.Hit and self.RaLength > self.NvLength) then
    self.RaLength = self.RaLength - self.NvLength
  end -- Update hit report of the source
  if(entity.SetHitReport) then
    -- Update the current beam source hit report
    entity:SetHitReport(self, trace) -- What we just hit
  end -- Register us to the target sources table
  if(entity.RecuseBeamID and self.BmRecstg == 1) then -- Recursive
    entity:SetHitReportMax(entity.RecuseBeamID) -- Update reports
  end -- We need to apply the top index hit reports count
  if(LaserLib.IsValid(target) and target.RegisterSource) then
    -- Register the beam initial entity to target sources
    target:RegisterSource(entity) -- Register target in sources
  end; return self -- Coding effective API
end

--[[
 * This calculates the primary refraction info when we change boundary
 * index > Refraction index for the new medium boundaty
 * trace > Trace result structure of the current trace beam
]]
function mtBeam:GetBoundaryEntity(index, trace)
  local bnex, bsam, vdir -- Refraction entity direction and reflection
  -- Call refraction cases and prepare to trace-back
  if(self.StRfract) then -- Bounces were decremented so move it up
    if(self:IsFirst()) then
      vdir, bnex = Vector(self.VrDirect), true -- Node starts inside solid
    else -- When two props are stuck save the middle boundary and traverse
      -- When the traverse mediums is different and node is not inside a laser
      if(self:IsMemory(index, trace.HitPos)) then
        vdir, bnex, bsam = LaserLib.GetRefracted(self.VrDirect,
                       self.TrMedium.M[3], self.TrMedium.M[1][1], index)
        -- Do not waste game ticks to refract the same refraction ratio
      else -- When there is no medium refractive index traverse change
        vdir, bsam = Vector(self.VrDirect), true -- Keep the last beam direction
      end -- Finish start-refraction for current iteration
    end -- Marking the fraction being zero and refracting from the last entity
    self.StRfract = false -- Make sure to disable the flag again
  else -- Otherwise do a normal water-entity-air refraction
    vdir, bnex, bsam = LaserLib.GetRefracted(self.VrDirect,
                   trace.HitNormal, self.TrMedium.S[1][1], index)
  end
  return bnex, bsam, vdir
end

--[[
 * This traps the beam by following the trace
 * You can mark trace view points as visible
 * sours > Override for laser unit entity `self`
 * imatr > Reference to a beam material object
 * color > Color structure reference for RGBA
]]
function mtBeam:Draw(sours, imatr, color)
  if(SERVER) then return self end
  local tvpnt = self.TvPoints
  -- Check node availability
  if(not tvpnt[1]) then return self end
  if(not tvpnt.Size) then return self end
  if(tvpnt.Size <= 0) then return self end
  -- Update rendering boundaries
  local sours = (sours or self.BmSource)
  local ushit = LocalPlayer():GetEyeTrace().HitPos
  local bbmin = sours:LocalToWorld(sours:OBBMins())
  local bbmax = sours:LocalToWorld(sours:OBBMaxs())
  -- Extend render bounds with player hit position
  LaserLib.UpdateRB(bbmin, ushit, math.min)
  LaserLib.UpdateRB(bbmax, ushit, math.max)
  -- Extend render bounds with the first node
  LaserLib.UpdateRB(bbmin, tvpnt[1][1], math.min)
  LaserLib.UpdateRB(bbmax, tvpnt[1][1], math.max)
  -- Adjust the render bounds with world-space coordinates
  sours:SetRenderBoundsWS(bbmin, bbmax) -- World space is faster
  -- Material must be cached and updated with left click setup
  if(imatr) then render.SetMaterial(imatr) end
  local cup = (color or self.BmColor)
  local spd = DATA.DRWBMSPD:GetFloat()
  -- Draw the beam sequentially being faster
  for idx = 2, tvpnt.Size do
    local org = tvpnt[idx - 1]
    local new = tvpnt[idx - 0]
    local ntx, otx = new[1], org[1] -- Read origin
    local wdt = LaserLib.GetWidth(org[2]) -- Start width
    -- Make sure the coordinates are converted to world ones
    LaserLib.UpdateRB(bbmin, ntx, math.min)
    LaserLib.UpdateRB(bbmax, ntx, math.max)
    -- When we need to draw the beam with rendering library
    if(org[5]) then cup = (org[6] or cup) -- Change color
      local dtm, len = (spd * CurTime()), ntx:Distance(otx)
      render.DrawBeam(otx, ntx, wdt, dtm + len / 16, dtm, cup)
    end -- Draw the actual beam texture
  end -- Adjust the render bounds with world-space coordinates
  sours:SetRenderBoundsWS(bbmin, bbmax); return self
end

--[[
 * This is actually faster than stuffing all the beams
 * information for every laser in a dedicated table and
 * draw the table elements one by one at once.
 * sours > Entity keeping the beam effects internals
 * trace > Trace result received from the beam
 * endrw > Draw enabled flag from beam sources
]]
function mtBeam:DrawEffect(sours, trace, endrw)
  if(SERVER) then return self end
  local sours = (sours or self:GetSource())
  if(trace and not trace.HitSky and
    endrw and sours.isEffect)
  then -- Drawing effects is enabled
    if(not sours.dtEffect) then
      sours.dtEffect = EffectData()
    end -- Allocate effect class
    if(trace.Hit) then
      local ent = trace.Entity
      local eff = sours.dtEffect
      if(not LaserLib.IsUnit(ent)) then
        eff:SetStart(trace.HitPos)
        eff:SetOrigin(trace.HitPos)
        eff:SetNormal(trace.HitNormal)
        util.Effect("AR2Impact", eff)
        -- Draw particle effects
        if(self.NvDamage > 0) then
          if(not (ent:IsPlayer() or ent:IsNPC())) then
            local dmr = DATA.MXBMDAMG:GetFloat()
            local mul = (self.NvDamage / dmr)
            local dir = LaserLib.GetReflected(self.VrDirect,
                                              trace.HitNormal)
            eff:SetNormal(dir)
            eff:SetScale(0.5)
            eff:SetRadius(10 * mul)
            eff:SetMagnitude(3 * mul)
            util.Effect("Sparks", eff)
          else
            util.Effect("BloodImpact", eff)
          end
        end
      end
    end
  end; return self
end

--[[
 * Function handler for calculating SISO actor routines
 * These are specific handlers for specific classes
 * having single input beam and single output beam
 * trace > Reference to trace result structure
 * beam  > Reference to laser beam class
]]
local gtACTORS = {
  ["event_horizon"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent, src = trace.Entity, beam:GetSource()
    local pob, dir = trace.HitPos, beam.VrDirect
    local eff, out = src.isEffect, ent.Target
    if(out == ent) then return end -- We need to go somewhere
    if(not LaserLib.IsValid(out)) then return end
    -- Leave networking to CAP. Invalid target. Stop
    local pot, dit = ent:GetTeleportedVector(pob, dir)
    if(SERVER and ent:IsOpen() and eff) then -- Library effect flag
      ent:EnterEffect(pob, beam.NvWidth) -- Enter effect
      out:EnterEffect(pot, beam.NvWidth) -- Exit effect
    end -- Stargate ( CAP ) requires little nudge in the origin vector
    beam.VrOrigin:Set(pot); beam.VrDirect:Set(dit)
    -- Otherwise the trace will get stick and will hit again
    beam:RegisterNode(beam.VrOrigin, false, true)
    beam.TeFilter, beam.TrFActor = out, true
    beam.IsTrace = true -- CAP networking is correct. Continue
  end,
  ["gmod_laser_portal"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent, src = trace.Entity, beam:GetSource()
    if(not ent:IsHitNormal(trace)) then return end
    local idx = (tonumber(ent:GetEntityExitID()) or 0)
    if(idx <= 0) then return end -- No output ID chosen
    local out = ent:GetActiveExit(idx) -- Validate output entity
    if(not out) then return end -- No output ID. Missing entity
    local nrm = ent:GetNormalLocal() -- Read current normal
    local bnr = (nrm:LengthSqr() > 0) -- When the model is flat
    local mir = ent:GetMirrorExitPos()
    local pos, dir = trace.HitPos, beam.VrDirect
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
    beam.VrOrigin:Set(nps); beam.VrDirect:Set(ndr)
    beam:RegisterNode(beam.VrOrigin, false, true)
    beam.TeFilter, beam.TrFActor = out, true
    beam.IsTrace = true -- Output model is validated. Continue
  end,
  ["prop_portal"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent, src, out = trace.Entity, beam:GetSource()
    if(not ent:IsLinked()) then return end -- No linked pair
    if(SERVER) then out = ent:FindOpenPair() -- Retrieve open pair
    else out = Entity(ent:GetNWInt("laseremitter_portal", 0)) end
    -- Assume that output portal will have the same surface offset
    if(not LaserLib.IsValid(out)) then return end -- No linked pair
    ent:SetNWInt("laseremitter_portal", out:EntIndex())
    local node = beam:GetNode(); node[5] = true
    local dir, pos = beam.VrDirect, trace.HitPos
    local mav, vsm = GetMarginPortal(ent, pos, dir)
    beam:RegisterNode(mav, false, false)
    local nps, ndr = GetBeamPortal(ent, out, pos, dir)
    beam:RegisterNode(nps); nps:Add(vsm * ndr)
    beam.VrOrigin:Set(nps); beam.VrDirect:Set(ndr)
    beam:RegisterNode(nps)
    beam.TeFilter, beam.TrFActor = out, true
    beam.IsTrace = true -- Output portal is validated. Continue
  end,
  ["gmod_laser_dimmer"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, beam, trace, bmln)
    if(trace and trace.Hit and beam and bdot) then
      beam.IsTrace = true -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamReplicate() and 1 or mdot)
      local node = beam:SetPowerRatio(vdot) -- May absorb
      beam.VrOrigin:Set(trace.HitPos)
      beam.TeFilter, beam.TrFActor = ent, true -- Makes beam pass the dimmer
      node[1]:Set(trace.HitPos) -- We are not portal update position
      node[5] = true            -- We are not portal enable drawing
    end
  end,
  ["seamless_portal"] = function(beam, trace)
    beam:Finish(trace)
    local ent = trace.Entity
    local out = ent:ExitPortal()
    if(not LaserLib.IsValid(out)) then return end
    local node = beam:GetNode(); node[5] = true
    local osz, esz = out:GetExitSize(), ent:GetExitSize()
    local szx = (osz.x / esz.x)
    local szy = (osz.y / esz.y)
    local szz = (osz.z / esz.z)
    local pos, dir = trace.HitPos, beam.VrDirect
    local mav, vsm = GetMarginPortal(ent, pos, dir, trace.HitNormal)
    beam:RegisterNode(mav, false, false)
    local nps, ndr = GetBeamPortal(ent, out, pos, dir,
      function(vpos)
          vpos.x =  vpos.x * szx
          vpos.y = -vpos.y * szy
          vpos.z =  vpos.z * szz
      end,
      function(vdir)
        vdir.y = -vdir.y
        vdir.z = -vdir.z
      end)
    beam:RegisterNode(nps); nps:Add(vsm * ndr)
    beam.VrOrigin:Set(nps); beam.VrDirect:Set(ndr)
    beam:RegisterNode(nps)
    beam.TeFilter, beam.TrFActor = out, true
    beam.IsTrace = true -- Output portal is validated. Continue
  end,
  ["gmod_laser_rdivider"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm = ent:GetHitNormal()
    local bdot = ent:GetHitPower(norm, beam, trace)
    if(trace and trace.Hit and bdot) then
      local aim, nrm = beam.VrDirect, trace.HitNormal
      local ray = LaserLib.GetReflected(aim, nrm)
      if(SERVER) then
        ent:DoDamage(ent:DoBeam(trace.HitPos, aim, beam))
        ent:DoDamage(ent:DoBeam(trace.HitPos, ray, beam))
      else
        ent:DrawBeam(ent:DoBeam(trace.HitPos, aim, beam))
        ent:DrawBeam(ent:DoBeam(trace.HitPos, ray, beam))
      end
    end
  end,
  ["gmod_laser_filter"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent, src = trace.Entity, beam:GetSource()
    local norm = ent:GetHitNormal()
    local bdot = ent:GetHitPower(norm, beam, trace)
    if(trace and trace.Hit and beam and bdot) then
      local info = beam.TvPoints -- Read current node stack
      local node = info[info.Size] -- Extract nodes stack size
      local sc = beam:GetColorRGBA(true)
      local ec = ent:GetBeamColorRGBA(true)
      local matc = ent:GetInBeamMaterial()
      local mats = src:GetInBeamMaterial()
      if(ent:GetBeamPassEnable()) then
        local mc = (0.15 * DATA.CLMX) -- Color tolerance
        local mcr = (math.abs(sc.r - ec.r) <= mc)
        local mcg = (math.abs(sc.g - ec.g) <= mc)
        local mcb = (math.abs(sc.b - ec.b) <= mc)
        local mca = (math.abs(sc.a - ec.a) <= mc)
        if(ent:GetBeamPassTexture()) then
          if(matc ~= "" and (matc ~= mats)) then return end
        else -- Block the given texture
          if(matc ~= "" and (matc == mats)) then return end
        end
        if(ent:GetBeamPassColor()) then
          if(ec.r > 0 and not mcr) then return end
          if(ec.g > 0 and not mcg) then return end
          if(ec.b > 0 and not mcb) then return end
          if(ec.a > 0 and not mca) then return end
        else -- Block similar beams
          if(ec.r > 0 and mcr) then return end
          if(ec.g > 0 and mcg) then return end
          if(ec.b > 0 and mcb) then return end
          if(ec.a > 0 and mca) then return end
        end
        beam.VrOrigin:Set(trace.HitPos)
        beam.TeFilter, beam.TrFActor = ent, true -- Makes beam pass the dimmer
        node[1]:Set(trace.HitPos) -- We are not portal update position
        node[5] = true            -- We are not portal enable drawing
        beam.IsTrace = true -- Beam hits correct surface. Continue
      else -- The beam did not fell victim to direct draw filtering
        local width, damage, force, length
        if(ent:GetBeamReplicate()) then
          width  = beam.NvWidth
          damage = beam.NvDamage
          force  = beam.NvForce
          length = beam.NvLength
        else -- Color needs to be changed for the current node
          if(not node[6]) then node[6] = Color(0,0,0,0) end
          if(ent:GetBeamPowerClamp()) then
            local ew, bw = ent:GetInBeamWidth() , beam.NvWidth
            local ed, bd = ent:GetInBeamDamage(), beam.NvDamage
            local ef, bf = ent:GetInBeamForce() , beam.NvForce
            local el, bl = ent:GetInBeamLength(), beam.NvLength
            width  = (ew > 0) and math.Clamp(bw, 0, ew) or bw
            damage = (ed > 0) and math.Clamp(bd, 0, ed) or bd
            if(not LaserLib.IsPower(width, damage)) then return end
            force  = (ef > 0) and math.Clamp(bf, 0, ef) or bf
            length = (el > 0) and math.Clamp(bl, 0, el) or bl
            node[6].r = math.Clamp(sc.r, 0, ec.r)
            node[6].g = math.Clamp(sc.g, 0, ec.g)
            node[6].b = math.Clamp(sc.b, 0, ec.b)
            node[6].a = math.Clamp(sc.a, 0, ec.a)
          else
            width  = math.max(beam.NvWidth  - ent:GetInBeamWidth() , 0)
            damage = math.max(beam.NvDamage - ent:GetInBeamDamage(), 0)
            if(not LaserLib.IsPower(width, damage)) then return end
            force  = math.max(beam.NvForce  - ent:GetInBeamForce() , 0)
            length = math.max(beam.NvLength - ent:GetInBeamLength(), 0)
            node[6].r = math.max(sc.r - ec.r, 0)
            node[6].g = math.max(sc.g - ec.g, 0)
            node[6].b = math.max(sc.b - ec.b, 0)
            node[6].a = math.max(sc.a - ec.a, 0)
          end
          beam:SetColorRGBA(node[6]) -- Last beam color being used
        end -- Remove from the output beams with such color and material
        beam.NvLength  = length; -- Length not used in visuals
        beam.NvWidth   = width ; node[2] = width
        beam.NvDamage  = damage; node[3] = damage
        beam.NvForce   = force ; node[4] = force
        beam.VrOrigin:Set(trace.HitPos)
        beam.TeFilter, beam.TrFActor = ent, true -- Makes beam pass the dimmer
        node[1]:Set(trace.HitPos) -- We are not portal update position
        node[5] = true            -- We are not portal enable drawing
        beam.IsTrace = true -- Beam hits correct surface. Continue
      end
    end
  end,
  ["gmod_laser_parallel"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, beam, trace, bmln)
    if(trace and trace.Hit and beam and bdot) then
      beam.IsTrace = true -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamDimmer() and mdot or 1)
      local node = beam:SetPowerRatio(vdot) -- May absorb
      beam.VrOrigin:Set(trace.HitPos)
      beam.VrDirect:Set(trace.HitNormal); LaserLib.VecNegate(beam.VrDirect)
      beam.TeFilter, beam.TrFActor = ent, true -- Makes beam pass the parallel
      node[1]:Set(trace.HitPos) -- We are not portal update node
      node[5] = true            -- We are not portal enable drawing
    end
  end,
  ["gmod_laser_reflector"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local mat = beam:GetMaterialID(trace)
    local reflect = GetMaterialEntry(mat, gtREFLECT)
    if(not reflect) then return end
    local node = beam:GetNode()
    local ent = trace.Entity; beam.IsTrace = true
    if(beam.BrReflec) then -- May absorb
      local ratio = ent:GetReflectRatio()
      beam:SetPowerRatio((ratio > 0) and ratio or reflect[1])
    end
    beam.VrDirect:Set(LaserLib.GetReflected(beam.VrDirect, trace.HitNormal))
    beam.VrOrigin:Set(trace.HitPos)
    node[1]:Set(trace.HitPos) -- We are not portal update node
    node[5] = true            -- We are not portal enable drawing
  end,
  ["gmod_laser_refractor"] = function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local mat = beam:GetMaterialID(trace) -- Current extracted material as string
    local refract, key = GetMaterialEntry(mat, gtREFRACT)
    if(not refract) then return end
    local ent = trace.Entity; beam.IsTrace = true
    local node, rcpy = beam:GetNode(), ent:GetRefractInfo(refract)
    local bnex, bsam, vdir = beam:GetBoundaryEntity(rcpy[1], trace)
    if(ent:GetHitSurfaceMode()) then
      beam:Redirect(trace.HitPos, vdir) -- Redirect the beam on the surface
      beam.TeFilter, beam.TrFActor = ent, true -- Makes beam pass the entity
    else -- Refraction done using multiple surfaces
      if(bnex or bsam) then -- We have to change mediums
        beam:SetRefractEntity(trace.HitPos, vdir, ent, rcpy, key)
      else -- Redirect the beam with the reflected ray
        beam:Redirect(trace.HitPos, vdir)
      end
    end -- Apply refraction ratio. Entity may absorb the power
    if(beam.BrReflec) then beam:SetPowerRatio(rcpy[2]) end
    node[1]:Set(trace.HitPos) -- We are not portal update node
    node[5] = true            -- We are not portal enable drawing
  end
}

function LaserLib.SetActor(ent, func)
  if(not LaserLib.IsValid(ent)) then return end
  gtACTORS[ent:GetClass()] = func
end

--[[
 * Traces a laser beam from the entity provided
 * entity > Entity origin of the beam ( laser )
 * origin > Initial ray world position vector
 * direct > Initial ray world direction vector
 * length > Total beam length to be traced
 * width  > Beam starting width from the origin
 * damage > The amount of damage the beam does
 * force  > The amount of force the beam does
 * usrfle > Use surface material reflecting efficiency
 * usrfre > Use surface material refracting efficiency
 * noverm > Enable interactions with no material override
]]
function LaserLib.DoBeam(entity, origin, direct, length, width, damage, force, usrfle, usrfre, noverm, index, stage)
  -- Parameter validation check. Allocate only when these conditions are present
  if(not LaserLib.IsValid(entity)) then return end -- Source entity must be valid
  -- Create a laser beam object and validate the currently passed ray spawn parameters
  local beam = Beam(origin, direct, width, damage, length, force) -- Creates beam class
  if(not beam) then return end -- Beam parameters are mismatched and traverse is not run
  -- Temporary values that are considered local and do not need to be accessed by hit reports
  local trace, tr, target = {}, {} -- Configure and target and shared trace reference
  -- Reports dedicated values that are being used by other entities and processes
  beam.BrReflec = tobool(usrfle) -- Beam reflection ratio flag. Reduce beam power when reflecting
  beam.BrRefrac = tobool(usrfre) -- Beam refraction ratio flag. Reduce beam power when refracting
  beam.BmNoover = tobool(noverm) -- Beam no override material flag. Try to extract original material
  beam.BmRecstg = (math.max(tonumber(stage) or 0, 0) + 1) -- Beam recursion depth for units that use it
  beam.BmIdenty = math.max(tonumber(index) or 1, 1) -- Beam hit report index. Defaults to one if not provided

  beam:SourceFilter(entity)
  beam:RegisterNode(origin)

  repeat
    -- Run the trace using the defined conditional parameters
    trace = beam:Trace(trace); target = trace.Entity

    -- Initial start so the beam separates from the laser
    if(beam:IsFirst()) then
      beam.TeFilter = nil

      if(trace.HitWorld and trace.StartSolid and beam.NvMask == MASK_ALL) then
        -- Beam starts inside map solid and source must be changed
        if(bit.band(trace.Contents, CONTENTS_WATER) > 0) then
          beam:SetRefractContent(3, trace)
        elseif(bit.band(trace.Contents, CONTENTS_WINDOW) > 0) then
          beam:SetRefractContent(2, trace)
        end
      end
    else
      if(not beam:IsAir() and not beam.IsRfract) then
        if(not beam:IsWater(trace.HitPos)) then
          beam:RefractWaterAir() -- Water to air specifics
          -- Update the trace reference with the new beam
          trace = beam:Trace(trace); target = trace.Entity
        end
      end
    end
    -- Check current target for being a valid specific actor
    -- Stores whenever the trace is valid entity or not and the class
    local ok, act = beam:ActorTarget(target)
    -- Actor flag and specific filter are now reset when present
    if(trace.Fraction > 0) then -- Ignore registering zero length traces
      if(ok) then -- Target is valid and it is a actor
        if(act and gtACTORS[act]) then
          beam:RegisterNode(trace.HitPos, trace.LengthNR, false)
        else -- The trace entity target is not special actor case
          beam:RegisterNode(trace.HitPos, trace.LengthNR)
        end
      else -- The trace has hit invalid entity or world
        if(trace.FractionLeftSolid > 0) then
          local mar = trace.LengthLS -- Use the left solid value
          local org = beam:GetNudge(mar) -- Calculate nudge origin
          -- Register the node at the location the laser lefts the glass
          beam:RegisterNode(org, mar)
        else
          beam:RegisterNode(trace.HitPos, trace.LengthLS)
        end
        beam.StRfract = trace.StartSolid -- Start in world entity
      end
    else -- Trace distance length is zero so enable refraction
      beam.StRfract = true -- Do not alter the beam direction
    end -- Do not put a node when beam does not traverse
    -- When we are still tracing and hit something that is not specific unit
    if(beam.IsTrace and trace.Hit) then
      -- Register a hit so reduce bounces count
      if(ok) then
        if(beam.IsRfract) then
          -- Well the beam is still tracing
          beam.IsTrace = true -- Produce next ray
          -- Decide whenever to go out of the entity according to the hit location
          if(beam:IsAir()) then
            beam:SetMediumSours(mtBeam.A)
          else -- Water general flag is present
            if(beam:IsWater(trace.HitPos)) then
              beam:SetMediumSours(mtBeam.W)
            else -- Check if point is in or out of the water
              beam:SetMediumSours(mtBeam.A)
            end -- Update the source accordingly
          end -- Negate the normal so it must point inwards before refraction
          LaserLib.VecNegate(trace.HitNormal); LaserLib.VecNegate(beam.VrDirect)
          -- Make sure to pick the correct refract exit medium for current node
          if(not beam:IsTraverse(trace.HitPos, nil, trace.HitNormal, target, tr)) then
            -- Refract the hell out of this requested beam with entity destination
            local vdir, bnex = LaserLib.GetRefracted(beam.VrDirect,
                           trace.HitNormal, beam.TrMedium.D[1][1], beam.TrMedium.S[1][1])
            if(bnex) then -- When the beam gets out of the medium
              beam:Redirect(trace.HitPos, vdir, true)
              if(not beam:IsWater()) then -- Check for zero when water only
                if(not beam:IsAir()) then beam:ClearWater() end
              end -- Reset the normal. We are out of the water now
              beam:SetMediumMemory(beam.TrMedium.D, nil, trace.HitNormal)
            else -- Get the trace ready to check the other side and register the location
              beam:SetTraceNext(trace.HitPos, vdir)
            end -- Apply power ratio when requested
            if(usrfre) then beam:SetPowerRatio(beam.TrMedium.D[1][2]) end
          end
        else -- Put special cases here
          if(act and gtACTORS[act]) then
            local suc, err = pcall(gtACTORS[act], beam, trace)
            if(not suc) then beam.IsTrace = false; target:Remove(); error(err) end
          elseif(LaserLib.IsUnit(target)) then -- Trigger for units without action function
            beam:Finish(trace) -- When the entity is unit but does not have actor function
          else -- Otherwise bust continue medium change. Reduce loops when hit dedicated units
            local mat = beam:GetMaterialID(trace) -- Current extracted material as string
            beam.IsTrace  = true -- Still tracing the beam
            local reflect = GetMaterialEntry(mat, gtREFLECT)
            if(reflect and not beam.StRfract) then -- Just call reflection and get done with it..
              beam:Reflect(reflect[1], trace) -- Call reflection method
            else
              local refract, key = GetMaterialEntry(mat, gtREFRACT)
              if(beam.StRfract or (refract and key ~= beam.TrMedium.S[2])) then -- Needs to be refracted
                -- When we have refraction entry and are still tracing the beam
                if(refract) then -- When refraction entry is available do the thing
                  -- Subtract traced length from total length
                  beam.NvLength = beam.NvLength - beam.NvLength * trace.Fraction
                  -- Calculated refraction ray. Reflect when not possible
                  local bnex, bsam, vdir = beam:GetBoundaryEntity(refract[1], trace)
                  -- Check refraction medium boundary and perform according actions
                  if(bnex or bsam) then -- We have to change mediums
                    beam:SetRefractEntity(trace.HitPos, vdir, target, refract, key)
                  else -- Redirect the beam with the reflected ray
                    beam:Redirect(trace.HitPos, vdir)
                  end
                  -- Apply power ratio when requested
                  if(usrfre) then beam:SetPowerRatio(refract[2]) end
                  -- We cannot be able to refract as the requested beam is missing
                else beam:Finish(trace) end
                -- We are neither reflecting nor refracting and have hit a wall
              else beam:Finish(trace) end -- All triggers are processed
            end
          end
        end -- Comes from air then hits and refracts in water or starts in water
      elseif(trace.HitWorld) then
        if(beam.IsRfract) then
          if(not trace.AllSolid) then
            -- Important thing is to consider what is the shape of the world entity
            -- We can either memorize the normal vector which will fail for different shapes
            -- We can either set the trace length insanely long will fail windows close to the ground
            -- Another trace is made here to account for these problems above
            -- Well the beam is still tracing
            beam.IsTrace = true -- Produce next ray
            -- Make sure that outer trace will always hit
            local org, nrm = beam:GetNudge(trace.LengthLS + DATA.NUGE)
            LaserLib.VecNegate(beam.VrDirect)
            -- Margin multiplier for trace back to find correct surface normal
            -- This is the only way to get the proper surface normal vector
            local tr = TraceBeam(org, beam.VrDirect, 2 * DATA.NUGE,
              mtBeam.F, MASK_ALL, COLLISION_GROUP_NONE, false, 0, tr)
            -- Store hit position and normal in beam temporary
            local nrm = Vector(tr.HitNormal); org:Set(tr.HitPos)
            -- Reverse direction of the normal to point inside transparent
            LaserLib.VecNegate(nrm); LaserLib.VecNegate(beam.VrDirect)
            -- Do the refraction according to medium boundary
            if(not beam:IsTraverse(org, nil, nrm, target, tr)) then
              local vdir, bnex = LaserLib.GetRefracted(beam.VrDirect,
                                   nrm, beam.TrMedium.D[1][1], mtBeam.A[1][1])
              if(bnex) then -- When the beam gets out of the medium
                beam:Redirect(org, vdir, true)
                beam:SetMediumSours(mtBeam.A)
                -- Memorizing will help when beam traverses from world to no-collided entity
                beam:SetMediumMemory(beam.TrMedium.D, nil, nrm)
              else -- Get the trace ready to check the other side and register the location
                beam:Redirect(org, vdir)
              end
            end
          else -- The beam ends inside a solid transparent medium
            local org = beam:GetNudge(beam.NvLength)
            beam:RegisterNode(org, beam.NvLength)
            beam:Finish(trace)
          end -- Apply power ratio when requested
          if(usrfre) then beam:SetPowerRatio(beam.TrMedium.D[1][2]) end
        else
          if(act and gtACTORS[act]) then
            local suc, err = pcall(gtACTORS[act], beam, trace)
            if(not suc) then beam.IsTrace = false; target:Remove(); error(err) end
          elseif(LaserLib.IsUnit(target)) then -- Trigger for units without action function
            beam:Finish(trace) -- When the entity is unit but does not have actor function
          else -- Otherwise bust continue medium change. Reduce loops when hit dedicated units
            local mat = beam:GetMaterialID(trace) -- Current extracted material as string
            beam.IsTrace  = true -- Still tracing the beam
            local reflect = GetMaterialEntry(mat, gtREFLECT)
            if(reflect and not beam.StRfract) then
              beam:Reflect(reflect[1], trace) -- Call reflection method
            else
              local refract, key = GetMaterialEntry(mat, gtREFRACT)
              if(beam.StRfract or (refract and key ~= beam.TrMedium.S[2])) then -- Needs to be refracted
                -- When we have refraction entry and are still tracing the beam
                if(refract) then -- When refraction entry is available do the thing
                  -- Calculated refraction ray. Reflect when not possible
                  if(beam.StRfract) then -- Laser is within the map water submerged
                    beam:SetWater(refract[3] or key, tr)
                    beam:Redirect(trace.HitPos) -- Keep the same direction and initial origin
                    beam.StRfract = false -- Lower the flag so no performance hit is present
                  else -- Beam comes from the air and hits the water. Store water plane and refract
                    -- Get the trace ready to check the other side and point and register the location
                    local vdir, bnex = LaserLib.GetRefracted(beam.VrDirect,
                                         trace.HitNormal, beam.TrMedium.S[1][1], refract[1])
                    beam:SetWater(refract[3] or key, trace)
                    beam:Redirect(trace.HitPos, vdir)
                  end -- Need to make the traversed destination the new source
                  beam:SetRefractWorld(trace, refract, key)
                  -- Apply power ratio when requested
                  if(usrfre) then beam:SetPowerRatio(refract[2]) end
                  -- We cannot be able to refract as the requested entry is missing
                else beam:Finish(trace) end
                -- All triggers when reflecting and refracting are processed
              else beam:Finish(trace) end -- Not traversing and have hit a wall
            end
          end -- We are neither hit a valid entity nor a map water
        end
      else beam:Finish(trace) end; beam:Bounce() -- Refresh medium pass through information
    else beam:Finish(trace) end -- Trace did not hit anything to be bounced off from
  until(beam:IsFinish())
  -- Clear the water trigger refraction flag
  beam:ClearWater()
  -- The beam ends inside transparent entity
  if(not beam:IsNode()) then return beam end
  -- Update the sources and trigger the hit reports
  beam:UpdateSource(trace)
  -- Return what did the beam hit and stuff
  return beam, trace
end

function LaserLib.ComboBoxString(panel, convar, nameset)
  local unit = LaserLib.GetTool()
  local svar = GetConVar(unit.."_"..convar):GetString()
  local base = language.GetPhrase("tool."..unit.."."..convar.."_con")
  local hint = language.GetPhrase("tool."..unit.."."..convar)
  local item, name = panel:ComboBox(base, unit.."_"..convar)
  item:SetTooltip(hint); name:SetTooltip(hint)
  item:SetSortItems(true); item:Dock(TOP); item:SetTall(22)
  for key, val in pairs(list.GetForEdit(nameset)) do
    local bsel = (svar == val.name)
    local name = language.GetPhrase(key)
    local icon = LaserLib.GetIcon(val.icon)
    item:AddChoice(name, val.name, bsel, icon)
  end
  function name:DoRightClick()
    SetClipboardText(self:GetValue())
  end
  function item:DoRightClick()
    local vN = name:GetValue()
    local iD = self:GetSelectedID()
    local vT = self:GetOptionText(iD)
    local vD = self:GetOptionData(iD)
    SetClipboardText(vN.." "..vT.." ["..vD.."]")
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

  local moar = {
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
    table.insert(moar, {"models/props_bts/rocket.mdl"})
    table.insert(moar, {"models/props/cake/cake.mdl",90})
    table.insert(moar, {"models/props/water_bottle/water_bottle.mdl",90})
    table.insert(moar, {"models/props/turret_01.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(moar, {"models/props_bts/projector.mdl",0,"1,-10,5","0,-1,0"})
    table.insert(moar, {"models/props/laser_emitter.mdl",0,"29,0,-14","1,0,0"})
    table.insert(moar, {"models/props/laser_emitter_center.mdl",0,"29,0,0","1,0,0"})
    table.insert(moar, {"models/weapons/w_portalgun.mdl",0,"-20,-0.7,-0.3","-1,0,0"})
    table.insert(moar, {"models/props_bts/glados_ball_reference.mdl",0,"0,15,0","0,1,0"})
    table.insert(moar, {"models/props/pc_case02/pc_case02.mdl",0,"-0.2,2.4,-9.2","1,0,0"})
    table.insert(moar, {"models/props/radio_reference.mdl",0,"0.006396,3.646849,14.241646","0,0,1"})
  end

  if(IsMounted("portal2")) then -- Portal 2
    table.insert(moar, {"models/br_debris/deb_s8_cube.mdl"})
    table.insert(moar, {"models/npcs/turret/turret.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(moar, {"models/npcs/turret/turret_skeleton.mdl",0,"12,0,36.75","1,0,0"})
  end

  if(IsMounted("hl2")) then -- HL2
    table.insert(moar, {"models/items/ar2_grenade.mdl"})
    table.insert(moar, {"models/props_lab/huladoll.mdl",90})
    table.insert(moar, {"models/weapons/w_missile_closed.mdl"})
    table.insert(moar, {"models/weapons/w_missile_launch.mdl"})
    table.insert(moar, {"models/props_c17/canister01a.mdl",90})
    table.insert(moar, {"models/props_combine/weaponstripper.mdl"})
    table.insert(moar, {"models/items/combine_rifle_ammo01.mdl",90})
    table.insert(moar, {"models/props_borealis/bluebarrel001.mdl",90})
    table.insert(moar, {"models/props_c17/canister_propane01a.mdl",90})
    table.insert(moar, {"models/props_borealis/door_wheel001a.mdl",180})
    table.insert(moar, {"models/items/combine_rifle_cartridge01.mdl",-90})
    table.insert(moar, {"models/props_trainstation/trashcan_indoor001b.mdl",-90})
    table.insert(moar, {"models/props_lab/reciever01b.mdl",0,"-7.12,-6.56,0.35","-1,0,0"})
    table.insert(moar, {"models/props_c17/trappropeller_lever.mdl",0,"0,-6,-0.15","0,-1,0"})
  end

  if(IsMounted("dod")) then -- DoD
    table.insert(moar, {"models/weapons/w_smoke_ger.mdl",-90})
  end

  if(IsMounted("ep2")) then -- HL2 EP2
    table.insert(moar, {"models/props_junk/gnome.mdl",0,"-3,0.94,6","-1,0,0"})
  end

  if(IsMounted("cstrike")) then -- Counter-Strike Source
    table.insert(moar, {"models/props/de_nuke/emergency_lighta.mdl",90})
  end

  if(IsMounted("left4dead")) then -- Left 4 Dead
    table.insert(moar, {"models/props_unique/airport/line_post.mdl",90})
    table.insert(moar, {"models/props_street/firehydrant.mdl",0,"-0.081,0.052,39.31","0,0,1"})
  end

  if(IsMounted("tf")) then -- Team Fortress 2
    table.insert(moar, {"models/props_hydro/road_bumper01.mdl",90})
  end

  if(WireLib) then -- Make these model available only if the player has Wire
    table.insert(moar, {"models/led2.mdl", 90})
    table.insert(moar, {"models/venompapa/wirecdlock.mdl", 90})
    table.insert(moar, {"models/jaanus/wiretool/wiretool_siren.mdl", 90})
    table.insert(moar, {"models/jaanus/wiretool/wiretool_range.mdl", 90})
    table.insert(moar, {"models/jaanus/wiretool/wiretool_beamcaster.mdl", 90})
    table.insert(moar, {"models/jaanus/wiretool/wiretool_grabber_forcer.mdl", 90})
  end

  -- Automatic model array population. Add models in the list above
  table.Empty(list.GetForEdit("LaserEmitterModels"))

  local sTool = LaserLib.GetTool()
  for idx = 1, #moar do
    local rec = moar[idx]
    local mod = tostring(rec[1] or "")
    local ang = (tonumber(rec[2]) or 0)
    local org = tostring(rec[3] or "")
    local dir = tostring(rec[4] or "")
    table.Empty(rec)
    rec[sTool.."_model" ] = mod
    rec[sTool.."_angle" ] = ang
    rec[sTool.."_origin"] = org
    rec[sTool.."_direct"] = dir
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
