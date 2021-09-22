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
DATA.MCRYSTAL = CreateConVar("laseremitter_mcrystal", "models/props_c17/pottery02a.mdl", DATA.FGSRVCN, "Change to adjust the crystal model")
DATA.MREFLECT = CreateConVar("laseremitter_mreflect", "models/madjawa/laser_reflector.mdl", DATA.FGSRVCN, "Change to adjust the reflector model")
DATA.MSPLITER = CreateConVar("laseremitter_mspliter", "models/props_c17/pottery04a.mdl", DATA.FGSRVCN, "Change to adjust the splitter model")
DATA.MDIVIDER = CreateConVar("laseremitter_mdivider", "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Change to adjust the divider model")
DATA.MSENSOR  = CreateConVar("laseremitter_msensor" , "models/props_c17/pottery01a.mdl", DATA.FGSRVCN, "Change to adjust the sensor model")
DATA.MDIMMER  = CreateConVar("laseremitter_mdimmer" , "models/props_c17/FurnitureShelf001b.mdl", DATA.FGSRVCN, "Change to adjust the dimmer model")
DATA.NSPLITER = CreateConVar("laseremitter_nspliter", 2, DATA.FGSRVCN, "Change to adjust the default splitter outputs count", 0, 16)
DATA.XSPLITER = CreateConVar("laseremitter_xspliter", 1, DATA.FGSRVCN, "Change to adjust the default splitter X direction", 0, 1)
DATA.YSPLITER = CreateConVar("laseremitter_yspliter", 1, DATA.FGSRVCN, "Change to adjust the default splitter Y direction", 0, 1)
DATA.EFFECTTM = CreateConVar("laseremitter_effecttm", 0.1, DATA.FGINDCN, "Change to adjust the time between effect drawing", 0, 5)
DATA.ENSOUNDS = CreateConVar("laseremitter_ensounds", 1, DATA.FGSRVCN, "Trigger this to enable or disable redirector sounds")
DATA.LNDIRACT = CreateConVar("laseremitter_lndiract", 20, DATA.FGINDCN, "How long will the direction of output beams be rendered", 0, 50)
DATA.DAMAGEDT = CreateConVar("laseremitter_damagedt", 0.1, DATA.FGSRVCN, "The time frame to pass between the beam damage cycles", 0, 10)

DATA.GRAT = 1.61803398875   -- Golden ratio used for panels
DATA.TOOL = "laseremitter"  -- Tool name for internal use
DATA.ICON = "icon16/%s.png" -- Format to convert icons
DATA.NOAV = "N/A"           -- Not available as string
DATA.TOLD = SysTime()       -- Reduce debug function calls
DATA.RNDB = 3               -- Decimals beam round for visibility check
DATA.KWID = 5               -- Width coefficient used to calculate power
DATA.MINW = 0.05            -- Mininum width to be considered visible
DATA.DOTM = 0.01            -- Colinearity and dot prodic margin check
DATA.POWL = 0.001           -- Lowest bounds of laser power
DATA.NMAR = 0.0001          -- Margin amount to push vectors with
DATA.ERAD = 2               -- Entity radius coefficient for traces
DATA.NTIF = {}              -- User notification configuration type
DATA.AMAX = {-360, 360}
DATA.NTIF[1] = "GAMEMODE:AddNotify(\"%s\", NOTIFY_%s, 6)"
DATA.NTIF[2] = "surface.PlaySound(\"ambient/water/drip%d.wav\")"

-- Store zero angle and vector
DATA.AZERO = Angle()
DATA.VZERO = Vector()
DATA.VDRUP = Vector(0,0,1)

-- The default key in a collection point to take when not found
DATA.KEYD = "#"
DATA.KEYA = "*"

DATA.CLS = {
  -- Class hashes enabled for creating hit reports via `SetHitReport`
  -- [1] Can the entity be considered and actual beam source
  -- [2] Does the entity have the inherited editable laser properties
  -- [3] Should the entity be checked for infinite loop sources
  ["gmod_laser"         ] = {true , true , false},
  ["gmod_laser_crystal" ] = {true , true , true },
  ["gmod_laser_splitter"] = {true , true , true },
  ["gmod_laser_divider" ] = {true , false, false},
  ["gmod_laser_sensor"  ] = {false, true , false},
  ["gmod_laser_dimmer"  ] = {true , false, false},
  -- [1] Actual class passed to ents.Create
  -- [2] Extension for folder name indices
  -- [3] Extension for variable name indices
  {"gmod_laser"         , nil        , nil      }, -- Laser entity calss
  {"gmod_laser_crystal" , "crystal"  , "CRYSTAL"}, -- Laser crystal class
  {"prop_physics"       , "reflector", "REFLECT"}, -- Laser reflectors class
  {"gmod_laser_splitter", "splitter" , "SPLITER"}, -- Laser beam splitter
  {"gmod_laser_divider" , "divider"  , "DIVIDER"}, -- Laser beam divider
  {"gmod_laser_sensor"  , "sensor"   , "SENSOR" }, -- Laser beam sensor
  {"gmod_laser_dimmer"  , "dimmer"   , "DIMMER" }  -- Laser beam divider
}

DATA.MOD = { -- Model used by the entities menu
  "", -- Laser model is changed via laser tool. Variable is not needed.
  DATA.MCRYSTAL:GetString(), -- Portal cube: models/props/reflection_cube.mdl
  DATA.MREFLECT:GetString(),
  DATA.MSPLITER:GetString(),
  DATA.MDIVIDER:GetString(),
  DATA.MSENSOR:GetString() , -- Portal catcher: models/props/laser_catcher_center.mdl
  DATA.MDIMMER:GetString()
}

DATA.MAT = {
  "", -- Laser material is changed with the model
  "models/dog/eyeglass"    ,
  "debug/env_cubemap_model",
  "models/dog/eyeglass"    ,
  "models/dog/eyeglass"    ,
  "models/props_combine/citadel_cable",
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
  ["WHITE"]   = Color(255, 255, 255, 255)
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
  [3] = "water", -- Glass enumerator index
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
  ["models/props_combine/com_shield001a"]       = {1.573, 0.653},
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
  output         = nil
}

-- Callbacks for console variables
for idx = 2, #DATA.CLS do
  local name = DATA.CLS[idx][3]
  local varo = DATA["M"..name]
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

function LaserLib.Trace(origin, direct, length, filter, mask, colgrp, iworld, result)
  if(StarGate ~= nil) then
    DATA.TRACE.start:Set(origin)
    DATA.TRACE.endpos:Set(direct)
    DATA.TRACE.endpos:Normalize()
    DATA.TRACE.endpos:Mul(length)
    return StarGate.Trace:New(DATA.TRACE.start, DATA.TRACE.endpos, filter);
  else
    DATA.TRACE.start:Set(origin)
    DATA.TRACE.endpos:Set(direct)
    DATA.TRACE.endpos:Normalize()
    DATA.TRACE.endpos:Mul(length)
    DATA.TRACE.endpos:Add(origin)
    DATA.TRACE.filter = filter
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
      util.TraceLine(DATA.TRACE)
      DATA.TRACE.output = nil
      return result
    else
      DATA.TRACE.output = nil
      return util.TraceLine(DATA.TRACE)
    end
  end
end

-- Validates entity or physics object
function LaserLib.IsValid(arg)
  if(arg == nil) then return false end
  if(arg == NULL) then return false end
  return arg:IsValid()
end

-- Used for kill crediting
function LaserLib.SetPlayer(ent, user)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsValid(user)) then return end
  ent.ply, ent.player = user, user
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
function LaserLib.DrawPoint(pos)
  if(not CLIENT) then return end
  local crw = LaserLib.GetColor("YELLOW")
  render.SetColorMaterial()
  render.DrawSphere(pos, 1, 25, 25, crw)
end

function LaserLib.GetReportID(key)
  local out = (tonumber(key) or 1)
        out = math.max(out, 1)
  return math.floor(out)
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

function LaserLib.IsUnit(ent, idx)
  if(not LaserLib.IsValid(ent)) then return false end
  local set = DATA.CLS[ent:GetClass()]
  if(not set) then return false end
  if(not idx) then return true end
  return set[idx]
end

function LaserLib.GetZeroTransform()
  return LaserLib.GetZeroVector(),
         LaserLib.GetZeroAngle()
end

function LaserLib.VecNegate(vec)
  vec.x = -vec.x
  vec.y = -vec.y
  vec.z = -vec.z
  return vec
end

function LaserLib.GetClass(iK, iC)
  local nK = math.floor(tonumber(iK) or 0)
  local tC = DATA.CLS[nK] -- Pick elemrnt
  if(not tC) then return nil end -- No info
  local nC = math.floor(tonumber(iC) or 0)
  return tC[nC] -- Return whatever found
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
 * Returns the yaw angle for the spawn function
 * ply > Player to calc the angle for
   [1] > The calculated yaw result angle
]]
function LaserLib.GetAngleSF(ply)
  local yaw = (ply:GetAimVector():Angle().y + 180) % 360
  return Angle(0, yaw, 0)
end

--[[
 * Reflects a beam from a surface with material override
 * incident > The incident direction vector ( normalized )
 * normal   > Surface normal vector trace.HitNormal ( normalized )
 * Return the refracted ray and beam status
  [1] > The refracted ray direction vector
]]
function LaserLib.GetReflected(incident, normal)
  local ref = normal:GetNormalized()
  local inc = incident:GetNormalized()
        ref:Mul(-2 * ref:Dot(inc))
        ref:Add(inc)
  return ref
end

--[[
 * Refracts a beam across two mediums by returning the refracted vector
 * incident > The incident direction vector ( normalized )
 * normal   > Surface normal vector trace.HitNormal ( normalized )
 * source   > Refraction index of the source medium
 * destin   > Refraction index of the destination medium
 * Return the refracted ray and beam status
  [1] > The refracted ray direction vector
  [2] > Will the beam go out of the medium
]]
function LaserLib.GetRefracted(incident, normal, source, destin)
  local inc = incident:GetNormalized()
  local nrm = Vector(normal); nrm:Normalize()
  local vcr = inc:Cross(LaserLib.VecNegate(nrm))
  local ang, sii, deg = nrm:AngleEx(vcr), vcr:Length(), 0
  local sio = math.asin(sii / (destin / source))
  if(sio ~= sio) then -- Argument sine is undefined so reflect (NaN)
    return LaserLib.GetReflected(incident, normal), false
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
 * width > The value to chack beam visiblility
]]
function LaserLib.IsPower(width, damage)
  local margn = DATA.KWID * DATA.MINW
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
  duplicator.StoreEntityModifier(ent, "material", data)
end

--[[
 * https://wiki.facepunch.com/gmod/Enums/MAT
 * https://wiki.facepunch.com/gmod/Entity:GetMaterialType
 * Retrieves material override for an entity or use the default
 * ent > Entity to read data for
 * org > Toggle original material selecton when not available
 * trace > Trace data to take the material for
 * mator > Toggle material original selecton when not available
 * Returns: material
]]
local function GetMaterialID(trace, mator)
  if(not trace) then return nil end
  if(not trace.Hit) then return nil end
  if(trace.HitWorld) then
    local mat = trace.HitTexture
    if(mat:sub(1,1) == "*" and mat:sub(-1,-1) == "*") then
      -- **studio**, **displacement**, ** empty **
      mat = DATA.MATYPE[trace.MatType]
    end
    return mat
  else
    local ent = trace.Entity
    if(not LaserLib.IsValid(ent)) then return nil end
    local mat = ent:GetMaterial()
    -- No override is available use original
    if(mat == "" and mator) then -- Enabled
      mat = ent:GetMaterials()[1] -- Just grab the first
      -- Gmod can not simply decide which material is hit
    end -- Read the dominating material
    if(SERVER and mat == "") then
      mat = DATA.MATYPE[ent:GetMaterialType()]
    end -- Physobj has a single surfacetype related to model
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
 * according tho the base entity and direction provided
 * base   > Base entity to calculate the vector for
 * direct > Local direction vector according to `base`
 * Returns the local entity origin offcet vector
 * obcen  > The local entity origin vector
]]
function LaserLib.GetBeamOrigin(base, direct)
  if(not LaserLib.IsValid(base)) then return Vector(DATA.VZERO) end
  local vbeam, obcen = Vector(direct), base:OBBCenter()
  local obdir = base:OBBMaxs(); obdir:Sub(base:OBBMins())
  local kmulv = math.abs(obdir:Dot(vbeam))
        vbeam:Mul(kmulv / 2); obcen:Add(vbeam)
  return obcen
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
  local org = LaserLib.GetBeamOrigin(base, dir)
  local obb = base:OBBCenter()
        org:Sub(obb)
        LaserLib.VecNegate(org)
        org:Add(obb)
  local pos = base:LocalToWorld(org)
        org:Set(base:WorldToLocal(pos))
        pos:Set(norm)
        pos:Mul(math.abs(org:Dot(dir)))
        pos:Add(hitp)
  base:SetPos(pos)
  base:SetAngles(ang)
end

if(SERVER) then

  AddCSLuaFile("autorun/laserlib.lua")

  -- https://developer.valvesoftware.com/wiki/Env_entity_dissolver
  function LaserLib.SpawnDissolver(base, position, attacker, disstype)
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

  function LaserLib.DoDamage(target   , hitPos     , normal  , beamDir     ,
                             damage   , pushForce  , attacker, dissolveType,
                             killSound, forceCenter, laserEnt)
    local dmgtm = DATA.DAMAGEDT:GetFloat()
    laserEnt.nextDamage = laserEnt.nextDamage or CurTime()

    local phys = target:GetPhysicsObject()
    if(pushForce and LaserLib.IsValid(phys)) then
      if(forceCenter) then
        phys:ApplyForceCenter(beamDir * pushForce)
      else
        phys:ApplyForceOffset(beamDir * pushForce, hitPos)
      end
    end

    if(CurTime() >= laserEnt.nextDamage) then
      if(target:IsVehicle()) then
        local driver = target:GetDriver()
        -- Take damage doesn't work on player inside a vehicle.
        if(LaserLib.IsValid(driver)) then
          target = driver; target:Kill()
        end -- We must kill the driver!
      end

      if(target:GetClass() == "shield") then
        local damage = math.Clamp(damage / 2500 * 3, 0, 4)
        target:Hit(laserEnt, hitPos, damage, -1 * normal)
        laserEnt.nextDamage = CurTime() + dmgtm
        return -- We stop here because we hit a shield!
      end

      if(target:Health() <= damage) then
        if(target:IsNPC() or target:IsPlayer()) then
          local odissolve = LaserLib.SpawnDissolver(laserEnt, target:GetPos(), attacker, dissolveType)

          if(target:IsPlayer()) then
            target:TakeDamage(damage, attacker, laserEnt)

            local tardoll = target:GetRagdollEntity()
            -- We need to kill the player first to get his ragdoll.
            if(not LaserLib.IsValid(tardoll)) then return end
            -- Thanks to Nevec for the player ragdoll idea, allowing us to dissolve him the cleanest way.
            tardoll:SetName(odissolve.Target)
          else
            target:SetName(odissolve.Target)

            local tarwep = target:GetActiveWeapon()
            if(LaserLib.IsValid(tarwep)) then
              tarwep:SetName(odissolve.Target)
            end
          end

          odissolve:Fire("Dissolve", odissolve.Target, 0)
          odissolve:Fire("Kill", "", 0.1)
        end

        if(killSound ~= nil and (target:Health() > 0 or target:IsPlayer())) then
          sound.Play(killSound, target:GetPos())
          target:EmitSound(Sound(killSound))
        end
      else
        laserEnt.nextDamage = CurTime() + dmgtm
      end

      target:TakeDamage(damage, attacker, laserEnt)
    end
  end

  function LaserLib.New(user       , pos         , ang         , model      ,
                        angleOffset, key         , width       , length     ,
                        damage     , material    , dissolveType, startSound ,
                        stopSound  , killSound   , toggle      , startOn    ,
                        pushForce  , endingEffect, reflectRate , refractRate,
                        forceCenter, frozen      , enOnverMater)

    local unit = LaserLib.GetTool()
    if(not (LaserLib.IsValid(user) and user:IsPlayer())) then return nil end
    if(not user:CheckLimit(unit.."s")) then return nil end

    local laser = ents.Create(LaserLib.GetClass(1, 1))
    if(not (LaserLib.IsValid(laser))) then return nil end

    laser:SetPos(pos)
    laser:SetAngles(ang)
    laser:SetModel(Model(model))
    laser:SetAngleOffset(angleOffset)
    laser:Spawn()
    laser:SetCreator(user)
    laser:Setup(width       , length     , damage     , material    ,
                dissolveType, startSound , stopSound  , killSound   ,
                toggle      , startOn    , pushForce  , endingEffect,
                reflectRate , refractRate, forceCenter, enOnverMater, false)

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
      angleOffset = angleOffset,
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
  data.NvWidth  = LaserLib.GetWidth(rate * data.NvWidth)
  data.NvDamage = rate * data.NvDamage
  data.NvForce  = rate * data.NvForce
  -- Update the parameters used for drawing the beam trace
  local info = data.TvPoints[data.TvPoints.Size]
  info[2], info[3], info[4] = data.NvWidth, data.NvDamage, data.NvForce
  -- Check out power rankings so the trace absorbed everything
  local power = LaserLib.GetPower(data.NvWidth, data.NvDamage)
  if(power < DATA.POWL) then data.IsTrace = false end -- Entity absorbed the remaining light
end

--[[
 * Beam traverses from medium [1] to medium [2]
 * data   > The structure to update the nodes for
 * origin > The node position to be registered
 * bulen  > Update the length according to the new node
]]
function LaserLib.RegisterNode(data, origin, bulen, bdraw)
  local bdraw = (bdraw or bdraw == nil) and true or false
  local info = data.TvPoints -- Local reference to stack
  local node, width = Vector(origin), data.NvWidth
  local damage, force = data.NvDamage , data.NvForce
  if(bulen) then -- Substract the path trough the medium
    local prev = info[info.Size][1]
    data.NvLength = data.NvLength - (node - prev):Length()
  end -- Register the new node to the stack
  info.Size = info.Size + 1
  info[info.Size] = {node, width, damage, force, bdraw}
end

--[[
 * Traces a laser beam from the entity provided
 * entity > Entity origin to the beam ( laser or crystal )
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
  local data, trace = {}
  -- Configure data structure
  data.TrMaters = ""
  data.NvMask   = MASK_ALL -- Trace mask. When not provided negative one is used
  data.NvCGroup = COLLISION_GROUP_NONE -- Collision group. Missing then COLLISION_GROUP_NONE
  data.IsTrace  = false -- Library is still tracing the beam
  data.NvIWorld = false -- Ignore world flag to make it hit the other side
  data.IsRfract = {false, false} -- Refracting flag for entity [1] and world [2]
  data.StRfract = false -- Start tracing the beam inside a boundary
  data.TeFilter = entity -- Make sure the initial laser source is skipped
  data.TvPoints = {Size = 0} -- Create empty vertices array
  data.VrOrigin = Vector(origin) -- Copy origin not to modify it
  data.VrDirect = direct:GetNormalized() -- Copy deirection not to modify it
  data.BmLength = math.max(tonumber(length) or 0, 0)
  data.NvDamage = math.max(tonumber(damage) or 0, 0)
  data.NvWidth  = math.max(tonumber(width ) or 0, 0)
  data.NvForce  = math.max(tonumber(force ) or 0, 0)
  data.TrMedium = {S = {DATA.REFRACT["air"], "air"}}
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
  data.RepIndex = index  -- Beam hit report index. Usually one if not provided

  if(data.NvLength <= 0) then return end
  if(data.VrDirect:LengthSqr() <= 0) then return end
  if(not LaserLib.IsValid(data.TeFilter)) then return end

  LaserLib.RegisterNode(data, origin)

  repeat
    --[[
      TODO: Fix world water to air refraction
      When beam goes up has to be checked when comes
      out of the water
      if(DATA.VDRUP:Dot(data.VrDirect) and )
    ]]

    local isRfract = (data.IsRfract[1] or data.IsRfract[2])

    trace = LaserLib.Trace(data.VrOrigin,
                           data.VrDirect,
                           (isRfract and data.TrRfract or data.NvLength),
                           data.TeFilter,
                           data.NvMask,
                           data.NvCGroup,
                           data.NvIWorld)

    local valid = LaserLib.IsValid(trace.Entity) -- Validate trace entity
    if(trace.Fraction > 0) then -- Ignore registering zero length traces
      if(valid and trace.Entity:GetClass() == "event_horizon") then -- trace.Entity
        LaserLib.RegisterNode(data, trace.HitPos, isRfract, false)
      else
        LaserLib.RegisterNode(data, trace.HitPos, isRfract)
      end
    else
      if(data.TvPoints.Size == 1) then
        data.StRfract = true -- Beam starts inside a refractive solid
      end -- Continue straight and ignore the zero fraction node
    end -- Do not put a node when beam starts in a solid

    if(trace.Hit and not LaserLib.IsUnit(trace.Entity)) then
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
                data.TeFilter = nil
                data.NvIWorld = false
                -- Appy origin and direction when beam exits the medium
                data.VrDirect:Set(vdir)
                data.VrOrigin:Set(trace.HitPos)
              else -- Get the trace ready to check the other side and register the location
                data.VrDirect:Set(vdir)
                data.VrOrigin:Set(vdir)
                data.VrOrigin:Mul(data.DmRfract * DATA.ERAD)
                data.VrOrigin:Add(trace.HitPos)
                LaserLib.VecNegate(data.VrDirect)
              end
            end
            if(usrfre) then
              LaserLib.SetPowerRatio(data, data.TrMedium.D[1][2])
            end
          end
        else -- Put special cases here
          if(trace.Entity:GetClass() == "event_horizon") then
            data.IsTrace = true
            if( not (CLIENT and (not trace.Entity.DrawRipple or trace.Entity.Target == NULL)) // HAX
            and not (SERVER and (not trace.Entity:IsOpen() or trace.Entity.ShuttingDown))) then
              local org, dir = trace.Entity:GetTeleportedVector(trace.HitPos, data.VrDirect)
              data.VrOrigin:Set(org); data.VrDirect:Set(dir)
              if(SERVER and entity.drawEffect) then
                trace.Entity:EnterEffect(trace.HitPos, data.NvWidth);
                if(LaserLib.IsValid(trace.Entity.Target)) then
                  trace.Entity.Target:EnterEffect(data.VrOrigin, data.NvWidth)
                end
              end
              LaserLib.DrawPoint(org)
              LaserLib.RegisterNode(data, data.VrOrigin, nil, true)
              data.NvLength = data.NvLength - data.NvLength * trace.Fraction
            else
              data.IsTrace = false
              data.NvLength = data.NvLength - data.NvLength * trace.Fraction
            end
          else
            data.TrMaters = GetMaterialID(trace, noverm)
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
                local rent, vdir, bout = trace.Entity -- Refraction entity
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
                data.DmRfract = 2 * trace.Entity:BoundingRadius()
                data.VrDirect:Set(vdir)
                data.VrOrigin:Set(vdir)
                data.VrOrigin:Mul(data.DmRfract * DATA.ERAD)
                data.VrOrigin:Add(trace.HitPos)
                LaserLib.VecNegate(data.VrDirect)
                -- Must trace only this entity otherwise invalid
                data.TeFilter = function(ent) return (ent == rent) end
                data.NvIWorld = true -- Ignore world too for precision  ws
                data.IsRfract[1] = true -- Raise the bounce off refract flag
                data.TrRfract = 2 * data.DmRfract * DATA.ERAD -- Scale again to make it hit
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
              data.VrOrigin:Mul(DATA.NMAR)
              data.VrOrigin:Add(trace.HitPos)
              LaserLib.VecNegate(data.VrDirect)
            end
            if(usrfre) then
              LaserLib.SetPowerRatio(data, data.TrMedium.D[1][2])
            end
          end
        else
          data.TrMaters = GetMaterialID(trace, noverm)
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
                data.VrOrigin:Set(direct)
                data.VrOrigin:Mul(DATA.NMAR)
                data.VrOrigin:Add(trace.HitPos)
                LaserLib.VecNegate(data.VrDirect)
                data.IsRfract[2] = true
              else
                if(data.TrMedium.D[1]) then -- From air to water
                  local vdir, bout = LaserLib.GetRefracted(data.VrDirect,
                                                           trace.HitNormal,
                                                           data.TrMedium.S[1][1],
                                                           data.TrMedium.D[1][1])
                  if(vdir) then -- Get the trace tready to check the other side and point and register the location
                    data.VrDirect:Set(vdir)
                    data.VrOrigin:Set(vdir)
                    data.VrOrigin:Mul(DATA.NMAR)
                    data.VrOrigin:Add(trace.HitPos)
                    data.TeFilter = nil
                    data.NvMask   = MASK_SOLID
                    data.TrMedium.S, data.TrMedium.D = data.TrMedium.D, data.TrMedium.S
                  end
                  if(usrfre) then
                    LaserLib.SetPowerRatio(data, data.TrMedium.D[1][2])
                  end
                end
              end
            else -- We are neither reflecting nor refracting and have hit a wall
              data.IsTrace = false -- Make sure to exit not to do performance hit
              data.NvLength = data.NvLength - data.NvLength * trace.Fraction
            end -- All triggers when reflecting and refracting are processed
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
    end
    if(LaserLib.IsValid(trace.Entity) and trace.Entity.RegisterSource) then
      trace.Entity:RegisterSource(entity) -- Register soucrce entity
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

  if(IsMounted("portal")) then -- Portal is mounted
    table.insert(data, {"models/props_bts/rocket.mdl"})
    table.insert(data, {"models/props/cake/cake.mdl",90})
    table.insert(data, {"models/Weapons/w_portalgun.mdl",180})
    table.insert(data, {"models/props/laser_emitter_center.mdl"})
    table.insert(data, {"models/props/pc_case02/pc_case02.mdl",90})
    table.insert(data, {"models/props/water_bottle/water_bottle.mdl",90})
  end

  if(IsMounted("hl2")) then -- HL2 is mounted
    table.insert(data, {"models/items/ar2_grenade.mdl"})
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
  end

  if(IsMounted("dod")) then -- DoD is mounted
    table.insert(data, {"models/weapons/w_smoke_ger.mdl",-90})
  end

  if(IsMounted("cstrike")) then -- Counter-Strike is mounted
    table.insert(data, {"models/props/de_nuke/emergency_lighta.mdl",90})
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
    table.Empty(rec)
    rec[DATA.TOOL.."_model"      ] = mod
    rec[DATA.TOOL.."_angleoffset"] = ang
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
