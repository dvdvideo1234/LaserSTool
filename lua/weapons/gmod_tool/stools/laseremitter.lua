local gsTOOL     = LaserLib.GetTool()
local gsNOAV     = LaserLib.GetData("NOAV")
local gtAMAX     = LaserLib.GetData("AMAX")
local gsKEYA     = LaserLib.GetData("KEYA")
local gnGRAT     = LaserLib.GetData("GRAT")
local gnWLMR     = LaserLib.GetData("WLMR")
local gsFNUH     = LaserLib.GetData("FNUH")
local gsLSEP     = LaserLib.GetData("LSEP")
local gtDISPERSE = LaserLib.GetData("DISPERSE")
local cvMXBMWIDT = LaserLib.GetData("MXBMWIDT")
local cvMXBMLENG = LaserLib.GetData("MXBMLENG")
local cvMXBMDAMG = LaserLib.GetData("MXBMDAMG")
local cvMXBMFORC = LaserLib.GetData("MXBMFORC")
local cvMFORCELM = LaserLib.GetData("MFORCELM")
local cvMAXRAYAS = LaserLib.GetData("MAXRAYAS")
local cvLANGUAGE = GetConVar("gmod_language")

PrintTable(LaserLib)

if(CLIENT) then

  TOOL.Information = {
    {name = "info"      , icon = "gui/info"   },
    {name = "mater"     , icon = LaserLib.GetIcon("wand")},
    {name = "left"      , icon = "gui/lmb.png"},
    {name = "right"     , icon = "gui/rmb.png"},
    {name = "reload"    , icon = "gui/r.png"  },
    {name = "reload_use", icon = "gui/r.png"  , icon2 = "gui/e.png"},
  }

  -- Listen for changes to the localify language and reload the tool's menu to update the localizations
  cvars.RemoveChangeCallback(cvLANGUAGE:GetName(), gsTOOL.."lang")
  cvars.AddChangeCallback(cvLANGUAGE:GetName(), function(sNam, vO, vN)
    local oUser = LocalPlayer(); if(not IsValid(oUser)) then return end
    local oTool = oUser:GetTool(gsTOOL); if(not oTool) then return end
    -- Retrieve the control panel from the tool main tab
    local fCont = oTool.BuildCPanel; if(not fCont) then return end
    local pCont = controlpanel.Get(gsTOOL) if(IsValid(pCont)) then
      pCont:ClearControls()
      local bS, vOut = pcall(fCont, pCont)
      if(not bS) then error("Control error: "..vOut) end
    end -- Wipe the panel so it is clear of contents sliders buttons and stuff
    -- Retrieve the utilities user preferencies panel
    local pUser = controlpanel.Get(gsTOOL.."_utilities_user")
    if(IsValid(pUser)) then -- User panel exists. Update it
      local fUser = LaserLib.Controls("Utilities", "User")
      if(fUser) then pUser:ClearControls()
        local bS, vOut = pcall(fUser, pUser)
        if(not bS) then error("User error: "..vOut) end
      end -- User panel is updated with other language
    end -- Retrieve the utilities admin preferencies panel
    local pAdmn = controlpanel.Get(gsTOOL.."_utilities_admin")
    if(IsValid(pAdmn)) then -- Admin panel exists. Update it
      local fAdmn = LaserLib.Controls("Utilities", "Admin")
      if(fAdmn) then pAdmn:ClearControls()
        local bS, vOut = pcall(fAdmn, pAdmn)
        if(not bS) then error("Admin error: "..vOut) end
      end -- Admin panel is updated with other language
    end -- Panels are cleared and we change the language utilizing localify
  end, gsTOOL.."lang")

  -- http://www.famfamfam.com/lab/icons/silk/preview.php
  concommand.Add(gsTOOL.."_openmaterial",
    function(user, cmd, args)
      local base, tseq, sors
      local argm = tostring(args[1] or ""):upper()
      if(argm == "MIRROR") then
        sors = "REFLECT"
        base = LaserLib.DataReflect(gsKEYA)
        tseq = LaserLib.GetSequenceData(base)
      elseif(argm == "TRANSPARENT") then
        sors = "REFRACT"
        base = LaserLib.DataRefract(gsKEYA)
        tseq = LaserLib.GetSequenceData(base)
      else return nil end
      tseq.Sors = sors:lower().."used"
      tseq.Conv = GetConVar(gsTOOL.."_"..tseq.Sors)
      tseq.Name = language.GetPhrase("tool."..gsTOOL..".openmaterial").." "..argm
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
            pnCombo:SetSize(pnFrame:GetWide() - (gnGRAT - 1) * pnFrame:GetWide(), 25)
            pnCombo:SetTooltip(language.GetPhrase("tool."..gsTOOL..".openmanager_find"))
            pnCombo:SetValue(language.GetPhrase("tool."..gsTOOL..".openmanager_findv"))
            if(tseq[1]["Key"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTOOL..".openmanager_mepmn"), "Key", false, LaserLib.GetIcon("key_go")) end
            if(tseq[1]["Rate"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTOOL..".openmanager_meppr"), "Rate", false, LaserLib.GetIcon("chart_bar")) end
            if(tseq[1]["Ridx"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTOOL..".openmanager_mepri"), "Ridx", false, LaserLib.GetIcon("transmit")) end
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

TOOL.Category = "Construction"
TOOL.Name     = (language and language.GetPhrase("tool."..gsTOOL..".name"))

if(SERVER) then
  duplicator.RegisterEntityModifier("laseremitter_material",
    function(user, ent, dupe) LaserLib.SetMaterial(ent, dupe.MaterialOverride) end)

  duplicator.RegisterEntityModifier("laseremitter_properties",
    function(user, ent, dupe) LaserLib.SetMaterial(ent, dupe.Material) end)

  duplicator.RegisterEntityClass(LaserLib.GetClass(1), LaserLib.NewLaser,
    --[[  user  ]]  "pos"       , "ang"         , "model"      , "tranData"   ,
    "key"         , "width"     , "length"      , "damage"     , "material"   ,
    "dissolveType", "startSound", "stopSound"   , "killSound"  , "runToggle"  ,
    "startOn"     , "pushForce" , "endingEffect", "reflectRate", "refractRate",
    "forceCenter" , "frozen"    , "enOverMater" , "enSafeBeam" , "enIgneBeam" , "rayColor")

  CreateConVar("sbox_max"..gsTOOL.."s", 20)
end

cleanup.Register(gsTOOL.."s")

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
  [ "skin"         ] = 0,
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
  [ "enonvermater" ] = 0,
  [ "ensafebeam"   ] = 0,
  [ "enignebeam"   ] = 0,
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

cleanup.Register(gsTOOL.."s")

function TOOL:Holster()
  if(LaserLib.IsValid(self.GhostEntity)) then
    self.GhostEntity:SetNoDraw(true)
    self.GhostEntity:Remove()
  end; self.GhostEntity = nil
end

function TOOL:GetAngleOffset()
  return math.Clamp(self:GetClientNumber("angle", 0), gtAMAX[1], gtAMAX[2])
end

function TOOL:GetSpawnSkin()
  return math.max(math.floor(self:GetClientNumber("skin", 0)), 0)
end

function TOOL:GetUnit(ent)
  if(not LaserLib.IsValid(ent)) then return gsNOAV end
  local css = ent:GetClass():gsub(LaserLib.GetClass(1), ""):gsub("^_", "")
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
  local user, ent = self:GetOwner(), trace.Entity
  if(ent:IsPlayer()) then return false end
  local swep = self:GetSWEP()
  if(not swep:CheckLimit(gsTOOL.."s")) then return false end
  local pos, ang     = trace.HitPos, trace.HitNormal:Angle()
  local trandata     = LaserLib.GetTransform(user)
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
  local enignebeam   = (self:GetClientNumber("enignebeam", 0) ~= 0)
  local enonvermater = (self:GetClientNumber("enonvermater", 0) ~= 0)
  local width        = math.Clamp(self:GetClientNumber("width", 0), 0, cvMXBMWIDT:GetFloat())
  local length       = math.Clamp(self:GetClientNumber("length", 0), 0, cvMXBMLENG:GetFloat())
  local damage       = math.Clamp(self:GetClientNumber("damage", 0), 0, cvMXBMDAMG:GetFloat())
  local pushforce    = math.Clamp(self:GetClientNumber("pushforce", 0), 0, cvMXBMFORC:GetFloat())
  local forcelimit   = math.Clamp(self:GetClientNumber("forcelimit", 0), 0, cvMFORCELM:GetFloat())

  if(LaserLib.IsValid(ent) and ent:GetClass() == LaserLib.GetClass(1)) then
    LaserLib.Notify(user, "Paste settings !", "UNDO")
    ent:Setup(width      , length      , damage    , material   , dissolvetype,
              startsound , stopsound   , killsound , toggle     , starton     ,
              pushforce  , endingeffect, trandata  , reflectrate, refractrate ,
              forcecenter, enonvermater, ensafebeam, enignebeam , raycolor    , true)
    return true
  elseif(LaserLib.IsValid(ent) and ent:GetClass() == LaserLib.GetClass(9)) then
    local idx = self:GetClientInfo("portalexit"); ent:SetEntityExitID(idx)
    LaserLib.Notify(user, "Paste ID"..self:GetUnit(ent).."["..idx.."] !", "UNDO")
    return true
  end

  local laser = LaserLib.NewLaser(user        , pos         , ang         , model       , trandata   ,
                                  key         , width       , length      , damage      , material   ,
                                  dissolvetype, startsound  , stopsound   , killsound   , toggle     ,
                                  starton     , pushforce   , endingeffect, reflectrate , refractrate,
                                  forcecenter , frozen      , enonvermater, ensafebeam  , enignebeam , raycolor)

  if(not (LaserLib.IsValid(laser))) then return false end

  LaserLib.ApplySpawn(laser, trace, trandata)

  local we, nc = LaserLib.Weld(laser, trace, surfweld, nocollide, forcelimit)

  undo.Create("Laser emitter ["..laser:EntIndex().."]")
    undo.AddEntity(laser)
    if(we) then undo.AddEntity(we) end
    if(nc) then undo.AddEntity(nc) end
    undo.SetPlayer(user)
  undo.Finish()

  user:AddCount(gsTOOL.."s", laser)
  user:AddCleanup(gsTOOL.."s", laser)

  LaserLib.Notify(user, "Laser created !", "GENERIC")

  return true
end

function TOOL:RightClick(trace)
  if(CLIENT) then return true end
  if(not trace) then return false end
  local user, ent = self:GetOwner(), trace.Entity
  if(trace.HitWorld) then
    return false -- TODO: Make it actually do something
  else
    if(not LaserLib.IsValid(ent)) then return false end
    if(LaserLib.IsSource(ent)) then
      local r, g, b, a = ent:GetBeamColorRGBA()
      LaserLib.ConCommand(user, "colorr"      , r)
      LaserLib.ConCommand(user, "colorg"      , g)
      LaserLib.ConCommand(user, "colorb"      , b)
      LaserLib.ConCommand(user, "colora"      , a)
      LaserLib.ConCommand(user, "width"       , ent:GetBeamWidth())
      LaserLib.ConCommand(user, "length"      , ent:GetBeamLength())
      LaserLib.ConCommand(user, "damage"      , ent:GetBeamDamage())
      LaserLib.ConCommand(user, "ensafebeam"  , (ent:GetBeamSafety() and 1 or 0))
      LaserLib.ConCommand(user, "enignebeam"  , (ent:GetBeamSafety() and 1 or 0))
      LaserLib.ConCommand(user, "material"    , ent:GetBeamMaterial())
      LaserLib.ConCommand(user, "dissolvetype", ent:GetDissolveType())
      LaserLib.ConCommand(user, "startsound"  , ent:GetStartSound())
      LaserLib.ConCommand(user, "stopsound"   , ent:GetStopSound())
      LaserLib.ConCommand(user, "killsound"   , ent:GetKillSound())
      LaserLib.ConCommand(user, "pushforce"   , ent:GetBeamForce())
      LaserLib.ConCommand(user, "forcecenter" , ent:GetForceCenter())
      LaserLib.ConCommand(user, "reflectrate" , ent:GetReflectRatio())
      LaserLib.ConCommand(user, "refractrate" , ent:GetRefractRatio())
      LaserLib.ConCommand(user, "endingeffect", ent:GetEndingEffect())
      LaserLib.ConCommand(user, "enonvermater", (ent:GetNonOverMater() and 1 or 0))
      LaserLib.ConCommand(user, "starton"     , (ent:GetOn() and 1 or 0))
      LaserLib.ConCommand(user, "toggle"      , (ent:GetTable().runToggle and 1 or 0))
      LaserLib.Notify(user, "Copy"..self:GetUnit(ent).."["..ent:EntIndex().."] settings !", "UNDO")
    elseif(ent:GetClass() == LaserLib.GetClass(9)) then
      local idx = tostring(ent:EntIndex())
      LaserLib.ConCommand(user, "portalexit", idx)
      LaserLib.Notify(user, "Copy ID"..self:GetUnit(ent).."["..idx.."] !", "UNDO")
    else
      local nor, rnd = trace.HitNormal, 3
      local ang = math.atan2(math.Round(nor:Dot(ent:GetUp()), rnd),
                             math.Round(nor:Dot(ent:GetForward()), rnd))
      local mod, ang = ent:GetModel(), math.deg(ang)
      local dir = Vector(trace.HitNormal); dir:Mul(gnWLMR)
      dir:Add(ent:GetPos()); dir:Set(ent:WorldToLocal(dir)); dir:Div(gnWLMR)
      local org = Vector(trace.HitPos); org:Set(ent:WorldToLocal(org))
      dir = tostring(dir):Trim():gsub("%s+", gsLSEP)
      org = tostring(org):Trim():gsub("%s+", gsLSEP)
      if(user:KeyDown(IN_DUCK)) then -- Easy export selected model
        if(user:KeyDown(IN_SPEED)) then -- Easy export custom model
          dir = "\""..tostring(dir):Trim():gsub("%s+", gsLSEP).."\""
          org = "\""..tostring(org):Trim():gsub("%s+", gsLSEP).."\""
          print("table.insert(moar, {\""..mod.."\",0,"..org..","..dir.."})")
        else
          print("table.insert(moar, {\""..mod.."\","..ang.."})")
        end
      else
        if(user:KeyDown(IN_SPEED)) then
          LaserLib.ConCommand(user, "model" , mod)
          LaserLib.ConCommand(user, "angle" , ang)
          LaserLib.ConCommand(user, "origin", org)
          LaserLib.ConCommand(user, "direct", dir)
          LaserLib.Notify(user, "Model: "..mod, "UNDO")
        else
          LaserLib.ConCommand(user, "origin")
          LaserLib.ConCommand(user, "direct")
          LaserLib.ConCommand(user, "model" , mod)
          LaserLib.ConCommand(user, "angle" , ang)
          LaserLib.Notify(user, "Model: "..mod.." ["..ang.."]", "UNDO")
        end
      end
    end
  end; return true
end

function TOOL:Reload(trace)
  if(CLIENT) then return true end
  if(not trace) then return false end
  local user, ent = self:GetOwner(), trace.Entity
  if(trace.HitWorld) then
    if(user:KeyDown(IN_USE)) then
      LaserLib.ConCommand(user, "openmaterial", "transparent"); return true
    elseif(user:KeyDown(IN_SPEED)) then
      LaserLib.ConCommand(user, "openmaterial", "mirror"); return true
    end; return false
  else
    if(not LaserLib.IsValid(ent))  then return false end
    if(ent:IsPlayer()) then return false end
    if(user:KeyDown(IN_USE) and ent:GetClass() ~= LaserLib.GetClass(9)) then
      LaserLib.SetMaterial(ent, self:GetClientInfo("refractused"))
    elseif(user:KeyDown(IN_SPEED) and ent:GetClass() ~= LaserLib.GetClass(9)) then
      LaserLib.SetMaterial(ent, self:GetClientInfo("reflectused"))
    elseif(user:KeyDown(IN_DUCK) and (LaserLib.GetOwner(ent) == user or user:IsAdmin())) then
      ent:Remove()
    else
      if(ent:GetClass() == LaserLib.GetClass(9)) then
        local idx = (tonumber(ent:GetEntityExitID()) or 0)
        local txt = ((idx ~= 0) and tostring(idx) or gsNOAV); ent:SetEntityExitID(0)
        LaserLib.Notify(user, "Clear ID"..self:GetUnit(ent).."["..txt.."] !", "UNDO")
      else
        LaserLib.SetMaterial(ent)
      end
    end; return true
  end; return false
end

function TOOL:UpdateEmitterGhost(ent, user)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsValid(user)) then return end
  if(not user:IsPlayer()) then return end
  if(ent:IsPlayer()) then return end

  local trace = user:GetEyeTrace()
  local tre = trace.Entity
  local pos = trace.HitPos
  local ang = trace.HitNormal:Angle()
  ent:SetPos(pos); ent:SetAngles(ang)

  LaserLib.ApplySpawn(ent, trace, LaserLib.GetTransform(user))

  if(not trace.Hit or tre:IsPlayer()
      or tre:GetClass() == LaserLib.GetClass(1)
      or tre:GetClass() == LaserLib.GetClass(9))
  then
    ent:SetNoDraw(true); return
  end

  ent:SetNoDraw(false)
end

function TOOL:GetSurface(user, ent, pos)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsValid(user)) then return end
  local ces = ent:GetClass()
  local mat = ent:GetMaterial()
  local row = LaserLib.DataReflect(mat)
  if(row) then
    if(ces == LaserLib.GetClass(3)) then
      row = ent:GetReflectInfo(row)
      row[1] = math.Round(row[1], 3)
    end
    return "{"..table.concat(row, "|").."} "..mat
  else row = LaserLib.DataRefract(mat)
    if(row) then
      if(ces == LaserLib.GetClass(12)) then
        row = ent:GetRefractInfo(row)
        row[1] = math.Round(row[1], 3)
        row[2] = math.Round(row[2], 3)
      end
      local rww = LaserLib.DataRefract("water")
      local con = LaserLib.IsContent(pos, rww.Con)
      local idx, fnm = (con and rww[1] or 1), "["..gsFNUH.."]"
      local ang = LaserLib.GetRefractAngle(row[1], idx, true)
      return fnm:format(ang).."{"..table.concat(row, "|").."} "..mat
    end
  end
end

function TOOL:DrawHUD()
  local user = LocalPlayer()
  local tr = user:GetEyeTrace()
  if(not (tr and tr.Hit)) then return end
  local txt = self:GetSurface(user, tr.Entity, tr.HitPos)
  local ray = self:GetClientNumber("rayassist", 0)
  LaserLib.DrawAssist(tr.HitPos, tr.HitNormal, ray)
  LaserLib.DrawTextHUD(txt)
end

function TOOL:Think()
  local model = self:GetClientInfo("model")

  print(1, self.GhostEntity, model)

  if(not LaserLib.IsValid(self.GhostEntity)
      or self.GhostEntity:GetModel() ~= model)
  then
    local pos, ang = LaserLib.GetZeroTransform()

    print(2, model, util.IsValidProp( model ), pos, ang)

    self:MakeGhostEntity(model, pos, ang)
  end

  self:UpdateEmitterGhost(self.GhostEntity, self:GetOwner())
end

local gtConvarList = TOOL:BuildConVarList()

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(cPanel)
  cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10)
  cPanel:SetName(language.GetPhrase("tool."..gsTOOL..".name"))
  cPanel:Help   (language.GetPhrase("tool."..gsTOOL..".desc"))

  pCon = vgui.Create("ControlPresets", cPanel)
  pCon:SetPreset(gsTOOL)
  pCon:AddOption("Default", gtConvarList)
  for key, val in pairs(table.GetKeys(gtConvarList)) do pCon:AddConVar(val) end
  cPanel:AddItem(pCon)

  pNum = vgui.Create("CtrlNumPad", cPanel)
  pNum:SetConVar1(gsTOOL.."_key")
  pNum:SetLabel1(language.GetPhrase("tool."..gsTOOL..".key_con"))
  pNum.NumPad1:SetTooltip(language.GetPhrase("tool."..gsTOOL..".key"))
  cPanel:AddPanel(pNum)

  LaserLib.NumSlider(cPanel, "width"    , 0, cvMXBMWIDT:GetFloat(), gtConvarList[gsTOOL.."_width"])
  LaserLib.NumSlider(cPanel, "length"   , 0, cvMXBMLENG:GetFloat(), gtConvarList[gsTOOL.."_length"])
  LaserLib.NumSlider(cPanel, "damage"   , 0, cvMXBMDAMG:GetFloat(), gtConvarList[gsTOOL.."_damage"])
  LaserLib.NumSlider(cPanel, "pushforce", 0, cvMXBMFORC:GetFloat(), gtConvarList[gsTOOL.."_pushforce"])

  local tMat = list.GetForEdit("LaserEmitterMaterials")
  local tKey = table.GetKeys(tMat) -- Sort the keys table on material
  table.sort(tKey, function(u, v) return tMat[u].name < tMat[v].name end)
  pMat = cPanel:MatSelect(gsTOOL.."_material", nil, true, 0.15, 0.24)
  pMat.Label:SetText(language.GetPhrase("tool."..gsTOOL..".material_con"))
  pMat:SetTooltip(language.GetPhrase("tool."..gsTOOL..".material"))
  for iK = 1, #tKey do
    local key = tKey[iK]
    local val, nam = tMat[key], nil
    local pImg = pMat:AddMaterial(key, val.name)
    key = ((key:sub(1,1) == "#") and key:sub(2,-1) or key)
    nam = language.GetPhrase(key); pImg:SetTooltip(nam)
    function pImg:DoClick()
      LaserLib.SetPaintOver(pMat, self)
      LaserLib.ConCommand(nil, "material", self.Value)
    end
    function pImg:DoRightClick()
      local pnMenu = DermaMenu(false, self)
      if(not IsValid(pnMenu)) then return end
      local pMenu, pOpts = pnMenu:AddSubMenu(language.GetPhrase("tool."..gsTOOL..".openmanager_copy"))
      if(not IsValid(pMenu)) then return end
      if(not IsValid(pOpts)) then return end
      pOpts:SetImage(LaserLib.GetIcon("page_copy"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copyn"),
        function() SetClipboardText(nam) end):SetIcon(LaserLib.GetIcon("textfield_rename"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copyi"),
        function() SetClipboardText(key) end):SetIcon(LaserLib.GetIcon("key"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copym"),
        function() SetClipboardText(val.name) end):SetIcon(LaserLib.GetIcon("lightning"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copya"),
        function() SetClipboardText(nam..":"..key..">"..val.name) end):SetIcon(LaserLib.GetIcon("asterisk_yellow"))
      local pMenu, pOpts = pnMenu:AddSubMenu(language.GetPhrase("tool."..gsTOOL..".openmanager_sort"))
      if(not IsValid(pMenu)) then return end
      if(not IsValid(pOpts)) then return end
      pOpts:SetImage(LaserLib.GetIcon("table_sort"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepmn").." (<)", function()
        LaserLib.SortDisperse(pMat, nil, false) end):SetImage(LaserLib.GetIcon("arrow_down"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepmn").." (>)", function()
        LaserLib.SortDisperse(pMat, nil, true) end):SetImage(LaserLib.GetIcon("arrow_up"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepci").." (<)", function()
        LaserLib.SortDisperse(pMat, function(r,g,b) return r+g+b end, false) end):SetImage(LaserLib.GetIcon("arrow_down"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepci").." (>)", function()
        LaserLib.SortDisperse(pMat, function(r,g,b) return r+g+b end, true) end):SetImage(LaserLib.GetIcon("arrow_up"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepcn").." (<)", function()
        LaserLib.SortDisperse(pMat, math.min, false) end):SetImage(LaserLib.GetIcon("arrow_down"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepcn").." (>)", function()
        LaserLib.SortDisperse(pMat, math.min, true) end):SetImage(LaserLib.GetIcon("arrow_up"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepcx").." (<)", function()
        LaserLib.SortDisperse(pMat, math.max, false) end):SetImage(LaserLib.GetIcon("arrow_down"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepcx").." (>)", function()
        LaserLib.SortDisperse(pMat, math.max, true) end):SetImage(LaserLib.GetIcon("arrow_up"))
      pnMenu:Open()
    end
  end

  pMix = vgui.Create("DColorMixer", cPanel)
  pMix:Dock(TOP); pMix:SetTall(250)
  pMix:SetLabel(language.GetPhrase("tool."..gsTOOL..".color_con"))
  pMix:SetTooltip(language.GetPhrase("tool."..gsTOOL..".color"))
  pMix:SetConVarR(gsTOOL.."_colorr")
  pMix:SetConVarG(gsTOOL.."_colorg")
  pMix:SetConVarB(gsTOOL.."_colorb")
  pMix:SetConVarA(gsTOOL.."_colora")
  pMix:SetWangs(true)
  pMix:SetPalette(true)
  pMix:SetAlphaBar(true)
  cPanel:AddItem(pMix)

  local tProp = list.GetForEdit("LaserEmitterModels")
  local uProp = table.GetKeys(tProp); table.sort(uProp, function(u, v) return u < v end)
  pProp = vgui.Create("PropSelect", cPanel)
  pProp.Height = 4; pProp:Dock(TOP) -- Stretch the panel to have 4 rows
  pProp:SetConVar(gsTOOL.."_model") -- Primary convar is the model
  pProp:SetTooltip(language.GetPhrase("tool."..gsTOOL..".model"))
  pProp.Label:SetText(language.GetPhrase("tool."..gsTOOL..".model_con"))
  for i = 1, #uProp do
    local key = uProp[i]
    local val = tProp[key]
    local pIco = pProp:AddModel(key, val); pIco:SetTooltip(key)
    function pIco:DoRightClick()
      local pnMenu = DermaMenu(false, self)
      if(not IsValid(pnMenu)) then return end
      local pMenu, pOpts = pnMenu:AddSubMenu(language.GetPhrase("tool."..gsTOOL..".openmanager_copy"))
      if(not IsValid(pMenu)) then return end
      if(not IsValid(pOpts)) then return end
      pOpts:SetImage(LaserLib.GetIcon("page_copy"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copyu"),
        function() SetClipboardText(key) end):SetIcon(LaserLib.GetIcon("brick"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copyi"),
        function() SetClipboardText(tostring(i)) end):SetIcon(LaserLib.GetIcon("key"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_copya"),
        function() -- Concatenate all model configurations and send them to the clipboard
          local ang, skn = LaserLib.GetEmpty(val[gsTOOL.."_angle" ]), LaserLib.GetEmpty(val[gsTOOL.."_skin"  ])
          local org, dir = LaserLib.GetEmpty(val[gsTOOL.."_origin"]), LaserLib.GetEmpty(val[gsTOOL.."_direct"])
          SetClipboardText(key..":"..ang.."|"..org.."|"..dir.."|"..skn) end):SetIcon(LaserLib.GetIcon("asterisk_yellow"))
      local pMenu, pOpts = pnMenu:AddSubMenu(language.GetPhrase("tool."..gsTOOL..".openmanager_sort"))
      if(not IsValid(pMenu)) then return end
      if(not IsValid(pOpts)) then return end
      pOpts:SetImage(LaserLib.GetIcon("table_sort"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepun").." (<)", function()
        table.sort(pProp.List.Items, function(u,v) return (u.Value < v.Value) end)
        pProp.List:PerformLayout() end):SetImage(LaserLib.GetIcon("arrow_down"))
      pMenu:AddOption(language.GetPhrase("tool."..gsTOOL..".openmanager_mepun").." (>)", function()
        table.sort(pProp.List.Items, function(u,v) return (u.Value > v.Value) end)
        pProp.List:PerformLayout() end):SetImage(LaserLib.GetIcon("arrow_up"))
      local skn = NumModelSkins(key)
      if(skn > 0) then -- In case the model has any skins list them here
        local cS = tonumber(val[gsTOOL.."_skin"]) -- Current selected skin (empty)
        local trn = language.GetPhrase("tool."..gsTOOL..".openmanager_skin")
        local pMenu, pOpts = pnMenu:AddSubMenu(trn)
        if(not IsValid(pMenu)) then return end
        if(not IsValid(pOpts)) then return end
        pOpts:SetImage(LaserLib.GetIcon("camera"))
        for iS = 1, skn do local vS = (iS - 1)
          local sS = ((cS == vS) and ("["..vS.."]") or vS)
          pMenu:AddOption(trn..": "..tostring(sS), function()
            val[gsTOOL.."_skin"] = vS end):SetImage(LaserLib.GetIcon("paintbrush"))
        end
      end
      pnMenu:Open()
    end
  end; cPanel:AddItem(pProp)

  LaserLib.ComboBoxString(cPanel, "dissolvetype", "LaserDissolveTypes")
  LaserLib.ComboBoxString(cPanel, "startsound"  , "LaserStartSounds"  )
  LaserLib.ComboBoxString(cPanel, "stopsound"   , "LaserStopSounds"   )
  LaserLib.ComboBoxString(cPanel, "killsound"   , "LaserKillSounds"   )

  LaserLib.NumSlider(cPanel, "forcelimit", 0, cvMFORCELM:GetFloat(), gtConvarList[gsTOOL.."_forcelimit"])
  LaserLib.NumSlider(cPanel, "rayassist" , 0, cvMAXRAYAS:GetFloat(), gtConvarList[gsTOOL.."_rayassist"])
  LaserLib.CheckBox (cPanel, "surfweld")
  LaserLib.CheckBox (cPanel, "nocollide")
  LaserLib.CheckBox (cPanel, "frozen")
  LaserLib.CheckBox (cPanel, "toggle")
  LaserLib.CheckBox (cPanel, "starton")
  LaserLib.CheckBox (cPanel, "endingeffect")
  LaserLib.CheckBox (cPanel, "reflectrate")
  LaserLib.CheckBox (cPanel, "refractrate")
  LaserLib.CheckBox (cPanel, "forcecenter")
  LaserLib.CheckBox (cPanel, "enonvermater")
  LaserLib.CheckBox (cPanel, "ensafebeam")
  LaserLib.CheckBox (cPanel, "enignebeam")
end

if(CLIENT) then
  -- Enter `spawnmenu_reload` in the console to reload the panel
  local function setupUserSettings(cPanel)
    cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10)
    cPanel:SetName(language.GetPhrase("tool."..gsTOOL..".utilities_user"))
    cPanel:ControlHelp(language.GetPhrase("tool."..gsTOOL..".user_var"))
    LaserLib.NumSlider(cPanel, "lndiract" )
    LaserLib.NumSlider(cPanel, "drwbmspd" )
    LaserLib.NumSlider(cPanel, "effectdt" )
    LaserLib.NumSlider(cPanel, "nrassist" )
    LaserLib.NumSlider(cPanel, "maxrayast")
  end

  LaserLib.Controls("Utilities", "User", setupUserSettings)

  -- Enter `spawnmenu_reload` in the console to reload the panel
  local function setupAdminSettings(cPanel)
    cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10)
    cPanel:SetName(language.GetPhrase("tool."..gsTOOL..".utilities_admin"))
    cPanel:ControlHelp(language.GetPhrase("tool."..gsTOOL..".admin_var"))
    LaserLib.CheckBox (cPanel, "ensounds"  )
    LaserLib.NumSlider(cPanel, "maxspltbc" )
    LaserLib.NumSlider(cPanel, "maxbmwidt" )
    LaserLib.NumSlider(cPanel, "maxbmdamg" )
    LaserLib.NumSlider(cPanel, "maxbmforc" )
    LaserLib.NumSlider(cPanel, "maxbmleng" )
    LaserLib.NumSlider(cPanel, "maxbounces")
    LaserLib.NumSlider(cPanel, "maxforclim")
    LaserLib.NumSlider(cPanel, "nspliter"  )
    LaserLib.NumSlider(cPanel, "xspliter"  )
    LaserLib.NumSlider(cPanel, "yspliter"  )
    LaserLib.NumSlider(cPanel, "zspliter"  )
    LaserLib.NumSlider(cPanel, "damagedt"  )
    LaserLib.NumSlider(cPanel, "vesfbeam"  )
    LaserLib.NumSlider(cPanel, "timeasync" )
    LaserLib.NumSlider(cPanel, "blholesg"  )
    LaserLib.NumSlider(cPanel, "wdhuecnt"  )
    LaserLib.NumSlider(cPanel, "wdrgbmar"  )
  end

  LaserLib.Controls("Utilities", "Admin", setupAdminSettings)
end
