require 'spec_helper'

describe CultomePlayer::Extras::CommandAlias do

    let(:t){ Test.new }

    it 'respond to alias command' do
        t.should respond_to(:alias)
    end

    it 'create an alias of a command string' do
        t.alias([
                {type: :literal, value: 'sap'},
                {type: :literal, value: 'search %1 | play 1'},
        ])

        t.registered_aliases['sap'].should eq('search %1 | play 1')
    end

    it 'execute a command string given its alias' do
        t.should_receive(:quit)
        t.execute('exit')
    end
end
