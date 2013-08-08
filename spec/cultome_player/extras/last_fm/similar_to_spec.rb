require 'spec_helper'

describe CultomePlayer::Extras::LastFm::SimilarTo do

  let(:t){ Test.new }

  it 'register to listen for "similar" command' do
    Test.new.should respond_to(:similar)
  end

  context 'with similars stored in databse' do
    before :each do
      t.play([{type: :literal, value: 'Traffic Light'}])
      t.should_not_receive(:request_to_lastfm)
    end

    it 'find similar songs to current song due empty params' do
      not_have, have = t.similar
      not_have.should_not be_empty
      have.should_not be_nil
    end

    it 'find similar songs to current song' do
      not_have, have = t.similar([{type: :object, value: :song}])
      not_have.should_not be_empty
      have.should_not be_nil
    end

    it 'find similar artists to current artist' do
      not_have, have = t.similar([{type: :object, value: :artist}])
      have.should_not be_nil
      not_have.should_not be_empty
    end
  end

  context 'without similar in databsae' do
    before :each do
      t.play([{type: :literal, value: 'someday'}])
    end

    it 'find similar songs to current song due empty params' do
      response = JSON.parse(File.open("#{t.project_path}/spec/data/http/getSimilarTrack.response").readlines.join)
      t.should_receive(:request_to_lastfm).and_return(response)
      t.should_receive(:store_similar_tracks)
      not_have, have = t.similar
      not_have.should_not be_empty
      have.should_not be_nil
    end

    it 'find similar songs to current song' do
      response = JSON.parse(File.open("#{t.project_path}/spec/data/http/getSimilarTrack.response").readlines.join)
      t.should_receive(:request_to_lastfm).and_return(response)
      t.should_receive(:store_similar_tracks)

      not_have, have = t.similar([{type: :object, value: :song}])
      not_have.should_not be_empty
      have.should_not be_nil
    end

    it 'find similar artists to current artist' do
      response = JSON.parse(File.open("#{t.project_path}/spec/data/http/getSimilarArtist.response").readlines.join)
      t.should_receive(:request_to_lastfm).and_return(response)
      t.should_receive(:store_similar_artists)

      not_have, have = t.similar([{type: :object, value: :artist}])
      have.should_not be_nil
      not_have.should_not be_empty
    end
  end
end

