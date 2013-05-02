require 'cultome/plugin'

# Plugin that tries to detect musical user preferences analizing the music he listen and the habits he has.
module Plugin
	class TasteAnalizer < PluginBase

		# Register this listener for the events: next and prev
		# @note Required method for register listeners
		#
		# @return [List<Symbol>] The name of the events to listen.
		def get_listener_registry
			[:next, :prev]
		end

		# When a callback is invoked in this listener, we give point to the last listened song.
		def method_missing(method_name, *args)
			super unless get_listener_registry.include?(method_name)
			calculate_songs_weight(prev_song, song) unless prev_song.nil?
		end

		private

		# Give point to a song, artist and album depending on various factors like how much the song played? is the same genre? same artist?
		#
		# @param song [Song] The current song
		# @param next_song [Song] The next song to be played
		def calculate_songs_weight(song, next_song)
			return -1 unless song.class == Song && next_song.class == Song
			return 0 unless song_status.respond_to?(:[]) && !song_status["mp3.position.microseconds"].nil?

			#puts "Calificando cancion #{ song }, #{ next_song }, #{ @p.current_command }..."

			progress_in_sec = song_status["mp3.position.microseconds"] / 1000000
			percentage = (progress_in_sec * 100) / song.duration

			points = 0

			if @p.current_command[:command] =~ /next/
				Song.increment_counter(:points, song.id) if song == next_song
				points += 1
			end

			if percentage < 20
				# restamos puntos a la rola actual
				Song.decrement_counter :points, song.id
				Album.decrement_counter :points, song.album.id unless song.album.nil?
				Artist.decrement_counter :points, song.artist.id unless song.artist.id if song.artist != next_song.artist

				points -= 1
			elsif percentage > 60 && percentage < 90
				# damos un punto a la rola actual
				Song.increment_counter :points, song.id
				Album.increment_counter :points, song.album.id unless song.album.nil?
				Artist.increment_counter :points, song.artist.id unless song.artist.nil?

				points += 1
			elsif percentage >= 90
				# damos 2 puntos a la rola actual
				Song.update_counters song.id, points: 2
				Album.increment_counter :points, song.album.id unless song.album.nil?
				Artist.increment_counter :points, song.artist.id unless song.artist.nil?

				points += 1
			elsif @p.current_command[:command] =~ /prev/
				# le damos puntos a la proxima rola 
				# porque la queremos volver a escuchar
				Song.increment_counter :points, song.id
				Album.increment_counter :points, song.album.id unless song.album.nil?
				Artist.increment_counter :points, song.artist.id unless song.artist.nil?

				points += 1
			end

			# checamos si cambio el genero de la musica
			genres_weight = calculate_genre_compatibility(song.genres, next_song.genres)
			#puts "Genre weight: #{genres_weight}"

			return points + genres_weight
		end

		# Calculate how much song genres is similar to other.
		#
		# @param current_genres [List<Genre>] One list of genres
		# @param next_genres [List<Genre>] The other list of genres to compare with.
		# @return [Float] A number between 0 and 1. Denotes the similitud between song genres.
		def calculate_genre_compatibility(current_genres, next_genres)
			return 0 if current_genres.nil? || current_genres.empty?
			return 0 if next_genres.nil? || next_genres.empty?

			product = current_genres.product(next_genres)
			weight = product.inject(0){|sum, comb| sum += compare_genres(*comb)}
			return weight / product.size
		end
		
		# Lazy initializator for 'genres compatibility' configuration
		def genre_compatibility
			@config["genres compatibility"] ||= {}
		end

		# Calculate how much a genre is similar to other genre.
		#
		# @param g1 [Genre] A genre
		# @param g2 [Genre] Another genre to compre with.
		# @return [Float] A number between 0 and 1. Denotes the similitud between genres.
		def compare_genres(g1, g2)
			#puts "Comparando generos: #{g1.name} == #{g2.name}"
			return 1.0 if g1.name == g2.name
			similar = genre_compatibility[[g1.name, g2.name]]
			#puts "1) G1: #{g1.name} G2: #{g2.name} => #{similar}"
			return similar unless similar.nil?
			#puts "2) G1: #{g2.name} G2: #{g1.name} => #{genre_compatibility[[g2.name, g1.name]]}"
			return genre_compatibility[[g2.name, g1.name]] || 0.0
		end

		#Rock
		#Pop
		#BritPop
		#Blues
		#Alternative
		#Soundtrack
		#Comedy
		#Hip-Hop
		#Progressive Rock
		#Heavy Metal
		#Tribal
		#AlternRock
		#Rap
		#Disco
		#Metal
		#Dance
		#Hard Rock
		#Ethnic
		#Euro-House
		#Other
		#Industrial
		#Electronic
		#Club
		#Indie
		#Funk
		#Acid Jazz
	end
end
