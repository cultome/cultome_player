require 'spec_helper'

describe CultomePlayer::Player::Interface::Helper do
  let(:t){ TestClass.new }

  it 'raise an error if processing a unknown object' do
    expect{ t.process_for_search([Parameter.new({type: :object, value: 'unknown'})]) }.to raise_error 'invalid search:unknown type'
  end
end
