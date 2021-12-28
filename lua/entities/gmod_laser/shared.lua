ENT.Type           = "anim"
ENT.Category       = LaserLib.GetData("CATG")
ENT.PrintName      = "Emiter"
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
ENT.RenderGroup    = RENDERGROUP_OPAQUE

local EFFECTDT = LaserLib.GetData("EFFECTDT")
local DAMAGEDT = LaserLib.GetData("DAMAGEDT")

AddCSLuaFile(LaserLib.GetTool().."/wire_wrapper.lua")
include(LaserLib.GetTool().."/wire_wrapper.lua")

AddCSLuaFile(LaserLib.GetTool().."/editable_wrapper.lua")
include(LaserLib.GetTool().."/editable_wrapper.lua")

function ENT:SetupSourceDataTables()
  self:EditableSetVector("OriginLocal" , "General")
  self:EditableSetVector("DirectLocal" , "General")
  self:EditableSetBool  ("ForceCenter" , "General")
  self:EditableSetBool  ("ReflectRatio", "Material")
  self:EditableSetBool  ("RefractRatio", "Material")
  self:EditableSetBool  ("InPowerOn"   , "Internals")
  self:EditableSetFloat ("InBeamWidth" , "Internals", 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  self:EditableSetFloat ("InBeamLength", "Internals", 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  self:EditableSetFloat ("InBeamDamage", "Internals", 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  self:EditableSetFloat ("InBeamForce" , "Internals", 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  self:EditableSetStringCombo("InBeamMaterial", "Internals", list.GetForEdit("LaserEmitterMaterials"))
  self:EditableSetBool("InNonOverMater"  , "Internals")
  self:EditableSetBool("EndingEffect"    , "Visuals")
  self:EditableSetVectorColor("BeamColor", "Visuals")
  self:EditableSetFloat("BeamAlpha", "Visuals", 0, LaserLib.GetData("CLMX"))
  self:EditableSetStringCombo("DissolveType", "Visuals", list.GetForEdit("LaserDissolveTypes"), "name")
end

function ENT:SetupDataTables()
  self:SetupSourceDataTables()
  self:EditableRemoveOrderInfo()
end

function ENT:SetBeamTransform(tranData)
  if(tranData[2] and tranData[3]) then
    local diru = LaserLib.GetData("VDRUP")
    local zero = LaserLib.GetData("VZERO")
    local orgn = (tranData[2] or zero)
    local dirc = (tranData[3] or diru):GetNormalized()
    self:SetOriginLocal(orgn)
    self:SetDirectLocal(dirc)
  else
    local amx = LaserLib.GetData("AMAX")
    local val = (tonumber(tranData[1]) or 0)
    local ang = math.Clamp(val, amx[1], amx[2])
    local dir = LaserLib.GetBeamDirection(self, ang)
    local org = LaserLib.GetBeamOrigin(self, dir)
    self:SetOriginLocal(org)
    self:SetDirectLocal(dir)
  end; return self
end

function ENT:GetBeamOrigin(origin, nocnv)
  if(nocnv) then return Vector(origin) end
  return self:LocalToWorld(origin or self:GetOriginLocal())
end

function ENT:GetBeamDirection(direct, nocnv)
  if(nocnv) then return Vector(direct) end
  local dir = Vector(direct or self:GetDirectLocal())
        dir:Rotate(self:GetAngles())
  return dir
end

function ENT:GetHitPower(normal, trace, data, bmln)
  local norm = Vector(normal)
        norm:Rotate(self:GetAngles())
  local dotm = LaserLib.GetData("DOTM")
  local dotv = math.abs(norm:Dot(data.VrDirect))
  if(bmln) then dotv = 2 * math.asin(dotv) / math.pi end
  local dott = math.abs(norm:Dot(trace.HitNormal))
  return (dott > (1 - dotm)), dotv
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
      Handling color setup and conversion
---------------------- ]]
function ENT:SetBeamColorRGBA(mr, mg, mb, ma)
  local m = LaserLib.GetData("CLMX")
  local v, a = Vector(), m
  if(istable(mr)) then
    v.x = ((mr[1] or mr["r"] or m) / m)
    v.y = ((mr[2] or mr["g"] or m) / m)
    v.z = ((mr[3] or mr["b"] or m) / m)
    a = (mr[4] or mr["a"] or m)
  else
    v.x = ((mr or m) / m) -- [0-1]
    v.y = ((mg or m) / m) -- [0-1]
    v.z = ((mb or m) / m) -- [0-1]
    a = (ma or m) -- [0-255]
  end
  self:SetBeamColor(v)
  self:SetBeamAlpha(a)
end

function ENT:GetBeamColorRGBA(bcol)
  local m = LaserLib.GetData("CLMX")
  local v = self:GetBeamColor()
  local a = self:GetBeamAlpha()
  local r, g, b = (v.x * m), (v.y * m), (v.z * m)
  if(bcol) then local c = self.rgbCached
    if(not c) then c = Color(0,0,0,0); self.rgbCached = c end
    c.r, c.g, c.b, c.a = r, g, b, a; return c
  else -- The user requests four numbers instead
    return r, g, b, a
  end
end

--[[
 * Effects draw handling decides whenever
 * the current tick has to draw the effects
 * Flag is automatically reset in every call
 * then becomes true when it meets requirements
]]
function ENT:UpdateFlags()
  local time = CurTime()

  self.isEffect = false -- Reset the frame effects
  if(not self.nxEffect or time > self.nxEffect) then
    local dt = EFFECTDT:GetFloat() -- Read configuration
    self.isEffect, self.nxEffect = true, time + dt
  end

  if(SERVER) then -- Damage exists only on the server
    self.isDamage = false -- Reset the frame damage
    if(not self.nxDamage or time > self.nxDamage) then
      local dt = DAMAGEDT:GetFloat() -- Read configuration
      self.isDamage, self.nxDamage = true, time + dt
    end
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

function ENT:DoBeam(org, dir, idx)
  local force  = self:GetBeamForce()
  local width  = self:GetBeamWidth()
  local origin = self:GetBeamOrigin(org)
  local length = self:GetBeamLength()
  local damage = self:GetBeamDamage()
  local usrfle = self:GetReflectRatio()
  local usrfre = self:GetRefractRatio()
  local direct = self:GetBeamDirection(dir)
  local noverm = self:GetNonOverMater()
  local trace, data = LaserLib.DoBeam(self,
                                      origin,
                                      direct,
                                      length,
                                      width,
                                      damage,
                                      force,
                                      usrfle,
                                      usrfre,
                                      noverm,
                                      idx)
  return trace, data
end

function ENT:Setup(width       , length     , damage     , material    ,
                   dissolveType, startSound , stopSound  , killSound   ,
                   runToggle   , startOn    , pushForce  , endingEffect, tranData,
                   reflectRate , refractRate, forceCenter, enOverMater , rayColor, update)
  self:SetBeamWidth(width)
  self:SetBeamLength(length)
  self:SetBeamDamage(damage)
  self:SetBeamForce(pushForce)
  -- These are not controlled by wire and are stored in the laser itself
  self:SetBeamColorRGBA(rayColor)
  self:SetForceCenter(forceCenter)
  self:SetBeamMaterial(material)
  self:SetDissolveType(dissolveType)
  self:SetStartSound(startSound)
  self:SetStopSound(stopSound)
  self:SetKillSound(killSound)
  self:SetEndingEffect(endingEffect)
  self:SetReflectRatio(reflectRate)
  self:SetRefractRatio(refractRate)
  self:SetNonOverMater(enOverMater)

  if(not update) then
    self:SetBeamTransform(tranData)
  end -- Update does not change transform

  if((not update) or
    (not runToggle and update))
  then self:SetOn(startOn) end

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
    runToggle    = runToggle,
    startOn      = startOn,
    pushForce    = pushForce,
    endingEffect = endingEffect,
    reflectRate  = reflectRate,
    refractRate  = refractRate,
    forceCenter  = forceCenter,
    enOverMater  = enOverMater,
    tranData     = tranData,
    rayColor     = {r, g, b, a}
  })

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
 * Checks whenever the entity `ent` beam report hits us `self`
 * self > Target entity to be checked
 * ent  > Reporter entity to be checked
 * idx  > Forced index to check for hit report. Not mandatory
 * bri  > Search from idx as start hit report index. Not mandatory
 * Data is stored in notation: self.hitReports[ID]
]]
function ENT:GetHitSourceID(ent, idx, bri)
  if(not LaserLib.IsValid(ent)) then return nil end -- Invalid
  if(ent == self) then return nil end -- Cannot be source to itself
  if(not self.hitSources[ent]) then return nil end -- Not source
  if(not LaserLib.IsUnit(ent)) then return nil end -- Not unit
  if(not ent:GetOn()) then return nil end -- Unit is not powered on
  local rep = ent.hitReports -- Retrieve and localize hit reports
  if(not rep) then return nil end -- No hit reports. Exit at once
  if(idx and not bri) then -- Retrieve the report requested by ID
    local trace, data = ent:GetHitReport(idx) -- Retrieve beam report
    if(trace and trace.Hit and self == trace.Entity) then return idx end
  else local anc = (bri and idx or 1) -- Check all the entity reports for possible hits
    for cnt = anc, rep.Size do local trace, data = ent:GetHitReport(cnt)
      if(trace and trace.Hit and self == trace.Entity) then return cnt end
    end -- The hit report list is scanned and no reports are found hitting us `self`
  end; return nil -- Tell requestor we did not find anything that hits us `self`
end

--[[
 * Registers a trace hit report under the specified index
 * trace > Trace result structure to register
 * trace > Beam data structure to register
 * index > Index to use for storige ( defaults to 1 )
]]
function ENT:SetHitReport(trace, data, index)
  if(not self.hitReports) then self.hitReports = {Size = 0} end
  local rep, idx = self.hitReports, (tonumber(index) or 1)
  if(idx >= rep.Size) then rep.Size = idx end
  if(not rep[idx]) then rep[idx] = {} end; rep = rep[idx]
  rep["DT"] = data; rep["TR"] = trace; return self
end

--[[
 * Retrieves hit report trace and data under specified index
 * index > Hit report index to read ( defaults to 1 )
]]
function ENT:GetHitReport(index)
  if(not self.hitReports) then return end
  local idx = (tonumber(index) or 1)
  local rep = self.hitReports[idx]
  if(not rep) then return end
  return rep["TR"], rep["DT"]
end

--[[
 * Checks for infinite loops when the source `ent`
 * is powered by other generators powered by `self`
 * self > The root of the tree propagated
 * ent  > The entity of the source checked
 * set  > Contains the already processed items
]]
function ENT:IsInfinite(ent, set)
  local set = (set or {})
  if(LaserLib.IsValid(ent)) then
    if(set[ent]) then return false end
    if(ent == self) then return true else set[ent] = true end
    if(LaserLib.IsUnit(ent, 1) and ent.hitSources) then
      for src, stat in pairs(ent.hitSources) do
        -- Other hits and we are in its sources
        if(LaserLib.IsValid(src)) then -- Crystal has been hit by other crystal
          if(src == self) then return true end
          if(LaserLib.IsUnit(src, 1) and src.hitSources) then -- Class propagades the tree
            if(self:IsInfinite(src, set)) then return true end end
        end -- Cascadely propagate trough the crystal sources from `self`
      end; return false -- The entity does not persists in itself
    else return false end
  else return false end
end

--[[
 * Processes the sources table for a given entity
 * using a custom local scope function routine.
 * Runs a dedicated routine to define how the
 * source `ent` affects our `self` behavior.
 * self > Entity base item that is being issued
 * ent  > Entity hit reports getting checked
 * proc > Scope function to process. Arguments:
 *      > index  > Hit report active index
 *      > trace  > Hit report active trace
 *      > data   > Hit report active data
 * Returns flag indicating presence of hit reports
]]
function ENT:ProcessReports(ent, proc)
  if(not LaserLib.IsValid(ent)) then return false end
  local idx = self:GetHitSourceID(ent)
  if(idx) then local siz = ent.hitReports.Size
    while(idx and idx <= siz) do -- First index always hits when present
      local trace, data = ent:GetHitReport(idx) -- When the report hits us
      local suc, err = pcall(proc, self, ent, idx, trace, data) -- Call process
      if(not suc) then self:Remove(); error(err); return false end
      idx = self:GetHitSourceID(ent, idx + 1, true) -- Prepare for the next report
    end; return true -- At least one report is processed for the current entity
  end; return false -- The entity hit reports do not hit us `self`
end

--[[
 * Processes the sources table for all entities
 * using a custom local scope function routine.
 * Runs the dedicated routines to define how the
 * sources `ent` affect our `self` behavior.
 * Automatically removes the non related reports
 * self > Entity base item that is being issued
 * proc > Scope function to process. Arguments:
 *      > entity > Hit report active entity
 *      > index  > Hit report active index
 *      > trace  > Hit report active trace
 *      > data   > Hit report active data
 * Process how `ent` hit reports affects us `self`. Remove when no hits
]]
function ENT:ProcessSources(proc)
  local proc = (proc or self.ActionSource)
  if(not proc) then return false end
  if(not self.hitSources) then return false end
  for ent, hit in pairs(self.hitSources) do -- For all rgistered source entities
    if(hit and LaserLib.IsValid(ent)) then -- Process only valid hits from the list
      if(not self:ProcessReports(ent, proc)) then -- Are there any procesed sources
        self.hitSources[ent] = nil -- Remove the netity from the list
      end -- Check when there is any hit report that is processed correctly
    else self.hitSources[ent] = nil end -- Delete the entity when force skipped
  end; return true -- There are hit reports and all are processed correctly
end

--[[
 * Initializes array definitions and createsa a list
 * that is derived from the string arguments.
 * This will create arays in notation `self.hit%NAME`
 * Pass `false` as name to skip the wire output
]]
function ENT:InitArrays(...)
  local arg = {...}
  local num = #arg
  if(num <= 0) then return self end
  self.hitSetup = {Size = num}
  for idx = 1, num do local nam = arg[idx]
    self.hitSetup[idx] = {Name = nam, Data = {}}
  end; return self
end

--[[
 * Clears the output arrays according to the hit size
 * Removes the residual elements from wire ouputs
 * Desidned to be called at the end of sources process
]]
function ENT:UpdateArrays()
  local set = self.hitSetup
  if(not set) then return self end
  local idx = (tonumber(self.hitSize) or 0) + 1
  for cnt = 1, set.Size do
    local arr = set[cnt]
    if(arr and arr.Data) then
      LaserLib.Clear(arr.Data, idx)
    end
  end; return self
end

--[[
 * Registers the argument values in the setup arrays
 * The argument order must be the same as initialization
 * The first array must always hold valid source entities
]]
function ENT:SetArrays(...)
  local set = self.hitSetup
  if(not set) then return self end
  local idx = (tonumber(self.hitSize) or 0)
  local arr, arg = set[1].Data, {...}
  if(not arr) then return self end
  if(idx > 0 and arr[idx] == arg[1]) then return self end
  idx = idx + 1 -- Entity is different so increment
  for cnt = 1, set.Size do -- Copy values to arrays
    arr = set[cnt].Data
    arr[idx] = arg[cnt]
  end; self.hitSize = idx
  return self
end

--[[
 * Triggers all the dedicated data arrays in one call
]]
function ENT:WireArrays()
  if(not SERVER) then return self end
  local set = self.hitSetup
  if(not set) then return self end
  local idx = (tonumber(self.hitSize) or 0)
  self:WireWrite("Count", idx)
  for cnt = 1, set.Size do -- Copy values to arrays
    local nam = set[cnt].Name
    local arr = (idx > 0 and set[cnt].Data or nil)
    if(nam) then self:WireWrite(nam, arr) end
  end; return self
end

--[[
 * Updates beam the data according to the source entity
 * data > Data to be updated currently ( mandatory )
 * sdat > Beam data from the previous stage
]]
function ENT:UpdateBeam(data, sdat)
  if(LaserLib.IsUnit(self, 2)) then -- When actual source
    data.BmSource = self -- Initial stage store source
  else -- Make sure we always know which entity is source
    data.BmSource = sdat.BmSource -- Inherit previous source
  end -- Otherwise inherit the source from previos stage
  return data -- The routine will always succeed
end
