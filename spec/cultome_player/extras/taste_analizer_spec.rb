require 'spec_helper'

describe CultomePlayer::Extras::TasteAnalizer do

	let(:t){ Test.new }

	it 'register to listen for "similar" command' do
        t.event_listeners.should include(:next, :prev)
        t.event_listeners[:next].should include(:qualify_song_preference)
        t.event_listeners[:prev].should include(:qualify_song_preference)
	end

	it 'it call the callback on next or prev command execution' do
        t.should_receive(:qualify_song_preference).with([]).twice
        t.execute('play judas')
        t.execute('next')
        t.execute('prev')
    end

	it 'calculate preferences' do
        t.execute('play judas')
        t.execute('next')
        t.qualify_song_preference([]).should == 1
    end
end
