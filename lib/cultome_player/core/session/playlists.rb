
module CultomePlayer::Core::Session::Playlists
  def playlists(*names)
    @playlists ||= CultomePlayer::Core::Objects::Playlists.new
    @playlists.register(*names)
    @playlists.get(*names)
  end
end
