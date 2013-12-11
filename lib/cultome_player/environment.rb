require 'yaml'

module CultomePlayer
  module Environment
    def db_adapter
      env_config['db_adapter'] || raise('environment problem:environment information not loaded')
    end

    def db_file
      env_config['db_file'] || raise('environment problem:environment information not loaded')
    end

    def db_log_file
      env_config['db_log_file'] || raise('environment problem:environment information not loaded')
    end

    def file_types
      env_config['file_types'] || raise('environment problem:environment information not loaded')
    end

    def config_file
      env_config['config_file'] || raise('environment problem:environment information not loaded')
    end

    def player_config
      @player_config ||= {}
    end

    def env_config
      @env_config ||= {}
    end

    def prepare_environment(env)
      env_config = YAML.load_file File.expand_path('config/environment.yml')
      @env_config = env_config[env.to_s]
      raise 'environment problem:environment not found' if @env_config.nil?
      expand_paths @env_config
      create_required_files @env_config
      load_master_config @env_config
    end

    def load_master_config(env)
      config_file = File.expand_path env['config_file']
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
        end
      end
    end

    private

    def expand_paths(env_config)
      env_config.each do |k,v|
        if k.end_with?('_file')
          env_config[k] = File.expand_path(v)
        end
      end
    end

  end
end
