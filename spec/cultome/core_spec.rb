require 'spec_helper'
require 'cultome/core'

class CultomePlayer 
	class Player
		def initialize(p)
		end
	end
end

describe CultomePlayer do

	let(:p){ CultomePlayer.new }

	it 'Should load every plugin in the folder lib/cultome/commands', java:true do
		p.load_commands
		p.instance_variable("@command_registry").should_not be_empty
	end

	it 'Should parse and dispatch to listeners the user command' do
		p.should_receive(:parse).with('play algodon').and_return([{
			command: :play,
			params: [{type: :literal, value: 'algodon'}]
		}])
		p.should_receive(:send_to_listeners)
		p.execute('play algodon')
	end

	it 'Should generate an in-app help' do
		p.help.should_not be_nil
	end

	it 'Should display messages' do
		p.display("message").should eq("message")
	end
end
