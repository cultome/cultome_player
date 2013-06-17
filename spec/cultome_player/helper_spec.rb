require 'spec_helper'

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
end
