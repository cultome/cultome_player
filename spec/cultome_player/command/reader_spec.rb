require 'spec_helper'

describe CultomePlayer::Command::Reader do
  let(:t){ TestClass.new }

  context 'autocomplete' do
    it 'actions' do
      allow(Readline).to receive(:line_buffer).and_return( "pl" )
      expect(t.send(:completion_proc).call("pl")).to eq ["play "]
    end

    it 'path parameters' do
      allow(Readline).to receive(:line_buffer).and_return( "play /hom" )
      expect(t.send(:completion_proc).call("/hom")).to eq ["/home/"]
    end

    it 'object parameters' do
      allow(Readline).to receive(:line_buffer).and_return( "play @art" )
      expect(t.send(:completion_proc).call("@art")).to eq ["@artist"]
    end
  end

  context 'show probable' do
    it 'actions' do
      allow(Readline).to receive(:line_buffer).and_return( "p" )
      expect(t.send(:completion_proc).call("p")).to eq ["play ",  "pause ", "prev "]
    end

    it 'parameter types' do
      allow(Readline).to receive(:line_buffer).and_return( "play " )
      expect(t.send(:completion_proc).call("")).to eq ["<literal>", "<number>", "<criteria>", "<object>", " "]
    end

    it 'paths' do
      allow(Readline).to receive(:line_buffer).and_return( "play /home/" )
      opcs = t.send(:completion_proc).call("/home/")
      opcs.each{|opc| expect(opc).to start_with "/home/" }
    end

    it 'objects' do
      allow(Readline).to receive(:line_buffer).and_return( "play @a" )
      expect(t.send(:completion_proc).call("@a")).to eq ["@artist", "@album"]
    end
  end
end
