local gsTool = LaserLib.GetTool()
local gsNoAV = LaserLib.GetData("NOAV")
local gsLaseremCls = LaserLib.GetClass(1, 1)
local gsLaserptCls = LaserLib.GetClass(9, 1)
local gsLaserelCls = LaserLib.GetClass(3, 1)
local gsLasererCls = LaserLib.GetClass(12, 1)

if(CLIENT) then

  TOOL.Information = {
    {name = "info"      , icon = "gui/info"   },
    {name = "mater"     , icon = LaserLib.GetIcon("wand")},
    {name = "left"      , icon = "gui/lmb.png"},
    {name = "right"     , icon = "gui/rmb.png"},
    {name = "reload"    , icon = "gui/r.png"  },
    {name = "reload_use", icon = "gui/r.png"  , icon2 = "gui/e.png"},
  }

  language.Add("tool."..gsTool..".name", "Laser Spawner")
  language.Add("tool."..gsTool..".desc", "Spawns very dangerous lasers!")
  language.Add("tool."..gsTool..".0", "Do not look into the beam source with the remaining eye!")
  language.Add("tool."..gsTool..".mater", "Hit world to select active mirror or transparent material")
  language.Add("tool."..gsTool..".left", "Create or update a laser where you are aiming")
  language.Add("tool."..gsTool..".right", "Retrieve settings from trace entity. Hold SHIFT to use custom offsets")
  language.Add("tool."..gsTool..".reload", "Reset material. Hold SHIFT to apply mirror. Hold DUCK to remove your props")
  language.Add("tool."..gsTool..".reload_use", "Apply transparent material to trace prop")
  language.Add("tool."..gsTool..".frozen_con", "Freeze on creation")
  language.Add("tool."..gsTool..".frozen", "Freezes the laser when created")
  language.Add("tool."..gsTool..".key_con", "Control key")
  language.Add("tool."..gsTool..".key", "Numpad key that controls the laser trigger")
  language.Add("tool."..gsTool..".width_con", "Width:")
  language.Add("tool."..gsTool..".width", "Controls laser beam width")
  language.Add("tool."..gsTool..".length_con", "Length:")
  language.Add("tool."..gsTool..".length", "Controls laser beam maximum length")
  language.Add("tool."..gsTool..".damage_con", "Damage:")
  language.Add("tool."..gsTool..".damage", "Controls laser beam damage amount")
  language.Add("tool."..gsTool..".material", "Select laser beam material form the ones shown here")
  language.Add("tool."..gsTool..".model_con", "Laser entity model:")
  language.Add("tool."..gsTool..".model", "Select laser visual model form the ones shown here")
  language.Add("tool."..gsTool..".color", "Controls the laser beam material base color when supported")
  language.Add("tool."..gsTool..".color_con", "Beam material color:")
  language.Add("tool."..gsTool..".dissolvetype_con", "Dissolve type:")
  language.Add("tool."..gsTool..".dissolvetype", "Controls visuals used when dissolving players")
  language.Add("tool."..gsTool..".startsound_con", "Start sound:")
  language.Add("tool."..gsTool..".startsound", "Controls sounds used when starting the laser")
  language.Add("tool."..gsTool..".stopsound_con", "Stop sound:")
  language.Add("tool."..gsTool..".stopsound", "Controls sounds used when stopping the laser")
  language.Add("tool."..gsTool..".killsound_con", "Kill sound:")
  language.Add("tool."..gsTool..".killsound", "Controls sounds used when killing players or NPC")
  language.Add("tool."..gsTool..".toggle_con", "Toggled operation")
  language.Add("tool."..gsTool..".toggle", "Starts the laser when the button is hit")
  language.Add("tool."..gsTool..".starton_con", "Start on creation")
  language.Add("tool."..gsTool..".starton", "Starts the laser on when gets created")
  language.Add("tool."..gsTool..".forcecenter_con", "Apply center force")
  language.Add("tool."..gsTool..".forcecenter", "When prop push force is present enable to force the center instead")
  language.Add("tool."..gsTool..".pushforce_con", "Push props:")
  language.Add("tool."..gsTool..".pushforce", "Seutp the laser beam to push props")
  language.Add("tool."..gsTool..".endingeffect_con", "Enable ending effects")
  language.Add("tool."..gsTool..".endingeffect", "Allows showing ending effects on beam hit")
  language.Add("tool."..gsTool..".surfweld_con", "Weld to surface")
  language.Add("tool."..gsTool..".surfweld", "Welds the laser to the trace surface")
  language.Add("tool."..gsTool..".nocollide_con", "No-collide to surface")
  language.Add("tool."..gsTool..".nocollide", "No-collides the laser to the trace surface")
  language.Add("tool."..gsTool..".rayassist_con", "Assist margin:")
  language.Add("tool."..gsTool..".rayassist", "Distance margin to assists the player when setting up laser systems")
  language.Add("tool."..gsTool..".forcelimit_con", "Force limit:")
  language.Add("tool."..gsTool..".forcelimit", "Conrold the force limit on the weld created")
  language.Add("tool."..gsTool..".reflectrate_con", "Reflection power ratio")
  language.Add("tool."..gsTool..".reflectrate", "Reflect the amount of power according to the surface material type")
  language.Add("tool."..gsTool..".refractrate_con", "Refraction power ratio")
  language.Add("tool."..gsTool..".refractrate", "Refract the amount of power according to the medium material type")
  language.Add("tool."..gsTool..".enonvermater_con", "Use base entity material")
  language.Add("tool."..gsTool..".enonvermater", "Utilize the first material from the list. Otherwise use material type")
  language.Add("tool."..gsTool..".ensafebeam_con", "Enable emiter beam safety")
  language.Add("tool."..gsTool..".ensafebeam", "Allows player and beam interaction from the portal series")
  language.Add("tool."..gsTool..".openmaterial", "Manager for: ")
  language.Add("tool."..gsTool..".openmaterial_cmat", "Copy material")
  language.Add("tool."..gsTool..".openmaterial_cset", "Copy settings")
  language.Add("tool."..gsTool..".openmaterial_call", "Copy all info")
  language.Add("tool."..gsTool..".openmaterial_sort", "Sort materials")
  language.Add("tool."..gsTool..".openmaterial_find","Select which value you need a search for using patterns")
  language.Add("tool."..gsTool..".openmaterial_find0","Search by value...")
  language.Add("tool."..gsTool..".openmaterial_find1","Surface material name")
  language.Add("tool."..gsTool..".openmaterial_find2","Power reduction ratio")
  language.Add("tool."..gsTool..".openmaterial_find3","Medium refractive index")
  language.Add("Cleanup_"..gsTool.."s", "Laser elements")
  language.Add("Cleaned_"..gsTool.."s", "Cleaned up all Laser elements")
  language.Add("Undone_"..gsTool, "Undone Laser emitter")
  language.Add("SBoxLimit_"..gsTool.."s", "You've hit the Laser elements limit!")

  -- http://www.famfamfam.com/lab/icons/silk/preview.php
  concommand.Add(gsTool.."_openmaterial",
    function(ply, cmd, args)
      local base, tseq, sors
      local reca = LaserLib.GetData("KEYA")
      local rate = LaserLib.GetData("GRAT")
      local argm = tostring(args[1] or ""):upper()
      if(argm == "MIRROR") then
        sors = "REFLECT"
        base = LaserLib.DataReflect(reca)
        tseq = LaserLib.GetSequenceData(base)
      elseif(argm == "TRANSPARENT") then
        sors = "REFRACT"
        base = LaserLib.DataRefract(reca)
        tseq = LaserLib.GetSequenceData(base)
      else return nil end
      tseq.Sors = sors:lower().."used"
      tseq.Conv = GetConVar(gsTool.."_"..tseq.Sors)
      tseq.Name = language.GetPhrase("tool."..gsTool..".openmaterial")..argm
      local pnFrame = vgui.Create("DFrame"); if(not IsValid(pnFrame)) then return nil end
      local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()
      local iPa, iSx, iSy = 5, (scrW / 2), (scrH / 2)
      pnFrame:SetTitle(tseq.Name)
      pnFrame:SetVisible(false)
      pnFrame:SetDraggable(true)
      pnFrame:SetDeleteOnClose(true)
      pnFrame:SetPos(0, 0)
      pnFrame:SetSize(iSx , iSy)
      local pnCombo = vgui.Create("DComboBox"); if(not IsValid(pnCombo)) then return nil end
            pnCombo:SetParent(pnFrame)
            pnCombo:SetSortItems(false)
            pnCombo:SetPos(iPa, 24 + iPa)
            pnCombo:SetSize(pnFrame:GetWide() - (rate - 1) * pnFrame:GetWide(), 25)
            pnCombo:SetTooltip(language.GetPhrase("tool."..gsTool..".openmaterial_find"))
            pnCombo:SetValue(language.GetPhrase("tool."..gsTool..".openmaterial_find0"))
            if(tseq[1]["Key"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTool..".openmaterial_find1"), "Key", false, LaserLib.GetIcon("key_go")) end
            if(tseq[1]["Rate"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTool..".openmaterial_find2"), "Rate", false, LaserLib.GetIcon("chart_bar")) end
            if(tseq[1]["Ridx"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTool..".openmaterial_find3"), "Ridx", false, LaserLib.GetIcon("transmit")) end
      local pnText = vgui.Create("DTextEntry"); if(not IsValid(pnText)) then return nil end
            pnText:SetParent(pnFrame)
            pnText:SetPos(pnCombo:GetWide() + 2 * iPa, pnCombo:GetY())
            pnText:SetSize(pnFrame:GetWide() - pnCombo:GetWide() - 3 * iPa, pnCombo:GetTall())
      local pnMat = vgui.Create("MatSelect"); if(not IsValid(pnMat)) then return nil end
            pnMat:SetParent(pnFrame)
            pnMat:SetPos(iPa, pnCombo:GetY() + pnCombo:GetTall() + iPa)
            pnMat:SetSize(pnFrame:GetWide() - 2 * iPa, pnFrame:GetTall() - 2 * iPa)
      function pnText:OnEnter(sTxt)
        local iD = pnCombo:GetSelectedID()
        if(not iD or iD <= 0) then return end
        local sD = pnCombo:GetOptionData(iD)
        local fD = (sD and sD:len() > 0)
        for iD = 1, tseq.Size do local tRow = tseq[iD]
          if(fD) then
            if(tostring(tRow[sD]):find(sTxt)) then
              tRow.Draw = true else tRow.Draw = false end
          else tRow.Draw = true end
        end; LaserLib.UpdateMaterials(pnFrame, pnMat, tseq)
      end
      LaserLib.SetMaterialSize(pnMat, 4)
      LaserLib.UpdateMaterials(pnFrame, pnMat, tseq)
      pnFrame:Center()
      pnFrame:SetVisible(true)
      pnFrame:MakePopup()
    end)
end

TOOL.Settings = {0, "", ""}
TOOL.Category = "Construction"
TOOL.Name     = (language and language.GetPhrase("tool."..gsTool..".name"))

if(SERVER) then
  duplicator.RegisterEntityModifier("laseremitter_material",
    function(ply, ent, dupe) LaserLib.SetMaterial(ent, dupe.MaterialOverride) end)

  duplicator.RegisterEntityModifier("laseremitter_properties",
    function(ply, ent, dupe) LaserLib.SetMaterial(ent, dupe.Material) end)

  duplicator.RegisterEntityClass(gsLaseremCls, LaserLib.NewLaser,
    --[[  ply  ]]  "pos"         , "ang"         , "model"      ,
    "tranData"   , "key"         , "width"       , "length"     ,
    "damage"     , "material"    , "dissolveType", "startSound" ,
    "stopSound"  , "killSound"   , "runToggle"   , "startOn"    ,
    "pushForce"  , "endingEffect", "reflectRate" , "refractRate",
    "forceCenter", "frozen"      , "enOverMater" , "enSafeBeam" , "rayColor")

  CreateConVar("sbox_max"..gsTool.."s", 20)
end

cleanup.Register(gsTool.."s")

TOOL.ClientConVar =
{
  [ "key"          ] = 51,
  [ "width"        ] = 4,
  [ "length"       ] = 1000,
  [ "damage"       ] = 10,
  [ "colorr"       ] = 255,
  [ "colorg"       ] = 255,
  [ "colorb"       ] = 255,
  [ "colora"       ] = 255,
  [ "angle"        ] = 0,
  [ "origin"       ] = "",
  [ "direct"       ] = "",
  [ "material"     ] = "trails/laser",
  [ "model"        ] = "models/props_lab/tpplug.mdl",
  [ "dissolvetype" ] = "core",
  [ "startsound"   ] = "ambient/energy/weld1.wav",
  [ "stopsound"    ] = "ambient/energy/weld2.wav",
  [ "killsound"    ] = "ambient/levels/citadel/weapon_disintegrate1.wav",
  [ "toggle"       ] = 1,
  [ "starton"      ] = 0,
  [ "pushforce"    ] = 100,
  [ "endingeffect" ] = 1,
  [ "surfweld"     ] = 1,
  [ "forcelimit"   ] = 0,
  [ "nocollide"    ] = 1,
  [ "reflectrate"  ] = 1,
  [ "refractrate"  ] = 1,
  [ "reflectused"  ] = LaserLib.DataReflect(),
  [ "refractused"  ] = LaserLib.DataRefract(),
  [ "enonvermater" ] = 1,
  [ "ensafebeam"   ] = 0,
  [ "forcecenter"  ] = 0,
  [ "portalexit"   ] = 0,
  [ "rayassist"    ] = 25,
  [ "frozen"       ] = 1 -- The cold never bothered me anyway
}

LaserLib.SetupModels()
LaserLib.SetupMaterials()
LaserLib.SetupComboBools()
LaserLib.SetupSoundEffects()
LaserLib.SetupDissolveTypes()

cleanup.Register(gsTool.."s")

function TOOL:Holster()
  if(LaserLib.IsValid(self.GhostEntity)) then
    self.GhostEntity:SetNoDraw(true)
    self.GhostEntity:Remove()
  end; self.GhostEntity = nil
end

function TOOL:GetAngleOffset()
  local amax = LaserLib.GetData("AMAX")
  local nang = self:GetClientNumber("angle", 0)
  return math.Clamp(nang, amax[1], amax[2])
end

function TOOL:GetTransform()
  local tset = self.Settings
  tset[1] = self:GetAngleOffset()
  tset[2] = self:GetClientInfo("origin")
  tset[3] = self:GetClientInfo("direct")
  return LaserLib.SetupTransform(tset)
end

function TOOL:GetUnit(ent)
  if(not LaserLib.IsValid(ent)) then return LaserLib.GetData("NOAV") end
  local css = ent:GetClass():gsub(gsLaseremCls, ""):gsub("^_", "")
  return ((css:len() > 0) and (" "..css.." ") or (" "))
end

function TOOL:GetBeamRayColor()
 local r = self:GetClientNumber("colorr", 0)
 local g = self:GetClientNumber("colorg", 0)
 local b = self:GetClientNumber("colorb", 0)
 local a = self:GetClientNumber("colora", 0)
 return Color(r, g, b, a)
end

function TOOL:LeftClick(trace)
  if(CLIENT) then return true end
  if(not trace.HitPos) then return false end
  local ply, ent = self:GetOwner(), trace.Entity
  if(ent:IsPlayer()) then return false end
  local swep = self:GetSWEP()
  if(not swep:CheckLimit(gsTool.."s")) then return false end
  local pos, ang     = trace.HitPos, trace.HitNormal:Angle()
  local width        = math.Clamp(self:GetClientNumber("width", 0), 0, LaserLib.GetData("MXBMWIDT"):GetFloat())
  local length       = math.Clamp(self:GetClientNumber("length", 0), 0, LaserLib.GetData("MXBMLENG"):GetFloat())
  local damage       = math.Clamp(self:GetClientNumber("damage", 0), 0, LaserLib.GetData("MXBMDAMG"):GetFloat())
  local pushforce    = math.Clamp(self:GetClientNumber("pushforce", 0), 0, LaserLib.GetData("MXBMFORC"):GetFloat())
  local forcelimit   = math.Clamp(self:GetClientNumber("forcelimit", 0), 0, LaserLib.GetData("MFORCELM"):GetFloat())
  local trandata     = self:GetTransform()
  local raycolor     = self:GetBeamRayColor()
  local key          = self:GetClientNumber("key")
  local model        = self:GetClientInfo("model")
  local material     = self:GetClientInfo("material")
  local stopsound    = self:GetClientInfo("stopsound")
  local killsound    = self:GetClientInfo("killsound")
  local startsound   = self:GetClientInfo("startsound")
  local dissolvetype = self:GetClientInfo("dissolvetype")
  local toggle       = (self:GetClientNumber("toggle", 0) ~= 0)
  local frozen       = (self:GetClientNumber("frozen", 0) ~= 0)
  local starton      = (self:GetClientNumber("starton", 0) ~= 0)
  local surfweld     = (self:GetClientNumber("surfweld", 0) ~= 0)
  local nocollide    = (self:GetClientNumber("nocollide", 0) ~= 0)
  local reflectrate  = (self:GetClientNumber("reflectrate", 0) ~= 0)
  local refractrate  = (self:GetClientNumber("refractrate", 0) ~= 0)
  local endingeffect = (self:GetClientNumber("endingeffect", 0) ~= 0)
  local forcecenter  = (self:GetClientNumber("forcecenter", 0) ~= 0)
  local ensafebeam   = (self:GetClientNumber("ensafebeam", 0) ~= 0)
  local enonvermater = (self:GetClientNumber("enonvermater", 0) ~= 0)

  if(LaserLib.IsValid(ent) and ent:GetClass() == gsLaseremCls) then
    LaserLib.Notify(ply, "Paste settings !", "UNDO")
    ent:Setup(width      , length      , damage    , material   , dissolvetype,
              startsound , stopsound   , killsound , toggle     , starton     ,
              pushforce  , endingeffect, trandata  , reflectrate, refractrate ,
              forcecenter, enonvermater, ensafebeam, raycolor   , true)
    return true
  elseif(LaserLib.IsValid(ent) and ent:GetClass() == gsLaserptCls) then
    local idx = self:GetClientInfo("portalexit"); ent:SetEntityExitID(idx)
    LaserLib.Notify(ply, "Paste ID"..self:GetUnit(ent).."["..idx.."] !", "UNDO")
    return true
  end

  local laser = LaserLib.NewLaser(ply        , pos         , ang         , model       ,
                                  trandata   , key         , width       , length      ,
                                  damage     , material    , dissolvetype, startsound  ,
                                  stopsound  , killsound   , toggle      , starton     ,
                                  pushforce  , endingeffect, reflectrate , refractrate ,
                                  forcecenter, frozen      , enonvermater, ensafebeam  , raycolor)

  if(not (LaserLib.IsValid(laser))) then return false end

  LaserLib.ApplySpawn(laser, trace, self:GetTransform())

  local we, nc = LaserLib.Weld(laser, trace, surfweld, nocollide, forcelimit)

  undo.Create("Laser emitter ["..laser:EntIndex().."]")
    undo.AddEntity(laser)
    if(we) then undo.AddEntity(we) end
    if(nc) then undo.AddEntity(nc) end
    undo.SetPlayer(ply)
  undo.Finish()

  ply:AddCount(gsTool.."s", laser)
  ply:AddCleanup(gsTool.."s", laser)

  LaserLib.Notify(ply, "Laser created !", "GENERIC")

  return true
end

function TOOL:RightClick(trace)
  if(CLIENT) then return true end
  if(not trace) then return false end
  local ply, ent = self:GetOwner(), trace.Entity
  if(trace.HitWorld) then
    return false -- TODO: Make it actually do something
  else
    if(not LaserLib.IsValid(ent)) then return false end
    if(LaserLib.IsSource(ent)) then
      local r, g, b, a = ent:GetBeamColorRGBA()
      LaserLib.ConCommand(ply, "colorr"      , r)
      LaserLib.ConCommand(ply, "colorg"      , g)
      LaserLib.ConCommand(ply, "colorb"      , b)
      LaserLib.ConCommand(ply, "colora"      , a)
      LaserLib.ConCommand(ply, "width"       , ent:GetBeamWidth())
      LaserLib.ConCommand(ply, "length"      , ent:GetBeamLength())
      LaserLib.ConCommand(ply, "damage"      , ent:GetBeamDamage())
      LaserLib.ConCommand(ply, "ensafebeam"  , ent:GetBeamSafety())
      LaserLib.ConCommand(ply, "material"    , ent:GetBeamMaterial())
      LaserLib.ConCommand(ply, "dissolvetype", ent:GetDissolveType())
      LaserLib.ConCommand(ply, "startsound"  , ent:GetStartSound())
      LaserLib.ConCommand(ply, "stopsound"   , ent:GetStopSound())
      LaserLib.ConCommand(ply, "killsound"   , ent:GetKillSound())
      LaserLib.ConCommand(ply, "pushforce"   , ent:GetBeamForce())
      LaserLib.ConCommand(ply, "forcecenter" , ent:GetForceCenter())
      LaserLib.ConCommand(ply, "reflectrate" , ent:GetReflectRatio())
      LaserLib.ConCommand(ply, "refractrate" , ent:GetRefractRatio())
      LaserLib.ConCommand(ply, "endingeffect", ent:GetEndingEffect())
      LaserLib.ConCommand(ply, "enonvermater", ent:GetNonOverMater())
      LaserLib.ConCommand(ply, "starton"     , (ent:GetOn() and 1 or 0))
      LaserLib.ConCommand(ply, "toggle"      , (ent:GetTable().runToggle and 1 or 0))
      LaserLib.Notify(ply, "Copy"..self:GetUnit(ent).."["..ent:EntIndex().."] settings !", "UNDO")
    elseif(ent:GetClass() == gsLaserptCls) then
      local idx = tostring(ent:EntIndex())
      LaserLib.ConCommand(ply, "portalexit", idx)
      LaserLib.Notify(ply, "Copy ID"..self:GetUnit(ent).."["..idx.."] !", "UNDO")
    else
      local nor, rnd, mar = trace.HitNormal, 3, LaserLib.GetData("WLMR")
      local ang = math.atan2(math.Round(nor:Dot(ent:GetUp()), rnd),
                             math.Round(nor:Dot(ent:GetForward()), rnd))
      local mod, ang = ent:GetModel(), math.deg(ang)
      local dir = Vector(trace.HitNormal); dir:Mul(mar)
      dir:Add(ent:GetPos()); dir:Set(ent:WorldToLocal(dir)); dir:Div(mar)
      local org = Vector(trace.HitPos); org:Set(ent:WorldToLocal(org))
      dir = tostring(dir):Trim():gsub("%s+", ",")
      org = tostring(org):Trim():gsub("%s+", ",")
      if(ply:KeyDown(IN_DUCK)) then -- Easy export selected model
        if(ply:KeyDown(IN_SPEED)) then -- Easy export custom model
          dir = "\""..tostring(dir):Trim():gsub("%s+", ",").."\""
          org = "\""..tostring(org):Trim():gsub("%s+", ",").."\""
          print("table.insert(moar, {\""..mod.."\",0,"..org..","..dir.."})")
        else
          print("table.insert(moar, {\""..mod.."\","..ang.."})")
        end
      else
        if(ply:KeyDown(IN_SPEED)) then
          LaserLib.ConCommand(ply, "model" , mod)
          LaserLib.ConCommand(ply, "angle" , ang)
          LaserLib.ConCommand(ply, "origin", org)
          LaserLib.ConCommand(ply, "direct", dir)
          LaserLib.Notify(ply, "Model: "..mod, "UNDO")
        else
          LaserLib.ConCommand(ply, "origin")
          LaserLib.ConCommand(ply, "direct")
          LaserLib.ConCommand(ply, "model" , mod)
          LaserLib.ConCommand(ply, "angle" , ang)
          LaserLib.Notify(ply, "Model: "..mod.." ["..ang.."]", "UNDO")
        end
      end
    end
  end; return true
end

function TOOL:Reload(trace)
  if(CLIENT) then return true end
  if(not trace) then return false end
  local ply, ent = self:GetOwner(), trace.Entity
  if(trace.HitWorld) then
    if(ply:KeyDown(IN_USE)) then
      LaserLib.ConCommand(ply, "openmaterial", "transparent"); return true
    elseif(ply:KeyDown(IN_SPEED)) then
      LaserLib.ConCommand(ply, "openmaterial", "mirror"); return true
    end; return false
  else
    if(not LaserLib.IsValid(ent))  then return false end
    if(ent:IsPlayer()) then return false end
    if(ply:KeyDown(IN_USE) and ent:GetClass() ~= gsLaserptCls) then
      LaserLib.SetMaterial(ent, self:GetClientInfo("refractused"))
    elseif(ply:KeyDown(IN_SPEED) and ent:GetClass() ~= gsLaserptCls) then
      LaserLib.SetMaterial(ent, self:GetClientInfo("reflectused"))
    elseif(ply:KeyDown(IN_DUCK) and ent:GetCreator() == ply) then
      ent:Remove()
    else
      if(ent:GetClass() == gsLaserptCls) then
        local idx = (tonumber(ent:GetEntityExitID()) or 0)
        local txt = ((idx ~= 0) and tostring(idx) or gsNoAV); ent:SetEntityExitID(0)
        LaserLib.Notify(ply, "Clear ID"..self:GetUnit(ent).."["..txt.."] !", "UNDO")
      else
        LaserLib.SetMaterial(ent)
      end
    end; return true
  end; return false
end

function TOOL:UpdateGhostLaserEmitter(ent, ply)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsValid(ply)) then return end
  if(not ply:IsPlayer()) then return end
  if(ent:IsPlayer()) then return end

  local trace = ply:GetEyeTrace()

  LaserLib.ApplySpawn(ent, trace, self:GetTransform())

  if(not trace.Hit
      or trace.Entity:IsPlayer()
      or trace.Entity:GetClass() == gsLaseremCls
      or trace.Entity:GetClass() == gsLaserptCls)
  then
    ent:SetNoDraw(true)
    return
  end

  ent:SetNoDraw(false)
end

function TOOL:GetSurface(ent)
  if(not LaserLib.IsValid(ent)) then return end
  local ces = ent:GetClass()
  local mat = ent:GetMaterial()
  local row = LaserLib.DataReflect(mat)
  if(row) then
    if(ces == gsLaserelCls) then
      row = {ent:GetReflectRatio()}
    end
    return "{"..table.concat(row, "|").."} "..mat
  else row = LaserLib.DataRefract(mat)
    if(row) then
      if(ces == gsLasererCls) then
        row = ent:GetRefractInfo(row)
        row[1] = math.Round(row[1], 3)
        row[2] = math.Round(row[2], 3)
      end
      local fnm = "["..LaserLib.GetData("FNUH").."]"
      local ang = LaserLib.GetRefractAngle(row[1], 1, true)
      return fnm:format(ang).."{"..table.concat(row, "|").."} "..mat
    end
  end
end

function TOOL:DrawHUD()
  local ply = LocalPlayer()
  local tr = ply:GetEyeTrace()
  if(not (tr and tr.Hit)) then return end
  local txt = self:GetSurface(tr.Entity)
  local ray = self:GetClientNumber("rayassist", 0)
  LaserLib.DrawAssist(tr.HitPos, tr.HitNormal, ray)
  LaserLib.DrawTextHUD(txt)
end

function TOOL:Think()
  local model = self:GetClientInfo("model")

  if(not LaserLib.IsValid(self.GhostEntity)
      or self.GhostEntity:GetModel() ~= model)
  then
    local pos, ang = LaserLib.GetZeroTransform()
    self:MakeGhostEntity(model, pos, ang)
  end

  self:UpdateGhostLaserEmitter(self.GhostEntity, self:GetOwner())
end

local gtConvarList = TOOL:BuildConVarList()

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(panel) local pItem, pName, vData
  panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
  panel:SetName(language.GetPhrase("tool."..gsTool..".name"))
  panel:Help   (language.GetPhrase("tool."..gsTool..".desc"))

  pItem = vgui.Create("ControlPresets", panel)
  pItem:SetPreset(gsTool)
  pItem:AddOption("Default", gtConvarList)
  for key, val in pairs(table.GetKeys(gtConvarList)) do pItem:AddConVar(val) end
  panel:AddItem(pItem)

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetConVar1(gsTool.."_key")
  pItem:SetLabel1(language.GetPhrase("tool."..gsTool..".key_con"))
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsTool..".key"))
  panel:AddPanel(pItem)

  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTool..".width_con"), gsTool.."_width", 0, LaserLib.GetData("MXBMWIDT"):GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".width")); pItem:SetDefaultValue(gtConvarList[gsTool.."_width"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTool..".length_con"), gsTool.."_length", 0, LaserLib.GetData("MXBMLENG"):GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".length")); pItem:SetDefaultValue(gtConvarList[gsTool.."_length"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTool..".damage_con"), gsTool.."_damage", 0, LaserLib.GetData("MXBMDAMG"):GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".damage")); pItem:SetDefaultValue(gtConvarList[gsTool.."_damage"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTool..".pushforce_con"), gsTool.."_pushforce", 0, LaserLib.GetData("MXBMFORC"):GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".pushforce")); pItem:SetDefaultValue(gtConvarList[gsTool.."_pushforce"])
  pItem = panel:MatSelect(gsTool.."_material", list.GetForEdit("LaserEmitterMaterials"), true, 0.15, 0.24)
  pItem.Label:SetText(language.GetPhrase("tool."..gsTool..".material_con"))
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".material"))

  pItem = vgui.Create("CtrlColor", panel)
  pItem:Dock(TOP); pItem:SetTall(250)
  pItem:SetLabel(language.GetPhrase("tool."..gsTool..".color_con"))
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".color"))
  pItem:SetConVarR(gsTool.."_colorr")
  pItem:SetConVarG(gsTool.."_colorg")
  pItem:SetConVarB(gsTool.."_colorb")
  pItem:SetConVarA(gsTool.."_colora")
  panel:AddPanel(pItem)

  pItem = vgui.Create("PropSelect", panel)
  pItem:Dock(TOP); pItem:SetTall(100)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".model"))
  pItem:ControlValues({ -- garrysmod/lua/vgui/propselect.lua#L99
    models = list.GetForEdit("LaserEmitterModels"),
    label  = language.GetPhrase("tool."..gsTool..".model_con")
  }); panel:AddItem(pItem)

  LaserLib.ComboBoxString(panel, "dissolvetype", "LaserDissolveTypes")
  LaserLib.ComboBoxString(panel, "startsound"  , "LaserStartSounds"  )
  LaserLib.ComboBoxString(panel, "stopsound"   , "LaserStopSounds"   )
  LaserLib.ComboBoxString(panel, "killsound"   , "LaserKillSounds"   )

  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTool..".forcelimit_con"), gsTool.."_forcelimit", 0, LaserLib.GetData("MFORCELM"):GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".forcelimit")); pItem:SetDefaultValue(gtConvarList[gsTool.."_forcelimit"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTool..".rayassist_con"), gsTool.."_rayassist", 0, LaserLib.GetData("MAXRAYAS"):GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".rayassist")); pItem:SetDefaultValue(gtConvarList[gsTool.."_rayassist"])
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".surfweld_con"), gsTool.."_surfweld")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".surfweld"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".nocollide_con"), gsTool.."_nocollide")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".nocollide"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".frozen_con"), gsTool.."_frozen")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".frozen"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".toggle_con"), gsTool.."_toggle")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".toggle"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".starton_con"), gsTool.."_starton")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".starton"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".endingeffect_con"), gsTool.."_endingeffect")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".endingeffect"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".reflectrate_con"), gsTool.."_reflectrate")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".reflectrate"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".refractrate_con"), gsTool.."_refractrate")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".refractrate"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".forcecenter_con"), gsTool.."_forcecenter")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".forcecenter"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".enonvermater_con"), gsTool.."_enonvermater")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".enonvermater"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTool..".ensafebeam_con"), gsTool.."_ensafebeam")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTool..".ensafebeam"))
end
