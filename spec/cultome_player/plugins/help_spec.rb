require 'spec_helper'

describe CultomePlayer::Plugins::Help do
	let(:t){ TestClass.new }

	it 'respond to command_help' do
		t.should respond_to(:command_help)
	end

	it 'respond to sintaxis_help' do
		t.should respond_to(:sintaxis_help)
	end

	it 'respond to usage_help' do
		t.should respond_to(:usage_help)
	end

	it 'respond to description_help' do
		t.should respond_to(:description_help)
	end
end