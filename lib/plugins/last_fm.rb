require 'cultome/persistence'
require 'cultome/exception'
require 'plugins/last_fm/similar_to'
require 'plugins/last_fm/scrobbler'
require 'net/http'
require 'json'
require 'cgi'
require 'text_slider'
require 'digest'

# Plugin to use information from the Last.fm webservices.
module Plugins
    module LastFm
        extend TextSlider
        include SimilarTo
        include Scrobbler

        LAST_FM_WS_ENDPOINT = 'http://ws.audioscrobbler.com/2.0/'
        LAST_FM_API_KEY = 'bfc44b35e39dc6e8df68594a55a442c5'
        LAST_FM_SECRET = '2ff2254532bbae15b2fd7cfefa5ba018'
        GET_SIMILAR_TRACKS_METHOD = 'track.getSimilar'
        GET_SIMILAR_ARTISTS_METHOD = 'artist.getSimilar'
        SCROBBLE_METHOD = 'track.scrobble'
        GET_TOKEN_METHOD = 'auth.getToken'
        GET_SESSION_METHOD = 'auth.getSession'
        TEXT_WIDTH = 50

        # Register this listener for the events: next, prev and quit
        # @note Required method for register listeners
        #
        # @return [List<Symbol>] The name of the events to listen.
        def self.get_listener_registry
            {
                next: :scrobble,
                prev: :scrobble,
                quit: :scrobble
            }
        end

        # Register the command: similar
        # @note Required method for register commands
        #
        # @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
        def self.get_command_registry
            {similar: {
                help: "Look in last.fm for similar artists or songs", 
                params_format: "<object>",
                usage: <<-HELP
There are two primary uses for this plugin:
    * find similar songs to the current song
    * find similar artists of the artist of the current song

To search for similar songs you dont need extra parameters, but if you wish to be explicit you can pass '@song' as parameter.

To search for artist the parameter '@artist' is required.

When the results are parsed successfully from Last.fm the first time, the results are stored in the local database, so, successives calls of this command, for the same song or artist dont require internet access.

                HELP
            },
                configure_lastfm: {
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
            }}
        end

        def configure_lastfm(params=[])
            return nil if params.empty?
            return nil unless params.size == 1 && params[0][:type] == :literal

            if params[0][:value] == 'begin'
                display c5(<<-INFO 
Hello! we're gonna setup the Last.fm scrobbler so this player can notify Last.fm the music you are hearing. So this is waht we'll do:
    1) The default browser will be opened and you'll be required to login into your Last.fm account (you require  an internet connection).
    2) You'll be asked to give authorization to this player to scrobble in your account.
    3) When you give the authorization, come back here and type:
        configure_lastfm done

Thats it! Not so hard right? So, lets begin! Press <enter> when you are ready....
                           INFO
                          )
                          # wait for user to be ready
                          gets

                          auth_info = LastFm.define_query(:token)
                          json = LastFm.consult_lastfm(auth_info, true)

                          return display(c2("Problem! #{json['error']}: #{json['message']}")) if json['token'].nil?

                          # guardamos el token para el segundo paso
                          LastFm.config['token'] = json['token']

                          auth_url = "http://www.last.fm/api/auth?api_key=#{LAST_FM_API_KEY}&token=#{LastFm.config['token']}"

                          if os == :windows
                              system("start \"\" \"#{auth_url}\"")
                          elsif os == :linux
                              system("gnome-open \"#{auth_url}\" \"\"")
                          else
                              display c4("Please write the next URL in your browser:\n#{auth_url}")
                          end

            elsif params[0][:value] == 'done'
                display c4("Thanks! Now we are validating the authorization and if it all right then we're done!. Wait a minute please...")
                auth_info = LastFm.define_query(:session)
                json = LastFm.consult_lastfm(auth_info, true)

                return display(c2("Problem! #{json['error']}: #{json['message']}")) if json['session'].nil?

                LastFm.config['session_key'] = json['session']['key']

                display c4("Ok! everything is set and the scrobbler is working now! Enjoy!")
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

        # Make a request to the last.fm webservice, and parse the response with JSON.
        #
        # @param (see #define_query)
        # @return [Hash] Filled with the webservice response information.
        def self.consult_lastfm(query_info, signed=false, method=:get)
            query_info[:api_key] = LastFm::LAST_FM_API_KEY

            if signed
                query_info[:sk] = LastFm.config['session_key'] unless LastFm.config['session_key'].nil?
                query_info[:api_sig] = generate_call_sign(query_info)
            end

            # siempre pedims la representacion en JSON, pero este parametro no se firma con el resto
            query_info[:format] = 'json'

            query_string = LastFm.get_query_string(query_info)

            begin
                if method == :get
                    url = "#{LastFm::LAST_FM_WS_ENDPOINT}?#{query_string}"
                        json_string = getClient.get_response(URI(url)).body
                elsif method == :post
                    url = LastFm::LAST_FM_WS_ENDPOINT
                    json_string = getClient.post_form(URI(url), query_info).body
                end
                return JSON.parse(json_string)
            rescue Exception => e
                raise CultomePlayerException.new(:internet_not_available, error_message: e.message, take_action: false) if e.message =~ /(Connection refused|Network is unreachable|name or service not known)/
            end
        end

        # Get a HTTP client for handle request. It check for environment variable __http_proxy__ and if setted, create Prxyed client.
        #
        # @return [Net::HTTP] The client to make request.
        def self.getClient
            return Net::HTTP unless ENV['http_proxy']

            proxy = URI.parse ENV['http_proxy']
            Net::HTTP::Proxy(proxy.host, proxy.port)
        end

        # Given the command information, creates a search criteria.
        #
        # @param type [Symbol] The type of query to be executed
        # @param song [Song] The song to find similars, depending on the params.
        # @param artist [Artist] The artist to find similars, depending on the params.
        # @return [Hash] With keys :method, :artist and :track, depending on the parameters.
        def self.define_query(type, song=nil, artist=nil, scrobbles=nil)
            case type
            when :artist
                LastFm.change_text("Looking for artists similar to #{artist}...")

                query = {
                    method: LastFm::GET_SIMILAR_ARTISTS_METHOD,
                    artist: artist,
                    limit: SimilarTo.similar_results_limit,
                }

            when :song
                LastFm.change_text("Looking for tracks similar to #{song} / #{artist}...")

                query = {
                    method: LastFm::GET_SIMILAR_TRACKS_METHOD,
                    artist: artist,
                    track: song,
                    limit: SimilarTo.similar_results_limit,
                }

            when :scrobble
                query = {
                    method: LastFm::SCROBBLE_METHOD,
                    artist: artist,
                    track: song,
                    timestamp: LastFm.timestamp,
                }

            when :multiple_scrobble
                query = {
                    method: LastFm::SCROBBLE_METHOD,
                }
                scrobbles.each_with_index do |s, idx|
                    query["artist[#{idx}]".to_sym] = s.artist
                    query["track[#{idx}]".to_sym] = s.track
                    query["timestamp[#{idx}]".to_sym] = s.timestamp
                end

            when :token
                query = {
                    method: LastFm::GET_TOKEN_METHOD,
                }

            when :session
                query = {
                    method: LastFm::GET_SESSION_METHOD,
                    token: LastFm.config['token'],
                }
            else
                display c2("You can only retrive similar @song or @artist.")
            end

            return query
        end

        # Time variable only relevant for testing. Returns an integer timestamps.
        #
        # @return [Integer] If fixes always return that date. Returns Time.now otherwise.
        def self.timestamp
            @test_time || Time.now.to_i
        end

        # Create a safe query string to use with the request to the webservice.
        #
        # @param (see #define_query)
        # @result [String] A safe query string.
        def self.get_query_string(search_info)
            return search_info.sort.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1].to_s)}&" }
        end

        def self.change_text(text, options={})
            opts = {
                background: true, 
                repeat: true, 
                width: LastFm::TEXT_WIDTH
            }

            opts.merge!(options)


            @thrd = roll_text(text, opts) do |text|
                display(c4(text), true)
            end

            sleep(2)
        end
    end
end

