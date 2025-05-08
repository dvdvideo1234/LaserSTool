ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Filter"
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
ENT.UnitID         = 11

LaserLib.RegisterUnit(ENT, "models/props_c17/frame002a.mdl", "models/props_combine/citadel_cable")

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

local gnDOTM     = LaserLib.GetData("DOTM")
local gnCLMX     = LaserLib.GetData("CLMX")
local cvMXBMWIDT = LaserLib.GetData("MXBMWIDT")
local cvMXBMLENG = LaserLib.GetData("MXBMLENG")
local cvMXBMDAMG = LaserLib.GetData("MXBMDAMG")
local cvMXBMFORC = LaserLib.GetData("MXBMFORC")

function ENT:SetupDataTables()
  local material = list.Get("LaserEmitterMaterials"); material["<Empty>"] = {name = "", icon = "stop"}
  self:EditableSetVector("NormalLocal"  , "General") -- Used as normal
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("BeamPowerClamp", "General")
  self:EditableSetBool  ("BeamPassEnable", "General")
  self:EditableSetBool  ("BeamPassTexture", "General")
  self:EditableSetBool  ("BeamPassColor", "General")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, cvMXBMWIDT:GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, cvMXBMLENG:GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, cvMXBMDAMG:GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, cvMXBMFORC:GetFloat())
  self:EditableSetStringCombo("InBeamMaterial", "Internals", material, "name", "icon")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetFloat("BeamAlpha", "Visuals", 0, gnCLMX)
  LaserLib.Configure(self)
end

--[[
 * Handling color setup and conversion
]]
function ENT:SetBeamColorRGBA(mr, mg, mb, ma)
  local v, a, m = Vector(), gnCLMX, gnCLMX
  if(istable(mr)) then
    v.x = math.Clamp(LaserLib.GetNumber(3, mr[1], mr["r"], m), 0, m) / m
    v.y = math.Clamp(LaserLib.GetNumber(3, mr[2], mr["g"], m), 0, m) / m
    v.z = math.Clamp(LaserLib.GetNumber(3, mr[3], mr["b"], m), 0, m) / m
      a = math.Clamp(LaserLib.GetNumber(3, mr[4], mr["a"], m), 0, m)
  else
    v.x = math.Clamp(LaserLib.GetNumber(2, mr, m), 0, m) / m -- [0-1]
    v.y = math.Clamp(LaserLib.GetNumber(2, mg, m), 0, m) / m -- [0-1]
    v.z = math.Clamp(LaserLib.GetNumber(2, mb, m), 0, m) / m -- [0-1]
      a = math.Clamp(LaserLib.GetNumber(2, ma, m), 0, m) -- [0-255]
  end
  self:SetBeamColor(v)
  self:SetBeamAlpha(a)
end

function ENT:GetBeamColorRGBA(bcol)
  local v = self:GetBeamColor()
  local a = self:GetBeamAlpha()
  local r, g, b = (v.x * gnCLMX), (v.y * gnCLMX), (v.z * gnCLMX)
  if(bcol) then local c = self.roColor
    if(not c) then c = Color(0,0,0,0); self.roColor = c end
    c.r, c.g, c.b, c.a = r, g, b, a; return c
  else -- The user requests four numbers instead
    return r, g, b, a
  end
end

-- Override the beam transformation
function ENT:SetBeamTransform()
  local normal = Vector(1,0,0) -- Local surface direction
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

function ENT:GetHitPower(normal, beam, trace)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - gnDOTM))
end
