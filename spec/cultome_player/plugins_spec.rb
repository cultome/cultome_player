require 'spec_helper'

describe CultomePlayer::Plugins do
	let(:p){ TestClass.new }
	it 'check if plugins respond to a given command' do
		p.plugins_respond_to?("help").should be_true
		p.plugins_respond_to?("nonexistent").should_not be_true
	end

	it 'return the format for a command' do
		p.plugin_command_sintaxis("help").should be_instance_of Regexp
	end

	it 'call initializator for all the plugins' do
		p.should_receive(:init_plugin_points)
		p.init_plugins
	end
end