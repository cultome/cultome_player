require 'spec_helper'

include CultomePlayer::Objects

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  before :each do
    Drive.create!(id: 1, name: 'test', path: '/patito', connected: true)
    Song.create!(id: 1, name: "song_uno",    artist_id: 1, album_id: 1, drive_id: 1, relative_path: "uno/uno.mp3") 
    Song.create!(id: 2, name: "song_dos",    artist_id: 1, album_id: 2, drive_id: 1, relative_path: "uno/dos/dos.mp3")
    Song.create!(id: 3, name: "song_tres",   artist_id: 1, album_id: 2, drive_id: 1, relative_path: "uno/dos/tres/tres.mp3")
    Song.create!(id: 4, name: "song_cuatro", artist_id: 2, album_id: 3, drive_id: 1, relative_path: "fake/cuatro.mp3")
    Song.create!(id: 5, name: "song_cinco",  artist_id: 3, album_id: 4, drive_id: 1, relative_path: "fake/cinco.mp3")

    Artist.create!(id: 1, name: "artist_uno")
    Artist.create!(id: 2, name: "artist_dos")
    Artist.create!(id: 3, name: "artist_tres")
    Artist.create!(id: 4, name: "artist_cuatro")

    Album.create!(id: 1, name: "album_uno")
    Album.create!(id: 2, name: "album_dos")
    Album.create!(id: 3, name: "album_tres")
    Album.create!(id: 4, name: "album_cuatro")
  end

  it 'return a Response object' do
    t.execute('search a:artist_uno').should be_instance_of Response
  end

  it 'respond with a list when results are found in the message property'

  it 'respond success when there are results' do
    r = t.execute('search a:artist_uno')
    r.should be_success
    r.should respond_to :songs
  end

  it 'respond failure when there are not results' do
    r = t.execute('search a:nothing')
    r.should be_failure
    r.should respond_to :message
  end

  context 'with criteria parameters' do
    it 'different criterias create an AND filter' do
      r = t.execute 'search a:artist_uno b:album_dos'
      songs = r.send(r.response_type)
      songs.should have(2).items
      songs.each{|s| s.artist.name.should match /uno/ }
      songs.each{|s| s.album.name.should match /dos/ }
    end

    it 'same criterias create an OR filter' do
      r = t.execute 'search a:artist_dos a:artist_tres'
      songs = r.send(r.response_type)
      songs.should have(2).songs
      songs.each{|s| s.artist.name.should match /(dos|tres)/ }
    end
  end

  context 'with object parameters' do
    it 'search using an object as criteria' do
      r = t.execute 'search @artist'
      songs = r.send(r.response_type)
      songs.should have(3).item
      songs.each{|s| s.artist.name.should eq t.current_artist.name }
    end

    it 'create and OR filter more than one object' do
      t.execute('search @artist @album').should have(4).songs
    end
  end

  context 'with literal parameters' do
    it 'create an OR filter with the fields trackname, artist and album' do
      t.execute('search song_cuatro song_cinco').should have(2).songs
      t.execute('search song_uno song_dos').should have(2).songs
      t.execute('search album_dos cinco').should have(3).songs
      t.execute('search cinco').should have(1).songs
    end
  end

  context 'with mixed parameters' do
    it 'create an OR filter between each type' do
      t.execute('search t:song_tres artist_tres @album').should have(3).songs
      t.execute('search t:song_cuatro t:song_dos @album').should have(2).songs
      t.execute('search song_dos song_uno').should have(2).songs
      t.execute('search @artist song_tres').should have(3).songs
    end
  end
end
