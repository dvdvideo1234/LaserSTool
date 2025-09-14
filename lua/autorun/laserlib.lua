LaserLib = LaserLib or {} -- Initialize the global variable of the library

local DATA = {}

DATA.GRAT = 1.61803398875      -- Golden ratio used for panels
DATA.TOOL = "laseremitter"     -- Tool name for internal use
DATA.ICON = "icon16/%s.png"    -- Format to convert icons
DATA.NOAV = "N/A"              -- Not available as string
DATA.CATG = "Laser"            -- Category name in the entities tab
DATA.TOLD = SysTime()          -- Reduce debug function calls
DATA.RNDB = 3                  -- Decimals beam round for visibility check
DATA.RNBH = 2                  -- Dedicated rounding for black hole comparison
DATA.KWID = 5                  -- Width coefficient used to calculate power
DATA.CLMX = 255                -- Maximum value for valid coloring
DATA.CTOL = 20                 -- Color vectors and alpha comparison tolerance
DATA.NUGE = 2                  -- Nudge amount for origin vectors back-tracing
DATA.MINW = 0.05               -- Minimum width to be considered visible
DATA.DOTM = 0.01               -- Collinearity and dot product margin check
DATA.POWL = 0.001              -- Lowest bounds of laser power
DATA.BRAD = 2.5                -- How much the bounding radius is scaled for back-trace
DATA.ERAD = 1.5                -- Entity refract coefficient for back trace origins
DATA.TRWD = 0.27               -- Beam back trace width when refracting
DATA.WLMR = 10000              -- World vectors to be correctly converted to local
DATA.TRWU = 50000              -- The distance to trace for finding water surface
DATA.FMVA = "%f,%f,%f"         -- Utilized to output formatted vectors in proper manner
DATA.FNUH = "%.2f"             -- Formats number to be printed on a HUD
DATA.FPSS = "%09d#%09d"        -- Formats pass-trough sensor keys
DATA.AMAX = {-360, 360}        -- General angular limits for having min/max
DATA.WVIS = { 700, 300}        -- General wavelength limits for visible light
DATA.WCOL = {  0 , 300}        -- Mapping for wavelength to color hue conversion
DATA.WMAP = {  20,   5}        -- Dispersion wavelength mapping for refractive index
DATA.SODD = 589.29             -- General wavelength for sodium line used for dispersion
DATA.KEYD  = "#"               -- The default key in a collection point to take when not found
DATA.KEYA  = "*"               -- The all key in a collection point to return the all in set
DATA.KEYX  = "~"               -- The first symbol used to disable given things
DATA.IMAT  = "*"               -- First and last symbol to match studio displacement empty mats
DATA.LSEP  = ","               -- General list separator. Used for string splits and concatenation
DATA.AZERO = Angle()           -- Zero angle used across all sources
DATA.VZERO = Vector()          -- Zero vector used across all sources
DATA.VDRFW = Vector(1, 0, 0)   -- Global forward vector used across all sources
DATA.VDRRG = Vector(0,-1, 0)   -- Global right vector used across all sources. Positive is at the left
DATA.VDRUP = Vector(0, 0, 1)   -- Global up vector used across all sources
DATA.WTCOL = Color(0, 0, 0)    -- For wavelength to color conversions. It is expensive to create color
DATA.DISID = DATA.TOOL.."_torch[%d]" -- Format to update dissolver target with entity index
DATA.EXPLP = DATA.TOOL.."_exitpair"  -- General key for storing laser portal-pair entity networking
DATA.PHKEY = DATA.TOOL.."_physprop"  -- Key used to register physical properties modifier
DATA.MTKEY = DATA.TOOL.."_material"  -- Key used to register dupe material modifier
DATA.BVKEY = DATA.TOOL.."_hoangvel"  -- Key used to register black hole ang velocity
DATA.TRDGQ = (DATA.TRWD * math.sqrt(3)) / 2 -- Trace hit normal displacement
DATA.FSELF = function(arg) return arg end -- Copy-constructor for numbers and strings
DATA.FILTW = function(ent) return (ent == game.GetWorld()) end -- Trace world filter function
DATA.CAPSF = function(str) return str:gsub("^%l", string.upper) end -- Capitalize first letter
DATA.HXCOLOR = {FM = "%02s", DT = {}} -- Stores temporary setting for hex to color conversion
DATA.HARUNTM = {10, 150, 5}     -- Hash storage for beam runtime. Bounces, safety velocity, black hole segment
DATA.HADFSPL = {2, 1, 0, 1}     -- Hash storage for controls the default splitter outputs count and direction
DATA.HADELTA = {0.1, 0.15, 0.2} -- Hash storage for general time deltas. Damage, effects, asynchronous
DATA.HAWASTP = {  15,  15}      -- Hash storage for color configuration to wavelength list step
DATA.DMPARAM = {}               -- Table to store the damage parameter specific values

-- Server controlled flags for console variables
DATA.FGSRVCN = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)
-- Independently controlled flags for console variables
DATA.FGINDCN = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

-- Library internal variables for limits and realtime tweaks ( server controlled )
DATA.MXSPLTBC = CreateConVar(DATA.TOOL.."_maxspltbc" , 16   , DATA.FGSRVCN, "Maximum splitter output laser beams count", 0, 32)
DATA.MXBMWIDT = CreateConVar(DATA.TOOL.."_maxbmwidt" , 30   , DATA.FGSRVCN, "Maximum beam width for all laser beams", 0, 100)
DATA.MXBMDAMG = CreateConVar(DATA.TOOL.."_maxbmdamg" , 5000 , DATA.FGSRVCN, "Maximum beam damage for all laser beams", 0, 10000)
DATA.MXBMFORC = CreateConVar(DATA.TOOL.."_maxbmforc" , 25000, DATA.FGSRVCN, "Maximum beam force for all laser beams", 0, 50000)
DATA.MXBMLENG = CreateConVar(DATA.TOOL.."_maxbmleng" , 25000, DATA.FGSRVCN, "Maximum beam length for all laser beams", 0, 50000)
DATA.MBOUNCES = CreateConVar(DATA.TOOL.."_maxbounces", 10   , DATA.FGSRVCN, "Maximum surface bounces for the laser beam", 0, 1000)
DATA.MFORCELM = CreateConVar(DATA.TOOL.."_maxforclim", 25000, DATA.FGSRVCN, "Maximum force limit available to the welds", 0, 50000)
DATA.NSPLITER = CreateConVar(DATA.TOOL.."_nspliter"  , 2    , DATA.FGSRVCN, "Controls the default splitter outputs count", 0, 16)
DATA.XSPLITER = CreateConVar(DATA.TOOL.."_xspliter"  , 1    , DATA.FGSRVCN, "Controls the default splitter X direction", -1, 1)
DATA.YSPLITER = CreateConVar(DATA.TOOL.."_yspliter"  , 0    , DATA.FGSRVCN, "Controls the default splitter Y direction", -1, 1)
DATA.ZSPLITER = CreateConVar(DATA.TOOL.."_zspliter"  , 1    , DATA.FGSRVCN, "Controls the default splitter Z direction", -1, 1)
DATA.ENSOUNDS = CreateConVar(DATA.TOOL.."_ensounds"  , 1    , DATA.FGSRVCN, "Trigger this to enable or disable redirection sounds")
DATA.DAMAGEDT = CreateConVar(DATA.TOOL.."_damagedt"  , 0.1  , DATA.FGSRVCN, "The time frame to pass between the beam damage cycles", 0, 10)
DATA.VESFBEAM = CreateConVar(DATA.TOOL.."_vesfbeam"  , 150  , DATA.FGSRVCN, "Controls the beam safety velocity for player pushed aside", 0, 500)
DATA.NRASSIST = CreateConVar(DATA.TOOL.."_nrassist"  , 1000 , DATA.FGSRVCN, "Controls the area that is searched when drawing assist", 0, 10000)
DATA.TIMEASYN = CreateConVar(DATA.TOOL.."_timeasync" , 0.2  , DATA.FGSRVCN, "Controls the time delta checked for asynchronous events", 0, 5)
DATA.BLHOLESG = CreateConVar(DATA.TOOL.."_blholesg"  , 5    , DATA.FGSRVCN, "Black hole gravity curving interpolation segment length", 0, 20)
DATA.WDHUESTP = CreateConVar(DATA.TOOL.."_wdhuestp"  , 15   , DATA.FGSRVCN, "Hue step when using dispersion and splitting color components", 0, 50)
DATA.WDRGBMAR = CreateConVar(DATA.TOOL.."_wdrgbmar"  , 15   , DATA.FGSRVCN, "Hue compare margin for dispersion and splitting color components", 0, 100)

-- Library internal variables for limits and realtime tweaks ( independent )
DATA.MAXRAYAS = CreateConVar(DATA.TOOL.."_maxrayast" , 100  , DATA.FGINDCN, "Maximum distance to compare projection to units center", 0, 250)
DATA.LNDIRACT = CreateConVar(DATA.TOOL.."_lndiract"  , 10   , DATA.FGINDCN, "How long will the direction of output beams be rendered", 0, 50)
DATA.DRWBMSPD = CreateConVar(DATA.TOOL.."_drwbmspd"  , 8    , DATA.FGINDCN, "The speed used to render the beam in the main routine", 0, 16)
DATA.EFFECTDT = CreateConVar(DATA.TOOL.."_effectdt"  , 0.15 , DATA.FGINDCN, "Controls the time between effect drawing", 0, 5)

DATA.TCUST = {
  "Forward", "Right", "Up",
  H = {ID = 0, M = 0, V = 0},
  L = {ID = 0, M = 0, V = 0}
}

-- Translates color from index/key to key/index
DATA.COLID = {
  ["r"] = 1, -- Red
  ["g"] = 2, -- Green
  ["b"] = 3, -- Blue
  ["a"] = 4, -- Alpha
  "r", "g", "b", "a"
}

-- Tells the `CopyData` function how to handle types
DATA.COPYCV = {
  ["boolean"] = DATA.FSELF,
  ["number" ] = DATA.FSELF,
  ["string" ] = DATA.FSELF,
  ["Entity" ] = DATA.FSELF,
  ["Player" ] = DATA.FSELF,
  ["Vector" ] = Vector,
  ["Angle"  ] = Angle
}

DATA.UNITS = {
  -- https://wiki.facepunch.com/gmod/Structures/TraceResult
  -- There is really no point in using IMaterial as (x,y) beam hit cannot be extracted from the trace
  -- Classes existing in the hash part are laser-enabled entities `LaserLib.Configure(self)`
  -- Classes are stored in notation `[ent:GetClass()] = true` and used in `LaserLib.IsUnit(ent)`
  ["gmod_laser"          ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_crystal"  ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_reflector"] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_splitter" ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_divider"  ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_sensor"   ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_dimmer"   ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_splitterm"] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_portal"   ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_parallel" ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_filter"   ] = true, -- This is present for hot reload. You must register yours separately
  ["gmod_laser_refractor"] = true, -- This is present for hot reload. You must register yours separately
  -- These are intended for user configuration and pre-allocation. Used to create also convars
  -- [1] Actual class passed to `ents.Create` and used to actually create the proper scripted entity
  -- [2] Extension for folder and variable name indices. Stores which folder are entity specific files located
  -- [3] Contains the current model ( last path ) cashed being used for the given entity unit ID
  -- [4] Contains the current material ( texture ) cashed being used for the given entity unit ID
  -- [5] Whenever the unit is initialized successfully. Must contain nil, true or false
  {"gmod_laser"          , nil        , nil                                      , nil                                        }, -- Laser entity `ENT:EveryBeam/ENT:DoBeam`
  {"gmod_laser_crystal"  , "crystal"  , "models/props_c17/pottery02a.mdl"        , "models/dog/eyeglass"                      }, -- Laser crystal `ENT:EveryBeam/ENT:DoBeam`
  {"gmod_laser_reflector", "reflector", "models/madjawa/laser_reflector.mdl"     , "debug/env_cubemap_model"                  }, -- Laser reflectors `ACTOR`
  {"gmod_laser_splitter" , "splitter" , "models/props_c17/pottery04a.mdl"        , "models/dog/eyeglass"                      }, -- Laser splitter `ENT:EveryBeam/ENT:DoBeam`
  {"gmod_laser_divider"  , "divider"  , "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass"                      }, -- Laser divider `ENT:EveryBeam/ENT:DoBeam`
  {"gmod_laser_sensor"   , "sensor"   , "models/props_lab/jar01a.mdl"            , "phoenix_storms/concrete1"                 }, -- Laser sensor `ENT:EveryBeam/ENT:DoBeam`
  {"gmod_laser_dimmer"   , "dimmer"   , "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass"                      }, -- Laser dimmer `ACTOR`
  {"gmod_laser_splitterm", "splitterm", "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass"                      }, -- Laser splitterm `ENT:EveryBeam/ENT:DoBeam`
  {"gmod_laser_portal"   , "portal"   , "models/props_c17/frame002a.mdl"         , "models/props_combine/com_shield001a"      }, -- Laser portal  `ACTOR`
  {"gmod_laser_parallel" , "parallel" , "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass"                      }, -- Laser parallel `ACTOR`
  {"gmod_laser_filter"   , "filter"   , "models/props_c17/frame002a.mdl"         , "models/props_combine/citadel_cable"       }, -- Laser filter `ACTOR`
  {"gmod_laser_refractor", "refractor", "models/madjawa/laser_reflector.mdl"     , "models/props_combine/health_charger_glass"}  -- Laser refractor `ACTOR`
}; DATA.UNITS.Size = #DATA.UNITS

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

DATA.REFLECT = { -- Reflection descriptor
  [1] = "cubemap", -- Cube maps textures
  [2] = "reflect", -- Has reflect in the name
  [3] = "mirror" , -- Regular mirror surface
  [4] = "chrome" , -- Chrome stuff reflect
  [5] = "shiny"  , -- All shiny reflective stuff
  [6] = "white"  , -- All general white paint
  [7] = "metal"  , -- All shiny metals reflecting
  -- Used for prop updates and checks
  [DATA.KEYD] = "debug/env_cubemap_model",
  -- User for general class control. Status: [nil] = missing, [false] = disable
  -- [1] : Surface reflection index for the material specified
  -- [2] : Which index is the material found at when it is searched in array part
  -- [3] : Reverse integer index for search for medium contents sequential order
  [""]                                     = false, -- Disable empty materials
  ["**empty**"]                            = false, -- Disable empty world materials
  ["**studio**"]                           = false, -- Disable empty prop materials
  ["cubemap"]                              = {0.999}, -- Other cube map reflective stuff
  ["reflect"]                              = {0.999}, -- It has reflect in the name
  ["mirror"]                               = {0.999}, -- It has mirror in the name
  ["chrome"]                               = {0.955}, -- Something chromed and reflective
  ["shiny"]                                = {0.915}, -- Something generally shiny
  ["white"]                                = {0.342}, -- Something white that reflects
  ["metal"]                                = {0.045}, -- General metallic surface
  -- Materials that are overridden and directly hash searched
  ["models/shiny"]                         = {0.915}, -- Some generally shiny model
  ["wtp/chrome_1"]                         = {0.955}, -- Chrome surface variation
  ["wtp/chrome_2"]                         = {0.955}, -- Chrome surface variation
  ["wtp/chrome_3"]                         = {0.955}, -- Chrome surface variation
  ["wtp/chrome_4"]                         = {0.955}, -- Chrome surface variation
  ["wtp/chrome_5"]                         = {0.955}, -- Chrome surface variation
  ["wtp/chrome_6"]                         = {0.955}, -- Chrome surface variation
  ["wtp/chrome_7"]                         = {0.955}, -- Chrome surface variation
  ["wtp/paint_1"]                          = {0.115}, -- Various reflective paints
  ["wtp/paint_2"]                          = {0.055}, -- Various reflective paints
  ["wtp/paint_3"]                          = {0.684}, -- Various reflective paints
  ["wtp/paint_4"]                          = {0.831}, -- Various reflective paints
  ["wtp/paint_5"]                          = {0.107}, -- Various reflective paints
  ["models/player/shared/ice_player"]      = {0.830}, -- Various reflective paints
  ["phoenix_storms/mat/mat_phx_metallic"]  = {0.317}, -- Various reflective paints
  ["phoenix_storms/mat/mat_phx_metallic2"] = {0.317}, -- Various reflective paints
  ["phoenix_storms/mat/mat_phx_plastic"]   = {0.547}, -- Various reflective paints
  ["phoenix_storms/mat/mat_phx_plastic2"]  = {0.547}, -- Various reflective paints
  ["models/materials/chpaint"]             = {0.576}, -- Various reflective paints
  ["phoenix_storms/window"]                = {0.897}, -- PHX window
  ["bobsters_trains/chrome"]               = {0.955}, -- Chrome from bobster trains
  ["gm_construct/color_room"]              = {0.342}, -- White room in gm_construct
  ["debug/env_cubemap_model"]              = {1.000}, -- There is no perfect mirror
  ["models/materials/chchrome"]            = {0.864}, -- Chromed materials
  ["phoenix_storms/grey_chrome"]           = {0.757}, -- Gray chrome
  ["phoenix_storms/fender_white"]          = {0.625}, -- White reflective fender
  ["sprops/textures/sprops_chrome"]        = {0.757}, -- Various PHX chrome materials
  ["sprops/textures/sprops_chrome2"]       = {0.657}, -- Various PHX chrome materials
  ["phoenix_storms/fender_chrome"]         = {0.694}, -- Various PHX chrome materials
  ["phoenix_storms/pack2/bluelight"]       = {0.734}, -- PHX blue light
  ["sprops/trans/wheels/wheel_d_rim1"]     = {0.943}, -- Shiny wheel material
  ["bobsters_trains/base"]                 = {0.741}, -- Shiny wheel material
  ["bobsters_trains/base2"]                = {0.741}, -- Shiny wheel material
  ["bobsters_trains/chrome_dirty_black"]   = {0.537}
}; DATA.REFLECT.Size = #DATA.REFLECT

DATA.REFRACT = {
  -- https://wiki.facepunch.com/gmod/Structures/TraceResult
  -- https://en.wikipedia.org/wiki/List_of_refractive_indices
  -- There is really no point in using IMaterial as (x,y) beam hit cannot be extracted from the trace
  -- Sequential keys must be ordered by contents inclusion
  -- Lower enumerator means higher priority for contents to be checked
  [1] = "air"  , -- Empty enumerator index 0
  [2] = "glass", -- Glass enumerator index 2
  [3] = "slime", -- Slime enumerator index 16
  [4] = "water", -- Water enumerator index 32
  [5] = "transparent", -- Translucent stuff 268435456
  [6] = "translucent", -- Translucent stuff 268435456
  -- Used for prop updates and checks `CheckMaterials`
  [DATA.KEYD] = "models/props_combine/health_charger_glass",
  -- User for general class control. Status: [nil] = missing, [false] = disable
  -- [1]   : Medium refraction index for the material specified by sodium line
  -- [2]   : Medium refraction rating when the beam goes through reduces its power
  -- [ID]  : Reverse integer index to search for medium contents sequential order
  -- [Key] : Which hash key material has been found when it is searched in array part
  -- [Con] : What contents does the specified index match when requested position check
  [""]                                          = false, -- Disable empty materials
  ["**empty**"]                                 = false, -- Disable empty world materials
  ["**studio**"]                                = false, -- Disable empty prop materials
  ["air"]                                       = {1.000, 1.000, Con = CONTENTS_EMPTY      }, -- Air refraction index
  ["water"]                                     = {1.333, 0.955, Con = CONTENTS_WATER      }, -- Water refraction index
  ["slime"]                                     = {1.387, 0.731, Con = CONTENTS_SLIME      }, -- Slime refraction index
  ["glass"]                                     = {1.521, 0.999, Con = CONTENTS_WINDOW     }, -- Glass refraction index
  ["transparent"]                               = {1.437, 0.874, Con = CONTENTS_TRANSLUCENT}, -- Transparent stuff
  ["translucent"]                               = {1.437, 0.455, Con = CONTENTS_TRANSLUCENT}, -- Translucent stuff
  -- Materials that are overridden and directly hash searched
  ["models/error/new light1"]                   = {1.528, 0.931}, -- Mee's procedural shard
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
  ["models/props_lab/tank_glass001"]            = {1.511, 0.654}, -- Red tank glass
  ["models/props_combine/com_shield001a"]       = {1.573, 0.653}, -- Dynamically changing glass
  ["models/props_combine/combine_fenceglow"]    = {1.638, 0.924}, -- Glass with decent impurities
  ["models/props_c17/frostedglass_01a_dx60"]    = {1.521, 0.853}, -- Forged glass DirectX 6.0
  ["models/props_c17/frostedglass_01a"]         = {1.521, 0.853}, -- Forged glass
  ["models/props_combine/health_charger_glass"] = {1.552, 1.000}, -- Resembles no perfect glass
  ["models/props_combine/combine_door01_glass"] = {1.583, 0.341}, -- Bit darker glass
  ["models/props_combine/citadel_cable"]        = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/citadel_cable_b"]      = {1.583, 0.441}, -- Dark glass
  ["models/props_combine/pipes01"]              = {1.583, 0.761}, -- Dark glass other
  ["models/props_combine/pipes03"]              = {1.583, 0.761}, -- Dark glass other
  ["models/props_combine/stasisshield_sheet"]   = {1.511, 0.427}  -- Blue temper glass
}; DATA.REFRACT.Size = #DATA.REFRACT

-- Black hole interfaces
DATA.BLHOLE = {
  ["gwater2_blackhole"] = { -- Mee's Gwater 2
    GetCenter = function(ent) return ent:LocalToWorld(ent:OBBCenter()) end,
    GetRadius = function(ent) return ent:GetRadius() end,
    GetAffect = function(ent, pos, stp)
      local kve, wve = DATA.BVKEY, nil
      local cen = ent:LocalToWorld(ent:OBBCenter())
      local rav = Vector(pos); rav:Sub(cen)
      local grv, drg, req = Vector(rav), Vector(), rav:LengthSqr()
      grv:Normalize(); grv:Mul(-stp * (ent:GetStrength() / req))
      if(SERVER) then -- There is physics only on the server
        wve = ent:GetPhysicsObject():GetAngleVelocity()
        wve:Set(ent:LocalToWorld(wve)); wve:Sub(cen)
        ent:SetNWVector(kve, wve)
      else wve = ent:GetNWVector(kve, drg) end
      if(not wve:IsZero()) then -- D = aGM / r^3
        drg:Set(wve:Cross(rav))
        drg:Mul(stp / (10 * req ^ 1.5)); grv:Add(drg)
      end; return grv
    end,
    Registry = {}
  }
}

DATA.BLHOLE["gwater_blackhole"] = { -- Mee's Gwater 1
  GetCenter = DATA.BLHOLE["gwater2_blackhole"].GetCenter,
  GetRadius = DATA.BLHOLE["gwater2_blackhole"].GetRadius,
  GetAffect = DATA.BLHOLE["gwater2_blackhole"].GetAffect,
  Registry = {}
}

--[[
 * Material configuration to use when override is missing
 * Acts like a reference key jump for to the REFLECT set
 * Convert all numbers to strings to prevent memory gaps
 * https://wiki.facepunch.com/gmod/Enums/MAT
]]
DATA.MATYPE = {
  [tostring(MAT_SNOW      )] = "white",
  [tostring(MAT_SLOSH     )] = "water",
  [tostring(MAT_GRATE     )] = "metal",
  [tostring(MAT_CLIP      )] = "metal",
  [tostring(MAT_METAL     )] = "metal",
  [tostring(MAT_VENT      )] = "metal",
  [tostring(MAT_GLASS     )] = "glass",
  [tostring(MAT_WARPSHIELD)] = "glass"
}

DATA.MATSRF = {
  {Sur = SURF_WARP , Nam = "water"},
  {Sur = SURF_TRANS, Nam = "translucent"}
}; DATA.MATSRF.Size = #DATA.MATSRF

DATA.TRACE = {
  filter         = nil,
  output         = nil,
  ignoreworld    = false,
  start          = Vector(),
  endpos         = Vector(),
  mins           = Vector(),
  maxs           = Vector(),
  mask           = MASK_SOLID,
  collisiongroup = COLLISION_GROUP_NONE
}

if(CLIENT) then
  DATA.CAPB = {} -- Store functions for control panel
  DATA.TAHD = TEXT_ALIGN_CENTER -- Text alignment
  DATA.KILL = "vgui/entities/gmod_laser_killicon"
  DATA.HOVM = Material("gui/ps_hover.png", "nocull")
  DATA.HOVB = GWEN.CreateTextureBorder(0, 0, 64, 64, 8, 8, 8, 8, DATA.HOVM)
  surface.CreateFont("LaserHUD", {font = "Arial", size = 22, weight = 600})
  surface.CreateFont("LaserRAY", {font = "Trebuchet24", size = 22, weight = 600})
  surface.CreateFont("LaserOBB", {font = "Trebuchet18", size = 22, weight = 600})
  DATA.HOVP = function(pM, iW, iH) DATA.HOVB(0, 0, iW, iH, DATA.COLOR["WHITE"]) end
  DATA.REFLECT.Sort = {Size = 0, Info = {"Rate", "Type", Size = 2}, Mpos = 0}
  DATA.REFRACT.Sort = {Size = 0, Info = {"Ridx", "Rate", "Type", Size = 3}, Mpos = 0}
  killicon.Add(DATA.UNITS[1][1], DATA.KILL, DATA.COLOR["WHITE"])
else -- Server-side initialization. Put server related code here
  AddCSLuaFile("autorun/laserlib.lua")
  AddCSLuaFile(DATA.TOOL.."/wire_wrapper.lua")
  AddCSLuaFile(DATA.TOOL.."/editable_wrapper.lua")
  DATA.DMGI = DamageInfo() -- Create a server-side damage information class
  DATA.BURN = Sound("player/general/flesh_burn.wav") -- Burn sound for player safety
  -- User notification configuration type. Used to format notifications via string.format
  DATA.NTIF = {"GAMEMODE:AddNotify(\"%s\", NOTIFY_%s, 6)", "surface.PlaySound(\"ambient/water/drip%d.wav\")"}
end

--[[
 * Attaches callback changes to convar updating local data
 * key  > Data hash pointing to a list placeholder
 * ...  > Vararg list of convars. Any getting changed updates the list
]]
local function ConfigureChangeList(key, ...)
  local data = DATA[key]
  if(not data) then return end
  local sors = {...}
  for idx = 1, #sors, 2 do
    local cvar = sors[idx]
    local func = sors[idx + 1]
    local idat = math.floor(idx/2) + 1
    if(cvar and func) then
      local name = cvar:GetName()
      local exec = cvar[func]
      if(exec) then
        local function update(sV, vO, vN)
          if(func == "GetString") then
            data[idat] = tostring(vN or "")
          elseif(func == "GetInt") then
            data[idat] = math.floor(tonumber(vN) or 0)
          elseif(func == "GetFloat") then
            data[idat] = (tonumber(vN) or 0)
          elseif(func == "GetBool") then
            data[idat] = tobool(vN)
          else error("List ["..key.."] trig ["..idat.."] "..name..":"..func) end
        end -- Call the handler with old and new data
        local suc, out = pcall(exec, cvar); if(not suc) then
          error("List ["..key.."] load ["..idat.."] "..name..":"..func) end
        update(name, data[idat], out)
        cvars.RemoveChangeCallback(name, name.."_list")
        cvars.AddChangeCallback(name, update, name.."_list")
      else error("List ["..key.."] exec ["..idat.."] "..name..":"..func) end
    else error("List ["..key.."] parm ["..idat.."] "..name..":"..func) end
  end
end

--[[
 * Registers a hook and client/server even fill for special cases
 * Configures the hook and user message for population special cases
]]
local function ConfigureHookRegistry(set, name)
  local suid = DATA.TOOL.."_"..name
  if(SERVER) then
    util.AddNetworkString(suid.."_add")
    util.AddNetworkString(suid.."_rem")
    hook.Remove("PlayerSpawnedSENT", suid)
    hook.Add("PlayerSpawnedSENT", suid,
      function(ply, ent)
        if(not LaserLib.IsValid(ent)) then return end
        local ukey = ent:GetClass()
        local info = set[ukey]
        if(not info) then return end
        info.Registry[ent] = true
        net.Start(suid.."_add")
          net.WriteEntity(ent)
        net.Broadcast()
        ent:CallOnRemove(suid, function(erm)
          if(not LaserLib.IsValid(erm)) then return end
          info.Registry[erm] = nil
          net.Start(suid.."_rem")
            net.WriteEntity(erm)
          net.Broadcast()
        end)
      end)
  else
    function upEntity(sv)
      local ent = net.ReadEntity()
      if(not LaserLib.IsValid(ent)) then return end
      local ukey = ent:GetClass()
      local info = set[ukey]
      if(not info) then return end
      info.Registry[ent] = sv
    end
    net.Receive(suid.."_add", function() upEntity(true) end)
    net.Receive(suid.."_rem", function() upEntity( nil) end)
  end
end

--[[
 * Checks and setups the material set of type reflect or refract
 * data > Data set for reflect or refract being validated
 * size > Search array size that is being forced on the check
]]
local function CheckMaterials(data, size)
  -- Validate default key
  local key, set = data[DATA.KEYD]
  -- Check forced size and compare with internal
  local siz = (tonumber(size) or data.Size)
  -- Check default key and raise error
  if(key == nil) then -- Check default key presence
    error("Default key index missing: "..tostring(key))
  else -- Check default key configuration
    if(data[key] == nil) then -- Key not present
      error("Default key entry missing: "..tostring(key)) end
  end -- Default key is configured correctly
  -- There is data in the sequential part
  if(data.Size and data.Size > 0) then
    if(siz < 0) then -- Size is invalid
      error("Search array length negative: "..tostring(siz)) end
    if(math.ceil(siz) ~= math.floor(siz)) then
      error("Search array length fractional: "..tostring(siz)) end
    if(siz ~= data.Size) then
      error("Search array length mismatch: "..tostring(siz)) end
    -- Configure refract sequential entries
    for idx = 1, siz do
      key = data[idx]; if(not key) then
        error("Dataset key missing: "..tostring(idx)) end
      set = data[key]; if(not set) then
        error("Dataset set missing: "..tostring(key)) end
      if(not istable(set)) then
        error("Dataset ent missing: "..tostring(key)) end
      set.Key = key; set.ID = idx
    end
  end
end

--[[
 * Performs CAP dedicated traces. Will return result
 * only when CAP hits its dedicated entities
 * origin > Trace origin as world position vector
 * direct > Trace direction as world aim vector
 * length > Trace length in source units
 * filter > Trace filter as standard config
 * https://github.com/RafaelDeJongh/cap/pull/108
 * https://github.com/RafaelDeJongh/cap/blob/master/lua/stargate/shared/tracelines.lua
]]
local function TraceCAP(origin, direct, length, filter)
  if(StarGate) then
    local g_trace = DATA.TRACE
    g_trace.start:Set(origin) -- By default CAP uses origin position ray
    g_trace.endpos:Set(direct) -- By default CAP uses direction ray length
    if(length and length > 0) then -- Length is available. Use it instead
      g_trace.endpos:Normalize() -- Normalize ending position
      g_trace.endpos:Mul(length) -- Scale using the external length
    end -- The data is ready as the CAP trace accepts it and call the thing
    local tr = StarGate.Trace:New(g_trace.start, g_trace.endpos, filter)
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
  local g_trace = DATA.TRACE
  g_trace.start:Set(origin)
  g_trace.endpos:Set(direct)
  g_trace.endpos:Normalize()
  if(length and length > 0) then
    g_trace.endpos:Mul(length)
  else -- Use proper length even if missing
    g_trace.endpos:Mul(direct:Length())
  end -- Utilize direction length when not provided
  g_trace.endpos:Add(origin)
  g_trace.filter = filter
  if(width and width > 0) then
    local m = width / 2
    g_trace.action = util.TraceHull
    g_trace.mins:SetUnpacked(-m, -m, -m)
    g_trace.maxs:SetUnpacked( m,  m,  m)
  else
    if(SeamlessPortals) then -- Mee's Seamless-Portals
      g_trace.action = SeamlessPortals.TraceLine
    else -- Seamless portals are not installed
      g_trace.action = util.TraceLine
    end -- Use the original no detour trace line
  end
  if(mask) then
    g_trace.mask = mask
  else -- Default trace mask
    g_trace.mask = MASK_SOLID
  end
  if(iworld) then
    g_trace.ignoreworld = iworld
  else -- Default world ignore
    g_trace.ignoreworld = false
  end
  if(colgrp) then
    g_trace.collisiongroup = colgrp
  else -- Default collision group
    g_trace.collisiongroup = COLLISION_GROUP_NONE
  end
  if(result) then
    g_trace.output = result
    g_trace.action(g_trace)
    g_trace.output = nil
    return result
  else
    g_trace.output = nil
    return g_trace.action(g_trace)
  end
end

--[[
 * Checks if the content is present in binary
 * Complementary content exists in base content
 * Returns true when content persists in trace
 * base > Base content including all properties
 * comp > Complementary property being checked
]]
function LaserLib.InBinary(base, comp)
  if(base == comp) then return true end
  return (bit.band(base, comp) == comp)
end

--[[
 * Checks if content is present in the position
 * Returns true when content persists in trace
 * cpos > Origin content position being checked
 * comp > Complementary property being checked
]]
function LaserLib.IsContent(cpos, comp)
  return LaserLib.InBinary(util.PointContents(cpos), comp)
end

--[[
 * This is designed to compare contents to the refract list
 * It will compare the trace contents to the medium content
 * On success will return the content ID to update trace
 * cont > The trace contents being checked and matched
]]
function LaserLib.GetContentsID(cont)
  local g_refract = DATA.REFRACT
  for idx = 1, g_refract.Size do -- Check contents
    local key = g_refract[idx] -- Index content key
    local row = g_refract[key] -- Index entry row
    if(row) then local conr = row.Con -- Read row contents
      if(conr ~= nil) then -- Row contents exists check it
        if(conr ~= 0) then -- Row contents is non-zero
          if(LaserLib.InBinary(cont, conr)) then return idx end
        else -- Compare directly when zero to avoid mismatch
          if(cont == conr) then return idx end -- Air contents
        end -- Contents are compared and index is extracted
      end -- Contents have been specified successfully
    end -- Check if we have the corresponding bit or be equal
  end; return nil -- The contents did not get matched to entry
end

--[[
 * Checks when the entity has interactive material
 * Cashes the incoming request for the material index
 * Used to pick data when reflecting or refracting
 * mat > Direct material to check for. Missing uses `ent`
 * set > The dedicated parameters setting to check
 * Returns: Material entry from the given set
]]
local function GetMaterialEntry(mat, set)
  if(not mat) then return nil end
  if(not set) then return nil end
  local mat = tostring(mat):lower()
  -- Read the first entry from table
  local key, val = mat, set[mat]
  -- Check for overriding with default
  if(mat == DATA.KEYD) then return set[val], val end
  -- Check for element overrides found
  if(val) then return val, key end
  -- Check for disabled entry (false)
  if(val ~= nil) then return nil end
  -- Check for miss element category (nil)
  for idx = 1, set.Size do key = set[idx]
    if(mat:find(key)) then -- Cache the material
      set[mat] = set[key] -- Cache the material found
      return set[mat], key -- Compare the entry
    end -- Read and compare the next entry
  end; set[mat] = (val ~= nil) -- Undefined material
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

--[[
 * Calculates a Gauss bell curve distribution
 * Center and deviation are not mandatory
 * xin > X axis to calculate the distribution for
 * cen > Distribution center. Maximum location
 * oev > Distribution deviation. Value spread on value 0.5
 * Returns
 * [1] > The calculated standard Gaussian distribution
]]
function LaserLib.Gauss(xin, cen, oev)
  return 1 / math.exp((xin - (cen or 0))^2 / (2 * (oev or 0.5)^2))
end

--[[
 * Project a position onto ray defines as origin and direction
 * pos > Position being projected onto a ray
 * org > Ray origin that we are projecting onto
 * dir > Ray direction that we are projecting onto
 * Returns
 * [1] > Projected position onto the ray
 * [2] > Position ray margin as dot product
]]
function LaserLib.ProjectPointRay(pos, org, dir)
  local dir = dir:GetNormalized()
  local vrs = Vector(pos); vrs:Sub(org)
  local mar = vrs:Dot(dir); vrs:Set(dir)
        vrs:Mul(mar); vrs:Add(org)
  return vrs, mar
end

--[[
 * Checks when the given position is inside the entity
 * pos > Position origin being checked
 * ent > Entity being used as an AABB cube
 * https://wiki.facepunch.com/gmod/Vector:WithinAABox
]]
function LaserLib.InEntity(pos, ent)
  local vmin = ent:OBBMins()
  local vmax = ent:OBBMaxs()
  local vpos = ent:WorldToLocal(pos)
  return vpos:WithinAABox(vmax, vmin)
end

--[[
 * Calculates the beam exit entity responsible for drawing beam
 * When exit entity is only available at server side network the ID
 * This is mainly used for link-pair portals. Exit may be invalid
 * base > Base entity acting as a portal entrance
 * from > The way to retrieve the exit entity on the server
 * hash > Networking hash to store the exit entity ID
 * Returns the exit entity for the beam to traverse from
]]
function LaserLib.GetBeamExit(base, from)
  local hash, exit = DATA.EXPLP, from -- Exit portal pair hash
  if(SERVER) then -- Locating open pair is server-side
    if(LaserLib.IsValid(exit)) then -- Validate portal
      base:SetNWInt(hash, exit:EntIndex()) -- Store pair
    else base:SetNWInt(hash, 0); return end -- No linked pair
    return exit -- Return the refreshed exit entity
  else -- Client takes entity form networking
    exit = (exit or ents.GetByIndex(base:GetNWInt(hash, 0)))
    if(not LaserLib.IsValid(exit)) then return end -- No linked pair
    return exit -- Exit portal will have the same surface offset
  end
end

--[[
 * Calculates the beam position and direction when entity is a portal
 * This assumes that the beam enters the +X and exits at +X
 * Doing so will lead to correct beam representation across portal Y axis
 * base    > Base entity acting as a portal entrance
 * exit    > Exit entity acting as a portal beam output location
 * origin  > Hit location vector placed on the first entity surface
 * direct  > Direction that the beam goes inside the first entity
 * forigin > Origin custom modifier function. Negates X, Y by default
 * fdirect > Direction custom modifier function. Negates X, Y by default
 * Returns the output beam ray position and direction
]]
function LaserLib.GetBeamPortal(base, exit, origin, direct, forigin, fdirect)
  if(not (base and base:IsValid())) then return origin, direct end
  if(not (exit and exit:IsValid())) then return origin, direct end
  local pos, dir, wmr = Vector(origin), Vector(direct), DATA.WLMR
  pos:Set(base:WorldToLocal(pos)); dir:Mul(wmr)
  if(forigin) then local suc, err = pcall(forigin, pos)
    if(not suc) then error("Origin: "..err) end
  else pos.x, pos.y = -pos.x, -pos.y end
  pos:Set(exit:LocalToWorld(pos))
  dir:Add(base:GetPos())
  dir:Set(base:WorldToLocal(dir))
  if(fdirect) then local suc, err = pcall(fdirect, dir)
    if(not suc) then error("Direct: "..err) end
  else dir.x, dir.y = -dir.x, -dir.y end
  dir:Rotate(exit:GetAngles()); dir:Div(wmr)
  return pos, dir
end

--[[
 * Projects beam direction onto portal forward and retrieves
 * portal beam margin visuals to be displayed correctly in
 * render target surface. Returns incorrect results when
 * portal position is not located on the render target surface
 * entity > The portal entity to calculate margin for
 * origin > Hit location vector placed on the first entity surface
 * direct > Direction that the beam goes inside the first entity
 * normal > Surface normal vector. Usually portal:GetForward()
 * Returns the output beam ray margin transition
]]
function LaserLib.GetMarginPortal(entity, origin, direct, normal)
  local normal = (normal or entity:GetForward())
  local pos, mav = entity:GetPos(), Vector(direct)
  local wvc = Vector(origin); wvc:Sub(pos)
  local mar = math.abs(wvc:Dot(normal)) -- Project entrance vector
  local vsm = mar / math.cos(math.asin(normal:Cross(direct):Length()))
  vsm = 2 * vsm; mav:Mul(vsm); mav:Add(origin)
  return mav, vsm
end

--[[
 * Inserts consistent data in array notation {1,2,Size=2}
 * tArr > Array to modify
 * aVia > Data to be inserted
 * iID  > Location to insert data in
 * bOvr > Force replace the array slot
]]
local function InsertData(tArr, aVia, iID, bOvr)
  if(not tArr.Size) then tArr.Size = #tArr end
  local idx = (tonumber(iID) or 0)
  local vdt, siz = (aVia or DATA.KEYX), tArr.Size
  if(idx < 1 or idx > siz) then
    table.insert(tArr, vdt)
    tArr.Size = (siz + 1)
  else
    if(bOvr) then tArr[idx] = aVia else
      table.insert(tArr, idx, vdt)
      tArr.Size = (siz + 1)
    end
  end; return tArr
end

--[[
 * Selects consistent data in array notation {1,2,Size=2}
 * tArr > Array to modify
 * iID  > Location to insert data in
 * bOvr > Read only without pop data out
]]
local function SelectData(tArr, iID, bOvr)
  if(not tArr.Size) then tArr.Size = #tArr end
  local siz = tArr.Size
  local idx = (tonumber(iID) or 0)
  if(idx < 1 or idx > siz) then
    if(bOvr) then return tArr[siz] else
      tArr.Size = (siz - 1)
      return table.remove(tArr)
    end
  else
    if(bOvr) then return tArr[idx] else
      tArr.Size = (siz - 1)
      return table.remove(tArr, idx)
    end
  end; return tArr
end

--[[
 * Cleans data so it becomes consistent in array notation {1,2,Size=2}
 * It loops trough the array and removes the empty values
 * tArr > Array to modify. For in-place modification
]]
local function CleanData(tArr)
  local mxn = table.maxn(tArr)
  if(not tArr.Size) then tArr.Size = mxn end
  local cui, cuv = nil, nil
  for idx = 1, mxn do
    cuv = tArr[idx]
    if(cuv) then
      if(cui) then
        tArr[cui] = cuv
        tArr[idx] = nil
        cui = cui + 1
      end
    else
      if(not cui) then
        cui = idx
      end
    end
  end; tArr.Size = (cui - 1)
  return tArr
end

--[[
 * Copies data contents from a table
 * tSrc > Array to copy from
 * tSkp > Skipped fields list
 * tOny > Selected fields list
 * tAsn > Fields to use assignment for
 * tCpn > Fields to use table.Copy for
 * tDst > Destination table when provided
]]
local function CopyData(tSrc, tSkp, tOny, tAsn, tCpn, tDst)
  local tCpy = (tDst or {}) -- Destination data
  for nam, vsm in pairs(tSrc) do
    if((not tOny or (tOny and tOny[nam])) and
       (not tSkp or (tSkp and not tSkp[nam]))
    ) then -- Field is selected to be copied
      local typ = type(vsm) -- Read data type
      local fcn = DATA.COPYCV[typ] -- Constructor
      if(fcn) then -- Copy-conversion exists
        tCpy[nam] = fcn(vsm) -- Copy-convert
      else -- Table or other case
        if(tAsn and tAsn[nam]) then
          tCpy[nam] = vsm -- Assign enable for field
        elseif(tCpn and tCpn[nam]) then
          tCpy[nam] = table.Copy(vsm) -- General copy table
        else -- Unhanded field. Report error to the user
          error("Mismatch ["..typ.."]["..nam.."]: "..tostring(vsm))
        end -- Assign a copy table
      end -- The snapshot is completed
  end; end; return tCpy
end

--[[
 * Checks if The given vectors are orthogonal
 * vFw > Forward axis vector as direction
 * vUp > Up axis vector finishing the plane
 * Returns true when vectors are orthogonal
]]
function LaserLib.IsOrtho(vFw, vUp)
  return (math.abs(vFw:Dot(vUp)) <= DATA.DOTM)
end

--[[
 * Makes the up direction vector orthogonal
 * to the forward one. Uses forced cross product
 * Stores data into the up direction vector
 * vFw > Forward axis vector as direction
 * vUp > Up axis vector finishing the plane
 * bNu > Enable normalizing the result
 * bNr > Enable normalizing the result
 * Returns reference to up direction vector
]]
function LaserLib.SetOrtho(vFw, vUp, bNu, bNr)
  local vRg = vFw:Cross(vUp)
  vUp:Set(vRg:Cross(vFw))
  if(bNu) then vUp:Normalize() end
  if(bNr) then vRg:Normalize() end
  return vUp, vRg
end

function LaserLib.GetSign(arg)
  return arg / math.abs(arg)
end

-- https://wiki.facepunch.com/gmod/Silkicons
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

--[[
 * Reads entity unit value from the list
 * iR > Row index. Same as the entity unit ID
 * iC > Column index. Same as value requested
]]
function LaserLib.GetClass(iR)
  local tU = DATA.UNITS[tonumber(iR) or 0]
  return (tU and tU[1] or nil)
end

function LaserLib.GetSuffix(iR)
  local tU = DATA.UNITS[tonumber(iR) or 0]
  return (tU and tU[2] or nil)
end

function LaserLib.GetModel(iR, vR)
  local tU = DATA.UNITS[tonumber(iR) or 0]
  if(tU and vR) then tU[3] = vR end
  return (tU and tU[3] or nil)
end

function LaserLib.GetMaterial(iR, vR)
  local tU = DATA.UNITS[tonumber(iR) or 0]
  if(tU and vR) then tU[4] = vR end
  return (tU and tU[4] or nil)
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
 * Compared when given time interval is passed
 * Returns true when the interval is passed
 * tim > Time point to compare against
 * cur > External current time
]]
function LaserLib.IsTime(tim, cur)
  local cmp = DATA.HADELTA[3]
  local cur = (cur or CurTime())
  return ((cur - tim) > cmp) -- Time has passed
end

--[[
 * Validates entity and checks for something else
 * arg > Entity object to be checked
]]
function LaserLib.IsOther(arg)
  if(arg:IsNPC()) then return true end
  if(arg:IsWorld()) then return true end
  if(arg:IsPlayer()) then return true end
  if(arg:IsWeapon()) then return true end
  if(arg:IsWidget()) then return true end
  if(arg:IsVehicle()) then return true end
  if(arg:IsRagdoll()) then return true end
  if(arg:IsDormant()) then return true end
  return false
end

--[[
 * Checks whenever an entity is a player
]]
function LaserLib.IsPlayer(arg)
  if(not LaserLib.IsValid(arg)) then return false end
  if(not arg.IsPlayer) then return false end
  return arg:IsPlayer()
end

--[[
 * Extracts the first available number in a list
 * num   > Amount of item to check for number
 * {...} > Variable arguments list of numbers
 * Returns the fist number found or nil
]]
function LaserLib.GetNumber(n, ...)
  local arg, out = {...}
  for i = 1, n do
    out = out or tonumber(arg[i])
    if(out) then return out end
  end; return out
end

--[[
 * Extracts the color components from RGBA arguments when valid
 * In case not being valid the max component luminosity is returned
 * Automatically handles the input arguments in range of [0-255]
 * mr  > Red component of the picked color channel
 * mg  > Green component of the picked color channel
 * mb  > Blue component of the picked color channel
 * ma  > Alpha component of the picked color channel
]]
function LaserLib.GetColorRGBA(mr, mg, mb, ma)
  local m = DATA.CLMX
  if(istable(mr)) then -- Color object or table
    return math.Clamp(LaserLib.GetNumber(3, mr["r"], mr[1], m), 0, m),
           math.Clamp(LaserLib.GetNumber(3, mr["g"], mr[2], m), 0, m),
           math.Clamp(LaserLib.GetNumber(3, mr["b"], mr[3], m), 0, m),
           math.Clamp(LaserLib.GetNumber(3, mr["a"], mr[4], m), 0, m)
  else -- Everything else
    return math.Clamp(LaserLib.GetNumber(2, mr, m), 0, m),
           math.Clamp(LaserLib.GetNumber(2, mg, m), 0, m),
           math.Clamp(LaserLib.GetNumber(2, mb, m), 0, m),
           math.Clamp(LaserLib.GetNumber(2, ma, m), 0, m)
  end
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
 * Extracts table value content from 2D set specified key
 * tab > Reference to a table of row tables
 * key > The key to be extracted (not mandatory)
]]
function LaserLib.ExtractCon(tab, key)
  if(not tab) then return tab end
  if(not key) then return tab end
  local set = {} -- Allocate
  for k, v in pairs(tab) do
    set[k] = v[key] -- Populate values
  end; return set -- Key-value pairs
end

--[[
 * Extracts table icons from 2D set specified key
 * tab > Reference to a table of row tables
 * key > The key to be extracted (not mandatory)
 * dir > Enable direct table mapping
]]
function LaserLib.ExtractIco(tab, key)
  if(not tab) then return end
  if(not key) then return end
  if(istable(key)) then
    for k, v in pairs(key) do
      key[k] = LaserLib.GetIcon(v)
    end; return key
  else
    if(key:sub(1, 1) == DATA.KEYX) then
      return LaserLib.GetIcon(key:sub(2, -1))
    else
      local set = {} -- Allocate
      for k, v in pairs(tab) do -- Populate values
        set[k] = LaserLib.GetIcon(v[key])
      end; return set -- Key-value pairs
    end -- Update icon with key table or string
  end
end

--[[
 * Returns the entity owner when defined
 * Uses various entity fields and methods
]]
function LaserLib.GetOwner(ent)
  if(not LaserLib.IsValid(ent)) then return nil end
  local set, user = ent.OnDieFunctions
  -- Use CPPI first when installed. If fails search down
  user = ((CPPI and ent.CPPIGetOwner) and ent:CPPIGetOwner() or nil)
  if(LaserLib.IsPlayer(user)) then return user else user = nil end
  -- Try the direct entity methods. Extract owner from functions
  user = (ent.GetOwner and ent:GetOwner() or nil)
  if(LaserLib.IsPlayer(user)) then return user else user = nil end
  user = (ent.GetCreator and ent:GetCreator() or nil)
  if(LaserLib.IsPlayer(user)) then return user else user = nil end
  -- Try then various entity internal key values
  user = ent.player; if(LaserLib.IsPlayer(user)) then return user else user = nil end
  user = ent.Owner; if(LaserLib.IsPlayer(user)) then return user else user = nil end
  user = ent.owner; if(LaserLib.IsPlayer(user)) then return user else user = nil end
  if(set) then -- Duplicator die functions are registered
    set = set.GetCountUpdate; user = (set.Args and set.Args[1] or nil)
    if(LaserLib.IsPlayer(user)) then return user else user = nil end
    set = set.undo1; user = (set.Args and set.Args[1] or nil)
    if(LaserLib.IsPlayer(user)) then return user else user = nil end
  end; return user -- No owner is found. Nothing is returned
end

--[[
 * This setups the beam kill crediting
 * Updates the kill credit player for specific entity
 * To obtain the creator player use `ent:GetCreator()`
 * https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/entity.lua#L69
]]
function LaserLib.SetPlayer(ent, user)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsPlayer(user)) then return end
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

function LaserLib.ToString(tav)
  local a = tonumber(tav[1] or tav.x or tav.p) or 0
  local b = tonumber(tav[2] or tav.y or tav.y) or 0
  local c = tonumber(tav[3] or tav.z or tav.r) or 0
  return DATA.FMVA:format(a, b, c)
end

function LaserLib.ByString(str)
  local str = tostring(str or ""):Trim()
  local tav = DATA.LSEP:Explode(str)
  local a = (tonumber(tav[1]) or 0)
  local b = (tonumber(tav[2]) or 0)
  local c = (tonumber(tav[3]) or 0)
  return a, b, c
end

function LaserLib.SetupTransform(tran) local amax = DATA.AMAX
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
    LaserLib.SnapCustom(base, trace, tran[2], tran[3])
  else
    LaserLib.SnapNormal(base, trace, tran[1])
  end
end

--[[
 * Retrieves the splitter lean control angle
 * F/U vectors are locals angle will be local also
 * F/U vectors are world angle will be world also
 * forwd > Forward vector for angle calculation
 * upwrd > Upwards vector for angle calculation
 * marbx > Angle axis offset margin for X
 * marby > Angle axis offset margin for Y
 * marbz > Angle axis offset margin for Z
]]
function LaserLib.GetLeanAngle(forwd, upwrd, marbx, marby, marbz)
  local marbx = math.Clamp(tonumber(marbx) or 0, -1, 1)
  local marby = math.Clamp(tonumber(marby) or 0, -1, 1)
  local marbz = math.Clamp(tonumber(marbz) or 0, -1, 1)
  local angle = forwd:AngleEx(upwrd)
  local aup   = angle:Up(); aup:Mul(marbz)
  local arg   = angle:Right(); arg:Mul(marby)
  local afw   = angle:Forward(); afw:Mul(marbx)
  afw:Add(arg); afw:Add(aup)
  return afw:AngleEx(upwrd)
end

--[[
 * Check when the entity is laser library unit
]]
function LaserLib.IsUnit(ent)
  if(LaserLib.IsValid(ent)) then
    return DATA.UNITS[ent:GetClass()]
  else return false end
end

--[[
 * Defines when the entity can produce output beam
]]
function LaserLib.IsBeam(ent)
  if(LaserLib.IsValid(ent)) then
    return (ent.DoBeam ~= nil)
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
    return (ent.DoBeam ~= nil and ent.GetDissolveType ~= nil)
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
    material["<Empty>"] = {name = "", icon = "stop"}
    dissolve["<Empty>"] = {name = "", icon = "stop"}
    ent:EditableSetIntCombo("ForceCenter" , "General" , comxbool, "name", "icon")
    ent:EditableSetIntCombo("ReflectRatio", "Material", comxbool, "name", "icon")
    ent:EditableSetIntCombo("RefractRatio", "Material", comxbool, "name", "icon")
  else
    ent:EditableSetBool("ForceCenter" , "General")
    ent:EditableSetBool("ReflectRatio", "Material")
    ent:EditableSetBool("RefractRatio", "Material")
  end
  ent:EditableSetBool ("InPowerOn"   , "Internals")
  ent:EditableSetFloat("InBeamWidth" , "Internals", 0, DATA.MXBMWIDT:GetFloat())
  ent:EditableSetFloat("InBeamLength", "Internals", 0, DATA.MXBMLENG:GetFloat())
  ent:EditableSetFloat("InBeamDamage", "Internals", 0, DATA.MXBMDAMG:GetFloat())
  ent:EditableSetFloat("InBeamForce" , "Internals", 0, DATA.MXBMFORC:GetFloat())
  ent:EditableSetStringCombo("InBeamMaterial", "Internals", material, "name", "icon")
  if(nov) then
    ent:EditableSetIntCombo("InNonOverMater", "Internals", comxbool, "name", "icon")
    ent:EditableSetIntCombo("InBeamSafety"  , "Internals", comxbool, "name", "icon")
    ent:EditableSetIntCombo("EndingEffect"  , "Visuals"  , comxbool, "name", "icon")
  else
    ent:EditableSetBool("InNonOverMater", "Internals")
    ent:EditableSetBool("InBeamSafety"  , "Internals")
    ent:EditableSetBool("EndingEffect"  , "Visuals")
  end
  ent:EditableSetVectorColor("BeamColor", "Visuals")
  ent:EditableSetFloat("BeamAlpha", "Visuals", 0, DATA.CLMX)
  ent:EditableSetStringCombo("DissolveType", "Visuals", dissolve, "name", "icon")
end

--[[
 * Register unit configuration index as unit ID
 * uent > Unit entity class source folder `ENT`
 * mdef > Default convar model value
 * vdef > Default convar material value
 * conv > When provided used for convar prefix
]]
function LaserLib.RegisterUnit(uent, mdef, vdef, conv)
  -- Is index is provided populate model and create convars
  local index = (tonumber(uent.UnitID) or 0); if(index <= 1) then
    error("Index invalid: "..tostring(iunit)) end
  local usrc = tostring(uent.Folder or ""); if(usrc == "") then
    error("Name invalid: "..tostring(cunit)) end
  local ocas = LaserLib.GetClass(1); if(ocas == "") then
    error("Base empty: "..tostring(ocas)) end
  local ucas = usrc:match(ocas..".+$", 1); if(ucas == "") then
    error("Class invalid: "..tostring(usrc)) end
  local udrr = ucas:gsub(ocas.."%A+", ""); if(udrr == "") then
    error("Suffix empty: "..tostring(usrc)) end
  local vset = (DATA.UNITS[index] or {}); if(vset and vset[5]) then
    error("Unit present ["..index.."]["..vset[1].."]: "..ucas) end
  local uset = vset[1]; if(uset and uset ~= ucas) then
    error("Unit mismatch ["..index.."]["..vset[1].."]: "..ucas) end
  -- Allocate class configuration. Make it accessible to the library
  local vidx = tostring(conv or udrr):lower() -- Extract variable suffix
  vset[1], vset[2], vset[3], vset[4], vset[5] = ucas, vidx, mdef, vdef, true
  -- Configure arrays and corresponding console variables
  local vmod = tostring(mdef or ""):lower()
  local vmat = tostring(vdef or ""):lower()
  local vaum, vauv = ("mu"..vidx), ("vu"..vidx)
  local varm = CreateConVar(DATA.TOOL.."_"..vaum, vmod, DATA.FGSRVCN, "Controls the "..udrr.." model")
  local varv = CreateConVar(DATA.TOOL.."_"..vauv, vmat, DATA.FGSRVCN, "Controls the "..udrr.." material")
  -- Store convar objects
  DATA[vaum:upper()], DATA[vauv:upper()], DATA.UNITS[index] = varm, varv, vset
  -- Configure model visual
  local vanm = varm:GetName()
  cvars.RemoveChangeCallback(vanm, vanm)
  cvars.AddChangeCallback(vanm, function(name, o, n)
    local m = tostring(n):Trim()
    if(m:sub(1,1) ~= DATA.KEYD) then LaserLib.GetModel(index, m) else
      varm:SetString(LaserLib.GetModel(index, varm:GetDefault()))
    end -- Update current model at index [4]
  end, vanm); LaserLib.GetModel(index, varm:GetString():lower())
  -- Configure material visual
  local vanv = varv:GetName()
  cvars.RemoveChangeCallback(vanv, vanv)
  cvars.AddChangeCallback(vanv, function(name, o, n)
    local v = tostring(n):Trim()
    if(v:sub(1,1) ~= DATA.KEYD) then LaserLib.GetMaterial(index, v) else
      varv:SetString(LaserLib.GetMaterial(index, varv:GetDefault()))
    end -- Update current material at index [5]
  end, vanv); LaserLib.GetMaterial(index, varv:GetString():lower())
  -- Return the class extracted from folder
  return ucas -- This is passed to `ents.Create`
end

--[[
 * Clears entity internal order info for the editable wrapper
 * Registers the entity to the units list on CLIENT/SERVER
 * unit > Entity to register as primary laser source unit
]]
function LaserLib.Configure(unit)
  if(not LaserLib.IsValid(unit)) then return end
  local uas, cas = unit:GetClass(), LaserLib.GetClass(1)
  if(not uas:find(cas)) then error("Invalid unit: "..uas) end
  -- Delete temporary order info and register unit
  unit.meOrderInfo = nil; DATA.UNITS[uas] = true
  -- Instance specific configuration
  if(SERVER) then -- Do server configuration finalizer
    if(unit.OverrideOnRemove) then
      function unit:OnRemove() self:OverrideOnRemove() end
    else function unit:OnRemove() self:WireRemove() end end
    if(unit.OverrideOnRestore) then
      function unit:OnRemove() self:OverrideOnRestore() end
    else function unit:OnRestore() self:WireRestored() end end
    if(unit.OverridePreEntityCopy) then
      function unit:PreEntityCopy() self:OverridePreEntityCopy() end
    else function unit:PreEntityCopy() self:WirePreEntityCopy() end end
    if(unit.OverridePostEntityPaste) then
      function unit:PostEntityPaste(ply, ent, cre) self:OverridePostEntityPaste(ply, ent, cre) end
    else function unit:PostEntityPaste(ply, ent, cre) self:WirePostEntityPaste(ply, ent, cre) end end
    if(unit.OverrideApplyDupeInfo) then
      function unit:ApplyDupeInfo(ply, ent, info, feid) self:OverrideApplyDupeInfo(ply, ent, info, feid) end
    else function unit:ApplyDupeInfo(ply, ent, info, feid) self:WireApplyDupeInfo(ply, ent, info, feid) end end
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
        -- Update the player for kill crediting
        LaserLib.SetPlayer(self, (src.ply or src.player))
        -- Use coding effective API
        return self
      end
    end
  else
    --[[
     * This is used for stubborn units that does not update their beam
     * bounds view. The beam simply disappears when render bounds are
     * not updated. Places a point in player view to make it always seen
     * emin > External wold-space OBBMins
     * emax > External wold-space OBBMaxs
    ]]
    function unit:UpdateViewRB(emin, emax)
      local vpos, vmin, vmax = LaserLib.GetPlayerView(20)
      if(emin) then vmin = emin else -- External MAXS
        vmin = self:LocalToWorld(self:OBBMins()) end
      if(emax) then vmax = emax else -- External MINS
        vmax = self:LocalToWorld(self:OBBMaxs()) end
      LaserLib.UpdateBounds(vmin, math.min, vpos)
      LaserLib.UpdateBounds(vmax, math.max, vpos)
      self:SetRenderBoundsWS(vmin, vmax)
    end
  end

  --[[
   * Effects draw handling decides whenever
   * the current tick has to draw the effects
   * Flag is automatically reset in every call
   * then becomes true when it meets requirements
  ]]
  function unit:UpdateFlags()
    local time, delt = CurTime(), DATA.HADELTA
    if(SERVER) then -- Damage exists only on the server
      self.isDamage = false -- Reset the frame damage
      if(not self.nxDamage or time > self.nxDamage) then
        self.isDamage, self.nxDamage = true, time + delt[1]
      end
    end
    self.isEffect = false -- Reset the frame effects
    if(not self.nxEffect or time > self.nxEffect) then
      self.isEffect, self.nxEffect = true, time + delt[2]
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
    local set = (set or {}) -- Allocate pass-trough entity registration table
    if(LaserLib.IsValid(ent)) then -- Invalid entities cannot do infinite loops
      if(set[ent]) then return false end -- This has already been checked for infinite
      if(ent == self) then return true else set[ent] = true end -- Check and register
      if(LaserLib.IsBeam(ent) and ent.hitSources) then -- Can output names and has sources
        for src, stat in pairs(ent.hitSources) do -- Other hits and we are in its sources
          if(LaserLib.IsValid(src)) then -- Crystal has been hit by other crystal
            if(src == self) then return true end -- Performance optimization
            if(LaserLib.IsBeam(src) and src.hitSources) then -- Class propagates the tree
              if(self:IsInfinite(src, set)) then return true end end
          end -- Cascades propagate trough the crystal sources from `self`
        end; return false -- The entity does not persists in itself
      else return false end
    else return false end
  end

  ------ HIT REPORTS MANAGER ------

  --[[
   * Returns hit report stack size
  ]]
  function unit:GetHitReportMax()
    local ros = self.hitReports
    if(not ros) then return 0 end
    return ros.Size or 0
  end

  --[[
   * Removes hit reports from the list according to new size
   * rovr > When remove overhead is provided deletes
            all entries with larger index
   * Data is stored in notation: self.hitReports[ID]
  ]]
  function unit:SetHitReportMax(rovr)
    if(self.hitReports) then
      local ros, idx = self.hitReports
      if(rovr) then -- Overhead mode
        local rovr = tonumber(rovr) or 0
        idx, ros.Size = (rovr + 1), rovr
      else idx, ros.Size = 1, 0 end
      -- Wipe selected items
      while(ros[idx]) do
        ros[idx] = nil
        idx = idx + 1
      end
    end; return self
  end

  --[[
   * Checks whenever the entity `ent` beam report hits us `self`
   * self > Target entity to be checked
   * ent  > Reporter entity to be checked
   * idx  > Forced index to check for hit report. Not mandatory
   * bri  > Search from `idx` as start hit report index. Not mandatory
   * Data is stored in notation: self.hitReports[ID]
  ]]
  function unit:GetHitSourceID(ent, idx, bri)
    if(not LaserLib.IsUnit(ent)) then return nil end -- Invalid
    if(ent == self) then return nil end -- Cannot be source to itself
    if(not self.hitSources[ent]) then return nil end -- Not source
    if(not ent:GetOn()) then return nil end -- Unit is not powered on
    local ros = ent.hitReports -- Retrieve and localize hit reports
    if(not ros) then return nil end -- No hit reports. Exit at once
    if(idx and not bri) then -- Retrieve the report requested by ID
      local beam = ent:GetHitReport(idx) -- Retrieve beam report
      if(beam) then local trace = beam:GetTarget()
        if(trace and trace.Hit and self == trace.Entity) then return idx end end
    else local anc = (bri and idx or 1) -- Check all the entity reports for possible hits
      for cnt = anc, ros.Size do local beam = ent:GetHitReport(cnt)
        if(beam) then local trace = beam:GetTarget()
          if(trace and trace.Hit and self == trace.Entity) then return cnt end end
      end -- The hit report list is scanned and no reports are found hitting us `self`
    end; return nil -- Tell requestor we did not find anything that hits us `self`
  end

  --[[
   * Registers a trace hit report under automatic index
   * This is done only for units that have beam output
   * Make sure to provide unique beam identification ID
   * This is called only for units that run `DoBeam`
   * Unit: My `[idx]`-th beam passed trough there and hit that
   * beam  > Beam structure to register
  ]]
  function unit:SetHitReport(beam)
    local ros, idx = self.hitReports, beam.BmIdenty -- Read hit reports
    if(not ros) then ros = {Size = 0}; self.hitReports = ros end
    InsertData(ros, beam, idx, true)
    return self -- Coding effective API
  end

  --[[
   * Retrieves hit report trace and beam for specified index
   * index > Hit report index to read ( defaults to 1 )
  ]]
  function unit:GetHitReport(index)
    if(not index) then return end
    local ros = self.hitReports
    if(not ros) then return nil end
    return SelectData(ros, index, true)
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
    end -- When the have dedicated method to apply on each source
    local idx = self:GetHitSourceID(ent)
    if(idx) then local siz = ent.hitReports.Size
      if(each) then local suc, err = pcall(each, self, ent, idx)
        if(not suc) then self:Remove(); error(err); return false end
      end -- When the have dedicated method to apply on each source
      if(proc) then -- Trigger the beam processing routine
        while(idx and idx <= siz) do -- First index always hits when present
          local beam = ent:GetHitReport(idx) -- When the report hits us
          local suc, err = pcall(proc, self, ent, idx, beam) -- Call process
          if(not suc) then self:Remove(); error(err); return false end
          idx = self:GetHitSourceID(ent, idx + 1, true) -- Prepare for the next report
        end -- When the have dedicated method to apply on each source
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
    for ent, hit in pairs(self.hitSources) do -- For all registered source entities
      if(hit and LaserLib.IsValid(ent)) then -- Process only valid hits from the list
        if(not self:ProcessReports(ent, proc, each, apre, post)) then -- Proceed sources
          self.hitSources[ent] = nil -- Remove the entity from the list
        end -- Check when there is any hit report that is processed correctly
      else self.hitSources[ent] = nil end -- Delete the entity when force skipped
    end; return true -- There are hit reports and all are processed correctly
  end

  ------ INTERNAL ARRAY MANGER ------

  --[[
   * Initializes array definitions and creates a list
   * that is derived from the string arguments.
   * This will create arrays in notation `self.hit%NAME`
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
   * Removes the residual elements from wire outputs
   * Designed to be called at the end of sources process
  ]]
  function unit:UpdateArrays()
    local set = self.hitSetup
    if(not set) then return self end
    local idx = (tonumber(self.hitSize) or 0)
    for cnt = 1, set.Size do local wsr = set[cnt]
      if(wsr and wsr.Data) then LaserLib.Clear(wsr.Data, idx + 1) end
    end; set.Save = nil -- Clear the last top entity
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
      local wsr = set[cnt]
      wsr.Data[idx] = arg[cnt]
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
      local wsr = set[cnt]
      local nam, dat  = wsr.Name, wsr.Data
      local arr = (idx > 0 and dat or nil)
      if(wsr and dat) then LaserLib.Clear(dat, idx + 1) end
      if(wsr and nam) then self:WireWrite(nam, arr) end
    end; set.Save = nil; return self
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

function LaserLib.GetTransformUnit(ent)
  if(not LaserLib.IsValid(ent)) then return end
  local org = (ent.GetOriginLocal and ent:GetOriginLocal() or ent:OBBCenter())
  local dir = (ent.GetDirectLocal and ent:GetDirectLocal() or nil)
  if(not dir) then  dir = (ent.GetNormalLocal and ent:GetNormalLocal() or nil) end
  if(not (org and dir)) then return end
  local pos, ang = ent:GetPos(), ent:GetAngles()
  local vor = Vector(org); vor:Rotate(ang); vor:Add(pos)
  local vdr = Vector(dir); vdr:Rotate(ang)
  return vor, vdr
end

--[[
 * Generates a position in front of player view
 * It is used to be provided to render bounds
 * mar > Margin to extent the aim vector
]]
function LaserLib.GetPlayerView(mar)
  if(SERVER) then return end -- Server can go out now
  local user = LocalPlayer()
  local vpos = user:GetAimVector()
        vpos:Mul(mar or 0); vpos:Add(user:EyePos())
  return vpos
end

--[[
 * Draws OBB projected iteration for a single ray
 * vbb > Bounding box center being drawn
 * org > Origin ray start position vector
 * dir > Direction ray beam aiming vector (normalized)
 * nar > Threshold to compare the distance OBB to projection
 * rev > Reverse the drawing colors when available
]]
function LaserLib.DrawAssistOBB(vbb, org, dir, nar, rev)
  if(SERVER) then return end -- Server can go out now
  if(not (org and dir)) then return end
  local ctr = LaserLib.GetColor("GREEN")
  local csr = LaserLib.GetColor("YELLOW")
  local vrs, mar = LaserLib.ProjectPointRay(vbb, org, dir)
  local amr = vbb:DistToSqr(vrs)
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
    surface.SetFont("LaserOBB")
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
  local mray = DATA.MAXRAYAS:GetFloat()
  local nasr = DATA.NRASSIST:GetFloat()
  local vndr = Vector(nasr, nasr, nasr)
  local vmax = Vector(org); vmax:Add(vndr)
  local vmin = Vector(org); vmin:Sub(vndr)
  local ncst = math.Clamp(ray, 0, mray)^2
  local teun = ents.FindInBox(vmin, vmax)
  for idx = 1, #teun do local ent = teun[idx]
    if(LaserLib.IsValid(ent) and
      LaserLib.IsUnit(ent) and tre ~= ent)
    then -- Move targets to the trace entity beam
      local vbb = ent:LocalToWorld(ent:OBBCenter())
      local ros = (tre and tre.hitReports or nil)
      if(ros and ros.Size and ros.Size > 0) then
        LaserLib.DrawAssistReports(vbb, tre, ncst)
      else
        LaserLib.DrawAssistOBB(vbb, org, dir, ncst)
      end
    end
  end
  if(tre and ply) then
    local cas = LaserLib.GetClass(1)
    local vbb = tre:LocalToWorld(tre:OBBCenter())
    local org, dir = ply:EyePos(), ply:GetAimVector()
    for idx = 1, #teun do
      local ent = teun[idx]
      local ecs = ent:GetClass()
      if(tre ~= ent and not ecs ~= cas and
         LaserLib.IsValid(ent) and ecs:find(cas, 1, true))
      then -- Move trace entity to the targets beam
        local ros = (ent and ent.hitReports or nil)
        if(ros and ros.Size and ros.Size > 0) then
          LaserLib.DrawAssistReports(vbb, ent, ncst, true)
        else
          local org, dir = LaserLib.GetTransformUnit(ent)
          LaserLib.DrawAssistOBB(vbb, org, dir, ncst, true)
        end
      end
    end
  end
end

--[[
 * Draws the HUD on the tool screen that is the bottom
 * line information for reflection surfaces and refraction mediums
 * txt > The text being drawn at the bottom of the screen
]]
function LaserLib.DrawTextHUD(txt)
  if(SERVER) then return end
  if(not txt) then return end
  local arn, rat = DATA.TAHD, DATA.GRAT
  local blk = LaserLib.GetColor("BLACK")
  local bkg = LaserLib.GetColor("BACKGND")
  local w = surface.ScreenWidth()
  local h = surface.ScreenHeight()
  local sx, sy = (w / rat), (h / (15 * rat))
  local px = (w / 2) - (sx / 2)
  local py = h - sy - (rat - 1) * sy
  local tx, ty = (px + (sx / 2)), (py + (sy / 2))
  draw.RoundedBox(16, px, py, sx, sy, bkg)
  draw.SimpleText(txt, "LaserHUD", tx, ty, blk, arn, arn)
end

-- Draw a position on the screen
function LaserLib.DrawPoint(pos, col, idx, msg)
  if(SERVER) then return end
  local crw = LaserLib.GetColor(col or "YELLOW")
  render.SetColorMaterial()
  render.DrawSphere(pos, 0.5, 25, 25, crw)
  if(idx or msg) then
    local txt, mrg, fnt = "", 6, "LaserRAY"
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
    local txt, mrg, fnt = "", 6, "LaserRAY"
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
        table.insert(ser, row) -- Insert data entry
        ser.Size = ser.Size + 1 -- Increment size
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
  local nRat = DATA.GRAT
  local scrW = surface.ScreenWidth()
  local scrH = surface.ScreenHeight()
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
 * Stores the sidebar value so it can be later utilized
 * pnMat > Reference to side materials frame list
 * sort  > Structure to update bar position
]]
function LaserLib.UpdateVBar(pnMat, sort)
  if(SERVER) then return end
  local pnBar = pnMat.List.VBar
  if(not IsValid(pnBar)) then return end
  pnBar.Dragging = false
  pnBar.DraggingCanvas = nil
  pnBar:MouseCapture(false)
  pnBar.btnGrip.Depressed = false
  sort.Mpos = pnBar:GetScroll()
  return sort.Mpos
end

--[[
 * Triggers save request for the material select
 * scroll bar and reads it on the next panel open
 * Animates the slider to the last remembered position
 * pnMat > Reference to side materials frame list
 * sort  > Structure to update bar position
]]
function LaserLib.SetMaterialScroll(pnMat, sort)
  if(SERVER) then return end
  local pnBar = pnMat.List.VBar
  if(not IsValid(pnBar)) then return end
  function pnBar:OnMouseReleased()
    LaserLib.UpdateVBar(pnMat, sort)
  end -- Release mouse on the mar to accept
  pnBar:AnimateTo(sort.Mpos, 0.05)
end

--[[
 * Preforms material selection panel update for the requested entries
 * Clears the content and remembers the last panel view state
 * Called recursively when sorting or filtering is requested
]]
function LaserLib.UpdateMaterials(pnFrame, pnMat, sort)
  if(SERVER) then return end
  -- Update material selection content
  LaserLib.ClearMaterials(pnMat)
  -- Read the controls table and create index
  local tCont, iC, sTool = pnMat.Controls, 0, DATA.TOOL
  -- Update material panel with ordered values
  for iD = 1, sort.Size do
    local tRow, pnImg = sort[iD]
    if(tRow.Draw) then -- Drawing is enabled
      local sCon = LaserLib.GetSequenceInfo(tRow, sort.Info)
      local sInf, sKey = sCon.." "..tRow.Key, tRow.Key
      pnMat:AddMaterial(sInf, sKey); iC = iC + 1; pnImg = tCont[iC]
      function pnImg:DoClick()
        LaserLib.UpdateVBar(pnMat, sort)
        LaserLib.SetMaterialPaintOver(pnMat, self)
        LaserLib.ConCommand(nil, sort.Sors, sKey)
        pnFrame:SetTitle(sort.Name.." > "..sInf)
      end
      function pnImg:DoRightClick()
        LaserLib.UpdateVBar(pnMat, sort)
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
  local trva = (LaserLib.IsValid(tren) and not tren:IsWorld())
  local anch, encw, encn = (trva and tren or game.GetWorld())
  if(weld) then
    local fmax = DATA.MFORCELM:GetFloat()
    local flim = math.Clamp(tonumber(flim) or 0, 0, fmax)
    encw = constraint.Weld(laser, anch, 0, bone, flim)
    if(encw and encw:IsValid()) then
      laser:DeleteOnRemove(encw) -- Remove the weld with the laser
      if(trva) then anch:DeleteOnRemove(encw) end
    end
  end
  if(noco and trva) then -- Otherwise falls through the ground
    encn = constraint.NoCollide(laser, anch, 0, bone)
    if(encn and encn:IsValid()) then
      laser:DeleteOnRemove(encn) -- Remove the NC with the laser
      anch:DeleteOnRemove(encn)  -- Remove the NC with the anchor
    end -- Skip no-collide when world is anchor
  end; return encw, encn -- Do not call this for the world
end

--[[
 * Returns the yaw angle for the spawn function
 * ply > Player to calculate the angle for
 * Returns the calculated yaw result angle
]]
function LaserLib.GetAngleSF(ply)
  local amx = DATA.AMAX[2]
  local avc = ply:GetAimVector()
  local yaw = (avc:Angle().y + amx / 2) % amx
  local ang = Angle(0, yaw, 0); ang:Normalize()
  return ang -- Player spawn angle
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
  local mar = (source / destin) -- Calculate ref ratio
  if(math.abs(mar) > 1) then mar = 1 / mar end -- Reverse
  local arg = math.asin(mar) -- Calculate sine argument
  if(not bdegr) then return arg end -- Return radians
  return math.deg(arg) -- Do some extra work for degrees
end

--[[
 * https://en.wikipedia.org/wiki/Refraction
 * Refracts a beam across two mediums by returning the refracted vector
 * direct > The incident direction vector
 * normal > Surface normal vector trace.HitNormal ( normalized )
 * source > Refraction index of the source medium
 * destin > Refraction index of the destination medium
 * Return the refracted ray and beam status
 *    [1] > The refracted ray direction vector
 *    [2] > Will the beam traverse to the next medium
 *    [3] > Mediums have the same refractive index
]]
function LaserLib.GetRefracted(direct, normal, source, destin)
  local inc = direct:GetNormalized() -- Read normalized copy or incident
  if(source == destin) then return inc, true, true end -- Continue out medium
  local nrm = Vector(normal); nrm:Negate()  -- Call copy-constructor
  local vcr = inc:Cross(nrm) -- Always normalized. Sine: |i||n|sin(i^n)
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
 * vcbase > Vector to be updated and manipulated
 * action > The function to be called. Either max or min
 * bounds > Vector the base must be updated with
]]
function LaserLib.UpdateBounds(vcbase, action, bounds)
  local sx, ox = pcall(action, vcbase.x, bounds.x)
  if(not sx) then error("Bounds error X: "..ox) end
  local sy, oy = pcall(action, vcbase.y, bounds.y)
  if(not sy) then error("Bounds error Y: "..oy) end
  local sz, oz = pcall(action, vcbase.z, bounds.z)
  if(not sz) then error("Bounds error Z: "..oz) end
  vcbase.x, vcbase.y, vcbase.z = ox, oy, oz
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
  local power = LaserLib.GetPower(width, damage)
  return (math.Round(power, DATA.RNDB) > DATA.MINW)
end

function GetCollectionData(key, set)
  local idx = DATA.KEYD
  local def = set[set[idx]]
  if(not key) then return def end
  if(key == idx) then return def end
  local out = set[key] -- Try to index
  if(not out) then return def end
  return out -- Return indexed OK
end

-- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
function LaserLib.GetDissolveID(idx)
  return GetCollectionData(idx, DATA.DISTYPE)
end

function LaserLib.GetColor(idx)
  return GetCollectionData(idx, DATA.COLOR)
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
 * Translates indices to color keys for RGB
 * Generally used to split colors into separate beams
 * idx > Index of the beam being split to components
 * mr  > Red component of the picked color channel
         Can also be a color object then `mb` is missed
 * mg  > Green component of the picked color channel
         Can also be a flag for new color if `mr` is object
 * mb  > Blue component of the picked color channel
]]
function LaserLib.GetColorID(idx, mr, mg, mb)
  if(not (idx and idx > 0)) then return end
  local idc = ((idx - 1) % 3) + 1 -- Index component
  local key = DATA.COLID[idc] -- Key color component
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

--[[
 * Apply material on an entity
 * ent > Entity to modify
 * mat > Override material to apply
]]
function LaserLib.SetMaterial(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local tab = {MaterialOverride = tostring(mat or "")}
  ent:SetMaterial(tab.MaterialOverride)
  duplicator.StoreEntityModifier(ent, DATA.MTKEY, tab)
end

--[[
 * Apply physical properties on an entity
 * ent > Entity to modify
 * mat > Physical properties to apply
]]
function LaserLib.SetProperties(ent, mat)
  if(not LaserLib.IsValid(ent)) then return end
  local phy = ent:GetPhysicsObject()
  if(not LaserLib.IsValid(phy)) then return end
  local tab = {Material = tostring(mat or "")}
  construct.SetPhysProp(nil, ent, 0, phy, tab)
  duplicator.StoreEntityModifier(ent, DATA.PHKEY, tab)
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
 * trrs  > The trace result structure being used
 * angle > The model offset beam angling parameterization
]]
function LaserLib.SnapNormal(base, trrs, angle)
  local ang = trrs.HitNormal:Angle()
        ang:RotateAroundAxis(ang:Right(), -angle)
  local dir = LaserLib.GetBeamDirection(base, angle); dir:Negate()
  local org = LaserLib.GetBeamOrigin(base, dir); org:Negate()
  dir:Rotate(ang); org:Rotate(ang); org:Add(trrs.HitPos)
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
  tab.anCustom:Set(f:AngleEx(u)) -- Transfer and apply angle pitch
  tab.anCustom:RotateAroundAxis(f:Cross(u), -90) -- Cache angle
  return tab.anCustom
end

--[[
 * Projects the OBB onto the ray defined by position and direction
 * base   > Base entity to calculate the snapping for
 * trrs   > The trace result structure being used
 * origin > The model offset beam origin parameterization
 * direct > The model offset beam direct parameterization
]]
function LaserLib.SnapCustom(base, trrs, origin, direct)
  local dir = Vector(direct); dir:Negate()
  local ang, tra = Angle(), trrs.HitNormal:Angle()
  local pos = LaserLib.GetBeamOrigin(base, dir)
  ang:Set(LaserLib.GetCustomAngle(base, direct))
  tra:RotateAroundAxis(tra:Right(), -90)
  ang:Set(base:AlignAngles(base:LocalToWorldAngles(ang), tra))
  pos:Rotate(ang); pos:Negate(); pos:Add(trrs.HitPos)
  base:SetPos(pos); base:SetAngles(ang)
end

if(SERVER) then
  --[[
   * Configures visuals material and model for a unit
   * ply > Entity class unit owner or the player
   * ent > The actual entity class unit spawned
   * trc > Reference to trace result structure
  ]]
  function LaserLib.SetVisuals(ply, ent, trc)
    local vmo = false
    local tre, idx = trc.Entity, ent.UnitID
    if(ply:KeyDown(IN_USE)) then -- When replacing
      local own = LaserLib.GetOwner(tre)
      if(LaserLib.IsValid(tre) and not -- Use valid stuff
         LaserLib.IsOther(tre) and -- Use valid physics
         (own == ply or own == NULL)) -- Use your own stuff
      then vmo = true end -- Update the conditions flag
    end -- Check the conditions flag and apply changes
    if(vmo) then -- Use the trace valid model as a unit
      ent:SetPos(tre:GetPos()) -- Use trace position
      ent:SetAngles(tre:GetAngles()) -- Use trace angle
      ent:SetModel(tre:GetModel()); tre:Remove()
      LaserLib.SetMaterial(ent, LaserLib.GetMaterial(idx))
    else -- Conditions are not met so work normally
      ent:SetModel(LaserLib.GetModel(idx))
      LaserLib.SetMaterial(ent, LaserLib.GetMaterial(idx))
    end
  end

  function LaserLib.NewLaser(user       , pos         , ang         , model      ,
                             trandata   , key         , width       , length     ,
                             damage     , material    , dissolveType, startSound ,
                             stopSound  , killSound   , runToggle   , startOn    ,
                             pushForce  , endingEffect, reflectRate , refractRate,
                             forceCenter, frozen      , enOverMater , enSafeBeam , rayColor )

    if(not LaserLib.IsValid(user)) then return end
    if(not user:IsPlayer()) then return end
    if(not user:CheckLimit(DATA.TOOL.."s")) then return end

    local laser = ents.Create(LaserLib.GetClass(1))
    if(not (LaserLib.IsValid(laser))) then return end

    laser:SetCollisionGroup(COLLISION_GROUP_NONE)
    laser:SetSolid(SOLID_VPHYSICS)
    laser:SetMoveType(MOVETYPE_VPHYSICS)
    laser:SetNotSolid(false)
    laser:SetPos(pos)
    laser:SetAngles(ang)
    laser:SetModel(LaserLib.GetModel(1, Model(model)))
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
 * Remaps refraction index according to material sodium line
 * Returns the dynamic refraction index based on wavelength
 * This is mainly used for calculating component light dispersion
 * wave > Wavelength of the input beam traversing the medium
 * nidx > Refractive index for the sodium line according to the material
 * https://en.wikipedia.org/wiki/List_of_refractive_indices
 * http://hyperphysics.phy-astr.gsu.edu/hbase/geoopt/dispersion.html#c1
]]
function LaserLib.WaveToIndex(wave, nidx)
  local wr, mr, ms = DATA.WVIS, DATA.WMAP, DATA.SOMR
  local s = math.Remap(DATA.SODD, wr[1], wr[2], mr[1], mr[2])
  local x = math.Remap(wave, wr[1], wr[2], mr[1], mr[2])
  local h = -math.log(s) / ms -- Sodium line index
  return (-math.log(x) / ms - h) + nidx
end

--[[
 * Converts beam wavelength to a color
 * This is mainly used for calculating component light dispersion
 * wave > Wavelength of the input beam traversing the medium
 * bobc > Return a color object instead of 4 numbers
 * https://en.wikipedia.org/wiki/HSL_and_HSV#/media/File:Hsl-hsv_models.svg
 * https://wiki.facepunch.com/gmod/Global.HSVToColor
]]
function LaserLib.WaveToColor(wave, bobc)
  local wvis, wcol = DATA.WVIS, DATA.WCOL
  local hue = math.Remap(wave, wvis[1], wvis[2], wcol[1], wcol[2])
  local tab = HSVToColor(hue, 1, 1) -- Returns table not color
  if(bobc) then local wtcol = DATA.WTCOL
    wtcol.r, wtcol.g = tab.r, tab.g
    wtcol.b, wtcol.a = tab.b, tab.a; return wtcol
  end; return tab.r, tab.g, tab.b, tab.a
end

function LaserLib.ColorToWave(mr, mg, mb, ma)
  local wvis, wcol, wtcol = DATA.WVIS, DATA.WCOL, DATA.WTCOL
  local r, g, b, a = LaserLib.GetColorRGBA(mr, mg, mb, ma)
        wtcol.r, wtcol.g, wtcol.b = r, g, b
  local mh, ms, mv = ColorToHSV(wtcol)
  local rm = math.Remap(mh, 0, 360, wcol[1], wcol[2])
  return math.Remap(rm, wcol[1], wcol[2], wvis[1], wvis[2])
end

function LaserLib.SetWaveArray()
  local conf = DATA.HAWASTP
  local step, marg = conf[1], -conf[2]
  local wave = conf.Wave
  if(step <= 0) then
    if(wave) then
      table.Empty(wave)
      conf.Wave = nil
    end; return nil
  end
  if(marg > 0) then
    if(wave) then
      table.Empty(wave)
      conf.Wave = nil
    end; return nil
  end
  if(not wave) then
    conf.Wave = {Data = {}}
    wave = conf.Wave
  end
  local tW = wave.Data
  if(step == (tonumber(tW.Step) or 0)) then return tW end
  tW.Size = 0    -- Amount of entries the decomposition has
  tW.Step = step -- Hue adjustment step when defining components
  tW.Marg = marg -- Color compare margin for component check
  tW.PM = 0      -- Power multiplier converted scaled for comparison
  tW.PX = 0      -- Individual component power for non-white light part
  tW.PN = 0      -- Individual component power for white light part
  tW.IS = 0      -- Index start for the component extraction
  tW.IE = 0      -- Index end for the component extraction
  local wvis, wcol = DATA.WVIS, DATA.WCOL
  local huS, huE = wcol[1], wcol[2]
  for hue = huS, huE, step do
    local r, g, b = HSVToColor(hue, 1, 1)
    local co = {r = r, g = g, b = b}
    local wv = math.Remap(hue, huS, huE, wvis[1], wvis[2])
    table.insert(tW, {C = co, P = 0, W = wv, B = false})
    tW.Size = tW.Size + 1
  end; return tW
end

function LaserLib.GetWaveArray(cow)
  local tW = LaserLib.SetWaveArray()
  if(not tW) then return nil end
  local comx, wvis = DATA.CLMX, DATA.WVIS
  local weco, wcol = DATA.WTCOL, DATA.WCOL
  local coax = math.max(cow.r, cow.g, cow.b)
  local coan = math.min(cow.r, cow.g, cow.b)
  local marg = tW.Marg
  if(coan > 0) then
    tW.PN = (coan / comx)
    coax  = (coax - coan)
    tW.PX = (coax / comx)
    tW.PM = (comx / coax)
    weco.r = tW.PM * (cow.r - coan)
    weco.g = tW.PM * (cow.g - coan)
    weco.b = tW.PM * (cow.b - coan)
    tW.IS, tW.IE = 1, tW.Size
  else
    tW.PM = (comx / coax)
    tW.PX, tW.PN = (coax / comx), 0
    weco.r = (tW.PM * cow.r)
    weco.g = (tW.PM * cow.g)
    weco.b = (tW.PM * cow.b)
  end
  for iH = 1, tW.Size do
    local wav = tW[iH]
    local mr = (weco.r - wav.C.r)
    local mg = (weco.g - wav.C.g)
    local mb = (weco.b - wav.C.b)
    wav.P, wav.B = 0, false
    if(mr >= marg and mg >= marg and mb >= marg) then
      -- Dominating component in the source color
      if(coan <= 0) then tW.IE = iH
        if(tW.IS == 0) then tW.IS = iH end
      end -- Calculate the start-end indices
      wav.P = tW.PX; wav.B = true
    end
    if(coan > 0) then -- Base white component
      if(wav.B) then -- Adjust the dominant component
        wav.P = wav.P + tW.PN
      else -- Insert a gray component in the list
        wav.P = tW.PN
      end
    end
  end; return tW
end

--[[
 * This implements beam OOP with all its specifics
]]
local mtBeam = {} -- Object metatable for class methods
      mtBeam.__type  = "BeamData" -- Store class type here
      mtBeam.__trace = {} -- Temporary trace result to fill
      mtBeam.__index = mtBeam -- If not found in self search here
      mtBeam.__vtorg = Vector() -- Temporary calculation origin vector
      mtBeam.__vtdir = Vector() -- Temporary calculation direct vector
      mtBeam.__meair = {DATA.REFRACT["air"  ], "air"  } -- General air info
      mtBeam.__mewat = {DATA.REFRACT["water"], "water"} -- General water info
function LaserLib.Beam(origin, direct, length)
  local self = {}; setmetatable(self, mtBeam)
  self.VrOrigin = Vector(origin) -- Create local copy for origin not to modify it
  self.VrDirect = Vector(direct) -- Copy direction and normalize when present
  self.BmLength = math.max(tonumber(length) or 0, 0) -- Initial start beam length
  if(self.VrDirect:LengthSqr() > 0) then -- Length is not available use direct
    if(self.BmLength == 0) then self.BmLength = self.VrDirect:Length() end
    self.VrDirect:Normalize() -- Normalize the direction after transfer
  end -- Ray is configured. When direction length is zero we have invalid beam
  self.TsWater  = {P = Vector(), N = Vector()} -- Water surface storage specific
  self.TrMedium = {} -- Contains information for the mediums being traversed
  -- Trace data node points notation row for a given node ID
  --   [1] > Node location in 3D space position (vector)
  --   [2] > Node beam current width automatic (number)
  --   [3] > Node beam current damage automatic (number)
  --   [4] > Node beam current force automatic (number)
  --   [5] > Whenever to draw or not beam line (boolean)
  --   [6] > Color updated by various filters (color)
  self.BmHoleLn = DATA.HARUNTM[3] -- Black hole curve interpolation
  self.IsHoleGv = false -- Is is currently affected by gravity wells
  self.NvHoleLn = 0 -- Trace length used in case of gravity wells
  self.TvPoints = {Size = 0} -- Create empty vertices array for the client
  self.BmTarget = {} -- Stores the trace result when the beam is run
  self.BmWaveLn = 0  -- General beam wavelength. Enabled when greater than zero
  self.BmBranch = {Size = 0} -- In case this beam is branched stores the branch objects
  self.NvDamage = 0 -- Initial current beam damage
  self.NvWidth  = 0 -- Initial current beam width
  self.NvForce  = 0 -- Initial current beam force
  self.DmRfract = 0 -- Diameter trace-back dimensions of the entity
  self.TrRfract = 0 -- Full length for traces not being bound by hit events
  self.BmTracew = 0 -- Make sure beam is zero width during the initial trace hit
  self.IsTrace  = true -- Library is still tracing the beam and calculating nodes
  self.StRfract = false -- Start tracing the beam inside a medium boundary
  self.TrFActor = false -- Trace filter was updated by actor and must be cleared
  self.NvIWorld = false -- Ignore world flag to make it hit the other side
  self.IsRfract = false -- The beam is refracting inside and entity or world solid
  self.NxRgnode = true  -- Enables adding a node to the direction change nodes stack
  self.NvMask   = MASK_ALL -- Trace mask. When not provided negative one is used
  self.NvCGroup = COLLISION_GROUP_NONE -- Collision group. Missing then COLLISION_GROUP_NONE
  self.RaLength = self.BmLength -- Range of the length. Just like wire ranger
  self.NvLength = self.BmLength -- The actual beam lengths subtracted after iterations
  return self
end

--[[
 * Validates the beam object
]]
function mtBeam:IsValid()
  if(not self.VrOrigin) then return false end
  if(not self.VrDirect) then return false end
  if(self.VrDirect:LengthSqr() == 0) then return false end
  if(not (self.BmLength and self.BmLength > 0)) then return false end
  if(self.BrReflec == nil) then return false end
  if(self.BrRefrac == nil) then return false end
  if(self.BmNoover == nil) then return false end
  if(self.BmDisper == nil) then return false end
  if(self.NvLength == nil) then return false end
  if(self.NvBounce == nil) then return false end
  if(self.MxBounce == nil) then return false end
  if(not LaserLib.IsValid(self.BmSource)) then return false end
  if(not LaserLib.IsValid(self.BoSource)) then return false end
  return true
end

--[[
 * Returns the beam target
 * nT > Target index for the specific branch
        Otherwise gets the current beam branching
]]
function mtBeam:GetTarget(nT)
  local nT, pT = tonumber(nT), nil
  if(not nT) then return self.BmTarget end
  pT = self.BmBranch; if(not pT) then return nil end
  if(pT.Size <= 0) then return nil end
  pT = pT[nT]; if(not pT) then return nil end
  return pT.BmTarget
end

--[[
 * Returns the current beam wavelength
]]
function mtBeam:GetWavelength()
  return self.BmWaveLn
end

--[[
 * Updates the current beam wavelength
]]
function mtBeam:SetWavelength(nWav)
  self.BmWaveLn = math.max(0, (tonumber(nWav) or 0))
  return self
end


--[[
 * Returns the current beam flags
]]
function mtBeam:GetFgTexture()
  return self.BmNoover, self.BmDisper
end

--[[
 * Updates the current beam flags
]]
function mtBeam:SetFgTexture(bNov, bDsp)
  self.BmNoover = tobool(bNov) -- Beam no override material flag. Try to extract original material
  self.BmDisper = tobool(bDsp) -- Beam dispersion enable flag. Split white light to its components
  return self
end

--[[
 * Returns the current beam flags
]]
function mtBeam:GetFgDivert()
  return self.BrReflec, self.BrRefrac
end

--[[
 * Updates the current beam flags
]]
function mtBeam:SetFgDivert(bRfl, bRfr)
  self.BrReflec = tobool(bRfl) -- Beam reflection ratio flag. Reduce beam power when reflecting
  self.BrRefrac = tobool(bRfr) -- Beam refraction ratio flag. Reduce beam power when refracting
  return self
end

--[[
 * Returns the current beam force
]]
function mtBeam:GetForce()
  return self.NvForce
end

--[[
 * Updates the current beam force
]]
function mtBeam:SetForce(nF)
  self.NvForce = math.max(tonumber(nF) or 0, 0)
  return self
end

--[[
 * Returns the current beam damage
]]
function mtBeam:GetDamage()
  return self.NvDamage
end

--[[
 * Updates the current beam damage
]]
function mtBeam:SetDamage(nD)
  self.NvDamage = math.max(tonumber(nD) or 0, 0)
  return self
end

--[[
 * Returns the current beam width
]]
function mtBeam:GetWidth()
  return self.NvWidth
end

--[[
 * Updates the current beam width
]]
function mtBeam:SetWidth(nW)
  self.NvWidth  = math.max(tonumber(nW) or 0, 0)
  return self
end

--[[
 * Forces max bounces count
 * iBns > Maximum bounces used during run
]]
function mtBeam:SetBounces(iBns)
  if(iBns) then -- These is forced bounce count
    self.MxBounce = math.max(tonumber(iBns) or 0, 0)
  else -- Use the global convar value
    self.MxBounce = DATA.HARUNTM[1]
  end -- Amount of bounces to control the loop
  self.NvBounce = self.MxBounce
  return self
end

--[[
 * Reads draw color from the beam object when needed
]]
function mtBeam:GetColorRGBA(bcol)
  local c = self.NvColor -- Else source color
  if(not c) then local src = self:GetSource()
    c = (c or src:GetBeamColorRGBA(true))
  end -- No forced colors are present use source
  if(bcol) then return c end -- Return object
  return c.r, c.g, c.b, c.a -- Numbers
end

--[[
 * Cashes the currently used beam color when needed
]]
function mtBeam:SetColorRGBA(mr, mg, mb, ma)
  if(mr or mg or mb or ma) then
    local m, c = DATA.CLMX, nil -- Localize max
    if(self.NvColor) then c = self.NvColor
    else c = Color(0,0,0,0); self.NvColor = c end
    c.r, c.g, c.b, c.a = LaserLib.GetColorRGBA(mr, mg, mb, ma)
  end; return self -- We do not have input parameter
end

--[[
 * Returns the beam current active source entity
]]
function mtBeam:GetSource()
  return (self.BoSource or self.BmSource)
end

--[[
 * Updates the beam source according to the current entity
 * entity > Reference to the current entity
 * former > Reference to the source from last split
]]
function mtBeam:SetSource(base, ...)
  if(LaserLib.IsValid(base)) then
    self.BmSource = base end
  for idx, ent in pairs({...}) do
    if(LaserLib.IsPrimary(ent)) then
      self.BoSource = ent; break
    end -- Source is found
  end -- No source is found
end


--[[
 * Returns the beam current active length
 bS > Swap length priority
]]
function mtBeam:GetLength(bS)
  if(bS) then
    return (self.BmLength or self.BoLength)
  else
    return (self.BoLength or self.BmLength)
  end
end

--[[
 * Makes the laser trace loop use pre-defined length
 * This is done so the next unit will know the
 * actual length when SIMO entities are used
 * nB > Base length according to this entity
 * nO > Origin length according to source
 * bS > Swap length priority
]]
function mtBeam:SetLength(nB, nO, bS)
  local nB = math.max(tonumber(nB) or 0, 0)
    if(nB > 0) then self.BmLength = nB end
  if(nO) then
    local nO = math.max(tonumber(nO) or 0, 0)
    if(nO > 0) then self.BoLength = nO end
  end
  -- Range of the length. Just like wire ranger
  self.RaLength = self:GetLength(bS)
  -- The actual beam length subtracted after iterations
  self.NvLength = self:GetLength(bS)
end

--[[
 * Creates a beam snapshot copy
 * Snapshots have the same property as origin
 * They represent dedicated beam copy at a time
 * tSkp > Keys that are not processed or skipped
 * tOny > Keys that are copied nothing else
 * tAsn > Keys being copied via direct assignment
 * tCpn > Keys that are copied via table.copy
 * tDst > Store the beam copy in this table
]]
function mtBeam:GetCopy(tSkp, tOny, tAsn, tCpn, tDst)
  local cpBeam = CopyData(self, tSkp, tOny, tAsn, tCpn, tDst)
  setmetatable(cpBeam, mtBeam); return cpBeam
end

--[[
 * Validates beam nodes
 * When not valid returns nil
 * Returns validated beam nodes
]]
function mtBeam:GetPoints()
  local tvp = self.TvPoints
  if(not tvp) then return nil end
  if(not tvp[1]) then return nil end
  local szv = tvp.Size -- Vertex size
  if(not szv) then return nil end
  if(szv <= 0) then return nil end
  return tvp, szv
end

--[[
 * Clears all the data from the beam
]]
function mtBeam:Clear(key)
  if(key) then
    self[key] = nil
  else
    for k, v in pairs(self) do
      self[k] = nil end
  end; return self
end

--[[
 * Reads a water member
]]
function mtBeam:GetWater(key)
  local wat = self.TsWater
  if(key) then
    return wat[key]
  else
    return wat
  end
end

--[[
 * Returns the desired node information
 * index > Node index to be used. Defaults to node size
]]
function mtBeam:GetNode(index)
  local tvp = self.TvPoints
  if(index) then
    return tvp[index]
  else
    return tvp[tvp.Size]
  end
end

--[[
 * Passes some of the dedicated distance
]]
function mtBeam:Pass(trace, extern)
  -- By default we are hitting something with fraction
  local decrem = extern and extern or trace.LengthFR
  -- We have to register that the beam has passed trough a medium
  self.NvLength = self.NvLength - decrem
  return self -- Coding effective API
end

--[[
 * Makes the beam skip the entity and continue traversing
 * Setups entity actor filter and applies the actor flag
]]
function mtBeam:SetActor(entity)
  self.TeFilter = entity -- Register the entity actor filter
  self.TrFActor = (entity ~= nil) -- Actor existence boolean
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
 * Checks when water base medium is not activated
]]
function mtBeam:IsAir()
  return self:GetWater().N:IsZero()
end

--[[
 * Calculates dot product with beam direction and
 * the water surface and. Use to check when the
 * beam goes deep or tries to go up and out
 * Uses beam's direction when the parameter is missing
 * Returns various conditions for beam ray in water
 * nil      > Margin unavailable. No water surface
 * zero     > Ray glides on water surface
 * positive > Ray goes out of water
 * negative > Ray goes in the water
]]
function mtBeam:GetWaterDirect(dir)
  if(self:IsAir()) then return nil end
  local wat, tmp = self:GetWater(), self.__vtdir
  tmp:Set(dir or self.VrDirect)
  return tmp:Dot(wat.N)
end

--[[
 * Checks whenever the given position is located
 * above or below the water surface defined
 * pos > World-space position to be checked
 * Uses beam's origin when the parameter is missing
 * Returns various conditions for point in water
 * nil      > Water surface is undefined
 * zero     > Point is on the water
 * positive > Point is above water
 * negative > Point is below water
]]
function mtBeam:GetWaterOrigin(pos)
  if(self:IsAir()) then return nil end
  local wat, tmp = self:GetWater(), self.__vtorg
  tmp:Set(pos or self.VrOrigin); tmp:Sub(wat.P)
  return tmp:Dot(wat.N)
end

--[[
 * Runs a ray trace to find the water surface
 * origin > Trace ray origin position
 * direct > Trace ray origin direction
 * length > External forced length being searched
]]
function mtBeam:SetWaterSurface(origin, direct, length, filter)
  local len = (tonumber(length) or DATA.TRWU)
  local dir = self.__vtdir; dir:Set(direct or DATA.VDRUP)
  local org = self.__vtorg; org:Set(origin or self.VrOrigin)
  if(len <= 0) then len = dir:Length() end; dir:Normalize()
  local wat, tr = self:GetWater(), self:GetTrace(org, dir, len, filter, MASK_ALL)
  wat.P:Set(tr.Normal); wat.P:Mul(tr.FractionLeftSolid * len)
  wat.P:Add(org); wat.N:Set(dir); return self
end

--[[
 * Updates the water surface in the last iteration of entity refraction
 * Exit point is water and water is not registered. Register
 * Exit point is air and water surface is present. Clear water
 * vncon > Content enumerator value for current medium definition
]]
function mtBeam:UpdateWaterSurface(vncon)
  if(LaserLib.InBinary(vncon, CONTENTS_WATER)) then -- Point in the water
    if(self:IsAir()) then -- No water surface defined. Traverse to water
      self:SetWaterSurface()
      self.NvMask = MASK_SOLID -- Start traversing below the water
    end
  else -- Source engine returns that position is not water
    if(not self:IsAir()) then -- Water surface is available. Clear it
      self:ClearWater() -- Clear the water surface. Beam goes out
      self.NvMask = MASK_ALL -- Beam in the air must hit everything
    end -- Beam exits in air. The water surface mist be cleared
  end; return self
end

--[[
 * Clears the water surface normal
]]
function mtBeam:ClearWater()
  self:GetWater().N:Zero() -- Clear water flag
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
 * arg > Empty default to false ( stop trace )
 *       Otherwise passes inverted argument
]]
function mtBeam:Finish(arg)
  self.IsTrace = ((arg ~= nil) and (not tobool(arg)) or false)
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
 * Checks for memory refraction start-refract
 * from the last medium stored in memory and
 * ignores the beam start entity. Checks when
 * the given position is inside the beam source
]]
function mtBeam:IsMemory(index, pos, ent)
  local cnm = (index ~= self.TrMedium.M[1][1])
  if(not pos) then return cnm end
  local src = (ent or self:GetSource())
  return (cnm and not LaserLib.InEntity(pos, src))
end

--[[
 * Registers a medium in the dedicated list
]]
function mtBeam:SetMedium(index, data, mkey, norm)
  if(not index) then return self end
  local info = self.TrMedium[index]
  if(info) then -- Entry is present for this cached medium
    info[1], info[2], info[3] = (data or info[1]), (mkey or info[2]), (norm or info[3])
  else -- Entry for this cached medium is unavailable
    local meair = mtBeam.__meair -- Create trace medium data using the defaults
    self.TrMedium[index] = {(data or meair[1]), (mkey or meair[2]), (norm or Vector())}
  end; return self
end

--[[
 * Updates medium data assigned to a given name
 * Functions using this assume that the name exists
 * name   > Medium name being updated ( mandatory )
 * medium > Reference to medium data ( mandatory )
 * key    > Medium key from the set
 * normal > Normal vector being used
]]
function mtBeam:SetMediumName(name, medium, key, normal)
  local info = self.TrMedium[name]
  if(not info) then return self end
  if(key) then
    info[1] = medium -- Apply medium info
    info[2] = key    -- Apply medium key
  else
    info[1] = medium[1] -- Apply medium info
    info[2] = medium[2] -- Apply medium key
  end
  if(normal) then
    info[3]:Set(normal)
  end
  return self -- Coding effective API
end
--[[
 * Changes the source medium. Source is the medium that
 * surrounds all objects and acts line their environment
 * medium > Medium information ( mandatory )
 * key    > Registry key
]]
function mtBeam:SetMediumSours(medium, key)
  return self:SetMediumName("S", medium, key) -- Coding effective API
end

--[[
 * Changes the destination medium. Destination is the
 * medium that the beam continues its trajectory trough
 * medium > Medium information ( mandatory )
 * key    > Registry key
]]
function mtBeam:SetMediumDestn(medium, key)
  return self:SetMediumName("D", medium, key) -- Coding effective API
end

--[[
 * Changes the memory medium. Memory is the medium that
 * memorizes the last environment beam goes trough
 * medium > Medium information ( mandatory )
 * key    > Registry key
 * normal > Hit normal
]]
function mtBeam:SetMediumMemory(medium, key, normal)
  return self:SetMediumName("M", medium, key, normal) -- Coding effective API
end

--[[
 * Clears configuration parameters for trace medium
 * origin > Beam exit position
 * direct > Beam exit direction
]]
function mtBeam:Divert(origin, direct, reset)
  -- Apply origin and direction when beam exits the medium
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
 * Update trace length fractions and use it in the run method
 * trace > The trace result structure being expanded
 * Initial trace requested length for the current iteration
]]
function mtBeam:SetTraceLength(trace, length)
  -- In this case the value of node register length is calculated
  trace.LengthBS = length -- Actual trace beam user requested length
  trace.LengthFR = length * trace.Fraction -- Length fraction in units
  trace.LengthLS = length * trace.FractionLeftSolid -- Length fraction LS
  trace.LengthNR = self.IsRfract and (self.DmRfract - trace.LengthFR) or trace.LengthFR
  return self -- Coding effective API
end

--[[
 * Updates the hit texture if the trace contents
 * mcont > Medium content entry matched to `REFRACT[ID]`
 * trace > Trace structure of the current iteration
 * Returns a flag when the trace is updated
]]
function mtBeam:SetRefractContent(mcont, trace)
  local g_refract = DATA.REFRACT
  local idx = LaserLib.GetContentsID(mcont)
  if(not idx) then return false end
  local nam = g_refract[idx]
  if(not nam) then return false end
  if(trace) then -- Force zero the fraction
    trace.Fraction = 0
    trace.Contents = mcont
    trace.HitTexture = nam
    trace.HitPos:Set(self.VrOrigin)
    self:SetTraceLength(trace, 0)
  end; self:SetMediumSours(g_refract[nam], nam)
  return true, idx, nam
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
    vtm:Mul(-DATA.TRDGQ * self.BmTracew); trace.HitPos:Add(vtm)
  end -- At this point we know exactly how long will the trace be
  self:SetTraceLength(trace, length)
  return trace, trace.Entity
end

--[[
 * Registers a node when beam traverses from medium [1] to medium [2]
 * origin > The node position to be registered
 * nbulen > Update the length according to the new node
 *          Positive number when provided else internal length
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
  if(cnlen > 0) then -- Subtract the path trough the medium
    self:Pass(nil, cnlen) -- Direct length
  else local size = info.Size -- Read the node stack size
    if(size > 0 and nbulen) then -- Length is not provided
      local prev, vtmp = info[size][1], self.__vtorg
      vtmp:Set(node); vtmp:Sub(prev) -- Relative to previous
      self:Pass(nil, vtmp:Length())
    end -- Use the nodes and make sure previous exists
  end -- Register the new node to the stack
  if(self.NxRgnode) then
    table.insert(info, {node, width, damage, force, bedraw})
    info.Size = info.Size + 1 -- Register the node in stack
  else -- Skip registering this node and write the next one
    self.NxRgnode = true -- Mark the next node for insertion
  end; return self -- Coding effective API
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
  if(power < DATA.POWL) then self:Finish() end -- Absorbs remaining light
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
  local nxt, dir = set[siz][1], self.__vtdir
  dir:Set(self.VrDirect) dir:Mul(self.NvLength)
  nxt:Add(dir); self.NvLength = 0; return false
end

--[[
 * Checks whenever the material is studio
 * Either **studio**, **displacement**, **empty**
 * Includes empty strings as well
]]
function mtBeam:IsMaterial(mat)
  if(not mat) then return false end
  if(mat == "") then return false end
  local g_mtc = DATA.IMAT
  local ms, me = mat:sub(1,1), mat:sub(-1,-1)
  return (ms ~= g_mtc and me ~= g_mtc)
end

--[[
 * Defines how the default material is filled when one is missing
 * Overrides material when `GetSurfaceData` fails to provide values
 * https://wiki.facepunch.com/gmod/Enums/SURF
 * https://wiki.facepunch.com/gmod/Structures/TraceResult
]]
function mtBeam:GetMaterialMiss(mat, trace)
  local mat, g_srf = (mat or trace.HitTexture), DATA.MATSRF
  if(not self:IsMaterial(mat)) then -- String is not material
    mat = g_mat[tostring(trace.MatType)] -- Material lookup
    if(not self:IsMaterial(mat)) then -- No valid material
      local sur = trace.SurfaceFlags -- Read surface flags
      for idx = 1, g_srf.Size do local v = g_srf[idx] -- Index
        -- Use surface assignment. Check surface binary
        mat = (LaserLib.InBinary(sur, v.Sur) and v.Nam or nil)
        -- Lowest indices are taken with priority
        if(self:IsMaterial(mat)) then return mat end
      end -- Check surface. when found exit
    end -- Material has not been fount via lookup
  end; return mat -- Material lookup
end

--[[
 * Auto fills the material using various methods
 * Uses the hit texture and overrides it in case if *
 * https://wiki.facepunch.com/gmod/util.GetSurfaceData
 * https://wiki.facepunch.com/gmod/Structures/TraceResult
]]
function mtBeam:GetMaterialAuto(trace)
  local mat, g_mat = trace.HitTexture, DATA.MATYPE
  if(not self:IsMaterial(mat)) then -- String is not material
    local sur = util.GetSurfaceData(trace.SurfaceProps)
    if(sur) then mat = (sur.name or g_mat[tostring(sur.material)])
      -- In case the surface data exists and returns invalid mat
      if(not self:IsMaterial(mat)) then -- String is not material
        mat = self:GetMaterialMiss(mat, trace) end -- Trigger miss
    else mat = self:GetMaterialMiss(mat, trace) end -- Material lookup
  end; return mat -- Return the override material
end

--[[
 * https://wiki.facepunch.com/gmod/Enums/MAT
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
  if(trace.HitWorld) then -- Use trace material type
    -- Trace material type is unavailable. Use the surface
    return self:GetMaterialAuto(trace) -- Use auto fill
  else -- The trace is hitting a prop. Read the material
    local ent = trace.Entity -- Trace entity object
    if(not LaserLib.IsValid(ent)) then return nil end
    local mat = ent:GetMaterial() -- Entity may not have override
    if(not self:IsMaterial(mat)) then -- Empty then use the original material
      if(self.BmNoover) then mat = ent:GetMaterials()[1]
      else -- No override is enabled return original surface
        mat = self:GetMaterialAuto(trace) -- Use surface type
      end -- Physics object has a single surface type related to model
    end; return mat
  end
end

--[[
 * Samples the medium ahead in given direction
 * This aims to hit a solids of the map or entities
 * On success will return the refraction surface entry
 * Must update custom special case `gmod_laser_refractor`
 * origin > Refraction medium boundary origin
 * direct > Refraction medium boundary surface direct
]]
function mtBeam:GetSolidMedium(origin, direct, filter)
  local tr = self:GetTrace(origin, direct, DATA.NUGE, filter)
  if(not (tr or tr.Hit)) then return nil end -- Nothing traces
  if(tr.Fraction > 0) then return nil end -- Has physical air gap
  local ent, mat = tr.Entity, self:GetMaterialID(tr)
  local refract, key = GetMaterialEntry(mat, DATA.REFRACT)
  if(LaserLib.IsValid(ent)) then
    if(ent:GetClass() == LaserLib.GetClass(12)) then
      if(not refract) then return nil end
      return ent:GetRefractInfo(refract), key
    else -- Return the initial key
      return refract, key -- Return texture behavior
    end -- Entity is valid being refactor or not
  else -- Return whatever is found for this material
    return refract, key -- Invalid entity
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
  self.VrDirect:Negate()
  return self -- Coding effective API
end

--[[
 * Requests a beam reflection
 * ratio > Reflection ratio value
 * trace > The current trace result
]]
function mtBeam:Reflect(trace, ratio)
  self.VrDirect:Set(LaserLib.GetReflected(self.VrDirect, trace.HitNormal))
  self.VrOrigin:Set(trace.HitPos)
  if(self.BrReflec) then self:SetPowerRatio(ratio) end
  return self -- Coding effective API
end

--[[
 * Returns the trace entity valid flag and class
 * Updates the actor exit flag when found
 * target > The entity being the target
]]
function mtBeam:GetActorID(target)
  -- If filter was a special actor and the clear flag is enabled
  -- Make sure to reset the filter if needed to enter actor again
  if(self.TrFActor) then self:SetActor() end -- Custom filter clear
  -- Filter is present and we have request to clear the value
  -- Validate trace target and extract its class if available
  local suc, cas = LaserLib.IsValid(target), nil -- Validate target
  if(suc) then cas = target:GetClass() end; return suc, cas
end

--[[
 * Performs library dedicated beam trace with custom configuration
 * Stores the result in a dedicated beam trace table output
 * This is internal class wrapper for running `TraceBeam`
 * origin > Trace origin.        Mandatory vector
 * direct > Trace direction.     Mandatory vector
 * length > Trace length.        Default `direction:Length()`
 * filter > Trace filter.        Directly assigned value
 * mask   > Trace hit mask.      Default `MASK_SOLID`
 * colgrp > Trace collide group. Default `COLLISION_GROUP_NONE`
 * iworld > Trace ignore world.  Default `false`
 * width  > Trace beam width.    Default `0`
]]
function mtBeam:GetTrace(origin, direct, length, filter, mask, colgrp, iworld, width)
  local origin, direct = (origin or self.VrOrigin), (direct or self.VrDirect)
  return TraceBeam(origin, direct, length, filter, mask, colgrp, iworld, width, mtBeam.__trace)
end

--[[
 * Performs library dedicated beam trace. Runs a
 * CAP trace. When it fails runs a general trace
 * result > Trace output destination table as standard config
]]
function mtBeam:Trace(result)
  local destin, tr, ta = (result or self.BmTarget), nil, nil
  local length = (self.IsHoleGv and self.NvHoleLn or self.NvLength)
        length = (self.IsRfract and self.TrRfract or length)
  if(not self.IsRfract) then -- CAP trace is not needed when we are refracting
    tr = TraceCAP(self.VrOrigin, self.VrDirect, length, self.TeFilter)
    if(tr) then -- Return CAP currently hit and fill up destination
      if(destin) then -- Merge CAP result into the beam result
        tr, ta = self:SetTraceWidth(table.Merge(destin, tr), length)
      else tr, ta = self:SetTraceWidth(tr, length) end
      return tr, ta -- Return what has been provided by CAP
    end -- Traces done by CAP did not register anything
  end -- When the trace is not specific CAP entity continue
  tr, ta = self:SetTraceWidth(TraceBeam( -- Otherwise use the standard trace
    self.VrOrigin, self.VrDirect, length       , self.TeFilter,
    self.NvMask  , self.NvCGroup, self.NvIWorld, self.BmTracew, destin), length)
  return tr, ta
end

--[[
 * Calculates where the beam exits from the source
 * origin  > Beam origin location vector
 * direct  > Beam ray direction vector
 * target  > Entity target being checked
 * util.IntersectRayWithOBB
]]
function mtBeam:SetTraceExit()
  local org, dir = self.__vtorg, self.__vtdir
  local ent, len = self:GetSource(), self:GetLength()
  local mib, mab = ent:OBBMins(), ent:OBBMaxs()
  local anb, psb = ent:GetAngles(), ent:GetPos()
  org:Set(self.VrOrigin); dir:Set(self.VrDirect); dir:Mul(len)
  local rox = util.IntersectRayWithOBB(org, dir, psb, anb, mib, mab)
  if(not rox) then return self end
  local ren = (DATA.BRAD * ent:BoundingRadius())
  local nor = dir:GetNormalized(); nor:Mul(ren)
  rox:Add(nor); nor:Negate(); nor:Normalize(); nor:Mul(ren * DATA.ERAD)
  local roe = util.IntersectRayWithOBB(rox, nor, psb, anb, mib, mab)
  if(not roe) then return self end; self.VrOrigin:Set(roe)
  self:RegisterNode(roe, false, true); return self
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
  -- Register destination medium and raise calculate refraction flag
  if(refract) then self:SetMediumDestn(refract, key) end -- Change medium boundary
  -- Get the trace ready to check the other side and point and register the location
  self.DmRfract = (DATA.BRAD * target:BoundingRadius()) -- Diameter with a bit of margin
  if(direct) then self.VrDirect:Set(direct) end -- Forced direction available
  self.VrOrigin:Set(self.VrDirect)
  self.VrOrigin:Mul(self.DmRfract)
  self.VrOrigin:Add(origin)
  self.VrDirect:Negate()
  -- Must hit only this entity otherwise it is invalid
  self.TeFilter = function(ent) return (ent == target) end
  self.NvIWorld = true -- We are interested only in the refraction entity
  self.IsRfract = true -- Raise the bounce off refract flag
  self.BmTracew = DATA.TRWD -- Increase the beam width for back track
  self.TrRfract = (DATA.ERAD * self.DmRfract) -- Scale again to make it hit
  return self -- Coding effective API
end

--[[
 * Handles refraction of water to air
 * Diverts the beam from water to air at the boundary
 * point when water flag is triggered and hit position is
 * outside the water surface.
]]
function mtBeam:RefractWaterAir()
  -- When beam started inside the water and hit outside the water
  local org, dir, wat = self.VrOrigin, self.VrDirect, self:GetWater()
  -- This can be called then beam goes out of the water
  -- and will ensure no overhead traces will be needed.
  local vwa = util.IntersectRayWithPlane(org, dir, wat.P, wat.N)
  -- Water-air intersection point is stored in `vwa`
  -- The intersection point will never be empty in this case
  local mewat, meair, vtm = mtBeam.__mewat, mtBeam.__meair, self.__vtorg
  -- Registering the node cannot be done with direct subtraction
  self:RegisterNode(vwa, true); vtm:Set(wat.N); vtm:Negate()
  local vdir, bnex = self:Refract(dir, vtm, mewat[1][1], meair[1][1])
  if(bnex) then
    self.NvMask = MASK_ALL -- We change the medium to air
    self:ClearWater() -- Set water normal flag to zero
    self:SetMediumSours(meair) -- Switch to air medium
    self:Divert(vwa, vdir, true) -- Divert and reset laser beam
  else -- Divert the beam in case of going out reset medium
    self.NvMask = MASK_SOLID -- We stay in the water and hit stuff
    self:Divert(vwa, vdir) -- Divert only do not reset beam
  end -- Apply power ratio when requested
  if(self.BrRefrac) then self:SetPowerRatio(mewat[1][2]) end
  return self -- Coding effective API
end

--[[
 * Configures and activates the water refraction surface
 * The beam may start in the water or hit it and switch
 * mekey > Key indication for medium type found in the water
 * mecon > Medium contents found in initial iteration
 * trace > Trace result structure output being used
]]
function mtBeam:SetSurfaceWorld(mekey, mecon, trace)
  local wat, mewat = self:GetWater(), mtBeam.__mewat
  local vae, air = LaserLib.InBinary(mecon, CONTENTS_WATER), self:IsAir()
  if(not vae and mekey) then vae = mekey:find(mewat[2], 1, true) end
  if(self.StRfract) then
    if(vae and air) then -- Water is not yet registered for transition
      self:SetWaterSurface() -- Register the water surface
      self.NvMask = MASK_SOLID -- We stay in the water and hit stuff
    else -- Refract type is not water so reset the configuration
      self:ClearWater() -- Clear the water indicator normal vector
    end -- Water refraction configuration is done
  else -- Refract type not water then setup
    if(vae and air) then -- Water is not yet registered for transition
      self.NvMask = MASK_SOLID -- We stay in the water and hit stuff
      if(trace) then
        wat.P:Set(trace.HitPos) -- Memorize the surface position
        wat.N:Set(trace.HitNormal) -- Memorize the surface normal
      else -- Will most likely never happen but still possible
        self:SetWaterSurface() -- Register the water surface
      end
    else -- Refract type is not water so reset the configuration
      self:ClearWater() -- Clear the water indicator normal vector
    end -- Water refraction configuration is done
  end; return self -- Coding effective API
end

--[[
 * Setups the class for world and water refraction
]]
function mtBeam:SetRefractWorld(trace, refract, key)
  -- Register destination medium and raise calculate refraction flag
  if(refract) then self:SetMediumDestn(refract, key) end -- Change medium
  -- Subtract traced length from total length because we have hit something
  self.TrRfract = self.NvLength -- Remaining length in refract mode
  -- Separate control for water and non-water
  if(self:IsAir()) then -- There is no water surface registered
    self.IsRfract = true -- Beam is inside another non water solid
    self.NvIWorld = false -- World transparent objects do not need world ignore
    self.NvMask = MASK_ALL -- Beam did not traverse into water
    self.BmTracew = DATA.TRWD -- Increase the beam width for back track
    -- Apply world-only filter for refraction exit the location
    self.TeFilter = DATA.FILTW -- Function that filters hit world only
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
]]
function mtBeam:IsTraverse(origin, direct, normal, target)
  local org = mtBeam.__vtorg; org:Set(origin or self.VrOrigin)
  local dir = mtBeam.__vtdir; dir:Set(direct or self.VrDirect)
  local refract = self:GetSolidMedium(org, dir, target)
  if(not refract) then return false end
  -- Refract the hell out of this requested beam with entity destination
  local vdir, bnex, bsam = self:Refract(dir,
                 normal, self.TrMedium.D[1][1], refract[1])
  if(bnex) then
    self.IsRfract, self.StRfract = false, true -- Force start-refract
    self:Divert(org, nil, true) -- The beam did not traverse mediums
    self:SetMediumMemory(self.TrMedium.D, nil, normal)
    if(self.BrRefrac and not bsam) then self:SetPowerRatio(refract[2]) end
  else -- Get the trace ready to check the other side and register the location
    self:SetTraceNext(org, vdir) -- The beam did not traverse mediums
    if(self.BrRefrac and not bsam) then self:SetPowerRatio(self.TrMedium.D[1][2]) end
  end; return true -- Apply power ratio when requested
end

--[[
 * This does some logic on the start entity
 * Preforms some logic to calculate the filter
 * entity > Entity we intend the start the beam from
]]
function mtBeam:SourceFilter(entity, ...)
  if(not LaserLib.IsValid(entity)) then return self end
  -- Populated custom depending on the API
  if(entity.RecuseBeamID and self.BmRecstg == 1) then -- Recursive
    entity.RecuseBeamID = 0 -- Reset entity hit report index
  end -- We need to reset the top index hit reports count
  -- Make sure the initial laser source is skipped
  if(entity:IsPlayer()) then local eGun = entity:GetActiveWeapon()
    if(LaserLib.IsUnit(eGun)) then self.BmSource, self.TeFilter = eGun, {entity, eGun, ...} end
  elseif(entity:IsWeapon()) then local ePly = entity:GetOwner()
    if(LaserLib.IsUnit(entity)) then self.BmSource, self.TeFilter = entity, {entity, ePly, ...} end
  else -- Switch the filter according to the weapon the player is holding
    self.BmSource, self.TeFilter = entity, {entity, ...}
  end; return self
end

--[[
 * This does post-update and registers beam sources
 * Preforms some logic to calculate the filter
 * trace > Trace result after the last iteration
]]
function mtBeam:UpdateSource(trace)
  local trace = trace or self.BmTarget
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
 * index > Refraction index for the new medium boundary
 * trace > Trace result structure of the current trace beam
]]
function mtBeam:GetBoundaryEntity(index, trace)
  local bnex, bsam, vdir -- Refraction entity direction and reflection
  local dir, merum = self.VrDirect, self.TrMedium -- Localize medium
  -- Call refraction cases and prepare to trace-back
  if(self.StRfract) then -- Bounces were decremented so move it up
    if(self:IsFirst()) then
      vdir, bnex = Vector(dir), true -- Node starts inside solid
    else -- When two props are stuck save the middle boundary and traverse
      -- When the traverse mediums is different and node is not inside a laser
      if(self:IsMemory(index)) then
        vdir, bnex, bsam = self:Refract(dir, merum.M[3], merum.M[1][1], index)
        -- Do not waste game ticks to refract the same refraction ratio
      else -- When there is no medium refractive index traverse change
        vdir, bsam = Vector(dir), true -- Keep the last beam direction
      end -- Finish start-refraction for current iteration
    end -- Marking the fraction being zero and refracting from the last entity
    self.StRfract = false -- Make sure to disable the flag again
  else -- Otherwise do a normal water-entity-air refraction
    vdir, bnex, bsam = self:Refract(dir, trace.HitNormal, merum.S[1][1], index)
  end
  return bnex, bsam, vdir
end

--[[
 * Handles black hole gravity field effects
 * Generally light path being bend by heavy objects
 * Black holes. Treat them as direction vector deviation
 * In case of refraction. The gravity direction is unaffected
]]
function mtBeam:ApplyGravity()
  if(self.IsRfract) then return self end
  if(self.BmHoleLn <= 0) then return self end
  local g_blhole, g_rnd = DATA.BLHOLE, DATA.RNBH
  local vgrv, ngrv, xgrv = nil, nil, nil
  for case, info in pairs(g_blhole) do
    for hole, bool in pairs(info.Registry) do
      if(LaserLib.IsValid(hole)) then
        local org, dir = self.VrOrigin, self.VrDirect
        local cen, rad = info.GetCenter(hole), info.GetRadius(hole)
        local nFFr, nFBa = util.IntersectRayWithSphere(org, dir, cen, rad)
        if(nFFr and nFBa) then -- Ray intersects with gravity well
          local rFFr, rFBa = math.Round(nFFr, g_rnd), math.Round(nFBa, g_rnd)
          if(rFFr > 0 and rFBa > 0) then -- Ray will enter a gravity well
            -- The beam entry point is at `nFFr` fraction relative to the origin
            ngrv = (ngrv and math.min(ngrv, nFFr) or nFFr)
          elseif(rFFr < 0 and rFBa < 0) then -- Ray is outside this black hole
            -- Beam has already exited the well
            xgrv = (xgrv and math.max(xgrv, nFFr) or nFFr)
          elseif(rFFr <= 0 and rFBa >= 0) then -- Ray starts inside a well
            -- Start to amend the trace direction instantly towards the well
            if(not vgrv) then vgrv = Vector() end
            vgrv:Add(info.GetAffect(hole, org, self.BmHoleLn))
            self.IsHoleGv = true
            self.NvHoleLn = self.BmHoleLn
          end
        end
      else info.Registry[hole] = nil end
    end
  end
  if(vgrv) then self.VrDirect:Add(vgrv); return self end
  if(ngrv) then
    if(self.NvLength > ngrv) then
      self.IsHoleGv, self.NvHoleLn = true, ngrv
    else self.IsHoleGv = false end; return self
  end
  if(xgrv) then
    self.IsHoleGv = false
    return self
  end
  return self
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
  local tvpnt, szv = self:GetPoints()
  if(not tvpnt) then return self end
  -- Update rendering boundaries
  local tbran = self.BmBranch
  local sours = (sours or self.BmSource)
  local bmin, bmax = sours:GetRenderBounds()
        bmin:Set(sours:LocalToWorld(bmin))
        bmax:Set(sours:LocalToWorld(bmax))
  -- Extend render bounds with player view
  local vuser = LaserLib.GetPlayerView(20)
  LaserLib.UpdateBounds(bmin, math.min, vuser)
  LaserLib.UpdateBounds(bmax, math.max, vuser)
  -- Extend render bounds with entity OBB
  local omin = sours:LocalToWorld(sours:OBBMins())
  local omax = sours:LocalToWorld(sours:OBBMaxs())
  LaserLib.UpdateBounds(bmin, math.min, omin)
  LaserLib.UpdateBounds(bmax, math.max, omax)
  -- Extend render bounds with the first node
  local from = tvpnt[1][1] -- Beam start
  LaserLib.UpdateBounds(bmin, math.min, from)
  LaserLib.UpdateBounds(bmax, math.max, from)
  -- Adjust the render bounds with world-space coordinates
  sours:SetRenderBoundsWS(bmin, bmax) -- World space is faster
  -- Material must be cached and updated with left click setup
  if(imatr) then render.SetMaterial(imatr) end
  local cup = (color or self.NvColor)
  local spd = DATA.DRWBMSPD:GetFloat()
  -- Draw the beam sequentially being faster
  for idx = 2, szv do
    local new = tvpnt[idx]
    local org = tvpnt[idx - 1]
    local ntx, otx = new[1], org[1] -- Read origin
    -- Make sure the coordinates are converted to world ones
    LaserLib.UpdateBounds(bmin, math.min, ntx)
    LaserLib.UpdateBounds(bmax, math.max, ntx)
    -- When we need to draw the beam with rendering library
    if(org[5]) then cup = (org[6] or cup) -- Change color
      local wdt = LaserLib.GetWidth(org[2]) -- Start width
      local dtm, len = (spd * CurTime()), ntx:Distance(otx)
      render.DrawBeam(otx, ntx, wdt, dtm + len / 16, dtm, cup)
    end -- Draw the actual beam texture
  end -- Adjust the render bounds with world-space coordinates
  sours:SetRenderBoundsWS(bmin, bmax)
  if(tbran.Size > 0) then
    for idx = 1, tbran.Size do
      tbran[idx]:Draw(sours, imatr, color) end
  end; return self
end

--[[
 * This is actually faster than stuffing all the beams
 * information for every laser in a dedicated table and
 * draw the table elements one by one at once.
 * sours > Entity keeping the beam effects internals
 * endrw > Draw enabled flag from beam sources
]]
function mtBeam:DrawEffect(sours, endrw)
  if(SERVER) then return self end
  local sours = (sours or self:GetSource())
  local trace = self:GetTarget()
  if(trace and not trace.HitSky and
     endrw and sours.isEffect)
  then -- Drawing effects is enabled
    if(not sours.dtEffect) then
      sours.dtEffect = EffectData()
    end -- Allocate effect class
    if(not trace.Hit) then return self end
    if(trace.NoEffect) then return self end
    local ent, eff = trace.Entity, sours.dtEffect
    if(LaserLib.IsUnit(ent)) then return self end
    eff:SetStart(trace.HitPos)
    eff:SetOrigin(trace.HitPos)
    eff:SetNormal(trace.HitNormal)
    util.Effect("AR2Impact", eff)
    -- Draw particle effects
    if(self.NvDamage <= 0) then return self end
    if(ent:IsPlayer() or ent:IsNPC()) then
      util.Effect("BloodImpact", eff)
    else
      local dmr = DATA.MXBMDAMG:GetFloat()
      local mul = (self.NvDamage / dmr)
      local dir = LaserLib.GetReflected(self.VrDirect,
                                        trace.HitNormal)
      eff:SetNormal(dir)
      eff:SetScale(0.5)
      eff:SetRadius(10 * mul)
      eff:SetMagnitude(3 * mul)
      util.Effect("Sparks", eff)
    end
  end; return self
end

--[[
 * Function handler for calculating SISO actor routines
 * These are specific handlers for specific classes
 * having single input beam and single output beam
 * beam  > Reference to laser beam class
]]
DATA.ACTORS = {
  ["event_horizon"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent, src = trace.Entity, beam:GetSource()
    local pob, dir, eff = trace.HitPos, beam.VrDirect, src.isEffect
    local out = LaserLib.GetBeamExit(ent, ent.Target)
    if(out == ent) then return end -- We need to go somewhere
    if(not LaserLib.IsValid(out)) then return end
    local node = beam:GetNode(); node[5] = false -- Skip node
    -- Leave networking to CAP. Invalid target. Stop
    local pot, dit = ent:GetTeleportedVector(pob, dir)
    if(SERVER and ent:IsOpen() and eff) then -- Library effect flag
      ent:EnterEffect(pob, beam.NvWidth) -- Enter effect
      out:EnterEffect(pot, beam.NvWidth) -- Exit effect
    end -- Stargate ( CAP ) requires little nudge in the origin vector
    beam.VrOrigin:Set(pot); beam.VrDirect:Set(dit)
    -- Otherwise the trace will get stick and will hit again
    beam:RegisterNode(beam.VrOrigin, false, true)
    beam:SetActor(out); beam:Finish(false)
  end,
  ["gmod_laser_portal"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent, src = trace.Entity, beam:GetSource()
    if(not ent:IsHitNormal(trace)) then return end
    local idx = (tonumber(ent:GetEntityExitID()) or 0)
    if(idx <= 0) then return end -- No output ID chosen
    local out = ent:GetActiveExit(idx) -- Validate output entity
    if(not out) then return end -- No output ID. Missing entity
    local node = beam:GetNode(); node[5] = false -- Skip node
    local nrm = ent:GetNormalLocal() -- Read current normal
    local bnr = (nrm:LengthSqr() > 0) -- When the model is flat
    local mir = ent:GetMirrorExitPos()
    local pos, dir = trace.HitPos, beam.VrDirect
    local nps, ndr = LaserLib.GetBeamPortal(ent, out, pos, dir,
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
          local trn, wmr = Vector(trace.HitNormal), DATA.WLMR
          trn:Mul(wmr); trn:Add(ent:GetPos())
          trn:Set(ent:WorldToLocal(trn)); trn:Div(wmr)
          pdir:Set(LaserLib.GetReflected(pdir, trn))
        else
          local v, a = ent:ToCustomUCS(pdir)
          v.x = -v.x; v.y = -v.y
          pdir:Set(v); pdir:Rotate(a)
        end
      end)
    beam.VrOrigin:Set(nps); beam.VrDirect:Set(ndr)
    beam:RegisterNode(beam.VrOrigin, false, true)
    beam:SetActor(out)
    beam:Finish(false) -- Output model is validated. Continue
  end,
  ["prop_portal"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent, src = trace.Entity, beam:GetSource()
    if(not ent:IsLinked()) then return end -- No linked pair
    local opr = (SERVER and ent:FindOpenPair() or nil)
    local out = LaserLib.GetBeamExit(ent, opr)
    if(out == ent) then return end -- We need to go somewhere
    if(not LaserLib.IsValid(out)) then return end
    local dir, pos = beam.VrDirect, trace.HitPos
    local mav, vsm = LaserLib.GetMarginPortal(ent, pos, dir)
    beam:RegisterNode(mav, false, false)
    local nps, ndr = LaserLib.GetBeamPortal(ent, out, pos, dir)
    beam:RegisterNode(nps); nps:Add(vsm * ndr)
    beam.VrOrigin:Set(nps); beam.VrDirect:Set(ndr)
    beam:RegisterNode(nps)
    beam:SetActor(out)
    beam:Finish(false) -- Output portal is validated. Continue
  end,
  ["gmod_laser_dimmer"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent = trace.Entity -- Retrieve class trace entity
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, beam, trace, bmln)
    if(trace and trace.Hit and bdot) then
      beam:Finish(false) -- Beam hits correct surface. Continue
      local vdot = (ent:GetBeamReplicate() and 1 or mdot)
      local node = beam:SetPowerRatio(vdot) -- May absorb
      beam.VrOrigin:Set(trace.HitPos)
      beam:SetActor(ent) -- Makes beam pass the unit
    end
  end,
  ["seamless_portal"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent, out = trace.Entity
    local out = ent:GetExitPortal() -- Retrieve open pair
    if(not LaserLib.IsValid(out)) then return end
    local esz, osz = ent:GetSize(), out:GetSize()
    local szx = (osz.x / esz.x)
    local szy = (osz.y / esz.y)
    local szz = (osz.z / esz.z)
    local pos, dir = trace.HitPos, beam.VrDirect
    local mav, vsm = LaserLib.GetMarginPortal(ent, pos, dir, trace.HitNormal)
    beam:RegisterNode(mav, false, false)
    local nps, ndr = LaserLib.GetBeamPortal(ent, out, pos, dir,
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
    beam:SetActor(out) -- Makes beam pass the unit
    beam:Finish(false) -- Output portal is validated. Continue
  end,
  ["gmod_laser_rdivider"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
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
  ["gmod_laser_filter"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent, src = trace.Entity, beam:GetSource()
    local norm = ent:GetHitNormal()
    local bdot = ent:GetHitPower(norm, beam, trace)
    if(trace and trace.Hit and bdot) then
      local node = beam:GetNode() -- Extract last node
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
        beam:SetActor(ent) -- Makes beam pass the unit
        beam:Finish(false) -- Beam hits correct surface. Continue
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
            node[6].r = (ec.r > 0) and math.Clamp(sc.r, 0, ec.r) or sc.r
            node[6].g = (ec.g > 0) and math.Clamp(sc.g, 0, ec.g) or sc.g
            node[6].b = (ec.b > 0) and math.Clamp(sc.b, 0, ec.b) or sc.b
            node[6].a = (ec.a > 0) and math.Clamp(sc.a, 0, ec.a) or sc.a
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
        beam:SetActor(ent) -- Makes beam pass the unit
        beam:Finish(false) -- Beam hits correct surface. Continue
      end
    end
  end,
  ["gmod_laser_parallel"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent = trace.Entity -- Retrieve class trace entity
    local norm, bmln = ent:GetHitNormal(), ent:GetLinearMapping()
    local bdot, mdot = ent:GetHitPower(norm, beam, trace, bmln)
    if(trace and trace.Hit and bdot) then
      beam:Finish(false) -- Beam hits correct surface. Continue
      local focu = ent:GetFocus() -- Apply custom focus
      local rx, ry = ent:GetDeviation() -- Beam deviation
      local vdot = (ent:GetBeamDimmer() and mdot or 1)
      local node = beam:SetPowerRatio(vdot) -- May absorb
      beam.VrOrigin:Set(trace.HitPos)
      if(focu == 0) then
        beam.VrDirect:Set(trace.HitNormal); beam.VrDirect:Negate()
      else
        local nor = trace.HitNormal -- Surface normal
        local pos, dir = beam.VrOrigin, beam.VrDirect
        local obb = ent:LocalToWorld(ent:OBBCenter())
        local irs = util.IntersectRayWithPlane(pos, dir, obb, nor)
        if(not irs) then return end
        obb:Sub(irs); obb:Mul(focu)
        beam.VrDirect:Add(obb)
        beam.VrDirect:Normalize()
      end
      if(rx ~= 0 or ry ~= 0) then
        local brnd = ent:GetDeviateRandom()
        local sang = beam.VrDirect:Angle()
        local axsX, axsY = sang:Up(), sang:Right()
        --Randomize the exit direction
        local rand = (brnd and (math.random() - 0.5) or 1)
        sang:RotateAroundAxis(axsX, rx * rand)
        sang:RotateAroundAxis(axsY, ry * rand)
        beam.VrDirect:Set(sang:Forward())
      end
      beam:SetActor(ent) -- Makes beam pass the unit
    end
  end,
  ["gmod_laser_reflector"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local mat = beam:GetMaterialID(trace)
    local reflect = GetMaterialEntry(mat, DATA.REFLECT)
    if(not reflect) then return end -- No reflective surface. Exit
    local ent = trace.Entity -- Store local unit reference
    local rat = ent:GetReflectRatio() -- Read reflection ratio from entity
    beam:Finish(false) -- Call reflection method
    beam:Reflect(trace, (rat > 0) and rat or reflect[1])
  end,
  ["gmod_laser_refractor"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local mat = beam:GetMaterialID(trace) -- Current extracted material as string
    local refract, key = GetMaterialEntry(mat, DATA.REFRACT)
    if(not refract) then return end
    local ent = trace.Entity -- Store local unit reference
    local refcopy = ent:GetRefractInfo(refract)
    local bnex, bsam, vdir = beam:GetBoundaryEntity(refcopy[1], trace)
    if(ent:GetHitSurfaceMode()) then
      beam:Divert(trace.HitPos, vdir) -- Divert the beam on the surface
      beam:SetActor(ent) -- Makes beam pass the unit
    else -- Refraction done using multiple surfaces
      if(bnex or bsam) then -- We have to change mediums
        beam:SetRefractEntity(trace.HitPos, vdir, ent, refcopy, key)
      else -- Divert the beam with the reflected ray
        beam:Divert(trace.HitPos, vdir)
      end -- Tracing is enabled
    end; beam:Finish(false) -- Apply refraction ratio
    if(beam.BrRefrac) then beam:SetPowerRatio(refcopy[2]) end
  end,
  ["glua_custom_props"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent = trace.Entity
    if(not LaserLib.IsValid(ent)) then return end
    local dim, mat = ent:GetColor()["a"]
    if(dim == 255) then
      mat = beam:GetMaterialID(trace)
    else
      local phy = ent:GetPhysicsObject()
      if(not LaserLib.IsValid(phy)) then return end
      mat = phy:GetMaterial()
    end
    if(dim == 255) then
      local reflect = GetMaterialEntry(mat, DATA.REFLECT)
      if(reflect) then beam:Finish(false)
        beam:Reflect(trace, reflect[1]) -- Call reflection
        return -- Bail out with making just the reflection
      end
    end
    local refract, key = GetMaterialEntry(mat, DATA.REFRACT)
    if(not refract) then return end; beam:Finish(false)
    local bnex, bsam, vdir = beam:GetBoundaryEntity(refract[1], trace)
    if(bnex or bsam) then -- We have to change mediums
      beam:SetRefractEntity(trace.HitPos, vdir, ent, refract, key)
    else -- Divert the beam with the reflected ray
      beam:Divert(trace.HitPos, vdir)
    end
    if(beam.BrRefrac) then beam:SetPowerRatio(refract[2]) end
  end,
  ["procedural_shard"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local mat = beam:GetMaterialID(trace) -- Current extracted material as string
    local reflect = GetMaterialEntry(mat, DATA.REFLECT)
    if(reflect) then beam:Finish(false)
      beam:Reflect(trace, reflect[1]) -- Call reflection method
    else
      local refract, key = GetMaterialEntry(mat, DATA.REFRACT)
      if(not refract) then return end
      local ent = trace.Entity
      if(not LaserLib.IsValid(ent)) then return end
      local bnex, bsam, vdir = beam:GetBoundaryEntity(refract[1], trace)
      if(bnex or bsam) then -- We have to change mediums
        beam:SetRefractEntity(trace.HitPos, vdir, ent, refract, key)
      else -- Divert the beam with the reflected ray
        beam:Divert(trace.HitPos, vdir)
      end; beam:Finish(false)
      if(beam.BrRefrac) then beam:SetPowerRatio(refract[2]) end
    end
  end,
  ["gwater_blackhole"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    trace.NoEffect = true
  end,
  ["gwater2_blackhole"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    trace.NoEffect = true
  end,
  ["gmod_laser_sensor"] = function(beam)
    local trace = beam:GetTarget() -- Read current trace
    local ent = trace.Entity
    if(not ent:GetPassBeamTrough()) then return end
    if(SERVER) then
      local pss = ent.pssSources
      local src = beam:GetSource()
      if(LaserLib.IsValid(src)) then
        local idx, pdt = beam.BmIdenty, pss.Data
        local pky = DATA.FPSS:format(src:EntIndex(), idx)
        local dat = pdt[pky]; pss.Time = CurTime()
        local tcb, bcn = pss.Copy, false
        if(dat) then -- Update beam entry
          dat.Src = src; dat.Tim = pss.Time
          dat.Pbm = beam:GetCopy(nil, tcb.Ony, tcb.Asn, tcb.Cpn, dat.Pbm)
        else -- Entry is missing so create one
          pdt[pky] = {}; dat = pdt[pky]; bcn = true
          dat.Src = src; dat.Tim = pss.Time
          dat.Pbm = beam:GetCopy(nil, tcb.Ony, tcb.Asn, tcb.Cpn)
        end -- Work only for valid entity sources
        for key, set in pairs(pdt) do  -- Check all items
          if(LaserLib.IsTime(set.Tim)) then -- Time delta is passed
            pdt[key] = nil; bcn = true -- Remove and trigger ordering
          end -- Continue to trace the beam
        end -- Ordering is needed
        if(bcn) then -- Data change is present start handling it
          pss.Keys = table.GetKeys(pss.Data) -- Read keys from key-table
          table.sort(pss.Keys, function(cr, nx) -- Sort keys by data content
            return (pss.Data[cr].Tim > pss.Data[nx].Tim) -- Return boolean
          end); pss.Size = #pss.Keys -- Record with the biggest time is more recent
        end -- Order by the time the beam hits the sensor
      end -- Work only for valid entity sources
    end -- Continue to trace the beam
    beam.VrOrigin:Set(trace.HitPos)
    beam:Finish(false) -- Still tracing
    beam:SetActor(ent) -- Makes beam pass the unit
  end
}

--[[
 * Registers and actor function for entity specified class
 * The function argument are (beam) and define
 * what will happen if the beam loop meats this entity class
 * ent > Entity of the desired class to have a handler
 * act > Action function (beam) to handle entity
]]
function LaserLib.SetActor(ent, act)
  if(not LaserLib.IsValid(ent)) then
    error("Entity mismatch: "..tostring(ent)) end
  local ty = type(act); if(ty ~= "function") then
    error("Actor mismatch: ".. ty) end
  DATA.ACTORS[ent:GetClass()] = act
end

function LaserLib.GetActor(ent)
  if(not LaserLib.IsValid(ent)) then
    error("Entity mismatch: "..tostring(ent)) end
  local act = DATA.ACTORS[ent:GetClass()]
  local ty = type(act); if(ty ~= "function") then
    error("Actor mismatch: ".. ty) end
  return act
end

if(SERVER) then
  --[[
   * Function handler for calculating target custom damage
   * These are specific handlers for specific classes
   * Arguments are the same as `LaserLib.DoDamage`
  ]]
  DATA.DAMAGE = {
    ["shield"] = function(beam, param)
      local origin, normal = param.origin, param.normal
      local laser , target = param.laser , param.target
      local damage = math.Clamp(param.damage / 2500 * 3, 0, 4)
      target:Hit(laser, origin, damage, -1 * normal)
      return true -- Exit main damage routine
    end,
    ["#ISPLAYER#"] = function(beam, param)
      beam:DoSound(param) -- Play sound for breakable props
      local target = param.target
      local torch = beam:GetTorch(param)
      if(LaserLib.IsValid(torch)) then
        local swep = target:GetActiveWeapon() -- Do we have weapon to wipe
        beam:TakeDamage(param) -- Do damage to generate the ragdoll
        local doll = target:GetRagdollEntity() -- We need to kill the player first to get his ragdoll
        if(LaserLib.IsValid(doll)) then
          if(LaserLib.IsValid(swep)) then swep:SetName(torch.Target) end
          doll:SetName(torch.Target) -- Allowing us to dissolve him the cleanest way
          beam:DoDissolve(torch) -- Dissolver only for player and NPC
          return true -- Exit main damage routine
        else
          beam:TakeDamage(param, DMG_DISSOLVE)
          target:Kill(); return true -- Exit main damage routine
        end
      else
        beam:TakeDamage(param, DMG_DISSOLVE)
        target:Kill(); return true -- Exit main damage routine
      end
    end,
    ["#ISNPC#"] = function(beam, param)
      beam:DoSound(param) -- Play sound for breakable props
      local target = param.target
      local torch = beam:GetTorch(param)
      if(LaserLib.IsValid(torch)) then
        local swep = target:GetActiveWeapon() -- Do we have weapon to wipe
        if(LaserLib.IsValid(swep)) then swep:SetName(torch.Target) end -- Mark weapon
        target:SetName(torch.Target) -- The NPC does not have kill method. Mark it
        beam:TakeDamage(param) -- Do damage to generate the ragdoll
        beam:DoDissolve(torch) -- Dissolver only for player and NPC
        return true -- Exit main damage routine
      else
        beam:TakeDamage(param, DMG_DISSOLVE)
        target:Remove(); return true -- Exit main damage routine
      end
    end
  }

  --[[
   * Registers how a custom class handles damage
   * ent > Entity class as key to be registered
   * act > Function for handling custom damage
  ]]
  function LaserLib.GetDamage(ent)
    if(not LaserLib.IsValid(ent)) then
      error("Entity mismatch: "..tostring(ent)) end
    local act = DATA.DAMAGE[ent:GetClass()]
    local ty = type(act); if(ty ~= "function") then
      error("Damage mismatch: ".. ty) end
    return act
  end

  function LaserLib.SetDamage(ent, act)
    if(not LaserLib.IsValid(ent)) then
      error("Entity mismatch: "..tostring(ent)) end
    local ty = type(act); if(ty ~= "function") then
      error("Damage mismatch: ".. ty) end
    DATA.DAMAGE[ent:GetClass()] = act
  end

  -- https://wiki.facepunch.com/gmod/Global.DamageInfo
  function mtBeam:TakeDamage(param, dmtype)
    local target = param.target
    if(not LaserLib.IsValid(target)) then return end
    local laser = param.laser
    if(not LaserLib.IsValid(laser)) then return end
    local attacker = param.attacker
    if(not LaserLib.IsValid(attacker)) then return end
    local damage = param.damage
    if(not damage or (damage and damage <= 0)) then return end
    local dmtype = (dmtype and dmtype or param.dmtype)
    local dmg = DATA.DMGI -- Local reference to damage info object
    dmg:SetDamage(damage) -- Modifies the damage amount. Any positive number
    dmg:SetAttacker(attacker) -- Sets the attacker. For example a player or an NPC
    dmg:SetInflictor(laser) --Sets the inflictor. For example a weapon
    dmg:SetDamageType(dmtype) -- Damage type. comes form DMG enumerators
    target:TakeDamageInfo(dmg) -- Pass the damage info object
  end

  -- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
  function mtBeam:GetTorch(param)
    local laser  = param.laser
    if(not LaserLib.IsValid(laser)) then return nil end
    local attacker = param.attacker
    if(not LaserLib.IsValid(attacker)) then return nil end
    local target = param.target
    if(not LaserLib.IsValid(target)) then return nil end
    local dissolve = param.dissolve
    local origin = target:GetPos()
    local torch = ents.Create("env_entity_dissolver")
    if(not LaserLib.IsValid(torch)) then return nil end
    torch.Target = DATA.DISID:format(laser:EntIndex())
    torch:SetKeyValue("dissolvetype", dissolve)
    torch:SetKeyValue("magnitude", 0)
    torch:SetPos(origin)
    torch:SetPhysicsAttacker(attacker)
    torch:Spawn()
    return torch
  end

  function mtBeam:DoDissolve(torch)
    if(not LaserLib.IsValid(torch)) then return end
    torch:Fire("Dissolve", torch.Target, 0)
    torch:Fire("Kill", "", 0.1)
    torch:Remove()
  end

  function mtBeam:DoSound(param)
    local target, noise = param.target, param.noise
    if(not LaserLib.IsValid(target)) then return end
    if(noise and (target:Health() > 0 or target:IsPlayer())) then
      sound.Play(noise, target:GetPos())
      target:EmitSound(Sound(noise))
    end
  end

  function mtBeam:DoBurn(param)
    local target, origin = param.target, param.origin
    if(not LaserLib.IsValid(target)) then return end
    local direct, safety = param.direct, param.safety
    if(not safety) then return end -- Beam safety skipped
    local smu = DATA.HARUNTM[2] -- Safety velocity
    if(smu <= 0) then return end -- General setting
    local idx = target:StartLoopingSound(DATA.BURN)
    local obb = target:LocalToWorld(target:OBBCenter())
    local pbb = LaserLib.ProjectPointRay(obb, origin, direct)
          obb:Sub(pbb); obb:Normalize(); obb:Mul(smu)
          obb.z = 0; target:SetVelocity(obb)
    timer.Simple(0.5, function() target:StopLoopingSound(idx) end)
  end

  function mtBeam:DoDamage(laser)
    local trace = self:GetTarget()
    if(not (trace and trace.Hit)) then return end
    local target, param = trace.Entity, DATA.DMPARAM
    if(not LaserLib.IsValid(target)) then return end
    if(LaserLib.IsUnit(target)) then return end
    local sours = self:GetSource()
    if(not LaserLib.IsValid(sours)) then return end
    -- Localize the calculated parameters
    param.target   = target
    param.laser    = laser
    param.attacker = (self.ply or self.player) or sours:GetCreator()
    param.origin   = trace.HitPos
    param.normal   = trace.HitNormal
    param.direct   = self.VrDirect
    param.damage   = self.NvDamage
    param.dmtype   = DMG_ENERGYBEAM
    param.force    = self.NvForce
    param.dissolve = LaserLib.GetDissolveID(sours:GetDissolveType())
    param.noise    = sours:GetKillSound()
    param.fcenter  = sours:GetForceCenter()
    param.safety   = sours:GetBeamSafety()
    -- Create a reference to what is used locally
    local direct, damage = param.direct, param.damage
    local force , origin = param.force , param.origin
    -- Read damage configuration and physics
    local g_damage, phys = DATA.DAMAGE, target:GetPhysicsObject()
    -- In case the target is not a unit force it or burn it
    if(not LaserLib.IsUnit(target)) then
      if(force and force > 0 and LaserLib.IsValid(phys)) then
        if(fcenter) then -- Force relative to mass center
          phys:ApplyForceCenter(direct * force)
        else -- Keep force separate from damage inflicting
          phys:ApplyForceOffset(direct * force, origin)
        end -- This is the way laser can be used as forcer
      end -- Do not apply force on laser units
      if(target:IsPlayer() and damage > 0) then -- Portal beam safety
        self:DoBurn(param)
      end -- Target is not unit. Check emiter safety
    end
    -- Time to do next damage blast when there is damage
    if(laser.isDamage and damage and damage > 0) then
      local cas = target:GetClass()
      if(cas and g_damage[cas]) then
        local suc, oux = pcall(g_damage[cas], self, param)
        if(not suc) then target:Remove(); error(oux) end -- Remove target
        if(oux) then return end -- Exit main damage routine immediately
      else
        if(target:IsPlayer()) then
          if(target:Health() <= damage) then
            local suc, oux = pcall(g_damage["#ISPLAYER#"], self, param)
            if(not suc) then target:Kill(); error(oux) end -- Remove target
            if(oux) then return end -- Exit main damage routine immediately
          end
        elseif(target:IsNPC()) then
          if(target:Health() <= damage) then
            local suc, oux = pcall(g_damage["#ISNPC#"], self, param)
            if(not suc) then target:Remove(); error(oux) end -- Remove target
            if(oux) then return end -- Exit main damage routine immediately
          end
        elseif(target:IsVehicle()) then
          local driver = target:GetDriver()
          if(LaserLib.IsValid(driver) and driver:IsPlayer()) then
            if(driver:Health() <= damage) then driver:ExitVehicle()
              param.target = driver -- Switch target to the driver on kill
              local suc, oux = pcall(g_damage["#ISPLAYER#"], self, param)
              if(not suc) then driver:Kill(); error(oux) end -- Remove target
              if(oux) then return end -- Exit main damage routine immediately
            end
          end
        end
      end -- When target is not supposed to be killed yet
      self:TakeDamage(param) -- Make it eat one more slap
    end
  end
end

--[[
 * Dedicated beam refract method for specific wavelengths
 * LaserLib.GetRefracted(direct, normal, source, destin)
 * Returns [vdir, bnex, bsam] according to wavelength
]]
function mtBeam:Refract(vDir, vNor, nSrc, nDst)
  local nWav, nSo = self.BmWaveLn, DATA.SODD
  local tTrg, vUp = self.BmTarget, DATA.VDRUP
  local vDir = (vDir or self.VrDirect)
  local vNor = (vNor or (tTrg and tTrg.HitNormal) or vUp)
  local nSrc, nDst = tonumber(nSrc), tonumber(nDst)
  if(nWav > 0 and nWav ~= nSo) then
    nSrc = LaserLib.WaveToIndex(nWav, nSrc)
    nDst = LaserLib.WaveToIndex(nWav, nDst)
  end; return LaserLib.GetRefracted(vDir, vNor, nSrc, nDst)
end

--[[
 * Can this beam be dispersed into components
 * vOrg > Provide beam start for splitter source entities
 * tRef > Refraction sodium line configuration
]]
function mtBeam:IsDisperse(vOrg, tRef)
  if(not self.BmDisper) then return false end
  if(self.BmWaveLn > 0) then return false end
  local tW = LaserLib.GetWaveArray(self:GetColorRGBA(true))
  if(tW) then return false end
  local brn = self.BmBranch -- Index branch table
  -- This beam is already branched. Skip branching
  if(brn.Size > 0) then return false end
  local cnt = (tW.IE - tW.IS + 1); self:Finish()
  local src, ovr = self.BmSource, self.BmNoover
  local org = (vOrg or self.BmTarget.HitPos)
  local sr, sg, sb, sa = self:GetColorRGBA()
  for iW = tW.IS, tW.IE do
    local recw = tW[iW] -- Current component
    local marg = (recw.P / cnt) -- Power margin
    local beam = LaserLib.Beam(org, self.VrDirect)
    local r = (recw.C.r * recw.P)
    local g = (recw.C.g * recw.P)
    local b = (recw.C.b * recw.P)
    local vdir, bnex, bsam = self:Refract(nil, nil, 1, tRef[1])
    if(not beam:IsValid() and SERVER) then
      beam:Clear(); src:Remove(); return false end
    beam:SetSource(self.BmSource, self.BoSource)
    beam:SetWidth(self:GetWidth() * marg)
    beam:SetDamage(self:GetDamage() * marg)
    beam:SetForce(self:GetForce() * marg)
    beam:SetFgDivert(self:GetFgDivert())
    beam:SetFgTexture(self.BmNoover, false)
    beam:SetBounces(self.NvBounce)
    beam:SetWavelength(recw.W)
    beam:SetColorRGBA(r, g, b, sa)
    beam:SetFgTexture(ovr, false)
    brn.Size = brn.Size + 1
    table.insert(brn, beam:Run(brn.Size))
  end; return true
end

--[[
 * Traces a laser beam from the entity provided
 * iIdx > Provide beam start for splitter source entities
 * iStg > Recursion stage used to identify recursion depth
]]
function mtBeam:Run(iIdx, iStg)
  -- References to reflect and refract definitions
  local g_reflect, g_refract = DATA.REFLECT, DATA.REFRACT
  -- Temporary values that are considered local and do not need to be accessed by hit reports
  local trace, g_actors, target = self.BmTarget, DATA.ACTORS, nil -- Configure and target and shared trace reference
  -- Store general definition of air and water mediums for fast usage and indexing
  local mewat, meair, merum = mtBeam.__mewat, mtBeam.__meair, self.TrMedium -- Local reference
  -- Reports dedicated values that are being used by other entities and processes
  self.BmIdenty = math.max(tonumber(iIdx) or 1, 1) -- Beam hit report index. Defaults to one if not provided
  self.BmRecstg = (math.max(tonumber(iStg) or 0, 0) + 1) -- Beam recursion depth for units that use it
  -- Allocate source, destination and memory mediums
  self:SetMedium("S"); self:SetMedium("D"); self:SetMedium("M")
  -- Ignore the tracing entity and register first node
  self:SourceFilter(self.BmSource); self:RegisterNode(self.VrOrigin)
  -- Calculate the output location
  self:SetTraceExit()
  -- Start tracing the beam
  repeat
    self:ApplyGravity() -- When there are black holes apply gravity on the beam
    -- Run the trace using the defined conditional parameters
    trace, target = self:Trace() -- Sample one trace and read contents
    -- Check medium contents to know what to do when beam starts inside map solid
    if(self:IsFirst()) then -- Initial start so the beam separates from the laser
      self.TeFilter = nil -- The trace starts inside solid, switch content medium
      if(trace.StartSolid) then -- The beam starts in solid map environment
        if(not self:SetRefractContent(trace.Contents, trace)) then -- Switch medium via trace content
          self:SetRefractContent(util.PointContents(self.VrOrigin), trace) -- Trace contents not matched. Use origin
        end -- Switch medium via content finished. When not located medium is unchanged
      end -- Resample the trace result and update hit status via contents
    else -- We have water surface defined and we are not refracting
      if(not self:IsAir() and not self.IsRfract) then
        -- Must check the initial trace start and hit point
        local org = self:GetWaterOrigin() -- Estimate origin
        if(org and org <= 0) then -- Beam origin is underwater
          local dir = self:GetWaterDirect() -- Estimate direction
          if(dir and dir > 0) then -- Beam goes partially upwards
            local org = self:GetWaterOrigin(trace.HitPos)
            if(org and org > 0) then -- Ray ends out of water
              self:RefractWaterAir() -- Water to air specifics
              trace, target = self:Trace()
            end -- When the beam is short and ends in the water
          end
        end
      end
    end
    -- Check current target for being a valid specific actor
    -- Stores whenever the trace is valid entity or not and the class
    local suc, cas = self:GetActorID(target)
    -- Actor flag and specific filter are now reset when present
    if(trace.Fraction > 0) then -- Ignore registering zero length traces
      if(suc) then -- Target is valid and it is an actor
        -- Disable drawing is updated for specific actor request
        self:RegisterNode(trace.HitPos, trace.LengthNR)
        -- The trace entity target is special actor case or not
      else -- The trace has hit invalid entity or world
        if(trace.FractionLeftSolid > 0) then
          local mar = trace.LengthLS -- Use the left solid value
          local org = self:GetNudge(mar) -- Calculate nudge origin
          -- Register the node at the location the laser lefts the glass
          self:RegisterNode(org, mar)
        else
          self:RegisterNode(trace.HitPos, trace.LengthLS)
        end
        self.StRfract = trace.StartSolid -- Start in world entity
      end
    else -- Trace distance length is zero so enable refraction
      self.StRfract = true -- Do not alter the beam direction
    end -- Do not put a node when beam does not traverse
    -- When we are still tracing and hit something that is not specific unit
    if(self.IsTrace and trace.Hit) then
      -- Gravity wells do not affect the beam in solids
      self.IsHoleGv = false
      -- Register a hit so reduce bounces count
      if(suc) then
        if(self.IsRfract) then
          local mcons = util.PointContents(trace.HitPos)
          -- Check when bounce position is inside the water
          self:Finish(false) -- Produce next ray. Well the beam is still tracing
          -- Decide whenever to go out of the entity according to the hit location
          if(not self:SetRefractContent(mcons)) then -- Ask source engine for water position origin
            self:SetMediumSours(meair) -- Contents are not located and surface is missing
          end -- Negate the normal so it must point inwards before refraction
          trace.HitNormal:Negate(); self.VrDirect:Negate()
          -- Make sure to pick the correct refract exit medium for current node
          if(self.NvLength > 0) then
            if(not self:IsTraverse(trace.HitPos, nil, trace.HitNormal, target)) then
              -- Refract the hell out of this requested beam with entity destination
              local vdir, bnex = self:Refract(self.VrDirect,
                             trace.HitNormal, merum.D[1][1], merum.S[1][1])
              if(bnex) then -- When the beam gets out of the medium
                self:Divert(trace.HitPos, vdir, true)
                self:UpdateWaterSurface(mcons) -- Update the water surface
                self:SetMediumMemory(merum.D, nil, trace.HitNormal)
              else -- Get the trace ready to check the other side and register the location
                self:SetTraceNext(trace.HitPos, vdir)
              end -- Apply power ratio when requested
              if(self.BrRefrac) then self:SetPowerRatio(merum.D[1][2]) end
            end -- We are already on red while traversing so do not redirect
          else self:Finish() end -- Exit now without redirecting
        else -- Put special cases for specific classes here
          if(cas and g_actors[cas]) then
            self:Finish() -- Assume that beam stops traversing
            local suc, err = pcall(g_actors[cas], self)
            if(not suc) then self:Finish(); target:Remove(); error(err) end
          elseif(LaserLib.IsUnit(target)) then -- Trigger for units without action function
            self:Finish() -- When the entity is unit but does not have actor function
          else -- Otherwise must continue medium change. Reduce loops when hit dedicated units
            local mat = self:GetMaterialID(trace) -- Current extracted material as string
            self:Finish(false) -- Still tracing the beam
            local reflect = GetMaterialEntry(mat, g_reflect)
            if(reflect and not self.StRfract) then -- Just call reflection and get done with it..
              self:Reflect(trace, reflect[1]) -- Call reflection method
            else
              local refract, key = GetMaterialEntry(mat, g_refract)
              if(self.StRfract or (refract and key ~= merum.S[2])) then -- Needs to be refracted
                -- When we have refraction entry and are still tracing the beam
                if(refract) then -- When refraction entry is available do the thing
                  -- Check whenever dispersion is enabled and try to decompose
                  if(not self:IsDisperse(nil, refract)) then
                    -- The beam is monochromatic and should not be branched
                    -- Calculated refraction ray. Reflect when not possible
                    local bnex, bsam, vdir = self:GetBoundaryEntity(refract[1], trace)
                    -- Check refraction medium boundary and perform according actions
                    if(bnex or bsam) then -- We have to change mediums
                      self:SetRefractEntity(trace.HitPos, vdir, target, refract, key)
                    else -- Divert the beam with the reflected ray
                      self:Divert(trace.HitPos, vdir)
                    end
                    -- Apply power ratio when requested
                    if(self.BrRefrac) then self:SetPowerRatio(refract[2]) end
                    -- We cannot be able to refract as the requested beam is missing
                  end
                else self:Finish() end
                -- We are neither reflecting nor refracting and have hit a wall
              else self:Finish() end -- All triggers are processed
            end
          end
        end -- Comes from air then hits and refracts in water or starts in water
      elseif(trace.HitWorld) then
        if(self.IsRfract) then
          if(not trace.AllSolid) then
            -- Important thing is to consider what is the shape of the world entity
            -- We can either memorize the normal vector which will fail for different shapes
            -- We can either set the trace length insanely long will fail windows close to the ground
            -- Another trace is made here to account for these problems above
            -- Well the beam is still tracing
            self:Finish(false) -- Produce next ray
            -- Make sure that outer trace will always hit
            local org, nrm = self:GetNudge(trace.LengthLS + DATA.NUGE)
            self.VrDirect:Negate()
            -- Margin multiplier for trace back to find correct surface normal
            -- This is the only way to get the proper surface normal vector
            local tr = self:GetTrace(org, self.VrDirect, 2 * DATA.NUGE, DATA.FILTW, MASK_ALL)
            -- Store hit position and normal in beam temporary
            local nrm = Vector(tr.HitNormal); org:Set(tr.HitPos)
            -- Reverse direction of the normal to point inside transparent
            nrm:Negate(); self.VrDirect:Negate()
            -- Do the refraction according to medium boundary
            if(self.NvLength > 0) then
              if(not self:IsTraverse(org, nil, nrm, target)) then
                local vdir, bnex = self:Refract(self.VrDirect,
                                     nrm, merum.D[1][1], meair[1][1])
                if(bnex) then -- When the beam gets out of the medium
                  self:Divert(org, vdir, true)
                  self:SetMediumSours(meair)
                  -- Memorizing will help when beam traverses from world to no-collided entity
                  self:SetMediumMemory(merum.D, nil, nrm)
                else -- Get the trace ready to check the other side and register the location
                  self:Divert(org, vdir)
                end
              end -- We are already on red while traversing so do not redirect
            else self:Finish() end -- Exit now without redirecting
          else -- The beam ends inside a solid transparent medium
            local org = self:GetNudge(self.NvLength)
            self:RegisterNode(org, self.NvLength)
            self:Finish()
          end -- Apply power ratio when requested
          if(self.BrRefrac) then self:SetPowerRatio(merum.D[1][2]) end
        else
          if(cas and g_actors[cas]) then
            local suc, err = pcall(g_actors[cas], self)
            if(not suc) then self:Finish(); target:Remove(); error(err) end
          elseif(LaserLib.IsUnit(target)) then -- Trigger for units without action function
            self:Finish() -- When the entity is unit but does not have actor function
          else -- Otherwise bust continue medium change. Reduce loops when hit dedicated units
            local mat = self:GetMaterialID(trace) -- Current extracted material as string
            self:Finish(false) -- Still tracing the beam
            local reflect = GetMaterialEntry(mat, g_reflect)
            if(reflect and not self.StRfract) then
              self:Reflect(trace, reflect[1]) -- Call reflection method
            else
              local refract, key = GetMaterialEntry(mat, g_refract)
              if(self.StRfract or (refract and key ~= merum.S[2])) then -- Needs to be refracted
                -- When we have refraction entry and are still tracing the beam
                if(refract) then -- When refraction entry is available do the thing
                  -- Check whenever dispersion is enabled and try to decompose
                  if(not self:IsDisperse(nil, refract)) then
                    -- The beam is monochromatic and should not be branched
                    -- Define water surface as of air-water beam interaction
                    self:SetSurfaceWorld(refract.Key or key, trace.Contents, trace)
                    -- Calculated refraction ray. Reflect when not possible
                    if(self.StRfract) then -- Laser is within the map water submerged
                      self.StRfract = false -- Lower the flag so no performance hit is present
                      self:Divert(trace.HitPos) -- Keep the same direction and initial origin
                    else -- Beam comes from the air and hits the water. Store water surface and refract
                      -- Get the trace ready to check the other side and point and register the location
                      local vdir, bnex = self:Refract(self.VrDirect,
                                           trace.HitNormal, merum.S[1][1], refract[1])
                      self:Divert(trace.HitPos, vdir)
                    end
                    -- Need to make the traversed destination the new source
                    self:SetRefractWorld(trace, refract, key)
                    -- Apply power ratio when requested
                    if(self.BrRefrac) then self:SetPowerRatio(refract[2]) end
                  end
                  -- We cannot be able to refract as the requested entry is missing
                else self:Finish() end
                -- All triggers when reflecting and refracting are processed
              else self:Finish() end -- Not traversing and have hit a wall
            end
          end -- We are neither hit a valid entity nor a map water
        end
      else self:Finish() end; self:Bounce() -- Refresh medium pass through information
    elseif(self.IsTrace and self.IsHoleGv) then
      if(self.NvLength > 0) then
        self:Bounce()
        self:Divert(trace.HitPos)
        -- If we were about to enter a black hole reset the step for next iteration
        if(self.NvHoleLn ~= self.BmHoleLn) then self.NvHoleLn = self.BmHoleLn end
      else self:Finish() end
    else
      self:Finish()
    end -- Trace did not hit anything to be bounced off from
  until(self:IsFinish())
  -- Clear the water trigger refraction flag
  self:ClearWater()
  -- The beam ends inside transparent entity
  if(not self:IsNode()) then self.BmTarget = nil; return self end
  -- Update the sources and trigger the hit reports
  self:UpdateSource()
  -- Return what did the beam hit and stuff
  return self
end

function LaserLib.NumSlider(panel, convar, nmin, nmax, ndef, ndig)
  if(SERVER) then return end
  local sTool = DATA.TOOL -- Read the tool name directly
  local cV = GetConVar(sTool.."_"..convar)
  if(not cV) then error("Convar missing: "..convar) end
  local sT = ("tool."..sTool.."."..convar)
  local sN, sH = cV:GetName(), cV:GetHelpText()
  local sB, sC = language.GetPhrase(sT), language.GetPhrase(sT.."_con")
  local pItem = panel:NumSlider(sC, sN, nmin or cV:GetMin(), nmax or cV:GetMax(), ndig or 5)
        pItem:SetTooltip((sB == sT) and sH or sB); pItem:SetDefaultValue(ndef or cV:GetDefault())
  return pItem -- Return created panel
end

function LaserLib.CheckBox(panel, convar)
  if(SERVER) then return end
  local sTool = DATA.TOOL -- Read the tool name directly
  local cV = GetConVar(sTool.."_"..convar)
  if(not cV) then error("Convar missing: "..convar) end
  local sT = ("tool."..sTool.."."..convar)
  local sN, sH = cV:GetName(), cV:GetHelpText()
  local sB = language.GetPhrase(sT)
  local sA = language.GetPhrase(sT.."_con")
  local pItem = panel:CheckBox(sA, sN)
        pItem:SetTooltip((sB == sT) and sH or sB)
  function pItem.Label:DoRightClick()
    SetClipboardText(self:GetValue())
  end
  return pItem -- Return created panel
end

function LaserLib.ComboBoxString(panel, convar, nameset)
  local sTool = DATA.TOOL -- Read the tool name directly
  local sVar  = GetConVar(sTool.."_"..convar):GetString()
  local sBase = language.GetPhrase("tool."..sTool.."."..convar.."_con")
  local sHint = language.GetPhrase("tool."..sTool.."."..convar)
  local pItem, pName = panel:ComboBox(sBase, sTool.."_"..convar)
  pItem:SetTooltip(sHint); pName:SetTooltip(sHint)
  pItem:SetSortItems(true); pItem:Dock(TOP); pItem:SetTall(22)
  for key, row in pairs(list.GetForEdit(nameset)) do
    local bS = (sVar == row.name)
    local sN = language.GetPhrase(key)
    local sI = LaserLib.GetIcon(row.icon)
    pItem:AddChoice(sN, row.name, bS, sI)
  end
  function pName:DoRightClick()
    SetClipboardText(self:GetValue())
  end
  function pItem:DoRightClick()
    local vN = pName:GetValue()
    local iD = self:GetSelectedID()
    local vT = self:GetOptionText(iD)
    local vD = self:GetOptionData(iD)
    SetClipboardText("["..vN..iD.."]:["..vT.."]["..vD.."]")
  end
  return pItem, pName
end

-- https://github.com/Facepunch/garrysmod/tree/master/garrysmod/resource/localization/en
function LaserLib.SetupComboBools()
  if(SERVER) then return end

  table.Empty(list.GetForEdit("LaserEmitterComboBools"))
  list.Set("LaserEmitterComboBools", "<Empty>", {name = 0, icon = "stop" })
  list.Set("LaserEmitterComboBools",  "False" , {name = 1, icon = "cross"})
  list.Set("LaserEmitterComboBools",  "True"  , {name = 2, icon = "tick" })
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
  language.Add("laser.effects.bluelaser1"    , "Blue Laser Effect" )
  language.Add("laser.effects.redshader"     , "Red Shader"        )
  language.Add("laser.effects.whiteshader"   , "White Shader"      )
  language.Add("laser.effects.shield"        , "Combine Shield"    )
  language.Add("laser.effects.wframe"        , "Wireframe"         )
  language.Add("laser.effects.predator"      , "Predator"          )

  table.Empty(list.GetForEdit("LaserEmitterMaterials"))
  list.Set("LaserEmitterMaterials", "#laser.cable.cable1"          , {name = "cable/cable"                        , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.cable.cable2"          , {name = "cable/cable2"                       , icon = "palette", cors = {25, 25, 25}})
  list.Set("LaserEmitterMaterials", "#laser.splodearc.sheet"       , {name = "models/effects/splodearc_sheet"     , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.warp.sheet"            , {name = "models/props_lab/warp_sheet"        , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.cable.crystal_beam1"   , {name = "cable/crystal_beam1"                , icon = "palette", cors = {140, 110, 55}})
  list.Set("LaserEmitterMaterials", "#laser.ropematerial.redlaser" , {name = "cable/redlaser"                     , icon = "palette", cors = {140, 110, 55}})
  list.Set("LaserEmitterMaterials", "#laser.ropematerial.blue_elec", {name = "cable/blue_elec"                    , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.emptool"       , {name = "models/alyx/emptool_glow"           , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.redlaser1"     , {name = "effects/redlaser1"                  , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.bluelaser1"    , {name = "effects/bluelaser1"                 , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.redshader"     , {name = "models/shadertest/shader4"          , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.whiteshader"   , {name = "models/shadertest/shader3"          , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.shield"        , {name = "models/props_combine/com_shield001a", icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.wframe"        , {name = "models/wireframe"                   , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#laser.effects.predator"      , {name = "models/shadertest/predator"         , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#ropematerial.xbeam"          , {name = "cable/xbeam"                        , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#ropematerial.physbeam"       , {name = "cable/physbeam"                     , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#ropematerial.hydra"          , {name = "cable/hydra"                        , icon = "palette", cors = false})
  list.Set("LaserEmitterMaterials", "#trail.plasma"                , {name = "trails/plasma"                      , icon = "palette", cors = {225, 225, 225}})
  list.Set("LaserEmitterMaterials", "#trail.electric"              , {name = "trails/electric"                    , icon = "palette", cors = {30, 50, 225}})
  list.Set("LaserEmitterMaterials", "#trail.smoke"                 , {name = "trails/smoke"                       , icon = "palette", cors = {100, 100, 100}})
  list.Set("LaserEmitterMaterials", "#trail.laser"                 , {name = "trails/laser"                       , icon = "palette", cors = {225, 225, 225}})
  list.Set("LaserEmitterMaterials", "#trail.love"                  , {name = "trails/love"                        , icon = "palette", cors = {130, 40, 100}})
  list.Set("LaserEmitterMaterials", "#trail.lol"                   , {name = "trails/lol"                         , icon = "palette", cors = {225, 225, 225}})
  list.Set("LaserEmitterMaterials", "#trail.beam_generic01"        , {name = "effects/beam_generic01"             , icon = "palette", cors = {225, 225, 225}})
  list.Set("LaserEmitterMaterials", "#trail.beam001_blu"           , {name = "effects/beam001_blu"                , icon = "palette", cors = {10, 10, 50}})
  list.Set("LaserEmitterMaterials", "#trail.beam001_red"           , {name = "effects/beam001_red"                , icon = "palette", cors = {50, 10, 10}})
  list.Set("LaserEmitterMaterials", "#trail.beam001_white"         , {name = "effects/beam001_white"              , icon = "palette", cors = {225, 225, 225}})
  list.Set("LaserEmitterMaterials", "#trail.repair_claw_trail_blue", {name = "effects/repair_claw_trail_blue"     , icon = "palette", cors = {50, 50, 190}})
  list.Set("LaserEmitterMaterials", "#trail.repair_claw_trail_red" , {name = "effects/repair_claw_trail_red"      , icon = "palette", cors = {210, 130, 50}})
  list.Set("LaserEmitterMaterials", "#trail.australiumtrail_red"   , {name = "effects/australiumtrail_red"        , icon = "palette", cors = {255, 33, 0}})
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
    table.insert(moar, {"models/props_bts/projector.mdl",0,"1,-10,5","0,-1,0"})
    table.insert(moar, {"models/props/laser_emitter.mdl",0,"29,0,-14","1,0,0"})
    table.insert(moar, {"models/props/laser_emitter_center.mdl",0,"29,0,0","1,0,0"})
    table.insert(moar, {"models/props_bts/glados_ball_reference.mdl",0,"0,15,0","0,1,0"})
    table.insert(moar, {"models/props/pc_case02/pc_case02.mdl",0,"-0.2,2.4,-9.2","1,0,0"})
  end

  if(IsMounted("portal2")) then -- Portal 2
    table.insert(moar, {"models/props/reflection_cube.mdl"})
    table.insert(moar, {"models/br_debris/deb_s8_cube.mdl"})
    table.insert(moar, {"models/props/laser_catcher_center.mdl",0,"23.7,0,0","1,0,0"})
    table.insert(moar, {"models/npcs/monsters/monster_a_cube.mdl",0,"13,0,18","0,0,1"})
    table.insert(moar, {"models/npcs/turret/turret.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(moar, {"models/npcs/turret/turret_skeleton.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(moar, {"models/traincar_interior/traincar_cube_bl.mdl",0,"0,16,12.45","0,1,0"})
    table.insert(moar, {"models/props/security_camera_prop_reference.mdl",0,"38.6,-0.34,-13.8","1,0,0"})
    table.insert(moar, {"models/props_mall/cage_light_fixture.mdl",0,"0,5.17,-8.33","0,0,-1"})
  end

  if(IsMounted("portal") or IsMounted("portal2")) then -- Some models repeat
    table.insert(moar, {"models/props/turret_01.mdl",0,"12,0,36.75","1,0,0"})
    table.insert(moar, {"models/weapons/w_portalgun.mdl",0,"-20,-0.7,-0.3","-1,0,0"})
    table.insert(moar, {"models/props/radio_reference.mdl",0,"0,3.65,14.24","0,0,1"})
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

  local pref = (DATA.TOOL.."_")
  for idx = 1, #moar do
    local rec = moar[idx]
    local mod =  tostring(rec[1]  or "")
    local ang = (tonumber(rec[2]) or 0 )
    local org =  tostring(rec[3]  or "")
    local dir =  tostring(rec[4]  or "")
    table.Empty(rec)
    rec[pref.."model" ] = mod
    rec[pref.."angle" ] = ang
    rec[pref.."origin"] = org
    rec[pref.."direct"] = dir
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

--[[
 * Creates panel control options function
 * sDir > Control panel tab name
 * sSub > Control panel type
 * fFoo > Control panel handler function
 * Usage: LaserLib.Controls("Utilities", "User", setupUserSettings)
]]
function LaserLib.Controls(sDir, sSub, fFoo)
  if(SERVER) then return end
  local tBar, fCap = DATA.CAPB, DATA.CAPSF -- Third argument controls the behavior
  local sDir, sSub = tostring(sDir):lower(), tostring(sSub):lower()
  local bS, lDir = pcall(fCap, sDir); if(not bS) then return end
  local bS, lSub = pcall(fCap, sSub); if(not bS) then return end
  local sKey, sHoo = (DATA.TOOL.."%s_%s"):format(sDir, sSub), "PopulateToolMenu"
  if(fFoo) then
    if(not tBar[sDir]) then tBar[sDir] = {} end; tBar[sDir][sSub] = fFoo
    hook.Remove(sHoo, sKey); hook.Add(sHoo, sKey, function()
      spawnmenu.AddToolMenuOption(lDir, lSub, sKey,
        language.GetPhrase("tool."..DATA.TOOL..".name"), "", "", fFoo) end)
  else
    if(not tBar[sDir]) then return end -- Control class not present
    return tBar[sDir][sSub] -- Return what is stored in
  end
end

if(CLIENT) then
  -- https://wiki.facepunch.com/gmod/3D_Rendering_Hooks
  hook.Add("PostDrawHUD", DATA.TOOL.."_grab_draw", -- Physgun draw beam assist
    function() -- Handles drawing the assist when user holds laser unit
      local ply = LocalPlayer(); if(not LaserLib.IsValid(ply)) then return end
      local ray = ply:GetInfoNum(DATA.TOOL.."_rayassist", 0); if(ray <= 0) then return end
      local wgn = ply:GetActiveWeapon(); if(not LaserLib.IsValid(wgn)) then return end
      if(wgn:GetClass() ~= "weapon_physgun") then return end -- Not holding physgun
      local tr = ply:GetEyeTrace(); if(not (tr and tr.Hit)) then return end
      local tre = tr.Entity; if(not LaserLib.IsValid(tre)) then return end
      if(tre:GetClass():find("gmod_laser", 1, true)) then -- For all laser units
        local vor, vdr = LaserLib.GetTransformUnit(tre) -- Read unit transform
        vor, vdr = (vor or tr.HitPos), (vdr or tr.HitNormal) -- Fail-safe rays
        LaserLib.DrawAssist(vor, vdr, ray, tre, ply) -- Convert to world-space
      end
  end)
end

CheckMaterials(DATA.REFLECT, 7)
CheckMaterials(DATA.REFRACT, 6)

ConfigureHookRegistry(DATA.BLHOLE, "sp_black_hole")

ConfigureChangeList("HAWASTP", DATA.WDHUESTP, "GetFloat",
                               DATA.WDRGBMAR, "GetFloat")

ConfigureChangeList("HADFSPL", DATA.NSPLITER, "GetInt",
                               DATA.XSPLITER, "GetFloat",
                               DATA.YSPLITER, "GetFloat",
                               DATA.ZSPLITER, "GetFloat")

ConfigureChangeList("HADELTA", DATA.DAMAGEDT, "GetFloat",
                               DATA.EFFECTDT, "GetFloat",
                               DATA.TIMEASYN, "GetFloat")

ConfigureChangeList("HARUNTM", DATA.MBOUNCES, "GetInt",
                               DATA.VESFBEAM, "GetFloat",
                               DATA.BLHOLESG, "GetFloat")
