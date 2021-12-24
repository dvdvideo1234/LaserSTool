E2Lib.RegisterExtension("laserbeam", true,
  "Lets E2 chips utilize entity finction form the laser sources.",
  "Provides a dedicated API that can extract data from laser source entities."
)

local gtBoolToNum = {[true] = 1,[false] = 0} -- Convert between GLua boolean and wire boolean

__e2setcost(1)
e2function string entity:laserGetStopSound()
  if(not LaserLib.IsValid(this)) then return "" end
  if(not LaserLib.IsUnit(this, 2)) then return "" end
  return this:GetStopSound()
end

__e2setcost(1)
e2function string entity:laserGetKillSound()
  if(not LaserLib.IsValid(this)) then return "" end
  if(not LaserLib.IsUnit(this, 2)) then return "" end
  return this:GetKillSound()
end

__e2setcost(1)
e2function string entity:laserGetStartSound()
  if(not LaserLib.IsValid(this)) then return "" end
  if(not LaserLib.IsUnit(this, 2)) then return "" end
  return this:GetStartSound()
end

__e2setcost(1)
e2function number entity:laserGetForceCenter()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return gtBoolToNum[this:GetForceCenter()]
end

__e2setcost(1)
e2function string entity:laserGetBeamMaterial()
  if(not LaserLib.IsValid(this)) then return "" end
  if(not LaserLib.IsUnit(this, 2)) then return "" end
  return this:GetBeamMaterial()
end

__e2setcost(1)
e2function string entity:laserGetDissolveType()
  if(not LaserLib.IsValid(this)) then return "" end
  if(not LaserLib.IsUnit(this, 2)) then return "" end
  return this:GetDissolveType()
end

__e2setcost(1)
e2function number entity:laserGetDissolveTypeID()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return LaserLib.GetDissolveID(this:GetDissolveType())
end

__e2setcost(1)
e2function number entity:laserGetEndingEffect()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return gtBoolToNum[this:GetEndingEffect()]
end

__e2setcost(1)
e2function number entity:laserGetReflectRatio()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return gtBoolToNum[this:GetReflectRatio()]
end

__e2setcost(1)
e2function number entity:laserGetRefractRatio()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return gtBoolToNum[this:GetRefractRatio()]
end

__e2setcost(1)
e2function number entity:laserGetNonOverMater()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return gtBoolToNum[this:GetNonOverMater()]
end

__e2setcost(1)
e2function entity entity:laserGetPlayer()
  if(not LaserLib.IsValid(this)) then return nil end
  if(not LaserLib.IsUnit(this, 2)) then return nil end
  return (this.ply or this.player)
end

__e2setcost(1)
e2function number entity:laserGetBeamPower()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  local width  = this:GetBeamWidth()
  local damage = this:GetBeamDamage()
  return LaserLib.GetPower(width, damage)
end

__e2setcost(1)
e2function number entity:laserGetBeamLength()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return this:GetBeamLength()
end

__e2setcost(1)
e2function number entity:laserGetBeamWidth()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return this:GetBeamWidth()
end

__e2setcost(1)
e2function number entity:laserGetBeamDamage()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return this:GetBeamDamage()
end

__e2setcost(1)
e2function number entity:laserGetBeamForce()
  if(not LaserLib.IsValid(this)) then return 0 end
  if(not LaserLib.IsUnit(this, 2)) then return 0 end
  return this:GetBeamForce()
end
