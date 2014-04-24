
module CultomePlayer::Player::Interface
  module Extended

    # For more information on this command refer to user manual or inline help in interactive mode.
    def search(cmd)
      songs = select_songs_with cmd

      if songs.empty?
        failure('It matches not even one')
      else
        playlists[:focus] <= songs
        success(songs: songs, response_type: :songs)
      end
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def show(cmd)
      if cmd.params.empty?
        if playing?
          #mostramos la cancion actual
          msg = get_progress_bar_with_labels(playback_position, playback_length, 20, format_secs(playback_position), format_secs(playback_length))
          playlists[:focus] <= current_song
          return success(message: "#{current_song.to_s}\n#{msg}", song: current_song)
        else
          return failure("Nothing to show yet. Try with 'play' first.")
        end

      else
        list_to_show = cmd.params(:object).reduce([]) do |acc, p|
          acc + case p.value
            when :playlist then current_playlist.to_a
            when :current then playlists[:current].to_a
            when :history then playlists[:history].to_a
            when :queue then playlists[:queue].to_a
            when :focus then playlists[:focus].to_a

            when :library then whole_library.to_a
            when :drives then Drive.all
            when :song then return success(message: current_song.to_s, song: current_song)
            else []
          end
        end

        if list_to_show.empty?
          return failure("I checked and there is nothing there.")
        else
          playlists[:focus] <= list_to_show
          return success(list: list_to_show, response_type: :list)
        end
      end
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def enqueue(cmd)
      songs = select_songs_with cmd
      if songs.empty?
        failure(message: "No songs found with this criteria. Sorry, nothing was enqueued.")
      else
        playlists[:queue] << songs
        msg = "These songs were enqueued:\n"
        songs.each {|s,idx| msg << "  #{s.to_s}\n"}

        success(message: msg, enqueued: songs)
      end
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def shuffle(cmd)
      if cmd.params.empty?
        if playlists[:current].shuffling?
          return success(message: "Everyday I'm shuffling!", shuffling: true)
        else
          return success(message: "No shuffling", shuffling: false)
        end
      else
        turn_on = cmd.params(:boolean).first.value
        turn_on ? playlists[:current].shuffle : playlists[:current].order
        return success(message: turn_on ? "Now we're shuffling!" : "Shuffle is now off")
      end
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def connect(cmd)
      path = cmd.params(:path).first
      name = cmd.params(:literal).first

      if path.nil?
        # with only literal parameter
        raise 'invalid parameter:missing parameters' if name.nil?

        # es una reconexion...
        drive = Drive.find_by(name: name.value)
        raise 'invalid name:the named drive doesnt exists' if drive.nil?

        if drive.connected
            failure(message: "What you mean? Drive 'name.value' is connected.")
        else
          if drive.update_attributes({connected: true})
            success(message: "Drive '#{name.value}' was reconnected.")
          else
            failure(message: "Something went wrong and I couldnt reconnect drive '#{name.value}'. Try again later please.")
          end
        end
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

    # For more information on this command refer to user manual or inline help in interactive mode.
    def disconnect(cmd)
      name = cmd.params(:literal).first.value
      drive = Drive.find_by(name: name)
      raise "Drive '#{name}' dont exist." if drive.nil?

      if drive.connected
        if drive.update(connected: false)
          success(message: "Drive '#{name}' is now disconnected.")
        else
          failure(message: "I cant disconnect drive '#{name}', something weird happened. Maybe if you again later works.")
        end
      else
        failure(message: "The drive '#{name}' is already disconnected.")
      end
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def ff(cmd)
      ff_in_secs = 10

      unless cmd.params(:number).empty?
        ff_in_secs = cmd.params(:number).first.value
      end

      ff_in_player ff_in_secs

      return success(message: "Fast Forwarded by #{ff_in_secs} secs")
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def fb(cmd)
      fb_in_secs = 10

      unless cmd.params(:number).empty?
        fb_in_secs = cmd.params(:number).first.value
      end

      fb_in_player fb_in_secs

      return success(message: "Fast Backwarded by #{fb_in_secs} secs")
    end

    # For more information on this command refer to user manual or inline help in interactive mode.
    def repeat(cmd)
      repeat_in_player
      return success(message: "Repeating " + current_song.to_s)
    end
  end
end

