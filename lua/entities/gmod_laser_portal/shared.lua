ENT.Type           = "anim"
ENT.Category       = "Laser"
ENT.PrintName      = "Portal"
ENT.Information    = ENT.Category.." "..ENT.PrintName
ENT.Base           = LaserLib.GetClass(1, 1)
if(WireLib) then
  ENT.WireDebugName = ENT.Information
end
ENT.Editable       = true
ENT.Author         = "DVD"
ENT.Spawnable      = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
  self:EditableSetVector("NormalLocal" , "General") -- Used as forward
  self:EditableSetBool("MirrorExitPos" , "General") -- Mirror the exit ray location
  self:EditableSetBool("ReflectExitDir", "General") -- Reflect the exit ray direction
  self:EditableSetBool("InPowerOn"     , "Internals")
  self:EditableSetStringGeneric("InEntityID", "Internals")
  self:EditableRemoveOrderInfo()
end

function ENT:RegisterSource(ent)
  self.hitSources[ent] = true; return self
end

-- Override the beam transormation
function ENT:SetBeamTransform()
  local normal = Vector(1,0,0) -- Local surface normal
  self:SetNormalLocal(normal)
  return self
end

function ENT:InitSources()
  self.hitSize = 0
  if(CLIENT) then
    if(not self.hitSources) then
      self.hitArray   = {} -- Array to output for wiremod
      self.hitSources = {} -- Sources in notation `[ent] = true`
    end
  else
    if(self.hitSources) then
      table.Empty(self.hitSources)
      table.Empty(self.hitArray)
    else
      self.hitArray   = {} -- Array to output for wiremod
      self.hitSources = {} -- Sources in notation `[ent] = true`
    end
  end
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

function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
  self:WireWrite("On", (state and 1 or 0))
  return self
end

function ENT:GetOn()
  local state = self:GetInPowerOn()
  if(SERVER) then self:DoSound(state) end
  return state
end

function ENT:SetEntityID(idx)
  local idx = (tonumber(idx) or 0)
  self:SetInEntityID(tostring(idx))
  return self
end

function ENT:GetEntityID(bupd)
  local idx = self:GetInEntityID()
  idx = (tonumber(idx) or 0)
  return idx
end

function ENT:IsHitNormal(trace)
  local normal = Vector(self:GetHitNormal())
        normal:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  return (math.abs(normal:Dot(trace.HitNormal)) > (1 - dotm))
end

function ENT:UpdateSources()
  local hdx = 0; self.hitSize = 0 -- Add sources in array
  local idx, ent = self:GetEntityID()
  if(idx > 0) then ent = Entity(idx) else return self:SetEntityID(0) end
  if(not LaserLib.IsValid(ent)) then return self:SetEntityID(0) end
  if(ent:IsWorld() or ent:IsPlayer()) then return self:SetEntityID(0) end
  if(ent:GetModel() ~= self:GetModel()) then return self:SetEntityID(0) end
  if(ent:GetClass() ~= self:GetClass()) then return self:SetEntityID(0) end
   --  if(SERVER) then ent.hitBeam = true end -- Start recieving telemetry beams
  self:ProcessSources(function(entity, index, trace, data)
    if(trace and trace.Hit and data and self:IsHitNormal(trace)) then
      if(self.hitArray[self.hitSize] ~= entity) then
        local hitSize = self.hitSize + 1
        self.hitArray[hitSize] = entity -- Store source
        self.hitSize = hitSize -- Point to next slot
      end
      local mir = self:GetMirrorExitPos()
      local nrm = (self:GetReflectExitDir() and trace.HitNormal or nil)
      local pos, dir = LaserLib.GetReverse(trace.HitPos, data.VrDirect)
            pos, dir = LaserLib.GetBeamPortal(self, ent, pos, dir, mir, nrm)
      if(CLIENT) then
        hdx = hdx + 1; self:DrawBeam(entity, ent, pos, dir, data, hdx)
      else
        hdx = hdx + 1; self:DoDamage(self:DoBeam(entity, ent, pos, dir, data, hdx))
      end
    end -- Sources are located in the table hash part
  end); self:RemHitReports(hdx)
  return self:UpdateArrays("hitArray")
end

--[[
 * Specific beam traced for divider
 * ent  > Entity source to be divided
 * org  > Beam origin location
 * dir  > Beam trace direction
 * sdat > Source beam trace data
 * idx  > Index to store the result
]]
function ENT:DoBeam(ent, nxt, org, dir, sdat, idx)
  local length = sdat.NvLength
  local usrfle = sdat.BrReflec
  local usrfre = sdat.BrRefrac
  local noverm = sdat.BmNoover
  local damage = sdat.NvDamage
  local force  = sdat.NvForce
  local width  = LaserLib.GetWidth(sdat.NvWidth)
  local trace, data = LaserLib.DoBeam(nxt,
                                      org,
                                      dir,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm,
                                      idx)
  if(LaserLib.IsUnit(ent, 2)) then
    data.BmSource = ent -- Initial stage store laser
  else -- Make sure we always know which laser is source
    data.BmSource = sdat.BmSource -- Inherit previous laser
  end -- Otherwise inherit the laser source from prev stage
  return trace, data
end
