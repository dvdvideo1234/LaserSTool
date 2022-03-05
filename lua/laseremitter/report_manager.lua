--[[
 * Removes hit reports from the list
 * rovr > When remove overhead is provided deletes
          all entries with larger index
 * Data is stored in notation: self.hitReports[ID]
]]
function ENT:SetHitReportMax(rovr)
  if(self.hitReports) then
    local rep, idx = self.hitReports
    if(rovr) then -- Overhead mode
      local rovr = tonumber(rovr) or 0
      idx, rep.Size = (rovr + 1), rovr
    else idx, rep.Size = 1, 0 end
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
  LaserLib.Print("GetHitSourceID", ent, idx, bri)
  if(not LaserLib.IsValid(ent)) then return nil end -- Invalid
  if(ent == self) then return nil end -- Cannot be source to itself
  if(not self.hitSources[ent]) then return nil end -- Not source
  if(not ent:GetOn()) then return nil end -- Unit is not powered on
  local rep = ent.hitReports -- Retrieve and localize hit reports
  if(not rep) then return nil end -- No hit reports. Exit at once
  if(idx and not bri) then -- Retrieve the report requested by ID
    local beam, trace = ent:GetHitReport(idx) -- Retrieve beam report
    if(trace and trace.Hit and self == trace.Entity) then return idx end
  else local anc = (bri and idx or 1) -- Check all the entity reports for possible hits
    for cnt = anc, rep.Size do local beam, trace = ent:GetHitReport(cnt)
      if(trace and trace.Hit and self == trace.Entity) then return cnt end
    end -- The hit report list is scanned and no reports are found hitting us `self`
  end; return nil -- Tell requestor we did not find anything that hits us `self`
end

--[[
 * Registers a trace hit report under the specified index
 * trace > Trace result structure to register
 * beam  > Beam structure to register
]]
function ENT:SetHitReport(beam, trace)
  if(not self.hitReports) then self.hitReports = {Size = 0} end
  local rep, idx = self.hitReports, beam.BmIdenty
  if(idx >= rep.Size) then rep.Size = idx end
  if(not rep[idx]) then rep[idx] = {} end; rep = rep[idx]
  rep["BM"] = beam; rep["TR"] = trace; return self
end

--[[
 * Retrieves hit report trace and beam under specified index
 * index > Hit report index to read ( defaults to 1 )
]]
function ENT:GetHitReport(index)
  if(not index) then return end
  if(not self.hitReports) then return end
  local rep = self.hitReports[index]
  if(not rep) then return end
  return rep["BM"], rep["TR"]
end

--[[
 * Processes the sources table for a given entity
 * using a custom local scope function routine.
 * Runs a dedicated routine to define how the
 * source `ent` affects our `self` behavior.
 * self > Entity base item that is being issued
 * ent  > Entity hit reports getting checked
 * proc > Scope function per-beam handler. Arguments:
 *      > entity > Hit report active source
 *      > index  > Hit report active index
 *      > trace  > Hit report active trace
 *      > beam   > Hit report active beam
 * each > Scope function per-source handler. Arguments:
 *      > entity > Hit report active source
 *      > index  > Hit report active index
 * apre > Action taken for pre-processing
 *      > entity > Source entity
 * post > Action taken for post-processing
 *      > entity > Source entity
 * Returns flag indicating presence of hit reports
]]
function ENT:ProcessReports(ent, proc, each, apre, post)
  if(not LaserLib.IsValid(ent)) then return false end
  if(apre) then local suc, err = pcall(apre, self, ent)
    if(not suc) then self:Remove(); error(err); return false end
  end -- When whe have dedicated methor to apply on each source
  local idx = self:GetHitSourceID(ent)
  if(idx) then local siz = ent.hitReports.Size
    if(each) then local suc, err = pcall(each, self, ent, idx)
      if(not suc) then self:Remove(); error(err); return false end
    end -- When whe have dedicated method to apply on each source
    if(proc) then -- Trigger the beam processing routine
      while(idx and idx <= siz) do -- First index always hits when present
        local beam, trace = ent:GetHitReport(idx) -- When the report hits us
        local suc, err = pcall(proc, self, ent, idx, beam, trace) -- Call process
        if(not suc) then self:Remove(); error(err); return false end
        idx = self:GetHitSourceID(ent, idx + 1, true) -- Prepare for the next report
      end -- When whe have dedicated method to apply on each source
    end -- Trigger the post-processing routine
    if(post) then local suc, err = pcall(post, self, ent)
      if(not suc) then self:Remove(); error(err); return false end
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
 *      > beam   > Hit report active beam
 * Process how `ent` hit reports affects us `self`. Remove when no hits
]]
function ENT:ProcessSources(proc, each, apre, post)
  local proc, each = (proc or self.EveryBeam ), (each or self.EverySource)
  local apre, post = (apre or self.PreProcess), (post or self.PostProcess)
  if(not self.hitSources) then return false end
  for ent, hit in pairs(self.hitSources) do -- For all rgistered source entities
    if(hit and LaserLib.IsValid(ent)) then -- Process only valid hits from the list
      if(not self:ProcessReports(ent, proc, each, apre, post)) then -- Procesed sources
        self.hitSources[ent] = nil -- Remove the netity from the list
      end -- Check when there is any hit report that is processed correctly
    else self.hitSources[ent] = nil end -- Delete the entity when force skipped
  end; return true -- There are hit reports and all are processed correctly
end
