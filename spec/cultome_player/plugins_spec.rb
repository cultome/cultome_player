require 'spec_helper'

describe CultomePlayer::Plugins do
	let(:p){ TestClass.new }
	it 'check if plugins respond to a given command' do
		expect(p.plugins_respond_to?("help")).to be true
		expect(p.plugins_respond_to?("nonexistent")).not_to be true
	end

	it 'return the format for a command' do
		expect(p.plugin_command_sintax("help")).to be_instance_of Regexp
	end

	it 'call initializator for all the plugins' do
		expect(p).to receive(:init_plugin_points)
		p.init_plugins
	end
end
