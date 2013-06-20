#require 'cultome/persistence'
#require 'cultome/exception'
#require 'plugins/last_fm/similar_to'
#require 'plugins/last_fm/scrobbler'
require 'net/http'
#require 'json'
#require 'cgi'
#require 'digest'
require 'cultome_player/extras/last_fm/similar_to'
require 'cultome_player/extras/last_fm/scrobbler'

module CultomePlayer::Extras
    module LastFm

        include SimilarTo
        include Scrobbler

        # Last.fm webservice endpoint
        LAST_FM_WS_ENDPOINT = 'http://ws.audioscrobbler.com/2.0/'

        # CulToMe Player's Last.fm API key
        LAST_FM_API_KEY = 'bfc44b35e39dc6e8df68594a55a442c5'

        # CulToMe Player's Last.fm secret
        LAST_FM_SECRET = '2ff2254532bbae15b2fd7cfefa5ba018'

        # Get similar tracks's webservice method name
        GET_SIMILAR_TRACKS_METHOD = 'track.getSimilar'

        # Get similar artist's webservice method name
        GET_SIMILAR_ARTISTS_METHOD = 'artist.getSimilar'

        # Submit scrobble's webservice method name
        SCROBBLE_METHOD = 'track.scrobble'

        # Get token's webservice method name
        GET_TOKEN_METHOD = 'auth.getToken'

        # Get session's webservice method name
        GET_SESSION_METHOD = 'auth.getSession'

        # Register the configure_lastfm command.
        def self.included(base)
            CultomePlayer::Player.command_registry << :configure_lastfm
            CultomePlayer::Player.command_help_registry[:configure_lastfm] = {
                help: "Configure you Last.fm account to be able to scrobble.",
                params_format: "<literal>",
                usage: <<-HELP
Execute a little wizard to help you configure the scrobbler with your Last.fm account.

To begin the wizard just type
    * configure_lastfm begin

To make successfuly configure the scrobbler you require an active internet connection because we require you login into your account via a web browser and give authorization to this application to scrobble to your account. When you had have the authorization, and to finish this configuration and start scrobbling type the next command:
    * configure_lastfm done

This process is required only once, we promess you.
                HELP
            }
        end

        # Configure the user cultome player client for scrobble.
        #
        # @param params [Array<Hash>] It receive one literal parameter and the only two valid values for this is 'begin' and 'done'.
        def configure_lastfm(params=[])
            return nil if params.empty?
            return nil unless params.size == 1 && params[0][:type] == :literal

            if params[0][:value] == 'begin'
                display c5(<<-INFO 
Hello! we're gonna setup the Last.fm scrobbler so this player can notify Last.fm the music you are hearing. So this is what we'll do:
    1) The default browser will be opened and you'll be required to login into your Last.fm account (you require  an internet connection).
    2) You'll be asked to give authorization to this player to scrobble in your account.
    3) When you give the authorization, come back here and type:

        configure_lastfm done

Thats it! Not so hard right? So, lets begin! When you are ready press <enter> ...
                           INFO
                  )
                  # wait for user to be ready
                  gets

                  auth_info = define_lastfm_query(:token)
                  json = request_to_lastfm(auth_info, true)

                  raise 'Houston! we had a problem extracting Last.fm information' if json.nil?

                  return display(c2("Problem! #{json['error']}: #{json['message']}")) if json['token'].nil?

                  # guardamos el token para el segundo paso
                  extras_config['token'] = json['token']

                  auth_url = "http://www.last.fm/api/auth?api_key=#{LAST_FM_API_KEY}&token=#{extras_config['token']}"

                  if os == :windows
                      system("start \"\" \"#{auth_url}\"")
                  elsif os == :linux
                      system("gnome-open \"#{auth_url}\" \"\"")
                  else
                      display c4("Please write the next URL in your browser:\n#{auth_url}")
                  end

            elsif params[0][:value] == 'done'
                display c4("Thanks! Now we are validating the authorization and if it all right then we're done!. Wait a minute please...")
                auth_info = define_lastfm_query(:session)
                json = request_to_lastfm(auth_info, true)

                return display(c2("Problem! #{json['error']}: #{json['message']}")) if json['session'].nil?

                extras_config['session_key'] = json['session']['key']

                display c4("Ok! everything is set and the scrobbler is working now! Enjoy!")
            end
        end

        private

        # Lazy initializator for the 'similar results limit' configuration
        #
        # @return [Integer] The registries displayed for similar artist/song results.
        def similar_results_limit
            extras_config["similar_results_limit"] ||= 10
        end

        # Generate the Last.fm sign for the request. Basibly the sign is concatenate all the parameters with their values in alphabetical order and generate a 32 charcters MD5 hash.
        #
        # @param query_info [Hash] The parameters sended in the request.
        # @return [String] The sign of this request.
        def generate_lastfm_request_sign(query_info)
            params = query_info.sort.inject(""){|sum,map| sum += "#{map[0]}#{map[1]}" }
            sign = params + LastFm::LAST_FM_SECRET
            return Digest::MD5.hexdigest(sign)
        end

        # Make a request to the last.fm webservice, and parse the response with JSON.
        #
        # @param (see #define_lastfm_query)
        # @return [Hash] Filled with the webservice response information.
        def request_to_lastfm(query_info, signed=false, method=:get)
            query_info[:api_key] = LastFm::LAST_FM_API_KEY

            if signed
                query_info[:sk] = extras_config['session_key'] unless extras_config['session_key'].nil?
                query_info[:api_sig] = generate_lastfm_request_sign(query_info)
            end

            # siempre pedims la representacion en JSON, pero este parametro no se firma con el resto
            query_info[:format] = 'json'

            query_string = convert_to_query_string(query_info)

            begin
                if method == :get
                    url = "#{LastFm::LAST_FM_WS_ENDPOINT}?#{query_string}"
                        json_string = get_http_client.get_response(URI(url)).body
                elsif method == :post
                    url = LastFm::LAST_FM_WS_ENDPOINT
                    json_string = get_http_client.post_form(URI(url), query_info).body
                end
                return JSON.parse(json_string)
            rescue Exception => e
                raise Cultome::CultomePlayerException.new(:internet_not_available, error_message: e.message, take_action: false) if e.message =~ /(Connection refused|Network is unreachable|name or service not known)/
            end
        end

        # Given the command information, creates a search criteria.
        #
        # @param type [Symbol] The type of query to be executed
        # @param song [Song] The song to find similars, depending on the params.
        # @param artist [Artist] The artist to find similars, depending on the params.
        # @return [Hash] With keys :method, :artist and :track, depending on the parameters.
        def define_lastfm_query(type, song=nil, artist=nil, scrobbles=nil)
            case type
            when :artist
                display("Looking for artists similar to #{artist}...")

                query = {
                    method: LastFm::GET_SIMILAR_ARTISTS_METHOD,
                    artist: artist,
                    limit: similar_results_limit,
                }

            when :song
                display("Looking for tracks similar to #{song} / #{artist}...")

                query = {
                    method: LastFm::GET_SIMILAR_TRACKS_METHOD,
                    artist: artist,
                    track: song,
                    limit: similar_results_limit,
                }

            when :scrobble
                query = {
                    method: LastFm::SCROBBLE_METHOD,
                    artist: artist,
                    track: song,
                    timestamp: current_timestamp,
                }

            when :multiple_scrobble
                query = {
                    method: LastFm::SCROBBLE_METHOD,
                }
                scrobbles.each_with_index do |s, idx|
                    query["artist[#{idx}]".to_sym] = s.artist
                    query["track[#{idx}]".to_sym] = s.track
                    query["timestamp[#{idx}]".to_sym] = current_timestamp
                end

            when :token
                query = {
                    method: LastFm::GET_TOKEN_METHOD,
                }

            when :session
                query = {
                    method: LastFm::GET_SESSION_METHOD,
                    token: extras_config['token'],
                }
            else
                display c2("You can only retrive similar @song or @artist.")
            end

            return query
        end

        # Time variable only relevant for testing. Returns an integer timestamps.
        #
        # @return [Integer] If fixes always return that date. Returns Time.now otherwise.
        def current_timestamp
            @test_time || Time.now.to_i
        end

        # Create a safe query string to use with the request to the webservice.
        #
        # @param (see #define_lastfm_query)
        # @return [String] A safe query string.
        def convert_to_query_string(search_info)
            return search_info.sort.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1].to_s)}&" }
        end

    end
end
