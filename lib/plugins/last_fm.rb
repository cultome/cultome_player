require 'cultome/plugin'
require 'cultome/persistence'
require 'net/http'
require 'json'
require 'cgi'

# Plugin to use information from the Last.fm webservices.
module Plugin
	class LastFm < PluginBase

		LAST_FM_WS_ENDPOINT = 'http://ws.audioscrobbler.com/2.0/'
		LAST_FM_API_KEY = 'bfc44b35e39dc6e8df68594a55a442c5'
		GET_SIMILAR_TRACKS_METHOD = 'track.getSimilar'
		GET_SIMILAR_ARTISTS_METHOD = 'artist.getSimilar'


		# Register the command: similar
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{similar: {help: "Look in last.fm for similar artists or songs", params_format: "<object>"}}
		end

		# Display a list with similar artist or album of the give song or artist and shows a list with them, separing the one within our library.
		#
		# @param params [List<Hash>] With parsed player's object information. Only @artist and @song are valid.
		def similar(params=[])
			song_name = @cultome.song.name
			artist_name = @cultome.artist.name
			song_id = @cultome.song.id
			artist_id = @cultome.artist.id

			search_info = define_search(params, song_name, artist_name)

			in_db = check_in_db(search_info)

			if in_db.empty?
				json = get_similars(search_info)

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
					display("Problem! #{json['error']}: #{json['message']}")
				end
			else
				# trabajamos con datos de la db
				if search_info[:method] == GET_SIMILAR_ARTISTS_METHOD
					artists_in_library = find_artists_in_library(in_db)
					show_artist(artist_name, in_db, artists_in_library)

					return in_db, artists_in_library
				elsif search_info[:method] == GET_SIMILAR_TRACKS_METHOD
					tracks_in_library = find_tracks_in_library(in_db)
					show_tracks(song_name, in_db, tracks_in_library)

					return in_db, tracks_in_library
				end
			end
		end

		private

		# Lazy initializator for the 'similar results limit' configuration
		def similar_results_limit
			@config["similar_results_limit"] ||= 10
		end

		# Check if previously the similars has been inserted.
		#
		# @param (see #define_search)
		# @return [List<Similar>] A list with the result of the search for similars for this criterio.
		def check_in_db(search_info)
			if search_info[:method] == GET_SIMILAR_ARTISTS_METHOD
				artist = Artist.includes(:similars).find_by_name(search_info[:artist])
				return artist.similars
			elsif search_info[:method] == GET_SIMILAR_TRACKS_METHOD
				tracks = Song.includes(:similars).find_by_name(search_info[:track])
				return tracks.similars
			end
		end

		# Given the command information, creates a search criteria.
		#
		# @param params [List<Hash>] Command's params information.
		# @param song [Song] The song to find similars, depending on the params.
		# @param artist [Artist] The artist to find similars, depending on the params.
		# @return [Hash] With keys :method, :artist and :track, depending on the parameters.
		def define_search(params, song, artist)
			if params.empty?
				# por default se buscan rolas similares
				display("Looking for tracks similar to #{song} / #{artist}...")
				query = {
					method: GET_SIMILAR_TRACKS_METHOD,
					artist: artist,
					track: song
				}
			else
				params.each do |param|
					case param[:type]
					when :object
						case param[:value]
						when :artist
							display("Looking for artists similar to #{artist}...")
							query = {
								method: GET_SIMILAR_ARTISTS_METHOD,
								artist: artist
							}

						when :song
							display("Looking for tracks similar to #{song} / #{artist}...")
							query = {
								method: GET_SIMILAR_TRACKS_METHOD,
								artist: artist,
								track: song
							}
						else
							display("You can only retrive similar @song or @artist.")
						end
					else
						display("You can only retrive similar @song or @artist.")
					end
				end
			end

			return query
		end

		# Create a safe query string to use with the request to the webservice.
		#
		# @param (see #define_search)
		# @result [String] A safe query string.
		def get_query_string(search_info)
			return search_info.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1])}&" }
		end

		# Make a request to the last.fm webservice, and parse the response with JSON.
		#
		# @param (see #define_search)
		# @return [Hash] Filled with the webservice response information.
		def get_similars(search_info)
			query_string = search_info.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1])}&" }

			url = "#{LAST_FM_WS_ENDPOINT}?api_key=#{LAST_FM_API_KEY}&limit=#{similar_results_limit}&format=json&#{query_string}"

			json_string = Net::HTTP::get_response(URI(url)).body

			return JSON.parse(json_string)
		end

		# For the given artist list, find in the library if that artist exists, if exist, remove it from the parameter list.
		# @note This method change the artist parameter.
		#
		# @param artists [List<Hash>] Contains the transformed artist information.
		# @return [List<Artist>] The artist found in library.
		def find_artists_in_library(artists)
			in_library = []

			display('Fetching similar artist from library', true)

			artists.keep_if do |a|
				display('.', true)

				artist = Artist.find_by_name(a[:artist])
				if artist.nil? 
					# aqui meter a similars
					true
				else
					in_library << artist
					false
				end
			end
			display("")

			return in_library
		end

		# For the given tracks list, find in the library if that track exists, if exist, remove it from the parameter list.
		# @note This method change the tracks parameter.
		#
		# @param tracks [List<Hash>] Contains the transformed track information.
		# @return [List<Song>] The songs found in library.
		def find_tracks_in_library(tracks)
			in_library = []

			display('Fetching similar tracks from library', true)

			tracks.keep_if do |t|
				display('.', true)
				song = Song.joins(:artist).where('songs.name = ? and artists.name = ?', t[:track], t[:artist]).to_a
				if song.empty?
					# aqui meter a similars
					true
				else
					in_library << song
					false
				end
			end
			display("")

			return in_library.flatten
		end

		# Display a list with similar tracks found and not found in library.
		#
		# @param song [Song] The song compared.
		# @param tracks [List<Hash>] The song transformed information.
		# @param tracks_in_library [List<Song>] The similari songs found in library.
		def show_tracks(song, tracks, tracks_in_library)
			display("Similar tracks to #{song}") unless tracks.empty?
			tracks.each{|a| display("  #{a[:track]} / #{a[:artist]}") } unless tracks.empty?

			display("Similar tracks to #{song} in library") unless tracks_in_library.empty?
			display(tracks_in_library) unless tracks_in_library.empty?
			#tracks_in_library.each{|a| display("  #{a.name} / #{a.artist.name}") } unless tracks_in_library.empty?

			if tracks.empty? && tracks_in_library.empty?
				display("No similarities found for #{song}") 
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
			display("Similar artists to #{artist}") unless artists.empty?
			artists.each{|a| display("  #{a[:artist]}") } unless artists.empty?

			display("Similar artists to #{artist} in library") unless artists_in_library.empty?
			artists_in_library.each{|a| display("  #{a.name}") } unless artists_in_library.empty?

			display("No similarities found for #{artist}") if artists.empty? && artists_in_library.empty?
		end
	end
end

