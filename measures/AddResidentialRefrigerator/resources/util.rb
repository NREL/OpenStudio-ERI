class Mat_solid
	def initialize(rho, cp, k)
		@rho = rho
		@cp = cp
		@k = k
	end
		
	def rho
		return @rho
	end
	
	def Cp
		return @cp
	end
	
	def k
		return @k
	end
end

class Mat_air
	def initialize(r_air_gap, inside_air_sh)
		@r_air_gap = r_air_gap
		@inside_air_sh = inside_air_sh
	end
	
	attr_accessor(:inside_air_dens)
	
	def R_air_gap
		return @r_air_gap
	end
	
	def inside_air_sh
		return @inside_air_sh
	end
end

class Constants
	DefaultSolarAbsCeiling = 0.3
	DefaultSolarAbsFloor = 0.6
	DefaultSolarAbsWall = 0.5
	MaterialPlywood1_2in = "Plywood-1_2in"
	MaterialPlywood3_4in = "Plywood-3_4in"
	MaterialPlywood3_2in = "Plywood-3_2in"
	MaterialTypeProperties = "PROPERTIES"
	MaterialGypsumBoard1_2in = "GypsumBoard-1_2in"
	MaterialSoil12in = "Soil-12in"
	SpaceGround = "ground"
	SpaceCrawl = "crawlspace"
	Material2x = "2x" #for rim joist
	MaterialFloorMass = "FloorMass"
	MaterialCrawlCeilingIns = "CrawlCeilingIns"
	MaterialConcrete8in = "Concrete-8in"
	MaterialCWallIns = "CWallIns"
	MaterialCWallFicR = "CWall-FicR"
	MaterialTypeResistance = "RESISTANCE"
	MaterialCFloorFicR = "CFloor-FicR"
	MaterialWallRigidIns = "WallRigidIns"
	MaterialCSJoistandCavity = "CSJoistandCavity"
	MaterialAdiabatic = "Adiabatic"
	MaterialCarpetBareLayer = "CarpetBareLayer"
	MaterialStudandAirWall = "StudandAirWall"
	Material2x4 = "2x4"
	MaterialUFBsmtCeilingIns = "UFBsmtCeilingIns"
	MaterialUFBaseWallIns = "UFBaseWallIns"
  SpaceUnfinAttic = "unfinishedattic"
  RoofStructureRafter = "rafter"
  PCMtypeConcentrated = "concentrated"
  MaterialConcPCMCeilWall = "ConcPCMCeilWall"
  MaterialRoofingMaterial = "RoofingMaterial"
  MaterialRadiantBarrier = "RadiantBarrier"
end