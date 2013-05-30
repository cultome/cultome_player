require 'spec_helper'

describe CultomePlayer do

	let(:p){ Cultome::CultomePlayer.new }

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
		with_connection { p.execute('play algodon') }
	end
end
