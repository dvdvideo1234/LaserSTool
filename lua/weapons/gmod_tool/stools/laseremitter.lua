local gsTOOL     = LaserLib.GetTool()
local gsNOAV     = LaserLib.GetData("NOAV")
local gtAMAX     = LaserLib.GetData("AMAX")
local gsKEYA     = LaserLib.GetData("KEYA")
local gnGRAT     = LaserLib.GetData("GRAT")
local gnWLMR     = LaserLib.GetData("WLMR")
local gsFNUH     = LaserLib.GetData("FNUH")
local cvMXBMWIDT = LaserLib.GetData("MXBMWIDT")
local cvMXBMLENG = LaserLib.GetData("MXBMLENG")
local cvMXBMDAMG = LaserLib.GetData("MXBMDAMG")
local cvMXBMFORC = LaserLib.GetData("MXBMFORC")
local cvMFORCELM = LaserLib.GetData("MFORCELM")
local cvMAXRAYAS = LaserLib.GetData("MAXRAYAS")

if(CLIENT) then

  TOOL.Information = {
    {name = "info"      , icon = "gui/info"   },
    {name = "mater"     , icon = LaserLib.GetIcon("wand")},
    {name = "left"      , icon = "gui/lmb.png"},
    {name = "right"     , icon = "gui/rmb.png"},
    {name = "reload"    , icon = "gui/r.png"  },
    {name = "reload_use", icon = "gui/r.png"  , icon2 = "gui/e.png"},
  }

  -- http://www.famfamfam.com/lab/icons/silk/preview.php
  concommand.Add(gsTOOL.."_openmaterial",
    function(ply, cmd, args)
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
      tseq.Name = language.GetPhrase("tool."..gsTOOL..".openmaterial")..argm
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
            pnCombo:SetTooltip(language.GetPhrase("tool."..gsTOOL..".openmaterial_find"))
            pnCombo:SetValue(language.GetPhrase("tool."..gsTOOL..".openmaterial_find0"))
            if(tseq[1]["Key"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTOOL..".openmaterial_find1"), "Key", false, LaserLib.GetIcon("key_go")) end
            if(tseq[1]["Rate"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTOOL..".openmaterial_find2"), "Rate", false, LaserLib.GetIcon("chart_bar")) end
            if(tseq[1]["Ridx"]) then pnCombo:AddChoice(language.GetPhrase("tool."..gsTOOL..".openmaterial_find3"), "Ridx", false, LaserLib.GetIcon("transmit")) end
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
TOOL.Name     = (language and language.GetPhrase("tool."..gsTOOL..".name"))

if(SERVER) then
  duplicator.RegisterEntityModifier("laseremitter_material",
    function(ply, ent, dupe) LaserLib.SetMaterial(ent, dupe.MaterialOverride) end)

  duplicator.RegisterEntityModifier("laseremitter_properties",
    function(ply, ent, dupe) LaserLib.SetMaterial(ent, dupe.Material) end)

  duplicator.RegisterEntityClass(LaserLib.GetClass(1), LaserLib.NewLaser,
    --[[  ply  ]]  "pos"         , "ang"         , "model"      ,
    "tranData"   , "key"         , "width"       , "length"     ,
    "damage"     , "material"    , "dissolveType", "startSound" ,
    "stopSound"  , "killSound"   , "runToggle"   , "startOn"    ,
    "pushForce"  , "endingEffect", "reflectRate" , "refractRate",
    "forceCenter", "frozen"      , "enOverMater" , "enSafeBeam" , "rayColor")

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
  [ "dissolvetype" ] = "core",
  [ "startsound"   ] = "ambient/energy/weld1.wav",
  [ "stopsound"    ] = "ambient/energy/weld2.wav",
  [ "killsound"    ] = "ambient/levels/citadel/weapon_disintegngrate1.wav",
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
  local nang = self:GetClientNumber("angle", 0)
  return math.Clamp(nang, gtAMAX[1], gtAMAX[2])
end

function TOOL:GetTransform()
  local tset = self.Settings
  tset[1] = self:GetAngleOffset()
  tset[2] = self:GetClientInfo("origin")
  tset[3] = self:GetClientInfo("direct")
  return LaserLib.SetupTransform(tset)
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
  local ply, ent = self:GetOwner(), trace.Entity
  if(ent:IsPlayer()) then return false end
  local swep = self:GetSWEP()
  if(not swep:CheckLimit(gsTOOL.."s")) then return false end
  local pos, ang     = trace.HitPos, trace.HitNormal:Angle()
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
  local width        = math.Clamp(self:GetClientNumber("width", 0), 0, cvMXBMWIDT:GetFloat())
  local length       = math.Clamp(self:GetClientNumber("length", 0), 0, cvMXBMLENG:GetFloat())
  local damage       = math.Clamp(self:GetClientNumber("damage", 0), 0, cvMXBMDAMG:GetFloat())
  local pushforce    = math.Clamp(self:GetClientNumber("pushforce", 0), 0, cvMXBMFORC:GetFloat())
  local forcelimit   = math.Clamp(self:GetClientNumber("forcelimit", 0), 0, cvMFORCELM:GetFloat())

  if(LaserLib.IsValid(ent) and ent:GetClass() == LaserLib.GetClass(1)) then
    LaserLib.Notify(ply, "Paste settings !", "UNDO")
    ent:Setup(width      , length      , damage    , material   , dissolvetype,
              startsound , stopsound   , killsound , toggle     , starton     ,
              pushforce  , endingeffect, trandata  , reflectrate, refractrate ,
              forcecenter, enonvermater, ensafebeam, raycolor   , true)
    return true
  elseif(LaserLib.IsValid(ent) and ent:GetClass() == LaserLib.GetClass(9)) then
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

  ply:AddCount(gsTOOL.."s", laser)
  ply:AddCleanup(gsTOOL.."s", laser)

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
    elseif(ent:GetClass() == LaserLib.GetClass(9)) then
      local idx = tostring(ent:EntIndex())
      LaserLib.ConCommand(ply, "portalexit", idx)
      LaserLib.Notify(ply, "Copy ID"..self:GetUnit(ent).."["..idx.."] !", "UNDO")
    else
      local nor, rnd = trace.HitNormal, 3
      local ang = math.atan2(math.Round(nor:Dot(ent:GetUp()), rnd),
                             math.Round(nor:Dot(ent:GetForward()), rnd))
      local mod, ang = ent:GetModel(), math.deg(ang)
      local dir = Vector(trace.HitNormal); dir:Mul(gnWLMR)
      dir:Add(ent:GetPos()); dir:Set(ent:WorldToLocal(dir)); dir:Div(gnWLMR)
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
    if(ply:KeyDown(IN_USE) and ent:GetClass() ~= LaserLib.GetClass(9)) then
      LaserLib.SetMaterial(ent, self:GetClientInfo("refractused"))
    elseif(ply:KeyDown(IN_SPEED) and ent:GetClass() ~= LaserLib.GetClass(9)) then
      LaserLib.SetMaterial(ent, self:GetClientInfo("reflectused"))
    elseif(ply:KeyDown(IN_DUCK) and (LaserLib.GetOwner(ent) == ply or ply:IsAdmin())) then
      ent:Remove()
    else
      if(ent:GetClass() == LaserLib.GetClass(9)) then
        local idx = (tonumber(ent:GetEntityExitID()) or 0)
        local txt = ((idx ~= 0) and tostring(idx) or gsNOAV); ent:SetEntityExitID(0)
        LaserLib.Notify(ply, "Clear ID"..self:GetUnit(ent).."["..txt.."] !", "UNDO")
      else
        LaserLib.SetMaterial(ent)
      end
    end; return true
  end; return false
end

function TOOL:UpdateEmitterGhost(ent, ply)
  if(not LaserLib.IsValid(ent)) then return end
  if(not LaserLib.IsValid(ply)) then return end
  if(not ply:IsPlayer()) then return end
  if(ent:IsPlayer()) then return end

  local trace = ply:GetEyeTrace()

  LaserLib.ApplySpawn(ent, trace, self:GetTransform())

  if(not trace.Hit
      or trace.Entity:IsPlayer()
      or trace.Entity:GetClass() == LaserLib.GetClass(1)
      or trace.Entity:GetClass() == LaserLib.GetClass(9))
  then
    ent:SetNoDraw(true); return
  end

  ent:SetNoDraw(false)
end

function TOOL:GetSurface(ent)
  if(not LaserLib.IsValid(ent)) then return end
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
      local fnm = "["..gsFNUH.."]"
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

  self:UpdateEmitterGhost(self.GhostEntity, self:GetOwner())
end

local gtConvarList = TOOL:BuildConVarList()

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(panel) local pItem, pName, vData
  panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
  panel:SetName(language.GetPhrase("tool."..gsTOOL..".name"))
  panel:Help   (language.GetPhrase("tool."..gsTOOL..".desc"))

  pItem = vgui.Create("ControlPresets", panel)
  pItem:SetPreset(gsTOOL)
  pItem:AddOption("Default", gtConvarList)
  for key, val in pairs(table.GetKeys(gtConvarList)) do pItem:AddConVar(val) end
  panel:AddItem(pItem)

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetConVar1(gsTOOL.."_key")
  pItem:SetLabel1(language.GetPhrase("tool."..gsTOOL..".key_con"))
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsTOOL..".key"))
  panel:AddPanel(pItem)

  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTOOL..".width_con"), gsTOOL.."_width", 0, cvMXBMWIDT:GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".width")); pItem:SetDefaultValue(gtConvarList[gsTOOL.."_width"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTOOL..".length_con"), gsTOOL.."_length", 0, cvMXBMLENG:GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".length")); pItem:SetDefaultValue(gtConvarList[gsTOOL.."_length"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTOOL..".damage_con"), gsTOOL.."_damage", 0, cvMXBMDAMG:GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".damage")); pItem:SetDefaultValue(gtConvarList[gsTOOL.."_damage"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTOOL..".pushforce_con"), gsTOOL.."_pushforce", 0, cvMXBMFORC:GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".pushforce")); pItem:SetDefaultValue(gtConvarList[gsTOOL.."_pushforce"])
  pItem = panel:MatSelect(gsTOOL.."_material", list.GetForEdit("LaserEmitterMaterials"), true, 0.15, 0.24)
  pItem.Label:SetText(language.GetPhrase("tool."..gsTOOL..".material_con"))
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".material"))

  pItem = vgui.Create("CtrlColor", panel)
  pItem:Dock(TOP); pItem:SetTall(250)
  pItem:SetLabel(language.GetPhrase("tool."..gsTOOL..".color_con"))
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".color"))
  pItem:SetConVarR(gsTOOL.."_colorr")
  pItem:SetConVarG(gsTOOL.."_colorg")
  pItem:SetConVarB(gsTOOL.."_colorb")
  pItem:SetConVarA(gsTOOL.."_colora")
  panel:AddPanel(pItem)

  pItem = vgui.Create("PropSelect", panel)
  pItem:Dock(TOP); pItem:SetTall(150)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".model"))
  pItem:ControlValues({ -- garrysmod/lua/vgui/propselect.lua#L99
    models = list.GetForEdit("LaserEmitterModels"),
    label  = language.GetPhrase("tool."..gsTOOL..".model_con")
  }); panel:AddItem(pItem)

  LaserLib.ComboBoxString(panel, "dissolvetype", "LaserDissolveTypes")
  LaserLib.ComboBoxString(panel, "startsound"  , "LaserStartSounds"  )
  LaserLib.ComboBoxString(panel, "stopsound"   , "LaserStopSounds"   )
  LaserLib.ComboBoxString(panel, "killsound"   , "LaserKillSounds"   )

  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTOOL..".forcelimit_con"), gsTOOL.."_forcelimit", 0, cvMFORCELM:GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".forcelimit")); pItem:SetDefaultValue(gtConvarList[gsTOOL.."_forcelimit"])
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsTOOL..".rayassist_con"), gsTOOL.."_rayassist", 0, cvMAXRAYAS:GetFloat(), 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".rayassist")); pItem:SetDefaultValue(gtConvarList[gsTOOL.."_rayassist"])
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".surfweld_con"), gsTOOL.."_surfweld")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".surfweld"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".nocollide_con"), gsTOOL.."_nocollide")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".nocollide"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".frozen_con"), gsTOOL.."_frozen")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".frozen"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".toggle_con"), gsTOOL.."_toggle")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".toggle"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".starton_con"), gsTOOL.."_starton")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".starton"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".endingeffect_con"), gsTOOL.."_endingeffect")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".endingeffect"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".reflectrate_con"), gsTOOL.."_reflectrate")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".reflectrate"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".refractrate_con"), gsTOOL.."_refractrate")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".refractrate"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".forcecenter_con"), gsTOOL.."_forcecenter")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".forcecenter"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".enonvermater_con"), gsTOOL.."_enonvermater")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".enonvermater"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsTOOL..".ensafebeam_con"), gsTOOL.."_ensafebeam")
  pItem:SetTooltip(language.GetPhrase("tool."..gsTOOL..".ensafebeam"))
end
