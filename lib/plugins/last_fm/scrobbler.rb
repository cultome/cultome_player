
module Plugins
    module Scrobbler

        def self.included(base)
            base.extend ClassMethods
        end

        module ClassMethods
            def scrobble(cultome, params=[])
                p = cultome.prev_song
                return nil if p.nil?

                song_name = p.name
                artist_name = p.artist.name
                artist_id = p.artist.id
                progress = cultome.song_status[:seconds] || 0

                # necesitamos que la cancion haya sido tocada almenos 30 segundos
                return nil if progress < 30
                song_name = cultome.song.name

                # no hacemos scrobble si el artista o el track son desconocidos
                raise Cultome::CultomePlayerException.new(:unable_to_scrobble) if artist_id == 1
                return nil if LastFm.config['session_key'].nil?

                query_info = LastFm.define_query(:scrobble, song_name, artist_name)

                begin
                    LastFm.consult_lastfm(query_info, true, :post)

                    Scrobbler.check_pending_scrobbles
                rescue Exception => e
                    # guardamos los scrobbles para subirlos cuando haya conectividad
                    Cultome::Scrobble.create(artist: artist_name, track: song_name, timestamp: query_info[:timestamp])
                    e.displayable = false if e.respond_to?(:displayable=)
                    raise e
                end
            end
        end

        def self.check_pending_scrobbles
            pending = Cultome::Scrobble.pending
            if pending.size > 0
                query = LastFm.define_query(:multiple_scrobble, nil, nil, pending)

                LastFm.consult_lastfm(query, true, :post)

                # eliminamos los scrobbles
                pending.each{|s| s.delete }

                # checamos si hay mas por enviar
                return check_pending_scrobbles
            end
        end
    end
end
