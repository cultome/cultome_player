
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
		puts "Calificando cancion #{ song }, #{ next_song }, #{ @p.song_status }, #{ @p.current_command }..."

		progress_in_sec = @p.song_status["mp3.position.microseconds"] / 1000000
		percentage = (progress_in_sec * 100) / song.duration
		
		if @p.current_command[:command] =~ /next/
			if percentage < 10
				# restamos puntos a la rola actual
puts "-1 a #{song}"
				Song.decrement_counter :points, song.id
			elsif percentage > 60 && percentage < 90
				# damos un punto a la rola actual
puts "1 a #{song}"
				Song.increment_counter :points, song.id
			elsif percentage >= 90
			# damos 2 puntos a la rola actual
puts "2 a #{song}"
				Song.update_counters song.id, points: 2
			end
		elsif @p.current_command[:command] =~ /prev/
			# le damos puntos a la proxima rola 
			# porque la queremos volver a escuchar
puts "1 a #{next_song}"
			Song.update_counters next_song.id, points: 1
		#elsif @p.current_command[:command] =~ /play/ 
			# a todas las rolas pasadas por numero
			# se les dan puntos por ser seleccionadas a mano
			#if @p.current_command[:params].all?{|p| p[:type] == :number }
			#end
		end

		# checamos si cambio el genero de la musica
		genres_weight = calculate_genre_compatibility(song.genres, next_song.genres)
		puts "Genre weight: #{genres_weight}"
	end

	def calculate_genre_compatibility(current_genres, next_genres)
		return 0 if current_genres.nil? || current_genres.empty?
		return 0 if next_genres.nil? || next_genres.empty?

		weight = current_genres.product(next_genres).inject(0){|sum, c,n| sum += compare_genres(c,n)}

		return weight / (current_genres.size + next_genres)
	end

	def compare_genres(g1, g2)
		return 1 if g1 == g2
		case g1
			when 'Rock'
				case g2
					when 'Metal' then return 0.7
					when 'Pop' then return 0.3
				end
		end
	end
end
