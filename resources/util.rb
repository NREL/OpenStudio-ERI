
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
    @infMethodASHRAE = "ASHRAE-ENHANCED"
    @g = 32.174    # gravity (ft/s2)
    @infMethodRes = "RESIDENTIAL"
    @infMethodSG = "S-G"
    @auto = "auto"
    @terrainOcean = "ocean"
    @terrainPlains = "plains"
    @terrainRural = "rural"
    @terrainSuburban = "suburban"
    @terrainCity = "city"
    @testBldgMinimal = "minimal"
    @r = 1.9858 # gas constant (Btu/lbmol-R)
    @ventTypeExhaust = "exhaust"
    @ventTypeSupply = "supply"
    @ventTypeBalanced = "balanced"
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

  def InfMethodASHRAE
    return @infMethodASHRAE
  end

  def g
    return @g
  end

  def InfMethodRes
    return @infMethodRes
  end

  def InfMethodSG
    return @infMethodSG
  end

  def Auto
    return @auto
  end

  def TerrainOcean
    return @terrainOcean
  end

  def TerrainPlains
    return @terrainPlains
  end

  def TerrainRural
    return @terrainRural
  end

  def TerrainSuburban
    return @terrainSuburban
  end

  def TerrainCity
    return @terrainCity
  end

  def TestBldgMinimal
    return @testBldgMinimal
  end

  def R
    return @r
  end

  def VentTypeExhaust
    return @ventTypeExhaust
  end

  def VentTypeSupply
    return @ventTypeSupply
  end

  def VentTypeBalanced
    return @ventTypeBalanced
  end

end

class Mat_liq
  def initialize(rho, cp, k, mu, h_fg, t_frz, t_boil, t_crit)
    @rho    = rho       # Density (lb/ft3)
    @cp     = cp        # Specific Heat (Btu/lbm-R)
    @k      = k         # Thermal Conductivity (Btu/h-ft-R)
    @mu     = mu        # Dynamic Viscosity (lbm/ft-h)
    @h_fg   = h_fg      # Latent Heat of Vaporization (Btu/lbm)
    @t_frz  = t_frz     # Freezing Temperature (degF)
    @t_boil = t_boil    # Boiling Temperature (degF)
    @t_crit = t_crit    # Critical Temperature (degF)
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

  def mu
    return @mu
  end

  def H_fg
    return @h_fg
  end

  def T_frz
    return @t_frz
  end

  def T_boil
    return @t_boil
  end

  def T_crit
    return @t_crit
  end
end

class Mat_gas
  def initialize(rho, cp, k, mu, m)
    @rho    = rho           # Density (lb/ft3)
    @cp     = cp            # Specific Heat (Btu/lbm-R)
    @k      = k             # Thermal Conductivity (Btu/h-ft-R)
    @mu     = mu            # Dynamic Viscosity (lbm/ft-h)
    @m      = m             # Molecular Weight (lbm/lbmol)
    if @m
      @r  = Constants.new.R / m # Gas Constant (Btu/lbm-R)
    else
      @r = nil
    end
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

  def mu
    return @mu
  end

  def M
    return @m
  end

  def R
    return @r
  end
end

class Properties
  def initialize
    # From EES at STP
    @air = Mat_gas.new(0.07518,0.2399,0.01452,0.04415,28.97)
    @h2O_l = Mat_liq.new(62.32,0.9991,0.3386,2.424,1055,32.0,212.0,nil)
    @h2O_v = Mat_gas.new(nil,0.4495,nil,nil,18.02)

    # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
    @r22_l = Mat_liq.new(nil,0.2732,nil,nil,100.5,nil,-41.35,204.9)
    @r22_v = Mat_gas.new(nil,0.1697,nil,nil,nil)

    # From wolframalpha.com
    @wood = Mat_solid.new(630,2500,0.14)

    @psychMassRat = @h2O_v.M / Air.M
  end

  def Air
    return @air
  end

  def H2O_l
    return @h2O_l
  end

  def H2O_v
    return @h2O_v
  end

  def R22_l
    return @r22_l
  end

  def R22_v
    return @r22_v
  end

  def Wood
    return @wood
  end

  def PsychMassRat
    return @psychMassRat
  end
end

class Psychrometrics
  def initialize
  end

  def rhoD_fT_w_P(tdb, w, p)
        '''
        Description:
        ------------
            Calculate the density of dry air at a given drybulb temperature,
            humidity ratio and pressure.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degF)
            w       float      humidity ratio        (lbm/lbm)
            P       float      pressure              (psia)

        Outputs:
        --------
            rhoD    float      density of dry air    (lbm/ft3)
        '''
    properties = Properties.new
    constants = Constants.new
    pair = properties.PsychMassRat * p / (properties.PsychMassRat + w) # (psia)
    rhoD = OpenStudio::convert(pair,"psi","Btu/ft^3").get / (constants.R / properties.Air.M) / (OpenStudio::convert(tdb,"F","R").get) # (lbm/ft3)

    return rhoD

  end

  def h_fT_w_SI(tdb, w)
        '''
        Description:
        ------------
            Calculate the enthalpy at a given drybulb temperature
            and humidity ratio.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degC)
            w       float      humidity ratio        (kg/kg)

        Outputs:
        --------
            h       float      enthalpy              (J/kg)
        '''
    h = 1000.0 * (1.006 * tdb + w * (2501.0 + 1.86 * tdb))
    return h
  end

  def w_fT_h_SI(tdb, h)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature
            and enthalpy.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature  (degC)
            h       float      enthalpy              (J/kg)

        Outputs:
        --------
            w       float      humidity ratio        (kg/kg)
        '''
    w = (h / 1000.0 - 1.006 * tdb) / (2501.0 + 1.86 * tdb)
    return w
  end
end