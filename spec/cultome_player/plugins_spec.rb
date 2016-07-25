require 'spec_helper'

describe CultomePlayer::Plugins do
  let(:t){ TestClass.new }
  it 'check if plugins respond to a given command' do
    expect(t.plugins_respond_to?("help")).to be true
    expect(t.plugins_respond_to?("nonexistent")).not_to be true
  end

  it 'return the format for a command' do
    expect(t.plugin_command_sintax("help")).to be_instance_of Regexp
  end

  it 'call initializator for all the plugins' do
    expect(t).to receive(:init_plugin_points)
    t.init_plugins
  end

  context 'for included plugins' do
    describe CultomePlayer::Plugins::Alias do
      it 'respond to usage_alias' do
        expect(t).to respond_to(:usage_alias)
      end

      it 'returns usage information' do
        expect(t.usage_alias).not_to be_empty
      end
    end
  end
end
