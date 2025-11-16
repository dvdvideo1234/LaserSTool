E2Lib.RegisterExtension("laserbeam", true,
  "Allows E2 chips utilize entity functions form the laser sources and addon.",
  "Provides a dedicated API that can extract beam information from laser entities and database."
)

local gbRNEXT, gbRSAME = false, false -- These store the current status for medium refraction
local gsKEYA    = LaserLib.GetData("KEYA") -- Retrieve the active key indexing select all
local gtREFLECT = LaserLib.DataReflect(gsKEYA) -- Retrieve all reflection database entries
local gtREFRACT = LaserLib.DataRefract(gsKEYA) -- Retrieve all refraction database entries
local gtWIRECNV = {[true] = 1,[false] = 0} -- Convert between GLua boolean and wire boolean

--[[
 * Converts any value to wiremod dedicated booleans
 * src > source value to be converted
]]
local function toBool(src)
  return gtWIRECNV[tobool(src)]
end

--[[
 * Converts any value to wiremod dedicated number
 * src > source value to be converted
]]
local function toNumber(src)
  return (tonumber(src) or 0)
end

--[[
 * Converts any value to wiremod dedicated string
 * src > source value to be converted
]]
local function toString(src)
  return tostring(src or "")
end

local function getReports(ent)
  if(not LaserLib.IsUnit(ent)) then return nil end
  return ent.mrReports -- Entity hit reports
end
--[[
 * Returns the specified laser hit report entry under the requested index
 * ent > Entity to search for hit reports
 * idx > Hit report requested index entry to search for
 * trc > Switch to beam hit report trace result structure
]]
local function getReport(ent, idx, trc)
  local rep = getReports(ent) -- Entity reports
  if(not rep) then return nil end -- No reports
  local siz = rep.Size -- Entity hit report size
  if(not siz or siz == 0) then return nil end
  if(idx <= 0 or idx > siz) then return nil end
  rep = rep[idx]; if(not rep) then return nil end
  if(trc) then rep = rep.BmTarget end
  return rep -- Return the indexed hit report type
end

--[[
 * Returns the specified laser hit report entry member value under the requested index
 * ent > Entity to search for hit reports
 * idx > Hit report requested index entry to search for
 * key > Hit report requested data structure member name
 * trc > Switch to beam hit report trace result structure
]]
local function getReportKey(ent, idx, key, trc)
  local rep = getReport(ent, idx, trc)
  if(not rep) then return nil end; rep = rep[key]
  if(not rep) then return nil end; return rep
end

--[[
 * Returns the argument when classified as source. Otherwise `nil`
 * ent > Entity to be checked for being a source
]]
local function getSource(ent)
  local src = LaserLib.IsSource(ent)
  return (src and ent or nil)
end

__e2setcost(1)
e2function string entity:laserGetStopSound()
  local src = getSource(this)
  if(not src) then return "" end
  return toString(src:GetStopSound())
end

__e2setcost(1)
e2function string entity:laserGetKillSound()
  local src = getSource(this)
  if(not src) then return "" end
  return toString(src:GetKillSound())
end

__e2setcost(1)
e2function string entity:laserGetStartSound()
  local src = getSource(this)
  if(not src) then return "" end
  return toString(src:GetStartSound())
end

__e2setcost(1)
e2function number entity:laserGetForceCenter()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetForceCenter())
end

__e2setcost(1)
e2function string entity:laserGetBeamMaterial()
  local src = getSource(this)
  if(not src) then return "" end
  return toString(src:GetBeamMaterial())
end

__e2setcost(1)
e2function string entity:laserGetDissolveType()
  local src = getSource(this)
  if(not src) then return "" end
  return toString(src:GetDissolveType())
end

__e2setcost(1)
e2function number entity:laserGetDissolveTypeID()
  local src = getSource(this)
  if(not src) then return 0 end
  return toNumber(LaserLib.GetDissolveID(src:GetDissolveType()))
end

__e2setcost(1)
e2function number entity:laserGetEndingEffect()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetEndingEffect())
end

__e2setcost(1)
e2function number entity:laserGetReflectRatio()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetReflectRatio())
end

__e2setcost(1)
e2function number entity:laserGetRefractRatio()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetRefractRatio())
end

__e2setcost(1)
e2function number entity:laserGetNonOverMater()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetNonOverMater())
end

__e2setcost(1)
e2function entity entity:laserGetPlayer()
  local src = getSource(this)
  if(not src) then return nil end
  return (src.ply or src.player)
end

__e2setcost(1)
e2function number entity:laserGetBeamPower()
  local src = getSource(this)
  if(not src) then return 0 end
  local width  = src:GetBeamWidth()
  local damage = src:GetBeamDamage()
  return toNumber(LaserLib.GetPower(width, damage))
end

__e2setcost(1)
e2function number entity:laserGetBeamLength()
  local src = getSource(this)
  if(not src) then return 0 end
  return toNumber(src:GetBeamLength())
end

__e2setcost(1)
e2function number entity:laserGetBeamWidth()
  local src = getSource(this)
  if(not src) then return 0 end
  return toNumber(src:GetBeamWidth())
end

__e2setcost(1)
e2function number entity:laserGetBeamDamage()
  local src = getSource(this)
  if(not src) then return 0 end
  return toNumber(src:GetBeamDamage())
end

__e2setcost(1)
e2function number entity:laserGetBeamForce()
  local src = getSource(this)
  if(not src) then return 0 end
  return toNumber(src:GetBeamForce())
end

__e2setcost(1)
e2function number entity:laserGetBeamSafety()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetBeamSafety())
end

__e2setcost(1)
e2function number entity:laserIsUnit()
  return toBool(LaserLib.IsUnit(this))
end

__e2setcost(1)
e2function number entity:laserIsBeam()
  return toBool(LaserLib.IsBeam(this))
end

__e2setcost(1)
e2function number entity:laserIsPrimary()
  return toBool(LaserLib.IsPrimary(this))
end

__e2setcost(1)
e2function number entity:laserIsSource()
  return toBool(LaserLib.IsSource(this))
end

__e2setcost(1)
e2function number entity:laserGetReportSize()
  local ext = getReports(this) -- Entity hit reports
  return (ext and toNumber(ext.Size) or 0)  -- No reports
end

__e2setcost(1)
e2function vector entity:laserGetDataOrigin(number idx)
  local ext = getReportKey(this, idx, "VrOrigin")
  if(not ext) then return Vector() end
  return Vector(ext)
end

__e2setcost(1)
e2function vector entity:laserGetDataDirect(number idx)
  local ext = getReportKey(this, idx, "VrDirect")
  if(not ext) then return Vector() end
  return Vector(ext)
end

__e2setcost(1)
e2function number entity:laserGetDataLength(number idx)
  local beam = getReport(this, idx)
  if(not beam) then return 0 end
  return toNumber(beam:GetLength())
end

__e2setcost(1)
e2function number entity:laserGetDataDamage(number idx)
  return toNumber(getReportKey(this, idx, "NvDamage"))
end

__e2setcost(1)
e2function number entity:laserGetDataWidth(number idx)
  return toNumber(getReportKey(this, idx, "NvWidth"))
end

__e2setcost(1)
e2function number entity:laserGetDataForce(number idx)
  return toNumber(getReportKey(this, idx, "NvForce"))
end

__e2setcost(1)
e2function number entity:laserGetDataBounceMax(number idx)
  return toNumber(getReportKey(this, idx, "MxBounce"))
end

__e2setcost(1)
e2function number entity:laserGetDataBounceRest(number idx)
  return toNumber(getReportKey(this, idx, "NvBounce"))
end

__e2setcost(1)
e2function number entity:laserGetDataRange(number idx)
  return toNumber(getReportKey(this, idx, "RaLength"))
end

__e2setcost(1)
e2function number entity:laserGetDataLengthRest(number idx)
  return toNumber(getReportKey(this, idx, "NvLength"))
end

__e2setcost(1)
e2function entity entity:laserGetDataSource(number idx)
  local beam = getReport(this, idx)
  if(not beam) then return nil end
  local src = beam:GetSource()
  return (LaserLib.IsValid(src) and src or nil)
end

__e2setcost(1)
e2function number entity:laserGetDataIsReflect(number idx)
  local ext = getReportKey(this, idx, "BrReflec")
  if(ext == nil) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function number entity:laserGetDataIsRefract(number idx)
  local ext = getReportKey(this, idx, "BrRefrac")
  if(ext == nil) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function vector entity:laserGetDataPointNode(number idx, number cnt)
  local ext = getReportKey(this, idx, "TvPoints")
  if(not ext) then return Vector() end; local set = ext[cnt]
  if(not set) then return Vector() end; return Vector(set[1])
end

__e2setcost(1)
e2function number entity:laserGetDataPointWidth(number idx, number cnt)
  local ext = getReportKey(this, idx, "TvPoints")
  if(not ext) then return 0 end; local set = ext[cnt]
  if(not set) then return 0 end; return toNumber(set[2])
end

__e2setcost(1)
e2function number entity:laserGetDataPointDamage(number idx, number cnt)
  local ext = getReportKey(this, idx, "TvPoints")
  if(not ext) then return 0 end; local set = ext[cnt]
  if(not set) then return 0 end; return toNumber(set[3])
end

__e2setcost(1)
e2function number entity:laserGetDataPointForce(number idx, number cnt)
  local ext = getReportKey(this, idx, "TvPoints")
  if(not ext) then return 0 end local set = ext[cnt]
  if(not set) then return 0 end; return toNumber(set[4])
end

__e2setcost(1)
e2function number entity:laserGetDataPointIsDraw(number idx, number cnt)
  local ext = getReportKey(this, idx, "TvPoints")
  if(not ext) then return 0 end; local set = ext[cnt]
  if(not set) then return 0 end; return toBool(set[5])
end

__e2setcost(1)
e2function number entity:laserGetDataPointSize(number idx)
  local ext = getReportKey(this, idx, "TvPoints")
  return toNumber(ext and ext.Size or 0)
end

__e2setcost(1)
e2function number entity:laserGetTraceAllSolid(number idx)
  local ext = getReportKey(this, idx, "AllSolid", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceContents(number idx)
  local ext = getReportKey(this, idx, "Contents", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceDispFlags(number idx)
  local ext = getReportKey(this, idx, "DispFlags", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function entity entity:laserGetTraceEntity(number idx)
  local ext = getReportKey(this, idx, "Entity", true)
  return (LaserLib.IsValid(ext) and ext or nil)
end

__e2setcost(1)
e2function number entity:laserGetTraceFraction(number idx)
  local ext = getReportKey(this, idx, "Fraction", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceFractionLS(number idx)
  local ext = getReportKey(this, idx, "FractionLeftSolid", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHit(number idx)
  local ext = getReportKey(this, idx, "Hit", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitBox(number idx)
  local ext = getReportKey(this, idx, "HitBox", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitGroup(number idx)
  local ext = getReportKey(this, idx, "HitGroup", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitNoDraw(number idx)
  local ext = getReportKey(this, idx, "HitNoDraw", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitNonWorld(number idx)
  local ext = getReportKey(this, idx, "HitNonWorld", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function vector entity:laserGetTraceHitNormal(number idx)
  local ext = getReportKey(this, idx, "HitNormal", true)
  if(not ext) then return Vector() end; return Vector(ext)
end

__e2setcost(1)
e2function vector entity:laserGetTraceHitPos(number idx)
  local ext = getReportKey(this, idx, "HitPos", true)
  if(not ext) then return Vector() end; return Vector(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitSky(number idx)
  local ext = getReportKey(this, idx, "HitSky", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function string entity:laserGetTraceHitTexture(number idx)
  local ext = getReportKey(this, idx, "HitTexture", true)
  if(not ext) then return "" end; return toString(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitWorld(number idx)
  local ext = getReportKey(this, idx, "HitWorld", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function vector entity:laserGetTraceNormal(number idx)
  local ext = getReportKey(this, idx, "Normal", true)
  if(not ext) then return Vector() end
  return Vector(ext)
end

__e2setcost(1)
e2function number entity:laserGetTracePhysicsBone(number idx)
  local ext = getReportKey(this, idx, "PhysicsBone", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function vector entity:laserGetTraceStartPos(number idx)
  local ext = getReportKey(this, idx, "StartPos", true)
  if(not ext) then return Vector() end
  return Vector(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceStartSolid(number idx)
  local ext = getReportKey(this, idx, "StartSolid", true)
  if(not ext) then return 0 end; return toBool(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceSurfaceFlags(number idx)
  local ext = getReportKey(this, idx, "SurfaceFlags", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number entity:laserGetTraceSurfacePropsID(number idx)
  local ext = getReportKey(this, idx, "SurfaceProps", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function string entity:laserGetTraceSurfacePropsName(number idx)
  local ext = getReportKey(this, idx, "SurfaceProps", true)
  if(not ext) then return "" end
  return toString(util.GetSurfacePropName(ext))
end

__e2setcost(1)
e2function number entity:laserGetTraceMatType(number idx)
  local ext = getReportKey(this, idx, "MatType", true)
  if(not ext) then return 0 end; return toNumber(ext)
end

__e2setcost(1)
e2function number laserGetReflectDataRatio(string idx)
  local ext = gtREFLECT[idx]; return toNumber(ext and ext[1] or 0)
end

__e2setcost(1)
e2function number laserGetReflectDataID(string idx)
  local ext = gtREFLECT[idx]; return toNumber(ext and ext.ID or 0)
end

__e2setcost(1)
e2function string laserGetReflectDataKey(string idx)
  local ext = gtREFLECT[idx]; return toString(ext and ext.Key or "")
end

__e2setcost(1)
e2function number laserGetRefractDataIndex(string idx)
  local ext = gtREFRACT[idx]; return toNumber(ext and ext[1] or 0)
end

__e2setcost(1)
e2function number laserGetRefractDataRatio(string idx)
  local ext = gtREFRACT[idx]; return toNumber(ext and ext[2] or 0)
end

__e2setcost(1)
e2function number laserGetRefractDataID(string idx)
  local ext = gtREFRACT[idx]; return toNumber(ext and ext.ID or 0)
end

__e2setcost(1)
e2function number laserGetRefractDataContent(string idx)
  local ext = gtREFRACT[idx]; return toNumber(ext and ext.Con or 0)
end

__e2setcost(1)
e2function string laserGetRefractDataKey(string idx)
  local ext = gtREFRACT[idx]; return toString(ext and ext.Key or "")
end

__e2setcost(1)
e2function vector laserGetReflectBeam(vector come, vector norm)
  return LaserLib.GetReflected(come, norm)
end

__e2setcost(1)
e2function vector laserGetRefractBeam(vector come, vector norm, number sors, number dest)
  local res, nex, sam = LaserLib.GetRefracted(come, norm, sors, dest)
  gbRNEXT, gbRSAME = nex, sam; return res
end

__e2setcost(1)
e2function number laserGetRefractIsNext()
  return toBool(gbRNEXT)
end

__e2setcost(1)
e2function number laserGetRefractIsSame()
  return toBool(gbRSAME)
end

__e2setcost(1)
e2function number laserGetBeamPower(number width, number damage)
  return toNumber(LaserLib.GetPower(width, damage))
end

__e2setcost(1)
e2function number laserGetBeamIsPower(number width, number damage)
  return toBool(LaserLib.IsPower(width, damage))
end

__e2setcost(1)
e2function number laserGetDissolveID(string type)
  return toNumber(LaserLib.GetDissolveID(type))
end

__e2setcost(1)
e2function number laserGetRefractAngleRad(number source, number destin)
  return toNumber(LaserLib.GetRefractAngle(source, destin, false))
end

__e2setcost(1)
e2function number laserGetRefractAngleDeg(number source, number destin)
  return toNumber(LaserLib.GetRefractAngle(source, destin, true))
end

