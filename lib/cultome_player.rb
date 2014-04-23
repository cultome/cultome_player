require "cultome_player/version"
require "cultome_player/environment"
require "cultome_player/objects"
require "cultome_player/command"
require "cultome_player/player"
require "cultome_player/media"
require "cultome_player/utils"
require "cultome_player/events"
require "cultome_player/plugins"

module CultomePlayer
  include Environment
  include Utils
  include Objects
  include Command
  include Player
  include Media
  include Events
  include Plugins

  def execute(user_input)
    cmd = parse user_input
    # revisamos si es un built in command o un plugin
    action = cmd.action
    plugin_action = "command_#{cmd.action}".to_sym
    action = plugin_action if respond_to?(plugin_action)

    raise 'invalid command:action unknown' unless respond_to?(action)
    with_connection do
      send(action, cmd)
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

  def help_cultome_player
    cmds_availables = methods.grep(/^description_/).collect do |method_name|
      [method_name.to_s.gsub("description_", ""), send(method_name)]
    end

    border_width = 5
    cmd_column_width = cmds_availables.reduce(0){|sum, arr| sum > arr[0].length ? sum : arr[0].length}
    desc_column_width = 90 - border_width - cmd_column_width

    cmds_availables_formatted = cmds_availables.collect do |arr|
      "   " + arrange_in_columns(arr, [cmd_column_width, desc_column_width], border_width)
    end

    return <<-HELP
usage: <command> [param param ...]

The following commands are availables:
#{cmds_availables_formatted.join("\n")}

The params can be of any of these types:
   criterio     A key:value pair. Only a,b,t are recognized.
   literal      Any valid string. If contains spaces quotes or double quotes are required.
   object       Identifiers preceded with an @.
   number       An integer number.
   path         A string representing a path in filesystem.
   boolean      Can be true, false. Accept some others.
   ip           An IP4 address.

See 'help <command>' for more information on a especific command.

Refer to the README file for a complete user guide.
    HELP
  end
end
