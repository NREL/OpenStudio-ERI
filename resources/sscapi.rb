
require 'ffi'

module SSC
  extend FFI::Library
  ffi_lib FFI::Library::LIBC
  
  if /win/.match(RUBY_PLATFORM) or /mingw/.match(RUBY_PLATFORM)
    # ffi_lib "./resources/ssc.dll"
    ffi_lib "#{File.dirname(__FILE__)}/ssc.dll"
  elsif /darwin/.match(RUBY_PLATFORM)
    ffi_lib "#{File.dirname(__FILE__)}/ssc.dylib"
  elsif /linux2/.match(RUBY_PLATFORM)
    ffi_lib "#{File.dirname(__FILE__)}/ssc.so"
  else
    puts "Platform not supported: #{RUBY_PLATFORM}"
  end
  
  attach_function :ssc_version, [], :int
  attach_function :ssc_build_info, [], :string
  attach_function :ssc_data_create, [], :pointer
  attach_function :ssc_data_free, [:pointer], :void
  attach_function :ssc_data_clear, [:int], :void
  attach_function :ssc_data_unassign, [:pointer, :string], :void
  attach_function :ssc_data_query, [:pointer, :string], :int
  attach_function :ssc_data_first, [:pointer], :string
  attach_function :ssc_data_next, [:pointer], :string
  attach_function :ssc_data_set_string, [:pointer, :string, :string], :void
  attach_function :ssc_data_set_number, [:pointer, :string, :double], :void
  attach_function :ssc_data_set_array, [:pointer, :string, :pointer, :int], :void
  attach_function :ssc_data_set_matrix, [:pointer, :string, :pointer, :int, :int], :void
  attach_function :ssc_data_set_table, [:pointer, :string, :void], :void
  attach_function :ssc_data_get_string, [:pointer, :string], :string
  attach_function :ssc_data_get_number, [:pointer, :string, :pointer], :pointer
  attach_function :ssc_data_get_array, [:int, :string, :pointer], :pointer
  attach_function :ssc_data_get_matrix, [:pointer, :string, :int, :int], :pointer
  attach_function :ssc_data_get_table, [:pointer, :string], :void
  attach_function :ssc_module_entry, [:int], :pointer
  attach_function :ssc_entry_name, [:pointer], :string
  attach_function :ssc_entry_description, [:pointer], :string
  attach_function :ssc_entry_version, [:pointer], :int
  attach_function :ssc_module_create, [:string], :pointer
  attach_function :ssc_module_free, [:pointer], :void
  attach_function :ssc_module_var_info, [:pointer, :int], :pointer
  attach_function :ssc_info_var_type, [:pointer], :int
  attach_function :ssc_info_data_type, [:pointer], :int
  attach_function :ssc_info_name, [:pointer], :string
  attach_function :ssc_info_label, [:pointer], :string
  attach_function :ssc_info_units, [:pointer], :string
  attach_function :ssc_info_meta, [:pointer], :string
  attach_function :ssc_info_group, [:pointer], :string
  attach_function :ssc_info_uihint, [:pointer], :string
  attach_function :ssc_module_exec_set_print, [:int], :void
  attach_function :ssc_module_exec_simple_nothread, [:string, :int], :string
  attach_function :ssc_module_log, [:int, :int, :int, :double], :string
  attach_function :ssc_module_exec, [:pointer, :pointer], :pointer
  
end

class RbSSC

  include SSC

  def initialize
    @rdll = SSC
  end
    
  def version
    return @rdll.ssc_version
  end
  
  def build_info
    return @rdll.ssc_build_info
  end
  
  def data_create
    return @rdll.ssc_data_create()
  end
  
  def data_free(p_data)
    @rdll.ssc_data_free(p_data)
  end
  
  def data_clear(p_data)
    @rdll.ssc_data_clear(p_data)
  end
  
  def data_unassign(p_data, name)
    @rdll.ssc_data_unassign(p_data, name)
  end
  
  def data_query(p_data, name)
    return @rdll.ssc_data_query(p_data, name)
  end
  
  def data_first(p_data)
    @rdll.ssc_data_first(p_data)
  end
  
  def data_next(p_data)
    @rdll.ssc_data_next(p_data)
  end
  
  def data_set_string(p_data, name, value)
    @rdll.ssc_data_set_string(p_data, name, value)
  end
  
  def data_set_number(p_data, name, value)
    @rdll.ssc_data_set_number(p_data, name, value)
  end
  
  def data_set_array(p_data, name, parr)
    count = parr.length
    arr = c_number * count
    arr = parr # set all at once instead of looping
    return @rdll.ssc_data_set_array(p_data, name, arr, count)
  end
  
  def data_set_matrix(p_data, name, mat)
    nrows = mat.length
    ncols = mat[0].length
    size = nrows * ncols
    idx = 0
    (0...nrows).to_a.each do |r|
      (0...ncols).to_a.each do |c|
        arr[idx] = mat[r][c]
        idx += 1
      end
    end
    return @rdll.ssc_data_set_matrix(p_data, name, arr, nrows, ncols)
  end
  
  def data_set_table(p_data, name, tab)
    return @rdll.ssc_data_set_table(p_data, name, tab)
  end
  
  def data_get_string(p_data, name)
    @rdll.ssc_data_get_string(p_data, name)
  end
  
  def data_get_number(p_data, name)
    val = FFI::MemoryPointer.new(:pointer)
    @rdll.ssc_data_get_number(p_data, name, val)
    return val.to_i
  end
  
  def data_get_array(p_data, name)
    pointer = FFI::MemoryPointer.new(:double)
    parr = @rdll.ssc_data_get_array(p_data, name, pointer)
    arr = parr[0..8760] # TODO: count isn't returning 8760
    return arr
  end
  
  def data_get_matrix(p_data, name)
    parr = @rdll.ssc_data_get_matrix(p_data, name, nrows, ncols)
    idx = 0
    mat = []
    (0...nrows.value).to_a.each do |r|
      row = []
      (0...ncols.value).to_a.each do |c|
        row << parr[idx].to_f
        idx += 1
      end
      mat << row
    end
    return mat
  end
  
	# don't call data_free() on the result, it's an internal
	# pointer inside SSC
  def data_get_table(p_data, name)
    return @rdll.ssc_data_get_table(p_data, name)
  end

  def module_entry(index)
    return @rdll.ssc_module_entry(index)
  end
  
  def entry_name(p_entry)
    return @rdll.ssc_entry_name(p_entry)
  end
  
  def entry_description(p_entry)
    return @rdll.ssc_entry_description(p_entry)
  end
  
  def entry_version(p_entry)
    return @rdll.ssc_entry_version(p_entry)
  end
  
  def module_create(name)
    return @rdll.ssc_module_create(name)
    # return @rdll.ssc_module_create(name).to_i
  end
  
  def module_free(p_mod)
    @rdll.ssc_module_free(p_mod)
  end
  
  def module_var_info(p_mod, index)
    return @rdll.ssc_module_var_info(p_mod, index)
  end
  
  def info_var_type(p_inf)
    return @rdll.ssc_info_var_type(p_inf)
  end
  
  def info_data_type(p_inf)
    return @rdll.ssc_info_data_type(p_inf)
  end
  
  def info_name(p_inf)
    return @rdll.ssc_info_name(p_inf)
  end

  def info_label(p_inf)
    return @rdll.ssc_info_label(p_inf)
  end
  
  def info_units(p_inf)
    return @rdll.ssc_info_units(p_inf)
  end
  
  def info_meta(p_inf)
    return @rdll.ssc_info_meta(p_inf)
  end
  
  def info_group(p_inf)
    return @rdll.ssc_info_group(p_inf)
  end
  
  def info_uihint(p_inf)
    return @rdll.ssc_info_uihint(p_inf)
  end
  
  def module_exec(p_mod, p_data)
    return @rdll.ssc_module_exec(p_mod, p_data).to_i
    ssc_module_exec_simple_nothread
  end
  
  def module_exec_simple_no_thread(modname, data)
    return @rdll.ssc_module_exec_simple_nothread(modname, data)
  end
  
  def module_log(p_mod, index)
    log_type = 0 # TODO: not sure what this should be
    time = 0 # TODO: not sure what this should be
    return @rdll.ssc_module_log(p_mod, index, log_type, time)
  end
  
  def module_exec_set_print(prn)
    return @rdll.ssc_module_exec_set_print(prn)
  end  
  
end

def setup_pv(ssc, data)
  ssc.data_set_number(data, 'system_capacity', 4)
  ssc.data_set_number(data, 'module_type', 0)
  ssc.data_set_number(data, 'array_type', 0)
  ssc.data_set_number(data, 'losses', 14)
  ssc.data_set_number(data, 'tilt', 15)
  ssc.data_set_number(data, 'azimuth', 180)
  ssc.data_set_number(data, 'adjust:constant', 0)
end

def run_pvwattsv5(ssc, data)
  # run PV system simulation
  mod = ssc.module_create("pvwattsv5")
  ssc.module_exec_set_print(0)
  if ssc.module_exec(mod, data) == 0
    puts "PVWatts V5 simulation error"
    idx = 1
    msg = ssc.module_log(mod, 0)
    while !msg.nil?
      puts "\t: #{msg}"
      msg = ssc.module_log(mod, idx)
      idx += 1
    end
  else
    ann = ssc.data_get_number(data, "ac_annual")
    puts "PVWatts V5 simulation ok, e_net (annual kW) = #{ann}"
  end
end

def run_test
  
  wf = File.expand_path(File.join(File.dirname(__FILE__), "../../examples/USA AZ Phoenix (TMY2).csv"))
    
  ssc = RbSSC.new
  
  # p_mod = ssc.module_create("pvwattsv5")
  # p_var = ssc.module_var_info(p_mod, 0)
  # puts ssc.ssc_info_var_type(p_var) # 1: SSC_INPUT, 2: SSC_OUTPUT, 3: SSC_INOUT
  # puts ssc.ssc_info_data_type(p_var) # 0: SSC_INVALID, 1: SSC_STRING, 2: SSC_NUMBER, 3: SSC_ARRAY, 4: SSC_MATRIX, 5: SSC_TABLE
  # puts ssc.ssc_info_name(p_var)
  # puts ssc.ssc_info_label(p_var)
  # puts ssc.ssc_info_units(p_var)
  # puts ssc.ssc_info_meta(p_var)
  # puts ssc.ssc_info_group(p_var)
  
  p_dat = ssc.data_create
  setup_pv(ssc, p_dat)
  ssc.data_set_string(p_dat, 'solar_resource_file', wf)
  p_mod = ssc.module_create("pvwattsv5")
  # puts ssc.module_exec(p_mod, p_dat)
  ssc.module_exec_set_print(0)  
  ssc.data_get_number(p_dat, "ac_annual")
  
  dat = ssc.data_create
  setup_pv(ssc, dat)
  ssc.data_set_string(dat, 'solar_resource_file', wf)
  run_pvwattsv5(ssc, dat)  
  ssc.data_clear(dat)
  
  # read a weather file for this example program
  # and extract the data from it into a bunch of Python variables
  # note: this weather data could come from any source  
  ssc.data_set_string(dat, 'file_name', wf)
  ssc.module_exec_simple_no_thread('wfreader', dat)
  lat = ssc.data_get_number(dat, 'lat')
  lon = ssc.data_get_number(dat, 'lon')
  tz = ssc.data_get_number(dat, 'tz')
  elev = ssc.data_get_number(dat, 'elev')
  year = ssc.data_get_array(dat, 'year')
  month = ssc.data_get_array(dat, 'month')
  day = ssc.data_get_array(dat, 'day')
  hour = ssc.data_get_array(dat, 'hour')
  minute = ssc.data_get_array(dat, 'minute')
  beam = ssc.data_get_array(dat, 'beam')
  diffuse = ssc.data_get_array(dat, 'diffuse')
  wspd = ssc.data_get_array(dat, 'wspd')
  tdry = ssc.data_get_array(dat, 'tdry')
  albedo = ssc.data_get_array(dat, 'albedo')
  ssc.data_clear(dat)
  
  # create an SSC data with a bunch of fields
  wfd = ssc.data_create
  ssc.data_set_number(wfd, 'lat', lat)
  ssc.data_set_number(wfd, 'lon', lon)
  ssc.data_set_number(wfd, 'tz', tz)
  ssc.data_set_number(wfd, 'elev', elev)
  
  ssc.data_set_array(wfd, 'year', year)
  ssc.data_set_array(wfd, 'month', month)
  ssc.data_set_array(wfd, 'day', day)
  ssc.data_set_array(wfd, 'hour', hour)
  
  # note: if using an hourly TMY file with integrated/averaged
  # values, do not set the minute column here. otherwise
  # SSC will assume it is instantaneous data and will not adjust
  # the sun position in sunrise and sunset hours appropriately
  # however, if using subhourly data or instantaneous NSRDB data
  # do explicitly provide the minute data column for sunpos calcs  
  
  ssc.data_set_array(wfd, 'dn', beam)
  ssc.data_set_array(wfd, 'df', diffuse)
  ssc.data_set_array(wfd, 'wspd', wspd)
  ssc.data_set_array(wfd, 'tdry', tdry)
  ssc.data_set_array(wfd, 'albedo', albedo)
  
  # instead of setting a string weather file, simply
  # set the table variable that contains the various fields
  # with solar resource data
  ssc.data_set_table(dat, 'solar_resource_data', wfd )
  
  # we can free the resource data table now, since
  # the previous line copies it all into SSC
  ssc.data_free(wfd)
  
  # set up other PV parameters and run
  setup_pv(ssc, dat)
  run_pvwattsv5(ssc, dat)  
  
  ssc.data_free(dat)
  
end

# run_test
