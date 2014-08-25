
# Add classes or functions here than can be used across a variety of our python classes and modules.

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
  def initialize
    @defaultSolarAbsCeiling = 0.3
    @defaultSolarAbsFloor = 0.6
    @defaultSolarAbsWall = 0.5
    @materialPlywood1_2in = "Plywood-1_2in"
    @materialPlywood3_4in = "Plywood-3_4in"
    @materialPlywood3_2in = "Plywood-3_2in"
    @materialTypeProperties = "PROPERTIES"
    @materialGypsumBoard1_2in = "GypsumBoard-1_2in"
    @materialSoil12in = "Soil-12in"
    @spaceGround = "ground"
    @spaceCrawl = "crawlspace"
    @material2x = "2x" #for rim joist
    @materialFloorMass = "FloorMass"
    @materialCrawlCeilingIns = "CrawlCeilingIns"
    @materialConcrete8in = "Concrete-8in"
    @materialCWallIns = "CWallIns"
    @materialCWallFicR = "CWall-FicR"
    @materialTypeResistance = "RESISTANCE"
    @materialCFloorFicR = "CFloor-FicR"
    @materialWallRigidIns = "WallRigidIns"
    @materialCSJoistandCavity = "CSJoistandCavity"
    @materialAdiabatic = "Adiabatic"
    @materialCarpetBareLayer = "CarpetBareLayer"
    @materialStudandAirWall = "StudandAirWall"
    @material2x4 = "2x4"
    @material2x6 = "2x6"
    @materialUFBsmtCeilingIns = "UFBsmtCeilingIns"
    @materialUFBaseWallIns = "UFBaseWallIns"
    @spaceUnfinAttic = "unfinishedattic"
    @roofStructureRafter = "rafter"
    @pcmtypeConcentrated = "concentrated"
    @materialConcPCMCeilWall = "ConcPCMCeilWall"
    @materialConcPCMPartWall = "ConcPCMPartWall"
    @materialRoofingMaterial = "RoofingMaterial"
    @materialRadiantBarrier = "RadiantBarrier"
    @materialPartitionWallMass = "PartitionWallMass"
    @monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    @scheduleTypeFraction = "FRACTION"
    @furnTypeLight = "LIGHT"
    @furnTypeHeavy = "HEAVY"
  end

  def DefaultSolarAbsCeiling
    return @defaultSolarAbsCeiling
  end

  def DefaultSolarAbsFloor
    return @defaultSolarAbsFloor
  end

  def DefaultSolarAbsWall
    return @defaultSolarAbsWall
  end

  def MaterialPlywood1_2in
    return @materialPlywood1_2in
  end

  def MaterialPlywood3_4in
    return @materialPlywood3_4in
  end

  def MaterialPlywood3_2in
    return @materialPlywood3_2in
  end

  def MaterialTypeProperties
    return @materialTypeProperties
  end

  def MaterialGypsumBoard1_2in
    return @materialGypsumBoard1_2in
  end

  def MaterialSoil12in
    return @materialSoil12in
  end

  def SpaceGround
    return @spaceGround
  end

  def SpaceCrawl
    return @spaceCrawl
  end

  def Material2x
    return @material2x
  end

  def MaterialFloorMass
    return @materialFloorMass
  end

  def MaterialCrawlCeilingIns
    return @materialCrawlCeilingIns
  end

  def MaterialConcrete8in
    return @materialConcrete8in
  end

  def MaterialCWallIns
    return @materialCWallIns
  end

  def MaterialCWallFicR
    return @materialCWallFicR
  end

  def MaterialTypeResistance
    return @materialTypeResistance
  end

  def MaterialCFloorFicR
    return @materialCFloorFicR
  end

  def MaterialWallRigidIns
    return @materialWallRigidIns
  end

  def MaterialCSJoistandCavity
    return @materialCSJoistandCavity
  end

  def MaterialAdiabatic
    return @materialAdiabatic
  end

  def MaterialCarpetBareLayer
    return @materialCarpetBareLayer
  end

  def MaterialStudandAirWall
    return @materialStudandAirWall
  end

  def Material2x4
    return @material2x4
  end

  def Material2x6
    return @material2x6
  end

  def MaterialUFBsmtCeilingIns
    return @materialUFBsmtCeilingIns
  end

  def MaterialUFBaseWallIns
    return @materialUFBaseWallIns
  end

  def SpaceUnfinAttic
    return @spaceUnfinAttic
  end

  def RoofStructureRafter
    return @roofStructureRafter
  end

  def PCMtypeConcentrated
    return @pcmtypeConcentrated
  end

  def MaterialConcPCMCeilWall
    return @materialConcPCMCeilWall
  end

  def MaterialConcPCMPartWall
    return @materialConcPCMPartWall
  end

  def MaterialRoofingMaterial
    return @materialRoofingMaterial
  end

  def MaterialRadiantBarrier
    return @materialRadiantBarrier
  end

  def MaterialPartitionWallMass
    return @materialPartitionWallMass
  end

  def MonthNames
    return @monthNames
  end

  def ScheduleTypeFraction
    return @scheduleTypeFraction
  end

  def FurnTypeLight
    return @furnTypeLight
  end

  def FurnTypeHeavy
    return @furnTypeHeavy
  end
end