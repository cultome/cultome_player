require 'spec_helper'

describe CultomePlayer::Command::Processor do
  let(:t){ TestClass.new }

  context '#read_command' do
  end

  context '#get_tokens' do
    it 'respond to get_tokens method' do
      t.should respond_to :get_tokens
    end

    it 'split literals' do
      t.get_tokens("uno dos").should eq ["uno", "dos"]
    end

    it 'split strings' do
      t.get_tokens("'uno dos' 'tres cuatro'").should eq ["uno dos", "tres cuatro"]
    end

    it 'split numbers' do
      t.get_tokens("1 2 3").should eq ["1", "2", "3"]
    end

    it 'split objects' do
      t.get_tokens("@uno @dos").should eq ["@uno", "@dos"]
    end

    it 'split paths' do
      t.get_tokens("/home/mio '/home/tuyo/con espacio'").should eq ["/home/mio", "/home/tuyo/con espacio"]
    end

    it 'split criteria' do
      t.get_tokens("uno:dos tres:'cuatro cinco'").should eq ["uno:dos", "tres:cuatro cinco"]
    end

    it 'raise an error if unclosed string is present' do
      expect { t.get_tokens("uno 'dos") }.to raise_error
    end
  end

  context '#identify_tokens' do
    it 'identify object' do
      t.identify_tokens(["@uno"]).should eq [{type: :object, value: "uno"}]
    end

    it 'identify criteria' do
      t.identify_tokens(["uno:dos"]).should eq [{type: :criteria, criteria: "uno", value: "dos"}]
    end

    it 'identify path' do
      t.identify_tokens(["/home/mio"]).should eq [{type: :path, value: "/home/mio"}]
      t.identify_tokens(["~/music"]).should eq [{type: :path, value: "~/music"}]
    end

    it 'identify number' do
      t.identify_tokens(["1"]).should eq [{type: :number, value: "1"}]
    end

    it 'identify literal' do
      t.identify_tokens(["uno"]).should eq [{type: :literal, value: "uno"}]
    end

    it 'identify as unknown token that dont recognize' do
      t.identify_tokens(["@uno dos"]).should eq [{type: :unknown, value: "@uno dos"}]
      t.identify_tokens(["uno dos:tres"]).should eq [{type: :unknown, value: "uno dos:tres"}]
      t.identify_tokens(["uno/dos"]).should eq [{type: :unknown, value: "uno/dos"}]
    end
  end

  context '#validate_command' do
    it 'validate a command without parameters' do
      t.validate_command(:command, [{type: :literal, value: "stop"}]).should be_true
    end

    it 'validate a command with one parameter' do
      t.validate_command(:command, [{type: :literal, value: "play"}, {type: :literal, value: "uno"}]).should be_true
    end

    it 'validate a command with more than one parameter' do
      t.validate_command(:command, [{type: :literal, value: "play"}, {type: :number, value: "1"}, {type: :object, value: "dos"}, {type: :criteria, criteria: "tres", value: "cuatro"}]).should be_true
    end

    it 'detect invalid command' do
      expect{
        t.validate_command(:command, [{type: :unknown, value: "uno1"}])
      }.to raise_error("invalid command:invalid command")
    end

    it 'detect invalid command format' do
      expect{
        t.validate_command(:command, [{type: :number, value: "1"}])
      }.to raise_error("invalid command:invalid command")
    end
  end

  context 'parse user command' do
    it 'respond to parse method' do
      t.should respond_to :parse
    end

    it 'returns a command object' do
      t.parse("next").should be_instance_of CultomePlayer::Objects::Command
    end

    it 'returns a command even when defined as plugin' do
      t.parse("help").should be_instance_of CultomePlayer::Objects::Command
    end

    it 'set the action and parameter' do
      cmd = t.parse("enqueue uno 'dos' tres:cuatro")

      cmd.action.should eq "enqueue"
      cmd.parameters.should have(3).items
    end

    it 'basic command' do
      cmd = t.parse("prev")
      cmd.action.should eq "prev"
      cmd.should have(0).parameters
    end

    it 'with one parameter' do
      cmd = t.parse("shuffle on")
      cmd.action.should eq "shuffle"
      cmd.should have(1).parameters
    end

    it 'with many parameter' do
      cmd = t.parse("play uno @dos tes:cuatro")
      cmd.action.should eq "play"
      cmd.should have(3).parameters
    end

    context 'detect parameter type' do
      it 'type literal' do
        cmd = t.parse("search uno")
        cmd.should have(1).parameters
        cmd.params(:literal).should have(1).item
      end

      it 'type number' do
        cmd = t.parse("enqueue 1 2")
        cmd.should have(2).parameters
        cmd.params(:number).should have(2).item
      end

      it 'type object' do
        cmd = t.parse("show @uno")
        cmd.should have(1).parameters
        cmd.params(:object).should have(1).item
      end

      it 'type path' do
        cmd = t.parse("connect /home/mio/music => main")
        cmd.should have(3).parameters
        cmd.params(:path).should have(1).item
      end

      it 'type criteria' do
        cmd = t.parse("play uno:dos")
        cmd.should have(1).parameters
        cmd.params(:criteria).should have(1).item
      end
    end
  end
end
