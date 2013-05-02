require 'spec_helper'
require 'plugins/gesture_analizer'

describe Plugin::GestureAnalizer do

	let(:g){ Plugin::GestureAnalizer.new(nil, {}) }

	it 'Should register for all events' do
		g.get_listener_registry.should include(:__ALL_VALIDS__)
	end

	it 'Should add an event to the queue' do
		queue = g.play([{type: :literal, value: 'hola'}])
		queue.has(1, :play).should be_true
		queue.has(2, :play).should be_false
	end

	it 'Should detect a sequence of events' do
		g.should_receive(:display).with("#### Notifying: Looking for something")
		5.times{ g.next }
	end
end
