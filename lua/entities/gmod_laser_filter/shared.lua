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

local DOTM     = LaserLib.GetData("DOTM")
local CLMX     = LaserLib.GetData("CLMX")
local MXBMWIDT = LaserLib.GetData("MXBMWIDT")
local MXBMLENG = LaserLib.GetData("MXBMLENG")
local MXBMDAMG = LaserLib.GetData("MXBMDAMG")
local MXBMFORC = LaserLib.GetData("MXBMFORC")

function ENT:SetupDataTables()
  local material = list.Get("LaserEmitterMaterials"); material["Empty"] = ""
  self:EditableSetVector("NormalLocal"  , "General") -- Used as normal
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("BeamPowerClamp", "General")
  self:EditableSetBool  ("BeamPassEnable", "General")
  self:EditableSetBool  ("BeamPassTexture", "General")
  self:EditableSetBool  ("BeamPassColor", "General")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, MXBMWIDT:GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, MXBMLENG:GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, MXBMDAMG:GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, MXBMFORC:GetFloat())
  local maticons = table.Copy(material)
  for k, v in pairs(maticons) do maticons[k] = ((k == "Empty") and "stop" or "picture_edit") end
  self:EditableSetStringCombo("InBeamMaterial", "Internals", material, nil, maticons)
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetFloat("BeamAlpha", "Visuals", 0, CLMX)
  LaserLib.Configure(self)
end

--[[
 * Handling color setup and conversion
]]
function ENT:SetBeamColorRGBA(mr, mg, mb, ma)
  local v, a = Vector(), CLMX
  if(istable(mr)) then
    v.x = LaserLib.GetNumber(3, mr[1], mr["r"], CLMX) / CLMX
    v.y = LaserLib.GetNumber(3, mr[2], mr["g"], CLMX) / CLMX
    v.z = LaserLib.GetNumber(3, mr[3], mr["b"], CLMX) / CLMX
      a = LaserLib.GetNumber(3, mr[4], mr["a"], CLMX)
  else
    v.x = LaserLib.GetNumber(2, mr, CLMX) / CLMX -- [0-1]
    v.y = LaserLib.GetNumber(2, mg, CLMX) / CLMX -- [0-1]
    v.z = LaserLib.GetNumber(2, mb, CLMX) / CLMX -- [0-1]
      a = LaserLib.GetNumber(2, ma, CLMX) -- [0-255]
  end
  self:SetBeamColor(v)
  self:SetBeamAlpha(a)
end

function ENT:GetBeamColorRGBA(bcol)
  local v = self:GetBeamColor()
  local a = self:GetBeamAlpha()
  local r, g, b = (v.x * CLMX), (v.y * CLMX), (v.z * CLMX)
  if(bcol) then local c = self.roColor
    if(not c) then c = Color(0,0,0,0); self.roColor = c end
    c.r, c.g, c.b, c.a = r, g, b, a; return c
  else -- The user requests four numbers instead
    return r, g, b, a
  end
end

-- Override the beam transormation
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
    return self:GetNWFloat("GetNormalLocal", normal)
  end
end

function ENT:GetHitPower(normal, beam, trace)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - DOTM))
end
