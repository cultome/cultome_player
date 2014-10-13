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
    r = t.execute("connect '#{test_folder}' => test").first
    expect(r.files_detected).to eq 3
  end

  it 'import the files not imported before and update the rest' do
    r = t.execute("connect '#{test_folder}' => test").first
    expect(r.files_detected).to eq 3
    expect(r.files_updated).to eq 2
    expect(r.files_imported).to eq 1
  end

  context 'with only a literal parameter' do
    it 'connect the named drive if exist' do
      Drive.create!(name: "test", path: test_folder, connected: false)
      expect(Drive.find_by(name: 'test')).not_to be_connected
      r = t.execute("connect test").first
      expect(Drive.find_by(name: 'test')).to be_connected
    end

    it 'raise an error if drive not exists' do
      r = t.execute("connect ghost").first
      expect(r.message).to eq 'invalid name'
      expect(r.details).to eq 'the named drive doesnt exists'
    end
  end

  context 'with a path and a literal' do
    it 'create the drive if not exists' do
      expect(Drive.find_by(name: 'new')).to be_nil
      r = t.execute("connect '#{test_folder}' => new").first
      expect(Drive.find_by(name: 'new')).not_to be_nil
      expect(r.drive_updated).to be false
    end

    it 'update the drive if exists' do
      Drive.create!(name: "test", path: test_folder)
      r = t.execute("connect '#{test_folder}' => test").first
      expect(r.drive_updated).to be true
    end

    it 'raise an error if path is invalid' do
      r = t.execute('connect /invalid => ghost').first
      expect(r.message).to eq 'invalid path'
      expect(r.details).to eq 'the directory is invalid'
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
          r = t2.execute("connect '#{test_folder}/uno/dos/tres' => test").first
          expect(r.files_imported).to eq 1
          expect(r.files_updated).to eq 0
          @track = Song.all.first
        end

        it 'insert the correct song information' do
          expect(@track.name).to eq "Sing For Absolution"
          expect(@track.year).to eq 2003
          expect(@track.track).to eq 4
          expect(@track.duration).to eq 295
          expect(@track.relative_path).to eq "tres.mp3"
          # dependencias
          expect(@track.artist_id).to eq 1
          expect(@track.album_id).to eq 1
          expect(@track.drive_id).to eq 1
        end

        it 'insert the correct artist information' do
          expect(@track.artist.name).to eq "Muse"
        end

        it 'insert the correct album information' do
          expect(@track.album.name).to eq "Absolution"
          expect(@track.album.artists.first.name).to eq "Muse"
        end
      end
    end
  end
end
