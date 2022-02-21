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
  for cnt = 1, set.Size do local arr = set[cnt]
    if(arr and arr.Data) then LaserLib.Clear(arr.Data, idx) end
  end; set.Save = nil -- Clear the last top enntity
  return self -- Use coding effective API
end

--[[
 * Registers the argument values in the setup arrays
 * The argument order must be the same as initialization
 * The first array must always hold valid source entities
]]
function ENT:SetArrays(...)
  local set = self.hitSetup
  if(not set) then return self end
  local arg, idx = {...}, self.hitSize
  if(set.Save == arg[1]) then return self end
  if(not set.Save) then set.Save = arg[1] end
  idx = (tonumber(idx) or 0) + 1
  for cnt = 1, set.Size do
    set[cnt].Data[idx] = arg[cnt]
  end; self.hitSize = idx
  return self
end

--[[
 * Triggers all the dedicated arrays in one call
]]
function ENT:WireArrays()
  if(CLIENT) then return self end
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
