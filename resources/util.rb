
# Add classes or functions here than can be used across a variety of our python classes and modules.

class HelperMethods

    # Retrieves the number of bedrooms and bathrooms from the space type
    # They are assigned in the SetResidentialBedroomsAndBathrooms measure.
    def self.get_bedrooms_bathrooms(model, spacetype_handle, runner=nil)
        nbeds = nil
        nbaths = nil
        model.getSpaceTypes.each do |spaceType|
            if spaceType.handle.to_s == spacetype_handle.to_s
                space_equipments = spaceType.electricEquipment
                space_equipments.each do |space_equipment|
                    name = space_equipment.electricEquipmentDefinition.name.get.to_s
                    br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(name)
                    ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(name)	
                    if br_regexpr
                        nbeds = br_regexpr[:br].to_f
                    elsif ba_regexpr
                        nbaths = ba_regexpr[:ba].to_f
                    end
                end
            end
        end
        if nbeds.nil? or nbaths.nil?
            if not runner.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            end
        end
        return [nbeds, nbaths]
    end
    
    # Retrieves the floor area of the specified space type
    def self.get_floor_area(model, spacetype_handle, runner=nil)
        floor_area = 0
        model.getSpaceTypes.each do |spaceType|
            if spaceType.handle.to_s == spacetype_handle.to_s
                floor_area = OpenStudio.convert(spaceType.floorArea,"m^2","ft^2").get
            end
        end
        return floor_area
    end
    
end

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
	  gas_constant = 1.9858 # Gas Constant (Btu/lbmol-R)
      @r  = gas_constant / m # Gas Constant (Btu/lbm-R)
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
  def self.Air
    # From EES at STP
    return Mat_gas.new(0.07518,0.2399,0.01452,0.04415,28.97)
  end

  def self.H2O_l
    # From EES at STP
    return Mat_liq.new(62.32,0.9991,0.3386,2.424,1055,32.0,212.0,nil)
  end

  def self.H2O_v
    # From EES at STP
    return Mat_gas.new(nil,0.4495,nil,nil,18.02)
  end

  def self.R22_l
    # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
    return Mat_liq.new(nil,0.2732,nil,nil,100.5,nil,-41.35,204.9)
  end

  def self.R22_v
    # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
    return Mat_gas.new(nil,0.1697,nil,nil,nil)
  end

  def self.Wood
    # From wolframalpha.com
    return Mat_solid.new(630,2500,0.14)
  end

  def self.PsychMassRat
    return Properties.H2O_v.M / Properties.Air.M
  end
end

class EnergyGuideLabel
  def self.get_energy_guide_gas_cost(date)
    # Search for, e.g., "Representative Average Unit Costs of Energy for 
    # Five Residential Energy Sources (1996)"
    if date <= 1991
        # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
        return 60.54
    elsif date == 1992
        # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
        return 58.0
    elsif date == 1993
        # No data, use prev/next years
        return (58.0 + 60.40)/2.0
    elsif date == 1994
        # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
        return 60.40
    elsif date == 1995
        # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
        return 63.0
    elsif date == 1996
        # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
        return 62.6
    elsif date == 1997
        # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
        return 61.2
    elsif date == 1998
        # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
        return 61.9
    elsif date == 1999
        # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
        return 68.8
    elsif date == 2000
        # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
        return 68.8
    elsif date == 2001
        # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
        return 83.7
    elsif date == 2002
        # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086
        return 65.6
    elsif date == 2003
        # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
        return 81.6
    elsif date == 2004
        # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
        return 91.0
    elsif date == 2005
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
        return 109.2
    elsif date == 2006
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
        return 141.5
    elsif date == 2007
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
        return 121.8
    elsif date == 2008
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
        return 132.8
    elsif date == 2009
        # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
        return 111.2
    elsif date == 2010
        # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
        return 119.4
    elsif date == 2011
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
        return 110.1
    elsif date == 2012
        # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
        return 105.9
	elsif date == 2013
		# http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
		return 108.7
	elsif date == 2014
		# http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
		return 112.8
	elsif date >= 2015
		# http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
		return 100.3
	end
  end
  
  def self.get_energy_guide_elec_cost(date)
    # Search for, e.g., "Representative Average Unit Costs of Energy for 
    # Five Residential Energy Sources (1996)"
    if date <= 1991
        # http://books.google.com/books?id=GsY5AAAAIAAJ&pg=PA184&lpg=PA184&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1991&source=bl&ots=QuQ83OQ1Wd&sig=jEsENidBQCtDnHkqpXGE3VYoLEg&hl=en&sa=X&ei=3QOjT-y4IJCo8QSsgIHVCg&ved=0CDAQ6AEwBA#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201991&f=false
        return 8.24
    elsif date == 1992
        # http://books.google.com/books?id=esk5AAAAIAAJ&pg=PA193&lpg=PA193&dq=%22Representative+Average+Unit+Costs+of+Energy+for+Five+Residential+Energy+Sources%22+1992&source=bl&ots=tiUb_2hZ7O&sig=xG2k0WRDwVNauPhoXEQOAbCF80w&hl=en&sa=X&ei=owOjT7aOMoic9gTw6P3vCA&ved=0CDIQ6AEwAw#v=onepage&q=%22Representative%20Average%20Unit%20Costs%20of%20Energy%20for%20Five%20Residential%20Energy%20Sources%22%201992&f=false
        return 8.25
    elsif date == 1993
        # No data, use prev/next years
        return (8.25 + 8.41)/2.0
    elsif date == 1994
        # http://govpulse.us/entries/1994/02/08/94-2823/rule-concerning-disclosures-of-energy-consumption-and-water-use-information-about-certain-home-appli
        return 8.41
    elsif date == 1995
        # http://www.ftc.gov/os/fedreg/1995/february/950217appliancelabelingrule.pdf
        return 8.67
    elsif date == 1996
        # http://www.gpo.gov/fdsys/pkg/FR-1996-01-19/pdf/96-574.pdf
        return 8.60
    elsif date == 1997
        # http://www.ftc.gov/os/fedreg/1997/february/970205ruleconcerningdisclosures.pdf
        return 8.31
    elsif date == 1998
        # http://www.gpo.gov/fdsys/pkg/FR-1997-12-08/html/97-32046.htm
        return 8.42
    elsif date == 1999
        # http://www.gpo.gov/fdsys/pkg/FR-1999-01-05/html/99-89.htm
        return 8.22
    elsif date == 2000
        # http://www.gpo.gov/fdsys/pkg/FR-2000-02-07/html/00-2707.htm
        return 8.03
    elsif date == 2001
        # http://www.gpo.gov/fdsys/pkg/FR-2001-03-08/html/01-5668.htm
        return 8.29
    elsif date == 2002
        # http://govpulse.us/entries/2002/06/07/02-14333/rule-concerning-disclosures-regarding-energy-consumption-and-water-use-of-certain-home-appliances-an#id963086 
        return 8.28
    elsif date == 2003
        # http://www.gpo.gov/fdsys/pkg/FR-2003-04-09/html/03-8634.htm
        return 8.41
    elsif date == 2004
        # http://www.ftc.gov/os/fedreg/2004/april/040430ruleconcerningdisclosures.pdf
        return 8.60
    elsif date == 2005
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2005_costs.pdf
        return 9.06
    elsif date == 2006
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2006_energy_costs.pdf
        return 9.91
    elsif date == 2007
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/price_notice_032707.pdf
        return 10.65
    elsif date == 2008
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2008_forecast.pdf
        return 10.80
    elsif date == 2009
        # http://www1.eere.energy.gov/buildings/appliance_standards/commercial/pdfs/ee_rep_avg_unit_costs.pdf
        return 11.40
    elsif date == 2010
        # http://www.gpo.gov/fdsys/pkg/FR-2010-03-18/html/2010-5936.htm
        return 11.50
    elsif date == 2011
        # http://www1.eere.energy.gov/buildings/appliance_standards/pdfs/2011_average_representative_unit_costs_of_energy.pdf
        return 11.65
    elsif date == 2012
        # http://www.gpo.gov/fdsys/pkg/FR-2012-04-26/pdf/2012-10058.pdf
        return 11.84
	elsif date == 2013
		# http://www.gpo.gov/fdsys/pkg/FR-2013-03-22/pdf/2013-06618.pdf
		return 12.10
	elsif date == 2014
		# http://www.gpo.gov/fdsys/pkg/FR-2014-03-18/pdf/2014-05949.pdf
		return 12.40
	elsif date >= 2015
		# http://www.gpo.gov/fdsys/pkg/FR-2015-08-27/pdf/2015-21243.pdf
		return 12.70
	end
  end
  
end