require 'spec_helper'

describe CultomePlayer::Media do
  let(:t){ TestClass.new }

  describe 'parse mp3 information' do
    before :each do
      @info = t.extract_from_mp3("#{test_folder}/uno/uno.mp3")
    end

    it 'read name' do
      expect(@info[:name]).not_to be_nil
      expect(@info[:name]).not_to be_empty
    end

    it 'read album' do
      expect(@info[:album]).not_to be_nil
      expect(@info[:album]).not_to be_empty
    end

    it 'read genre' do
      expect(@info[:genre]).not_to be_nil
      expect(@info[:genre]).not_to be_empty
    end

    it 'read track' do
      expect(@info[:track]).not_to be_nil
      expect(@info[:track]).to be > 0
    end

    it 'read year' do
      expect(@info[:year]).not_to be_nil
      expect(@info[:year]).to be > 0
    end

    it 'read duration' do
      expect(@info[:duration]).not_to be_nil
      expect(@info[:duration]).to be > 0
    end
  end
end
