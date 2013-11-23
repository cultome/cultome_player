require 'spec_helper'

describe CultomePlayer::Command::Reader do
  let(:t){ TestClass.new }

  context 'autocomplete' do
    it 'actions' do
      Readline.stub(:line_buffer){ "pl" }
      t.completion_proc.call("pl").should eq ["play "]
    end

    it 'path parameters' do
      Readline.stub(:line_buffer){ "play /hom" }
      t.completion_proc.call("/hom").should eq ["/home/"]
    end

    it 'object parameters' do
      Readline.stub(:line_buffer){ "play @art" }
      t.completion_proc.call("@art").should eq ["@artist"]
    end
  end

  context 'show probable' do
    it 'actions' do
      Readline.stub(:line_buffer){ "p" }
      t.completion_proc.call("p").should eq ["play ",  "pause ", "prev "]
    end

    it 'parameter types' do
      Readline.stub(:line_buffer){ "play " }
      t.completion_proc.call("").should eq ["<literal>", "<number>", "<criteria>", "<object>", " "]
    end

    it 'paths' do
      Readline.stub(:line_buffer){ "play /home/" }
      opcs = t.completion_proc.call("/home/")
      opcs.each{|opc| opc.should start_with "/home/" }
    end

    it 'objects' do
      Readline.stub(:line_buffer){ "play @a" }
      t.completion_proc.call("@a").should eq ["@artist", "@album"]
    end
  end
end
