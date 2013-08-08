# encoding: utf-8
module CultomePlayer::Extras::LastFm
  module Scrobbler

    # Register event listener for next, prev and quit commands.
    def self.included(base)
      CultomePlayer::Player.register_event_listener(:next, :scrobble_next)
      CultomePlayer::Player.register_event_listener(:prev, :scrobble_prev)
      CultomePlayer::Player.register_event_listener(:quit, :scrobble_quit)
    end

    # Submit a scrobble to Last.fm given the conditions of the player and the command provided as parameter.
    #
    # @param command [Symbol] The command that fire this scrobble. The posibble values are :next, :prev and :quit.
    def scrobble(command)
      p = song_to_scrobble_when(command)
      return nil if p.nil?

      song_name = p.name
      artist_name = p.artist.name
      artist_id = p.artist.id
      progress = player.song_status[:seconds] || 0
      # necesitamos que la cancion haya sido tocada almenos 30 segundos
      return nil if progress < 30

      # no hacemos scrobble si el artista o el track son desconocidos
      raise 'unable_to_scrobble' if artist_id == 1
      return nil if extras_config['session_key'].nil?

      query_info = define_lastfm_query(:scrobble, song_name, artist_name)

      begin
        request_to_lastfm(query_info, true, :post)

        check_pending_scrobbles
      rescue Exception => e
        # guardamos los scrobbles para subirlos cuando haya conectividad
        CultomePlayer::Model::Scrobble.create(artist: artist_name, track: song_name, timestamp: query_info[:timestamp])
        e.displayable = false if e.respond_to?(:displayable=)
        raise e
      end
    end

    # Given a command valid for scrobbler, select the song that will me scrobbled with the current state of the player.
    #
    # @param command [Symbol] A valid command for scrobbler (:next, :prev or :quit).
    # @return [CultomePlayer::Model::Song] The song that will be scrobbled with the actual state of the player.
    def song_to_scrobble_when(command)
      case command
      when /next|prev/
        player.prev_song
      when :quit
        current_song
      end
    end

    private

    # Utility method to send the correct parameter (next) to scrobble
    #
    # @param params [Array] The parameters supplied with the command.
    def scrobble_next(params)
      scrobble(:next)
    end

    # Utility method to send the correct parameter (prev) to scrobble
    #
    # @param params [Array] The parameters supplied with the command.
    def scrobble_prev(params)
      scrobble(:prev)
    end

    # Utility method to send the correct parameter (quit) to scrobble
    #
    # @param params [Array] The parameters supplied with the command.
    def scrobble_quit(params)
      scrobble(:quit)
    end

    # Review the database for pending scrobbles to send to Last.fm and send them.
    def check_pending_scrobbles
      pending = CultomePlayer::Model::Scrobble.pending
      if pending.size > 0
        query = define_lastfm_query(:multiple_scrobble, nil, nil, pending)

        request_to_lastfm(query, true, :post)

        # eliminamos los scrobbles
        pending.each{|s| s.delete }

        # checamos si hay mas por enviar
        return check_pending_scrobbles
      end
    end
  end
end
