require 'spec_helper'
require 'cultome/player_listener'

class Test
	include PlayerListener

	attr_accessor :song_status
	attr_accessor :status

	def initialize
		@song_status = nil
		@status = nil
	end

	def execute(input)
	end
end

describe PlayerListener do

	let(:l){ Test.new }

	it 'Should update the progress variable' do
		l.progress('uno', 'dos', 'tres', 'cuatro')
		l.song_status.should eq('cuatro')
	end

	it 'Should update state variable' do
		event = stub(code: 1)
		l.stateUpdated(event)
		l.status.should eq(:OPENED)
	end

	it 'Should call execute on EOM state' do
		l.should_receive(:execute).with('next')
		event = stub(code: 8)
		l.stateUpdated(event)
	end
end
