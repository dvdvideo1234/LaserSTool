-- Wrapper for: https://github.com/wiremod/wire/blob/master/lua/wire/server/wirelib.lua

--[[
 * Helper routine factory for `WirePostEntityPaste`
 * Returns wire specific and related entity picker
 * cre > Created entity set by the duplicator
]]
local function wireLookup(cre)
  return function(id, def)
    if(id == nil) then return def
    elseif(id == 0) then return game.GetWorld() end
    local ent = cre[id] or (isnumber(id) and ents.GetByIndex(id))
    if(IsValid(ent)) then return ent else return def end
  end
end

--[[
 * Unpacks the ports information to prepare them for wire library
 * Trims any blank spaces from the configuration and applies defaults
]]
local function wireUnpackPortInfo(tP)
  if(not WireLib) then return nil end
  local sN, sT, sD = tP[1], tP[2], tP[3]
  sN = ((sN ~= nil) and string.Trim(tostring(sN)) or nil)
  sT = ((sT ~= nil) and string.Trim(tostring(sT)) or "NORMAL")
  sD = ((sD ~= nil) and string.Trim(tostring(sD)) or nil)
  return sN, sT, sD
end

--[[
 * Setups the ports information and calls the wire library
 * oE > Entity which white ports are being configured
 * sF > Function name of the wite library being called
 * tI > Ports information table name/type/desription
 * bL > The wire function can process a single port at a time
]]
local function wireSetupPorts(oE, sF, tI, bL)
  if(not WireLib) then return oE end
  local iD, tN, tT, tD = 1, {}, {}, {}
  while(tI[iD]) do local sN, sT, sD = wireUnpackPortInfo(tI[iD])
    if(not sN) then oE:WireError("("..sF..")["..iD.."]: Name missing"); return oE end
    if(not sT) then oE:WireError("("..sF..")["..iD.."]: Type missing"); return oE end
    if(not WireLib.DT[sT]) then oE:WireError("("..sF..")["..iD.."]: Type invalid ["..sT.."]"); return oE end
    tN[iD], tT[iD], tD[iD] = sN, sT, sD; iD = (iD + 1) -- Call the provider
  end
  if(bL) then
    for iD = 1, #tN do -- Port name and type is mandatory
      local bS, sE = pcall(WireLib[sF], oE, tN[iD], tT[iD], tD[iD])
      if(not bS) then oE:WireError("("..sF..")["..iD.."]: Error: "..sE); return oE end
    end -- The wire method can process only one port description at a time
  else -- The wiremod method can process multiple ports in one call
    local bS, sE = pcall(WireLib[sF], oE, tN, tT, tD)
    if(not bS) then oE:WireError("("..sF..")["..iD.."]: Error: "..sE); return oE end
  end
  return oE -- Coding effective API. Must always return reference to self
end

--[[
 * For override. Change as you please to handle errors
 * Defines what should happen when error in wire is found
]]
function ENT:WireError(sM)
  local tI, sM = debug.getinfo(2), tostring(sM or "")
  local sN = tI and tI.name or "Incognito"
  local sO = tostring(self).."."..sN..": "..sM
  self:Remove(); error(sO.."\n")
end

--[[
 * Used to check if a given input exists
 * sN > Port name must be string
]]
function ENT:WireIsInput(sN)
  if(not WireLib) then return nil end
  if(sN == nil) then self:WireError("Name missing"); return nil end
  local tP, sP = self["Inputs"], tostring(sN); tP = (tP and tP[sP] or nil)
  return (tP ~= nil)
end

--[[
 * Used to check if a given input exists
 * sN > Port name must be string
]]
function ENT:WireIsOutput(sN)
  if(not WireLib) then return nil end
  if(sN == nil) then self:WireError("Name missing"); return nil end
  local tP, sP = self["Outputs"], tostring(sN); tP = (tP and tP[sP] or nil)
  return (tP ~= nil)
end

--[[
 * Used to index a wite port and return its content
 * sT > Port key `Input` or `Output`
 * sN > Port name must be string
]]
local widx = {["Inputs"] = true, ["Outputs"] = true}
function ENT:WireIndex(sT, sN)
  if(not WireLib) then return nil end
  if(sT == nil) then self:WireError("Type missing"); return nil end
  if(not widx[sT]) then self:WireError("("..tostring(sT).."): Type invalid"); return nil end
  if(sN == nil) then self:WireError("("..sT.."): Name missing"); return nil end
  local tP, sP = self[sT], tostring(sN); tP = (tP and tP[sP] or nil)
  if(tP == nil) then self:WireError("("..sT..")("..sP.."): Name invalid"); return tP, sP end
  return tP, sP -- Returns the dedicated indexed wire I/O port and name
end

--[[
 * Used to forcefully disconnect an output
 * sN > The output name to disconnect
]]
function ENT:WireDisconnect(sN)
  if(not WireLib) then return nil end; local tP, sP = self:WireIndex("Outputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Output missing"); return self end
  WireLib.DisconnectOutput(self, sN); return self -- Disconnects the output
end

--[[
 * Checks whenever a wire input is connected
 * sN > Input name to check connection for
]]
function ENT:WireIsConnected(sN)
  if(not WireLib) then return nil end; local tP, sP = self:WireIndex("Inputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Input missing"); return nil end
  return IsValid(tP.Src) -- When the input exists and connected returns true
end

--[[
 * Procedure. Removes wire abilities from an entity
 * bU > Set to true if you want to remove ent from the list and
            if you want to call `WireLib._RemoveWire(eid)` manually.
        Set to false so it doesn't count as a wire able entity anymore
]]
function ENT:WireRemove(bU)
  if(not WireLib) then return self end
  WireLib.Remove(self, bU); return self
end

--[[
 * Procedure. Restores ports on a wire able entity
 * bF > Only needed for existing components to allow them to be updated
]]
function ENT:WireRestored(bF)
  if(not WireLib) then return self end
  WireLib.Restored(self, bF); return self
end

--[[
 * Builds duplicator needed wire information
 * Function. Returns the built dupe information
]]
function ENT:WireBuildDupeInfo()
  if(not WireLib) then return end
  return WireLib.BuildDupeInfo(self)
end

--[[
 * Procedure. Applies duplicator needed wire information
 * Does not return anything. It is prcedure
 * ply    > Player to store the info for
 * ent    > Entity to store the info for
 * info   > Information table to apply
 * fentid > Pointer to function retrieving entity by ID
 * Usage: function ENT:ApplyDupeInfo(ply, ent, info, fentid)
            self:WireApplyDupeInfo(ply, ent, info, fentid) end
]]
function ENT:WireApplyDupeInfo(ply, ent, info, fentid)
  if(not WireLib) then return self end
  WireLib.ApplyDupeInfo(ply, ent, info, fentid)
  return self
end

--[[
 * Procedure. Must be run inside `ENT:PreEntityCopy`
 * Makes wire do the pre-copy preparation for dupe info
 * Usage: function ENT:PreEntityCopy()
            self:WirePreEntityCopy() end
]]
function ENT:WirePreEntityCopy()
  if(not WireLib) then return self end
  duplicator.StoreEntityModifier(
    self, "WireDupeInfo", self:WireBuildDupeInfo())
  return self
end

--[[
 * Procedure. Must be run inside `ENT:PostEntityPaste`
 * Makes wire do the post-paste preparation for dupe info
 * Usage: function ENT:PostEntityPaste(player, entity, created)
            self:WirePostEntityPaste(player, entity, created) end
 * ply > The player calling the routune
 * ent > The entity being post-pasted
 * cre > The created entities list after paste
]]
function ENT:WirePostEntityPaste(ply, ent, cre)
  if(not WireLib) then return self end
  if(not ent.EntityMods) then return self end
  if(not ent.EntityMods.WireDupeInfo) then return self end
  self:WireApplyDupeInfo(ply, ent, ent.EntityMods.WireDupeInfo, wireLookup(cre))
  return self
end

--[[
 * Reads a port of a wire able entity
 * sN > The input name to read
 * bC > Set to true to force a check if the input is connected
]]
function ENT:WireRead(sN, bC)
  if(not WireLib) then return nil end; local tP, sP = self:WireIndex("Inputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Input missing"); return nil end
  if(bC) then return (IsValid(tP.Src) and tP.Value or nil) end; return tP.Value
end

--[[
 * Writes to a port of a wire able entity
 * sN > The output name to write
 * vD > The wire port content to write
 * bT > Set to true to force type check
]]
function ENT:WireWrite(sN, vD, bT)
  if(not WireLib) then return self end; local tP, sP = self:WireIndex("Outputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Output missing"); return self end
  if(bT) then
    local sD = tP.Type; if(sD == nil) then
      self:WireError("("..sP.."): Type missing"); return self end
    local tD = WireLib.DT[sD]; if(tD == nil) then
      self:WireError("("..sP..")("..sD.."): Type undefined"); return self end
    local sT, sZ = type(vD), type(tD.Zero); if(sT ~= sZ) then
      self:WireError("("..sP..")("..sT.."~"..sZ.."): Type mismatch"); return self end
  end
  WireLib.TriggerOutput(self, sP, vD); return self
end

function ENT:WireCreateInputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "CreateSpecialInputs", {...})
end

function ENT:WireCreateOutputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "CreateSpecialOutputs", {...})
end

function ENT:WireAdjustInputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "AdjustSpecialInputs", {...})
end

function ENT:WireAdjustOutputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "AdjustSpecialOutputs", {...})
end

function ENT:WireRetypeInputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "RetypeInputs", {...}, true)
end

function ENT:WireRetypeOutputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "RetypeOutputs", {...}, true)
end
