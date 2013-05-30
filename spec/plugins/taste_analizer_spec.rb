require 'spec_helper'
require 'cultome/persistence'

describe Plugins::TasteAnalizer do

	let(:t){ Plugins::TasteAnalizer }
	let(:p){ Cultome::CultomePlayer.new }

	it 'Should register to listen for "similar" command' do
		t.get_listener_registry.should include(:next, :prev)
	end

	it 'Should calculate preferences' do
        p.stub(:song_status){ {"mp3.position.microseconds" => 30000000 } }
        p.stub(:current_command){ {command: :next} }
        with_connection do
            p.prev_song = Cultome::Song.joins(:genres).where("genres.name = ?", "Rock" ).first
            p.song = Cultome::Song.joins(:genres).where("genres.name = ?", "Metal" ).first
            t.calculate_songs_weight(p).round(2).should == 0.7
        end
	end
end
