ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Divider Recursive"
ENT.Information    = ENT.Category.." "..ENT.PrintName
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.Information
else
  ENT.Base          = "base_entity"
end
ENT.Editable       = true
ENT.Purpose        = "Divides incoming beam into pass-trough and reflected"
ENT.Instructions   = "Position this entity on the incoming beam path"
ENT.Author         = "DVD"
ENT.Contact        = "dvdvideo123@gmail.com"
ENT.Spawnable      = false
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH
ENT.UnitID         = 0

include(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

local gnDOTM = LaserLib.GetData("DOTM")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  LaserLib.Configure(self)
  self.hitSources = {}
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:GetOn()
  local src = self.hitSources
  if(not src) then return false end
  LaserLib.Print("ON:", table.IsEmpty(src))
  return (not table.IsEmpty(src))
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

function ENT:GetHitPower(normal, beam, trace)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - gnDOTM))
end

function ENT:DoBeam(org, dir, bmex)
  if(self.RecuseBeamID > 10) then
    self.RecuseBeamID = 0
    self:SetHitReportMax()
    LaserLib.Print("Limit reached")
  end
  self.RecuseBeamID = self.RecuseBeamID + 1
  LaserLib.Print("Beam", self.RecuseBeamID, bmex.BmRecstg, bmex.TeFilter)
  local todiv  = (self:GetBeamReplicate() and 1 or 2)
  local beam   = LaserLib.Beam(org, dir, bmex.NvLength)
        beam:SetSource(self, bmex:GetSource())
        beam:SetWidth(LaserLib.GetWidth(bmex.NvWidth / todiv))
        beam:SetDamage(bmex.NvDamage / todiv)
        beam:SetForce(bmex.NvForce  / todiv)
        beam:SetFgDivert(bmex.BrReflec, bmex.BrRefrac)
        beam:SetFgTexture(bmex.BmNoover, false)
        beam:SetBounces()
  if(not beam:IsValid() and SERVER) then
    beam:Clear(); self:Remove(); return end
  return beam:Run(self.RecuseBeamID, bmex.BmRecstg)
end

