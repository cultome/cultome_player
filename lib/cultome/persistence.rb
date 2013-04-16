# encoding: UTF-8

require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new('logs/db.log')

ActiveRecord::Base.establish_connection(
	adapter: "jdbcsqlite3",
	database: "dev.sql"
)

class Cultome::Song < ActiveRecord::Base
	attr_accessible :name, :artist_id, :album_id, :year, :track, :duration, :relative_path, :drive_id, :points, :last_played_at

	belongs_to :artist
	belongs_to :album
	has_and_belongs_to_many :genres
	belongs_to :drive
	has_many :similars, as: :similar

	scope :connected, joins(:drive).where('drives.connected' => true)

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

class Cultome::Artist < ActiveRecord::Base
	attr_accessible :name, :id, :points

	has_many :songs
	has_many :albums, through: :songs
	has_many :similars, as: :similar

	def to_s
		":::: Artist: #{self.name} ::::"
	end
end

class Cultome::Similar < ActiveRecord::Base
	attr_accessible :track, :artist, :artist_url, :track_url, :type

	belongs_to :similar, polymorphic: true

	def to_s
		str = ":::: "
		str += "Song: #{self.track} \\ " if self.type == 'track'
		str += "Artist: #{self.artist} ::::"
	end
end

class Cultome::Album < ActiveRecord::Base
	attr_accessible :name, :id, :points

	has_many :songs
	has_many :artists, through: :songs

	def to_s
		str = ":::: Album: #{self.name}" 
		str += " \\ Artist: #{self.artists.uniq.collect{|a| a.name}.join(', ')}" unless self.artists.nil? || self.artists.empty?
		str += " ::::"
	end
end

class Cultome::Genre < ActiveRecord::Base
	attr_accessible :name, :points

	has_and_belongs_to_many :songs

	def to_s
		":::: Genre: #{self.name} ::::"
	end
end

class Cultome::Drive < ActiveRecord::Base
	attr_accessible :name, :path, :connected

	has_many :songs

	def to_s
		":::: Drive: #{self.name} => #{self.songs.size} songs => #{self.path} => #{connected ? "Online" : "Offline"} ::::"
	end
end
