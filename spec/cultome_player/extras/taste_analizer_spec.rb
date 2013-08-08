require 'spec_helper'

describe CultomePlayer::Extras::TasteAnalizer do

  let(:t){ Test.new }

  before :each do
    t.turn_shuffle :off
    t.execute('play judas')
    t.execute('next')
  end

  it 'register to listen for "similar" command' do
    t.event_listeners.should include(:next, :prev)
    t.event_listeners[:next].should include(:qualify_song_preference)
    t.event_listeners[:prev].should include(:qualify_song_preference)
  end

  it 'it call the callback on next command execution' do
    t.should_receive(:qualify_song_preference).with([]).once
    t.execute('next')
  end

  it 'it call the callback on prev command execution' do
    t.should_receive(:qualify_song_preference).with([]).once
    t.execute('prev')
  end

  it 'calculate preferences on next command' do
    t.execute('next')
    t.qualify_song_preference([]).should > 0
  end

  it 'calculate preferences on prev command' do
    t.execute('prev')
    t.player.song_status = {seconds: 350}
    t.qualify_song_preference([]).should > 0
  end

  it 'calculate preferences' do
    t.qualify_song_preference([]).should == 1
  end

  it "calculate preferences when the song's playback is between 60% and 90%" do
    t.player.song_status = {seconds: 350}
    t.qualify_song_preference([]).should == 3
  end
end
