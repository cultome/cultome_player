
module CultomePlayer::Extras::LastFm
    module Scrobbler
        def self.included(base)
            CultomePlayer::Player.register_event_listener(:next, :scrobble)
            CultomePlayer::Player.register_event_listener(:prev, :scrobble)
            CultomePlayer::Player.register_event_listener(:quit, :scrobble)
        end

        def scrobble(command)
            p = player.prev_song
            return nil if p.nil?

            song_name = p.name
            artist_name = p.artist.name
            artist_id = p.artist.id
            progress = player.song_status[:seconds] || 0
            # necesitamos que la cancion haya sido tocada almenos 30 segundos
            return nil if progress < 30
            song_name = player.song.name

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

        private

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
