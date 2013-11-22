require 'spec_helper'

describe CultomePlayer::Player::Interface do
  let(:t){ TestClass.new }

  it 'respond to basic commands' do
    [:play , :pause , :stop , :next , :prev , :quit].each do |cmd|
      t.should respond_to cmd
    end
  end

  it 'respond to extended commands' do
    [:show , :enqueue , :search , :shuffle , :help , :connect , :disconnect , :ff , :fb].each do |cmd|
      t.should respond_to cmd
    end
  end
end
