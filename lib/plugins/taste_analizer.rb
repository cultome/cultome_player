
# Plugin that tries to detect musical user preferences analizing the music he listen and the habits he has.
module Plugins
	module TasteAnalizer

		# Register this listener for the events: next and prev
		# @note Required method for register listeners
		#
		# @return [List<Symbol>] The name of the events to listen.
		def self.get_listener_registry
			{ 
                next: :calculate_songs_weight,
                prev: :calculate_songs_weight
            }
		end

		# Give point to a song, artist and album depending on various factors like how much the song played? is the same genre? same artist?
		#
		# @param song [Song] The current song
		# @param next_song [Song] The next song to be played
		def self.calculate_songs_weight(cultome, params=[])
            return nil if cultome.prev_song.nil?

			song = cultome.prev_song
            next_song = cultome.song

			return -1 unless song.class == Cultome::Song && next_song.class == Cultome::Song
			return 0 unless cultome.song_status.respond_to?(:[]) && !cultome.song_status[:seconds].nil?

			#puts "Calificando cancion #{ song }, #{ next_song }, #{ cultome.current_command }..."

			percentage = (cultome.song_status[:seconds] * 100) / song.duration

			points = 0

			if cultome.current_command[:command] =~ /next/
				Cultome::Song.increment_counter(:points, song.id) if song == next_song
				points += 1
			end

			if percentage < 20
				# restamos puntos a la rola actual
				Cultome::Song.decrement_counter :points, song.id
				Cultome::Album.decrement_counter :points, song.album.id unless song.album.nil?
				Cultome::Artist.decrement_counter :points, song.artist.id unless song.artist.id if song.artist != next_song.artist

				points -= 1
			elsif percentage > 60 && percentage < 90
				# damos un punto a la rola actual
				Cultome::Song.increment_counter :points, song.id
				Cultome::Album.increment_counter :points, song.album.id unless song.album.nil?
				Cultome::Artist.increment_counter :points, song.artist.id unless song.artist.nil?

				points += 1
			elsif percentage >= 90
				# damos 2 puntos a la rola actual
				Cultome::Song.update_counters song.id, points: 2
				Cultome::Album.increment_counter :points, song.album.id unless song.album.nil?
				Cultome::Artist.increment_counter :points, song.artist.id unless song.artist.nil?

				points += 1
			elsif cultome.current_command[:command] =~ /prev/
				# le damos puntos a la proxima rola 
				# porque la queremos volver a escuchar
				Cultome::Song.increment_counter :points, song.id
				Cultome::Album.increment_counter :points, song.album.id unless song.album.nil?
				Cultome::Artist.increment_counter :points, song.artist.id unless song.artist.nil?

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
		def self.calculate_genre_compatibility(current_genres, next_genres)
			return 0 if current_genres.nil? || current_genres.empty?
			return 0 if next_genres.nil? || next_genres.empty?

			product = current_genres.product(next_genres)
			weight = product.inject(0){|sum, comb| sum += compare_genres(*comb)}
			return weight / product.size
		end
		
		# Lazy initializator for 'genres compatibility' configuration
		def self.genre_compatibility
			TasteAnalizer.config["genres_compatibility"] ||= {}
		end

		# Calculate how much a genre is similar to other genre.
		#
		# @param g1 [Genre] A genre
		# @param g2 [Genre] Another genre to compre with.
		# @return [Float] A number between 0 and 1. Denotes the similitud between genres.
		def self.compare_genres(g1, g2)
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
