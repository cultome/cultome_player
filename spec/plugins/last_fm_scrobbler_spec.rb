require 'spec_helper'
require 'cultome_player'
require 'plugins/last_fm'
require 'webmock/rspec'

describe Plugins::Scrobbler do

    let(:player){ Cultome::CultomePlayer.new }
    let(:s){ Plugins::LastFm }

    it 'Should scrobble one song' do
        Plugins::LastFm.instance_eval{ @test_time = 1369147228 }
        stub_request(:post, "http://ws.audioscrobbler.com/2.0/").with(:body => {
            "api_key"=>"bfc44b35e39dc6e8df68594a55a442c5",
            "api_sig"=>"cb0be8e3bab1184ef851bfeb7e7dfd42",
            "artist"=>"The Ting Tings",
            "format"=>"json",
            "method"=>"track.scrobble",
            "sk"=>"00585dbbedb14ac55d9f9e6f60257a8d",
            "timestamp"=>"1369147228",
            "track"=>"Great Dj"})
            .to_return(File.new("#{project_path}/spec/data/track.scrobble"))

            Plugins::Scrobbler.should_receive(:check_pending_scrobbles)
            Plugins::LastFm.stub(:config){{'session_key' => '1234567890'}}
            player.stub(:song_status){{seconds: 31000000}}

            with_connection do
                player.play
                player.next
                s.scrobble(player, [])
            end
    end

    it 'Should scrobble more than one song' do
        Plugins::LastFm.instance_eval{ @test_time = 1369147228 }
        stub_request(:post, "http://ws.audioscrobbler.com/2.0/").
            with(:body => hash_including({
            "api_key"=>"bfc44b35e39dc6e8df68594a55a442c5",
            "format"=>"json", 
            "method"=>"track.scrobble", 
            "sk"=>"00585dbbedb14ac55d9f9e6f60257a8d", 
        })).to_return(File.new("#{project_path}/spec/data/track.multiple_scrobble"))

        with_connection do
            initial = Cultome::Scrobble.all.size
            52.times {|idx| Cultome::Scrobble.create(artist: "Artist #{idx}", track: "Track #{idx}", timestamp: idx.to_s) }
            middle = Cultome::Scrobble.all.size
            middle.should eq(initial + 52)
            Plugins::Scrobbler.check_pending_scrobbles
            final = Cultome::Scrobble.all.size
            final.should eq(0)
        end
    end
end
