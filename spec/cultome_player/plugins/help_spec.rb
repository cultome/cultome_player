require 'spec_helper'

describe CultomePlayer::Plugins::Help do
  let(:t){ TestClass.new }

  it 'respond to command_help' do
    expect(t).to respond_to(:command_help)
  end

  it 'respond to sintax_help' do
    expect(t).to respond_to(:sintax_help)
  end

  it 'returns fail when no help available' do
    expect(t).to receive(:usage_invalid).and_return(nil)

    r = t.execute("help invalid").first
    expect(r.success?).to be false
    expect(r.data[:response_type]).to eq :message
  end

  it 'returns a general help usage message' do
    r = t.execute("help").first
    expect(r.success?).to be true
    expect(r.data[:response_type]).to eq :message
    expect(r.data[:message]).to match /usage: <command>/
  end
end
