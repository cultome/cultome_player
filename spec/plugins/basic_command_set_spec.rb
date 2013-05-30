require 'spec_helper'

describe Plugins::BasicCommandSet do

	let(:p){ Cultome::CultomePlayer.new }

	it 'Should generate an in-app help' do
		p.help.should_not be_nil
	end
end
