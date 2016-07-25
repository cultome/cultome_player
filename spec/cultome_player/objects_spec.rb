require 'spec_helper'

describe CultomePlayer::Objects do
  let(:t){ TestClass.new  }

  describe CultomePlayer::Objects::Command do
    it 'groups parameters by type' do
      cmd1 = t.parse("play young 1 a:Muse @focus").first
      cmd2 = t.parse("shuffle true").first
      cmd3 = t.parse("connect /home/user/music => main").first

      expect(cmd1.params.size).to eq 4
      expect(cmd2.params.size).to eq 1
      expect(cmd3.params.size).to eq 3

      check_param(cmd1, :literal, "young")
      check_param(cmd1, :criteria, "Muse")
      check_param(cmd1, :number, 1)
      check_param(cmd1, :object, :focus)
      check_param(cmd2, :boolean, true)
      check_param(cmd3, :path, "/home/user/music")
      check_param(cmd3, :bubble, "=>")
    end

    it 'creates a string representation' do
      cmd1 = t.parse("play young 1 a:Muse @focus").first
      cmd2 = t.parse("shuffle true").first
      cmd3 = t.parse("connect /home/user/music => main").first

      expect(cmd1.to_s).to eq "play young 1 a:Muse @focus"
      expect(cmd2.to_s).to eq "shuffle true"
      expect(cmd3.to_s).to eq "connect /home/user/music => main"
    end

    def check_param(cmd, type, value)
      expect(cmd.params(type).size).to eq 1
      p = cmd.params(type).first
      expect(p.type).to eq type
      expect(p.value).to eq value
    end
  end
end
