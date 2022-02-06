-- Wiremod dedicated entity method to retrieve information from laser sources
E2Helper.Descriptions["laserGetBeamDamage(e:)"]             = "Returns the laser source beam damage"
E2Helper.Descriptions["laserGetBeamForce(e:)"]              = "Returns the laser source beam force"
E2Helper.Descriptions["laserGetBeamLength(e:)"]             = "Returns the laser source beam length"
E2Helper.Descriptions["laserGetBeamMaterial(e:)"]           = "Returns the laser source beam material"
E2Helper.Descriptions["laserGetBeamPower(e:)"]              = "Returns the laser source beam power"
E2Helper.Descriptions["laserGetBeamWidth(e:)"]              = "Returns the laser source beam width"
E2Helper.Descriptions["laserGetDissolveType(e:)"]           = "Returns the laser source dissolve type name"
E2Helper.Descriptions["laserGetDissolveTypeID(e:)"]         = "Returns the laser source dissolve type ID"
E2Helper.Descriptions["laserGetEndingEffect(e:)"]           = "Returns the laser source ending effect flag"
E2Helper.Descriptions["laserGetForceCenter(e:)"]            = "Returns the laser source force in center flag"
E2Helper.Descriptions["laserGetKillSound(e:)"]              = "Returns the laser source kill sound"
E2Helper.Descriptions["laserGetNonOverMater(e:)"]           = "Returns the laser source base entity material flag"
E2Helper.Descriptions["laserGetPlayer(e:)"]                 = "Returns the laser unit player getting the kill credit"
E2Helper.Descriptions["laserGetReflectRatio(e:)"]           = "Returns the laser source reflection ratio flag"
E2Helper.Descriptions["laserGetRefractRatio(e:)"]           = "Returns the laser source refraction ratio flag"
E2Helper.Descriptions["laserGetStartSound(e:)"]             = "Returns the laser source start sound"
E2Helper.Descriptions["laserGetStopSound(e:)"]              = "Returns the laser source stop sound"
-- Wiremod dedicated entity method to retrieve beam information from hit reports
E2Helper.Descriptions["laserGetDataBounceMax(e:n)"]         = "Returns the maximum allowed laser beam bounces"
E2Helper.Descriptions["laserGetDataBounceRest(e:n)"]        = "Returns the remaining laser beam bounces"
E2Helper.Descriptions["laserGetDataDamage(e:n)"]            = "Returns the remaining laser beam damage"
E2Helper.Descriptions["laserGetDataDirect(e:n)"]            = "Returns the last laser beam direction vector"
E2Helper.Descriptions["laserGetDataForce(e:n)"]             = "Returns the remaining laser beam force"
E2Helper.Descriptions["laserGetDataIsReflect(e:n)"]         = "Returns the laser source reflect flag"
E2Helper.Descriptions["laserGetDataIsRefract(e:n)"]         = "Returns the laser source refract flag"
E2Helper.Descriptions["laserGetDataLength(e:n)"]            = "Returns the laser source beam length"
E2Helper.Descriptions["laserGetDataLengthRest(e:n)"]        = "Returns the remaining laser beam length"
E2Helper.Descriptions["laserGetDataOrigin(e:n)"]            = "Returns the last laser beam origin vector"
E2Helper.Descriptions["laserGetDataPointDamage(e:nn)"]      = "Returns the laser beam node damage"
E2Helper.Descriptions["laserGetDataPointForce(e:nn)"]       = "Returns the laser beam node force"
E2Helper.Descriptions["laserGetDataPointIsDraw(e:nn)"]      = "Returns the laser beam node draw flag"
E2Helper.Descriptions["laserGetDataPointNode(e:nn)"]        = "Returns the laser beam node location vector"
E2Helper.Descriptions["laserGetDataPointSize(e:n)"]         = "Returns the laser beam nodes count"
E2Helper.Descriptions["laserGetDataPointWidth(e:nn)"]       = "Returns the laser beam node width"
E2Helper.Descriptions["laserGetDataRange(e:n)"]             = "Returns the laser beam traverse range"
E2Helper.Descriptions["laserGetDataSource(e:n)"]            = "Returns the laser beam source entity"
E2Helper.Descriptions["laserGetDataWidth(e:n)"]             = "Returns the remaining laser beam width"
-- Wiremode dedicated entity method to retrieve beam trace from hit reports
E2Helper.Descriptions["laserGetTraceEntity(e:n)"]           = "Returns the last trace entity"
E2Helper.Descriptions["laserGetTraceFraction(e:n)"]         = "Returns the last trace used hit fraction `[0-1]`"
E2Helper.Descriptions["laserGetTraceFractionLS(e:n)"]       = "Returns the last trace fraction left solid [0-1]"
E2Helper.Descriptions["laserGetTraceHit(e:n)"]              = "Returns the last trace hit flag"
E2Helper.Descriptions["laserGetTraceHitBox(e:n)"]           = "Returns the last trace hit box ID"
E2Helper.Descriptions["laserGetTraceHitGroup(e:n)"]         = "Returns the last trace hit group enums"
E2Helper.Descriptions["laserGetTraceHitNoDraw(e:n)"]        = "Returns the last trace hit no-draw brush"
E2Helper.Descriptions["laserGetTraceHitNonWorld(e:n)"]      = "Returns the last trace hit non-world flag"
E2Helper.Descriptions["laserGetTraceHitNormal(e:n)"]        = "Returns the last trace hit normal vector"
E2Helper.Descriptions["laserGetTraceHitPos(e:n)"]           = "Returns the last trace hit position vector"
E2Helper.Descriptions["laserGetTraceHitSky(e:n)"]           = "Returns the last trace hit sky flag"
E2Helper.Descriptions["laserGetTraceHitTexture(e:n)"]       = "Returns the last trace hit texture"
E2Helper.Descriptions["laserGetTraceHitWorld(e:n)"]         = "Returns the last trace hit world flag"
E2Helper.Descriptions["laserGetTraceMatType(e:n)"]          = "Returns the last trace material type enums"
E2Helper.Descriptions["laserGetTraceNormal(e:n)"]           = "Returns the last trace normal vector"
E2Helper.Descriptions["laserGetTraceHitPhysicsBone(e:n)"]   = "Returns the last trace hit physics bone ID"
E2Helper.Descriptions["laserGetTraceStartPos(e:n)"]         = "Returns the last trace start position"
E2Helper.Descriptions["laserGetTraceSurfacePropsID(e:n)"]   = "Returns the last trace hit surface property ID"
E2Helper.Descriptions["laserGetTraceSurfacePropsName(e:n)"] = "Returns the last trace hit surface property name"
E2Helper.Descriptions["laserGetTraceStartSolid(e:n)"]       = "Returns the last trace start solid flag"
E2Helper.Descriptions["laserGetTraceAllSolid(e:n)"]         = "Returns the last trace all solid flag"
E2Helper.Descriptions["laserGetTraceSurfaceFlags(e:n)"]     = "Returns the last trace hit surface flags enums"
E2Helper.Descriptions["laserGetTraceDispFlags(e:n)"]        = "Returns the last trace hit surface displacement flag enums"
E2Helper.Descriptions["laserGetTraceContents(e:n)"]         = "Returns the last trace hit surface contents enums"
-- Other helper functions for database reflection and refraction
E2Helper.Descriptions["laserGetBeamPower(nn)"]              = "Returns the calcuated power by external width and damage"
E2Helper.Descriptions["laserGetBeamIsPower(nn)"]            = "Returns the flag indicating the power enabled threshold"
E2Helper.Descriptions["laserGetRefractDataIndex(s)"]        = "Returns the refract index database entry"
E2Helper.Descriptions["laserGetRefractDataRatio(s)"]        = "Returns the refract ratio database entry"
E2Helper.Descriptions["laserGetRefractDataKey(s)"]          = "Returns the refract loop key database entry"
E2Helper.Descriptions["laserGetReflectDataRatio(s)"]        = "Returns the reflect ratio database entry"
E2Helper.Descriptions["laserGetReflectDataKey(s)"]          = "Returns the reflect loop key database entry"
E2Helper.Descriptions["laserGetReflectBeam(vv)"]            = "Returns the reflected vector by external incident and normal"
E2Helper.Descriptions["laserGetRefractBeam(vvnn)"]          = "Returns the refracted vector by external incident, normal and medium indices"
E2Helper.Descriptions["laserGetRefractIsOut()"]             = "Returns a flag indicating the beam exiting the medium after refracting"
