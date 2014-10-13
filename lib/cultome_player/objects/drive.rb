require 'active_record'

module CultomePlayer
  module Objects
    # The ActiveRecord model for Drive objects.
    class Drive < ActiveRecord::Base

      include CultomePlayer::Utils

      has_many :songs

      def connected?
        connected
      end

      def to_s
        str = c4(":::: Drive: ")
        str += c14(self.name)
        str += c4(" => ")
        str += c14(self.songs.size.to_s)
        str += c4(" songs => ")
        str += c14(self.path)
        str += c4(" => ")
        str += connected ? c3("Online") : c2("Offline")
        str += c4(" ::::")
      end
    end
  end
end
