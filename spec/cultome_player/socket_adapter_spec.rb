require 'spec_helper'

class TestListener
    attr_reader :message

    def received(msg)
        @message = msg
    end
end

describe CultomePlayer::SocketAdapter do
    let(:t) { Test.new }
    let(:host_name) { 'localhost' }
    let(:host_port) { 20103 }

    before :each do
        @pid = t.launch_external_music_player
    end

    after :each do
        t.kill_external_music_player if @pid
    end

    it 'Should create a socket' do
        t.attach_to_socket(host_name, host_port, :external_player_data_in).should be_true
    end

    it 'Should receive data from the socket' do
        t.should_receive(:external_player_data_in).at_least(1)
        t.attach_to_socket(host_name, host_port, :external_player_data_in)
        sleep(0.5)

        t.play_in_external_player(CultomePlayer::Model::Song.first.path)
        sleep(1.5)
    end

    it 'Should write data to the socket' do
        t.attach_to_socket(host_name, host_port, :external_player_data_in)
        sleep(0.5)
        t.write_to_socket('play', CultomePlayer::Model::Song.first.path)
        sleep(0.5)
    end

    it 'Should raise an error if try to attach a socket twice' do
        t.attach_to_socket(host_name, host_port, :external_player_data_in)
        expect { t.attach_to_socket(host_name, host_port, :external_player_data_in) }.to raise_error('Socket already attached!')
    end
end
