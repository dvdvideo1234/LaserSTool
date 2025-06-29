include("shared.lua")

function ENT:Initialize()
  self.RecuseBeamID = 0 -- Recursive beam index

  LaserLib.SetActor(self, function(beam, trace)
    beam:Finish(trace) -- Assume that beam stops traversing
    local ent = trace.Entity -- Retrieve class trace entity
    local norm = ent:GetHitNormal()
    local bdot = ent:GetHitPower(norm, beam, trace)
    if(trace and trace.Hit and bdot) then
      local aim, nrm = beam.VrDirect, trace.HitNormal
      local ray = LaserLib.GetReflected(aim, nrm)
      if(SERVER) then
        ent:DoDamage(ent:DoBeam(trace.HitPos, aim, beam))
        ent:DoDamage(ent:DoBeam(trace.HitPos, ray, beam))
      else
        ent:DrawBeam(ent:DoBeam(trace.HitPos, aim, beam))
        ent:DrawBeam(ent:DoBeam(trace.HitPos, ray, beam))
      end
    end
  end)
end

function ENT:DrawBeam(beam)
  if(not beam) then return end
  local usent = beam:GetSource()
  local endrw = usent:GetEndingEffect()
  local corgb = usent:GetBeamColorRGBA(true)
  local imatr = usent:GetBeamMaterial(true)
  beam:Draw(usent, imatr) -- Draws the beam trace
  beam:DrawEffect(usent, endrw) -- Handle drawing the effects
  return self
end

function ENT:Draw()
  self:DrawModel()
  self:DrawShadow(false)
end
