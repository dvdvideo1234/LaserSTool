AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_parallel.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal"  , "VECTOR", "Parallel surface normal"  },
    {"DeviateX", "NORMAL", "Parallel deviation cone X"},
    {"DeviateY", "NORMAL", "Parallel deviation cone Y"},
    {"Focus"   , "NORMAL", "Parallel focus margin"    }
  ):WireCreateOutputs(
    {"Normal"  , "VECTOR", "Parallel surface normal"  },
    {"DeviateX", "NORMAL", "Parallel deviation cone X"},
    {"DeviateY", "NORMAL", "Parallel deviation cone Y"},
    {"Focus"   , "NORMAL", "Parallel focus margin"    },
    {"Entity"  , "ENTITY", "Parallel entity itself"   }
  )

  self:SetFocusMargin(0)
  self:SetBeamDimmer(false)

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local cas = LaserLib.GetClass(self.UnitID)
  local gen = LaserLib.GetTool()
  local ang = LaserLib.GetAngleSF(ply)
  local ent = ents.Create(cas)
  if(LaserLib.IsValid(ent)) then
    LaserLib.SnapNormal(ent, tr, 90)
    ent:SetAngles(ang) -- Apply angle after spawn
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetNotSolid(false)
    LaserLib.SetVisuals(ply, ent, tr)
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
