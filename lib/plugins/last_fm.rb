require 'cultome/plugin'
require 'cultome/persistence'
require 'cultome/exception'
require 'net/http'
require 'json'
require 'cgi'
require 'text_slider'
require 'digest'

# Plugin to use information from the Last.fm webservices.
module Plugin
	module SimilarTo
		# Display a list with similar artist or album of the give song or artist and shows a list with them, separing the one within our library.
		#
		# @param params [List<Hash>] With parsed player's object information. Only @artist and @song are valid.
		def similar(params=[])
			raise CultomePlayerException.new(:invalid_parameter, params: params) if !params.empty? && params.find{|p| p[:type] == :object}.nil?

			begin
				song_name = @cultome.song.name
				artist_name = @cultome.artist.name
				song_id = @cultome.song.id
				artist_id = @cultome.artist.id

				type = params.empty? ? :song : params.find{|p| p[:type] == :object}[:value]
				query_info = define_query(type, song_name, artist_name)

				in_db = check_in_db(query_info)

				if in_db.empty?
					json = consult_lastfm(query_info)

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

						artists_in_library = find_artists_in_library(artists)
						show_artist(artist_name, artists, artists_in_library)

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
						tracks_in_library = find_tracks_in_library(tracks)
						show_tracks(song_name, tracks, tracks_in_library)

						return tracks, tracks_in_library
					else
						# seguramente un error
						display(c2("Problem! #{json['error']}: #{json['message']}"))
					end
				else
					# trabajamos con datos de la db
					if query_info[:method] == LastFm::GET_SIMILAR_ARTISTS_METHOD
						artists_in_library = find_artists_in_library(in_db)
						show_artist(artist_name, in_db, artists_in_library)

						return in_db, artists_in_library
					elsif query_info[:method] == LastFm::GET_SIMILAR_TRACKS_METHOD
						tracks_in_library = find_tracks_in_library(in_db)
						show_tracks(song_name, in_db, tracks_in_library)

						return in_db, tracks_in_library
					end
				end
			ensure
				@thrd.kill if !@thrd.nil? && @thrd.stop?
			end
		end

		private

		# Lazy initializator for the 'similar results limit' configuration
		def similar_results_limit
			@config["similar_results_limit"] ||= 10
		end

		# Check if previously the similars has been inserted.
		#
		# @param (see #define_query)
		# @return [List<Similar>] A list with the result of the search for similars for this criterio.
		def check_in_db(query_info)
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

		def change_text(text, options={})
			opts = {
				background: true, 
				repeat: true, 
				width: 50
			}

			opts.merge!(options)


			@thrd = roll_text(text, opts) do |text|
				display(c4(text), true)
			end

			sleep(2)
		end

		# Make a request to the last.fm webservice, and parse the response with JSON.
		#
		# @param (see #define_query)
		# @return [Hash] Filled with the webservice response information.
		def consult_lastfm(query_info, signed=false, method=:get)
			query_info[:api_key] = LastFm::LAST_FM_API_KEY

			if signed
				query_info[:sk] = @config['session_key'] unless @config['session_key'].nil?
				query_info[:api_sig] = generate_call_sign(query_info)
			end

			# siempre pedims la representacion en JSON, pero este parametro no se firma con el resto
			query_info[:format] = 'json'

			query_string = get_query_string(query_info)
			client = getClient

			if method == :get
				url = "#{LastFm::LAST_FM_WS_ENDPOINT}?#{query_string}"
				json_string = client.get_response(URI(url)).body
			elsif method == :post
				url = LastFm::LAST_FM_WS_ENDPOINT
				json_string = client.post_form(URI(url), query_info).body
			end
			return JSON.parse(json_string)
		end

		def getClient
			return Net::HTTP unless ENV['http_proxy']

			proxy = URI.parse ENV['http_proxy']
			Net::HTTP::Proxy(proxy.host, proxy.port)
		end

		def generate_call_sign(query_info)
			params = query_info.sort.inject(""){|sum,map| sum += "#{map[0]}#{map[1]}" }
			sign = params + LastFm::LAST_FM_SECRET
			return Digest::MD5.hexdigest(sign)
		end

		# For the given artist list, find in the library if that artist exists, if exist, remove it from the parameter list.
		# @note This method change the artist parameter.
		#
		# @param artists [List<Hash>] Contains the transformed artist information.
		# @return [List<Artist>] The artist found in library.
		def find_artists_in_library(artists)
			in_library = []

			change_text('... ', {
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
		def find_tracks_in_library(tracks)
			in_library = []

			change_text("...", {
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
		def show_tracks(song, tracks, tracks_in_library)
			display c4("Similar tracks to #{song}") unless tracks.empty?
			tracks.each{|a| display c4("  #{a[:track]} / #{a[:artist]}") } unless tracks.empty?

			display c4("Similar tracks to #{song} in library") unless tracks_in_library.empty?
			display c4(tracks_in_library) unless tracks_in_library.empty?
			#tracks_in_library.each{|a| display("  #{a.name} / #{a.artist.name}") } unless tracks_in_library.empty?

			if tracks.empty? && tracks_in_library.empty?
				display c2("No similarities found for #{song}") 
			else
				@cultome.focus = tracks_in_library
			end
		end

		# Display a list with similar artist found and not found in library.
		#
		# @param artist [Artist] The artist compared.
		# @param artists [List<Hash>] The artist transformed information.
		# @param artists_in_library [List<Artist>] The similari artist found in library.
		def show_artist(artist, artists, artists_in_library)
			display c4("Similar artists to #{artist}") unless artists.empty?
			artists.each{|a| display c4("  #{a[:artist]}") } unless artists.empty?

			display c4("Similar artists to #{artist} in library") unless artists_in_library.empty?
			artists_in_library.each{|a| display("  #{a.name}") } unless artists_in_library.empty?

			display c2("No similarities found for #{artist}") if artists.empty? && artists_in_library.empty?
		end
	end

	module Scrobbler
		def scrobble(params=[])
			p = @cultome.prev_song
			return nil if p.nil?

			song_name = p.name
			artist_name = p.artist.name
			artist_id = p.artist.id
			if @cultome.song_status["mp3.position.microseconds"]
				progress = @cultome.song_status["mp3.position.microseconds"] / 1000000
			else
				progress = 0
			end

			# necesitamos que la cancion haya sido tocada almenos 30 segundos
			return nil if progress < 30
			song_name = @cultome.song.name

			# no hacemos scrobble si el artista o el track son desconocidos
			raise CultomePlayerException.new(:unable_to_scrobble, error_message: "Can't scrobble if artist or track names are unknown. Edit the ID3 tag.") if artist_id == 1

			return nil if @config['session_key'].nil?

			query_info = define_query(:scrobble, song_name, artist_name)

			begin
				consult_lastfm(query_info, true, :post)

				check_pending_scrobbles
			rescue Exception => e
				raise e unless e.message =~ /name or service not known/
					# guardamos los scrobbles para subirlos cuando haya conectividad
					Scrobble.create(artist: artist_name, track: song_name, timestamp: query_info[:timestamp])
			end
		end

		private

		def check_pending_scrobbles
			pending = Scrobble.pending
			if pending.size > 0
				query = define_query(:multiple_scrobble, nil, nil, pending)

				consult_lastfm(query, true, :post)

				# eliminamos los scrobbles
				pending.each{|s| s.delete }

				# checamos si hay mas por enviar
				return check_pending_scrobbles
			end
		end
	end

	class LastFm < PluginBase

		include TextSlider
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

		# Register this listener for the events: next, prev and quit
		# @note Required method for register listeners
		#
		# @return [List<Symbol>] The name of the events to listen.
		def get_listener_registry
			[:next, :prev, :quit]
		end

		# Register the command: similar
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
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
				params_format: "literal",
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

						  auth_info = define_query(:token)
						  json = consult_lastfm(auth_info, true)

						  return display(c2("Problem! #{json['error']}: #{json['message']}")) if json['token'].nil?

						  # guardamos el token para el segundo paso
						  @config['token'] = json['token']

						  auth_url = "http://www.last.fm/api/auth?api_key=#{LAST_FM_API_KEY}&token=#{@config['token']}"

						  if os == :windows
							  system("start \"\" \"#{auth_url}\"")
						  elsif os == :linux
							  system("gnome-open \"#{auth_url}\" \"\"")
						  else
							  display c4("Please write the next URL in your browser:\n#{auth_url}")
						  end

			elsif params[0][:value] == 'done'
				display c4("Thanks! Now we are validating the authorization and if it all right then we're done!. Wait a minute please...")
				auth_info = define_query(:session)
				json = consult_lastfm(auth_info, true)

				return display(c2("Problem! #{json['error']}: #{json['message']}")) if json['session'].nil?

				@config['session_key'] = json['session']['key']

				display c4("Ok! everything is set and the scrobbler is working now! Enjoy!")
			end
		end

		# Given the command information, creates a search criteria.
		#
		# @param type [Symbol] The type of query to be executed
		# @param song [Song] The song to find similars, depending on the params.
		# @param artist [Artist] The artist to find similars, depending on the params.
		# @return [Hash] With keys :method, :artist and :track, depending on the parameters.
		def define_query(type, song=nil, artist=nil, scrobbles=nil)
			case type
			when :artist
				change_text("Looking for artists similar to #{artist}...")

				query = {
					method: LastFm::GET_SIMILAR_ARTISTS_METHOD,
					artist: artist,
					limit: similar_results_limit,
				}

			when :song
				change_text("Looking for tracks similar to #{song} / #{artist}...")

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
					timestamp: Plugin::LastFm.timestamp,
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
					token: @config['token'],
				}
			else
				display c2("You can only retrive similar @song or @artist.")
			end

			return query
		end

		def self.timestamp
			@test_time || Time.now.to_i
		end

		# Create a safe query string to use with the request to the webservice.
		#
		# @param (see #define_query)
		# @result [String] A safe query string.
		def get_query_string(search_info)
			return search_info.sort.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1].to_s)}&" }
		end

		def method_missing(method_name, *args)
			return super if method_name !~ /next|prev|quit/

				scrobble(*args)
		end
	end

end

