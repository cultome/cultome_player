require 'spec_helper'

describe CultomePlayer::Command::Processor do
  let(:t){ TestClass.new }

  context '#read_command' do
  end

  context '#get_tokens' do
    it 'respond to get_tokens method' do
      expect(t).to respond_to :get_tokens
    end

    it 'split literals' do
      expect(t.get_tokens("uno dos")).to eq ["uno", "dos"]
    end

    it 'split strings' do
      expect(t.get_tokens("'uno dos' 'tres cuatro'")).to eq ["uno dos", "tres cuatro"]
    end

    it 'split numbers' do
      expect(t.get_tokens("1 2 3")).to eq ["1", "2", "3"]
    end

    it 'split objects' do
      expect(t.get_tokens("@uno @dos")).to eq ["@uno", "@dos"]
    end

    it 'split paths' do
      expect(t.get_tokens("/home/mio '/home/tuyo/con espacio'")).to eq ["/home/mio", "/home/tuyo/con espacio"]
    end

    it 'split criteria' do
      expect(t.get_tokens("uno:dos tres:'cuatro cinco'")).to eq ["uno:dos", "tres:cuatro cinco"]
    end

    it 'raise an error if unclosed string is present' do
      expect { t.get_tokens("uno 'dos") }.to raise_error
    end
  end

  context '#identify_tokens' do
    it 'identify object' do
      expect(t.identify_tokens(["@uno"])).to eq [{type: :object, value: "uno"}]
    end

    it 'identify criteria' do
      expect(t.identify_tokens(["uno:dos"])).to eq [{type: :criteria, criteria: "uno", value: "dos"}]
    end

    it 'identify path' do
      expect(t.identify_tokens(["/home/mio"])).to eq [{type: :path, value: "/home/mio"}]
      expect(t.identify_tokens(["~/music"])).to eq [{type: :path, value: "~/music"}]
    end

    it 'identify number' do
      expect(t.identify_tokens(["1"])).to eq [{type: :number, value: "1"}]
    end

    it 'identify literal' do
      expect(t.identify_tokens(["uno"])).to eq [{type: :literal, value: "uno"}]
    end

    it 'identify as unknown token that dont recognize' do
      expect(t.identify_tokens(["@uno dos"])).to eq [{type: :unknown, value: "@uno dos"}]
      expect(t.identify_tokens(["uno dos:tres"])).to eq [{type: :unknown, value: "uno dos:tres"}]
      expect(t.identify_tokens(["uno/dos"])).to eq [{type: :unknown, value: "uno/dos"}]
    end
  end

  context '#validate_command' do
    it 'validate a command without parameters' do
      expect(t.validate_command(:command, [{type: :literal, value: "stop"}])).to be_truthy
    end

    it 'validate a command with one parameter' do
      expect(t.validate_command(:command, [{type: :literal, value: "play"}, {type: :literal, value: "uno"}])).to be_truthy
    end

    it 'validate a command with more than one parameter' do
      expect(t.validate_command(:command, [{type: :literal, value: "play"}, {type: :number, value: "1"}, {type: :object, value: "dos"}, {type: :criteria, criteria: "tres", value: "cuatro"}])).to be_truthy
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
      expect(t).to respond_to :parse
    end

    it 'returns a command object' do
      expect(t.parse("next").first).to be_instance_of CultomePlayer::Objects::Command
    end

    it 'returns a command even when defined as plugin' do
      expect(t.parse("help").first).to be_instance_of CultomePlayer::Objects::Command
    end

    it 'set the action and parameter' do
      cmd = t.parse("enqueue uno 'dos' tres:cuatro").first

      expect(cmd.action).to eq "enqueue"
      expect(cmd.parameters.size).to eq 3
    end

    it 'basic command' do
      cmd = t.parse("prev").first
      expect(cmd.action).to eq "prev"
      expect(cmd.parameters.size).to eq 0
    end

    it 'with one parameter' do
      cmd = t.parse("shuffle on").first
      expect(cmd.action).to eq "shuffle"
      expect(cmd.parameters.size).to eq 1
    end

    it 'with many parameter' do
      cmd = t.parse("play uno @dos tes:cuatro").first
      expect(cmd.action).to eq "play"
      expect(cmd.parameters.size).to eq 3
    end

    context 'detect parameter type' do
      it 'type literal' do
        cmd = t.parse("search uno").first
        expect(cmd.parameters.size).to eq 1
        expect(cmd.params(:literal).size).to eq 1
      end

      it 'type number' do
        cmd = t.parse("enqueue 1 2").first
        expect(cmd.parameters.size).to eq 2
        expect(cmd.params(:number).size).to eq 2
      end

      it 'type object' do
        cmd = t.parse("show @uno").first
        expect(cmd.parameters.size).to eq 1
        expect(cmd.params(:object).size).to eq 1
      end

      it 'type path' do
        cmd = t.parse("connect /home/mio/music => main").first
        expect(cmd.parameters.size).to eq 3
        expect(cmd.params(:path).size).to eq 1
      end

      it 'type criteria' do
        cmd = t.parse("play uno:dos").first
        expect(cmd.parameters.size).to eq 1
        expect(cmd.params(:criteria).size).to eq 1
      end
    end

    it 'parse piped user commands' do
      cmds = t.parse("search 'algo' && play 1 && ff 45")
      expect(cmds.size).to eq 3
    end
  end
end
