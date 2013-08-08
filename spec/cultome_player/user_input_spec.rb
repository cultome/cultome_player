require 'spec_helper'

describe CultomePlayer::UserInput do

  let(:t) { Test.new }

  it 'parse a user input in multiple commands' do
    t.parse('play one').should be_kind_of Array
  end

  it 'parse a user input into a player command' do
    t.parse('play something').should eq([
                                        {
      command: :play, 
      params: [{type: :literal, value: 'something'}]
    }
    ])
  end

  it 'return a valid commands regex' do
    t.send(:valid_command_regex).should match(/([\w]+?\|?)+/)
  end

  it 'parse an user input into a commands list' do
    t.parse('play something | search a:else').should eq([{
      :command=>:play, 
      :params=>[{:value=>"something", :type=>:literal}]
    },{
      :command=>:search, 
      :params=>[{:criteria=>:a, :value=>"else", :type=>:criteria}]
    }])
  end

  it 'parse a command with one number parameter' do
    t.parse('play 1').should eq([{
      command: :play,
      params: [{type: :number, value: 1}]
    }])
  end

  it 'parse a command with number parameters' do
    t.parse('play 1 2').should eq([{
      command: :play,
      params: [{type: :number, value: 1}, {type: :number, value: 2}]
    }])
  end

  it 'parse a command with path parameters' do
    t.parse('play /home/user/no_spaces/').should eq([{
      command: :play,
      params: [{type: :path, value: '/home/user/no_spaces'}]
    }])
  end

  it 'parse a command with a path containig spaces' do
    t.parse('play "/home/user/no spaces/"').should eq([{
      command: :play,
      params: [{type: :path, value: '/home/user/no spaces'}]
    }])
  end

  it 'parse paramters with bubble word in the middle' do
    t.parse('connect drive => /home/user/no_spaces/').should eq([{
      command: :connect,
      params: [
        {type: :literal, value: 'drive'},
        {type: :path, value: '/home/user/no_spaces'}
    ]
    }])
  end

  it 'parse a command with one criteria parameter' do
    t.parse('play a:uno').should eq([{
      command: :play,
      params: [{type: :criteria, criteria: :a, value: 'uno'}]
    }])
  end

  it 'parse a command with one criteria parameter with values that contain spaces' do
    t.parse('play b:"uno dos"').should eq([{
      command: :play,
      params: [{type: :criteria, criteria: :b, value: 'uno dos'}]
    }])
  end

  it 'parse a command with more tha one criteria parameter' do
    t.parse('play b:"uno dos" t:tres').should eq([{
      command: :play,
      params: [
        {type: :criteria, criteria: :b, value: 'uno dos'},
        {type: :criteria, criteria: :t, value: 'tres'}
    ]
    }])
  end

  it 'parse a command with one object parameter' do
    t.parse('play @object').should eq([{
      command: :play,
      params: [{type: :object, value: :object}]
    }])
  end

  it 'parse a command with one object parameter' do
    t.parse('play @object @another').should eq([{
      command: :play,
      params: [
        {type: :object, value: :object},
        {type: :object, value: :another}
    ]
    }])
  end

  it 'parse a command with ip parameter' do
    t.parse('play 1.2.3.4').should eq([{
      command: :play,
      params: [{type: :ip, value: '1.2.3.4'}]
    }])
  end

  it 'parse a command with more than one ip parameters' do
    t.parse('play 1.2.3.4 11.22.33.44').should eq([{
      command: :play,
      params: [
        {type: :ip, value: '1.2.3.4'},
        {type: :ip, value: '11.22.33.44'}
    ]
    }])
  end

  it 'parse a command with literal parameters' do
    t.parse('play something').should eq([{
      command: :play,
      params: [{type: :literal, value: 'something'}]
    }])
  end

  it 'parse a command with only bubble words' do
    t.parse('play =>').should eq([{
      command: :play,
      params: []
    }])
  end

  it 'parse a command with unknown parameter' do
    t.parse('play 0').should eq([{
      command: :play,
      params: [{type: :unknown, value: 0}]
    }])
  end

  it 'parse a command with more than one unknown parameters' do
    t.parse('play g:nada').should eq([{
      command: :play,
      params: [{type: :unknown, value: 'g:nada'}]
    }])
  end

  it 'ask and receive an affirmative confirmation from user' do
    t.should_receive(:display).once.with('message')
    t.stub(:get_command).and_return('y')
    t.get_confirmation('message').should be_true
  end

  it 'ask and receive a negative confirmation from user' do
    t.should_receive(:display).once.with('message')
    t.stub(:get_command).and_return('n')
    t.get_confirmation('message').should be_false
  end

  it 'recognize as affirmative expression /Y|y|yes|1|si|s|ok/' do
    %w{Y y yes 1 si s ok}.each{|y| t.is_true_value(y).should be_true }
  end

  it 'parse a user input into a single command' do
    t.send(:parse_command, 'play one').should eq({
      command: :play,
      params: [{type: :literal, value: 'one'}]
    })
  end

  it 'parse correctly all the parameter types' do
    # numerics
    t.send(:parse_params,%w{1 21 10000000000}).should eq([
                                                         {value: 1, type: :number},
                                                         {value: 21, type: :number},
                                                         {value: 10000000000, type: :number},
    ])

    # path
    t.send(:parse_params,%w{/home/user /root/}).should eq([
                                                          {value: '/home/user', type: :path},
                                                          {value: '/root', type: :path},
    ])

    # criteria
    t.send(:parse_params,%w{a:uno b:dos t:tres_cuatro}).should eq([
                                                                  {value: 'uno', criteria: :a, type: :criteria},
                                                                  {value: 'dos', criteria: :b, type: :criteria},
                                                                  {value: 'tres_cuatro', criteria: :t, type: :criteria},
    ])

    # object
    t.send(:parse_params,%w{@one @two @three_four}).should eq([
                                                              {value: :one, type: :object},
                                                              {value: :two, type: :object},
                                                              {value: :three_four, type: :object},
    ])

    # ips
    t.send(:parse_params,%w{1.2.3.4 192.168.0.1 222.123.3.1}).should eq([
                                                                        {value: '1.2.3.4', type: :ip},
                                                                        {value: '192.168.0.1', type: :ip},
                                                                        {value: '222.123.3.1', type: :ip},
    ])


    # literal
    t.send(:parse_params,%w{pedro pablo paco}).should eq([
                                                         {value: 'pedro', type: :literal},
                                                         {value: 'pablo', type: :literal},
                                                         {value: 'paco', type: :literal},
    ])

    # bubble word
    t.send(:parse_params,%w{=>}).should be_empty

    # unknown
    t.send(:parse_params,%w{0 8:qwerty}).should eq([
                                                   {value: 0, type: :unknown},
                                                   {value: '8:qwerty', type: :unknown},
    ])
  end

  it 'parse two command joined by a pipe' do
    t.parse("play 1 | play 2").should have(2).commands
  end

  it 'parse macros with pipes inclosed in " or \'' do
    t.parse('alias space => "search space | play 1"').should eq([{
      :command=>:alias, 
      :params=>[{:value=>"space", :type=>:literal},
        {:value=>"search space | play 1", :type=>:unknown}]
    }])
  end
end
