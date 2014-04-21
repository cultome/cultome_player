require 'active_record'

module CultomePlayer
  module Objects
    # The ActiveRecord model for Genre objects.
    class Genre < ActiveRecord::Base
      has_and_belongs_to_many :songs

      def to_s
        str = c4(":::: Genre: ")
        str += c15(self.name)
        str += c4(" ::::")
      end
    end
  end
end