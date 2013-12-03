require 'spec_helper'

describe CultomePlayer::Player::Adapter::MPlayer do
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
    t.should_receive :start_player_with
    t.should_not be_player_running
    t.play_in_player song
  end

  it 'plays a song if there is one active playback' do
    t.should_receive(:send_to_player).with(/^loadfile/)
    t.should_receive(:send_to_player).with(/^get_time_length$/).exactly(2).times
    t.play_in_player song
    t.should be_player_running
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
      t.should_receive(:send_to_player).with("osd_show_text '=====  UNPAUSE  ====='")
      t.resume_in_player
    end

    it 'resume a stopped song' do
      t.stop_in_player
      t.should_receive(:start_player_with)
      t.play_in_player song
    end
  end
end
