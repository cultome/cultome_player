require 'spec_helper'

include CultomePlayer::Objects

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  before :each do
    Song.create!(id: 1, name: "song_uno",    artist_id: 1, album_id: 1, drive_id: 1, relative_path: "uno/uno.mp3") 
    Song.create!(id: 2, name: "song_dos",    artist_id: 1, album_id: 1, drive_id: 1, relative_path: "uno/dos/dos.mp3")

    Artist.create!(id: 1, name: "artist_uno")

    Album.create!(id: 1, name: "album_uno")
  end

  it 'detect all the files in the subdirectories' do
    r = t.execute "connect '#{test_folder}' => test"
    r.files_detected.should eq 3
  end

  it 'import the files not imported before and update the rest' do
    r = t.execute "connect '#{test_folder}' => test"
    r.files_detected.should eq 3
    r.files_updated.should eq 2
    r.files_imported.should eq 1
  end

  context 'with only a literal parameter' do
    it 'connect the named drive if exist' do
      Drive.create!(name: "test", path: test_folder, connected: false)
      Drive.find_by(name: 'test').should_not be_connected
      r = t.execute "connect test"
      Drive.find_by(name: 'test').should be_connected
    end

    it 'raise an error if drive not exists' do
      r = t.execute("connect ghost")
      r.message.should eq 'invalid name'
      r.details.should eq 'the named drive doesnt exists'
    end
  end

  context 'with a path and a literal' do
    it 'create the drive if not exists' do
      Drive.find_by(name: 'new').should be_nil
      r = t.execute "connect '#{test_folder}' => new"
      Drive.find_by(name: 'new').should_not be_nil
      r.drive_updated.should be_false
    end

    it 'update the drive if exists' do
      Drive.create!(name: "test", path: test_folder)
      r = t.execute "connect '#{test_folder}' => test"
      r.drive_updated.should be_true
    end

    it 'raise an error if path is invalid' do
      r = t.execute('connect /invalid => ghost')
      r.message.should eq 'invalid path'
      r.details.should eq 'the directory is invalid'
    end
  end

  describe 'with mp3 files' do
    let(:t2){ TestClass.new }

    before :each do
      Drive.create!(name: "library", path: test_folder)
    end

    describe 'create information from file' do
      it 'create the song' do
        expect{ t2.execute "connect '#{test_folder}' => test" }.to change{ Song.all.count }.by(1)
      end

      it 'create the artist' do
        expect{ t2.execute "connect '#{test_folder}' => test" }.to change{ Artist.all.count }.by(2) # una de las rolas no tiene artist
      end

      it 'create the album' do
        expect{ t2.execute "connect '#{test_folder}' => test" }.to change{ Album.all.count }.by(2) # una de las rolas no tiene album
      end

      context 'already imported into library' do
        before :each do
          DatabaseCleaner.clean_with(:truncation)
          r = t2.execute "connect '#{test_folder}/uno/dos/tres' => test"
          r.files_imported.should eq 1
          r.files_updated.should eq 0
          @track = Song.all.first
        end

        it 'insert the correct song information' do
          @track.name.should eq "Sing For Absolution"
          @track.year.should eq 2003
          @track.track.should eq 4
          @track.duration.should eq 295
          @track.relative_path.should eq "tres.mp3"
          # dependencias
          @track.artist_id.should eq 1
          @track.album_id.should eq 1
          @track.drive_id.should eq 1
        end

        it 'insert the correct artist information' do
          @track.artist.name.should eq "Muse"
        end

        it 'insert the correct album information' do
          @track.album.name.should eq "Absolution"
          @track.album.artists.first.name.should eq "Muse"
        end
      end
    end
  end
end
