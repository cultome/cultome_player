
module Plugins
    module SimilarTo
        # Display a list with similar artist or album of the give song or artist and shows a list with them, separing the one within our library.
        #
        # @param params [List<Hash>] With parsed player's object information. Only @artist and @song are valid.
        def similar(params=[])
            raise CultomePlayerException.new(:invalid_parameter, params: params) if !params.empty? && params.find{|p| p[:type] == :object}.nil?
            raise CultomePlayerException.new(:no_active_playback, take_action: false) if cultome.song.nil?

            begin
                song_name = cultome.song.name
                artist_name = cultome.song.artist.name
                song_id = cultome.song.id
                artist_id = cultome.song.artist.id

                type = params.empty? ? :song : params.find{|p| p[:type] == :object}[:value]
                query_info = Plugins::LastFm.define_query(type, song_name, artist_name)

                in_db = Plugins::SimilarTo.check_in_db(query_info)

                if in_db.empty?
                    json = Plugins::LastFm.consult_lastfm(query_info)

                    if !json['similarartists'].nil?
                        # get the information form the reponse
                        artists = json['similarartists']['artist'].collect do |a|
                            {
                                artist: a['name'],
                                artist_url: a['url'],
                                similar_to: 'artist'
                            }
                        end

                        # salvamos los similares
                        artists.each do |a|
                            Artist.find(artist_id).similars.create(a)
                        end

                        artists_in_library = Plugins::SimilarTo.find_artists_in_library(artists)
                        Plugins::SimilarTo.show_artist(artist_name, artists, artists_in_library)

                        return artists, artists_in_library
                    elsif !json['similartracks'].nil?
                        # convierte los datos del request en un hash mas manejable
                        tracks = json['similartracks']['track'].collect do |t|
                            {
                                track: t['name'],
                                artist: t['artist']['name'],
                                track_url: t['url'],
                                artist_url: t['artist']['url'],
                                similar_to: 'track'
                            }
                        end
                        # salvamos los similares
                        tracks.each do |t|
                            Song.find(song_id).similars.create(t)
                        end
                        tracks_in_library = Plugins.SimilarTo.find_tracks_in_library(tracks)
                        Plugins.SimilarTo.show_tracks(song_name, tracks, tracks_in_library)

                        return tracks, tracks_in_library
                    else
                        # seguramente un error
                        display(c2("Problem! #{json['error']}: #{json['message']}"))
                    end
                else
                    # trabajamos con datos de la db
                    if query_info[:method] == LastFm::GET_SIMILAR_ARTISTS_METHOD
                        artists_in_library = Plugins.SimilarTo.find_artists_in_library(in_db)
                        Plugins.SimilarTo.show_artist(artist_name, in_db, artists_in_library)

                        return in_db, artists_in_library
                    elsif query_info[:method] == LastFm::GET_SIMILAR_TRACKS_METHOD
                        tracks_in_library = Plugins.SimilarTo.find_tracks_in_library(in_db)
                        Plugins.SimilarTo.show_tracks(song_name, in_db, tracks_in_library)

                        return in_db, tracks_in_library
                    end
                end
            ensure
                @thrd.kill if !@thrd.nil? && @thrd.stop?
                print "#{" " * LastFm::TEXT_WIDTH}\r"
            end
        end

        # Lazy initializator for the 'similar results limit' configuration
        #
        # @return [Integer] The registries displayed for similar artist/song results.
        def self.similar_results_limit
            Plugins::LastFm.config["similar_results_limit"] ||= 10
        end

        # Check if previously the similars has been inserted.
        #
        # @param (see #define_query)
        # @return [List<Similar>] A list with the result of the search for similars for this criterio.
        def self.check_in_db(query_info)
            if query_info[:method] == LastFm::GET_SIMILAR_ARTISTS_METHOD
                artist = Artist.includes(:similars).find_by_name(query_info[:artist])
                return artist.similars unless artist.nil?
                return []
            elsif query_info[:method] == LastFm::GET_SIMILAR_TRACKS_METHOD
                track = Song.includes(:similars).find_by_name(query_info[:track])
                return track.similars unless track.nil?
                return []
            end
        end

        # Generate the Last.fm sign for the request. Basibly the sign is concatenate all the parameters with their values in alphabetical order and generate a 32 charcters MD5 hash.
        #
        # @param query_info [Hash] The parameters sended in the request.
        # @return [String] The sign of this request.
        def self.generate_call_sign(query_info)
            params = query_info.sort.inject(""){|sum,map| sum += "#{map[0]}#{map[1]}" }
            sign = params + LastFm::LAST_FM_SECRET
            return Digest::MD5.hexdigest(sign)
        end

        # For the given artist list, find in the library if that artist exists, if exist, remove it from the parameter list.
        # @note This method change the artist parameter.
        #
        # @param artists [List<Hash>] Contains the transformed artist information.
        # @return [List<Artist>] The artist found in library.
        def self.find_artists_in_library(artists)
            in_library = []

            LastFm::LastFm.change_text('... ', {
                prefix: 'Fetching similar artist from library',
                width: 3,
                add_repeat_transition: false
            })

            artists.keep_if do |a|
                artist = Artist.find_by_name(a[:artist])
                if artist.nil? 
                    # dejamos los artistas que no esten en nuestra library
                    true
                else
                    in_library << artist
                    false
                end
            end

            return in_library
        end

        # For the given tracks list, find in the library if that track exists, if exist, remove it from the parameter list.
        # @note This method change the tracks parameter.
        #
        # @param tracks [List<Hash>] Contains the transformed track information.
        # @return [List<Song>] The songs found in library.
        def self.find_tracks_in_library(tracks)
            in_library = []

            LastFm::LastFm.change_text("...", {
                prefix: 'Fetching similar tracks from library',
                width: 3,
                add_repeat_transition: false
            })

            tracks.keep_if do |t|
                song = Song.joins(:artist).where('songs.name = ? and artists.name = ?', t[:track], t[:artist]).to_a
                if song.empty?
                    # aqui meter a similars
                    true
                else
                    in_library << song
                    false
                end
            end

            return in_library.flatten
        end

        # Display a list with similar tracks found and not found in library.
        #
        # @param song [Song] The song compared.
        # @param tracks [List<Hash>] The song transformed information.
        # @param tracks_in_library [List<Song>] The similari songs found in library.
        def self.show_tracks(song, tracks, tracks_in_library)
            display c4("Similar tracks to #{song}") unless tracks.empty?
            tracks.each{|a| display c4("  #{a[:track]} / #{a[:artist]}") } unless tracks.empty?

            display c4("Similar tracks to #{song} in library") unless tracks_in_library.empty?
            display c4(tracks_in_library) unless tracks_in_library.empty?
            #tracks_in_library.each{|a| display("  #{a.name} / #{a.artist.name}") } unless tracks_in_library.empty?

            if tracks.empty? && tracks_in_library.empty?
                display c2("No similarities found for #{song}") 
            else
                cultome.focus = tracks_in_library
            end
        end

        # Display a list with similar artist found and not found in library.
        #
        # @param artist [Artist] The artist compared.
        # @param artists [List<Hash>] The artist transformed information.
        # @param artists_in_library [List<Artist>] The similari artist found in library.
        def self.show_artist(artist, artists, artists_in_library)
            display c4("Similar artists to #{artist}") unless artists.empty?
            artists.each{|a| display c4("  #{a[:artist]}") } unless artists.empty?

            display c4("Similar artists to #{artist} in library") unless artists_in_library.empty?
            artists_in_library.each{|a| display("  #{a.name}") } unless artists_in_library.empty?

            display c2("No similarities found for #{artist}") if artists.empty? && artists_in_library.empty?
        end
    end
end
