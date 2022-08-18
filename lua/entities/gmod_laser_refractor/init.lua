AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

resource.AddFile("models/madjawa/laser_refractor.mdl")
resource.AddFile("materials/vgui/entities/gmod_laser_refractor.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Index" , "NORMAL", "Refractor medium index" },
    {"Ratio" , "NORMAL", "Refractor medium ratio" }
  ):WireCreateOutputs(
    {"Index" , "NORMAL", "Refractor medium index" },
    {"Ratio" , "NORMAL", "Refractor medium ratio" },
    {"Entity", "ENTITY", "Refractor entity itself"}
  )

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Default use the surface material
  self:SetInRefractIndex(0)
  self:SetInRefractRatio(0)

  -- Default uses only one refractive surface
  self:SetZeroIndexMode(true)
  self:SetHitSurfaceMode(true)

  -- Setup default configuration
  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(LaserLib.GetClass(12, 1))
  if(LaserLib.IsValid(ent)) then
    LaserLib.SetMaterial(ent, LaserLib.GetMaterial(12))
    LaserLib.SnapNormal(ent, tr.HitPos, tr.HitNormal, 90)
    ent:SetAngles(ang)
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    if(ply:KeyDown(IN_USE)) then
      if(not LaserLib.Replace(tr.Entity, ent)) then
        ent:SetModel(LaserLib.GetModel(12)) end
    else ent:SetModel(LaserLib.GetModel(12)) end
    ent:Spawn()
    ent:SetCreator(ply)
    ent:Activate()
    ent:PhysWake()
    LaserLib.SetProperties(ent, "metal")
    LaserLib.SetPlayer(ent, ply)
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end
