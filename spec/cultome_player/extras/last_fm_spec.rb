require 'spec_helper'
require 'webmock/rspec'

describe CultomePlayer::Extras::LastFm do

    let(:t){ Test.new }
    let(:token){ '5b639825162a568dc1a6a41a1f746e9e' }

    it 'respond to command configure_lastfm' do
        t.should respond_to(:configure_lastfm)
    end

    it 'Should ask user authorization scrobbler (first step of configuration)' do
        t.should_receive(:gets)
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&api_sig=911747596d51614b4db1c340995cd628&format=json&method=auth.getToken").to_return(
            File.new("#{t.project_path}/spec/data/http/getToken.response")
        )

        if t.os == :windows
            t.should_receive(:system).with(/start \"\" \"http:\/\/www.last.fm\/api\/auth/)
        elsif t.os == :linux
            t.should_receive(:system).with(/gnome-open \"http:\/\/www.last.fm\/api\/auth\?api_key=bfc44b35e39dc6e8df68594a55a442c5&token=#{token}\" \"\"/)
        end

        t.configure_lastfm([{type: :literal, value: 'begin'}])
    end

    it 'Should configure scrobbler (second step of configuration)' do
        stub_request(:get, "http://ws.audioscrobbler.com/2.0/?api_key=bfc44b35e39dc6e8df68594a55a442c5&api_sig=d7f05d5be53174094959f3a484359efe&format=json&method=auth.getSession&token=#{token}").to_return(
            File.new("#{t.project_path}/spec/data/http/getSession.response")
        )

        t.stub(:extras_config){ {'token' => token} }
        t.configure_lastfm([{type: :literal, value: 'done'}])
    end

    it 'send request to Last.fm' do
        Net::HTTP.should_receive(:get_response).and_return("{response: ok}")
        t.send(:request_to_lastfm, {
            api_key: "1235",
            sk: "secret",
            my_param: 'my_value'
        })
    end

end
