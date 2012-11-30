require 'spec_helper'
require 'cultome'

class PlayerListener
end

class Player
end

describe CultomePlayer do

  let(:player) { CultomePlayer.new }
  before {
    Player.stub(:new)
    PlayerListener.stub(:new)
  }

  context '#execute' do
    it 'search' do
      player.should_receive(:search).with([])
      player.execute('search')
    end

    it 'search artista' do
      player.should_receive(:search).with([{:value=>"artista", :type=>:literal}])
      player.execute('search artista')
    end

    it 'search a:artista' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista", :type=>:criteria}])
      player.execute('search a:artista')
    end

    it 'search b:album' do
      player.should_receive(:search).with([{:criteria=>:b, :value=>"album", :type=>:criteria}])
      player.execute('search b:album')
    end

    it 'search s:rola' do
      player.should_receive(:search).with([{:criteria=>:s, :value=>"rola", :type=>:criteria}])
      player.execute('search s:rola')
    end

    it 'search artista album rola' do
      player.should_receive(:search).with([{:value=>"artista", :type=>:literal}, {:value=>"album", :type=>:literal}, {:value=>"rola", :type=>:literal}])
      player.execute('search artista album rola')
    end

    it 'search a:artista b:album s:rola' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista", :type=>:criteria}, {:criteria=>:b, :value=>"album", :type=>:criteria}, {:criteria=>:s, :value=>"rola", :type=>:criteria}])
      player.execute('search a:artista b:album s:rola')
    end

    it 'search a:artista1 a:artista2 a:artista3' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:criteria=>:a, :value=>"artista2", :type=>:criteria}, {:criteria=>:a, :value=>"artista3", :type=>:criteria}])
      player.execute('search a:artista1 a:artista2 a:artista3')
    end

    it 'search a:artista1 @playlist algo' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:value=>"playlist", :type=>:object}, {:value=>"algo", :type=>:literal}])
      player.execute('search a:artista1 @playlist algo')
    end
  end

  context '#search' do

    before{
      @s1 = Song.find(1) # name: "If a Had A Gun", artist_id: 1, album_id: 1
      @s2 = Song.find(2) # name: "The Death of You And Me", artist_id: 1, album_id: 1
      @s3 = Song.find(3) # name: "Paranoid", artist_id: 2, album_id: 2
      @s4 = Song.find(4) # name: "Stand By Me", artist_id: 3, album_id: 3
      @s5 = Song.find(5) # name: "Destination Calabria", artist_id: 0, album_id: 0
    }
    
    it 'no_args()' do
      r = player.search([])
      r.should == []
    end

    it 'artista' do
      r = player.search([{:value=>"Noel", :type=>:literal}])
      r.should == [@s1, @s2]
    end

    it 'a:artista' do
      r = player.search([{:criteria=>:a, :value=>"Black", :type=>:criteria}])
      r.should == [@s3]
    end

    it 'b:album' do
      r = player.search([{:criteria=>:b, :value=>"paranoid", :type=>:criteria}])
      r.should == [@s3]
    end

    it 's:rola' do
      r = player.search([{:criteria=>:s, :value=>"Stand", :type=>:criteria}])
      r.should == [@s4]
    end

    it 'artista album rola' do
      r = player.search([{:value=>"Noel", :type=>:literal}, {:value=>"paranoid", :type=>:literal}, {:value=>"Calabria", :type=>:literal}])
      r.should == [@s1, @s2, @s3, @s5]
    end

    it 'a:artista b:album s:rola' do
      r = player.search([{:criteria=>:a, :value=>"Noel", :type=>:criteria}, {:criteria=>:b, :value=>"High", :type=>:criteria}, {:criteria=>:s, :value=>"Death", :type=>:criteria}])
      r.should == [@s2]
    end

    it 'a:artista1 a:artista2 a:artista3' do
      r = player.search([{:criteria=>:a, :value=>"Noel", :type=>:criteria}, {:criteria=>:a, :value=>"Black", :type=>:criteria}, {:criteria=>:a, :value=>"oasis", :type=>:criteria}])
      r.should == [@s1, @s2, @s3, @s4]
    end

    xit 'a:artista1 @playlist algo' do
      r = player.search([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:value=>"playlist", :type=>:object}, {:value=>"algo", :type=>:literal}])
      r.should == []
    end
  end


end

# 'play'
# 'play 1'
# 'play 1 2 3'
# 'play @playlist'
# 'play @search'
# 'play @history' 
# 'play @artist' 
# 'play @album' 
# 'play artista'
# 'play a:artista'
# 'play b:album'
# 'play s:rola'
# 'play artista album rola' 
# 'play a:artista b:album s:rola' 
# 'show'
# 'show @song'
# 'show @playlist'
# 'show @history'
# 'show @search'
# 'show @album'
# 'show @artist'
# 'pause'
# 'stop'
# 'next'
# 'prev'
# 'search algo | play'
# 'search algo | play | show @artist'

# s5=Song.create(name: "Destination Calabria", artist_id: 0, album_id: 0, year: 0, track: 0, duration: 145

# where = "(artists.name like ? or albums.name like ? or songs.name like ?) or (artists.name like ? or albums.name like ? or songs.name like ?) or (artists.name like ? or albums.name like ? or songs.name like ?)"
# params = ["%Noel%", "%Noel%", "%Noel%", "%paranoid%", "%paranoid%", "%paranoid%", "%Calabria%", "%Calabria%", "%Calabria%"]
# songs = Song.joins("left outer join artists on artists.id == songs.artist_id").joins("left outer join albums on albums.id == songs.album_id").where(where, *params)
