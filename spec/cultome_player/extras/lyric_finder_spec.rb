require 'spec_helper'
require 'webmock/rspec'

describe CultomePlayer::Extras::LyricFinder do

  let(:t){ Test.new }

  it 'listen register command listen' do
    t.should respond_to(:lyric)
  end

  it 'Should find the lyrics for the current song' do
    stub_request(:get, "http://lyrics.wikia.com/api.php?artist=The%20Ting%20Tings&fmt=json&song=Traffic%20Light").to_return(File.new("#{t.project_path}/spec/data/http/search_lyric.response"))
    stub_request(:get, "http://lyrics.wikia.com/The_Ting_Tings:Great_DJ").to_return(File.new("#{t.project_path}/spec/data/http/lyric_found.response"))

    t.play([{type: :literal, value: 'Traffic Light'}])
    t.lyric.should_not be_blank
  end
end
