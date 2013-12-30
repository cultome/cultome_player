
module CultomePlayer::Player::Interface
  module Extended

    def search(cmd)
      songs = select_songs_with cmd

      playlists[:focus] <= songs

      if songs.empty?
        failure('It match not even one')
      else
        success(songs: songs)
      end
    end

    def show(cmd)
      if cmd.params.empty?
        if playing?
          #mostramos la cancion actual
          return success(message: current_song.to_s, song: current_song)
        else
          return failure("Nothing to show yet. Try with 'play' first.")
        end

      else
        list_to_show = cmd.params(:object).reduce([]) do |acc, p|
          acc + case p.value
          when :playlist then current_playlist.to_a
          when :library then whole_library.to_a
          else []
          end
        end

        msg = list_to_show.each_with_index.collect{|s,i| "#{i+1}. #{s.to_s}"}.join("\n")
        return success(message: msg, list: list_to_show)
      end
    end

    def enqueue
    end

    def shuffle
    end

    def help
    end

    def connect(cmd)
      path = cmd.params(:path).first
      name = cmd.params(:literal).first

      if path.nil?
        # with only literal parameter
        raise 'invalid parameter:missing parameters' if name.nil?

        # es una reconexion...
        drive = Drive.find_by(name: name.value)
        raise 'invalid name:the named drive doesnt exists' if drive.nil?
        drive.update_attributes({connected: true})
      else
        # with path and literal parameter
        raise 'invalid path:the directory is invalid' unless Dir.exist?(path.value)
        raise 'invalid name:name required' if name.nil?

        # es una creacion o actualizacion...
        # checamos si la unidad existe
        root_path = File.expand_path(path.value)
        drive = Drive.find_by(path: root_path)
        # la creamos si no existe...
        is_update = !drive.nil? 
        drive = Drive.create!(name: name.value, path: root_path) unless is_update

        track_info = get_files_in_tree(root_path, file_types).each_with_object([]) do |filepath, acc|
          acc << extract_from_mp3(filepath, library_path: root_path)
        end

        # insertamos las nuevas y actualizamos las existentes
        updated = update_song(track_info)
        imported = insert_song(track_info)

        success(message: connect_response_msg(imported, updated),
                files_detected: track_info.size,
                files_imported: imported,
                files_updated: updated,
                drive_updated: is_update)
      end
    end

    def disconnect
    end

    def ff(cmd)
      ff_in_secs = 10

      unless cmd.params(:number).empty?
        ff_in_secs = cmd.params(:number).first.value
      end

      ff_in_player ff_in_secs

      return success(message: "Fast Forwarded by #{ff_in_secs} secs")
    end

    def fb(cmd)
      fb_in_secs = 10

      unless cmd.params(:number).empty?
        fb_in_secs = cmd.params(:number).first
      end

      fb_in_player fb_in_secs

      return success(message: "Fast Backwarded by #{fb_in_secs} secs")
    end
  end
end

