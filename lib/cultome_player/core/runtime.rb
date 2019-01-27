require "json"

module CultomePlayer::Core::Runtime
  attr_reader :current_song

  def library(force_reload=false)
    @library = load_library if force_reload

    get_library
  end

  def session_history
    @session_history ||= []
  end

  def in_session?
    @in_session ||= false
  end

  #
  # Check the status of pause.
  #
  # @return [Boolean] True if paused, False otherwise
  def paused?
    @paused ||= false
  end

  # Check the status of stop.
  #
  # @return [Boolean] True if stopped, False otherwise
  def stopped?
    @stopped ||= true
  end

  # Check the status of play.
  #
  # @return [Boolean] True if playing, False otherwise
  def playing?
    @playing ||= false
  end

  # Check the status of shuffle.
  #
  # @return [Boolean] True if shuffling, False otherwise
  def shuffling?
    playlists[:current].shuffling?
  end

  # Returns the current song.
  #
  # @return [Song] The current song or nil if any.
  def current_song
    @current_song
  end

  # Returns the current artist.
  #
  # @return [Artist] The current artist or nil if any.
  def current_artist
    current_song.artist
  end

  # Returns the current album.
  #
  # @return [Album] The current album or nil if any.
  def current_album
    current_song.album
  end

  # Returns the current playlist.
  #
  # @return [Playlist] The current playlist or nil if any.
  def current_playlist
    playlists[:current]
  end

  # Returns the current playback position.
  #
  # @return [Integer] The current playback position in seconds.
  def playback_position
    @playback_time_position ||= 0
  end

  # Returns the current playback length.
  #
  # @return [Integer] The current playback length in seconds.
  def playback_length
    @playback_time_length ||= 0
  end

  private

  def get_library
    @library ||= load_library
  end

  def load_library
    JSON.load(File.read(db_file))
  rescue
    raise "Database is corrupted! Delete the file ~/.cultome_player/db.json and restart the player"
  end
end
