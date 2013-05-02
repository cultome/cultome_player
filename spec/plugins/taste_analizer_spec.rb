require 'spec_helper'
require 'cultome/helper'
require 'plugins/taste_analizer'

describe Plugin::TasteAnalizer do

	let(:t){ Plugin::TasteAnalizer.new(get_fake_player, master_config["taste_analizer"]) }

	it 'Should register to listen for "similar" command' do
		t.get_listener_registry.should include(:next, :prev)
	end

	it 'Should calculate preferences' do
		ActiveRecord::Base.establish_connection(adapter: ENV['db_adapter'], database: 'db_cultome.dat')
		rock = Song.joins(:genres).where("genres.name = ?", "Rock" ).first
		metal = Song.joins(:genres).where("genres.name = ?", "Metal" ).first
		t.send(:calculate_songs_weight, rock, metal).should == 0.7
	end
end
