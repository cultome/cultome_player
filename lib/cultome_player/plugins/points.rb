module CultomePlayer
  module Plugins
    module Points
      def init_plugin_points
        register_listener(:playback_finish){|song| on_playback_finish(song) }
        register_listener(:before_command_next){|cmd, res| on_before_change(cmd) }
        register_listener(:before_command_prev){|cmd, res| on_before_change(cmd) }
        register_listener(:after_command_prev){|cmd, res| on_after_prev(cmd, res) }
      end

      private

      def on_before_change(cmd)
        # current_song => the old song
        return if current_song.nil?

        percent_played = playback_position * 100 / playback_length
        gain = case percent_played
               when (10..50) then -1
               when (81..100) then 1
               else 0
               end

        update_points(gain)
      end

      def on_after_prev(cmd, response)
        # # current_song => the new song
        return if current_song.nil?

        if response.success?
          update_points(1)
        end
      end

      def on_playback_finish(song)
        update_points(1)
      end

      def update_points(diff)
        if current_song
          current_song.update(points: current_song.points + diff)
          current_song.artist.update(points: current_song.artist.points + diff) unless current_song.artist.nil?
          current_song.album.update(points: current_song.album.points + diff) unless current_song.album.nil?
          current_song.genres.each{|g| g.update(points: g.points + diff) } unless current_song.genres.nil?
        end
      end

    end
  end
end
