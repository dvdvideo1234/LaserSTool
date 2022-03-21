E2Lib.RegisterExtension("laserbeam", true,
  "Lets E2 chips utilize entity finction form the laser sources.",
  "Provides a dedicated API that can extract beam information from laser entities."
)

local REFLECT = LaserLib.GetData("REFLECT")
local REFRACT = LaserLib.GetData("REFRACT")
local gbRout  = false -- Wire cannot return multiple

local gtBoolToNum = {[true] = 1,[false] = 0} -- Convert between GLua boolean and wire boolean

local function getReport(ent, idx, typ)
  if(not LaserLib.IsValid(ent)) then return nil end
  if(not LaserLib.IsUnit(ent)) then return nil end
  local rep = ent.hitReports; if(not rep) then return nil end
  local siz = rep.Size; if(not siz) then return nil end
  if(idx <= 0 or idx > siz) then return nil end
  rep = rep[idx]; if(not rep) then return nil end
  rep = rep[typ]; if(not rep) then return nil end
  return rep -- Return the indexed hit report type
end

local function getReportKey(ent, idx, typ, key)
  local rep = getReport(ent, idx, typ)
  rep = rep[key]; if(not rep) then return nil end
  return rep -- Return indexed hit report value
end

local function getSource(ent)
  if(not LaserLib.IsValid(ent)) then return nil end
  if(not LaserLib.IsPrimary(ent)) then return nil end
  return ent -- Entity is actual source
end

__e2setcost(1)
e2function string entity:laserGetStopSound()
  local ent = getSource(this)
  if(not ent) then return "" end
  return this:GetStopSound()
end

__e2setcost(1)
e2function string entity:laserGetKillSound()
  local ent = getSource(this)
  if(not ent) then return "" end
  return this:GetKillSound()
end

__e2setcost(1)
e2function string entity:laserGetStartSound()
  local ent = getSource(this)
  if(not ent) then return "" end
  return this:GetStartSound()
end

__e2setcost(1)
e2function number entity:laserGetForceCenter()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return gtBoolToNum[this:GetForceCenter()]
end

__e2setcost(1)
e2function string entity:laserGetBeamMaterial()
  local ent = getSource(this)
  if(not ent) then return "" end
  return this:GetBeamMaterial()
end

__e2setcost(1)
e2function string entity:laserGetDissolveType()
  local ent = getSource(this)
  if(not ent) then return "" end
  return this:GetDissolveType()
end

__e2setcost(1)
e2function number entity:laserGetDissolveTypeID()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return LaserLib.GetDissolveID(this:GetDissolveType())
end

__e2setcost(1)
e2function number entity:laserGetEndingEffect()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return gtBoolToNum[this:GetEndingEffect()]
end

__e2setcost(1)
e2function number entity:laserGetReflectRatio()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return gtBoolToNum[this:GetReflectRatio()]
end

__e2setcost(1)
e2function number entity:laserGetRefractRatio()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return gtBoolToNum[this:GetRefractRatio()]
end

__e2setcost(1)
e2function number entity:laserGetNonOverMater()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return gtBoolToNum[this:GetNonOverMater()]
end

__e2setcost(1)
e2function entity entity:laserGetPlayer()
  local ent = getSource(this)
  if(not ent) then return nil end
  return (this.ply or this.player)
end

__e2setcost(1)
e2function number entity:laserGetBeamPower()
  local ent = getSource(this)
  if(not ent) then return 0 end
  local width  = this:GetBeamWidth()
  local damage = this:GetBeamDamage()
  return LaserLib.GetPower(width, damage)
end

__e2setcost(1)
e2function number entity:laserGetBeamLength()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return this:GetBeamLength()
end

__e2setcost(1)
e2function number entity:laserGetBeamWidth()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return this:GetBeamWidth()
end

__e2setcost(1)
e2function number entity:laserGetBeamDamage()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return this:GetBeamDamage()
end

__e2setcost(1)
e2function number entity:laserGetBeamForce()
  local ent = getSource(this)
  if(not ent) then return 0 end
  return this:GetBeamForce()
end

__e2setcost(1)
e2function vector entity:laserGetDataOrigin(number idx)
  local ext = getReportKey(this, idx, "BM", "VrOrigin")
  if(not ext) then return {0,0,0} end
  return {ext[1], ext[2], ext[3]}
end

__e2setcost(1)
e2function vector entity:laserGetDataDirect(number idx)
  local ext = getReportKey(this, idx, "BM", "VrDirect")
  if(not ext) then return {0,0,0} end
  return {ext[1], ext[2], ext[3]}
end

__e2setcost(1)
e2function number entity:laserGetDataLength(number idx)
  local beam = getReport(this, idx, "BM")
  if(not beam) then return 0 end
  return beam:GetLength()
end

__e2setcost(1)
e2function number entity:laserGetDataDamage(number idx)
  local ext = getReportKey(this, idx, "BM", "NvDamage")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function number entity:laserGetDataWidth(number idx)
  local ext = getReportKey(this, idx, "BM", "NvWidth")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function number entity:laserGetDataForce(number idx)
  local ext = getReportKey(this, idx, "BM", "NvForce")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function number entity:laserGetDataBounceMax(number idx)
  local ext = getReportKey(this, idx, "BM", "MxBounce")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function number entity:laserGetDataBounceRest(number idx)
  local ext = getReportKey(this, idx, "BM", "NvBounce")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function number entity:laserGetDataRange(number idx)
  local ext = getReportKey(this, idx, "BM", "RaLength")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function number entity:laserGetDataLengthRest(number idx)
  local ext = getReportKey(this, idx, "BM", "NvLength")
  return (ext and ext or 0)
end

__e2setcost(1)
e2function entity entity:laserGetDataSource(number idx)
  local beam = getReport(this, idx, "BM")
  if(not beam) then return nil end
  local src = beam:GetSource()
  return LaserLib.IsValid(src) and src or nil
end

__e2setcost(1)
e2function number entity:laserGetDataIsReflect(number idx)
  local ext = getReportKey(this, idx, "BM", "BrReflec")
  if(ext == nil) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function number entity:laserGetDataIsRefract(number idx)
  local ext = getReportKey(this, idx, "BM", "BrRefrac")
  if(ext == nil) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function vector entity:laserGetDataPointNode(number idx, number cnt)
  local ext = getReportKey(this, idx, "BM", "TvPoints")
  if(not ext) then return {0,0,0} end
  local set = ext[cnt]; if(not set) then return {0,0,0} end
  if(cnt <= 0 or cnt > ext.Size) then return {0,0,0} end
  return {set[1][1], set[1][2], set[1][3]}
end

__e2setcost(1)
e2function number entity:laserGetDataPointWidth(number idx, number cnt)
  local ext = getReportKey(this, idx, "BM", "TvPoints")
  if(not ext) then return 0 end
  local set = ext[cnt]; if(not set) then return 0 end
  return set[2]
end

__e2setcost(1)
e2function number entity:laserGetDataPointDamage(number idx, number cnt)
  local ext = getReportKey(this, idx, "BM", "TvPoints")
  if(not ext) then return 0 end
  local set = ext[cnt]; if(not set) then return 0 end
  return set[3]
end

__e2setcost(1)
e2function number entity:laserGetDataPointForce(number idx, number cnt)
  local ext = getReportKey(this, idx, "BM", "TvPoints")
  if(not ext) then return 0 end
  local set = ext[cnt]; if(not set) then return 0 end
  return set[4]
end

__e2setcost(1)
e2function number entity:laserGetDataPointIsDraw(number idx, number cnt)
  local ext = getReportKey(this, idx, "BM", "TvPoints")
  if(not ext) then return 0 end
  local set = ext[cnt]; if(not set) then return 0 end
  return gtBoolToNum[set[5]]
end

__e2setcost(1)
e2function number entity:laserGetDataPointSize(number idx)
  local ext = getReportKey(this, idx, "BM", "TvPoints")
  return (ext and ext.Size or 0)
end

__e2setcost(1)
e2function number entity:laserGetTraceAllSolid(number idx)
  local ext = getReportKey(this, idx, "TR", "AllSolid")
  if(not ext) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function number entity:laserGetTraceContents(number idx)
  local ext = getReportKey(this, idx, "TR", "Contents")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceDispFlags(number idx)
  local ext = getReportKey(this, idx, "TR", "DispFlags")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function entity entity:laserGetTraceEntity(number idx)
  local ext = getReportKey(this, idx, "TR", "Entity")
  return LaserLib.IsValid(ext) and ext or nil
end

__e2setcost(1)
e2function number entity:laserGetTraceFraction(number idx)
  local ext = getReportKey(this, idx, "TR", "Fraction")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceFractionLS(number idx)
  local ext = getReportKey(this, idx, "TR", "FractionLeftSolid")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceHit(number idx)
  local ext = getReportKey(this, idx, "TR", "Hit")
  if(not ext) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function number entity:laserGetTraceHitBox(number idx)
  local ext = getReportKey(this, idx, "TR", "HitBox")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceHitGroup(number idx)
  local ext = getReportKey(this, idx, "TR", "HitGroup")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceHitNoDraw(number idx)
  local ext = getReportKey(this, idx, "TR", "HitNoDraw")
  if(not ext) then return 0 end
  return gtBoolToNum[ext]
end

__e2setcost(1)
e2function number entity:laserGetTraceHitNonWorld(number idx)
  local ext = getReportKey(this, idx, "TR", "HitNonWorld")
  if(not ext) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function vector entity:laserGetTraceHitNormal(number idx)
  local ext = getReportKey(this, idx, "TR", "HitNormal")
  if(not ext) then return {0,0,0} end
  return {ext[1], ext[2], ext[3]}
end

__e2setcost(1)
e2function vector entity:laserGetTraceHitPos(number idx)
  local ext = getReportKey(this, idx, "TR", "HitPos")
  if(not ext) then return {0,0,0} end
  return {ext[1], ext[2], ext[3]}
end

__e2setcost(1)
e2function number entity:laserGetTraceHitSky(number idx)
  local ext = getReportKey(this, idx, "TR", "HitSky")
  if(not ext) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function string entity:laserGetTraceHitTexture(number idx)
  local ext = getReportKey(this, idx, "TR", "HitTexture")
  if(not ext) then return "" end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceHitWorld(number idx)
  local ext = getReportKey(this, idx, "TR", "HitWorld")
  if(not ext) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function vector entity:laserGetTraceNormal(number idx)
  local ext = getReportKey(this, idx, "TR", "Normal")
  if(not ext) then return {0,0,0} end
  return {ext[1], ext[2], ext[3]}
end

__e2setcost(1)
e2function number entity:laserGetTraceHitPhysicsBone(number idx)
  local ext = getReportKey(this, idx, "TR", "PhysicsBone")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function vector entity:laserGetTraceStartPos(number idx)
  local ext = getReportKey(this, idx, "TR", "StartPos")
  if(not ext) then return {0,0,0} end
  return {ext[1], ext[2], ext[3]}
end

__e2setcost(1)
e2function number entity:laserGetTraceStartSolid(number idx)
  local ext = getReportKey(this, idx, "TR", "StartSolid")
  if(not ext) then return 0 end; return gtBoolToNum[ext]
end

__e2setcost(1)
e2function number entity:laserGetTraceSurfaceFlags(number idx)
  local ext = getReportKey(this, idx, "TR", "SurfaceFlags")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number entity:laserGetTraceSurfacePropsID(number idx)
  local ext = getReportKey(this, idx, "TR", "SurfaceProps")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function string entity:laserGetTraceSurfacePropsName(number idx)
  local ext = getReportKey(this, idx, "TR", "SurfaceProps")
  if(not ext) then return 0 end
  return util.GetSurfacePropName(ext) or ""
end

__e2setcost(1)
e2function number entity:laserGetTraceMatType(number idx)
  local ext = getReportKey(this, idx, "TR", "MatType")
  if(not ext) then return 0 end; return ext
end

__e2setcost(1)
e2function number laserGetReflectDataRatio(string idx)
  local ext = REFLECT[idx]; return (ext and ext[1] or 0)
end

__e2setcost(1)
e2function string laserGetReflectDataKey(string idx)
  local ext = REFLECT[idx]; return (ext and ext[2] or "")
end

__e2setcost(1)
e2function number laserGetRefractDataIndex(string idx)
  local ext = REFRACT[idx]; return (ext and ext[1] or 0)
end

__e2setcost(1)
e2function number laserGetRefractDataRatio(string idx)
  local ext = REFRACT[idx]; return (ext and ext[2] or 0)
end

__e2setcost(1)
e2function string laserGetRefractDataKey(string idx)
  local ext = REFRACT[idx]; return (ext and ext[3] or "")
end

__e2setcost(1)
e2function vector laserGetReflectBeam(vector fall, vector norm)
  local res = LaserLib.GetReflected(fall, norm)
  return {res[1], res[2], res[3]}
end

__e2setcost(1)
e2function vector laserGetRefractBeam(vector fall, vector norm, number sors, number dest)
  local res, out = LaserLib.GetRefracted(fall, norm); gbRout = out
  return {res[1], res[2], res[3]}
end

__e2setcost(1)
e2function number laserGetRefractIsOut()
  return (gbRout and 1 or 0)
end

__e2setcost(1)
e2function number laserGetBeamPower(width, damage)
  return LaserLib.GetPower(width, damage)
end

__e2setcost(1)
e2function number laserGetBeamIsPower(width, damage)
  return (LaserLib.IsPower(width, damage) and 1 or 0)
end
