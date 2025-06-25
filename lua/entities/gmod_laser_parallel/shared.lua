ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Parallel"
ENT.Information    = ENT.Category.." "..ENT.PrintName
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.Information
else
  ENT.Base          = "base_entity"
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 10

LaserLib.RegisterUnit(ENT, "models/props_c17/furnitureshelf001b.mdl", "models/dog/eyeglass")

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

local gnDOTM = LaserLib.GetData("DOTM")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal", "General") -- Used as forward
  self:EditableSetBool  ("BeamDimmer" , "General")
  self:EditableSetBool  ("LinearMapping", "General")
  self:EditableSetFloat ("FocusMargin" , "General", -1, 1)
  self:EditableSetBool  ("DeviateRandom", "General")
  self:EditableSetFloat ("DeviationX" , "General", -180, 180)
  self:EditableSetFloat ("DeviationY" , "General", -180, 180)
  LaserLib.Configure(self)
end

-- Override the beam transformation
function ENT:SetBeamTransform()
  local normal = Vector(0,0,1) -- Local surface direction
  self:SetNormalLocal(normal)
  return self
end

function ENT:GetHitNormal()
  if(SERVER) then
    local normal = self:WireRead("Normal", true)
    if(normal) then normal:Normalize() else
      normal = self:GetNormalLocal()
    end -- Make sure length is one unit
    self:SetNWVector("GetNormalLocal", normal)
    self:WireWrite("Normal", normal)
    return normal
  else
    local normal = self:GetNormalLocal()
    return self:GetNWVector("GetNormalLocal", normal)
  end
end

function ENT:GetFocus()
  if(SERVER) then
    local focus = self:WireRead("Focus", true)
    if(not focus) then
      focus = self:GetFocusMargin()
    end -- Make sure length is one unit
    self:SetNWFloat("GetFocusMargin", focus)
    self:WireWrite("Focus", focus)
    return focus
  else
    local focus = self:GetFocusMargin()
    return self:GetNWFloat("GetFocusMargin", normal)
  end
end

function ENT:GetDeviation()
  if(SERVER) then
    local wx = self:WireRead("DeviateX", true)
    if(not wx) then wx = self:GetDeviationX() end
    local wy = self:WireRead("DeviateY", true)
    if(not wy) then wy = self:GetDeviationY() end
    self:SetNWFloat("GetDeviationX", wx)
    self:SetNWFloat("GetDeviationY", wy)
    self:WireWrite("DeviateX", wx)
    self:WireWrite("DeviateY", wy)
    return wx, wy
  else
    local wx = self:GetNWFloat("GetDeviationX", self:GetDeviationX())
    local wy = self:GetNWFloat("GetDeviationY", self:GetDeviationY())
    return wx, wy
  end
end

function ENT:GetHitPower(normal, beam, trace, bmln)
  local norm = Vector(normal); norm:Rotate(self:GetAngles())
  local dotv = math.abs(norm:Dot(beam.VrDirect))
  if(bmln) then dotv = 2 * math.asin(dotv) / math.pi end
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - gnDOTM)), dotv
end

