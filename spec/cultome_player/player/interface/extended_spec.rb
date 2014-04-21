require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  it 'repeats a song from the beginning' do
  	t.should_receive(:send_to_player).with(/^jump 0$/)
  	t.repeat(nil)
  end
end