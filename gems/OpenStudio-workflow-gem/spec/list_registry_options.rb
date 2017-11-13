registry = []
registry_register = []
options = []

Dir.glob(File.expand_path('../lib/', File.dirname(__FILE__)) + "/**/*.rb").each do |p|
  
  next if /run.rb/.match(p)
  next if /local.rb/.match(p)
  
  File.open(p, 'r').each_line do |line|
    if md = /registry\[(.*?)\]/.match(line)
      registry << md[1]
    elsif md = /registry.register\((.*?)\)/.match(line)
      registry_register << md[1]
    elsif md = /options\[(.*?)\]/.match(line)
      options << md[1]
    end
  end
end

puts "Registry:"
puts registry.uniq.sort
puts

puts "Registry Register:"
puts registry_register.uniq.sort
puts

puts "Options:"
puts options.uniq.sort