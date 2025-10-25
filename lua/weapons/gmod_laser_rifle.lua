-- Instructions and info
SWEP.Author                 = "DVD"
SWEP.Contact                = "dvd_video@abv.bg"
SWEP.Purpose                = "The laser power in your hands"
SWEP.Instructions           = "Primary attack to shoot a laser beam"
SWEP.Category               = LaserLib.GetData("CATG")
SWEP.PrintName              = SWEP.Category.." Rifle"
SWEP.Information            = SWEP.PrintName
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
SWEP.ViewModel              = "models/weapons/c_irifle.mdl"
SWEP.WorldModel             = "models/weapons/w_irifle.mdl"
-- Primary setup
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

local gtAMAX     = LaserLib.GetData("AMAX")
local gnCLMX     = LaserLib.GetData("CLMX")
local cvWDHUESTP = LaserLib.GetData("WDHUESTP")
local cvMXBMDAMG = LaserLib.GetData("MXBMDAMG")
local cvMXBMWIDT = LaserLib.GetData("MXBMWIDT")
local cvMXBMFORC = LaserLib.GetData("MXBMFORC")
local cvMXBMLENG = LaserLib.GetData("MXBMLENG")

if(SERVER) then
  resource.AddFile("materials/vgui/entities/gmod_laser_rifle.vmt")
end

function SWEP:Setup()
  if(CLIENT) then
    local cass = self:GetClass()
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
  self:SetHoldType("ar2")
  LaserLib.Configure(self)
end

function SWEP:Initialize()
  self:Setup()
end

function SWEP:Deploy()
  self:Setup()
end

--[[
 * Reload does nothing
]]
function SWEP:Reload()
  return false
end

--[[
 * PrimaryAttack
]]
function SWEP:PrimaryAttack()
  return false
end

--[[
 * SecondaryAttack
]]
function SWEP:SecondaryAttack()
  return false
end

--[[
 * Name: ShouldDropOnDie
 * Desc: Should this weapon be dropped when its owner dies?
]]
function SWEP:ShouldDropOnDie()
  return false
end

--[[
 * Think does nothing
]]

function SWEP:GetBeamMaterial(bool)
  local user = self:GetOwner()
  local matr = user:GetInfo(gsPref.."material")
  if(bool) then
    local matc = self.roMaterial
    if(matc) then
      if(matc:GetName() ~= matr) then
        matc = Material(matr)
        self.roMaterial = matc
      end
    else
      matc = Material(matr)
      self.roMaterial = matc
    end; return matc
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
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."width", 0), 0, cvMXBMWIDT:GetFloat())
end

function SWEP:GetBeamDamage()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."damage", 0), 0, cvMXBMDAMG:GetFloat())
end

function SWEP:GetBeamLength()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."length", 0), 0, cvMXBMLENG:GetFloat())
end

function SWEP:GetBeamForce()
  return math.Clamp(self:GetOwner():GetInfoNum(gsPref.."pushforce", 0), 0, cvMXBMFORC:GetFloat())
end

function SWEP:GetBeamSafety()
  return (self:GetOwner():GetInfoNum(gsPref.."ensafebeam", 0) ~= 0)
end

function SWEP:GetBeamOrigin()
  local user = self:GetOwner()
  local vorg = user:GetCurrentViewOffset()
  local vobb = user:LocalToWorld(user:OBBCenter())
        vorg:Mul(4); vorg:Add(vobb)
  return vorg
end

function SWEP:GetBeamDirect()
  local user = self:GetOwner()
  local vorg = self:GetBeamOrigin()
  local vdir = user:GetEyeTrace().HitPos
        vdir:Sub(vorg); vdir:Normalize()
  return vdir
end

function SWEP:DoBeam(origin, direct)
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local noverm = self:GetNonOverMater()
  local r, g, b, a = self:GetBeamColorRGBA()
  local disper = (cvWDHUESTP:GetFloat() > 0)
  local beam = LaserLib.Beam(origin, direct, self:GetBeamLength())
        beam:SetSource(self:GetOwner(), self)
        beam:SetWidth(LaserLib.GetWidth(self:GetBeamWidth()))
        beam:SetDamage(self:GetBeamDamage())
        beam:SetForce(self:GetBeamForce())
        beam:SetFgDivert(usrfle, usrfre)
        beam:SetFgTexture(noverm, disper)
        beam:SetBounces(1)
        beam:SetColorRGBA(r, g, b, a)
  if(not beam:IsValid() and SERVER) then
    beam:Clear(); self:Remove(); return end
  return beam:Run()
end

function SWEP:ServerBeam()
  self:UpdateInit()

  if(self:GetOn()) then
    local vorg = self:GetBeamOrigin()
    local vdir = self:GetBeamDirect()
    local beam = self:DoBeam(vorg, vdir)
    if(not beam) then return end
    local trace = beam:GetTarget()
    if(trace.StartSolid) then return end
    local ueye = self:GetOwner():EyePos()
    local dist = (trace.HitPos - ueye):LengthSqr()
    if(dist < 1500) then return end
    beam:DoDamage(self)
  end
end

if(SERVER) then

  function SWEP:OverrideOnRemove()
    -- Does nothing
  end

  function SWEP:Think()
    self:ServerBeam()
    self:NextThink(CurTime())
    return true
  end

else

  function SWEP:DrawBeam(origin, direct)
    self:UpdateInit()

    local beam = self:DoBeam(origin, direct)
    if(not beam) then return end
    local trace = beam:GetTarget()
    if(trace.StartSolid) then return end
    local ueye = self:GetOwner():EyePos()
    local dist = (trace.HitPos - ueye):LengthSqr()
    if(dist < 1500) then return end

    local eeff = self:GetEndingEffect()
    local matr = self:GetBeamMaterial(true)
    local colr = self:GetBeamColorRGBA(true)

    beam:Draw(self, matr, colr)
    beam:DrawEffect(self, eeff)
  end

  function SWEP:GetBeamRay(mussle)
    if(not mussle) then return end
    local hitpos = self:GetOwner():GetEyeTrace().HitPos
    local direct = self.MD; direct:Set(hitpos)
    local origin = self.MO; origin:Set(mussle.Pos)
          direct:Sub(origin)
          direct:Normalize()
    return origin, direct
  end

  -- How the local player sees the laser rifle
  function SWEP:PreDrawViewModel()
    self:DrawModel()
    if(self:GetOn()) then
      if(not (self.VM and self.VA)) then return end
      local mussle = self.VM:GetAttachment(self.VA)
      local org, dir = self:GetBeamRay(mussle)
      if(not org) then return end
      self:DrawBeam(org, dir)
    end
  end

  -- How others players see the laser rifle
  function SWEP:DrawWorldModel()
    self:DrawModel()
    if(self:GetOn()) then
      if(not self.WA) then return end
      local mussle = self:GetAttachment(self.WA)
      if(not mussle) then return end
      local org, dir = self:GetBeamRay(mussle)
      if(not org) then return end
      self:DrawBeam(org, dir)
    end
  end

end
