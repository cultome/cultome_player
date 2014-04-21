require "cultome_player/version"
require "cultome_player/environment"
require "cultome_player/objects"
require "cultome_player/command"
require "cultome_player/player"
require "cultome_player/media"
require "cultome_player/utils"
require "cultome_player/events"

module CultomePlayer
  include Environment
  include Utils
  include Objects
  include Command
  include Player
  include Media
  include Events

  # Posibbly valid inside a Interactive module
  def execute(user_input)
    cmd = parse user_input
    raise 'invalid command:action unknown' unless respond_to?(cmd.action)
    with_connection do
      send(cmd.action, cmd)
    end
  end

  def create_response(type, data)
    data[:response_type] = data.keys.first unless data.has_key?(:response_type)
    return Response.new(type, data)
  end

  def success(response)
    create_response(:success, response)
  end

  def failure(response)
    if response.instance_of?(String)
      create_response(:failure, message: response)
    else
      create_response(:failure, response)
    end
  end

  #Posibbly inside StateChecker module
  def paused?
    @paused ||= false
  end

  def stopped?
    @stopped ||= true
  end

  def playing?
    @playing ||= false
  end

  def current_song
    @current_song
  end

  def current_playlist
    playlists[:current]
  end

  def current_artist
    current_song.artist
  end

  def current_album
    current_song.album
  end

  def playback_position
    @playback_time_position ||= 0
  end

  def playback_length
    @playback_time_length ||= 0
  end

  def shuffling?
    playlists[:current].shuffling?
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
      end
    end

    def get_player(env=:user)
      DefaultPlayer.new(env)
    end
  end
end
