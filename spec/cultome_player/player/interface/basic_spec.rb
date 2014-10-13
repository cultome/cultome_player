require 'spec_helper'

describe CultomePlayer::Player::Interface::Basic do
  let(:t){ TestClass.new }

  describe '#pause' do
    it 'calls the underliying player' do
      expect(t).to receive(:pause_in_player)
      t.execute "pause on"
    end

    it 'respond to description_help' do
      expect(t).to respond_to(:description_help)
    end

    it 'respond to usage_help' do
      expect(t).to respond_to(:usage_help)
    end

    it 'respond with Response object' do
      expect(t.execute("pause on").first).to be_instance_of Response
    end
  end

  describe '#stop' do
    before :each do
      t.execute "connect '#{test_folder}' => test"
    end

    it 'calls the underliying player' do
      expect(t).to receive(:stop_in_player)
      t.execute "play"
      t.execute "stop"
    end

    it 'respond to description_stop' do
      expect(t).to respond_to(:description_stop)
    end

    it 'respond to usage_stop' do
      expect(t).to respond_to(:usage_stop)
    end

    it 'respond with Response object' do
      expect(t.execute("stop").first).to be_instance_of Response
    end
  end

  describe '#play' do

    it 'respond to description_play' do
      expect(t).to respond_to(:description_play)
    end

    it 'respond to usage_play' do
      expect(t).to respond_to(:usage_play)
    end

    it 'respond with Response object' do
      expect(t.execute("play").first).to be_instance_of Response
    end

    context 'without music connected' do
      it 'advise to connect music first if no music is connected' do
        r = t.execute("play").first
        expect(r.message).to match /No music connected! You should try 'connect \/home\/yoo\/music => main' first/
      end
    end

    context 'with music connected' do
      before :each do
        t.execute "connect '#{test_folder}' => test"
      end

      it 'calls the underliying player to play' do
        expect(t).to receive(:play_in_player)
        t.execute 'play'
      end

      it 'calls the underliying player to resume playback' do
        expect(t).to receive(:resume_in_player)
        t.execute 'play'
        t.execute "pause on"
        t.execute 'play'
      end

      context 'without parameters' do
        it 'in clean state should play all the library' do
          r = t.execute('play').first
          expect(r.playlist.size).to eq(3)
          expect(r).to respond_to(:now_playing)
          expect(r).to respond_to(:playlist)
          expect(t.current_playlist.songs.size).to eq(3)
          expect(t.current_song).not_to be_nil
        end

        it 'if paused should resume playback' do
          t.execute "pause on"
          expect(t).to be_paused
          t.execute 'play'
          expect(t).not_to be_paused
        end

        it 'if stopped should resume last playback from the begin' do
          t.execute "play"
          my_song = t.current_song
          t.execute "stop"
          expect(t).to be_stopped
          t.execute 'play'
          expect(t).to be_playing
          expect(my_song).to eq t.current_song
        end

        it 'get an error message if playing' do
          t.execute 'play'
          r = t.execute('play').first
          expect(r.message).to match /What you mean\? Im already playing!/
        end
      end

      context 'with number parameter' do
        it 'play the nth element in focus list without altering the current playlist' do
          t.execute 'search a'
          t.execute 'play 2'
          expect(t.current_song.name).to eq t.playlists[:focus].at(1).name
        end
      end

      context 'with criteria parameter' do
        it 'different criterias create an AND filter' do
          t.execute "play t:a"
          expect(t.current_playlist.songs.size).to eq(2)
          t.execute "play t:a a:m"
          expect(t.current_playlist.songs.size).to eq(1)
        end

        it 'same criterias create an OR filter' do
          t.execute "play t:a"
          expect(t.current_playlist.songs.size).to eq(2)
          t.execute "play t:a t:d"
          expect(t.current_playlist.songs.size).to eq(3)
        end
      end

      context 'with object parameter' do
        it 'replace the current playlist with the object content' do
          t.execute 'play'
          expect(t.current_playlist.songs.size).to eq(3)
          t.execute 'next'
          t.execute 'next'
          t.execute 'play @history'
          expect(t.current_playlist.songs.size).to eq(2)
        end
      end

      context 'with literal parameter' do
        it 'create an OR filter with the fields trackname, artist and album' do
          t.execute 'play way'
          expect(t.current_playlist.songs.size).to eq(1)
          t.execute 'play sing'
          expect(t.current_playlist.songs.size).to eq(1)
          t.execute 'play sing way'
          expect(t.current_playlist.songs.size).to eq(2)
        end
      end
    end
  end
end
