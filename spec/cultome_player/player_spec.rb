require 'spec_helper'

describe CultomePlayer::Player do
    let(:t){ Test.new }
    let(:command_listener){ Proc.new {} }

    before :each do
        t.stub(:display)
    end

    it 'parse a user command' do
        t.should_receive(:parse).with('play music').and_return([])
        t.execute('play music')
    end

    it 'call a command given the user input' do
        t.should_receive(:play).with([{type: :literal, value: 'music'}])
        t.execute('play music')
    end

    it 'execute a command' do
        t.should_receive(:play).with([type: :literal, value: 'anything'])
        t.play([type: :literal, value: 'anything'])
    end

    it 'register event listeners' do
        t.register_event_listener(:next, &command_listener)
        CultomePlayer::Player.event_listeners[:next].should include(command_listener)
    end

    it 'not notify listeners of player command executions' do
        command_listener.should_not_receive(:command_executed)
        t.register_event_listener(:command_executed, &command_listener)
        t.search([{ type: :literal, value: 'judas' }])
    end

    it 'notify listeners of player events' do
        command_listener.should_receive(:call).with([{
            command: :play,
            params: [{type: :literal, value: 'judas' }]
        }])
        t.register_event_listener(:command_executed, &command_listener)
        t.execute('play judas')
    end

    it 'return one value if one command is parsed' do
        t.should_receive(:play).and_return("ok")
        ret, ret2 = t.execute('play only')
        ret.should eq("ok")
        ret2.should be_nil
    end

    it 'return more than one value if more than one command is parsed' do
        t.should_receive(:play).twice.and_return("ok")
        ret, ret2 = t.execute('play one | play two')
        ret.should eq("ok")
        ret2.should eq("ok")
    end

    it 'show in-app help' do
        t.help.should_not be_empty
    end

    it 'show command help' do
        t.help([{type: :literal, value: 'play'}]).should_not be_empty
    end

    it 'generate dinamicly the in-app help' do
        t.should_receive(:regenerate_help)
        t.help_message
    end
end
