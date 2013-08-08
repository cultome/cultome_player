# encoding: utf-8
require 'logger'
require 'net/http'

module CultomePlayer
  module Helper

    # The default configuration file's name
    CONFIG_FILE_NAME = "config.yml"

    # Send a message to the defined output
    #
    # @param msg [String] The message to be printed
    # @param continous [Boolean] If false (as default) append a new line character at the end of the message.
    def display(msg, continous=false)
      if continous
        output.print msg.to_s
      else
        output.puts msg.to_s
      end
    end

    # Send a message to the defined output appending the application prompt as a new lines in the message
    #
    # @param msg [String] The message to be printed.
    def display_with_prompt(msg)
      display("\r#{msg}\n#{c4(player.current_prompt)}", true)
    end

    # Accesor to the defined output source. If not defined used STDOUT.
    #
    # @return An object that respond to #puts and #print.
    def output
      @output ||= respond_to?(:player_output) ? player_output : $stdout
    end

    # Tries to detect the operating system in which is running.
    #
    # @return [Symbol] the OS detected
    def os
      @_os ||= (
        host_os = RbConfig::CONFIG['host_os']
        case host_os
        when /mswin|msys|mingw|sygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :macosx
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          raise Exception.new("unknown os: #{host_os}")
        end
      )
    end
    # Create a context with a managed connection from the pool. The block passed will be
    # inside a valid connection.
    #
    # @param db_logic [Block] The logic that require a valid db connection.

    def with_connection(&db_logic)
      begin
        ActiveRecord::Base.connection_pool
      rescue Exception => e
        ActiveRecord::Base.establish_connection(
          adapter: db_adapter,
          database: db_file
        )
        ActiveRecord::Base.logger = Logger.new(File.open(db_log_path, 'a'))
      end

      ActiveRecord::Base.connection_pool.with_connection(&db_logic)
    end

    # Return the path to the db data file.
    #
    # @return  [String] The path to the db data file.
    def db_file
      environment[:database_file]
    end

    # Return the path to the base of the instalation.
    #
    # @return [String] The path to the base of the instalation.
    def project_path
      @project_path ||= File.expand_path(File.dirname(__FILE__) + "/../..")
    end

    # Return the path to the logs folder.
    #
    # @return [String] The path to the logs folder.
    def db_logs_folder_path
      "#{ user_dir }/db_logs"
    end

    # Return the path to the log file.
    #
    # @return [String] The path to the log file.
    def db_log_path
      "#{db_logs_folder_path}/cultome_player.log"
    end

    # Return the db adapter name used.
    #
    # @return [String] The db adapter name.
    def db_adapter
      environment[:db_adapter]
    end

    # Return the directory inside user home where this player writes his configurations
    #
    # @return [String] The directory where player writes its configurations
    def user_dir
      environment[:user_dir]
    end

    # Return the path to the player's config file
    #
    # @return [String] The absoulute path to the config file
    def config_file
      environment[:config_file]
    end

    # Return the path to the migrations folder.
    #
    # @return [String] The path to the migrations folder.
    def migrations_path
      "#{ project_path }/db/migrate"
    end

    # Return the environment configurations
    #
    # @return [Hash] With the environment configurations
    def environment
      @env ||= set_environment
    end

    # Return the path where the external player is installed.
    #
    # @return [String] The path where the external player is installed.
    def default_external_player_installation_path 
      @default_external_player_installation_path ||= "#{project_path}/ext_player"
    end

    # Set the environment variables. This should be the first thing you do, because once initialized, the variables can be updated. Is recommended to use this method during the initialize method.
    #
    # @param new_env [Hash] With any of the following keys: db_adapter, database_file, config_file, user_dir or ext_player_launch_cmd.
    # @return [Hash] The new environment variables.
    def set_environment(new_env={})
      # setteamos las configuracion por default mezcladas con las del usuario
      user_dir = new_env[:user_dir] || File.join(Dir.home, ".cultome")
      classpath = Dir.entries(default_external_player_installation_path).collect{|f|
        "#{default_external_player_installation_path}/#{f}" if f =~ /\.jar\Z/
      }.join(File::PATH_SEPARATOR)

      @env = {
        db_adapter: 'sqlite3',
        database_file: File.join(user_dir, "db_cultome.dat"),
        config_file: File.join(user_dir, CONFIG_FILE_NAME),
        user_dir: user_dir,
        ext_player_launch_cmd:  "java -cp \"#{classpath}\" com.cultome.cultomeplayer.Main"
      }.merge(new_env)
    end

    # Capture and dispose the standard output sended inside the block provided.
    def swallow_stdout
      s = StringIO.new
      oldstd = $stdout
      $stdout = s
      yield
      s.string
    ensure
      $stdout = oldstd
    end

    # Get a HTTP client for handle request. It check for environment variable __http_proxy__ and if setted, create Prxyed client.
    #
    # @return [Net::HTTP] The client to make request.
    def get_http_client
      return Net::HTTP unless ENV['http_proxy']

      proxy = URI.parse ENV['http_proxy']
      Net::HTTP::Proxy(proxy.host, proxy.port)
    end
  end
end
