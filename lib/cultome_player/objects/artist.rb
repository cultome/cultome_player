require 'active_record'

module CultomePlayer
  module Objects
    # The ActiveRecord model for Artist objects.
    class Artist < ActiveRecord::Base

      include CultomePlayer::Utils

      has_many :songs
      has_many :albums, through: :songs
      has_many :similars, as: :similar

      def to_s
        str = c4(":::: Artist: ")
        str += c15(self.name)
        str += c4(" ::::")
      end

      def readonly?
        false
      end
    end
  end
end
