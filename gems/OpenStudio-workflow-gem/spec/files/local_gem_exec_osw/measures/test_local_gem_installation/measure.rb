class TestLocalGemInstallation < OpenStudio::Ruleset::ModelUserScript

  def name
    'Test if the gem paths are properly loaded'
  end

  def arguments(model)
    OpenStudio::Ruleset::OSArgumentVector.new
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    begin
      require 'color_string'
    rescue
      runner.register_error "Error requiring gem: #{e.message} in #{e.backtrace.join("\n")}"
      return false
    end

    true

  end

end

TestLocalGemInstallation.new.registerWithApplication
