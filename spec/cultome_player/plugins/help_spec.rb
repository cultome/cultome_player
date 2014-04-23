require 'spec_helper'

class TestPlugin
	include CultomePlayer::Plugins::Help
end

describe CultomePlayer::Plugins::Help do
	let(:p){ TestPlugin.new }

	it 'respond to command_help' do
		p.should respond_to(:command_help)
	end

	it 'respond to usage_help' do
		p.should respond_to(:usage_help)
	end

	it 'respond to description_help' do
		p.should respond_to(:description_help)
	end
end