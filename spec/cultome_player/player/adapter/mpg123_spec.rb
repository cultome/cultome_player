require 'spec_helper'

describe CultomePlayer::Player::Adapter::Mpg123 do
  let(:t){ TestClass.new }
  let(:song) do
    s = Song.new
    s.stub(:path){'/duck/path'}
    s
  end

  it 'can check if player is running' do
    t.should respond_to :player_running?
  end

  it 'start the player if is not running' do
    t.should_receive :start_player
    t.should_not be_player_running
    t.play_in_player song
  end

  context 'with active playback' do
    before :each do
      t.play_in_player song
    end

    it 'pause a song' do
      t.should_receive(:send_to_player).with('pause')
      t.pause_in_player
    end

    it 'stops a song' do
      t.should_receive(:send_to_player).with('stop')
      t.stop_in_player
    end

    it 'resume a paused song' do
      t.pause_in_player
      t.should_receive(:send_to_player).with("pause")
      t.resume_in_player
    end

    it 'resume a stopped song' do
      t.stop_in_player
      t.should_receive(:start_player)
      t.play_in_player song
    end
  end

  context 'running actual mpg123 player', mplayer: true do
    it 'dont show the initial text from mpg123' do
      th = Thread.new do
        class MplayerTest
          include CultomePlayer
        end

        song1 = double(:song1, path: "/home/csoria/music/unknown/Torches/02 Pumped Up Kicks.mp3")
        song2 = double(:song2, path: "/home/csoria/music/unknown/Torches/07 Houdini.mp3")
        p = MplayerTest.new
        p.prepare_environment(:rspec)
        p.recreate_db_schema

        puts "Primera cancion..."
        p.play_in_player(song1)
        i = 0
        while i < 3
          sleep 1
          i += 1
        end

        puts "Segunda cancion(running: #{p.player_running?})..."
        p.play_in_player(song2)
        i = 0
        while i < 3
          sleep 1
          i += 1
        end
        puts "Terminado!"
      end # Thread

      th.join
    end
  end
end
