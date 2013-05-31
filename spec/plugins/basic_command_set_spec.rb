require 'spec_helper'
require 'plugins/basic_command_set'
require 'cultome_player'

describe Plugins::BasicCommandSet do

	let(:p){ Cultome::CultomePlayer.new }

	it 'Should generate an in-app help' do
		p.help.should_not be_nil
	end
end
