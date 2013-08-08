# encoding: utf-8
module CultomePlayer::Player
  module PlayerExposer

    # Register the command show.
    #
    # @param base [Class] The Class where this module is included.
    def self.included(base)
      base.command_registry << :show

      base.command_help_registry[:show] = {
        help: "Display information about status, objects and library.", 
        params_format: "[<object>]",
        usage: <<-HELP
If a parameter is provided the object is shown in the screen, for example
    * show @playlist
    Display the current playlist in screen.
    * show @history
    Display the playback history of the current session.

The following are a list of valid player objects:
    * playlist
    * search
    * history
    * artist
    * album
    * drives
    * queue
    * focus

Also exist pseudo-objects in the scope of show command to facilitate the exploration of library. The list is the next:
    * library        : The complete list of songs in the library
    * artists        : The list of artists in the library
    * albums         : The list of albums in the library
    * genres         : The list of genres in the library
    * recently_added : The list of song that were recently added to the library.
    * genre          : The songs with the same genres as the current playing

These objects can be used as any other object in the scope of this command, for example:
    * show @artists
    Display a list of artists from the library.

When an object is passed but not finded among the player objects nor the pseudo-object, the show command look for drives named like that, for example:
    * show @my_drive
    Display the list of song in the drive named 'my_drive'.

        HELP
      }
    end

    # Return an string with and object representations. If no parameter is provided, shows the progress of the current song.
    #
    # @param params [List<Hash>] With parsed player's object information.
    # @return [String] The message displayed.
    def show(params=[])
      raise 'no active playback' if current_song.nil?

      return "#{current_song}\n#{playback_progress}" if params.blank?

      params.each do |param|
        case param[:type]
        when :object
          case param[:value]
          when :library then player.focus = obj = find_by_query
          when :artists then player.focus = obj = CultomePlayer::Model::Artist.order(:name).all
          when :albums then player.focus = obj = CultomePlayer::Model::Album.order(:name).all
          when :genres then player.focus = obj = CultomePlayer::Model::Genre.order(:name).all
          when /playlist|search_results|history/ then player.focus = obj = player.instance_variable_get("@#{param[:value]}")
          when /search/ then player.focus = obj = player.search_results
          when /song|artist|album|queue|focus/ then obj = player.instance_variable_get("@#{param[:value]}")
          when /drives/ then obj = CultomePlayer::Model::Drive.all.to_a
          when :recently_added then player.focus = obj = CultomePlayer::Model::Song.where('created_at > ?', CultomePlayer::Model::Song.maximum('created_at') - (60*60*24) )
          when :genre then player.focus = obj = CultomePlayer::Model::Song.connected.joins(:genres).where('genres.name in (?)', current_song.genres.collect{|g| g.name }).to_a
          else
            # intentamos matchear las unidades primero
            drive = drives_registered.find{|d| d.name.to_sym == param[:value]}
            unless drive.nil?
              player.focus = obj = CultomePlayer::Model::Song.where('drive_id = ?', drive.id).to_a unless drive.nil?
            end
          end
        else
          obj = current_song 
        end # case
        #display(obj)
        return obj
      end # do
    end

    private

    # Show an ASCII bar with the time progress of the current song.
    #
    # @return [String] An ASCII bar with the time progress of the current song.
    def playback_progress
      actual = player.song_status[:seconds]
      percentage = ((actual * 100) / current_song.duration) / 10
      return c4("#{actual.to_time} <#{"=" * (percentage*2)}#{"-" * ((10-percentage)*2)}> #{current_song.duration.to_time}")
    end
  end
end

module CultomePlayer::Player::PlayerExposer

  # State checker of playing status.
  #
  # @return [Boolean] true if player is playing, false otherwise.
  def playing?
    player.state =~ /\ARESUMED|PLAYING\Z/ ? true : false
  end

  # State checker of library playing.
  #
  # @return [Boolean] true if the player is playing the library, false otherwise.
  def playing_library?
    player.playing_library?
  end

  # State checker of shuffle.
  #
  # @return [Boolean] true if the player is shuffling, false otherwise.
  def shuffling?
    player.shuffling
  end

  # State checker of pause.
  #
  # @return [Boolean] true if the player is paused, false otherwise.
  def paused?
    player.state =~ /\APAUSED\Z/ ? true : false
  end

  # Accessor for registered drives.
  #
  # @return [Array<CultomePlayer::Model::Drive>] With the drives registered in the player.
  def drives_registered 
    player.drives
  end

  # Accessor for the current playlist.
  #
  # @return [Array<CultomePlayer::Model::Song>] The current playlist.
  def current_playlist
    player.playlist
  end

  # Accesor for the current song
  #
  # @return [CultomePlayer::Model::Song] The current song.
  def current_song
    player.song
  end
end
