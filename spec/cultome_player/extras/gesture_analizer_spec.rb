require 'spec_helper'

describe CultomePlayer::Extras::GestureAnalizer do

    before :all do
        @t = Test.new
        @t.execute('play tings')
    end

    it 'add an event to the queue' do
        @t.user_actions.should have(1).actions_with(:play)
    end

    it 'detect a sequence of events' do
        @t.should_receive(:display).with("#### Notifying: Looking for something")
        6.times{ @t.execute('next') }
    end
end
