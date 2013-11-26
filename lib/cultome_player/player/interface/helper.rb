module CultomePlayer::Player::Interface
  module Helper

    VALID_SONG_ATTR = [:name, :year, :track, :duration, :relative_path, :artist_id, :album_id, :drive_id]

    def process_for_search(params)
      return nil, [] if params.empty?

      query, values = case params.first.type
        when :object then process_object_for_search(params)
        when :criteria then process_criteria_for_search(params)
        when :literal then process_literal_for_search(params)
      end

      raise 'invalid command:invalid search criteria' if query =~ /^[\(\)]+$/
      return query, values
    end

    def get_files_in_tree(path, *extensions)
      return extensions.each_with_object([]) do |ext, files|
        files << Dir.glob("#{path}/**/*.#{ext}")
      end.flatten
    end

    def insert_song(new_info)
      existing_paths = get_unique_paths
      to_be_processed = new_info.select{|s| !existing_paths.include?(s[:file_path]) }
      return to_be_processed.count do |info|
        # aqui va la logica de insercion
        write_song(info)
      end
    end

    def update_song(new_info)
      existing_paths = get_unique_paths
      to_be_processed = new_info.select{|s| existing_paths.include?(s[:file_path]) }
      return to_be_processed.count do |info|
        # extraemos la cancion almacenada.. si existe
        song = Song.includes(:drive).where("drives.path||'/'||songs.relative_path = ?", info[:file_path]).references(:drives).first

        song.nil? ? false : write_song(info, song)
      end
    end

    def whole_library
      Song.all.to_a
    end

    def play_queue
      song = playlists[:queue].remove_next
      play_in_player song
      return song
    end

    def search_songs_with(cmd)
      criteria_query, criteria_values = process_for_search(cmd.params(:criteria))
      literal_query, literal_values = process_for_search(cmd.params(:literal))
      object_query, object_values = process_for_search(cmd.params(:object))
      # preparamos la query completa con sus parametros
      search_query = [criteria_query, object_query, literal_query].compact.collect{|q| "(#{q})" }.join(" or ")
      search_values = [criteria_values, object_values, literal_values].flatten.compact
      # hacemos la query!
      return search_query.empty? ? [] : Song.includes(:artist, :album).where(search_query, *search_values).references(:artist, :album).to_a
    end

    def get_from_playlists(lists)
      valid_lists = lists.select{|list_name| playlist?(list_name) }
      return playlists[*valid_lists].songs
    end

    def select_songs_with(cmd)
      founded_songs = search_songs_with(cmd)
      from_focus = get_from_focus(cmd.params(:number))
      from_playlists = get_from_playlists(cmd.params_values(:object))
      return founded_songs + from_focus + from_playlists
    end

    def player_object(name)
      case name
      when :song then playlists[:current].current
      else raise 'unknown player object:unknown player object'
      end
    end

    def play_inline?(cmd)
      if cmd.action == :play
        return true if cmd.params.all?{|p| p.type == :number }
        if cmd.params.size == 1
          p = cmd.params.first
          return p.type == :object && p.value == 'song'
        end
      end

      return false
    end

    private

    def get_from_focus(params)
      params.map do |p|
        playlists[:focus].at p.value - 1
      end
    end

    def get_unique_paths
      Song.all.collect{|m| m.path }.uniq
    end

    def artist_id(artist_name)
      return 0 if artist_name.blank?
      artist = Artist.where(name: artist_name).first_or_create
      return artist.id
    end

    def album_id(album_name)
      return 0 if album_name.blank?
      album = Album.where(name: album_name).first_or_create
      return album.id
    end

    def drive_id(library_path)
      return 0 if library_path.blank?
      drive = Drive.where(path: library_path).first_or_create
      return drive.id
    end

    def add_genre_to(song, genre)
      unless genre.blank?
        song.genres << Genre.where(name: genre).first_or_create
      end
    end

    def write_song(info, song=nil)
      info[:artist_id] = artist_id(info[:artist])
      info[:album_id] = album_id(info[:album])
      info[:drive_id] = drive_id(info[:library_path])
      info[:relative_path] = info[:file_path].gsub("#{info[:library_path]}/", '')

      song_attr = info.select{|k,v| VALID_SONG_ATTR.include?(k) }

      if song.nil?
        song = Song.create!(song_attr)
      else
        song.update_attributes(song_attr)
      end

      add_genre_to(song, info[:genre])

      return song.persisted?
    end

    def process_literal_for_search(params)
      literals = params.collect do |p|
        {query: 'artists.name like ? or albums.name like ? or songs.name like ?', value: ["%#{p.value}%", "%#{p.value}%", "%#{p.value}%"] }
      end

      query = literals.collect{|o| o[:query] }.join(" or ")
      values = literals.collect{|o| o[:value]}

      return query, values
    end

    def process_object_for_search(params)
      objs = params.collect do |p|
          case p.value
          when :artist then {query: 'artists.name = ?', value: current_artist.name }
          when :album then {query: 'albums.name = ?', value: current_album.name }
          when :song then {query: 'songs.name = ?', value: current_song.name }
          else raise 'invalid search:unknown type'
          end unless playlist?(p.value)
      end.compact

      return nil, [] if objs.empty?

      query = objs.collect{|o| o[:query] }.join(" or ")
      values = objs.collect{|o| o[:value]}

      return query, values
    end

    def process_criteria_for_search(params)
      default = Hash.new{|h,k| h[k] = {count: 0, query: "", values: []} }
      # analizamos los criterios
      criterios = params.each_with_object(default) do |p, acc|
        info = acc[p.criteria] # creamos nuevo mapa o sacamos el existente

        info[:count] += 1
        info[:query] << " or " if info[:count] > 1
        case p.criteria
          when :a then info[:query] << "artists.name like ?"
          when :b then info[:query] << "albums.name like ?"
          when :t then info[:query] << "songs.name like ?"
        end
        info[:values] << "%#{p.value}%"
      end

      query = criterios.values.collect{|c| "(#{c[:query]})" }.join(" and ")
      values = criterios.values.collect{|c| c[:values] }.flatten

      return query, values
    end

  end
end
