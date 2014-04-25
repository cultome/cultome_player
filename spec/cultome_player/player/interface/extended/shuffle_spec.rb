require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  context '#shuffle' do
    it 'check shuffle status' do
      r = t.execute('shuffle').first
      r.message.should eq "No shuffling"
      r.shuffling.should be_false
    end

    it 'turn on the shuffle' do
      t.should_not be_shuffling
      t.execute('shuffle on')
      t.should be_shuffling
    end

    it 'turn off shuffle' do
      t.execute('shuffle on')
      t.should be_shuffling
      t.execute('shuffle off')
      t.should_not be_shuffling
    end
  end
end
