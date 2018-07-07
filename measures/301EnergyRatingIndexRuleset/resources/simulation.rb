class Simulation

    def self.apply(model, runner, timesteps=1, convlim_min=nil)

        sim = model.getSimulationControl
        sim.setRunSimulationforSizingPeriods(false)
        
        tstep = model.getTimestep
        tstep.setNumberOfTimestepsPerHour(timesteps)
        
        shad = model.getShadowCalculation
        shad.setCalculationFrequency(20)
        shad.setMaximumFiguresInShadowOverlapCalculations(200)
        
        outsurf = model.getOutsideSurfaceConvectionAlgorithm
        outsurf.setAlgorithm('DOE-2')
        
        insurf = model.getInsideSurfaceConvectionAlgorithm
        insurf.setAlgorithm('TARP')
        
        zonecap = model.getZoneCapacitanceMultiplierResearchSpecial
        zonecap.setHumidityCapacityMultiplier(15)

        if not convlim_min.nil?
          convlim = model.getConvergenceLimits
          convlim.setMinimumSystemTimestep(convlim_min)
        end
        
        return true
    end
       
end