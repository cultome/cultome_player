# encoding: utf-8
module CultomePlayer::Extras
  module TasteAnalizer

    # Register the event listener for next and prev commands.
    def self.included(base)
      CultomePlayer::Player.register_event_listener(:next, :qualify_song_preference)
      CultomePlayer::Player.register_event_listener(:prev, :qualify_song_preference)
    end

    # Give point to a song, artist and album depending on various factors like how much the song played? is the same genre? same artist?
    #
    # @param command [Hash] The user command
    def qualify_song_preference(command)
      return nil if player.prev_song.nil?

      song = player.prev_song
      next_song = current_song

      return -1 unless song.class == CultomePlayer::Model::Song && next_song.class == CultomePlayer::Model::Song
      return 0 unless player.song_status.respond_to?(:[]) && !player.song_status[:seconds].nil?

      #puts "Calificando cancion #{ song }, #{ next_song }, #{ player.current_command }..."

      percentage = (player.song_status[:seconds] * 100) / song.duration

      points = 0

      if player.current_command[:command] =~ /next/
        CultomePlayer::Model::Song.increment_counter(:points, song.id) if song == next_song
        points += 1
      end

      if percentage < 20
        # restamos puntos a la rola actual
        CultomePlayer::Model::Song.decrement_counter :points, song.id
        CultomePlayer::Model::Album.decrement_counter :points, song.album.id unless song.album.nil?
        CultomePlayer::Model::Artist.decrement_counter :points, song.artist.id unless song.artist.id if song.artist != next_song.artist

        points -= 1
      elsif percentage > 60 && percentage < 90
        # damos un punto a la rola actual
        CultomePlayer::Model::Song.increment_counter :points, song.id
        CultomePlayer::Model::Album.increment_counter :points, song.album.id unless song.album.nil?
        CultomePlayer::Model::Artist.increment_counter :points, song.artist.id unless song.artist.nil?

        points += 1
      elsif percentage >= 90
        # damos 2 puntos a la rola actual
        CultomePlayer::Model::Song.update_counters song.id, points: 2
        CultomePlayer::Model::Album.increment_counter :points, song.album.id unless song.album.nil?
        CultomePlayer::Model::Artist.increment_counter :points, song.artist.id unless song.artist.nil?

        points += 1
      elsif player.current_command[:command] =~ /prev/
        # le damos puntos a la proxima rola 
        # porque la queremos volver a escuchar
        CultomePlayer::Model::Song.increment_counter :points, song.id
        CultomePlayer::Model::Album.increment_counter :points, song.album.id unless song.album.nil?
        CultomePlayer::Model::Artist.increment_counter :points, song.artist.id unless song.artist.nil?

        points += 1
      end

      # checamos si cambio el genero de la musica
      genres_weight = calculate_genre_compatibility(song.genres, next_song.genres)
      #puts "Genre weight: #{genres_weight}"

      return points + genres_weight
    end

    private

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
      extras_config["genres_compatibility"] ||= {}
    end

    # Calculate how much a genre is similar to other genre.
    #
    # @param g1 [Genre] A genre
    # @param g2 [Genre] Another genre to compre with.
    # @return [Float] A number between 0 and 1. Denotes the similitud between genres.
    def compare_genres(g1, g2)
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
