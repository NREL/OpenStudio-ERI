class Psychrometrics
  def self.rhoD_fT_w_P(tdb, w, p)
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
    pair = Gas.PsychMassRat * p / (Gas.PsychMassRat + w) # (psia)
    rhoD = OpenStudio::convert(pair,"psi","Btu/ft^3").get / Gas.Air.R / (OpenStudio::convert(tdb,"F","R").get) # (lbm/ft3)

    return rhoD

  end

  def self.h_fT_w_SI(tdb, w)
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

  def self.w_fT_h_SI(tdb, h)
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

  def self.Pstd_fZ(z)
        '''
        Description:
        ------------
            Calculate standard pressure of air at a given altitude

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Z        float        altitude     (feet)

        Outputs:
        --------
            Pstd    float        barometric pressure (psia)
        '''

    pstd = 14.696 * ((1 - 6.8754e-6 * z) ** 5.2559)
    return pstd
  end

  def self.W_fT_Twb_P(tdb, twb, p)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature,
            wetbulb temperature and pressure.

        Source:
        -------
            ASHRAE Handbook 2009

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degF)
            Twb     float      wetbulb temperature   (degF)
            P       float      pressure              (psia)

        Outputs:
        --------
            w       float      humidity ratio        (lbm/lbm)
        '''
    w_star = Psychrometrics.w_fP(p, Psychrometrics.Psat_fT(twb))

    w = ((Liquid.H2O_l.H_fg - (Liquid.H2O_l.Cp - Gas.H2O_v.Cp) * twb) * w_star - Gas.Air.Cp * (tdb - twb)) / (Liquid.H2O_l.H_fg + Gas.H2O_v.Cp * tdb - Liquid.H2O_l.Cp * twb) # (lbm/lbm)
    return w
  end

  def self.w_fP(p, pw)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given pressure and partial pressure.

        Source:
        -------
            Based on HUMRATIO f77 code in ResAC (Brandemuehl)

        Inputs:
        -------
            P       float      pressure              (psia)
            Pw      float      partial pressure      (psia)

        Outputs:
        --------
            w       float      humidity ratio        (lbm/lbm)
        '''
    w = Gas.PsychMassRat * pw / (p - pw)
    return w
  end

  def self.Psat_fT(tdb)
        '''
        Description:
        ------------
            Calculate the saturation pressure of water vapor at a given temperature

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature      (degF)

        Outputs:
        --------
            Psat    float      saturated vapor pressure (psia)
        '''
    c1 = -1.0214165e4
    c2 = -4.8932428
    c3 = -5.3765794e-3
    c4 = 1.9202377e-7
    c5 = 3.5575832e-10
    c6 = -9.0344688e-14
    c7 = 4.1635019
    c8 = -1.0440397e4
    c9 = -1.1294650e1
    c10 = -2.7022355e-2
    c11 = 1.2890360e-5
    c12 = -2.4780681e-9
    c13 = 6.5459673

    t_abs = OpenStudio::convert(tdb,"F","R").get
    t_frz_abs = OpenStudio::convert(Liquid.H2O_l.T_frz)

    # If below freezing, calculate saturation pressure over ice
    if t_abs < t_frz_abs
      psat = Math.exp(c1 / t_abs + c2 + t_abs * (c3 + t_abs * (c4 + t_abs * (c5 + c6 * t_abs))) + c7 * Math.log(t_abs))
    # If above freezing, calculate saturation pressure over liquid water
    elsif
      psat = Math.exp(c8 / t_abs + c9 + t_abs * (c10 + t_abs * (c11 + c12 * t_abs)) + c13 * Math.log(t_abs))
    end
    return psat
  end
  
end