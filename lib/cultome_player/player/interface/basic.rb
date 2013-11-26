module CultomePlayer
  module Player
    module Interface
      module Basic

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
            playlists[:current, :focus] <= songs

          else
            songs = select_songs_with cmd
            # checamos si el tipo de comando es para programar una
            # nueva playlist o solo para tocar una cancion
            if play_inline?(cmd)
              playlists[:queue] << songs
            else
              playlists[:current] <= songs
            end
          end

          return success(playlist: songs) + execute("next no_history")
        end

        def pause(cmd)
          if cmd.params.empty?
            is_pause = !@paused
          else
            is_pause = cmd.params(:boolean).first.value
          end

          if is_pause 
            pause_in_player
          else
            resume_in_player
          end

          success(paused: paused?, stopped: stopped?, playing: playing?)
        end

        def stop(cmd)
          stop_in_player
          success(paused: paused?, stopped: stopped?, playing: playing?)
        end

        def next(cmd)
          if playlists[:queue].empty?
            unless cmd.params(:literal).any?{|p| p.value == 'no_history'}
              playlists[:history] << current_song
            end
            playlists[:queue] << playlists[:current].next
          end

          # aqui enviamos al reproductor externo a tocar
          play_queue

          return success(now_playing: current_song)
        end

        def prev(cmd)
        end

        def quit(cmd)
        end
      end
    end
  end
end