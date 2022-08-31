AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_splitterm.vmt")

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateInputs(
    {"Normal"  , "VECTOR", "Splitter surface normal"}
  ):WireCreateOutputs(
    {"On"      , "NORMAL", "Splitter working state" },
    {"Normal"  , "VECTOR", "Splitter surface normal"},
    {"Count"   , "NORMAL", "Splitter beam count"    },
    {"Entity"  , "ENTITY", "Splitter entity itself" },
    {"Array"   , "ARRAY" , "Splitter sources array" }
  )

  self:InitSources()
  self:SetBeamCount(0)
  self:SetBeamLeanX(0)
  self:SetBeamLeanY(0)
  self:SetStopSound("")
  self:SetStartSound("")
  self:SetBeamDimmer(false)
  self:SetBeamReplicate(false)
  self:SetBeamColorSplit(false)

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
    ent:SetAngles(ang) -- Appy angle after spawn
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
    ent:SetBeamCount(LaserLib.GetData("NSPLITER"):GetInt())
    ent:SetBeamLeanX(LaserLib.GetData("XSPLITER"):GetFloat())
    ent:SetBeamLeanY(LaserLib.GetData("YSPLITER"):GetFloat())
    ply:AddCount(gen.."s", ent)
    ply:AddCleanup(gen.."s", ent)
    return ent
  end
end

function ENT:Think()
  self:UpdateVectors()
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
