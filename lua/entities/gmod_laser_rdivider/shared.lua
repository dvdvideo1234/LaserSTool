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
  self.meSources = {}
end

function ENT:RegisterSource(ent)
  if(not self.meSources) then return self end
  self.meSources[ent] = true; return self
end

function ENT:GetOn()
  local src = self.meSources
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

function ENT:DoBeam(org, dir, bmsr)
  if(self.RecuseBeamID > 10) then
    self.RecuseBeamID = 0
    self:SetHitReportMax()
    LaserLib.Print("Limit reached")
  end
  self.RecuseBeamID = self.RecuseBeamID + 1
  LaserLib.Print("Beam", self.RecuseBeamID, bmsr.BmRecstg, bmsr.TeFilter)
  local todiv  = (self:GetBeamReplicate() and 1 or 2)
  local beam   = LaserLib.Beam(org, dir, bmsr.NvLength)
        beam:SetSource(self, bmsr:GetSource())
        beam:SetWidth(LaserLib.GetWidth(bmsr.NvWidth / todiv))
        beam:SetDamage(bmsr.NvDamage / todiv)
        beam:SetForce(bmsr.NvForce  / todiv)
        beam:SetFgDivert(bmsr.BrReflec, bmsr.BrRefrac)
        beam:SetFgTexture(bmsr.BmNoover, false)
        beam:SetBounces()
  if(not beam:IsValid() and SERVER) then
    beam:Clear(); self:Remove(); return end
  return beam:Run(self.RecuseBeamID, bmsr.BmRecstg)
end

