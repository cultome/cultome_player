require 'spec_helper'
require 'plugins/lyric_finder'
require 'webmock/rspec'

describe Plugin::LyricFinder do

	let(:l){ Plugin::LyricFinder.new(get_fake_player) }

	it 'Should register to listen for "lyric" command' do
		l.get_command_registry.should include(:lyric)
	end

	it 'Should find the lyrics for the current song', resources: true do
		stub_request(:get, "http://lyrics.wikia.com/api.php?artist=The%20Ting%20Tings&fmt=json&song=Traffic%20Light").to_return(File.new("#{project_path}/spec/data/search_lyric"))
		stub_request(:get, "http://lyrics.wikia.com/The_Ting_Tings:Great_DJ").to_return(File.new("#{project_path}/spec/data/lyric_found"))

		l.lyric.should_not be_blank
	end
end
