require 'active_record'

module CultomePlayer
  module Objects

    # The ActiveRecord model for Song objects.
    class Song < ActiveRecord::Base

      include CultomePlayer::Utils

      belongs_to :artist
      belongs_to :album
      has_and_belongs_to_many :genres
      belongs_to :drive
      has_many :similars, as: :similar

      scope :connected, -> {joins(:drive).where('drives.connected' => true)}

      # Get the full path to the song file.
      #
      # @return [String] The full path to the song file.
      def path
        File.join(self.drive.path, self.relative_path)
      end

      def to_s
        str = c4(":::: Song: ")
        str += c14(self.name)

        unless self.artist.nil?
          str += c4(" \\ Artist: ")
          str += c15(self.artist.name)
        end

        unless self.album.nil?
          str += c4(" \\ Album: ")
          str += c16(self.album.name)
        end
        str += c4(" ::::")
      end
    end
  end
end
