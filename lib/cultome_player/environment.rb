require 'yaml'
require 'rake'

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

    def mplayer_pipe
      env_config['mplayer_pipe'] || raise('environment problem:environment information not loaded')
    end

    def stdout
      STDOUT
    end

    def player_config
      @player_config ||= {}
    end

    def env_config
      @env_config ||= {}
    end

    def current_env
      @current_env
    end

    def prepare_environment(env, check_db=true)
      env_config = YAML.load_file File.expand_path('config/environment.yml')
      @env_config = env_config[env.to_s]
      @current_env = env.to_sym
      raise 'environment problem:environment not found' if @env_config.nil?
      expand_paths @env_config
      create_required_files @env_config
      load_master_config @env_config['config_file']
      check_db_schema if check_db
    end

    private

    def check_db_schema
      Rake.load_rakefile 'Rakefile'
      Rake.application.load_imports
      swallow_stdout{ Rake.application.invoke_task("db:create[#{current_env}]") }
    end

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
