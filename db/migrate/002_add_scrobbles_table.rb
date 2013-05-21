
class AddScrobblesTable < ActiveRecord::Migration
  def self.up
    create_table :scrobbles do |t|
      t.string :track 
      t.string :artist
      t.string :timestamp
      t.boolean :scrobbled, default: false
    end
  end

  def self.down
    drop_table :scrobbles
  end
end
