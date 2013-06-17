require 'spec_helper'

describe CultomePlayer::Interactive do
    let(:out){ double('output').as_null_object }
    let(:t){ 
        my_out = out
        myTest = Class.new do
            include CultomePlayer
            define_method :player_output do
                my_out
            end

            16.times do |idx|
                define_method "c#{idx}" do |str|
                    return str
                end
            end
        end

        myTest.new
    }

    it 'respond to quit command' do
        t.should respond_to(:quit)
    end

    it 'begin a cultome player interactive session with a welcome message' do
        t.should_receive(:get_command).and_return('quit')
        out.should_receive(:puts).with(/Welcome to CulToMe Player v[\d\.]+/)
        t.begin_interactive("my prompt")
    end

    it 'terminate a cultome player interactive session saying bye' do
        t.should_receive(:get_command).and_return('quit')
        out.should_receive(:puts).with('Bye!')
        t.begin_interactive("my prompt")
    end

    it 'show the prompt' do
        Readline.should_receive(:readline).and_return('quit')
        t.begin_interactive("my prompt")
    end

    it 'call execute with user input' do
        t.should_receive(:get_command).and_return('next', 'quit')
        t.should_receive(:next)
        t.begin_interactive("my prompt")
    end

end
