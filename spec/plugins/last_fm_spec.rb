require 'spec_helper'
require 'webmock/rspec'
require 'plugins/last_fm'

describe Plugin::LastFm do

  let(:token){ '5b639825162a568dc1a6a41a1f746e9e' }

  let(:player){ get_fake_player }

	let(:f){ Plugin::LastFm.new(player, {
    'secret' => '2ff2254532bbae15b2fd7cfefa5ba018',
    'token' => token,
  })}

  context '#similar' do
    it 'Should register to listen for "similar" command' do
      f.get_command_registry.should include(:similar)
    end

    it 'Should find similar songs to current song due empty params' do
      stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
        File.new("#{project_path}/spec/data/track.getSimilar")
      )
      Song.should_receive(:find).at_least(1).and_return(player.song)

      with_connection do
        not_have, have = f.similar
        not_have.should_not be_empty
        have.should_not be_nil
      end
    end

    it 'Should find similar songs to current song' do
      stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
        File.new("#{project_path}/spec/data/track.getSimilar")
      )
      Song.should_receive(:find).at_least(1).and_return(player.song)

      with_connection do
        not_have, have = f.similar([{type: :object, value: :song}])
        not_have.should_not be_empty
        have.should_not be_nil
      end
    end

    it 'Should find similar artists to current artist' do
      stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=artist.getSimilar").to_return(
        File.new("#{project_path}/spec/data/artist.getSimilar")
      )
      Artist.should_receive(:find).at_least(1).and_return(player.artist)

      with_connection do
        not_have, have = f.similar([{type: :object, value: :artist}])
        have.should_not be_nil
        not_have.should_not be_empty
      end
    end
  end

  context '#configure_lastfm' do
    it 'Should ask user authorization scrobbler (first step of configuration)' do
      f.should_receive(:gets)
      stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&api_sig=911747596d51614b4db1c340995cd628&format=json&method=auth.getToken").to_return(
        File.new("#{project_path}/spec/data/auth.getToken")
      )

      if os == :windows
        f.should_receive(:system).with(/start \"\" \"http:\/\/www.last.fm\/api\/auth/)
      elsif os == :linux
        f.should_receive(:system).with(/gnome-open http:\/\/www.last.fm\/api\/auth/)
      end

      f.configure_lastfm([{type: :literal, value: 'begin'}])
    end

    it 'Should configure scrobbler (second step of configuration)' do
      stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&api_sig=d7f05d5be53174094959f3a484359efe&format=json&method=auth.getSession&token=#{token}").to_return(
        File.new("#{project_path}/spec/data/auth.getSession")
      )
      f.configure_lastfm([{type: :literal, value: 'done'}])
    end

  end

  context '#scrobble' do

    let(:ff){ Plugin::LastFm.new(player, {
      'secret' => '2ff2254532bbae15b2fd7cfefa5ba018',
      'token' => token,
      'session_key' => "00585dbbedb14ac55d9f9e6f60257a8d",
    })}

    it 'Should scrobble one song' do
      Plugin::LastFm.instance_eval{ @test_time = 1369147228 }
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

      ff.should_receive(:check_pending_scrobbles)

      with_connection do
        ff.scrobble([])
      end
    end

    it 'Should scrobble more than one song' do
      Plugin::LastFm.instance_eval{ @test_time = 1369147228 }
      stub_request(:post, "http://ws.audioscrobbler.com/2.0/").
        with(:body => hash_including({
        "api_key"=>"bfc44b35e39dc6e8df68594a55a442c5",
        "format"=>"json", 
        "method"=>"track.scrobble", 
        "sk"=>"00585dbbedb14ac55d9f9e6f60257a8d", 
        })).to_return(File.new("#{project_path}/spec/data/track.multiple_scrobble"))

      with_connection do
        initial = Scrobble.all.size
        52.times {|idx| Scrobble.create(artist: "Artist #{idx}", track: "Track #{idx}", timestamp: idx.to_s) }
        middle = Scrobble.all.size
        middle.should eq(initial + 52)
        ff.send(:check_pending_scrobbles)
        final = Scrobble.all.size
        final.should eq(0)
      end
    end
  end
end
