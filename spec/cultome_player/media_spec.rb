require 'spec_helper'

describe CultomePlayer::Media do
  let(:t){ TestClass.new }

  describe 'parse mp3 information' do
    before :each do
      @info = t.extract_from_mp3("#{test_folder}/uno/uno.mp3")
    end

    it 'read name' do
      @info[:name].should_not be_nil
      @info[:name].should_not be_empty
    end

    it 'read album' do
      @info[:album].should_not be_nil
      @info[:album].should_not be_empty
    end

    it 'read genre' do
      @info[:genre].should_not be_nil
      @info[:genre].should_not be_empty
    end

    it 'read track' do
      @info[:track].should_not be_nil
      @info[:track].should > 0
    end

    it 'read year' do
      @info[:year].should_not be_nil
      @info[:year].should > 0
    end

    it 'read duration' do
      @info[:duration].should_not be_nil
      @info[:duration].should > 0
    end
  end
end
