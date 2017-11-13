require 'C:/Program Files/OpenStudio 1.14.0/Ruby/openstudio'

failures = []
Dir.glob(File.join(File.dirname(__FILE__), "*/**/*.osm")).each do |path|
  puts path
  vt = OpenStudio::OSVersion::VersionTranslator.new
  m = vt.loadModel(path)
  if m.is_initialized
    m.get.save(path, true)
  else
    failures << path
  end
end

if failures.size > 0
  puts
  puts "Failures:"
  puts failures.join("\n")
end