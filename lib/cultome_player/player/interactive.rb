module CultomePlayer::Player
  module Interactive

    PROMPT = "cultome> "

    # Begin a REP loop inside player.
    def begin_session
      @in_session = true
      display c5("Cultome Player v#{CultomePlayer::VERSION}")
      emit_event(:interactive_session_started)

      while in_session?
        begin
          cmd = read_command(PROMPT)
          execute_interactively cmd
        rescue Exception => e
          show_error(e.message)
          e.backtrace.each{|b| display c3(b) } if current_env == :test
        end
      end
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
        emit_event(:interactive_exception, e)
        raise e
      end
    end

    # Check if there is an interactive session in progress.
    #
    # @return [Boolean] True if session in progress. False otherwise.
    def in_session?
      @in_session ||= false
    end

    # Terminates a interactive session.
    def terminate_session
      @in_session = false
      save_player_configurations
      emit_event(:interactive_session_ended)
    end

    # Command history of this session
    #
    # @return [Array<Command>] The history of commands of this session.
    def session_history
      @session_history ||= []
    end

    def set_last_command(cmd)
      @last_command = cmd
    end

    def last_command
      @last_command
    end

    private

    def show_error(msg)
      type, message = msg.split(":")
      display c3("[#{type}] #{message}")
    end

    def show_response(r)
      return if r.respond_to?(:no_response)

      if r.respond_to?(:response_type)
        res_obj = r.send(r.response_type)
        if res_obj.respond_to?(:each)
          # es una lista
          display to_display_list(res_obj)

        elsif res_obj.class == String
          # es un mensaje
          display r.success? ? res_obj : c3(res_obj.to_s)

        else
          display c3("(((#{res_obj.to_s})))")

        end

        # Dont has response_type, eg has a message
      elsif r.respond_to?(:message)
        display r.success? ? c15(r.message) : c3(r.message)

      else
        display c3("!!! #{r} !!!")

      end
    end

  end
end
