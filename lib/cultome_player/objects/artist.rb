require 'active_record'

module CultomePlayer
  module Objects
    # The ActiveRecord model for Artist objects.
    class Artist < ActiveRecord::Base
      has_many :songs
      has_many :albums, through: :songs
      has_many :similars, as: :similar

      def to_s
        str = c4(":::: Artist: ")
        str += c11(self.name)
        str += c4(" ::::")
      end
    end
  end
end