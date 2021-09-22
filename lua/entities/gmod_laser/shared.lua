ENT.Type           = "anim"
ENT.PrintName      = "Laser Emiter"
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.PrintName
else
  ENT.Base          = "base_entity"
end
ENT.Editable       = true
ENT.Author         = "MadJawa"
ENT.Category       = ""
ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.Information    = ENT.PrintName

local EFFECTTM = LaserLib.GetData("EFFECTTM")

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupDataTables()
  local amax = LaserLib.GetData("AMAX")
  self:EditableSetVector("OriginLocal" , "General")
  self:EditableSetVector("DirectLocal" , "General")
  self:EditableSetFloat ("AngleOffset" , "General", amax[1], amax[2])
  self:EditableSetBool  ("StartToggle" , "General")
  self:EditableSetBool  ("ForceCenter" , "General")
  self:EditableSetBool  ("ReflectRatio", "Material")
  self:EditableSetBool  ("RefractRatio", "Material")
  self:EditableSetBool  ("InPowerOn"   , "Internals")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetComboString("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetComboString("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
  self:EditableRemoveOrderInfo()
end

function ENT:SetBeamTransform()
  local angle  = self:GetAngleOffset()
  local direct = LaserLib.GetBeamDirection(self, angle)
  local origin = LaserLib.GetBeamOrigin(self, direct)
  self:SetOriginLocal(origin)
  self:SetDirectLocal(direct)
  return self
end

function ENT:GetBeamOrigin(origin, world)
  if(world) then return origin end
  return self:LocalToWorld(origin or self:GetOriginLocal())
end

function ENT:GetBeamDirection(direct, world)
  if(world) then return direct end
  local dir = Vector(direct or self:GetDirectLocal())
        dir:Rotate(self:GetAngles())
  return dir
end

--[[ ----------------------
  Width
---------------------- ]]
function ENT:SetBeamWidth(num)
  local width = math.max(num, 0)
  self:SetInBeamWidth(width)
  return self
end

function ENT:GetBeamWidth()
  if(SERVER) then
    local width = self:WireRead("Width", true)
    if(width ~= nil) then width = math.max(width, 0)
    else width = self:GetInBeamWidth() end
    self:SetNWFloat("GetInBeamWidth", width)
    self:WireWrite("Width", width)
    return width
  else
    local width = self:GetInBeamWidth()
    return self:GetNWFloat("GetInBeamWidth", width)
  end
end

--[[ ----------------------
   Length
---------------------- ]]
function ENT:SetBeamLength(num)
  local length = math.abs(num)
  self:SetInBeamLength(length)
  return self
end

function ENT:GetBeamLength()
  if(SERVER) then
    local length = self:WireRead("Length", true)
    if(length ~= nil) then length = math.abs(length)
    else length = self:GetInBeamLength() end
    self:SetNWFloat("GetInBeamLength", length)
    self:WireWrite("Length", length)
    return length
  else
    local length = self:GetInBeamLength()
    return self:GetNWFloat("GetInBeamLength", length)
  end
end

--[[ ----------------------
  Damage
---------------------- ]]
function ENT:SetBeamDamage(num)
  local damage = math.max(num, 0)
  self:SetInBeamDamage(damage)
  return self
end

function ENT:GetBeamDamage()
  if(SERVER) then
    local damage = self:WireRead("Damage", true)
    if(damage ~= nil) then damage = math.max(damage, 0)
    else damage = self:GetInBeamDamage() end
    self:SetNWFloat("GetInBeamDamage", damage)
    self:WireWrite("Damage", damage)
    return damage
  else
    local damage = self:GetInBeamDamage()
    return self:GetNWFloat("GetInBeamDamage", damage)
  end
end

--[[ ----------------------
  Material
---------------------- ]]
function ENT:SetBeamMaterial(mat)
  self:SetInBeamMaterial(mat)
  return self
end

function ENT:GetBeamMaterial(bool)
  local mat = self:GetInBeamMaterial()
  if(bool) then
    if(self.matCached) then
      if(self.matCached:GetName() ~= mat) then
        self.matCached = Material(mat)
      end
    else
      self.matCached = Material(mat)
    end
    return self.matCached
  else
    return mat
  end
end

--[[ ----------------------
          Sounds
---------------------- ]]
function ENT:SetStartSound(snd)
  local snd = tostring(snd or "")
  if(self.startSound ~= snd) then
    self.startSound = Sound(snd)
  else
    self.startSound = snd
  end; return self
end

function ENT:GetStartSound()
  return self.startSound
end

function ENT:SetStopSound(snd)
  local snd = tostring(snd or "")
  if(self.stopSound ~= snd) then
    self.stopSound = Sound(snd)
  else
    self.stopSound = snd
  end; return self
end

function ENT:GetStopSound()
  return self.stopSound
end

function ENT:SetKillSound(snd)
  local snd = tostring(snd or "")
  if(self.killSound ~= snd) then
    self.killSound = Sound(snd)
  else
    self.killSound = snd
  end; return self
end

function ENT:GetKillSound()
  return self.killSound
end

--[[ ----------------------
  Makes sounds
---------------------- ]]
function ENT:DoSound(state)
  if(self.onState ~= state) then
    self.onState = state -- Write the state
    local pos, enb = self:GetPos(), LaserLib.GetData("ENSOUNDS")
    local cls, mcs = self:GetClass(), LaserLib.GetClass(1, 1)
    if(cls == mcs or enb:GetBool()) then
      if(state) then -- Activating laser for given position
        self:EmitSound(self:GetStartSound())
      else -- User shuts the entity off
        self:EmitSound(self:GetStopSound())
      end -- Sound is calculated correctly
    end
  end; return self
end

--[[ ----------------------
  On/Off
---------------------- ]]
function ENT:SetOn(bool)
  local state = tobool(bool)
  self:SetInPowerOn(state)
  return self
end

function ENT:GetOn()
  if(SERVER) then
    local state = self:WireRead("On", true)
    if(state ~= nil) then state = (state ~= 0)
    else state = self:GetInPowerOn() end
    self:SetNWBool("GetInPowerOn", state)
    self:WireWrite("On", (state and 1 or 0))
    self:DoSound(state)
    return state
  else
    local state = self:GetInPowerOn()
    return self:GetNWBool("GetInPowerOn", state)
  end
end

--[[ ----------------------
      Prop pushing
---------------------- ]]
function ENT:SetBeamForce(num)
  local force = math.max(num, 0)
  self:SetInBeamForce(force)
  return self
end

function ENT:GetBeamForce()
  if(SERVER) then
    local force = self:WireRead("Force", true)
    if(force ~= nil) then force = math.max(force, 0)
    else force = self:GetInBeamForce() end
    self:SetNWFloat("GetInBeamForce", force)
    self:WireWrite("Force", force)
    return force
  else
    local force = self:GetInBeamForce()
    return self:GetNWFloat("GetInBeamForce", force)
  end
end

--[[ ----------------------
      Effects draw handling
---------------------- ]]

function ENT:DrawEffectBegin()
  if(not self.nextEffect or CurTime() > self.nextEffect) then
    local time = EFFECTTM:GetFloat()
    self.drawEffect = true
    self.nextEffect = CurTime() + time
  end
end

function ENT:DrawEffectEnd()
  if(self.drawEffect) then
    self.drawEffect = false
  end
end

--[[ ----------------------
  Beam uses the original mateial override
---------------------- ]]
function ENT:SetNonOverMater(bool)
  local over = tobool(bool)
  self:SetInNonOverMater(over)
  return self
end

function ENT:GetNonOverMater()
  return self:GetInNonOverMater()
end

function ENT:Setup(width       , length     , damage     , material    ,
                   dissolveType, startSound , stopSound  , killSound   ,
                   toggle      , startOn    , pushForce  , endingEffect,
                   reflectRate , refractRate, forceCenter, enOnverMater, update)
  self:SetBeamWidth(width)
  self:SetBeamLength(length)
  self:SetBeamDamage(damage)
  self:SetBeamForce(pushForce)
  -- These are not controlled by wire and are stored in the laser itself
  self:SetBeamColor(Vector(1,1,1))
  self:SetForceCenter(forceCenter)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetStartToggle(toggle)
  self:SetEndingEffect(endingEffect)
  self:SetReflectRatio(reflectRate)
  self:SetRefractRatio(refractRate)
  self:SetNonOverMater(enOnverMater)
  self:SetBeamTransform()

  table.Merge(self:GetTable(), {
    width        = width,
    model        = model,
    length       = length,
    damage       = damage,
    material     = material,
    dissolveType = dissolveType,
    startSound   = startSound,
    stopSound    = stopSound,
    killSound    = killSound,
    toggle       = toggle,
    startOn      = startOn,
    pushForce    = pushForce,
    endingEffect = endingEffect,
    reflectRate  = reflectRate,
    refractRate  = refractRate,
    forceCenter  = forceCenter,
    enOnverMater = enOnverMater
  })

  if((not update) or
    (not toggle and update))
  then self:SetOn(startOn) end

  return self
end

--[[
 * Removes hit reports from the list
 * rovr > When remove overhead is provided deletes
          all entries with larger index
 * Data is stored in notation: self.hitReports[ID]
]]

function ENT:RemHitReports(rovr)
  if(self.hitReports) then
    local rep, idx = self.hitReports
    if(rovr) then
      local rovr = tonumber(rovr) or 0
      idx, rep.Size = (rovr + 1), rovr
    else
      idx, rep.Size = 1, 0
    end
    -- Wipe selected items
    while(rep[idx]) do
      rep[idx] = nil
      idx = idx + 1
    end
  end; return self
end

--[[
 * Returns the entity hit report information table
 * Data is stored in notation: self.hitReports[ID]
]]
function ENT:GetHitReports()
  return self.hitReports
end

--[[
 * Checks whenever the entity beam report hits us (self)
 * self > Target entity to be checked
 * ent  > Reporter entity to be checked
 * idx  > Forced index to check. Not mandatory
 * Data is stored in notation: self.hitReports[ID]
]]
function ENT:GetHitSourceID(ent, idx)
  if(not LaserLib.IsValid(ent)) then return nil end -- Skip
  if(ent == self) then return nil end -- Loop source
  if(not self.hitSources[ent]) then return nil end
  if(not LaserLib.IsUnit(ent)) then return nil end
  if(not ent:GetOn()) then return nil end
  local rep = ent:GetHitReports()
  if(not rep) then return nil end
  if(idx) then local trace, data = ent:GetHitReport(idx)
    if(trace and trace.Hit and self == trace.Entity) then return idx end
  else
    for cnt = 1, rep.Size do local trace, data = ent:GetHitReport(cnt)
      if(trace and trace.Hit and self == trace.Entity) then return cnt end
    end
  end; return nil
end

function ENT:SetHitReport(trace, data, index)
  if(not self.hitReports) then
    self.hitReports = {Size = 0}
  end; local rep = self.hitReports
  if(not rep) then return self end
  local idx = LaserLib.GetReportID(index)
  if(idx >= self.hitReports.Size) then
    self.hitReports.Size = idx end
  local rep = self.hitReports[idx]
  if(not rep) then
    self.hitReports[idx] = {}
    rep = self.hitReports[idx]
  end
  rep["DT"] = data
  rep["TR"] = trace
  return self
end

function ENT:GetHitReport(index)
  if(not self.hitReports) then return end
  local idx = LaserLib.GetReportID(index)
  local rep = self.hitReports[idx]
  if(not rep) then return end
  return rep["TR"], rep["DT"]
end

--[[
 * Custom way to recalculate the correct dominant
 * Override this when the entity is pass trough
 * Dominat is calcualted from its sources
 * ent > The base entity which issues the hit dominant
]]
function ENT:GetHitDominant(ent)
  return self
end

--[[
 * Checks for infinite loops when the source `ent`
 * is powered by other generators powered by self
 * self > The root of the tree propagated
 * ent  > The entity of the source checked
 * set  > Contains the already processed items
]]
function ENT:IsInfinite(ent, set)
  local set = (set or {})
  if(LaserLib.IsValid(ent)) then
    if(set[ent]) then return false end
    if(ent == self) then return true else set[ent] = true end
    if(LaserLib.IsUnit(ent, 3) and ent.hitSources) then
      for src, stat in pairs(ent.hitSources) do
        -- Other hits and we are in its sources
        if(LaserLib.IsValid(src)) then -- Crystal has been hit by other crystal
          if(src == self) then return true end
          if(LaserLib.IsUnit(src, 3) and src.hitSources) then -- Class propagades the tree
            if(self:IsInfinite(src, set)) then return true end end
        end -- Cascadely propagate trough the crystal sources from `self`
      end; return false -- The entity does not persists in itself
    else return false end
  else return false end
end

--[[
 * Processes the sources table for a given entity
 * using a custom local scope function routine
 * self > Entity base item that is being issued
 * ent  > Entity hit reports getting checked
 * proc > Scope function to process. Arguments:
 *      > index  > Hit report active index
 *      > trace  > Hit report active trace
 *      > data   > Hit report active data
]]
function ENT:ProcessReports(ent, proc)
  if(not LaserLib.IsValid(ent)) then return false end
  local idh = self:GetHitSourceID(ent)
  if(idh) then local idx, siz = idh, ent:GetHitReports().Size
    while(idx <= siz) do -- First index always hits when present
      if(idh) then -- When the entity hit report hiys us
        local trace, data = ent:GetHitReport(idh)
        local suc, err = pcall(proc, idh, trace, data)
        if(not suc) then self:Remove(); error(err); return false end
      end; idx = idx + 1 -- Prepare to process next report
      idh = self:GetHitSourceID(ent, idx)
    end -- Hit reports are processed for the current entity
  end; return true
end

--[[
 * Processes the sources table for all entities
 * using a custom local scope function routine.
 * Automatically removes the non related reports
 * self > Entity base item that is being issued
 * proc > Scope function to process. Arguments:
 *      > entity > Hit report active entity
 *      > index  > Hit report active index
 *      > trace  > Hit report active trace
 *      > data   > Hit report active data
]]
function ENT:ProcessSources(proc)
  if(not self.hitSources) then return false end
  for ent, hit in pairs(self.hitSources) do
    if(hit and LaserLib.IsValid(ent)) then
      local idh = self:GetHitSourceID(ent)
      if(idh) then local idx, siz = idh, ent:GetHitReports().Size
        while(idx <= siz) do -- First index always hits when present
          if(idh) then -- When the entity hit report hiys us
            local trace, data = ent:GetHitReport(idh)
            local suc, err = pcall(proc, ent, idh, trace, data)
            if(not suc) then self:Remove(); error(err); return false end
          end; idx = idx + 1 -- Prepare to process next report
          idh = self:GetHitSourceID(ent, idx)
        end -- Hit reports are processed for the current entity
      else self.hitSources[ent] = nil end
    else self.hitSources[ent] = nil end
  end; return true
end

--[[
 * Clears the output arrays according to the hit size
 * Removes the residual elements from wire ouputs
]]
function ENT:UpdateArrays(...)
  local cnt = (tonumber(self.hitSize) or 0)
  if(cnt <= 0) then return self end
  local set, cnt = {...}, (cnt + 1)
  for idx = 1, #set do
    local nam = set[idx]
    local arr = self[nam]
    if(arr) then -- Wipe the rest until empty
      while(arr[cnt]) do -- Table end check
        arr[cnt] = nil -- Wipe cirrent item
        cnt = (cnt + 1) -- Go to nex one
      end
    end
  end; return self
end
