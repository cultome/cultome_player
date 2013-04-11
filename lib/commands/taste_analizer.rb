
# TODO
#  - Agregar las similitudes de generos
#  - Agregar algun mecanismo para que me avise cuando un genero no este dado de alta
class TasteAnalizer

	def initialize(cultome_player)
		@p = cultome_player
	end

	def calculate_weight(obj1, obj2)
		if obj1.class == Song && obj2.class == Song
			calculate_songs_weight(obj1, obj2)
		end
	end

	def calculate_songs_weight(song, next_song)
		return if @p.song_status.empty?

		#puts "Calificando cancion #{ song }, #{ next_song }, #{ @p.song_status }, #{ @p.current_command }..."

		progress_in_sec = @p.song_status["mp3.position.microseconds"] / 1000000
		percentage = (progress_in_sec * 100) / song.duration
		
		if @p.current_command[:command] =~ /next/
			if song == next_song
				Song.increment_counter :points, song.id
			end

			if percentage < 20
				# restamos puntos a la rola actual
				Song.decrement_counter :points, song.id
				Album.decrement_counter :points, song.album.id unless song.album.nil?
				if song.artist != next_song.artist
					Artist.decrement_counter :points, song.artist.id unless song.artist.id
				end
			elsif percentage > 60 && percentage < 90
				# damos un punto a la rola actual
				Song.increment_counter :points, song.id
				Album.increment_counter :points, song.album.id unless song.album.nil?
				Artist.increment_counter :points, song.artist.id unless song.artist.nil?
			elsif percentage >= 90
			# damos 2 puntos a la rola actual
				Song.update_counters song.id, points: 2
				Album.increment_counter :points, song.album.id unless song.album.nil?
				Artist.increment_counter :points, song.artist.id unless song.artist.nil?
			end
		elsif @p.current_command[:command] =~ /prev/
			# le damos puntos a la proxima rola 
			# porque la queremos volver a escuchar
			Song.increment_counter :points, song.id
			Album.increment_counter :points, song.album.id unless song.album.nil?
			Artist.increment_counter :points, song.artist.id unless song.artist.nil?
		end

		# checamos si cambio el genero de la musica
		genres_weight = calculate_genre_compatibility(song.genres, next_song.genres)
		#puts "Genre weight: #{genres_weight}"
	end

	def calculate_genre_compatibility(current_genres, next_genres)
		return 0 if current_genres.nil? || current_genres.empty?
		return 0 if next_genres.nil? || next_genres.empty?

		product = current_genres.product(next_genres)
		weight = product.inject(0){|sum, comb| sum += compare_genres(*comb)}
		return weight / product.size
	end

	def compare_genres(g1, g2)
		#puts "Comparando generos: #{g1.name} == #{g2.name}"
		return 1.0 if g1.name == g2.name

		case g1.name
			when 'Rock'
				case g2.name
					when 'Progressive Rock' then return 0.9
					when 'Hard Rock' then return 0.9
					when 'AlternRock' then return 0.9
					when 'Metal' then return 0.7
					when 'Heavy Metal' then return 0.6
					when 'Pop' then return 0.3
					when 'Hip-Hop' then return 0.3
					when 'Alternative' then return 0.2
				end
			when /Pop|BritPop/
				case g2.name
					when 'BritPop' then return 0.8
					when 'Pop' then return 0.8
					when 'Dance' then return 0.5
					when 'Club' then return 0.5
					when 'Disco' then return 0.4
					when 'Funck' then return 0.2
				end
		end

		return 0.0
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
