require 'spec_helper'

describe CultomePlayer::Player::Interface::Helper do
  let(:t){ TestClass.new }

  it 'raise an error if processing a unknown object' do
    expect{ t.process_for_search([Parameter.new({type: :object, value: 'unknown'})]) }.to raise_error 'invalid search:unknown type'
  end

  it 'create a progress bar' do
    t.get_progress_bar(55, 200, 10).should eq "|##________|"
    t.get_progress_bar(55, 100, 10).should eq "|#####_____|"
    t.get_progress_bar(55, 100, 20).should eq "|###########_________|"
  end

  it 'create a progress bar with labels in both sides' do
    t.get_progress_bar_with_labels(5, 10, 10, "left", "right").should eq "left |#####_____| right"
    t.get_progress_bar_with_labels(5, 10, 10, "left").should eq "left |#####_____|"
    t.get_progress_bar_with_labels(5, 10, 10, "", "right").should eq "|#####_____| right"
  end

  it 'format seconds to minutos:seconds' do
    t.format_secs(4).should eq "00:04"
    t.format_secs(75).should eq "01:15"
    t.format_secs(65).should eq "01:05"
  end
end
