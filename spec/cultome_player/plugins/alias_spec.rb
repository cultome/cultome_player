require 'spec_helper'

describe CultomePlayer::Plugins::Alias do
	let(:t){ TestClass.new }

	it 'create an alias' do
		r = t.execute("alias play => p")
		r.should be_success
		t.plugin_config(:alias)['p'].should eq "play"
		t.should_receive(:play)
		t.execute("p")
	end

	it 'create an alias with params' do
		r = t.execute("alias 'search %1' => p")
		r.should be_success
		t.plugin_config(:alias)['p'].should eq "search %1"
		t.should_receive(:search)
		t.execute("p my_param")
	end

	it 'respond to command_alias' do
		t.should respond_to(:command_alias)
	end

	it 'respond to sintaxis_alias' do
		t.should respond_to(:sintaxis_alias)
	end

	it 'respond to usage_alias' do
		t.should respond_to(:usage_alias)
	end

	it 'respond to description_alias' do
		t.should respond_to(:description_alias)
	end

end