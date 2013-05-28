
module Plugins
    module Scrobbler

        def self.included(base)
puts "++++++++++ Including Scrobbler in #{base}"
            base.extend ClassMethods
        end

        module ClassMethods
            def scrobble(cultome, params=[])
puts "----------- SCROBBLE"
                p = cultome.prev_song
                return nil if p.nil?

                song_name = p.name
                artist_name = p.artist.name
                artist_id = p.artist.id
                if cultome.song_status["mp3.position.microseconds"]
                    progress = cultome.song_status["mp3.position.microseconds"] / 1000000
                else
                    progress = 0
                end

                # necesitamos que la cancion haya sido tocada almenos 30 segundos
                return nil if progress < 30
                song_name = cultome.song.name

                # no hacemos scrobble si el artista o el track son desconocidos
                raise CultomePlayerException.new(:unable_to_scrobble) if artist_id == 1

                return nil if Plugins::LastFm.config['session_key'].nil?

                query_info = Plugins::LastFm.define_query(:scrobble, song_name, artist_name)

                begin
                    Plugins.LastFm.consult_lastfm(query_info, true, :post)

                    Plugins::Scrobbler.check_pending_scrobbles
                rescue Exception => e
                    # guardamos los scrobbles para subirlos cuando haya conectividad
                    Scrobble.create(artist: artist_name, track: song_name, timestamp: query_info[:timestamp])
                    e.displayable = false if e.respond_to?(:displayable=)
                    raise e
                end
            end
        end

        def self.check_pending_scrobbles
            pending = Scrobble.pending
            if pending.size > 0
                query = Plugins::LastFm.define_query(:multiple_scrobble, nil, nil, pending)

                Plugins.LastFm.consult_lastfm(query, true, :post)

                # eliminamos los scrobbles
                pending.each{|s| s.delete }

                # checamos si hay mas por enviar
                return check_pending_scrobbles
            end
        end
    end
end
