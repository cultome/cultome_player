require 'cultome/commands/base_command'
require 'cultome/persistence'
require 'open-uri'
require 'json'
require 'cgi'

class LastFm < BaseCommand

	LAST_FM_WS_ENDPOINT = 'http://ws.audioscrobbler.com/2.0/'
	LAST_FM_API_KEY = 'bfc44b35e39dc6e8df68594a55a442c5'
	SIMILARS_LIMIT = 10
	GET_SIMILAR_TRACKS_METHOD = 'track.getSimilar'
	GET_SIMILAR_ARTISTS_METHOD = 'artist.getSimilar'

	def get_command_registry
		{similar: {help: "Look in last.fm for similar artists or songs", params_format: "<object>"}}
	end

	def similar(params=[])
		song = @p.song.name
		artist = @p.artist.name
		song_id = @p.song.id
		artist_id = @p.artist.id

		search_info = define_search(params, song, artist)

		in_db = check_in_db(search_info)

		if in_db.empty?
			json = get_similars(search_info)

			if !json['similarartists'].nil?
				artists = extract_artists(json['similarartists']['artist'])
				save_similar_artists(artist_id, artists)
				artists_in_library = find_artists_in_library(artists)
				show_artist(artist, artists, artists_in_library)
			elsif !json['similartracks'].nil?
				tracks = extract_tracks(json['similartracks']['track'])
				save_similar_tracks(song_id, tracks)
				tracks_in_library = find_tracks_in_library(tracks)
				show_tracks(song, tracks, tracks_in_library)
			else
				# seguramente un error
				display("Problem! #{json['error']}: #{json['message']}")
			end
		else
			# trabajamos con datos de la db
			if search_info[:method] == GET_SIMILAR_ARTISTS_METHOD
				artists_in_library = find_artists_in_library(in_db)
				show_artist(artist, in_db, artists_in_library)
			elsif search_info[:method] == GET_SIMILAR_TRACKS_METHOD
				tracks_in_library = find_tracks_in_library(in_db)
				show_tracks(song, in_db, tracks_in_library)
			end
		end
	end

	def save_similar_artists(original_artist_id, artists)
		artists.each do |a|
			Artist.find(original_artist_id).similars.create(a)
		end
	end

	def save_similar_tracks(original_track_id, tracks)
		tracks.each do |t|
			Song.find(original_track_id).similars.create(t)
		end
	end

	def check_in_db(search_info)
		if search_info[:method] == GET_SIMILAR_ARTISTS_METHOD
			artist = Artist.includes(:similars).find_by_name(search_info[:artist])
			return artist.similars
		elsif search_info[:method] == GET_SIMILAR_TRACKS_METHOD
			tracks = Song.includes(:similars).find_by_name(search_info[:track])
			return tracks.similars
		end
	end

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

	def get_query_string(search_info)
		return search_info.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1])}&" }
	end

	def get_similars(search_info)
		query_string = search_info.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1])}&" }

		url = "#{LAST_FM_WS_ENDPOINT}?api_key=#{LAST_FM_API_KEY}&limit=#{SIMILARS_LIMIT}&format=json&#{query_string}"

		json_string = open(url).readlines.join

		return JSON.parse(json_string)
	end

	def extract_artists(artists)
		artists.collect do |a|
			{
				artist: a['name'],
				artist_url: a['url'],
				similar_to: 'artist'
			}
		end
	end

	def extract_tracks(tracks)
		tracks.collect do |t|
			{
				track: t['name'],
				artist: t['artist']['name'],
				track_url: t['url'],
				artist_url: t['artist']['url'],
				similar_to: 'track'
			}
		end
	end

	def find_artists_in_library(artists)
		in_library = []

		display('Fetching similar artist from library', true)

		artists.keep_if do |a|
			display('.', true)

			artist = Artist.find_by_name(a[:artist])
			if artist.empty?
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

	def show_tracks(song, tracks, tracks_in_library)
		display("Similar tracks to #{song}") unless tracks.empty?
		tracks.each{|a| display("  #{a[:track]} / #{a[:artist]}") } unless tracks.empty?

		display("Similar tracks to #{song} in library") unless tracks_in_library.empty?
		display(tracks_in_library) unless tracks_in_library.empty?
		#tracks_in_library.each{|a| display("  #{a.name} / #{a.artist.name}") } unless tracks_in_library.empty?

		if tracks.empty? && tracks_in_library.empty?
			display("No similarities found for #{song}") 
		else
			@p.focus = tracks_in_library
		end
	end

	def show_artist(artist, artists, artists_in_library)
		display("Similar artists to #{artist}") unless artists.empty?
		artists.each{|a| display("  #{a[:artist]}") } unless artists.empty?

		display("Similar artists to #{artist} in library") unless artists_in_library.empty?
		artists_in_library.each{|a| display("  #{a.name}") } unless artists_in_library.empty?

		display("No similarities found for #{artist}") if artists.empty? && artists_in_library.empty?
	end
end

