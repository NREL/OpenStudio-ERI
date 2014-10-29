
module BA_Protocol
  require 'OpenStudio'

  Gallon = OpenStudio::createUnit('gal').get
  KiloWatt = OpenStudio::createUnit('kW').get
  KBtuHr = OpenStudio::createUnit("kBtu/hr").get
  
  def self.gal(val)
    OpenStudio::Quantity.new(val, Gallon)
  end
  
  def self.kW(val)
    OpenStudio::Quantity.new(val, KiloWatt)
  end

  def self.kBtuhr(val)
    OpenStudio::Quantity.new(val, KBtuHr)
  end
  
  
  Table_8_electric = {
    [1, "1" ]           => { storage: gal(30), capacity: kW(2.5), energy_factor: 0.93 },
    [1, "1.5" ]         => { storage: gal(30), capacity: kW(2.5), energy_factor: 0.93 },
    [1, "2" ]           => { storage: gal(30), capacity: kW(2.5), energy_factor: 0.93 },
    [1, "2.5" ]         => { storage: gal(30), capacity: kW(2.5), energy_factor: 0.93 },
    [1, "3" ]           => { storage: gal(30), capacity: kW(2.5), energy_factor: 0.93 },
    [1, "3.5 or more" ] => { storage: gal(30), capacity: kW(2.5), energy_factor: 0.93 },
    [2, "1" ]           => { storage: gal(30), capacity: kW(3.5), energy_factor: 0.93 },
    [2, "1.5" ]         => { storage: gal(30), capacity: kW(3.5), energy_factor: 0.93 },
    [2, "2" ]           => { storage: gal(40), capacity: kW(4.5), energy_factor: 0.92 },
    [2, "2.5" ]         => { storage: gal(40), capacity: kW(4.5), energy_factor: 0.92 },
    [2, "3" ]           => { storage: gal(40), capacity: kW(4.5), energy_factor: 0.92 },
    [2, "3.5 or more" ] => { storage: gal(40), capacity: kW(4.5), energy_factor: 0.92 },
    [3, "1" ]           => { storage: gal(40), capacity: kW(4.5), energy_factor: 0.92 },
    [3, "1.5" ]         => { storage: gal(40), capacity: kW(4.5), energy_factor: 0.92 },
    [3, "2" ]           => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [3, "2.5" ]         => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [3, "3" ]           => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [3, "3.5 or more" ] => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [4, "1" ]           => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [4, "1.5" ]         => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [4, "2" ]           => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [4, "2.5" ]         => { storage: gal(50), capacity: kW(5.5), energy_factor: 0.90 },
    [4, "3" ]           => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [4, "3.5 or more" ] => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [5, "1" ]           => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [5, "1.5" ]         => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [5, "2" ]           => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [5, "2.5" ]         => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [5, "3" ]           => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
    [5, "3.5 or more" ] => { storage: gal(66), capacity: kW(5.5), energy_factor: 0.88 },
  }
  Table_8_gas = {
    [1, "1" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [1, "1.5" ]         => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [1, "2" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [1, "2.5" ]         => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [1, "3" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [1, "3.5 or more" ] => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [2, "1" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [2, "1.5" ]         => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [2, "2" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [2, "2.5" ]         => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [2, "3" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [2, "3.5 or more" ] => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [3, "1" ]           => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [3, "1.5" ]         => { storage: gal(30), capacity: kBtuhr(36), energy_factor: 0.61 },
    [3, "2" ]           => { storage: gal(40), capacity: kBtuhr(36), energy_factor: 0.59 },
    [3, "2.5" ]         => { storage: gal(40), capacity: kBtuhr(36), energy_factor: 0.59 },
    [3, "3" ]           => { storage: gal(40), capacity: kBtuhr(36), energy_factor: 0.59 },
    [3, "3.5 or more" ] => { storage: gal(40), capacity: kBtuhr(36), energy_factor: 0.59 },
    [4, "1" ]           => { storage: gal(40), capacity: kBtuhr(38), energy_factor: 0.59 },
    [4, "1.5" ]         => { storage: gal(40), capacity: kBtuhr(38), energy_factor: 0.59 },
    [4, "2" ]           => { storage: gal(40), capacity: kBtuhr(38), energy_factor: 0.59 },
    [4, "2.5" ]         => { storage: gal(40), capacity: kBtuhr(38), energy_factor: 0.59 },
    [4, "3" ]           => { storage: gal(50), capacity: kBtuhr(38), energy_factor: 0.58 },
    [4, "3.5 or more" ] => { storage: gal(50), capacity: kBtuhr(38), energy_factor: 0.58 },
    [5, "1" ]           => { storage: gal(50), capacity: kBtuhr(48), energy_factor: 0.58 },
    [5, "1.5" ]         => { storage: gal(50), capacity: kBtuhr(48), energy_factor: 0.58 },
    [5, "2" ]           => { storage: gal(50), capacity: kBtuhr(48), energy_factor: 0.58 },
    [5, "2.5" ]         => { storage: gal(50), capacity: kBtuhr(48), energy_factor: 0.58 },
    [5, "3" ]           => { storage: gal(50), capacity: kBtuhr(48), energy_factor: 0.58 },
    [5, "3.5 or more" ] => { storage: gal(50), capacity: kBtuhr(48), energy_factor: 0.58 },
  }
end

  
