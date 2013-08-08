# encoding: utf-8
require 'cultome_player/player/basic_controls'
require 'cultome_player/player/player_exposer'
require 'cultome_player/player/player_state_holder'

module CultomePlayer
  module Player

    # Return a class that holds the current state of the player at all times.
    #
    # @return [PlayerStateHolder] an instance of PlayerStateHolder
    def player
      @player ||= PlayerStateHolder.new
    end

    # Register an event listener.
    #
    # @param event [Symbol] The event name to listen to.
    # @param callback_method [Symbol] The name of the callback method to be called when event is emited.
    def self.register_event_listener(event, callback_method)
      event_listeners[event] << callback_method
    end

    # Register an event listener.
    #
    # @param event [Symbol] The event name to listen to.
    # @param block The logic to be executed when the event is emited. This event is a closure so is evaluated in its own context.
    def register_event_listener(event, &block)
      event_listeners[event] << block
    end

    # Interpret a user command.
    #
    # @param user_input [String] The user command to be interpreted.
    def execute(user_input)
      begin
        cmds = parse(user_input)
        return_values = []

        emit_event(:command_valid, cmds)

        cmds.each do |cmd|
          player.current_command = cmd

          return_values << send(cmd[:command], cmd[:params])
          emit_event(cmd[:command], cmd[:params]) # el comando ejecutado
        end

        # cal the listeners
        emit_event(:command_executed, cmds)

        # regresamos los valores que tiraron los comandos
        return *return_values
      rescue RuntimeError => e
        return emit_event(:invalid_command_error, user_input) if e.message == 'invalid command'

        raise e
      end
    end

    # Accessor for the event_listeners registry.
    #
    # @return [Hash] The event_listeners registry. The keys are the events and the values are their listeners.
    def self.event_listeners
      @event_listeners ||= Hash.new{|h,k| h[k] = []}
    end

    # Accessor for the event_listeners registry.
    #
    # @return [Hash] The event_listeners registry. The keys are the events and the values are their listeners.
    def event_listeners
      Player.event_listeners
    end

    # Accessor for the command registry.
    #
    # @return [Array] the command that this player responds to.
    def self.command_registry
      @command_registry ||= [:help]
    end

    # Accessor for the command help registry.
    #
    # @return [Hash] The keys are the command and the value are a hash with the help content.
    def self.command_help_registry
      @command_help_registry ||= { help: {
        help: "Show the application help",
        params_format: "<literal>",
        usage: <<-HELP
Without parameters shows the general help.
    * help

But you can also pass a command name to receive help specific and extended to that command, let say we want to know how to use the 'play' command, you can do this:
    * help play

        HELP
      }}
    end

    # Command to show the generated in-app help message.
    #
    # @param params [Array<Hash>] If a command name is passed as literal, shows the command help. Otherwise shows the general help.
    def help(params=[])
      if params.empty?
        return c4(help_message)
      else
        help = ""
        cmd = params[0][:value].downcase.to_sym
        cmd_help = Player.command_help_registry[cmd]
        if cmd_help.nil?
          help << c2("Command invalid!")
        elsif cmd_help[:usage].nil?
          help << c4("Help for command #{cmd} is not available!")
        else
          help << c3("Usage: #{cmd} #{cmd_help[:params_format]}")
          help << c3("#{cmd_help[:help]}\n")
          help << c12(cmd_help[:usage])
        end

        return help
      end
    end

    # Catwalk command to choose where to execute the play command depending on the actual conditions.
    #
    # @param path [String] The path to the music file to be played.
    def play_in_music_player(path)
      external_player_connected? ? play_in_external_player(path) : play_in_local_player(path)
    end

    # Catwalk command to choose where to execute the seek command depending on the actual conditions.
    #
    # @param next_pos [Integer] The position where to jump in the current playback.
    def seek_in_music_player(next_pos)
      external_player_connected? ? seek_in_external_player(next_pos) : seek_in_local_player(next_pos)
    end

    # Catwalk command to choose where to execute the pause command depending on the actual conditions.
    def pause_in_music_player
      external_player_connected? ? pause_in_external_player : pause_in_local_player
    end

    # Catwalk command to choose where to execute the resume command depending on the actual conditions.
    def resume_in_music_player
      external_player_connected? ? resume_in_external_player : resume_in_local_player
    end

    # Catwalk command to choose where to execute the stop command depending on the actual conditions.
    def stop_in_music_player
      external_player_connected? ? stop_in_external_player : stop_in_local_player
    end

    # Get the generated in-app help.
    #
    # @return [String] The help generated
    def help_message
      @help_msg ||= regenerate_help
    end

    # Broadcast an event to the registered listeners.
    #
    # @param event [Symbol] The event name
    # @param params [Array] The parameters to send to the listeners of the event.
    def emit_event(event, *params)
      ret_values = []
      event_listeners[event].each do |listener|
        if listener.class == Proc
          ret_values << listener.call(*params)
        else
          ret_values << send(listener, *params)
        end
      end

      return ret_values.compact
    end

    private

    # Generates the in-app help from a list of command's help.
    #
    # @param command_help [List<Hash>] The hashes contains the keys :help, :params_format. The former is the command's help line and the latter its accepted parameters.
    # @return [String] The help message generated.
    def regenerate_help
      biggest_cmd = Player.command_help_registry.values.max{|a,b|
        "#{a[:command]} #{a[:params_format]}".length \
          <=> \
          "#{b[:command]} #{b[:params_format]}".length
      }
      offset = "#{biggest_cmd[:command]} #{biggest_cmd[:params_format]}".length
      bigger_offset = offset + 5

      @help_msg = "The following commands are loaded:\n"

      Player.command_help_registry.sort.each{|k,map| 
        msg = "#{k} #{map[:params_format]}"
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
  end
end

# La reabrimos para insertar sus dependencias
module CultomePlayer::Player
  include BasicControls
  include PlayerExposer
end
