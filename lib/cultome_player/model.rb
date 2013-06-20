# encoding: utf-8
require 'active_record'

module CultomePlayer
    module Model
        # The ActiveRecord model for Scrobbles objects.
        class Scrobble < ActiveRecord::Base
            attr_accessible :artist, :track, :timestamp, :scrobbled

            scope :pending, where(scrobbled: false).limit(50)
        end

        # The ActiveRecord model for Song objects.
        class Song < ActiveRecord::Base
            attr_accessible :name, :artist_id, :album_id, :year, :track, :duration, :relative_path, :drive_id, :points, :last_played_at

            belongs_to :artist
            belongs_to :album
            has_and_belongs_to_many :genres
            belongs_to :drive
            has_many :similars, as: :similar

            scope :connected, joins(:drive).where('drives.connected' => true)

            # Get the full path to the song file.
            #
            # @return [String] The full path to the song file.
            def path
                "#{self.drive.path}/#{self.relative_path}"
            end

            def to_s
                str = c4(":::: Song: ")
                str += c10(self.name)

                unless self.artist.nil?
                    str += c4(" \\ Artist: ")
                    str += c11(self.artist.name)
                end

                unless self.album.nil?
                    str += c4(" \\ Album: ")
                    str += c13(self.album.name)
                end
                str += c4(" ::::")
            end
        end

        # The ActiveRecord model for Artist objects.
        class Artist < ActiveRecord::Base
            attr_accessible :name, :id, :points

            has_many :songs
            has_many :albums, through: :songs
            has_many :similars, as: :similar

            def to_s
                str = c4(":::: Artist: ")
                str += c11(self.name)
                str += c4(" ::::")
            end
        end

        # The ActiveRecord model for Similar objects.
        class Similar < ActiveRecord::Base
            attr_accessible :track, :artist, :artist_url, :track_url, :similar_type

            belongs_to :similar, polymorphic: true

            def to_s
                str = c4(":::: ")
                if self.similar_type == 'CultomePlayer::Model::Song'
                    str += c4("Song: ")
                    str += c10(self.track)
                    str += c4(" \\ ")
                end
                str += c4("Artist: ")
                str += c11(self.artist)
                str += c4(" ::::")
            end
        end

        # The ActiveRecord model for Album objects.
        class Album < ActiveRecord::Base
            attr_accessible :name, :id, :points

            has_many :songs
            has_many :artists, through: :songs

            def to_s
                str = c4(":::: Album: ")
                str += c13(self.name)
                str += c4(" \\ Artist: ")
                unless self.artists.nil? || self.artists.empty?
                    str += c11(self.artists.uniq.collect{|a| a.name}.join(', '))
                end
                str += c4(" ::::")
            end
        end

        # The ActiveRecord model for Genre objects.
        class Genre < ActiveRecord::Base
            attr_accessible :name, :points

            has_and_belongs_to_many :songs

            def to_s
                str = c4(":::: Genre: ")
                str += c15(self.name)
                str += c4(" ::::")
            end
        end

        # The ActiveRecord model for Drive objects.
        class Drive < ActiveRecord::Base
            attr_accessible :name, :path, :connected

            has_many :songs

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
