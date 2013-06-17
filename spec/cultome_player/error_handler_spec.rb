require 'spec_helper'

describe CultomePlayer::ErrorHandler do
    let(:t){ Test.new }
    let(:error_msg){ "error#{CultomePlayer::SocketAdapter::PARAM_TERMINATOR_SEQ}error_description" }

    it 'listen for the playback_fail event' do
        t.event_listeners.should include(:playback_fail)
        t.event_listeners[:playback_fail].should include(:playback_error_handler)
    end

    it 'should call the error hanlder' do
        t.should_receive(:playback_error_handler)
        t.external_player_data_in(error_msg)
    end

    it 'display a message saying the song could not be played' do
        t.play([{type: :literal, value: 'Control Machete'}])
        t.should_receive(:display).twice
        t.external_player_data_in(error_msg)
    end

    it 'call next on the player' do
        t.should_receive(:next).twice
        t.play([{type: :literal, value: 'Control Machete'}])
        t.external_player_data_in(error_msg)
    end
end
