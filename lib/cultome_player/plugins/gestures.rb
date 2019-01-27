module CultomePlayer
  module Plugins
    module Gestures

      include CultomePlayer::Objects

      def init_plugin_gestures
        register_listener(:after_command){|cmd, res| check_gesture(cmd) }
      end

      private

      def actions_history
        @history ||= []
      end

      def check_gesture(cmd)
        if cmd.history?
          actions_history << [cmd, Time.new]
          check_looking_for_something
        end
      end

      def recents(secs)
        return actions_history.select{|cmd, time| time >= Time.new - secs}
      end

      def check_looking_for_something
        if recents(60).count{|cmd, time| cmd.action == "next"} >= 5
          delete_from_history "next"
          suggest_songs
        end
      end

      def delete_from_history(cmd)
        actions_history.delete_if {|cmd, time| cmd.action == "next"}
      end

      def suggest_songs
        display "Hey! cant find anything? Try one of these:"
        suggestions = get_suggestions
        display to_display_list(suggestions)
        playlists[:focus] <= suggestions
        return suggestions
      end

      def select_suggestion
        return (1..10).to_a.sample(1).first
      end

      def get_suggestions
        id = select_suggestion
        if (1..7).cover?(id)
          criteria = case id
                     when 1 # los que tienen mas puntos
                       "points desc"
                     when 2 # los que tienen menos puntos
                       "points"
                     when 3 # las mas tocadas
                       "plays desc"
                     when 4 # los menos tocados
                       "plays"
                     when 5 # los agregados recientemente
                       "created_at desc"
                     when 6 # los recientemente tocados
                       "last_played_at"
                     when 7 # los recientemente tocados
                       "points desc, plays desc"
                     end

          return Song.order(criteria).limit(5).to_a

        else # mas complejos
          case (id)
          when 8 # Por artista popular
            artist = Artist.order("points desc").limit(5).sample(1).first
            return [] if artist.nil?
            return artist.songs.sample(5)
          when 9 # Por album popular
            album = Album.order("points desc").limit(5).sample(1).first
            return [] if album.nil?
            return album.songs.sample(5)
          else
            return Song.all.sample(5)
          end
        end
      end #sugestions
    end
  end
end
