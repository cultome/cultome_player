require 'spec_helper'

describe CultomePlayer::Plugins::Alias do
	let(:t){ TestClass.new }

	it 'create an alias' do
		r = t.execute("alias play => p").first
		expect(r).to be_success
		t.plugin_config(:alias)['p'].should eq "play"
		expect(t).to receive(:play)
		t.execute("p")
	end

	it 'create an alias with params' do
		r = t.execute("alias 'search %1' => ss").first
		expect(r).to be_success
		t.plugin_config(:alias)['ss'].should eq "search %1"
		expect(t).to receive(:search)
		t.execute("ss my_param")
	end

	it 'respond to command_alias' do
		expect(t).to respond_to(:command_alias)
	end

	it 'respond to sintaxis_alias' do
		expect(t).to respond_to(:sintaxis_alias)
	end

	it 'respond to usage_alias' do
		expect(t).to respond_to(:usage_alias)
	end

	it 'respond to description_alias' do
		expect(t).to respond_to(:description_alias)
	end

end
