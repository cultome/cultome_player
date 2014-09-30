require 'yaml'
require 'rake'

module CultomePlayer
  module Environment

    # Get the db_adapter environment configuration value.
    #
    # @return [String] The db_adapter value for teh selected environment.
    def db_adapter
      env_config['db_adapter'] || raise('environment problem:environment information not loaded')
    end

    # Get the db_file environment configuration value.
    #
    # @return [String] The db_file value for teh selected environment.
    def db_file
      env_config['db_file'] || raise('environment problem:environment information not loaded')
    end

    # Get the db_log_file environment configuration value.
    #
    # @return [String] The db_log_file value for teh selected environment.
    def db_log_file
      env_config['db_log_file'] || raise('environment problem:environment information not loaded')
    end

    # Get the file_types environment configuration value.
    #
    # @return [String] The file_types value for teh selected environment.
    def file_types
      env_config['file_types'] || raise('environment problem:environment information not loaded')
    end

    # Get the config_file environment configuration value.
    #
    # @return [String] The config_file value for teh selected environment.
    def config_file
      env_config['config_file'] || raise('environment problem:environment information not loaded')
    end

    # Get the mplayer_pipe environment configuration value.
    #
    # @return [String] The mplayer_pipe value for teh selected environment.
    def mplayer_pipe
      env_config['mplayer_pipe'] || raise('environment problem:environment information not loaded')
    end

    # Get the stdout (not STDOUT) for the player.
    #
    # @return [IO] The stdout for the player.
    def stdout
      STDOUT
    end

    # Gets the player configurations.
    #
    # @return [Hash] Player configuration.
    def player_config
      @player_config ||= {}
    end

    # Gets the environment configurations.
    #
    # @return [Hash] Environment configuration.
    def env_config
      @env_config ||= {}
    end

    # Get the current environment name.
    #
    # @return [Symbol] The current environment name.
    def current_env
      @current_env
    end

    # Extract the configuration for the environment and setup valriables.
    #
    # @param env [Symbol] The name of the environment to load.
    # @param check_db [Boolean] Flag to decide if the database schema should be checked.
    def prepare_environment(env)
      env_config = YAML.load_file File.expand_path('config/environment.yml')
      @env_config = env_config[env.to_s]
      @current_env = env.to_sym
      raise 'environment problem:environment not found' if @env_config.nil?
      expand_paths @env_config
      create_required_files @env_config
      load_master_config @env_config['config_file']
    end

    def recreate_db_schema
      Rake.load_rakefile 'Rakefile'
      Rake.application.load_imports
      swallow_stdout{ Rake.application.invoke_task("db:create[#{current_env}]") }
    end

    def save_player_configurations
      open(config_file, 'w'){|f| f.write player_config.to_yaml }
    end

    private

    def load_master_config(config_file)
      @player_config = YAML.load_file(config_file) || {}
      @player_config['main'] ||= {}
    end

    def create_required_files(env_config)
      env_config.each do |k,v|
        if k.end_with?('_file')
          unless File.exist?(v)
            %x[mkdir -p '#{File.dirname(v)}' && touch '#{v}']
            raise 'environment problem:cannot create required files' unless $?.success?
          end
        elsif k.end_with?('_pipe')
          unless File.exist?(v)
            %x[mkfifo '#{v}']
            raise 'environment problem:cannot create required pipe' unless $?.success?
          end
        end
      end
    end

    def expand_paths(env_config)
      env_config.each do |k,v|
        if k.end_with?('_file') || k.end_with?('_pipe')
          env_config[k] = File.expand_path(v)
        end
      end
    end

  end
end
