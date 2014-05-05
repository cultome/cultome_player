require "cultome_player/version"
require "cultome_player/environment"
require "cultome_player/objects"
require "cultome_player/command"
require "cultome_player/player"
require "cultome_player/media"
require "cultome_player/utils"
require "cultome_player/events"
require "cultome_player/plugins"
require "cultome_player/state_checker"

module CultomePlayer
  include Environment
  include Utils
  include Objects
  include Command
  include Player
  include Media
  include Events
  include Plugins
  include StateChecker

  # Interpret a user input string as it would be typed in the console.
  #
  # @param user_input [String] The user input.
  # @return [Response] Response object with information about command execution.
  def execute(user_input)
    cmds = parse user_input

    seq_success = true # bandera de exito, si un comando de la cadena falla, los siguientes se abortan
    response_seq = cmds.collect do |cmd|
      if seq_success
        # revisamos si es un built in command o un plugin
        action = cmd.action
        plugin_action = "command_#{cmd.action}".to_sym
        action = plugin_action if plugins_respond_to?(cmd.action)

        raise 'invalid command:action unknown' unless respond_to?(action)
        with_connection do
          begin
            emit_event("before_command_#{action}".to_sym, cmd)
            r = send(action, cmd)
            emit_event("after_command_#{action}".to_sym, cmd, r)
            seq_success = false unless r.success?
            r # return response
          rescue Exception => e
            emit_event(:execute_exception, cmd, e)
            
            display c3("#{e.message}\n#{e.backtrace}\n") if current_env == :dev
            seq_success = false
            s = e.message.split(":")
            failure(message: s[0], details: s[1])
          end
        end
      else # seq_success == false
        nil
      end
    end
    return response_seq.compact # eliminamos los que no corrieron
  end

  # Creates a generic response
  #
  # @param type [Symbol] The response type.
  # @param data [Hash] The information that the response will contain.
  # @return [Response] Response object with information in form of getter methods.
  def create_response(type, data)
    data[:response_type] = data.keys.first unless data.has_key?(:response_type)
    return Response.new(type, data)
  end

  # Creates a success response. Handy method for #create_response
  #
  # @param response [Hash] The information that the response will contain.
  # @return [Response] Response object with information in form of getter methods.
  def success(response)
    create_response(:success, get_response_params(response))
  end

  # Creates a failure response. Handy method for #create_response
  #
  # @param response [Hash] The information that the response will contain.
  # @return [Response] Response object with information in form of getter methods.
  def failure(response)
    create_response(:failure, get_response_params(response))
  end

  class << self
    class DefaultPlayer
      include CultomePlayer

      def initialize(env)
        prepare_environment(env)
        playlists.register(:current)
        playlists.register(:history)
        playlists.register(:queue)
        playlists.register(:focus)
        playlists.register(:search)
        
        register_listener(:playback_finish) do |song|
          r = execute("next").first
          display_over("#{r.message}\n#{c5(PROMPT)}")
        end
        
        init_plugins
      end
    end

    # Get an instance of DefaultPlayer
    #
    # @param env [Symbol] The environment from which the configirations will be taken.
    # @return [DefaultPlayer] A Cultome player ready to rock.
    def get_player(env=:user)
      DefaultPlayer.new(env)
    end
  end

  private

  def get_response_params(response) 
    return {message: c1(response)} if response.instance_of?(String)
    return response
  end
end
