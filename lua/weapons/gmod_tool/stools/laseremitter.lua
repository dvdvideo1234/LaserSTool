local gsUnit = LaserLib.GetTool()
local gsLaseremCls = LaserLib.GetClass(1, 1)
local gsCrystalCls = LaserLib.GetClass(2, 1)
local gsReflectCls = LaserLib.GetClass(3, 1)
local gsReflectMod = LaserLib.GetModel(3, 1)

if(CLIENT) then
  language.Add("tool."..gsUnit..".name", "Laser Spawner")
  language.Add("tool."..gsUnit..".desc", "Spawn a very dangerous laser. Do not look into beam with remaining eye!")
  language.Add("tool."..gsUnit..".0", "Primary: Create/Update a laser where you are aiming")
  language.Add("tool."..gsUnit..".key_con", "Key:")
  language.Add("tool."..gsUnit..".key", "Numpad key that controls the laser trigger")
  language.Add("tool."..gsUnit..".width_con", "Width:")
  language.Add("tool."..gsUnit..".width", "Controls laser beam width")
  language.Add("tool."..gsUnit..".length_con", "Length:")
  language.Add("tool."..gsUnit..".length", "Controls laser beam maximum length")
  language.Add("tool."..gsUnit..".damage_con", "Damage:")
  language.Add("tool."..gsUnit..".damage", "Controls laser beam damage amount")
  language.Add("tool."..gsUnit..".model_con", "Model:")
  language.Add("tool."..gsUnit..".model", "Select laser entity visual model")
  language.Add("tool."..gsUnit..".dissolvetype_con", "Dissolve type:")
  language.Add("tool."..gsUnit..".dissolvetype", "Controls what visuals are used when dissolving players")
  language.Add("tool."..gsUnit..".toggle_con", "Toggle")
  language.Add("tool."..gsUnit..".toggle", "Starts the laser when the button is hit")
  language.Add("tool."..gsUnit..".starton_con", "Start on creation")
  language.Add("tool."..gsUnit..".starton", "Starts the laser on when gets created")
  language.Add("tool."..gsUnit..".pushprops_con", "Push props:")
  language.Add("tool."..gsUnit..".pushprops", "Seutp the laser beam to push props")
  language.Add("tool."..gsUnit..".endingeffect_con", "Ending effect")
  language.Add("tool."..gsUnit..".endingeffect", "Allow showing ending effects")
  language.Add("tool."..gsUnit..".worldweld_con", "Weld to surface")
  language.Add("tool."..gsUnit..".worldweld", "Welds the laser to the trace surface")
  language.Add("tool."..gsUnit..".reflectrate_con", "Surface type reflection")
  language.Add("tool."..gsUnit..".reflectrate", "Reflect the amount of power according to the surface type")
  language.Add("Cleanup_"..gsUnit, "Lasers")
  language.Add("Cleaned_"..gsUnit, "Cleaned up all Lasers")
  language.Add("Undone_"..gsUnit, "Undone Laser Emitter")
  language.Add("SBoxLimit_"..gsUnit.."s", "You've hit the Laser emiters limit!")
end

TOOL.Category = "Construction"
TOOL.Name     = (language and language.GetPhrase("tool."..gsUnit..".name"))

if(SERVER) then
  CreateConVar("sbox_max"..gsUnit.."s", 20)

  resource.AddFile(gsReflectMod)
  resource.AddFile("models/props_junk/flare.mdl")
  resource.AddFile("materials/effects/redlaser1.vmt")
  resource.AddFile("materials/effects/redlaser1_smoke.vtf")
  resource.AddFile("materials/vgui/entities/gmod_laser_crystal.vmt")
  resource.AddFile("materials/vgui/entities/gmod_laser_reflector.vmt")
  resource.AddFile("materials/vgui/entities/gmod_laser_killicon.vmt")
end

if(CLIENT) then
  language.Add(gsLaseremCls, "Laser Emiter") -- Relative to materials
  killicon.Add(gsLaseremCls, "vgui/entities/gmod_laser_killicon", LaserLib.GetColor("WHITE"))

  language.Add(gsCrystalCls, "Laser Crystal")
  killicon.AddAlias(gsCrystalCls, gsLaseremCls)

  language.Add(gsReflectCls, "Laser Reflector")
  killicon.AddAlias(gsReflectCls, gsLaseremCls)
end

cleanup.Register(gsUnit.."s")

TOOL.ClientConVar =
{
  [ "key"          ] = 5,
  [ "width"        ] = 4,
  [ "length"       ] = 30000,
  [ "damage"       ] = 2500,
  [ "material"     ] = "cable/physbeam",
  [ "model"        ] = "models/props_combine/headcrabcannister01a_skybox.mdl",
  [ "dissolvetype" ] = "core",
  [ "startsound"   ] = "ambient/energy/weld1.wav",
  [ "stopsound"    ] = "ambient/energy/weld2.wav",
  [ "killsound"    ] = "ambient/levels/citadel/weapon_disintegrate1.wav",
  [ "toggle"       ] = 0,
  [ "starton"      ] = 0,
  [ "pushprops"    ] = 100,
  [ "endingeffect" ] = 1,
  [ "worldweld"    ] = 0,
  [ "angleoffset"  ] = 270,
  [ "reflectrate"  ] = 1
}

list.Set("LaserEmitterModels", "models/props_combine/headcrabcannister01a_skybox.mdl", {laseremitter_angleoffset = 270})
list.Set("LaserEmitterModels", "models/props_combine/breenlight.mdl", {laseremitter_angleoffset = 180})
list.Set("LaserEmitterModels", "models/props_junk/flare.mdl", {laseremitter_angleoffset = 0 })
list.Set("LaserEmitterModels", "models/props_lab/tpplug.mdl", {laseremitter_angleoffset = 90 })
list.Set("LaserEmitterModels", "models/props_junk/TrafficCone001a.mdl", {laseremitter_angleoffset = 0})
list.Set("LaserEmitterModels", "models/props_junk/PopCan01a.mdl", {laseremitter_angleoffset = 0})
if(WireLib) then -- Make these model available only if the player has Wire
  list.Set("LaserEmitterModels", "models/jaanus/wiretool/wiretool_beamcaster.mdl", {laseremitter_angleoffset = 0})
end

list.Set("LaserEmitterMaterials", "cable/redlaser", "cable/redlaser")
list.Set("LaserEmitterMaterials", "effects/redlaser1", "effects/redlaser1")
list.Set("LaserEmitterMaterials", "cable/physbeam", "cable/physbeam")
list.Set("LaserEmitterMaterials", "cable/xbeam", "cable/xbeam")
list.Set("LaserEmitterMaterials", "cable/blue_elec", "cable/blue_elec")
list.Set("LaserEmitterMaterials", "cable/hydra", "cable/hydra")
list.Set("LaserEmitterMaterials", "cable/crystal_beam1", "cable/crystal_beam1")

if(CLIENT) then
  language.Add("DissolveType_Energy", "AR2 style")
  language.Add("DissolveType_HeavyElectric", "Heavy electrical")
  language.Add("DissolveType_LightElectric", "Light electrical")
  language.Add("DissolveType_Core", "Core Effect")
end

list.Set("LaserDissolveTypes", "#DissolveType_Energy", {laseremitter_dissolvetype = "energy"})
list.Set("LaserDissolveTypes", "#DissolveType_HeavyElectric", {laseremitter_dissolvetype = "heavyelec"})
list.Set("LaserDissolveTypes", "#DissolveType_LightElectric", {laseremitter_dissolvetype = "lightelec"})
list.Set("LaserDissolveTypes", "#DissolveType_Core", {laseremitter_dissolvetype = "core"})

if(CLIENT) then
  language.Add("Sound_None", "None")
  language.Add("Sound_AlyxEMP", "Alyx EMP")
  language.Add("Sound_Weld1", "Weld 1")
  language.Add("Sound_Weld2", "Weld 2")
  language.Add("Sound_ElectricExplosion1", "Electric Explosion 1")
  language.Add("Sound_ElectricExplosion2", "Electric Explosion 2")
  language.Add("Sound_ElectricExplosion3", "Electric Explosion 3")
  language.Add("Sound_ElectricExplosion4", "Electric Explosion 4")
  language.Add("Sound_ElectricExplosion5", "Electric Explosion 5")
  language.Add("Sound_Disintegrate1", "Disintegrate 1")
  language.Add("Sound_Disintegrate2", "Disintegrate 2")
  language.Add("Sound_Disintegrate3", "Disintegrate 3")
  language.Add("Sound_Disintegrate4", "Disintegrate 4")
  language.Add("Sound_Zapper", "Zapper")
end

list.Set( "LaserSounds", "#Sound_None", "")
list.Set( "LaserSounds", "#Sound_AlyxEMP", "AlyxEMP.Charge")
list.Set( "LaserSounds", "#Sound_Weld1", "ambient/energy/weld1.wav")
list.Set( "LaserSounds", "#Sound_Weld2", "ambient/energy/weld2.wav")
list.Set( "LaserSounds", "#Sound_ElectricExplosion1", "ambient/levels/labs/electric_explosion1.wav")
list.Set( "LaserSounds", "#Sound_ElectricExplosion2", "ambient/levels/labs/electric_explosion2.wav")
list.Set( "LaserSounds", "#Sound_ElectricExplosion3", "ambient/levels/labs/electric_explosion3.wav")
list.Set( "LaserSounds", "#Sound_ElectricExplosion4", "ambient/levels/labs/electric_explosion4.wav")
list.Set( "LaserSounds", "#Sound_ElectricExplosion5", "ambient/levels/labs/electric_explosion5.wav")
list.Set( "LaserSounds", "#Sound_Disintegrate1", "ambient/levels/citadel/weapon_disintegrate1.wav")
list.Set( "LaserSounds", "#Sound_Disintegrate2", "ambient/levels/citadel/weapon_disintegrate2.wav")
list.Set( "LaserSounds", "#Sound_Disintegrate3", "ambient/levels/citadel/weapon_disintegrate3.wav")
list.Set( "LaserSounds", "#Sound_Disintegrate4", "ambient/levels/citadel/weapon_disintegrate4.wav")
list.Set( "LaserSounds", "#Sound_Zapper", "ambient/levels/citadel/zapper_warmup1.wav")

for k, v in pairs(list.Get("LaserSounds")) do
  list.Set("LaserStartSounds", k, {laseremitter_startsound = v})
  list.Set("LaserStopSounds", k, {laseremitter_stopsound = v})
  list.Set("LaserKillSounds", k, {laseremitter_killsound = v})
end

cleanup.Register(gsUnit.."s")

--[[
Applies the final posutional and angular offsets to the laser spawned
Adjusts the custom model angle and calculates the touch position
 * ent   > The laser entity to preform the operation for
 * trace > The trace that player is aiming for
]]
function TOOL:ApplySpawn(ent, trace)
  local aos = self:GetClientNumber("angleoffset")
  local ang = trace.HitNormal:Angle()
        ang.pitch = ang.pitch + 90 - aos
  local oob = ent:OBBMins()
        oob:Rotate(ent:WorldToLocalAngles(ang))
        cnv = ent:LocalToWorld(oob)
        cnv:Sub(ent:GetPos())
  local srf = math.abs(trace.HitNormal:Dot(cnv))
  local pos = Vector(trace.HitNormal)
        pos:Mul(srf); pos:Add(trace.HitPos)
  ent:SetPos(pos)
  ent:SetAngles(ang)
end

function TOOL:LeftClick(trace)
  if(CLIENT) then return true end
  if(not trace.HitPos) then return false end
  if(trace.Entity:IsPlayer()) then return false end
  if(not self:GetSWEP():CheckLimit(gsUnit.."s")) then return false end

  local key          = self:GetClientNumber("key")
  local width        = self:GetClientNumber("width")
  local length       = self:GetClientNumber("length")
  local damage       = self:GetClientNumber("damage")
  local pushprops    = self:GetClientNumber("pushprops")
  local model        = self:GetClientInfo("model")
  local material     = self:GetClientInfo("material")
  local stopsound    = self:GetClientInfo("stopsound")
  local killsound    = self:GetClientInfo("killsound")
  local startsound   = self:GetClientInfo("startsound")
  local dissolvetype = self:GetClientInfo("dissolvetype")
  local angleoffset  = self:GetClientNumber("angleoffset")
  local toggle       = (self:GetClientNumber("toggle") ~= 0)
  local starton      = (self:GetClientNumber("starton") ~= 0)
  local worldweld    = (self:GetClientNumber("worldweld") ~= 0)
  local reflectrate  = (self:GetClientNumber("reflectrate") ~= 0)
  local endingeffect = (self:GetClientNumber("endingeffect") ~= 0)
  local ply, ent     = self:GetOwner(), trace.Entity
  local pos, ang     = trace.HitPos   , trace.HitNormal:Angle()

  if(ent:IsValid() and
     ent:GetClass() == gsLaseremCls)
  then
    ent:Setup(width       , length    , damage   , material    ,
              dissolvetype, startsound, stopsound, killsound   ,
              toggle      , starton   , pushprops, endingeffect,
              reflectrate , true)
    return true
  end

  local laser = LaserLib.New(ply        , pos         , ang         , model     ,
                             angleoffset, key         , width       , length    ,
                             damage     , material    , dissolvetype, startsound,
                             stopsound  , killsound   , toggle      , starton   ,
                             pushprops  , endingeffect, reflectrate , frozen)

  if(not (laser and laser:IsValid())) then return false end

  self:ApplySpawn(laser, trace)

  undo.Create("LaserEmitter")
    undo.AddEntity(laser)
    if(ent:IsValid() or worldweld) then
      local weld = constraint.Weld(laser, ent, trace.PhysicsBone, 0, 0)
      if(weld and weld:IsValid()) then
        undo.AddEntity(weld) -- Inser the weld in the undo list
        laser:DeleteOnRemove(weld) -- Remove the weld with the laser
        ent:DeleteOnRemove(weld) -- Remove weld with the anchor
      end
    end
    undo.SetPlayer(ply)
  undo.Finish()

  ply:AddCleanup(gsUnit.."s", laser)

  return true
end

function TOOL:RightClick(trace)
  return false
end

function TOOL:Reload(trace)
  if(CLIENT) then return true end
  if(not trace) then return false end
  if(not trace.Entity)  then return false end
  local ply, ent = self:GetOwner(), trace.Entity
  if(not ent:IsValid())  then return false end
  if(ent:IsPlayer()) then return false end
  if(ply:KeyDown(IN_SPEED)) then
    ent:SetMaterial(LaserLib.GetRefract())
  else
    ent:SetMaterial(LaserLib.GetReflect())
  end
  return true
end

if(SERVER) then
  duplicator.RegisterEntityClass(gsLaseremCls, LaserLib.New,
    "ply",
    "pos",
    "ang",
    "model",
    "angleOffset",
    "key",
    "width",
    "length",
    "damage",
    "material",
    "dissolveType",
    "startSound",
    "stopSound",
    "killSound",
    "toggle",
    "startOn",
    "pushProps",
    "endingEffect",
    "reflectRate",
    "frozen")
end

function TOOL:UpdateGhostLaserEmitter(ent, ply)
  if(not ent) then return end
  if(not ply) then return end
  if(ent:IsPlayer()) then return end
  if(not ent:IsValid()) then return end
  if(not ply:IsValid()) then return end
  if(not ply:IsPlayer()) then return end

  local trace = ply:GetEyeTrace()

  self:ApplySpawn(ent, trace)

  if(not trace.Hit or
         trace.Entity:IsPlayer() or
         trace.Entity:GetClass() == gsLaseremCls)
  then
    ent:SetNoDraw(true)
    return
  end

  ent:SetNoDraw(false)
end

function TOOL:Think()
  if(not self.GhostEntity or
     not self.GhostEntity:IsValid() or
         self.GhostEntity:GetModel() ~= self:GetClientInfo("Model"))
  then
    self:MakeGhostEntity(self:GetClientInfo("Model"), Vector(0, 0, 0), Angle(0, 0, 0))
  end

  self:UpdateGhostLaserEmitter(self.GhostEntity, self:GetOwner())
end

-- TODO: Remove `AddControl` and code a proper preset handler
local gtConvarList = TOOL:BuildConVarList()

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(panel)
  panel:ClearControls(); panel:DockPadding(5, 0, 5, 10)
  panel:SetName(language.GetPhrase("tool."..gsUnit..".name"))
  panel:Help   (language.GetPhrase("tool."..gsUnit..".desc"))

  local pItem = vgui.Create("ControlPresets", panel)
        pItem:SetPreset(gsUnit)
        pItem:AddOption("Default", gtConvarList)
        for key, val in pairs(table.GetKeys(gtConvarList)) do pItem:AddConVar(val) end
  panel:AddItem(pItem)

  pItem = vgui.Create("CtrlNumPad", panel)
  pItem:SetConVar1(gsUnit.."_key")
  pItem:SetLabel1(language.GetPhrase("tool."..gsUnit..".key_con"))
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsUnit..".key"))
  panel:AddPanel(pItem)

  pItem = panel:NumSlider(language.GetPhrase("tool."..gsUnit..".width_con"), gsUnit.."_width", 1, 30, 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".width"))
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsUnit..".length_con"), gsUnit.."_length", 0, 50000, 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".length"))
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsUnit..".damage_con"), gsUnit.."_damage", 0, 5000, 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".damage"))
  pItem = panel:NumSlider(language.GetPhrase("tool."..gsUnit..".pushprops_con"), gsUnit.."_pushprops", 0, 50000, 5)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".pushprops"))

  panel:AddControl( "MatSelect", {  Label = "Material:",
                    Height = 1,
                    ItemWidth = 24,
                    ItemHeight = 64,
                    ConVar = gsUnit.."_material",
                    Options = list.Get( "LaserEmitterMaterials" ) } )

  panel:AddControl( "PropSelect", { Label = "Model:",
                    ConVar = ""..gsUnit.."_model",
                    Models = list.Get( "LaserEmitterModels" ) } )

  panel:AddControl( "ComboBox", { Label = "Dissolve type:",
                  MenuButton = "0",
                  Command = ""..gsUnit.."_dissolvetype",
                  Options = list.Get( "LaserDissolveTypes" ) } )

  panel:AddControl( "ComboBox", { Label = "Start sound:",
                  MenuButton = "0",
                  Command = gsUnit.."_startsound",
                  Options = list.Get( "LaserStartSounds" ) } )

  panel:AddControl( "ComboBox", { Label = "Stop sound:",
                  MenuButton = "0",
                  Command = gsUnit.."_stopsound",
                  Options = list.Get( "LaserStopSounds" ) } )

  panel:AddControl( "ComboBox", { Label = "Kill sound:",
                  MenuButton = "0",
                  Command = gsUnit.."_killsound",
                  Options = list.Get( "LaserKillSounds" ) } )

  pItem = panel:CheckBox(language.GetPhrase("tool."..gsUnit..".worldweld_con"), gsUnit.."_worldweld")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".worldweld"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsUnit..".toggle_con"), gsUnit.."_toggle")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".toggle"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsUnit..".starton_con"), gsUnit.."_starton")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".starton"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsUnit..".endingeffect_con"), gsUnit.."_endingeffect")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".endingeffect"))
  pItem = panel:CheckBox(language.GetPhrase("tool."..gsUnit..".reflectrate_con"), gsUnit.."_reflectrate")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".reflectrate"))
end
