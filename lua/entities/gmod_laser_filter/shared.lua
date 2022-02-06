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

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupDataTables()
  local material = list.Get("LaserEmitterMaterials"); material["Empty"] = ""
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  self:EditableSetBool  ("BeamPowerClamp", "General")
  self:EditableSetBool  ("BeamPassTexture", "General")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetStringCombo("InBeamMaterial", "Internals", material)
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetFloat("BeamAlpha", "Visuals", 0, LaserLib.GetData("CLMX"))
  self:EditableRemoveOrderInfo()
end

--[[ ----------------------
      Handling color setup and conversion
---------------------- ]]
function ENT:SetBeamColorRGBA(mr, mg, mb, ma)
  local m = LaserLib.GetData("CLMX")
  local v, a = Vector(), m
  if(istable(mr)) then
    v.x = ((mr[1] or mr["r"] or m) / m)
    v.y = ((mr[2] or mr["g"] or m) / m)
    v.z = ((mr[3] or mr["b"] or m) / m)
      a =  (mr[4] or mr["a"] or m)
  else
    v.x = ((mr or m) / m) -- [0-1]
    v.y = ((mg or m) / m) -- [0-1]
    v.z = ((mb or m) / m) -- [0-1]
      a =  (ma or m) -- [0-255]
  end
  self:SetBeamColor(v)
  self:SetBeamAlpha(a)
end

function ENT:GetBeamColorRGBA(bcol)
  local m = LaserLib.GetData("CLMX")
  local v = self:GetBeamColor()
  local a = self:GetBeamAlpha()
  local r, g, b = (v.x * m), (v.y * m), (v.z * m)
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

function ENT:GetHitPower(normal, trace, beam)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - dotm))
end
