AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

resource.AddFile("materials/vgui/entities/gmod_laser_portal.vmt")

function ENT:PreEntityCopy()
  self:WirePreEntityCopy()
end

function ENT:PostEntityPaste(ply, ent, created)
  self:WirePostEntityPaste(ply, ent, created)
  local idx = (tonumber(self:GetEntityExitID()) or 0)
  local ent = created[idx]; self:SetEntityExitID(0)
  if(not self:IsTrueExit(ent)) then return end
  self:SetEntityExitID(tostring(ent:EntIndex()))
end

function ENT:ApplyDupeInfo(ply, ent, info, fentid)
  self:WireApplyDupeInfo(ply, ent, info, fentid)
end

function ENT:Initialize()
  self:SetSolid(SOLID_VPHYSICS)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)

  self:WireCreateOutputs(
    {"Entity", "ENTITY", "Portal entity itself" }
  )

  -- Mirror the exit position by default
  self:SetMirrorExitPos(true) -- Use list
  self:SetDrawTransfer(true) -- Overlay

  local phys = self:GetPhysicsObject()
  if(LaserLib.IsValid(phys)) then
    phys:Wake(); phys:SetMass(50)
  end -- Apply decent mass

  -- Setup default configuration
  self:WireWrite("Entity", self)
end

function ENT:SpawnFunction(ply, tr)
  if(not tr.Hit) then return end
  local cas = LaserLib.SetClass(self,
    "models/props_c17/frame002a.mdl",
    "models/props_combine/com_shield001a")
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
    LaserLib.SetProperties(ent, "metal")

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

function ENT:Think()
  self:UpdateVectors()
end
