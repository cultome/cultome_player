require 'spec_helper'

describe CultomePlayer::Plugins::Alias do
	let(:t){ TestClass.new }

	it 'create an alias' do
		r = t.execute("alias play => p").first
		expect(r).to be_success
		expect(t.plugin_config(:alias)['p']).to eq "play"
		expect(t).to receive(:play)
		t.execute("p")
	end

	it 'create an alias with params' do
		r = t.execute("alias 'search %1' => ss").first
		expect(r).to be_success
		expect(t.plugin_config(:alias)['ss']).to eq "search %1"
		expect(t).to receive(:search)
		t.execute("ss my_param")
	end

  it 'check existing aliases' do
		t.execute("alias 'search %1' => ss")
		r = t.execute("alias").first
    expect(r.data[:message]).to eq "\e[0;94;49mss => search %1\n\e[0m"
  end

  it 'respond to alias commands' do
    expect(t).not_to respond_to :command_ssonly
		t.execute("alias 'search %1' => ssonly")
    expect(t).to respond_to :command_ssonly
  end

  it 'execute alias command' do
    t.instance_variable_set("@in_session", true)

		t.execute("alias 'search %1' => ss")
    t.execute("ss")
  end

	it 'respond to command_alias' do
		expect(t).to respond_to(:command_alias)
	end

	it 'respond to sintax_alias' do
		expect(t).to respond_to(:sintax_alias)
	end

	it 'respond to usage_alias' do
		expect(t).to respond_to(:usage_alias)
	end

	it 'respond to description_alias' do
		expect(t).to respond_to(:description_alias)
	end

end
