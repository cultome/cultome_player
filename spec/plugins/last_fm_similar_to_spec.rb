require 'spec_helper'
require 'plugins/last_fm'
require 'webmock/rspec'

describe Plugins::SimilarTo do

    let(:token){ '5b639825162a568dc1a6a41a1f746e9e' }

    let(:player){ Cultome::CultomePlayer.new }
    let(:f){ Plugins::LastFm }

    let(:fixed_song){
        fake_similars = double("similars")
        fake_similars.stub(:create)
        fake_similars.stub(:empty?).and_return(true)

        fake_artist = double("artist")
        fake_artist.stub(:name).and_return("The Ting Tings", "The Ting Tings", "Vengaboys")
        fake_artist.stub(:id).and_return(160, 160, 138)
        fake_artist.stub(:similars).and_return(fake_similars)

        fake_song = double("song")
        fake_song.stub(:name).and_return("Traffic Light", "Great Dj", "Up and Down")
        fake_song.stub(:id).and_return(1067, 1066, 1086)
        fake_song.stub(:path).and_return("spec/data/to_send/music.mp3")
        fake_song.stub(:similars).and_return(fake_similars)
        fake_song.stub(:artist).and_return(fake_artist)
        fake_song
    }
    it 'Should register to listen for "similar" command' do
        f.get_command_registry.should include(:similar)
    end

    it 'Should find similar songs to current song due empty params' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
            File.new("#{project_path}/spec/data/track.getSimilar")
        )

        player.stub(:song){fixed_song}
        Cultome::Song.should_receive(:find).at_least(1).and_return(fixed_song)

        with_connection do
            not_have, have = player.similar
            not_have.should_not be_empty
            have.should_not be_nil
        end
    end

    it 'Should find similar songs to current song' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
            File.new("#{project_path}/spec/data/track.getSimilar")
        )

        player.stub(:song){fixed_song}
        Cultome::Song.should_receive(:find).at_least(1).and_return(fixed_song)

        with_connection do
            not_have, have = player.similar([{type: :object, value: :song}])
            not_have.should_not be_empty
            have.should_not be_nil
        end
    end

    it 'Should find similar artists to current artist' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=artist.getSimilar").to_return(
            File.new("#{project_path}/spec/data/artist.getSimilar")
        )
        player.stub(:song){fixed_song}
        Cultome::Artist.should_receive(:find).at_least(1).and_return(fixed_song.artist)

        with_connection do
            not_have, have = player.similar([{type: :object, value: :artist}])
            have.should_not be_nil
            not_have.should_not be_empty
        end
    end
end

