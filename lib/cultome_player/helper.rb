require 'logger'

module CultomePlayer
    module Helper

        CONFIG_FILE_NAME = "config.yml"

        def display(msg, continous=false)
            if continous
                output.print msg.to_s
            else
                output.puts msg.to_s
            end
        end

        def display_with_prompt(msg)
            display("\r#{msg}\n#{c4(player.current_prompt)}", true)
        end

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
            #@user_dir ||= File.join(Dir.home, ".cultome")
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

        def default_external_player_installation_path 
            @default_external_player_installation_path ||= "#{project_path}/ext_player"
        end

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
    end
end
