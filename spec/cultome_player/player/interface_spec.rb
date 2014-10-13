require 'spec_helper'

describe CultomePlayer::Player::Interface do
  let(:t){ TestClass.new }

  it 'respond to basic commands' do
    [:play , :pause , :stop , :next , :prev , :quit].each do |cmd|
      expect(t).to respond_to cmd
    end
  end

  it 'respond to extended commands' do
    [:show , :enqueue , :search , :shuffle , :connect , :disconnect , :ff , :fb].each do |cmd|
      expect(t).to respond_to cmd
    end
  end
end
