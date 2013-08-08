require 'spec_helper'

class TestListener
  attr_reader :message

  def received(msg)
    @message = msg
  end
end

describe CultomePlayer::SocketAdapter do
  let(:t) { Test.new }
  let(:socket){ MockSocket.new }
  let(:host_name) { 'localhost' }
  let(:host_port) { 20103 }

  before :each do
    TCPSocket.should_receive(:new).and_return(socket)
  end

  after :each do
    t.close_socket
  end

  it 'Should create a socket' do
    t.attach_to_socket(host_name, host_port, :external_player_data_in).should be_true
  end

  it 'Should receive data from the socket' do
    socket.buffer= "ok~~"
    t.should_receive(:external_player_data_in).at_least(1)
    t.attach_to_socket(host_name, host_port, :external_player_data_in)
    t.play_in_external_player(CultomePlayer::Model::Song.first.path)
    sleep(0.5)
  end

  it 'Should write data to the socket' do
    socket.should_receive(:print)
    t.attach_to_socket(host_name, host_port, :external_player_data_in)
    t.write_to_socket('play', CultomePlayer::Model::Song.first.path)
  end

  it 'Should raise an error if try to attach a socket twice' do
    t.attach_to_socket(host_name, host_port, :external_player_data_in)
    expect { t.attach_to_socket(host_name, host_port, :external_player_data_in) }.to raise_error('Socket already attached!')
  end
end
