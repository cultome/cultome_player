require 'cultome/plugins'
require 'cultome/user_input'
require 'cultome/installation_integrity'
require 'cultome/player_listener'
require 'cultome/exception'

# This class represents and holds the music player's state in one moment.
# This means that plugins can ask about, for example, current song, focused list or connected
# drives to make its work.
# Its work basicly is to load and call plugins (a.k.a registered commands), receive and parse user input 
# and call listeners/commands registered.
module Cultome
    module CultomePlayerCore

        def self.included(base)
            base.send :include, Plugins
            base.send :include, UserInput
            base.send :include, InstallationIntegrity
            base.send :include, CultomePlayerListener
        end

        # Utility method for running a standalone player. Initialize the commands
        # and loop to get user input until @running flag is set to false.
        # When a error is detected, a call to #execute with 'next' input is invoked.
        def start
            cultome.running = true

            while(cultome.running) do
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
                if cmds.blank?
                    cmds = cultome.last_cmds
                else
                    cultome.last_cmds = cmds
                end

                with_connection do
                    cmds.each do |cmd|
                        send_to_listeners(cmd[:command], cmd[:params])
                    end
                end
            rescue CultomePlayerException => ctmex
                send_to_listeners(:player_exception_throwed, ctmex, :__PLAYER_EXCEPTIONS__)
                default_error_action( ctmex )
            rescue Exception => ex
                default_error_action( ex ) unless send_to_listeners(:exception_throwed, ctmex, :__EXCEPTIONS__)
            end
        end

        # Persist the global configuration to the player's configuration file.
        def save_configuration
            File.open(config_file, 'w'){|f| YAML.dump(master_config, f)}
        end

        # Execute a defalt action when the player fails.
        #
        # @param ex [Exception] The exception throwed
        def default_error_action(ex)
            puts ex.backtrace if dev?

            if ex.respond_to?(:displayable)
                display c2(ex.message) if ex.displayable?
            else
                case ex.message
                when /(Connection refused|Network is unreachable)/ then display c2("The internet is not available!")
                else
                    display c2(ex.message)
                end
            end

            return execute('next') unless ex.respond_to?(:take_action?)

            execute('next') if ex.take_action?
        end

        private

        # Send the command parameters to appropiated registered listeners/commands.
        #
        # @param cmd [Hash] Contains the keys :command, :params. The latter is and array of hashes with the keys, dependending on the parameter type, :value, :type, :criteria.
        # @return [Boolean] True is there was any listeners that receive the message, false otherwise.
        def send_to_listeners(cmd, params, filter=:__ALL_VALIDS__)
            listeners = []
            is_valid = respond_to?(cmd)
            # si es un comando
            if is_valid
                send cmd, params
                self.current_command = {command: cmd, params: params}
                listeners << Plugins.listener_registry[:__ALL_VALIDS__]
            end


            listeners << Plugins.listener_registry[cmd]

            unless listeners.empty?
                listeners.flatten.each{|procedure|
                    procedure.call(self, params)
                }
            end

            return !listeners.empty? || respond_to?(cmd)
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
                    status.downcase == $1.to_sym
                end
                end

            send(method_name, *args)

            else
                # mandamos al player todo lo que no conozcamos
                player.send(method_name)
            end
        end
    end
end
