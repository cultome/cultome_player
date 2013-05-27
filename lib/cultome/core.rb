require 'cultome/player_listener'
require 'cultome/exception'
require 'active_support'
require 'active_support/inflector'
require 'active_record'
require 'logger'

# This class represents and holds the music player's state in one moment.
# This means that plugins can ask about, for example, current song, focused list or connected
# drives to make its work.
# Its work basicly is to load and call plugins (a.k.a registered commands), receive and parse user input 
# and call listeners/commands registered.
module Cultome
    class CultomePlayer
        include InstallationIntegrity
        include UserInput
        include PlayerListener
        include Helper
        include Plugins

        attr_accessor :playlist
        attr_accessor :search
        attr_accessor :history
        attr_accessor :queue
        attr_accessor :focus
        attr_accessor :drives

        attr_accessor :song
        attr_accessor :prev_song
        attr_accessor :artist
        attr_accessor :album
        attr_accessor :running
        attr_accessor :play_index
        attr_accessor :is_playing_library
        attr_accessor :is_shuffling

        attr_reader :player
        attr_reader :status
        attr_reader :song_status
        attr_reader :current_command

        def initialize
            @config = master_config["core"]

            @player = Player.new(self)
            @search = []
            @playlist = []
            @history = []
            @queue = []
            @play_index = -1
            @prompt = @config["prompt"]
            @status = :STOPPED
            @song_status = {}
            @last_cmds = []
            @is_shuffling = true
            @is_playing_library = false
            #@command_registry = []
            #@listener_registry = Hash.new{|h,k| h[k] = []}
            #@commands_help = {}
            @commands_loaded = false
        end

=begin
        # Load and registers commands and listeners presents in folder lib/cultome/commands.
        # With the commands create the in-app help.
        # When the app dont use start method, this mehod must be called manually.
        #
        # @return [Hash<Symbol, Class<? extends BaseCommand>>] The command registry after the load
        def load_commands
            with_connection do
                commands_path = "#{project_path}/lib/plugins"
                Dir.entries(commands_path).each{|file|
                    if file =~ /.rb\Z/
                        file_name = file.gsub('.rb', '')
                        require "plugins/#{file_name}"

                        plugin_cfg = master_config[file_name]
                        if plugin_cfg.nil?
                            plugin_cfg = master_config[file_name] = {}
                        end

                        command = "Plugin::#{file_name.classify}".constantize.new(self, plugin_cfg)

                        cmd_regs = command.get_command_registry if command.respond_to?(:get_command_registry)
                        cmd_regs.each{|k,v|
                            @command_registry.push k
                            @listener_registry[k] << command
                            v[:command] = k
                            @commands_help[k] = v
                        } unless cmd_regs.nil?

                        listener_regs = command.get_listener_registry if command.respond_to?(:get_listener_registry)
                        listener_regs.each{|k,v|
                            @listener_registry[k] << command
                        } unless listener_regs.nil?
                    end
                }
                # luego cargamos los comandos que provee esta clase
                @command_registry.push :help
                @listener_registry[:help] << self

                generate_help(@commands_help.values)

                @commands_loaded = true

                return @command_registry, @listener_registry
            end
        end
=end

        # Utility method for running a standalone player. Initialize the commands
        # and loop to get user input until @running flag is set to false.
        # When a error is detected, a call to #execute with 'next' input is invoked.
        def start
            @running = true

            while(@running) do
                execute get_command
            end
        end

        # Parse a user input into a command and dispatch it to the registered plugins.
        #
        # @param user_input [String] The user input
        # @return (see #send_to_listeners)
        def execute(user_input)
            begin
                cmds = parse(user_input)
                if cmds.nil? || cmds.empty?
                    cmds = @last_cmds
                else
                    @last_cmds = cmds
                end

                with_connection do
                    cmds.each do |cmd|
                        send_to_listeners(cmd[:command], cmd[:params])
                    end
                end
            rescue CultomePlayerException => ctmex
                send_to_listeners('player_exception_throwed', ctmex, :__PLAYER_EXCEPTIONS__)
                default_error_action( ctmex )
            rescue Exception => ex
                default_error_action( ex ) unless send_to_listeners('exception_throwed', ctmex, :__EXCEPTIONS__)
            end
        end

        # Shows the generated in-app help message.
        def help(params=[])
            if params.empty?
                display c4(@help_msg)
            else
                cmd = params[0][:value].to_sym
                cmd_help = @commands_help[cmd]
                if cmd_help.nil?
                    display c2("Command invalid!")
                elsif cmd_help[:usage].nil?
                    display c4("Help for command #{cmd} is not available!")
                else
                    display c3("Usage: #{cmd_help[:command]} #{cmd_help[:params_format]}")
                    display c3("#{cmd_help[:help]}\n")
                    display c12(cmd_help[:usage])
                end
            end
        end

        # Print a message in the screen.
        #
        # @param object [Object] Any object that responds to #to_s.
        # @param continuos [Boolean] If false a new line character is appended at the end of message.
        # @return [String] The message printed.
        def display(object, continuos=false)
            text = object.to_s
            if continuos
                print text
            else
                puts text
            end
            text
        end

        # Persist the global configuration to the player's configuration file.
        def save_configuration
            File.open(config_file, 'w'){|f| YAML.dump(master_config, f)}
        end

        private

        # Execute a defalt action when the player fails.
        #
        # @param ex [Exception] The exception throwed
        def default_error_action(ex)
            if ex.respond_to?(:displayable)
                display c2(ex.message) if ex.displayable?
            else
                case ex.message
                when /(Connection refused|Network is unreachable)/ then display c2("The internet is not available!")
                else
                    display c2(ex.message)
                    puts ex.backtrace if ENV['environment'] == 'dev'
                end
            end

            return execute('next') unless ex.respond_to?(:take_action?)

            execute('next') if ex.take_action?
        end

        # Send the command parameters to appropiated registered listeners/commands.
        #
        # @param cmd [Hash] Contains the keys :command, :params. The latter is and array of hashes with the keys, dependending on the parameter type, :value, :type, :criteria.
        # @return [Boolean] True is there was any listeners that receive the message, false otherwise.
        def send_to_listeners(cmd, params, filter=:__ALL_VALIDS__)
            listeners = @listener_registry.values_at(cmd, filter).flatten
            unless listeners.nil?
                @current_command = {command: cmd, params: params}
                listeners.each{|listener|
                    listener.send(cmd, params)
                }
            end

            return !listeners.nil? && !listeners.empty?
        end

        # Generates the in-app help from a list of command's help.
        #
        # @param command_help [List<Hash>] The hashes contains the keys :help, :params_format. The former is the command's help line and the latter its accepted parameters.
        # @return [String] The help message generated.
        def generate_help
            bigest_cmd = Plugins.command_help.max{|a,b|
                "#{a[:command]} #{a[:params_format]}".length \
                    <=> \
                    "#{b[:command]} #{b[:params_format]}".length
            }
            offset = "#{bigest_cmd[:command]} #{bigest_cmd[:params_format]}".length
            bigger_offset = offset + 5

            @help_msg = "The following commands are loaded:\n"

            command_help.each{|map| 
                msg = "#{map[:command]} #{map[:params_format]}"
                @help_msg += "  #{msg.ljust(offset)} #{map[:help]}\n"
            }

            @help_msg += "\nThe following are the parameters types:\n"
            @help_msg += "  #{"number".ljust(offset)}A integer value. Normally limited by the focused object.\n"
            @help_msg += "  #{"literal".ljust(offset)}Any string of characters. If spaces are required, wrap the string with \" or '\n"
            @help_msg += "  #{"object".ljust(offset)}One of the playes's objects. The following are available:\n"
            @help_msg += "#{"".ljust(bigger_offset)}@playlist: The current playlist.\n"
            @help_msg += "#{"".ljust(bigger_offset)}@song: The current song playing.\n"
            @help_msg += "#{"".ljust(bigger_offset)}@artist: The artist from the current song playing.\n"
            @help_msg += "#{"".ljust(bigger_offset)}@album: The album from the current song playing.\n"
            @help_msg += "#{"".ljust(bigger_offset)}@history: The history playlist.\n"
            @help_msg += "#{"".ljust(bigger_offset)}@search: the playlist with the results of the lastest search.\n"
            @help_msg += "#{"".ljust(bigger_offset)}@library: The playlist of the complete library..\n"
            @help_msg += "  #{"criteria".ljust(offset)}A key-value pair in the format <key>:<literal>. Valid keys are:\n"
            @help_msg += "#{"".ljust(bigger_offset)}a: stand for Artist.\n"
            @help_msg += "#{"".ljust(bigger_offset)}b: stand for Album.\n"
            @help_msg += "#{"".ljust(bigger_offset)}t: stand for Title.\n"
            @help_msg += "  #{"path".ljust(offset)}A valid path inside local filesystem.\n"

            @help_msg
        end

        # When no command is found for a user input,
        # this method send the command to the underlying music player.
        def method_missing(method_name, *args)
            if method_name =~ /\Ac([\d]+)\Z/
                define_color_palette
                send(method_name, *args)
                # interrogando sobre el estatus del reproductor
            elsif method_name =~ /\A(.*?)\?\Z/
                self.class.class_eval do 
                define_method method_name do
                    @status.downcase == $1.to_sym
                end
                end

            send(method_name, *args)

            else
                # mandamos al player todo lo que no conozcamos
                @player.send(method_name)
            end
        end
    end
end
