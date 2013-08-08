require 'spec_helper'

describe CultomePlayer::ExternalPlayer do

  HOST = 'localhost'
  PORT = 20103

  let(:t){ Test.new }

  context 'without external player already launched' do
    it 'raise an error if try to kill the player before launch' do
      expect{ t.kill_external_music_player }.to raise_error('There is no external player registered or and error ocurr when registering')
    end
  end

  context 'with external player already launched' do
    before :each do
      @pid = t.launch_external_music_player
    end

    after :each do
      t.kill_external_music_player if @pid
    end

    it 'launch the java music player' do
      @pid.should be_kind_of(Fixnum)
    end

    it 'update the state of player', resources: true do
      t.connect_external_music_player('localhost', 20103)
      sleep(0.5)

      t.player.state.should eq(:STOPPED)

      expect{
        t.play_in_external_player(CultomePlayer::Model::Song.first.path)
        sleep(1.0)
      }.to change{ t.player.state }.from(:STOPPED).to(:PLAYING)

      expect{
        t.pause_in_external_player
        sleep(1.0)
      }.to change{ t.player.state }.from(:PLAYING).to(:PAUSED)

      expect{
        t.resume_in_external_player
        sleep(0.5)
      }.to change{ t.player.state }.from(:PAUSED).to(:RESUMED)
    end

    it 'connect to a external player' do
      t.connect_external_music_player(HOST, PORT).should_not be_nil
    end

    it 'raise exception if a external player is aleady connected' do
      t.connect_external_music_player(HOST, PORT)
      expect { t.connect_external_music_player(HOST, PORT).should_not be_nil }.to raise_error('One external player is already connected')
    end

    it 'receive commands from external player' do
      t.should_receive(:external_player_data_in).at_least(1)

      t.connect_external_music_player(HOST, PORT)
      sleep(0.5)
      t.play_in_external_player(CultomePlayer::Model::Song.first.path)
      sleep(1.5)
    end

    it 'send play command to external player' do
      t.should_receive(:write_to_socket).with("play", "/home/user/music/01. Algodon.mp3")
      t.instance_eval{ @socket = "" }
      t.play_in_external_player('/home/user/music/01. Algodon.mp3')
    end
  end

  context 'with a player launched and connected' do

    before :each do
      t.instance_eval { @socket = "" }
      t.should_receive(:write_to_socket)
    end

    it 'send a play command to external player' do
      t.seek_in_external_player("path")
    end

    it 'send a seek command to external player' do
      t.seek_in_external_player(1212)
    end

    it 'send a pause command to external player' do
      t.pause_in_external_player
    end

    it 'send a resume command to external player' do
      t.resume_in_external_player
    end

    it 'send a stop command to external player' do
      t.stop_in_external_player
    end
  end
end
