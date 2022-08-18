AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_divider.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal"  , "VECTOR", "Divider surface normal"}
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Divider working state" },
    {"Normal"  , "VECTOR", "Divider surface normal"},
    {"Count"   , "NORMAL", "Divider beam count"    },
    {"Entity"  , "ENTITY", "Divider entity itself" },
    {"Array"   , "ARRAY" , "Divider sources array" }
  )

  self:InitSources()
  self:SetBeamReplicate(false)
  self:SetStopSound("")
  self:SetStartSound("")

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(5, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(5))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    if(ply:KeyDown(IN_USE)) then
      if(not LaserLib.Replace(tr.Entity, ent)) then
        ent:SetModel(LaserLib.GetModel(5)) end
    else ent:SetModel(LaserLib.GetModel(5)) end
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetPlayer(ent, ply)
    ent:SetBeamTransform()
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

function ENT:Think()
  self:UpdateFlags()
  self:UpdateSources()

  if(self.hitSize > 0) then
    self:SetOn(true)
  else
    self:SetOn(false)
    self:SetHitReportMax()
  end

  self:WireArrays()

  self:NextThink(CurTime())

  return true
end
