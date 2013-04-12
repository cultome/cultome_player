require 'open-uri'
require 'json'
require 'persistence'
require 'cgi'

class LastFm
	LAST_FM_WS_ENDPOINT = 'http://ws.audioscrobbler.com/2.0/'
	LAST_FM_API_KEY = 'bfc44b35e39dc6e8df68594a55a442c5'
	SIMILARS_LIMIT = 10

	def initialize(player)
		@p = player
	end

	def get_command_registry
		{similar: {help: "Look in last.fm for similar artists or songs", params_format: "<object>"}}
	end

	def similar(params=[])
		song = @p.song.name
		artist = @p.artist.name

		json = get_similars(params, song, artist)

		display("Similars found!") unless json.nil?

		if !json['similarartists'].nil?
			artists = extract_artists(json['similarartists']['artist'])
			artists_in_library = find_artists_in_library(artists)

			show_artist(artist, artists, artists_in_library)
		elsif !json['similartracks'].nil?
			tracks = extract_tracks(json['similartracks']['track'])
			tracks_in_library = find_tracks_in_library(tracks)
			show_tracks(song, tracks, tracks_in_library)
		else
			# seguramente un error
			display("Problem! #{json['error']}: #{json['message']}")
		end
	end

	def get_query_string(params, song, artist)
		if params.empty?
			# por default se buscan rolas similares
			display("Looking for tracks similar to #{song} / #{artist}...")
			query = {
				method: 'track.getSimilar',
				artist: artist,
				track: song,
			}
		else
			params.each do |param|
				case param[:type]
				when :object
					case param[:value]
					when :artist
						display("Looking for artists similar to #{artist}...")
						query = {
							method: 'artist.getSimilar',
							artist: artist,
						}

					when :song
						display("Looking for tracks similar to #{song} / #{artist}...")
						query = {
							method: 'track.getSimilar',
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
		
		return query.inject(""){|sum,map| sum += "#{map[0]}=#{CGI::escape(map[1])}&" }
	end

	def get_similars(params, song, artist)
		query_string = get_query_string(params, song, artist)

		url = "#{LAST_FM_WS_ENDPOINT}?api_key=#{LAST_FM_API_KEY}&limit=#{SIMILARS_LIMIT}&format=json&#{query_string}"

		json_string = open(url).readlines.join

		return JSON.parse(json_string)
	end

	def extract_artists(artists)
		artists.collect do |a|
			{
				name: a['name'],
				artist_url: a['url'],
			}
		end
	end

	def extract_tracks(tracks)
		tracks.collect do |t|
			{
				name: t['name'],
				artist: t['artist']['name'],
				track_url: t['url'],
				artist_url: t['artist']['url'],
			}
		end
	end

	def find_artists_in_library(artists)
		in_library = []

		display('Fetching similar artist from library', true)

		artists.keep_if do |a|

			display('.', true)

			artist = Artist.find_by_name(a[:name])
			if artist.empty?
				true
			else
				in_library << artist
				false
			end
		end

		return in_library
	end

	def find_tracks_in_library(tracks)
		in_library = []

		display('Fetching similar tracks from library', true)

		tracks.keep_if do |t|
			display('.', true)
			song = Song.joins(:artist).where('songs.name = ? and artists.name = ?', t[:name], t[:artist]).to_a
			if song.empty?
				true
			else
				in_library << song
				false
			end
		end

		return in_library.flatten
	end

	def display(msg, continuos=false)
		@p.display(msg, continuos)
	end

	def show_tracks(song, tracks, tracks_in_library)
		display("Similar tracks to #{song}") unless tracks.empty?
		tracks.each{|a| display("  #{a[:name]} / #{a[:artist]}") } unless tracks.empty?

		display("Similar tracks to #{song} in library") unless tracks_in_library.empty?
		tracks_in_library.each{|a| display("  #{a.name} / #{a.artist.name}") } unless tracks_in_library.empty?

		display("No similarities found for #{song}") if tracks.empty? && tracks_in_library.empty?
	end

	def show_artist(artist, artists, artists_in_library)
		display("Similar artists to #{artist}") unless artists.empty?
		artists.each{|a| display("  #{a[:name]}") } unless artists.empty?

		display("Similar artists to #{artist} in library") unless artists_in_library.empty?
		artists_in_library.each{|a| display("  #{a.name}") } unless artists_in_library.empty?

		display("No similarities found for #{artist}") if artists.empty? && artists_in_library.empty?
	end
end

