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
local cvWDHUECNT = LaserLib.GetData("WDHUECNT")
local cvMXFRESNE = LaserLib.GetData("MXFRESNE")
local cvMXBMDAMG = LaserLib.GetData("MXBMDAMG")
local cvMXBMWIDT = LaserLib.GetData("MXBMWIDT")
local cvMXBMFORC = LaserLib.GetData("MXBMFORC")
local cvMXBMLENG = LaserLib.GetData("MXBMLENG")

if(SERVER) then
  resource.AddFile("materials/vgui/entities/gmod_laser_rifle.vmt")
end

function SWEP:Setup()
  if(CLIENT) then
    local rtab = self:GetTable()
    local user = self:GetOwner()
    local vMO, wMO = user:GetViewModel(), self
    if(LaserLib.IsValid(vMO)) then
      local vID = vMO:LookupAttachment("muzzle")
      if(vID == 0) then vID = vMO:LookupAttachment("1") end
      if(user:GetAttachment(vID)) then
        rtab.VM = vMO
        rtab.VI = vID
        print("VM:VI", rtab.VM, rtab.VI)
      end
    end
    if(LaserLib.IsValid(wMO)) then
      local wID = wMO:LookupAttachment("muzzle")
      if(wID == 0) then wID = wMO:LookupAttachment("1") end
      if(user:GetAttachment(wID)) then
        rtab.WM = wMO
        rtab.WI = wID
        print("WM:WI", rtab.WM, rtab.WI)
      end
    end
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
  if(not user) then return false end
  if(not user:IsValid()) then return false end
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

function SWEP:GetBeamIgnite()
  return (self:GetOwner():GetInfoNum(gsPref.."enignebeam", 0) ~= 0)
end

function SWEP:GetBeamDisperse()
  return (cvWDHUECNT:GetInt() > 0)
end

function SWEP:GetBeamFresnel()
  return (cvMXFRESNE:GetInt() > 0)
end

function SWEP:GetBeamOrigin()
  local user = self:GetOwner()
  return user:LocalToWorld(user:OBBCenter())
end

function SWEP:GetBeamDirect()
  local user = self:GetOwner()
  local vorg = self:GetBeamOrigin()
  local vdir = user:GetEyeTrace().HitPos
        vdir:Sub(vorg); vdir:Normalize()
  return vdir
end

function SWEP:DoBeam()
  local origin = self:GetBeamOrigin()
  local direct = self:GetBeamDirect()
  local width  = self:GetBeamWidth()
  local length = self:GetBeamLength()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local noverm = self:GetNonOverMater()
  local fresne = self:GetBeamFresnel()
  local disper = self:GetBeamDisperse()
  local r, g, b, a = self:GetBeamColorRGBA()
  local beam = LaserLib.Beam(origin, direct, length)
        beam:SetSource(self:GetOwner(), self)
        beam:SetWidth(LaserLib.GetWidth(width))
        beam:SetDamage(self:GetBeamDamage())
        beam:SetForce(self:GetBeamForce())
        beam:SetFgDivert(usrfle, usrfre)
        beam:SetFgTexture(noverm, disper, fresne)
        beam:SetBounces(1)
        beam:SetFresnel(0)
        beam:SetColorRGBA(r, g, b, a)
  if(not beam:IsValid() and SERVER) then
    beam:Clear(); self:Remove(); return end
  return beam:Run()
end

if(SERVER) then

  function SWEP:OverrideOnRemove()
    -- Does nothing
  end

  function SWEP:ServerBeam()
    self:UpdateInit()

    if(not self:GetOn()) then return end
    local beam = self:DoBeam()
    if(not beam) then return end
    local trace = beam:GetTarget()
    if(not trace) then return end
    if(trace.StartSolid) then return end
    local ueye = self:GetOwner():EyePos()
    ueye:Sub(trace.HitPos)
    if(ueye:LengthSqr() < 1500) then return end
    beam:DoDamage(self)
  end

  function SWEP:Think()
    self:ServerBeam()
    self:NextThink(CurTime())
    return true
  end

else

  function SWEP:DrawBeam(org, src)
    self:UpdateInit()
    -- Calculate beam path
    local beam = self:DoBeam()
    if(not beam) then return end
    local trace = beam:GetTarget()
    if(not trace) then return end
    if(trace.StartSolid) then return end
    -- Cut off when looking at a wall
    local ueye = self:GetOwner():EyePos()
    ueye:Sub(trace.HitPos)
    if(ueye:LengthSqr() < 1500) then return end
    -- Modify the first node
    local tvp, siz = beam:GetPoints() -- Mark segment
    print("SZ", src, siz)
    if(siz < 1) then return end
    beam:GetNode(1)[1]:Set(org)
    beam:GetNode(1)[5] = false
    if(siz >= 2) then beam:GetNode(2)[1]:Set(org) end
    -- Read visuals
    local eeff = self:GetEndingEffect()
    local matr = self:GetBeamMaterial(true)
    local colr = self:GetBeamColorRGBA(true)
    -- Draw beam
    beam:Draw(self, matr, colr)
    beam:DrawEffect(self, eeff)
  end

  -- How the local player sees the laser rifle
  function SWEP:PreDrawViewModel()
    self:DrawModel()
    if(not self:GetOn()) then return end
    local rtab = self:GetTable()
    if(not (rtab.VM and rtab.VI)) then return end
    local muss = rtab.VM:GetAttachment(rtab.VI)
    if(not muss) then return end
    LaserLib.DrawPoint(muss.Pos + Vector(0,0,7))
    self:DrawBeam(muss.Pos, "V")
  end

  -- How others players see the laser rifle
  function SWEP:DrawWorldModel()
    self:DrawModel()
    if(not self:GetOn()) then return end
    local rtab = self:GetTable()
    if(not (rtab.WM and rtab.WI)) then return end
    local muss = rtab.WM:GetAttachment(rtab.WI)
    if(not muss) then return end
    LaserLib.DrawPoint(muss.Pos + Vector(0,0,10))
    self:DrawBeam(muss.Pos, "W")
  end

end
