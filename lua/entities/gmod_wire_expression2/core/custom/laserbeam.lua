
--[[ **************************** REGISTER **************************** ]]

-- Register extension to the wire extensions list
E2Lib.RegisterExtension("laserbeam", true,
  "Allows E2 chips utilize entity functions form the laser sources and addon.",
  "Provides a dedicated API that can extract beam information from laser entities and database."
)

--[[ **************************** CONFIGURATION **************************** ]]

local gsKEYA    = LaserLib.GetData("KEYA") -- Retrieve the active key indexing select all
local gtREFLECT = LaserLib.DataReflect(gsKEYA) -- Retrieve all reflection database entries
local gtREFRACT = LaserLib.DataRefract(gsKEYA) -- Retrieve all refraction database entries
local gtWIRECNV = {[true] = 1,[false] = 0} -- Convert between GLua boolean and wire boolean
local gtSTATUS  = {false, false, 0} -- These store the current status for medium refraction

--[[ **************************** PRIMITIVES **************************** ]]

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

--[[
 * Converts any value to wiremod dedicated string
 * src > source value to be converted
]]
local function getReports(ent)
  if(not LaserLib.IsUnit(ent)) then return nil end
  return ent:GetHitReports() -- Entity hit reports
end
--[[
 * Returns the specified laser hit report entry under the requested index
 * ent > Entity to search for hit reports
 * idx > Hit report requested index entry to search for
 * trc > Switch to beam hit report trace result structure
]]
local function getReport(ent, idx)
  local ros = getReports(ent) -- Entity reports
  if(not ros) then return nil end -- No reports
  local siz = ros.Size -- Entity hit report size
  if(not siz or siz == 0) then return nil end
  return ent:GetHitReport(idx) -- Indexed hit report
end

--[[
 * Returns the argument when classified as source. Otherwise `nil`
 * ent > Entity to be checked for being a source
]]
local function getSource(ent)
  local src = LaserLib.IsSource(ent)
  return (src and ent or nil)
end

--[[ **************************** API **************************** ]]

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
e2function number entity:laserGetBeamIgnite()
  local src = getSource(this)
  if(not src) then return 0 end
  return toBool(src:GetBeamIgnite())
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
  local BM = getReport(this, idx)
  if(not ext) then return Vector() end
  return Vector(ext.VrOrigin)
end

__e2setcost(1)
e2function vector entity:laserGetDataDirect(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return Vector() end
  return Vector(ext.VrDirect)
end

__e2setcost(1)
e2function number entity:laserGetDataDamage(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvDamage)
end

__e2setcost(1)
e2function number entity:laserGetDataWidth(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvWidth)
end

__e2setcost(1)
e2function number entity:laserGetDataForce(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvForce)
end

__e2setcost(1)
e2function number entity:laserGetDataBounceMax(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.MxBounce)
end

__e2setcost(1)
e2function number entity:laserGetDataBounceRest(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvBounce)
end

__e2setcost(1)
e2function number entity:laserGetDataRange(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.RaLength)
end

__e2setcost(1)
e2function number entity:laserGetDataLengthRest(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvLength)
end

__e2setcost(1)
e2function number entity:laserGetDataLengthBeam(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.BmLength)
end

__e2setcost(1)
e2function number entity:laserGetDataLengthOrig(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.BoLength)
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
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toBool(ext.BrReflec)
end

__e2setcost(1)
e2function number entity:laserGetDataIsRefract(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toBool(ext.BrRefrac)
end

__e2setcost(1)
e2function number entity:laserGetDataIsNoOver(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toBool(ext.BmNoover)
end

__e2setcost(1)
e2function number entity:laserGetDataIsDisperse(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toBool(ext.BmDisper)
end

__e2setcost(1)
e2function number entity:laserGetDataIsFresnel(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toBool(ext.BmFresne)
end

__e2setcost(1)
e2function number entity:laserGetDataFresnelCount(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvFresne)
end

__e2setcost(1)
e2function number entity:laserGetDataGravitySize(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.BmHoleLn)
end

__e2setcost(1)
e2function number entity:laserGetDataGravityStep(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.NvHoleLn)
end

__e2setcost(1)
e2function number entity:laserGetDataWaveLength(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end
  return toNumber(ext.BmWaveLn)
end

__e2setcost(1)
e2function vector entity:laserGetDataPointNode(number idx, number cnt)
  local ext = getReport(this, idx)
  if(not ext) then return Vector() end; ext = ext.TvPoints[cnt]
  if(not ext) then return Vector() end; return Vector(ext[1])
end

__e2setcost(1)
e2function number entity:laserGetDataPointWidth(number idx, number cnt)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext.TvPoints[cnt]
  if(not ext) then return 0 end; return toNumber(ext[2])
end

__e2setcost(1)
e2function number entity:laserGetDataPointDamage(number idx, number cnt)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext.TvPoints[cnt]
  if(not ext) then return 0 end; return toNumber(ext[3])
end

__e2setcost(1)
e2function number entity:laserGetDataPointForce(number idx, number cnt)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext.TvPoints[cnt]
  if(not ext) then return 0 end; return toNumber(ext[4])
end

__e2setcost(1)
e2function number entity:laserGetDataPointIsDraw(number idx, number cnt)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext.TvPoints[cnt]
  if(not ext) then return 0 end; return toBool(ext[5])
end

__e2setcost(1)
e2function number entity:laserGetDataPointSize(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext.TvPoints
  if(not ext) then return 0 end; return toNumber(ext.Size)
end

__e2setcost(1)
e2function number entity:laserGetTraceAllSolid(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.AllSolid)
end

__e2setcost(1)
e2function number entity:laserGetTraceContents(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.Contents)
end

__e2setcost(1)
e2function number entity:laserGetTraceDispFlags(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.DispFlags)
end

__e2setcost(1)
e2function entity entity:laserGetTraceEntity(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return nil end; ext = ext:GetTarget()
  if(not ext) then return nil end; ext = ext.Entity
  return (LaserLib.IsValid(ext) and ext or nil)
end

__e2setcost(1)
e2function number entity:laserGetTraceFraction(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.Fraction)
end

__e2setcost(1)
e2function number entity:laserGetTraceFractionLS(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.FractionLeftSolid)
end

__e2setcost(1)
e2function number entity:laserGetTraceHit(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.Hit)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitBox(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.HitBox)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitGroup(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.HitGroup)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitNoDraw(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.HitNoDraw)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitNonWorld(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.HitNonWorld)
end

__e2setcost(1)
e2function vector entity:laserGetTraceHitNormal(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return Vector() end; ext = ext:GetTarget()
  if(not ext) then return Vector() end; return Vector(ext.HitNormal)
end

__e2setcost(1)
e2function vector entity:laserGetTraceHitPos(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return Vector() end; ext = ext:GetTarget()
  if(not ext) then return Vector() end; return Vector(ext.HitPos)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitSky(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.HitSky)
end

__e2setcost(1)
e2function string entity:laserGetTraceHitTexture(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return "" end; ext = ext:GetTarget()
  if(not ext) then return "" end; return toString(ext.HitTexture)
end

__e2setcost(1)
e2function number entity:laserGetTraceHitWorld(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.HitWorld)
end

__e2setcost(1)
e2function vector entity:laserGetTraceNormal(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return Vector() end; ext = ext:GetTarget()
  if(not ext) then return Vector() end; return Vector(ext.Normal)
end

__e2setcost(1)
e2function number entity:laserGetTracePhysicsBone(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.PhysicsBone)
end

__e2setcost(1)
e2function vector entity:laserGetTraceStartPos(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return Vector() end; ext = ext:GetTarget()
  if(not ext) then return Vector() end; return Vector(ext.StartPos)
end

__e2setcost(1)
e2function number entity:laserGetTraceStartSolid(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toBool(ext.StartSolid)
end

__e2setcost(1)
e2function number entity:laserGetTraceSurfaceFlags(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.SurfaceFlags)
end

__e2setcost(1)
e2function number entity:laserGetTraceSurfacePropsID(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.SurfaceProps)
end

__e2setcost(1)
e2function string entity:laserGetTraceSurfacePropsName(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return "" end; ext = ext:GetTarget()
  if(not ext) then return "" end; ext = ext.SurfaceProps
  return toString(util.GetSurfacePropName(ext))
end

__e2setcost(1)
e2function number entity:laserGetTraceMatType(number idx)
  local ext = getReport(this, idx)
  if(not ext) then return 0 end; ext = ext:GetTarget()
  if(not ext) then return 0 end; return toNumber(ext.MatType)
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
  local res, nex, sam, cos = LaserLib.GetRefracted(come, norm, sors, dest)
  gtSTATUS[1], gtSTATUS[2], gtSTATUS[3] = nex, sam, cos; return res
end

__e2setcost(1)
e2function number laserGetRefractIsNext()
  return toBool(gtSTATUS[1])
end

__e2setcost(1)
e2function number laserGetRefractIsSame()
  return toBool(gtSTATUS[2])
end

__e2setcost(1)
e2function number laserGetRefractCosine()
  return toNumber(gtSTATUS[3])
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

__e2setcost(1)
e2function number laserGetRefractAngleRatio(number source, number destin)
  return toNumber(LaserLib.GetRefractAngle(source, destin))
end


