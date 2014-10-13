require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  context '#shuffle' do
    it 'check shuffle status' do
      r = t.execute('shuffle').first
      expect(r.message).to eq "No shuffling"
      expect(r.shuffling).to be false
    end

    it 'turn on the shuffle' do
      expect(t).not_to be_shuffling
      t.execute('shuffle on')
      expect(t).to be_shuffling
    end

    it 'turn off shuffle' do
      t.execute('shuffle on')
      expect(t).to be_shuffling
      t.execute('shuffle off')
      expect(t).not_to be_shuffling
    end
  end
end
