AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_dimmer.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal", "VECTOR", "Dimmer surface normal"}
  ):WireCreateOutputs(
    {"Normal", "VECTOR", "Dimmer surface normal"},
    {"Entity", "ENTITY", "Dimmer entity itself" }
  )

  self:SetBeamReplicate(false)
  self:SetBeamPowerClamp(false)
  self:SetBeamPassEnable(false)
  self:SetBeamPassTexture(true)
  self:SetBeamPassColor(true)
  self:SetInBeamWidth(0)
  self:SetInBeamLength(0)
  self:SetInBeamDamage(0)
  self:SetInBeamForce(0)
  self:SetInBeamMaterial("")
  self:SetBeamColorRGBA(0,0,0,0)

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
  local ent = ents.Create(LaserLib.GetClass(11, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(11))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang) -- Appy angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    ent:SetModel(LaserLib.GetModel(11))
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetPlayer(ent, ply)
    ent:SetBeamTransform()
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end
