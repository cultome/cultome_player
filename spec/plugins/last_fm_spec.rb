require 'spec_helper'
require 'webmock/rspec'
require 'plugins/last_fm'

describe Plugins::LastFm do

    let(:token){ '5b639825162a568dc1a6a41a1f746e9e' }

    let(:player){ Cultome::CultomePlayer.new }

    it 'Should ask user authorization scrobbler (first step of configuration)' do
        player.should_receive(:gets)
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&api_sig=911747596d51614b4db1c340995cd628&format=json&method=auth.getToken").to_return(
            File.new("#{Cultome::Helper.project_path}/spec/data/auth.getToken")
        )

        if os == :windows
            player.should_receive(:system).with(/start \"\" \"http:\/\/www.last.fm\/api\/auth/)
        elsif os == :linux
            player.should_receive(:system).with(/gnome-open \"http:\/\/www.last.fm\/api\/auth\?api_key=bfc44b35e39dc6e8df68594a55a442c5&token=#{token}\" \"\"/)
        end

        player.configure_lastfm([{type: :literal, value: 'begin'}])
    end

    it 'Should configure scrobbler (second step of configuration)' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&api_sig=d7f05d5be53174094959f3a484359efe&format=json&method=auth.getSession&token=#{token}").to_return(
            File.new("#{Cultome::Helper.project_path}/spec/data/auth.getSession")
        )

        Plugins::LastFm.stub(:config){ {'token' => token} }
        player.configure_lastfm([{type: :literal, value: 'done'}])
    end

end
