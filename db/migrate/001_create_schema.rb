
class CreateSchema < ActiveRecord::Migration
  def self.up
    create_table :songs do |t|
      t.string :name # If I Had A Gun
      t.string :artist_id # Noel Gallagher
      t.string :album_id # High Flying Birds
      t.integer :year # 2011
      t.integer :track # 3
      t.integer :duration # 50070000
      t.timestamps
    end

    create_table :albums do |t|
      t.string :name
    end

    create_table :artists do |t|
      t.string :name
    end

    create_table :genres do |t|
      t.string :name
    end

    create_table :genres_songs, id: false do |t|
      t.integer :song_id
      t.integer :genre_id
    end
  end

  def self.down
    drop_table :songs
    drop_table :albums
    drop_table :artists
    drop_table :genres
    drop_table :genres_songs
  end
end

