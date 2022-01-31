-- Instructions and info
SWEP.Author                 = "DVD"
SWEP.Contact                = "dvd_video@abv.bg"
SWEP.Purpose                = "The laser pawer in your hands"
SWEP.Instructions           = "Primary attack to shoot a laser beam"
SWEP.PrintName              = "Laser pistol"
SWEP.Category               = LaserLib.GetData("CATG")
-- Control values
SWEP.Weight                 = 5
SWEP.Slot                   = 3
SWEP.SlotPos                = 1
-- Control flags
SWEP.Spawnable              = true
SWEP.AdminOnly              = true
SWEP.UseHands               = true
SWEP.AutoSwitchTo           = false
SWEP.AutoSwitchFrom         = false
SWEP.DrawAmmo               = false
SWEP.DrawCrosshair          = true
-- Visuals
SWEP.ViewModel              = "models/weapons/c_pistol.mdl"
SWEP.WorldModel             = "models/weapons/w_pistol.mdl"
-- Prmaray setup
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
-- Secondary setup
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.AccurateCrosshair      = true

local gsTool = LaserLib.GetTool()
local gsPref = gsTool.."_"
local tAmax = LaserLib.GetData("AMAX")

local MXBMDAMG = LaserLib.GetData("MXBMDAMG")
local MXBMWIDT = LaserLib.GetData("MXBMWIDT")
local MXBMFORC = LaserLib.GetData("MXBMFORC")
local MXBMLENG = LaserLib.GetData("MXBMLENG")
local EFFECTDT = LaserLib.GetData("EFFECTDT")
local DAMAGEDT = LaserLib.GetData("DAMAGEDT")

if(SERVER) then
  resource.AddFile("materials/vgui/entities/gmod_laser_pistol.vmt")
end

function SWEP:Setup()
  if(CLIENT) then
    local user = self:GetOwner()
    if(user.GetViewModel and user:GetViewModel():IsValid()) then
      local mod = user:GetViewModel()
      local idx = mod:LookupAttachment("muzzle")
      if(idx == 0) then idx = mod:LookupAttachment("1") end
      if(user:GetAttachment(idx)) then
        self.VM = mod
        self.VA = idx
      end
    end
    self.WA = self:LookupAttachment("muzzle")
    self.MO, self.MD = Vector(), Vector()
  end

  LaserLib.GetData("CLS")[self:GetClass()] = {true, true}
end

function SWEP:Initialize()
  self:Setup()
end

function SWEP:Deploy()
  self:Setup()
end

--[[---------------------------------------------------------
  Reload does nothing
-----------------------------------------------------------]]
function SWEP:Reload()
  return false
end

--[[---------------------------------------------------------
  PrimaryAttack
-----------------------------------------------------------]]
function SWEP:PrimaryAttack()
  return false
end

--[[---------------------------------------------------------
  SecondaryAttack
-----------------------------------------------------------]]
function SWEP:SecondaryAttack()
  return false
end

--[[---------------------------------------------------------
  Name: ShouldDropOnDie
  Desc: Should this weapon be dropped when its owner dies?
-----------------------------------------------------------]]
function SWEP:ShouldDropOnDie()
  return false
end

--[[---------------------------------------------------------
  Think does nothing
-----------------------------------------------------------]]

function SWEP:GetBeamMaterial(bool)
  local user = self:GetOwner()
  local matc = self.roMaterial
  local matr = user:GetInfo(gsPref.."material")
  if(bool) then
    if(matc) then
      if(matc:GetName() ~= matr) then
        matc = Material(matr)
      end
    else matc = Material(matr) end
    self.roMaterial = matc; return matc
  else
    return matr
  end
end

function SWEP:GetOn()
  local user = self:GetOwner()
  return user:KeyDown(IN_ATTACK)
end

function SWEP:GetBeamColorRGBA(bcol)
  local user = self:GetOwner()
  local m = LaserLib.GetData("CLMX")
  local r = math.Clamp(user:GetInfoNum(gsPref.."colorr", 0), 0 , 255)
  local g = math.Clamp(user:GetInfoNum(gsPref.."colorg", 0), 0 , 255)
  local b = math.Clamp(user:GetInfoNum(gsPref.."colorb", 0), 0 , 255)
  local a = math.Clamp(user:GetInfoNum(gsPref.."colora", 0), 0 , 255)
  if(bcol) then local c = self.roColor
    if(not c) then c = Color(0,0,0,0); self.roColor = c end
    c.r, c.g, c.b, c.a = r, g, b, a; return c
  else -- The user requests four numbers instead
    return r, g, b, a
  end
end

function SWEP:UpdateFlags()
  local time = CurTime()

  self.isEffect = false -- Reset the frame effects
  if(not self.nxEffect or time > self.nxEffect) then
    local dt = EFFECTDT:GetFloat() -- Read configuration
    self.isEffect, self.nxEffect = true, time + dt
  end

  if(SERVER) then -- Damage exists only on the server
    self.isDamage = false -- Reset the frame damage
    if(not self.nxDamage or time > self.nxDamage) then
      local dt = DAMAGEDT:GetFloat() -- Read configuration
      self.isDamage, self.nxDamage = true, time + dt
    end
  end
end

--[[
 * Registers a trace hit report under the specified index
 * trace > Trace result structure to register
 * data  > Beam data structure to register
]]
function SWEP:SetHitReport(trace, data)
  if(not self.hitReports) then self.hitReports = {Size = 0} end
  local rep, idx = self.hitReports, data.BmIdenty
  if(idx >= rep.Size) then rep.Size = idx end
  if(not rep[idx]) then rep[idx] = {} end; rep = rep[idx]
  rep["DT"] = data; rep["TR"] = trace; return self
end

--[[
 * Retrieves hit report trace and data under specified index
 * index > Hit report index to read ( defaults to 1 )
]]
function SWEP:GetHitReport(index)
  if(not index) then return end
  if(not self.hitReports) then return end
  local rep = self.hitReports[index]
  if(not rep) then return end
  return rep["TR"], rep["DT"]
end

function SWEP:GetStopSound()
  return self:GetOwner():GetInfo(gsPref.."stopsound")
end

function SWEP:GetKillSound()
  return self:GetOwner():GetInfo(gsPref.."killsound")
end

function SWEP:GetStartSound()
  return self:GetOwner():GetInfo(gsPref.."startsound")
end

function SWEP:GetDissolveType()
  return self:GetOwner():GetInfo(gsPref.."dissolvetype")
end

function SWEP:GetNonOverMater()
  return (self:GetOwner():GetInfoNum(gsPref.."enonvermater", 0) ~= 0)
end

function SWEP:GetRefractRatio()
  return (self:GetOwner():GetInfoNum(gsPref.."refractrate", 0) ~= 0)
end

function SWEP:GetReflectRatio()
  return (self:GetOwner():GetInfoNum(gsPref.."reflectrate", 0) ~= 0)
end

function SWEP:GetForceCenter()
  return (self:GetOwner():GetInfoNum(gsPref.."forcecenter", 0) ~= 0)
end

function SWEP:GetEndingEffect()
  return (self:GetOwner():GetInfoNum(gsPref.."endingeffect", 0) ~= 0)
end

function SWEP:GetBeamWidth()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."width", 0), 0, MXBMWIDT:GetFloat())
end

function SWEP:GetBeamDamage()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."damage", 0), 0, MXBMDAMG:GetFloat())
end

function SWEP:GetBeamLength()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."length", 0), 0, MXBMLENG:GetFloat())
end

function SWEP:GetBeamForce()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."pushforce", 0), 0, MXBMFORC:GetFloat())
end

function SWEP:DoBeam(origin, direct)
  local user = self:GetOwner()
  local width  = self:GetBeamWidth()
  local damage = self:GetBeamDamage()
  local length = self:GetBeamLength()
  local force  = self:GetBeamForce()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local noverm = self:GetNonOverMater()
  local trace, data = LaserLib.DoBeam(user,
                                      origin,
                                      direct,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm)
  return trace, data
end

function SWEP:ServerBeam()
  self:UpdateFlags()

  if(self:GetOn()) then
    local user = self:GetOwner()
    local vorg = user:EyePos()
    local vdir = user:GetAimVector()

    LaserLib.Bounces(1)

    local trace, data = self:DoBeam(vorg, vdir)
    if(data and trace and
      LaserLib.IsValid(trace.Entity) and not
      LaserLib.IsUnit(trace.Entity)
    ) then

    local user = self:GetOwner()
    local fcen = self:GetForceCenter()
    local dtyp = self:GetDissolveType()
    local ssnd = self:GetStopSound()
    local ksnd = self:GetKillSound()

    LaserLib.DoDamage(trace.Entity,
                      trace.HitPos,
                      trace.Normal,
                      data.VrDirect,
                      data.NvDamage,
                      data.NvForce,
                      user,
                      LaserLib.GetDissolveID(dtyp),
                      ksnd,
                      fcen,
                      self)
    end
  end
end

if(SERVER) then

  function SWEP:Think()
    self:ServerBeam()
    self:NextThink(CurTime())
    return true
  end

else

  function SWEP:DrawBeam(origin, direct)
    self:UpdateFlags()
    LaserLib.Bounces(1)

    local trace, data = self:DoBeam(origin, direct)
    if(not data) then return end
    if(not trace) then return end

    local eeff = self:GetEndingEffect()
    local matr = self:GetBeamMaterial(true)
    local colr = self:GetBeamColorRGBA(true)

    data:Draw(self, matr, colr)
    data:DrawEffect(self, trace, eeff)
  end

  function SWEP:GetBeamDrawRay(mussle, udotp)
    if(not mussle) then return end
    local musfwd = mussle.Ang:Forward()
    local hitpos = self:GetOwner():GetEyeTrace().HitPos
    local direct = self.MD; direct:Set(hitpos)
    local origin = self.MO; origin:Set(mussle.Pos)
          direct:Sub(origin)
          direct:Normalize()
    return origin, direct
  end

  -- How the local player sees the laser pistol
  function SWEP:PreDrawViewModel()
    self:DrawModel()
    if(self:GetOn()) then
      if(not (self.VM and self.VA)) then return end
      local mussle = self.VM:GetAttachment(self.VA)
      local org, dir = self:GetBeamDrawRay(mussle)
      if(not org) then return end
      self:DrawBeam(org, dir)
    end
  end

  -- How others players see the laser pistol
  function SWEP:DrawWorldModel()
    self:DrawModel()
    if(self:GetOn()) then
      if(not self.WA) then return end
      local mussle = self:GetAttachment(self.WA)
      if(not mussle) then return end
      local org, dir = self:GetBeamDrawRay(mussle, true)
      if(not org) then return end
      self:DrawBeam(org, dir)
    end
  end

end