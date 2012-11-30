# encoding: UTF-8

require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new('logs/db.log')

ActiveRecord::Base.establish_connection(
    adapter: "jdbcsqlite3",
    database: "dev.sql"
)

class Song < ActiveRecord::Base
  attr_accessible :name, :artist_id, :album_id, :year, :track, :duration

  belongs_to :artist
  belongs_to :album
  has_and_belongs_to_many :genres
end

class Album < ActiveRecord::Base
  attr_accessible :name, :id

  has_many :songs
  has_one :artist, through: :songs
end

class Artist < ActiveRecord::Base
  attr_accessible :name, :id

  has_many :songs
  has_many :albums, through: :songs
end

class Genre < ActiveRecord::Base
  attr_accessible :name

  has_and_belongs_to_many :songs
end
