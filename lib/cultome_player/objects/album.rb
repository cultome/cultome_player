require 'active_record'

module CultomePlayer
  module Objects
    # The ActiveRecord model for Album objects.
    class Album < ActiveRecord::Base

      include CultomePlayer::Utils

      has_many :songs
      has_many :artists, through: :songs

      def to_s
        str = c4(":::: Album: ")
        str += c16(self.name)
        str += c4(" \\ Artist: ")
        unless self.artists.nil? || self.artists.empty?
          str += c11(self.artists.uniq.collect{|a| a.name}.join(', '))
        end
        str += c4(" ::::")
      end
    end
  end
end
