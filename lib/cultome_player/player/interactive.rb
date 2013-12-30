module CultomePlayer::Player
  module Interactive
    def begin_session
      @in_session = true
      display "Cultome Player v#{CultomePlayer::VERSION}"

      while in_session?
        begin
          r = execute read_command("cultome> ")
          display r.message
        rescue Exception => e
          display e.message
        end
      end
    end

    def in_session?
      @in_session ||= false
    end

    def terminate_session
      @in_session = false
    end
  end
end
