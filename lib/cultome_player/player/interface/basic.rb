module CultomePlayer
  module Player
    module Interface
      module Basic

        # For more information on this command refer to user manual or inline help in interactive mode.
        def play(cmd)
          if cmd.params.empty?
            # Estos los consideramos comportamientos inteligentes
            # porque checan el contexto y toman una descision,
            # por lo tanto la logica no aplica a el comando play normal

            # tocar mientras ya estamos tocando algo??
            return failure("What you mean? Im already playing!") if playing?
            # quitamos la pausa
            return execute "pause off" if paused?
            # iniciamos ultima la reproduccion desde el principio
            if stopped? && current_song
              curr_song = player_object :song
              return execute "play @song"
            end
            # tocamos toda la libreria
            songs = whole_library
            return failure("No music connected! You should try 'connect /home/yoo/music => main' first") if songs.empty?
            playlists[:current, :focus] <= songs

          else # with parameters
            songs = select_songs_with cmd
            # checamos si el tipo de comando es para programar una
            # nueva playlist o solo para tocar una cancion
            if play_inline?(cmd)
              playlists[:queue] << songs
            else
              playlists[:current] <= songs
            end
          end
          
          return success(playlist: songs) + execute("next no_history").first
        end

        # For more information on this command refer to user manual or inline help in interactive mode.
        def pause(cmd)
          if cmd.params.empty?
            is_pause = !paused?
          else
            is_pause = cmd.params(:boolean).first.value
          end

          if is_pause
            pause_in_player
          else
            resume_in_player
          end

          success(message: is_pause ? "Holding your horses" : "Letting it flow", paused: paused?, stopped: stopped?, playing: playing?)
        end

        # For more information on this command refer to user manual or inline help in interactive mode.
        def stop(cmd)
          stop_in_player
          success(message: "Stoped it!", paused: paused?, stopped: stopped?, playing: playing?)
        end

        # For more information on this command refer to user manual or inline help in interactive mode.
        def next(cmd)
          unless cmd.params(:literal).any?{|p| p.value == 'no_history'}
            playlists[:history] << current_song
          end
          
          if playlists[:queue].empty?
            playlists[:queue] << playlists[:current].next
          end

          # aqui enviamos al reproductor externo a tocar
          play_queue
          return success(message: "Now playing #{current_song}", now_playing: current_song)
        end

        # For more information on this command refer to user manual or inline help in interactive mode.
        def prev(cmd)
          playlists[:queue] << playlists[:history].pop
          playlists[:current].rewind_by 1
          execute("next no_history")
        end

        # For more information on this command refer to user manual or inline help in interactive mode.
        def quit(cmd)
          quit_in_player
          terminate_session
          return success("See you next time!") unless in_session?
          return failure("Oops! You should use Ctr-c or throw water to the CPU NOW!!!!")
        end
      end
    end
  end
end
