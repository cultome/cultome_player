require 'spec_helper'
require 'webmock/rspec'

describe CultomePlayer::Extras::LastFm::SimilarTo do


    before :all do
        @t = Test.new
        @song = CultomePlayer::Model::Song.find_by_name('Traffic Light')
        @t.play([{type: :literal, value: 'Traffic Light'}])
    end

    it 'register to listen for "similar" command' do
        @t.should respond_to(:similar)
    end

    it 'find similar songs to current song due empty params' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
            File.new("#{@t.project_path}/spec/data/http/getSimilarTrack.response")
        )

        not_have, have = @t.similar
        not_have.should_not be_empty
        have.should_not be_nil
    end

    it 'find similar songs to current song' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=track.getSimilar&track=Traffic%20Light").to_return(
            File.new("#{@t.project_path}/spec/data/http/getSimilarTrack.response")
        )

        not_have, have = @t.similar([{type: :object, value: :song}])
        not_have.should_not be_empty
        have.should_not be_nil
    end

    it 'find similar artists to current artist' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&artist=The%20Ting%20Tings&format=json&limit=10&method=artist.getSimilar").to_return(
            File.new("#{@t.project_path}/spec/data/http/getSimilarArtist.response")
        )

        not_have, have = @t.similar([{type: :object, value: :artist}])
        have.should_not be_nil
        not_have.should_not be_empty
    end
end

