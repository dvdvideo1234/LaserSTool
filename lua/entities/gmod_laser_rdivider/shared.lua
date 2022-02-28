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
ENT.Spawnable      = true
ENT.AdminSpawnable = true
ENT.RenderGroup    = RENDERGROUP_BOTH

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/report_manager.lua")
include(LaserLib.GetTool().."/report_manager.lua")

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal"  , "General") -- Used as forward
  self:EditableSetBool  ("BeamReplicate", "General")
  LaserLib.ClearOrder(self)
  self.ixBeam = 0
  self.hitSources = {}
end

function ENT:GetOn()
  local src = self.hitSources
  if(not src) then return false end
  print("ON:", table.IsEmpty(src))
  return (not table.IsEmpty(src))
end

-- Override the beam transormation
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
    return self:GetNWFloat("GetNormalLocal", normal)
  end
end

function ENT:GetHitPower(normal, beam, trace)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - dotm))
end

function ENT:PostProcess(ent)
  print("PostProcess", self.ixBeam)
  self:SetHitReportMax(self.ixBeam)
   self.ixBeam = 0
end

function ENT:RegisterSource(ent)
  if(not self.hitSources) then return self end
  self.hitSources[ent] = true; return self
end

function ENT:DoBeam(org, dir, bmex)
  self.ixBeam = self.ixBeam + 1
  LaserLib.SetExSources(self, bmex:GetSource())
  LaserLib.SetExLength(bmex.BmLength)
  local length = bmex.NvLength
  local usrfle = bmex.BrReflec
  local usrfre = bmex.BrRefrac
  local noverm = bmex.BmNoover
  local todiv  = (self:GetBeamReplicate() and 1 or 2)
  local damage = bmex.NvDamage / todiv
  local force  = bmex.NvForce  / todiv
  local width  = LaserLib.GetWidth(bmex.NvWidth / todiv)
  local beam, trace = LaserLib.DoBeam(self,
                                      org,
                                      dir,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm,
                                      self.ixBeam)
  return beam, trace
end

function ENT:SetActor()
  LaserLib.SetActor(self, function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm = ent:GetHitNormal()
    local bdot = ent:GetHitPower(norm, beam, trace)
    if(trace and trace.Hit and bdot) then
      local aim, nrm = beam.VrDirect, trace.HitNormal
      local ray = LaserLib.GetReflected(aim, nrm)
      if(SERVER) then
        ent:DoDamage(ent:DoBeam(trace.HitPos, aim, beam))
        ent:DoDamage(ent:DoBeam(trace.HitPos, ray, beam))
      else
        ent:DrawBeam(ent:DoBeam(trace.HitPos, aim, beam))
        ent:DrawBeam(ent:DoBeam(trace.HitPos, ray, beam))
      end
    end
  end)
end

function ENT:Think()



  LaserLib.Call(2, function()
    print("A----------", src)
    print("SRC", self.hitSources)
    print("REP", self.hitReports)

    -- PrintTable(self.hitReports)

    LaserLib.PrintOn()
  end)


  self:ProcessSources()
  self:NextThink(CurTime())
end
