require 'spec_helper'
require 'webmock/rspec'

describe CultomePlayer::Extras::LastFm::Scrobbler do

    let(:t){ Test.new }

    it 'register to listen event next' do
        t.event_listeners.should include(:next)
        t.event_listeners[:next].should include(:scrobble)

    end

    it 'register to listen event prev' do
        t.event_listeners.should include(:prev)
        t.event_listeners[:prev].should include(:scrobble)
    end

    it 'register to listen event quit' do
        t.event_listeners.should include(:quit)
        t.event_listeners[:quit].should include(:scrobble)
    end

    it 'scrobble one song' do
        t.instance_eval{ @test_time = 1369147228 }
        stub_request(:post, "http://ws.audioscrobbler.com/2.0/").with(:body => {
            "api_key"=>"bfc44b35e39dc6e8df68594a55a442c5",
            "api_sig"=>"cb0be8e3bab1184ef851bfeb7e7dfd42",
            "artist"=>"The Ting Tings",
            "format"=>"json",
            "method"=>"track.scrobble",
            "sk"=>"00585dbbedb14ac55d9f9e6f60257a8d",
            "timestamp"=>"1369147228",
            "track"=>"Great Dj"})
            .to_return(File.new("#{t.project_path}/spec/data/http/scrobble.response"))

            t.should_receive(:check_pending_scrobbles)
            t.stub(:extras_config){{'session_key' => '1234567890'}}
            t.player.stub(:song_status){{seconds: 31000000}}

            t.play([type: :literal, value: 'Ting Tings'])
            t.execute('next')
    end

    it 'scrobble more than one song' do
        t.instance_eval{ @test_time = 1369147228 }
        stub_request(:post, "http://ws.audioscrobbler.com/2.0/").
            with(:body => hash_including({
            "api_key"=>"bfc44b35e39dc6e8df68594a55a442c5",
            "format"=>"json", 
            "method"=>"track.scrobble", 
            "sk"=>"00585dbbedb14ac55d9f9e6f60257a8d", 
        })).to_return(File.new("#{t.project_path}/spec/data/http/multiple_scrobble.response"))

        initial = CultomePlayer::Model::Scrobble.all.size
        52.times {|idx| CultomePlayer::Model::Scrobble.create(artist: "Artist #{idx}", track: "Track #{idx}", timestamp: idx.to_s) }

        expect{ t.send :check_pending_scrobbles }.to change{ CultomePlayer::Model::Scrobble.all.size }.from(initial + 52).to(0)
    end
end
