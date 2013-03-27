
class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :songs do |t|
      t.string :name # If I Had A Gun
      t.integer :artist_id, default: 0 # Noel Gallagher
      t.integer :album_id, default: 0 # High Flying Birds
      t.integer :year # 2011
      t.integer :track # 3
      t.integer :duration # 50070000
      t.integer :drive_id
      t.string :relative_path
      t.integer :points
      t.timestamps
    end

    create_table :albums do |t|
      t.string :name
      t.integer :points
      t.timestamps
    end

    create_table :artists do |t|
      t.string :name
      t.integer :points
      t.timestamps
    end

    create_table :genres do |t|
      t.integer :points
      t.string :name
    end

    create_table :genres_songs, id: false do |t|
      t.integer :song_id
      t.integer :genre_id
    end

    create_table :drives do |t|
      t.string :name
      t.string :path
      t.timestamps
    end
  end

  def self.down
    drop_table :songs
    drop_table :albums
    drop_table :artists
    drop_table :genres
    drop_table :genres_songs
    drop_table :drives
  end
end

