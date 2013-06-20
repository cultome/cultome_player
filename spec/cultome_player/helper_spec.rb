require 'spec_helper'
require 'net/http'

describe CultomePlayer::Helper do
    let(:out){ double('output').as_null_object }
    let(:t){ 
        my_out = out
        myTest = Class.new do
            include CultomePlayer
            define_method :player_output do
                my_out
            end
        end

        myTest.new
    }


    it 'send messages to the screen' do
        out.should_receive(:puts).with("Testing")
        t.display("Testing")
    end

    it 'send messages to the screen without appending new line' do
        out.should_receive(:print).with("Testing")
        t.display("Testing", true)
    end

    it 'identify windows host os' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return(:mswin)
        t.os.should eq(:windows)
    end

    it 'identify windows host macosx' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return(:darwin)
        t.os.should eq(:macosx)
    end

    it 'identify windows host linux' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return(:linux)
        t.os.should eq(:linux)
    end

    it 'identify windows host unix' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return(:solaris)
        t.os.should eq(:unix)
    end

    it 'holds the db_file path' do
        t.db_file.should end_with 'db_cultome.dat'
    end

    it 'holds the db_log_file path' do
        t.db_log_path.should end_with 'cultome_player.log'
    end

    it 'holds the db_adapter name' do
        t.db_adapter.should eq 'sqlite3'
    end

    it 'capture the stdout from migrations' do
        swallowed = t.swallow_stdout do
            puts "Uno"
            print "Dos"
        end

        swallowed.should eq("Uno\nDos")
    end

    it 'get http client' do
        ENV['http_proxy'] = nil
        t.get_http_client.should eq Net::HTTP
    end

    it 'get http client behind a proxy' do
        ENV['http_proxy'] = 'http://avalid.server.com:1234'
        Net::HTTP.should_receive(:Proxy).with('avalid.server.com', 1234)
        t.get_http_client
    end
end
