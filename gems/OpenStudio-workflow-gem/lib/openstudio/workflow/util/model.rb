module OpenStudio
  module Workflow
    module Util
      # Manages routine tasks involving OpenStudio::Model or OpenStudio::Workflow objects, such as loading, saving, and
      # translating them.
      #
      module Model
        # Method to create / load an OSM file
        #
        # @param [String] osm_path The full path to an OSM file to load
        # @param [Object] logger An optional logger to use for finding the OSM model
        # @return [Object] The return from this method is a loaded OSM or a failure.
        #
        def load_osm(osm_path, logger)
          logger.info 'Loading OSM model'

          # Load the model and return it
          logger.info "Reading in OSM model #{osm_path}"

          loaded_model = nil
          begin
            translator = OpenStudio::OSVersion::VersionTranslator.new
            loaded_model = translator.loadModel(osm_path)
          rescue
            # TODO: get translator working in embedded.
            # Need to embed idd files
            logger.warn 'OpenStudio VersionTranslator could not be loaded'
            loaded_model = OpenStudio::Model::Model.load(osm_path)
          end
          raise "Failed to load OSM file #{osm_path}" if loaded_model.empty?
          loaded_model.get
        end

        # Method to create / load an IDF file
        #
        # @param [String] idf_path Full path to the IDF
        # @param [Object] logger An optional logger to use for finding the idf model
        # @return [Object] The return from this method is a loaded IDF or a failure.
        #
        def load_idf(idf_path, logger)
          logger.info 'Loading IDF model'

          # Load the IDF into a workspace object and return it
          logger.info "Reading in IDF model #{idf_path}"

          idf = OpenStudio::Workspace.load(idf_path)
          raise "Failed to load IDF file #{idf_path}" if idf.empty?
          idf.get
        end

        # Translates a OpenStudio model object into an OpenStudio IDF object
        #
        # @param [Object] model the OpenStudio::Model instance to translate into an OpenStudio::Workspace object -- see
        #   the OpenStudio SDK for details on the process
        # @return [Object] Returns and OpenStudio::Workspace object
        # @todo (rhorsey) rescue errors here
        #
        def translate_to_energyplus(model, logger = nil)
          logger = ::Logger.new(STDOUT) unless logger
          logger.info 'Translate object to EnergyPlus IDF in preparation for EnergyPlus'
          a = ::Time.now
          # ensure objects exist for reporting purposes
          model.getFacility
          model.getBuilding
          forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
          model_idf = forward_translator.translateModel(model)
          b = ::Time.now
          logger.info "Translate object to EnergyPlus IDF took #{b.to_f - a.to_f}"
          model_idf
        end

        # Saves an OpenStudio model object to file
        #
        # @param [Object] model The OpenStudio::Model instance to save to file
        # @param [String] save_directory Folder to save the model in
        # @param [String] name ('in.osm') Option to define a non-standard name
        # @return [String] OSM file name
        #
        def save_osm(model, save_directory, name = 'in.osm')
          osm_filename = File.join(save_directory.to_s, name.to_s)
          File.open(osm_filename, 'w') { |f| f << model.to_s }
          osm_filename
        end

        # Saves an OpenStudio IDF model object to file
        #
        # @param [Object] model The OpenStudio::Workspace instance to save to file
        # @param [String] save_directory Folder to save the model in
        # @param [String] name ('in.osm') Option to define a non-standard name
        # @return [String] IDF file name
        #
        def save_idf(model_idf, save_directory, name = 'in.idf')
          idf_filename = File.join(save_directory.to_s, name.to_s)
          File.open(idf_filename, 'w') { |f| f << model_idf.to_s }
          idf_filename
        end
      end
    end
  end
end
