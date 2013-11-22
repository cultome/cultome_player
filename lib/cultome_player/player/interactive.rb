module CultomePlayer::Player
  module Interactive
    def begin_session
      execute read_command("cultome> ")
    end
  end
end
