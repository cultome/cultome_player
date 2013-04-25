require 'spec_helper'
require 'webmock/rspec'
require 'plugins/last_fm'

describe Plugin::LastFm do

	let(:f){ Plugin::LastFm.new(get_fake_player) }

	it 'Should register to listen for "similar" command' do
		f.get_command_registry.should have_key(:similar)
	end

	it 'Should find similar songs to current song due empty params', resources: true do
		stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
			File.new("#{project_path}/spec/data/track.getSimilar")
		)

		not_have, have = f.similar
		not_have.should_not be_empty
		have.should_not be_empty
	end

	it 'Should find similar songs to current song', resources: true do
		stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
			File.new("#{project_path}/spec/data/track.getSimilar")
		)

		not_have, have = f.similar([{type: :object, value: :song}])
		not_have.should_not be_empty
		have.should_not be_empty
	end

	it 'Should find similar artists to current artist', resources: true do
		stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=Vengaboys&format=json&limit=10&method=artist.getSimilar").to_return(
			File.new("#{project_path}/spec/data/artist.getSimilar")
		)

		not_have, have = f.similar([{type: :object, value: :artist}])
		not_have.should_not be_empty
		have.should_not be_empty
	end
end
