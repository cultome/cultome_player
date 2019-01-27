module CultomePlayer::Core::Session
end

require "cultome_player/core/session/reader"
require "cultome_player/core/session/language"
require "cultome_player/core/session/processor"
require "cultome_player/core/session/playlists"
require "cultome_player/core/session/actions"

module CultomePlayer::Core::Session
  include Reader
  include Language
  include Processor
  include Playlists
  include Actions

  PROMPT = "cultome> "

  # Begin a REP loop inside player.
  def begin_session
    @in_session = true
    display c5("Cultome Player v#{CultomePlayer::VERSION}")
    emit(:interactive_session_started)

    while in_session?
      begin
        cmd = read_command(PROMPT)
        execute_interactively cmd
      rescue Exception => e
        show_error(e.message)
        e.backtrace.each{|b| display c3(b) } # if current_env == :test
      end
    end
  end

  # Terminates a interactive session.
  def terminate_session
    @in_session = false
    emit(:interactive_session_ended)
  end

  private

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

  def get_response_params(response)
    return {message: response} if response.instance_of?(String)
    return response
  end

  def set_last_command(cmd)
    @last_command = cmd
  end

  def execute_interactively(cmd)
    begin
      if cmd.empty?
        # tomamos en ultimo comando
        cmd = last_command

      else
        # agregamos el comando al historia de la session_history
        session_history << cmd
        # seteamos el ultimo comando ejecutado
        # # seteamos el ultimo comando ejecutado
        set_last_command(cmd)
      end

      return false if cmd.nil?

      r = execute cmd

      if r.size > 1
        display c1("#{r.size} commands were executed, Showing result of the last one.")
      end

      show_response(r.last)
    rescue Exception => e
      emit(:interactive_exception, e)
      raise e
    end
  end

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

        raise 'invalid command:action unknown' unless respond_to?(action)

        begin
          emit(:before_command, cmd: cmd)
          emit("before_command_#{action}".to_sym, cmd: cmd) if cmd.history?
          r = send(action, cmd)
          emit("after_command_#{action}".to_sym, cmd: cmd, response: r) if cmd.history?
          emit(:after_command, cmd: cmd, response: r)

          seq_success = false unless r.success?
          r # return response
        rescue Exception => e
          emit(:execute_exception, cmd: cmd, error: e)

          # if current_env == :test || current_env == :rspec
          display c3("#{e.message}")
          e.backtrace.each{|b| display c3(b) }
          # end

          seq_success = false
          s = e.message.split(":")
          failure(message: s[0], details: s[1])
        end
      else # seq_success == false
        nil
      end
    end
    return response_seq.compact # eliminamos los que no corrieron
  end
end
