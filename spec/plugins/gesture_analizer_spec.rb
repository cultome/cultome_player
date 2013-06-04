require 'spec_helper'
require 'plugins/gesture_analizer'

describe Plugins::GestureAnalizer do

	let(:p){ Cultome::CultomePlayer.new }
	let(:g){ Plugins::GestureAnalizer }

	it 'Should register for all events' do
		g.get_listener_registry.should include(:__ALL_VALIDS__)
	end

	it 'Should add an event to the queue' do
        with_connection do
            p.execute('play')
            queue = g.gesture(p)
            queue.has(1, :play).should be_true
            queue.has(2, :play).should be_false
        end
	end

	it 'Should detect a sequence of events' do
		g.should_receive(:display).at_least(1)
        with_connection do
            p.execute('play')
            6.times{ p.execute('next') }
        end
	end
end
