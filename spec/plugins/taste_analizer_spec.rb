require 'spec_helper'
require 'plugins/taste_analizer'

describe Plugin::TasteAnalizer do

	let(:t){ Plugin::TasteAnalizer.new(get_fake_player) }

	it 'Should register to listen for "similar" command' do
		t.get_listener_registry.should include(:next, :prev)
	end

	it 'Should calculate preferences' do
		t.send(:calculate_songs_weight, Song.first, Song.last).should > 0
	end
end
