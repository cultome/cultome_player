module CultomePlayer::Player
  module Interactive
    def begin_session
      @in_session = true

      while in_session?
        execute read_command("cultome> ")
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
