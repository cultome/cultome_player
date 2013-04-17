# encoding: UTF-8

require 'cultome/helper'
require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(
	adapter: db_adapter,
	database: db_file
)
ActiveRecord::Base.logger = Logger.new(File.open(db_log_path, 'a'))

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
		str = ":::: Song: #{self.name}"
		str += " \\ Artist: #{self.artist.name}" unless self.artist.nil?
		str += " \\ Album: #{self.album.name}" unless self.album.nil?
		str += " ::::"
	end
end

# The ActiveRecord model for Artist objects.
class Artist < ActiveRecord::Base
	attr_accessible :name, :id, :points

	has_many :songs
	has_many :albums, through: :songs
	has_many :similars, as: :similar

	def to_s
		":::: Artist: #{self.name} ::::"
	end
end

# The ActiveRecord model for Similar objects.
class Similar < ActiveRecord::Base
	attr_accessible :track, :artist, :artist_url, :track_url, :type

	belongs_to :similar, polymorphic: true

	def to_s
		str = ":::: "
		str += "Song: #{self.track} \\ " if self.type == 'track'
		str += "Artist: #{self.artist} ::::"
	end
end

# The ActiveRecord model for Album objects.
class Album < ActiveRecord::Base
	attr_accessible :name, :id, :points

	has_many :songs
	has_many :artists, through: :songs

	def to_s
		str = ":::: Album: #{self.name}" 
		str += " \\ Artist: #{self.artists.uniq.collect{|a| a.name}.join(', ')}" unless self.artists.nil? || self.artists.empty?
		str += " ::::"
	end
end

# The ActiveRecord model for Genre objects.
class Genre < ActiveRecord::Base
	attr_accessible :name, :points

	has_and_belongs_to_many :songs

	def to_s
		":::: Genre: #{self.name} ::::"
	end
end

# The ActiveRecord model for Drive objects.
class Drive < ActiveRecord::Base
	attr_accessible :name, :path, :connected

	has_many :songs

	def to_s
		":::: Drive: #{self.name} => #{self.songs.size} songs => #{self.path} => #{connected ? "Online" : "Offline"} ::::"
	end
end

