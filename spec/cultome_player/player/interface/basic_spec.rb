require 'spec_helper'

describe CultomePlayer::Player::Interface::Basic do
  let(:t){ TestClass.new }

  describe '#pause' do
    it 'calls the underliying player' do
      t.should_receive(:pause_in_player)
      t.execute "pause on"
    end
  end

  describe '#stop' do
    before :each do
      t.execute "connect '#{test_folder}' => test"
    end

    it 'calls the underliying player' do
      t.should_receive(:stop_in_player)
      t.execute "play"
      t.execute "stop"
    end
  end

  describe '#play' do
    context 'without music connected' do
      it 'advise to connect music first if no music is connected' do
        r = t.execute("play")
        r.message.should eq "No music connected! You should try 'connect /home/yoo/music => main' first"
      end
    end

    context 'with music connected' do
      before :each do
        t.execute "connect '#{test_folder}' => test"
      end

      it 'calls the underliying player to play' do
        t.should_receive(:play_in_player)
        t.execute 'play'
      end

      it 'calls the underliying player to resume playback' do
        t.should_receive(:resume_in_player)
        t.execute 'play'
        t.execute "pause on"
        t.execute 'play'
      end

      context 'without parameters' do
        it 'in clean state should play all the library' do
          r = t.execute 'play'
          r.playlist.should have(3).items
          r.should respond_to(:now_playing)
          r.should respond_to(:playlist)
          t.current_playlist.to_a.should have(3).items
          t.current_song.should_not be_nil
        end

        it 'if paused should resume playback' do
          t.execute "pause on"
          t.should be_paused
          t.execute 'play'
          t.should_not be_paused
        end

        it 'if stopped should resume last playback from the begin' do
          t.execute "play"
          my_song = t.current_song
          t.execute "stop"
          t.should be_stopped
          t.execute 'play'
          t.should be_playing
          my_song.should eq t.current_song
        end

        it 'get an error message if playing' do
          t.execute 'play'
          r = t.execute 'play'
          r.message.should eq 'What you mean? Im already playing!'
        end
      end

      context 'with number parameter' do
        it 'play the nth element in focus list without altering the current playlist' do
          t.execute 'search a'
          t.execute 'play 2'
          t.current_song.name.should eq t.playlists[:focus].at(1).name
        end
      end

      context 'with criteria parameter' do
        it 'different criterias create an AND filter' do
          t.execute "play t:a"
          t.current_playlist.should have(2).songs
          t.execute "play t:a a:m"
          t.current_playlist.should have(1).songs
        end

        it 'same criterias create an OR filter' do
          t.execute "play t:a"
          t.current_playlist.should have(2).songs
          t.execute "play t:a t:d"
          t.current_playlist.should have(3).songs
        end
      end

      context 'with object parameter' do
        it 'replace the current playlist with the object content' do
          t.execute 'play'
          t.current_playlist.should have(3).songs
          t.execute 'next'
          t.execute 'next'
          t.execute 'play @history'
          t.current_playlist.should have(2).songs
        end
      end

      context 'with literal parameter' do
        it 'create an OR filter with the fields trackname, artist and album' do
          t.execute 'play way'
          t.current_playlist.should have(1).songs
          t.execute 'play sing'
          t.current_playlist.should have(1).songs
          t.execute 'play sing way'
          t.current_playlist.should have(2).songs
        end
      end
    end
  end
end
